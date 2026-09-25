--!strict
--[[
    NetworkBridge.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ReplicatedStorage/EpecuenShared/NetworkBridge (ModuleScript)
    Description: Type-safe, centralized network layer creating and dispatching
                 RemoteEvents/RemoteFunctions between Server and Client.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkBridge = {}

local REMOTE_EVENT_NAMES = {
    "SanityUpdated",        -- S -> C (Player, newSanity: number, reason: string?)
    "TriggerHallucination", -- S -> C (Player, type: string, duration: number)
    "WaterExposureChanged", -- S -> C (Player, exposure: number, inWater: boolean)
    "FlashlightToggled",    -- C -> S (state: boolean) & S -> AllClients (sound & visual replica)
    "NoiseProduced",        -- C -> S (originPos: Vector3, radius: number, noiseType: string)
    "EntityAlerted",        -- S -> C (targetPos: Vector3)
    "InteractRequested",    -- C -> S (targetObject: Instance)
    "InteractCompleted",    -- S -> C (targetObject: Instance, success: boolean, message: string?)
    "PlayerDiedHorror",     -- S -> C (deathReason: string)
}

local REMOTE_FUNCTION_NAMES = {
    "GetPlayerSurvivalState", -- C -> S () -> PlayerSurvivalState
}

local remotesFolder: Folder

local function initRemotesFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("EpecuenRemotes")
    if not folder then
        if RunService:IsServer() then
            folder = Instance.new("Folder")
            folder.Name = "EpecuenRemotes"
            folder.Parent = ReplicatedStorage

            for _, name in ipairs(REMOTE_EVENT_NAMES) do
                local rem = Instance.new("RemoteEvent")
                rem.Name = name
                rem.Parent = folder
            end

            for _, name in ipairs(REMOTE_FUNCTION_NAMES) do
                local rf = Instance.new("RemoteFunction")
                rf.Name = name
                rf.Parent = folder
            end
        else
            -- Client waits for server to create the folder
            folder = ReplicatedStorage:WaitForChild("EpecuenRemotes", 15) :: Folder
            if not folder then
                error("[NetworkBridge] Failed to find EpecuenRemotes folder within timeout!")
            end
        end
    end
    return folder :: Folder
end

remotesFolder = initRemotesFolder()

function NetworkBridge.GetEvent(name: string): RemoteEvent
    local ev = remotesFolder:WaitForChild(name, 5)
    if not ev or not ev:IsA("RemoteEvent") then
        error(`[NetworkBridge] Event '{name}' not found in Remotes folder!`)
    end
    return ev :: RemoteEvent
end

function NetworkBridge.GetFunction(name: string): RemoteFunction
    local rf = remotesFolder:WaitForChild(name, 5)
    if not rf or not rf:IsA("RemoteFunction") then
        error(`[NetworkBridge] Function '{name}' not found in Remotes folder!`)
    end
    return rf :: RemoteFunction
end

return NetworkBridge
