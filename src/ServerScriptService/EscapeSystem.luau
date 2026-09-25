--!strict
-- ============================================================================
-- EscapeSystem.luau
-- Location: roblox/src/ServerScriptService/EscapeSystem.luau
--
-- EPECUÉN: NO ESCAPE - Final Escape Sequence & Victory System
--
-- PURPOSE:
-- Server-authoritative system managing the final escape sequence after the
-- Fiat Cronos has been successfully repaired (RepairReady == true).
--
-- BEHAVIOR:
--   1. Monitors CarRepairSystem.IsCronosRepairReady() and active Cronos instance.
--   2. Adds an authoritative ProximityPrompt to the Fiat Cronos ("Escapar de Epecuén")
--      once RepairReady == true.
--   3. Manages per-player escape state: NORMAL -> REPAIRED -> ESCAPING -> ESCAPED.
--   4. Validates escape trigger server-authoritatively (requires RepairReady == true).
--   5. Monitors player distance to the northern exit point (Acceso Norte: Vector3.new(-160, 19, -920)).
--   6. Grants victory status on reaching the exit point while ESCAPING.
--   7. Fires toast notifications via NetworkBridge / InteractCompleted.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EscapeSystem = {}

export type EscapeState = "NORMAL" | "REPAIRED" | "ESCAPING" | "ESCAPED"

local PROMPT_NAME = "CronosEscapePrompt"
local ACTION_TEXT = "Escapar de Epecuén"
local OBJECT_TEXT = "Fiat Cronos Reparado"
local HOLD_DURATION = 1.0
local MAX_DISTANCE = 12.0

-- Northern exit point representing escape back to Carhué
local EXIT_POSITION = Vector3.new(-160, 19, -920)
local EXIT_RADIUS = 35.0

local isInitialized = false
local playerEscapeState: { [Player]: EscapeState } = {}
local activeEscapePrompt: ProximityPrompt? = nil
local escapeTriggerConn: RBXScriptConnection? = nil
local heartbeatConn: RBXScriptConnection? = nil
local systemConnections: { RBXScriptConnection } = {}

local escapeEvent = Instance.new("BindableEvent")
EscapeSystem.OnPlayerEscaped = escapeEvent.Event

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

local function getNetworkBridge(): any
    local direct = ReplicatedStorage:FindFirstChild("NetworkBridge")
    if direct and direct:IsA("ModuleScript") then
        local success, mod = pcall(require, direct)
        if success then return mod end
    end
    local sharedFolder = ReplicatedStorage:FindFirstChild("EpecuenShared")
    if sharedFolder and sharedFolder:FindFirstChild("NetworkBridge") then
        local mod = sharedFolder:FindFirstChild("NetworkBridge")
        if mod and mod:IsA("ModuleScript") then
            local success, res = pcall(require, mod)
            if success then return res end
        end
    end
    local found = ReplicatedStorage:FindFirstChild("NetworkBridge", true)
    if found and found:IsA("ModuleScript") then
        local success, res = pcall(require, found)
        if success then return res end
    end
    return nil
end

local function notifyPlayer(player: Player, success: boolean, message: string)
    local target = Workspace
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
    local remotes = ReplicatedStorage:FindFirstChild("EpecuenRemotes")
    if remotes then
        local interactEv = remotes:FindFirstChild("InteractCompleted")
        if interactEv and interactEv:IsA("RemoteEvent") then
            interactEv:FireClient(player, target, success, message)
        end
    end
end

local function findCronosAnchor(): BasePart?
    local cronos = Workspace:FindFirstChild("FiatCronos", true) or Workspace:FindFirstChild("TheFiatCronos", true)
    if cronos then
        if cronos:IsA("BasePart") then return cronos end
        if cronos:IsA("Model") then
            local hood = cronos:FindFirstChild("Hood_Main", true)
            if hood and hood:IsA("BasePart") then return hood end
            if cronos.PrimaryPart then return cronos.PrimaryPart end
            return cronos:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    local marker = Workspace:FindFirstChild("Vehicle_FiatCronos", true)
    if marker then
        if marker:IsA("BasePart") then return marker end
        if marker:IsA("Model") then
            if marker.PrimaryPart then return marker.PrimaryPart end
            return marker:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    return nil
end

