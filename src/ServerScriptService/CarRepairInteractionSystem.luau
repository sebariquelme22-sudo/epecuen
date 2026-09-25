--!strict
-- ============================================================================
-- CarRepairInteractionSystem.luau
-- Location: roblox/src/ServerScriptService/CarRepairInteractionSystem.luau
--
-- EPECUÉN: NO ESCAPE - Fiat Cronos Vehicle-Repair Interaction System
--
-- PURPOSE:
-- Server-side interaction point at the existing Fiat Cronos to inspect the
-- repair readiness and verify the 5 repair components collected by the player.
--
-- CANONICAL COMPONENTS REQUIRED:
--   1. Battery      ("Batería" / "Batería de Plomo 12V 75Ah")
--   2. Alternator   ("Alternador" / "Alternador de Carga 14V")
--   3. SparkPlugs   ("Bujías" / "Juego de Bujías de Encendido")
--   4. FuelCanister ("Bidón de nafta" / "Bidón de Nafta 20L")
--   5. RadiatorHose ("Manguera del radiador" / "Manguera Reforzada de Refrigerante")
--
-- INTERACTION SPECIFICATION:
--   - Exactly ONE ProximityPrompt on the existing Fiat Cronos interaction point.
--   - ActionText: "Revisar piezas"
--   - ObjectText: "Fiat Cronos"
--   - HoldDuration: 1.0 second
--   - MaxActivationDistance: 10.0 studs
--   - RequiresLineOfSight: true
--   - Works with Keyboard (E), Gamepad (ButtonX), and Mobile/Touch (tap).
--   - Duplicate prompt creation is strictly prohibited.
--
-- SERVER-AUTHORITATIVE VALIDATION:
--   - Directly queries CarPartCollectionSystem for actual per-player progress.
--   - Does NOT trust client-provided parameters.
--   - Does NOT modify collection state.
--   - Does NOT start vehicle repair.
--   - Does NOT consume or remove any collected parts.
--
-- STATUS REPORTING:
--   - If < 5 parts: "Faltan X piezas para reparar el Cronos. Piezas faltantes: [names]."
--   - If 5 parts:   "Las 5 piezas están listas. El Cronos puede ser reparado."
--   - Uses existing NetworkBridge "InteractCompleted" for unobtrusive toast display.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CarRepairInteractionSystem = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type ObjectiveId = "Battery" | "Alternator" | "SparkPlugs" | "FuelCanister" | "RadiatorHose"

export type ComponentDefinition = {
    Id: ObjectiveId,
    DisplayName: string,
    FullName: string,
    ModelName: string,
    Order: number,
}

export type MissingPartDetail = {
    Id: ObjectiveId,
    DisplayName: string,
    FullName: string,
    ModelName: string,
}

export type RepairReadiness = {
    CollectedCount: number,
    TotalRequired: number,
    IsReady: boolean,
    MissingParts: { MissingPartDetail },
    StatusMessage: string,
}

export type InteractionState = "MissingParts" | "NeedsTool" | "ReadyToRepair" | "AlreadyRepaired"

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL COMPONENT DEFINITIONS
-- ----------------------------------------------------------------------------

local PROMPT_ACTION_TEXT = "Revisar piezas"
local PROMPT_ACTION_TEXT_REPAIR = "Reparar Cronos"
local PROMPT_OBJECT_TEXT = "Fiat Cronos"
local PROMPT_HOLD_DURATION = 1.0
local PROMPT_MAX_ACTIVATION_DISTANCE = 10.0
local PROMPT_REQUIRES_LINE_OF_SIGHT = true
local PROMPT_NAME = "CronosRepairPrompt"

local CANONICAL_COMPONENTS: { ComponentDefinition } = {
    {
        Id = "Battery",
        DisplayName = "Batería",
        FullName = "Batería de Plomo 12V 75Ah",
        ModelName = "VehiclePart_Battery_12V",
        Order = 1,
    },
    {
        Id = "Alternator",
        DisplayName = "Alternador",
        FullName = "Alternador de Carga 14V",
        ModelName = "VehiclePart_Alternator_14V",
        Order = 2,
    },
    {
        Id = "SparkPlugs",
        DisplayName = "Bujías",
        FullName = "Juego de Bujías de Encendido",
        ModelName = "VehiclePart_SparkPlugs_Set",
        Order = 3,
    },
    {
        Id = "FuelCanister",
        DisplayName = "Bidón de nafta",
        FullName = "Bidón de Nafta 20L",
        ModelName = "VehiclePart_FuelCanister_20L",
        Order = 4,
    },
    {
        Id = "RadiatorHose",
        DisplayName = "Manguera del radiador",
        FullName = "Manguera Reforzada de Refrigerante",
        ModelName = "VehiclePart_RadiatorHose_Reinforced",
        Order = 5,
    },
}

