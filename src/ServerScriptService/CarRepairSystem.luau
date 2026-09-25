--!strict
-- ============================================================================
-- CarRepairSystem.luau
-- Location: roblox/src/ServerScriptService/CarRepairSystem.luau
--
-- EPECUÉN: NO ESCAPE - Fiat Cronos Vehicle-Repair Server System
--
-- PURPOSE:
-- Server-authoritative system managing the repair sequence of the stranded
-- Fiat Cronos. Requires the player to have collected all 5 vehicle repair parts
-- and obtained the mechanical repair tool from the abandoned workshop toolbox.
--
-- BEHAVIOR:
--   1. Resolves the existing Fiat Cronos and the abandoned workshop toolbox.
--   2. Adds exactly one ProximityPrompt to the toolbox ("Usar caja de herramientas").
--   3. Authoritative repair service; Cronos prompt is owned by CarRepairInteractionSystem.
--   4. Grants session-only repair-tool state without destroying the toolbox.
--   5. Verifies all 5 canonical components collected via CarPartCollectionSystem.
--   6. Sets Attribute "RepairReady" = true on the Fiat Cronos on repair completion.
--   7. Dispatches toast feedback via the existing NetworkBridge mechanism:
--      "El Cronos está reparado. Ahora podemos escapar."
--   8. Strictly session-only, server-authoritative, zero client trust, zero DataStore.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CarRepairSystem = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type RepairStatus = {
    HasTool: boolean,
    PartsCount: number,
    TotalParts: number,
    IsRepaired: boolean,
    CanRepair: boolean,
    MissingPartsCount: number,
    StatusMessage: string,
}

-- ----------------------------------------------------------------------------
-- CONFIGURATION & PROMPT SPECIFICATIONS
-- ----------------------------------------------------------------------------

local TOTAL_REQUIRED_PARTS = 5

-- Toolbox ProximityPrompt constants
local TOOLBOX_PROMPT_NAME = "ToolboxRepairPrompt"
local TOOLBOX_ACTION_TEXT = "Usar caja de herramientas"
local TOOLBOX_OBJECT_TEXT = "Caja de herramientas"
local TOOLBOX_HOLD_DURATION = 1.0
local TOOLBOX_MAX_DISTANCE = 8.0

-- ----------------------------------------------------------------------------
-- INTERNAL SESSION STATE (SERVER-AUTHORITATIVE, SESSION ONLY)
-- ----------------------------------------------------------------------------

local isInitialized = false
local cronosIsRepaired = false

local playerHasTool: { [Player]: boolean } = {}
local playerRepairedCronos: { [Player]: boolean } = {}
local isRepairingInProgress: { [Player]: boolean } = {}

local activeToolboxModel: Model? = nil
local activeToolboxPrompt: ProximityPrompt? = nil
local activeCronosInstance: Instance? = nil
local activeCronosAnchorPart: BasePart? = nil

local toolboxTriggerConn: RBXScriptConnection? = nil
local systemConnections: { RBXScriptConnection } = {}

-- Decoupled server-side BindableEvents for external observers
local cronosRepairedEvent = Instance.new("BindableEvent")
CarRepairSystem.OnCronosRepaired = cronosRepairedEvent.Event

local toolboxUsedEvent = Instance.new("BindableEvent")
CarRepairSystem.OnToolboxUsed = toolboxUsedEvent.Event

-- ----------------------------------------------------------------------------
-- DEPENDENCY RESOLUTION
-- ----------------------------------------------------------------------------

