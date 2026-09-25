--!strict
-- ============================================================================
-- PlayerPersistenceSystem.luau
-- Location: roblox/src/ServerScriptService/PlayerPersistenceSystem.luau
--
-- EPECUÉN: NO ESCAPE - Secure Player Meta Persistence System
--
-- PURPOSE:
-- Server-authoritative system managing persistent meta data for players
-- (Completed runs, victories, tutorial state) via DataStoreService.
-- Never saves active gameplay progress (parts, obstacles, car repair state).
-- ============================================================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerPersistenceSystem = {}

export type PlayerData = {
    CompletedRuns: number,
    Victories: number,
    TutorialCompleted: boolean,
    LastSaveTimestamp: number,
}

local DATASTORE_NAME = "EpecuenPlayerMeta_v1"
local dataStore = pcall(function()
    return DataStoreService:GetDataStore(DATASTORE_NAME)
end)

local playerDataCache: { [Player]: PlayerData } = {}

local DEFAULT_DATA: PlayerData = {
    CompletedRuns = 0,
    Victories = 0,
    TutorialCompleted = false,
    LastSaveTimestamp = 0,
}

local function getSavedKey(player: Player): string
    return "Player_" .. tostring(player.UserId)
end

local function loadPlayerData(player: Player): PlayerData
    if not player or not player:IsDescendantOf(Players) then
        return table.clone(DEFAULT_DATA)
    end

    local data = table.clone(DEFAULT_DATA)
    if typeof(dataStore) ~= "userdata" and typeof(dataStore) ~= "table" then
        -- DataStoreService failed or restricted in Studio without API access
        playerDataCache[player] = data
        return data
    end

    local store = DataStoreService:GetDataStore(DATASTORE_NAME)
    local key = getSavedKey(player)

    local success, result = pcall(function()
        return store:GetAsync(key)
    end)

    if success and type(result) == "table" then
        if type(result.CompletedRuns) == "number" then data.CompletedRuns = result.CompletedRuns end
        if type(result.Victories) == "number" then data.Victories = result.Victories end
        if type(result.TutorialCompleted) == "boolean" then data.TutorialCompleted = result.TutorialCompleted end
        if type(result.LastSaveTimestamp) == "number" then data.LastSaveTimestamp = result.LastSaveTimestamp end
    elseif not success then
        warn("[EPECUÉN] Failed to load DataStore for player " .. player.Name .. ": " .. tostring(result))
    end

    playerDataCache[player] = data
    return data
end

local function savePlayerData(player: Player): boolean
    local data = playerDataCache[player]
    if not data then return false end

    local store = DataStoreService:GetDataStore(DATASTORE_NAME)
    local key = getSavedKey(player)
    data.LastSaveTimestamp = os.time()

    local success, err = pcall(function()
        store:SetAsync(key, data)
    end)

    if not success then
        warn("[EPECUÉN] Failed to save DataStore for player " .. player.Name .. ": " .. tostring(err))
        return false
    end

    return true
end

function PlayerPersistenceSystem.GetData(player: Player): PlayerData?
    return playerDataCache[player]
end

function PlayerPersistenceSystem.RecordVictory(player: Player): ()
    local data = playerDataCache[player]
    if not data then
        data = loadPlayerData(player)
    end
    data.Victories += 1
    data.CompletedRuns += 1
    savePlayerData(player)
end

function PlayerPersistenceSystem.SetTutorialCompleted(player: Player, completed: boolean): ()
    local data = playerDataCache[player]
    if not data then
        data = loadPlayerData(player)
    end
    data.TutorialCompleted = completed
    savePlayerData(player)
end

function PlayerPersistenceSystem.Initialize(): ()
    Players.PlayerAdded:Connect(function(player)
        loadPlayerData(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        savePlayerData(player)
        playerDataCache[player] = nil
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                savePlayerData(player)
            end)
        end
    end)
end

task.defer(function()
    PlayerPersistenceSystem.Initialize()
end)

return PlayerPersistenceSystem