local TOTAL_REQUIRED = #CANONICAL_COMPONENTS

-- ----------------------------------------------------------------------------
-- INTERNAL STATE & LIFECYCLE
-- ----------------------------------------------------------------------------

local isInitialized = false
local activePrompt: ProximityPrompt? = nil
local activeTargetPart: BasePart? = nil
local activeVehicleInstance: Instance? = nil

local promptTriggerConn: RBXScriptConnection? = nil
local promptHoldBeganConn: RBXScriptConnection? = nil
local promptHoldEndedConn: RBXScriptConnection? = nil
local systemConnections: { RBXScriptConnection } = {}

-- Server-side bindable event for decoupled observers
local repairInteractionEvent = Instance.new("BindableEvent")
CarRepairInteractionSystem.OnRepairChecked = repairInteractionEvent.Event

-- ----------------------------------------------------------------------------
-- DEPENDENCY RESOLUTION
-- ----------------------------------------------------------------------------

--- Resolves CarPartCollectionSystem from ServerScriptService safely.
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

--- Resolves CarRepairSystem from ServerScriptService safely.
local function getCarRepairSystem(): any
    local parent = script.Parent
    if parent and parent:FindFirstChild("CarRepairSystem") then
        local mod = parent:FindFirstChild("CarRepairSystem")
        if mod and mod:IsA("ModuleScript") then
            return require(mod)
        end
    end

    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarRepairSystem") then
        local mod = serverFolder:FindFirstChild("CarRepairSystem")
        if mod and mod:IsA("ModuleScript") then
            return require(mod)
        end
    end

    local found = ServerScriptService:FindFirstChild("CarRepairSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end

    return nil
end

--- Resolves NetworkBridge from ReplicatedStorage safely.
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
-- VEHICLE RESOLUTION & INTERACTION ANCHOR
-- ----------------------------------------------------------------------------

--- Selects the optimal exterior BasePart on the vehicle to host the ProximityPrompt.
--- Prioritizes front hood/engine bay area for natural player interaction.
local function resolveInteractionPart(vehicle: Instance): BasePart?
    if vehicle:IsA("BasePart") then
        return vehicle
    end

    if vehicle:IsA("Model") then
        -- 1. Check explicit interaction markers if already placed
        local namedPoint = vehicle:FindFirstChild("RepairInteractionPoint", true)
            or vehicle:FindFirstChild("InteractionPoint", true)
        if namedPoint and namedPoint:IsA("BasePart") then
            return namedPoint
        end

        -- 2. Prefer the front hood panel (exterior, eye-level, near engine bay)
        local hood = vehicle:FindFirstChild("Hood_Main", true)
        if hood and hood:IsA("BasePart") then
            return hood
        end

        -- 3. Vehicle PrimaryPart (Chassis_Root)
        if vehicle.PrimaryPart then
            return vehicle.PrimaryPart
        end

        -- 4. Any valid BasePart fallback
        return vehicle:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

--- Searches for the existing Fiat Cronos without creating or moving anything.
local function findExistingFiatCronos(): (Instance?, BasePart?)
    -- 1. Search for named models: "TheFiatCronos" or "FiatCronos"
    local cronos = Workspace:FindFirstChild("TheFiatCronos", true) :: Instance?
    if not cronos then
        cronos = Workspace:FindFirstChild("FiatCronos", true)
    end

    if cronos then
        local anchor = resolveInteractionPart(cronos)
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
                -- Check if the Model is parented inside the marker
                local childModel = vehicleMarker:FindFirstChildWhichIsA("Model")
                if childModel then
                    local anchor = resolveInteractionPart(childModel)
                    return childModel, anchor
                elseif vehicleMarker:IsA("BasePart") then
                    return vehicleMarker, vehicleMarker
                end
            end
        end

        -- Direct child of EpecuenWorld
        local worldCronos = world:FindFirstChild("FiatCronos") or world:FindFirstChild("TheFiatCronos")
        if worldCronos then
            local anchor = resolveInteractionPart(worldCronos)
            if anchor then
                return worldCronos, anchor
            end
        end
    end

    -- 3. Check for marker in Workspace root
    local rootMarker = Workspace:FindFirstChild("Vehicle_FiatCronos", true)
    if rootMarker then
        if rootMarker:IsA("Model") then
            return rootMarker, resolveInteractionPart(rootMarker)
        elseif rootMarker:IsA("BasePart") then
            local childModel = rootMarker:FindFirstChildWhichIsA("Model")
            if childModel then
                return childModel, resolveInteractionPart(childModel)
            end
            return rootMarker, rootMarker
        end
    end

    return nil, nil
end

-- ----------------------------------------------------------------------------
-- CLIENT NOTIFICATION HELPER
-- ----------------------------------------------------------------------------

--- Dispatches the inspection result to the player via the existing HUD toast system.
local function notifyPlayer(player: Player, readiness: RepairReadiness)
    local target = activeVehicleInstance or activeTargetPart or Workspace

    -- Attempt to use existing NetworkBridge "InteractCompleted" event
    local bridge = getNetworkBridge()
    if bridge and typeof(bridge.GetEvent) == "function" then
        local success, remoteEvent = pcall(function()
            return bridge.GetEvent("InteractCompleted")
        end)
        if success and remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireClient(player, target, readiness.IsReady, readiness.StatusMessage)
            return
        end
    end

    -- Fallback: Check ReplicatedStorage.EpecuenRemotes directly
    local remotes = ReplicatedStorage:FindFirstChild("EpecuenRemotes")
    if remotes then
        local interactEv = remotes:FindFirstChild("InteractCompleted")
        if interactEv and interactEv:IsA("RemoteEvent") then
            interactEv:FireClient(player, target, readiness.IsReady, readiness.StatusMessage)
        end
    end
end

--- Dispatches a direct message to the player via the existing HUD toast system.
local function notifyPlayerMessage(player: Player, isSuccess: boolean, message: string)
    local target = activeVehicleInstance or activeTargetPart or Workspace

    local bridge = getNetworkBridge()
    if bridge and typeof(bridge.GetEvent) == "function" then
        local success, remoteEvent = pcall(function()
            return bridge.GetEvent("InteractCompleted")
        end)
        if success and remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireClient(player, target, isSuccess, message)
            return
        end
    end

    local remotes = ReplicatedStorage:FindFirstChild("EpecuenRemotes")
    if remotes then
        local interactEv = remotes:FindFirstChild("InteractCompleted")
        if interactEv and interactEv:IsA("RemoteEvent") then
            interactEv:FireClient(player, target, isSuccess, message)
        end
    end
end

-- ----------------------------------------------------------------------------
-- CORE PROMPT INTERACTION HANDLER
-- ----------------------------------------------------------------------------

--- Dynamically updates the single prompt's presentation based on interacting player's readiness.
local function handlePromptHoldBegan(player: Player)
    if not player or not player:IsA("Player") or not activePrompt then
        return
    end

    local state, _ = CarRepairInteractionSystem.GetPlayerInteractionState(player)
    if state == "ReadyToRepair" then
        activePrompt.ActionText = PROMPT_ACTION_TEXT_REPAIR
    else
        activePrompt.ActionText = PROMPT_ACTION_TEXT
    end
end

--- Resets prompt text to default when hold ends.
local function handlePromptHoldEnded(player: Player)
    if activePrompt then
        activePrompt.ActionText = PROMPT_ACTION_TEXT
    end
end

--- Server-authoritative handler invoked when a player interacts with the Fiat Cronos.
--- Dynamically executes the appropriate state logic:
--- STATE 1 (Missing parts): Shows missing-parts status.
--- STATE 2 (5 parts, no tool): Explains the player needs the mechanical toolbox.
--- STATE 3 (5 parts, has tool): Changes prompt text to "Reparar Cronos", delegates repair operation to CarRepairSystem.
--- STATE 4 (Already repaired): Reports "El Cronos ya está reparado. Ahora podemos escapar."
local function handlePromptTriggered(player: Player)
    if not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then
        return
    end

    local state, message = CarRepairInteractionSystem.GetPlayerInteractionState(player)
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)

    if state == "AlreadyRepaired" then
        -- STATE 4: Player already repaired the Cronos
        notifyPlayerMessage(player, true, "El Cronos ya está reparado. Ahora podemos escapar.")
        repairInteractionEvent:Fire(player, readiness)
        return
    end

    if state == "MissingParts" then
        -- STATE 1: Missing parts (< 5 parts collected)
        notifyPlayer(player, readiness)
        repairInteractionEvent:Fire(player, readiness)
        return
    end

    if state == "NeedsTool" then
        -- STATE 2: All 5 parts collected but no repair tool
        notifyPlayerMessage(player, false, message)
        repairInteractionEvent:Fire(player, readiness)
        return
    end

    if state == "ReadyToRepair" then
        -- STATE 3: All 5 parts collected AND player has repair tool
        if activePrompt then
            activePrompt.ActionText = PROMPT_ACTION_TEXT_REPAIR
        end

        local repairSystem = getCarRepairSystem()
        if repairSystem then
            -- Delegate the actual repair operation to the existing CarRepairSystem server API
            if typeof(repairSystem.ExecuteRepair) == "function" then
                repairSystem.ExecuteRepair(player)
            elseif typeof(repairSystem.RepairCronos) == "function" then
                repairSystem.RepairCronos(player)
            elseif typeof(repairSystem.HandleRepair) == "function" then
                repairSystem.HandleRepair(player)
            else
                -- Fallback notification when CarRepairSystem does not expose an ExecuteRepair API
                notifyPlayerMessage(
                    player,
                    true,
                    "Todo listo para reparar el Fiat Cronos. (Requiere método público de ejecución en CarRepairSystem)"
                )
            end
        else
            notifyPlayerMessage(player, false, "Sistema de reparación no disponible.")
        end

        repairInteractionEvent:Fire(player, readiness)
        return
    end