--- Resolves CarPartCollectionSystem safely from ServerScriptService.
local function getCarPartCollectionSystem(): any
    local parent = script.Parent
    if parent and parent:FindFirstChild("CarPartCollectionSystem") then
        local mod = parent:FindFirstChild("CarPartCollectionSystem")
        if mod and mod:IsA("ModuleScript") then
            return require(mod)
        end
    end

    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarPartCollectionSystem") then
        local mod = serverFolder:FindFirstChild("CarPartCollectionSystem")
        if mod and mod:IsA("ModuleScript") then
            return require(mod)
        end
    end

    local found = ServerScriptService:FindFirstChild("CarPartCollectionSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end

    return nil
end

--- Resolves NetworkBridge safely from ReplicatedStorage for player toast alerts.
local function getNetworkBridge(): any
    local direct = ReplicatedStorage:FindFirstChild("NetworkBridge")
    if direct and direct:IsA("ModuleScript") then
        local success, mod = pcall(require, direct)
        if success then
            return mod
        end
    end

    local sharedFolder = ReplicatedStorage:FindFirstChild("EpecuenShared")
    if sharedFolder and sharedFolder:FindFirstChild("NetworkBridge") then
        local mod = sharedFolder:FindFirstChild("NetworkBridge")
        if mod and mod:IsA("ModuleScript") then
            local success, res = pcall(require, mod)
            if success then
                return res
            end
        end
    end

    local found = ReplicatedStorage:FindFirstChild("NetworkBridge", true)
    if found and found:IsA("ModuleScript") then
        local success, res = pcall(require, found)
        if success then
            return res
        end
    end

    return nil
end

-- ----------------------------------------------------------------------------
-- CLIENT FEEDBACK / TOAST HELPER
-- ----------------------------------------------------------------------------

--- Dispatches feedback message to the player using the existing NetworkBridge mechanism.
local function notifyPlayer(player: Player, success: boolean, message: string)
    local target = activeCronosInstance or activeCronosAnchorPart or activeToolboxModel or Workspace

    -- Attempt 1: Existing NetworkBridge "InteractCompleted" RemoteEvent
    local bridge = getNetworkBridge()
    if bridge and typeof(bridge.GetEvent) == "function" then
        local ok, remoteEvent = pcall(function()
            return bridge.GetEvent("InteractCompleted")
        end)
        if ok and remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireClient(player, target, success, message)
            return
        end
    end

    -- Attempt 2: Direct lookup in ReplicatedStorage.EpecuenRemotes
    local remotes = ReplicatedStorage:FindFirstChild("EpecuenRemotes")
    if remotes then
        local interactEv = remotes:FindFirstChild("InteractCompleted")
        if interactEv and interactEv:IsA("RemoteEvent") then
            interactEv:FireClient(player, target, success, message)
        end
    end
end

-- ----------------------------------------------------------------------------
-- WORLD RESOLUTION HELPERS
-- ----------------------------------------------------------------------------

--- Locates the physical abandoned toolbox in Workspace without creating new instances.
local function findExistingToolbox(): (Model?, BasePart?)
    -- 1. Direct search by canonical model name in Workspace
    local directModel = Workspace:FindFirstChild("RepairTool_Corralon_AbandonedToolbox", true)
    if directModel and directModel:IsA("Model") then
        local anchor = directModel.PrimaryPart
            or directModel:FindFirstChild("BasePlate", true)
            or directModel:FindFirstChildWhichIsA("BasePart", true)
        if anchor and anchor:IsA("BasePart") then
            return directModel, anchor
        end
    end

    -- 2. Search inside EpecuenWorld.EnvironmentDetails
    local world = Workspace:FindFirstChild("EpecuenWorld")
    if world then
        local env = world:FindFirstChild("EnvironmentDetails")
        if env then
            local inEnv = env:FindFirstChild("RepairTool_Corralon_AbandonedToolbox")
            if inEnv and inEnv:IsA("Model") then
                local anchor = inEnv.PrimaryPart
                    or inEnv:FindFirstChild("BasePlate", true)
                    or inEnv:FindFirstChildWhichIsA("BasePart", true)
                if anchor and anchor:IsA("BasePart") then
                    return inEnv, anchor
                end
            end
        end
    end

    return nil, nil
end

--- Selects an exterior BasePart on the Fiat Cronos (prefers front hood / engine bay).
local function resolveVehicleAnchor(vehicle: Instance): BasePart?
    if vehicle:IsA("BasePart") then
        return vehicle
    end

    if vehicle:IsA("Model") then
        local hood = vehicle:FindFirstChild("Hood_Main", true)
        if hood and hood:IsA("BasePart") then
            return hood
        end

        local repairPoint = vehicle:FindFirstChild("RepairInteractionPoint", true)
        if repairPoint and repairPoint:IsA("BasePart") then
            return repairPoint
        end

        if vehicle.PrimaryPart then
            return vehicle.PrimaryPart
        end

        return vehicle:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

--- Locates the physical Fiat Cronos in Workspace without creating new instances.
local function findExistingFiatCronos(): (Instance?, BasePart?)
    -- 1. Named models: "FiatCronos" or "TheFiatCronos"
    local cronos = Workspace:FindFirstChild("FiatCronos", true)
        or Workspace:FindFirstChild("TheFiatCronos", true)

    if cronos then
        local anchor = resolveVehicleAnchor(cronos)
        if anchor then
            return cronos, anchor
        end
    end

    -- 2. Search inside EpecuenWorld hierarchy
    local world = Workspace:FindFirstChild("EpecuenWorld")
    if world then
        local markers = world:FindFirstChild("Markers")
        if markers then
            local vehicleMarker = markers:FindFirstChild("Vehicle_FiatCronos")
            if vehicleMarker then
                local childModel = vehicleMarker:FindFirstChildWhichIsA("Model")
                if childModel then
                    local anchor = resolveVehicleAnchor(childModel)
                    return childModel, anchor
                elseif vehicleMarker:IsA("BasePart") then
                    return vehicleMarker, vehicleMarker
                end
            end
        end

        local worldCronos = world:FindFirstChild("FiatCronos") or world:FindFirstChild("TheFiatCronos")
        if worldCronos then
            local anchor = resolveVehicleAnchor(worldCronos)
            if anchor then
                return worldCronos, anchor
            end
        end
    end

    -- 3. Fallback search by marker
    local rootMarker = Workspace:FindFirstChild("Vehicle_FiatCronos", true)
    if rootMarker then
        if rootMarker:IsA("Model") then
            return rootMarker, resolveVehicleAnchor(rootMarker)
        elseif rootMarker:IsA("BasePart") then
            local childModel = rootMarker:FindFirstChildWhichIsA("Model")
            if childModel then
                return childModel, resolveVehicleAnchor(childModel)
            end
            return rootMarker, rootMarker
        end
    end

    return nil, nil
end

-- ----------------------------------------------------------------------------
-- PROMPT SETUP & INTERACTION LOGIC
-- ----------------------------------------------------------------------------

--- Handles toolbox interaction: gives session repair-tool state without destroying model.
local function handleToolboxTriggered(player: Player)
    if not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then
        return
    end

    if playerHasTool[player] then
        notifyPlayer(player, true, "Ya tienes las herramientas mecánicas del taller.")
        return
    end

    playerHasTool[player] = true
    notifyPlayer(player, true, "Caja de herramientas obtenida. Ahora puedes reparar el Fiat Cronos si tienes todas las piezas.")

    toolboxUsedEvent:Fire(player, activeToolboxModel)
end

--- Sets up exactly one ProximityPrompt on the abandoned workshop toolbox.
local function setupToolboxPrompt(): boolean
    local model, anchor = findExistingToolbox()
    if not model or not anchor then
        return false
    end

    activeToolboxModel = model

    -- Check if prompt already exists to prevent duplication
    local existingPrompt = anchor:FindFirstChild(TOOLBOX_PROMPT_NAME) :: ProximityPrompt?
    if not existingPrompt then
        existingPrompt = model:FindFirstChild(TOOLBOX_PROMPT_NAME, true) :: ProximityPrompt?
    end

    if existingPrompt and existingPrompt:IsA("ProximityPrompt") then
        activeToolboxPrompt = existingPrompt
    else
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = TOOLBOX_PROMPT_NAME
        prompt.ActionText = TOOLBOX_ACTION_TEXT
        prompt.ObjectText = TOOLBOX_OBJECT_TEXT
        prompt.HoldDuration = TOOLBOX_HOLD_DURATION
        prompt.MaxActivationDistance = TOOLBOX_MAX_DISTANCE
        prompt.RequiresLineOfSight = true
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.ClickablePrompt = true
        prompt.Parent = anchor

        activeToolboxPrompt = prompt
    end

    if activeToolboxPrompt then
        if toolboxTriggerConn and toolboxTriggerConn.Connected then
            toolboxTriggerConn:Disconnect()
        end
        toolboxTriggerConn = activeToolboxPrompt.Triggered:Connect(handleToolboxTriggered)
        return true
    end

    return false
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Authoritative repair execution API invoked by interaction controllers.
--- Verifies parts and tool server-authoritatively before executing repair sequence.
--- Returns (success: boolean, message: string).
function CarRepairSystem.ExecuteRepair(player: Player): (boolean, string)
    if not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then
        return false, "Jugador inválido."
    end

    -- Mutex lock against concurrent activations in the same frame
    if isRepairingInProgress[player] then
        return false, "Reparación en progreso."
    end
    isRepairingInProgress[player] = true

    local status = CarRepairSystem.GetRepairStatus(player)

    -- Case 1: Already repaired for this session
    if status.IsRepaired then
        local msg = "El Cronos ya está reparado. Ahora podemos escapar."
        notifyPlayer(player, true, msg)
        isRepairingInProgress[player] = nil
        return false, msg
    end

    -- Case 2: Missing vehicle repair parts
    if status.PartsCount < status.TotalParts then
        local missing = status.TotalParts - status.PartsCount
        local msg = string.format("Faltan %d piezas para reparar el Cronos (%d/%d recolectadas).", missing, status.PartsCount, status.TotalParts)
        notifyPlayer(player, false, msg)
        isRepairingInProgress[player] = nil
        return false, msg
    end

    -- Case 3: Missing mechanical tools
    if not status.HasTool then
        local msg = "Necesitas la caja de herramientas del Corralón Municipal."
        notifyPlayer(player, false, msg)
        isRepairingInProgress[player] = nil
        return false, msg
    end

    -- Case 4: Requirements fully satisfied: execute repair sequence
    playerRepairedCronos[player] = true
    cronosIsRepaired = true

    -- Ensure vehicle instance is resolved
    if not activeCronosInstance then
        local instance, anchor = findExistingFiatCronos()
        activeCronosInstance = instance
        activeCronosAnchorPart = anchor
    end

    -- Set server-side attribute on the vehicle model as world-level informational state
    if activeCronosInstance then
        activeCronosInstance:SetAttribute("RepairReady", true)
    end

    -- Provide canonical feedback
    local successMsg = "El Cronos está reparado. Ahora podemos escapar."
    notifyPlayer(player, true, successMsg)

    -- Fire decoupled server event for external systems
    cronosRepairedEvent:Fire(player, activeCronosInstance)

    isRepairingInProgress[player] = nil
    return true, successMsg
end

--- Initializes the Fiat Cronos repair system and arms interaction points.
function CarRepairSystem.Initialize(): boolean
    if isInitialized then
        return true
    end
    isInitialized = true

    -- 1. Attempt immediate prompt setup on the abandoned workshop toolbox
    setupToolboxPrompt()

    -- 2. Hook descendant addition on Workspace to detect if toolbox is generated later
    local descendantConn = Workspace.DescendantAdded:Connect(function(descendant: Instance)
        if not activeToolboxPrompt then
            if descendant.Name == "RepairTool_Corralon_AbandonedToolbox" then
                task.defer(setupToolboxPrompt)
            end
        end
    end)
    table.insert(systemConnections, descendantConn)

    -- 3. Hook player removal to clean up session state and prevent memory leaks
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
        playerHasTool[player] = nil
        playerRepairedCronos[player] = nil
        isRepairingInProgress[player] = nil
    end)
    table.insert(systemConnections, playerRemovingConn)

    return true