local function handleEscapeTriggered(player: Player)
    if not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then
        return
    end

    local repairSystem = getCarRepairSystem()
    local isReady = false
    if repairSystem and typeof(repairSystem.IsCronosRepairReady) == "function" then
        isReady = repairSystem.IsCronosRepairReady()
    else
        local cronos, _ = findCronosAnchor()
        if cronos and cronos:GetAttribute("RepairReady") == true then
            isReady = true
        end
    end

    if not isReady then
        notifyPlayer(player, false, "El Fiat Cronos aún no está reparado. Necesitas las 5 piezas y la caja de herramientas.")
        return
    end

    local currentState = playerEscapeState[player] or "NORMAL"
    if currentState == "ESCAPED" then
        notifyPlayer(player, true, "¡Ya has escapado de Epecuén con éxito!")
        return
    end

    if currentState == "ESCAPING" then
        notifyPlayer(player, true, "Ya estás en plena huida. ¡Conduce hacia la salida norte (Acceso Carhué)!")
        return
    end

    -- Initiate escape phase
    playerEscapeState[player] = "ESCAPING"
    notifyPlayer(player, true, "¡Has iniciado la huida de Epecuén! Conduce hacia la salida norte por la Ruta de Acceso.")
end

local function setupEscapePrompt(): boolean
    local anchor = findCronosAnchor()
    if not anchor then return false end

    local existing = anchor:FindFirstChild(PROMPT_NAME) :: ProximityPrompt?
    if existing and existing:IsA("ProximityPrompt") then
        activeEscapePrompt = existing
    else
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = PROMPT_NAME
        prompt.ActionText = ACTION_TEXT
        prompt.ObjectText = OBJECT_TEXT
        prompt.HoldDuration = HOLD_DURATION
        prompt.MaxActivationDistance = MAX_DISTANCE
        prompt.RequiresLineOfSight = true
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.ClickablePrompt = true
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
        prompt.Parent = anchor
        activeEscapePrompt = prompt
    end

    if activeEscapePrompt then
        if escapeTriggerConn and escapeTriggerConn.Connected then
            escapeTriggerConn:Disconnect()
        end
        escapeTriggerConn = activeEscapePrompt.Triggered:Connect(handleEscapeTriggered)
        return true
    end

    return false
end

function EscapeSystem.GetPlayerState(player: Player): EscapeState
    return playerEscapeState[player] or "NORMAL"
end

function EscapeSystem.Initialize(): boolean
    if isInitialized then return true end
    isInitialized = true

    -- Check periodically if repair is ready to enable prompt
    local _checkConn = task.spawn(function()
        while isInitialized do
            task.wait(2)
            local repairSystem = getCarRepairSystem()
            local isReady = false
            if repairSystem and typeof(repairSystem.IsCronosRepairReady) == "function" then
                isReady = repairSystem.IsCronosRepairReady()
            end
            if isReady then
                setupEscapePrompt()
            end
        end
    end)

    -- Heartbeat loop to verify distance to exit point for ESCAPING players
    heartbeatConn = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            local state = playerEscapeState[player]
            if state == "ESCAPING" then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart") :: BasePart
                    if hrp then
                        local dist = (hrp.Position - EXIT_POSITION).Magnitude
                        if dist <= EXIT_RADIUS then
                            playerEscapeState[player] = "ESCAPED"
                            notifyPlayer(player, true, "¡Has escapado con éxito de Epecuén! Sobreviviste al terror y a la salmuera.")
                            escapeEvent:Fire(player)
                        end
                    end
                end
            end
        end
    end)

    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
        playerEscapeState[player] = nil
    end)
    table.insert(systemConnections, playerRemovingConn)

    return true
end

function EscapeSystem.Cleanup(): ()
    isInitialized = false
    if escapeTriggerConn and escapeTriggerConn.Connected then
        escapeTriggerConn:Disconnect()
        escapeTriggerConn = nil
    end
    if heartbeatConn and heartbeatConn.Connected then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    for _, conn in ipairs(systemConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(systemConnections)
    if activeEscapePrompt then
        activeEscapePrompt:Destroy()
        activeEscapePrompt = nil
    end
    table.clear(playerEscapeState)
end

task.defer(function()
    EscapeSystem.Initialize()
end)

return EscapeSystem