end

-- ----------------------------------------------------------------------------
-- PUBLIC API: REPAIR READINESS & MISSING PARTS QUERY
-- ----------------------------------------------------------------------------

--- Calculates the complete repair readiness for a given player.
--- Server-authoritative: Reads purely from CarPartCollectionSystem.
--- Never modifies collection state, never starts repair, never consumes parts.
function CarRepairInteractionSystem.GetRepairReadiness(player: Player): RepairReadiness
    if not player or not player:IsA("Player") then
        return {
            CollectedCount = 0,
            TotalRequired = TOTAL_REQUIRED,
            IsReady = false,
            MissingParts = {},
            StatusMessage = string.format("Faltan %d piezas para reparar el Cronos.", TOTAL_REQUIRED),
        }
    end

    -- Query CarPartCollectionSystem server-authoritatively
    local collectionSystem = getCarPartCollectionSystem()
    local collectedMap: { [string]: boolean } = {}
    if collectionSystem and typeof(collectionSystem.GetCollectedParts) == "function" then
        local progress = collectionSystem.GetCollectedParts(player)
        if typeof(progress) == "table" then
            for k, v in pairs(progress) do
                if v == true then
                    collectedMap[k] = true
                end
            end
        end
    end

    local collectedCount = 0
    local missingParts: { MissingPartDetail } = {}

    for _, comp in ipairs(CANONICAL_COMPONENTS) do
        if collectedMap[comp.Id] == true then
            collectedCount += 1
        else
            table.insert(missingParts, {
                Id = comp.Id,
                DisplayName = comp.DisplayName,
                FullName = comp.FullName,
                ModelName = comp.ModelName,
            })
        end
    end

    local isReady = (collectedCount >= TOTAL_REQUIRED)
    local statusMessage: string

    if isReady then
        statusMessage = "Las 5 piezas están listas. El Cronos puede ser reparado."
    else
        local missingCount = TOTAL_REQUIRED - collectedCount
        local missingNames: { string } = {}
        for _, part in ipairs(missingParts) do
            table.insert(missingNames, part.DisplayName)
        end
        statusMessage = string.format(
            "Faltan %d piezas para reparar el Cronos. Piezas faltantes: %s.",
            missingCount,
            table.concat(missingNames, ", ")
        )
    end

    return {
        CollectedCount = collectedCount,
        TotalRequired = TOTAL_REQUIRED,
        IsReady = isReady,
        MissingParts = missingParts,
        StatusMessage = statusMessage,
    }