end

--- Returns whether the player has obtained the repair tools from the workshop toolbox.
function CarRepairSystem.HasRepairTool(player: Player): boolean
    if not player or not player:IsA("Player") then
        return false
    end
    return playerHasTool[player] == true
end

--- Returns whether the player has completed the Fiat Cronos repair sequence.
function CarRepairSystem.HasRepairedCronos(player: Player): boolean
    if not player or not player:IsA("Player") then
        return false
    end
    return playerRepairedCronos[player] == true
end

--- Returns whether the Fiat Cronos has been successfully repaired and is ready for escape.
function CarRepairSystem.IsCronosRepairReady(): boolean
    if cronosIsRepaired then
        return true
    end
    if activeCronosInstance and activeCronosInstance:GetAttribute("RepairReady") == true then
        return true
    end
    return false
end

--- Returns the comprehensive repair progression status for a given player.
function CarRepairSystem.GetRepairStatus(player: Player): RepairStatus
    local hasTool = CarRepairSystem.HasRepairTool(player)
    local isRepaired = CarRepairSystem.HasRepairedCronos(player)

    local partsCount = 0
    local collectionSystem = getCarPartCollectionSystem()
    if collectionSystem and typeof(collectionSystem.GetCollectedCount) == "function" then
        partsCount = collectionSystem.GetCollectedCount(player)
    end

    local missingParts = math.max(0, TOTAL_REQUIRED_PARTS - partsCount)
    local canRepair = (not isRepaired) and hasTool and (partsCount >= TOTAL_REQUIRED_PARTS)

    local statusMessage = ""
    if isRepaired then
        statusMessage = "El Cronos está reparado. Ahora podemos escapar."
    elseif not hasTool and partsCount < TOTAL_REQUIRED_PARTS then
        statusMessage = string.format("Faltan %d piezas y herramientas mecánicas del taller.", missingParts)
    elseif not hasTool then
        statusMessage = "Las 5 piezas están listas, pero necesitas herramientas mecánicas del Corralón."
    elseif partsCount < TOTAL_REQUIRED_PARTS then
        statusMessage = string.format("Herramientas listas, pero faltan %d piezas para completar la reparación.", missingParts)
    else
        statusMessage = "Todo listo para reparar el Fiat Cronos."
    end

    return {
        HasTool = hasTool,
        PartsCount = partsCount,
        TotalParts = TOTAL_REQUIRED_PARTS,
        IsRepaired = isRepaired,
        CanRepair = canRepair,
        MissingPartsCount = missingParts,
        StatusMessage = statusMessage,
    }
end

--- Cleans up internal state, prompt listeners, and connections.
function CarRepairSystem.Cleanup(): ()
    isInitialized = false
    cronosIsRepaired = false

    if toolboxTriggerConn and toolboxTriggerConn.Connected then
        toolboxTriggerConn:Disconnect()
        toolboxTriggerConn = nil
    end

    for _, conn in ipairs(systemConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(systemConnections)

    if activeToolboxPrompt then
        activeToolboxPrompt:Destroy()
        activeToolboxPrompt = nil
    end

    activeToolboxModel = nil
    activeCronosInstance = nil
    activeCronosAnchorPart = nil

    table.clear(playerHasTool)
    table.clear(playerRepairedCronos)
    table.clear(isRepairingInProgress)
end

-- Auto-initialize deferred on the server
task.defer(function()
    CarRepairSystem.Initialize()
end)

return CarRepairSystem
