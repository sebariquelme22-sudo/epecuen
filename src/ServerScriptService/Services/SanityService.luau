--!strict
--[[
    SanityService.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/EpecuenServer/Services/SanityService (ModuleScript)
    Description: Authoritative psychological sanity tracking, paranoia deterioration,
                 and dynamic hallucination trigger dispatch for players.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local SanityTypes = require(EpecuenShared:WaitForChild("SanityTypes") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local SanityService = {}

type PlayerData = {
    Sanity: number,
    LastCheck: number,
    NextHallucinationTime: number,
    LastDizzinessTime: number,
    InDarkness: boolean,
    NearMonster: boolean,
}

local playerDataMap: { [Player]: PlayerData } = {}
local sanityEvent: RemoteEvent
local hallucinationEvent: RemoteEvent

function SanityService.Init()
    sanityEvent = NetworkBridge.GetEvent("SanityUpdated")
    hallucinationEvent = NetworkBridge.GetEvent("TriggerHallucination")

    Players.PlayerAdded:Connect(SanityService.OnPlayerAdded)
    Players.PlayerRemoving:Connect(SanityService.OnPlayerRemoving)

    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(SanityService.OnPlayerAdded, p)
    end

    -- Loop tick for sanity decay
    task.spawn(function()
        while true do
            local dt = task.wait(1.0)
            SanityService.UpdateAll(dt)
        end
    end)

    print("[SanityService] Initialized successfully.")
end

function SanityService.OnPlayerAdded(player: Player)
    playerDataMap[player] = {
        Sanity = 100,
        LastCheck = os.clock(),
        NextHallucinationTime = os.clock() + math.random(
            GameConfig.SANITY.HALLUCINATION_INTERVAL_MIN,
            GameConfig.SANITY.HALLUCINATION_INTERVAL_MAX
        ),
        LastDizzinessTime = 0.0,
        InDarkness = true,
        NearMonster = false,
    }
end

function SanityService.OnPlayerRemoving(player: Player)
    playerDataMap[player] = nil
end

function SanityService.SetInDarkness(player: Player, inDarkness: boolean)
    local data = playerDataMap[player]
    if data then
        data.InDarkness = inDarkness
    end
end

function SanityService.SetNearMonster(player: Player, near: boolean)
    local data = playerDataMap[player]
    if data then
        data.NearMonster = near
    end
end

function SanityService.ModifySanity(player: Player, delta: number, reason: string?)
    local data = playerDataMap[player]
    if not data then return end

    local oldSanity = data.Sanity
    data.Sanity = math.clamp(data.Sanity + delta, 0, GameConfig.SANITY.MAX_SANITY)

    if math.abs(oldSanity - data.Sanity) >= 0.5 or data.Sanity <= 0 then
        sanityEvent:FireClient(player, data.Sanity, reason or "Environmental")
    end
end

function SanityService.GetSanity(player: Player): number
    local data = playerDataMap[player]
    return data and data.Sanity or 100
end

function SanityService.UpdateAll(dt: number)
    local now = os.clock()

    for player, data in pairs(playerDataMap) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local decay = 0

                if data.InDarkness then
                    decay += GameConfig.SANITY.DARKNESS_DECAY_PER_SEC * dt
                else
                    decay -= GameConfig.SANITY.RECOVERY_RATE_LIGHT * dt
                end

                if data.NearMonster then
                    decay += GameConfig.SANITY.MONSTER_PROXIMITY_DECAY * dt
                end

                if decay ~= 0 then
                    SanityService.ModifySanity(player, -decay, "AmbientPsychology")
                end

                -- Low sanity hallucination triggers
                if data.Sanity < SanityTypes.SanityThresholds.Uneasy and now >= data.NextHallucinationTime then
                    SanityService.DispatchHallucination(player, data.Sanity)
                    local minWait = (data.Sanity < SanityTypes.SanityThresholds.Psychotic) and 4 or 9
                    local maxWait = (data.Sanity < SanityTypes.SanityThresholds.Psychotic) and 12 or 22
                    data.NextHallucinationTime = now + math.random(minWait, maxWait)
                end
            end
        end
    end
end

function SanityService.DispatchHallucination(player: Player, sanity: number)
    local data = playerDataMap[player]
    local possible: { SanityTypes.HallucinationType } = { "Whispers", "FakeFootsteps", "SubmergedBell" }
    
    if sanity < SanityTypes.SanityThresholds.Paranoid then
        table.insert(possible, "ShadowSpecter")
        table.insert(possible, "DisorientCamera")

        local now = os.clock()
        if data and (now - data.LastDizzinessTime >= 120.0) then
            table.insert(possible, "DizzinessSpecter")
            data.LastDizzinessTime = now
        end
    end

    if sanity < SanityTypes.SanityThresholds.Psychotic then
        table.insert(possible, "StaticVision")
        table.insert(possible, "MajorJumpscare")
    end

    local chosen = possible[math.random(1, #possible)]
    local duration = (chosen == "DizzinessSpecter") and 4.0 or math.random(3, 7)
    hallucinationEvent:FireClient(player, chosen, duration)
end

return SanityService