end

--- Returns the list of missing repair components for a player.
function CarRepairInteractionSystem.GetMissingParts(player: Player): { MissingPartDetail }
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    return readiness.MissingParts
end

--- Returns only the canonical ObjectiveIds of missing components.
function CarRepairInteractionSystem.GetMissingPartIds(player: Player): { ObjectiveId }
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    local ids: { ObjectiveId } = {}
    for _, part in ipairs(readiness.MissingParts) do
        table.insert(ids, part.Id)
    end
    return ids
end

--- Returns whether the player has collected all 5 required components.
function CarRepairInteractionSystem.HasAllParts(player: Player): boolean
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    return readiness.IsReady
end

--- Returns the number of components collected by the player (0 to 5).
function CarRepairInteractionSystem.GetCollectedCount(player: Player): number
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    return readiness.CollectedCount
end

--- Returns the total number of components required (5).
function CarRepairInteractionSystem.GetTotalRequired(): number
    return TOTAL_REQUIRED
end

--- Returns the formatted status message for the player.
function CarRepairInteractionSystem.GetStatusMessage(player: Player): string
    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    return readiness.StatusMessage
end

--- Evaluates the player's progression state relative to the Fiat Cronos:
--- STATE 1 — "MissingParts": Missing one or more of the 5 canonical parts.
--- STATE 2 — "NeedsTool": All 5 parts collected, but lacks the mechanical toolbox.
--- STATE 3 — "ReadyToRepair": All 5 parts collected AND possesses the mechanical tool.
--- STATE 4 — "AlreadyRepaired": Player has already repaired the Cronos in this session.
function CarRepairInteractionSystem.GetPlayerInteractionState(player: Player): (InteractionState, string)
    if not player or not player:IsA("Player") then
        return "MissingParts", "Faltan piezas para reparar el Cronos."
    end

    local repairSystem = getCarRepairSystem()
    local isRepaired = false
    local hasTool = false

    if repairSystem then
        if typeof(repairSystem.HasRepairedCronos) == "function" then
            isRepaired = repairSystem.HasRepairedCronos(player)
        end
        if typeof(repairSystem.HasRepairTool) == "function" then
            hasTool = repairSystem.HasRepairTool(player)
        end
    end

    if isRepaired then
        return "AlreadyRepaired", "El Cronos ya está reparado. Ahora podemos escapar."
    end

    local readiness = CarRepairInteractionSystem.GetRepairReadiness(player)
    if not readiness.IsReady then
        return "MissingParts", readiness.StatusMessage
    end

    if not hasTool then
        return "NeedsTool", "Las 5 piezas están listas, pero necesitas herramientas mecánicas del Corralón. Busca la caja de herramientas en el Corralón Municipal."
    end

    return "ReadyToRepair", "Todo listo para reparar el Fiat Cronos."
end

--- Returns whether the player is fully eligible to repair the vehicle.
function CarRepairInteractionSystem.CanPlayerRepair(player: Player): boolean
    local state, _ = CarRepairInteractionSystem.GetPlayerInteractionState(player)
    return state == "ReadyToRepair"
end

--- Returns the active ProximityPrompt instance if created.
function CarRepairInteractionSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

--- Returns the active vehicle instance if resolved.
function CarRepairInteractionSystem.GetVehicle(): Instance?
    return activeVehicleInstance
end

--- Returns the target BasePart hosting the prompt if resolved.
function CarRepairInteractionSystem.GetTargetPart(): BasePart?
    return activeTargetPart
end

-- ----------------------------------------------------------------------------
-- PROMPT SETUP & LIFECYCLE
-- ----------------------------------------------------------------------------

--- Sets up exactly ONE ProximityPrompt on the existing Fiat Cronos.
--- Strictly guards against duplicate prompts and connection leaks.
function CarRepairInteractionSystem.SetupPrompt(): ProximityPrompt?
    -- If already created and parented properly, return existing prompt
    if activePrompt and activePrompt.Parent and activePrompt:IsDescendantOf(Workspace) then
        return activePrompt
    end

    local vehicle, targetPart = findExistingFiatCronos()
    if not targetPart then
        return nil
    end

    activeVehicleInstance = vehicle
    activeTargetPart = targetPart

    -- Guard against duplicate prompts on the target part or vehicle
    local existingPrompt = targetPart:FindFirstChild(PROMPT_NAME) :: ProximityPrompt?
    if not existingPrompt and vehicle then
        existingPrompt = vehicle:FindFirstChild(PROMPT_NAME, true) :: ProximityPrompt?
    end

    if existingPrompt and existingPrompt:IsA("ProximityPrompt") then
        activePrompt = existingPrompt

        -- Ensure properties adhere to the specification
        existingPrompt.ActionText = PROMPT_ACTION_TEXT
        existingPrompt.ObjectText = PROMPT_OBJECT_TEXT
        existingPrompt.HoldDuration = PROMPT_HOLD_DURATION
        existingPrompt.MaxActivationDistance = PROMPT_MAX_ACTIVATION_DISTANCE
        existingPrompt.RequiresLineOfSight = PROMPT_REQUIRES_LINE_OF_SIGHT
        existingPrompt.KeyboardKeyCode = Enum.KeyCode.E
        existingPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX

        if not promptTriggerConn then
            promptTriggerConn = existingPrompt.Triggered:Connect(handlePromptTriggered)
        end
        if not promptHoldBeganConn then
            promptHoldBeganConn = existingPrompt.PromptButtonHoldBegan:Connect(handlePromptHoldBegan)
        end
        if not promptHoldEndedConn then
            promptHoldEndedConn = existingPrompt.PromptButtonHoldEnded:Connect(handlePromptHoldEnded)
        end
        return existingPrompt
    end

    -- Create single, authoritative ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = PROMPT_NAME
    prompt.ActionText = PROMPT_ACTION_TEXT
    prompt.ObjectText = PROMPT_OBJECT_TEXT
    prompt.HoldDuration = PROMPT_HOLD_DURATION
    prompt.MaxActivationDistance = PROMPT_MAX_ACTIVATION_DISTANCE
    prompt.RequiresLineOfSight = PROMPT_REQUIRES_LINE_OF_SIGHT
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.ClickablePrompt = true -- Native mobile/touch tap support
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

    -- Parent to the chosen target part
    prompt.Parent = targetPart
    activePrompt = prompt

    -- Connect listeners
    promptTriggerConn = prompt.Triggered:Connect(handlePromptTriggered)
    promptHoldBeganConn = prompt.PromptButtonHoldBegan:Connect(handlePromptHoldBegan)
    promptHoldEndedConn = prompt.PromptButtonHoldEnded:Connect(handlePromptHoldEnded)

    return prompt
end

-- ----------------------------------------------------------------------------
-- INITIALIZATION
-- ----------------------------------------------------------------------------

--- Initializes the interaction system. Safe against duplicate calls.
--- Handles cases where the Fiat Cronos is generated dynamically after startup.
function CarRepairInteractionSystem.Initialize(): boolean
    if isInitialized then
        return true
    end
    isInitialized = true

    -- 1. Try to setup prompt immediately if vehicle already exists
    local prompt = CarRepairInteractionSystem.SetupPrompt()
    if prompt then
        return true
    end

    -- 2. If vehicle is not yet created, hook descendant addition to detect it when generated
    local descendantConn = Workspace.DescendantAdded:Connect(function(descendant: Instance)
        if not activePrompt then
            if descendant.Name == "FiatCronos"
                or descendant.Name == "Vehicle_FiatCronos"
                or descendant.Name == "TheFiatCronos"
            then
                task.defer(function()
                    CarRepairInteractionSystem.SetupPrompt()
                end)
            end
        end
    end)
    table.insert(systemConnections, descendantConn)

    -- 3. Also check EpecuenWorld directly if added
    local childAddedConn = Workspace.ChildAdded:Connect(function(child: Instance)
        if not activePrompt and child.Name == "EpecuenWorld" then
            task.defer(function()
                CarRepairInteractionSystem.SetupPrompt()
            end)
        end
    end)
    table.insert(systemConnections, childAddedConn)

    return true
end

--- Cleans up prompt, connections, and internal state.
function CarRepairInteractionSystem.Cleanup(): ()
    isInitialized = false

    if promptTriggerConn and promptTriggerConn.Connected then
        promptTriggerConn:Disconnect()
        promptTriggerConn = nil
    end

    if promptHoldBeganConn and promptHoldBeganConn.Connected then
        promptHoldBeganConn:Disconnect()
        promptHoldBeganConn = nil
    end

    if promptHoldEndedConn and promptHoldEndedConn.Connected then
        promptHoldEndedConn:Disconnect()
        promptHoldEndedConn = nil
    end

    for _, conn in ipairs(systemConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(systemConnections)

    if activePrompt then
        activePrompt:Destroy()
        activePrompt = nil
    end

    activeTargetPart = nil
    activeVehicleInstance = nil
end

-- Auto-initialize deferred on the server
task.defer(function()
    CarRepairInteractionSystem.Initialize()
end)

return CarRepairInteractionSystem
