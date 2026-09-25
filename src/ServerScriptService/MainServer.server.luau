--!strict
--[[
    MainServer.server.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/EpecuenServer/MainServer (Script)
    Description: Primary server bootstrap. Initializes networking, game services,
                 survival state managers, and environment safeguards.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

print("==================================================")
print("  EPECUÉN: NO ESCAPE — Server Initializing...   ")
print("==================================================")

-- Ensure shared packages are loaded
local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared", 15)
if not EpecuenShared then
    error("[MainServer] EpecuenShared not found in ReplicatedStorage!")
end

local EpecuenServer = ServerScriptService:WaitForChild("EpecuenServer")
local ServicesFolder = EpecuenServer:WaitForChild("Services")
local SanityService = require(ServicesFolder:WaitForChild("SanityService") :: ModuleScript)
local WaterHazardService = require(ServicesFolder:WaitForChild("WaterHazardService") :: ModuleScript)
local MonsterAIService = require(ServicesFolder:WaitForChild("MonsterAIService") :: ModuleScript)
local InteractionService = require(ServicesFolder:WaitForChild("InteractionService") :: ModuleScript)

-- Initialize core horror systems in order
SanityService.Init()
WaterHazardService.Init()
InteractionService.Init()
MonsterAIService.Init()

-- Setup baseline bleak Argentine pampas lighting
local function configureEnvironmentLighting()
    Lighting.ClockTime = 2.5 -- Night, but readable
    Lighting.Brightness = 2.0
    Lighting.OutdoorAmbient = Color3.fromRGB(85, 92, 105)
    Lighting.Ambient = Color3.fromRGB(70, 76, 88)
    Lighting.FogColor = Color3.fromRGB(55, 62, 72)
    Lighting.FogStart = 180
    Lighting.FogEnd = 800
    Lighting.GlobalShadows = false
    Lighting.ExposureCompensation = 0.4
end

configureEnvironmentLighting()

-- Initialize world map generation and vehicle progression systems
print("[EPECUEN] Initializing vehicle progression systems...")

local CarPartCollectionSystem = require(EpecuenServer:WaitForChild("CarPartCollectionSystem") :: ModuleScript)
CarPartCollectionSystem.Initialize()
print("[EPECUEN] CarPartCollectionSystem initialized")

local EpecuenMapGenerator = require(ServicesFolder:WaitForChild("EpecuenMapGenerator") :: ModuleScript)
EpecuenMapGenerator.Generate()
print("[EPECUEN] EpecuenMapGenerator generated")

-- Authoritative player spawn for Epecuén.
-- V4: disable Roblox's automatic character placement and load the character
-- only after the generated world exists. This prevents any other SpawnLocation
-- or default spawn behavior from putting the player below the map.
local SPAWN_POSITION = Vector3.new(-180, 23, -780)
local SPAWN_YAW = math.rad(180)
local SPAWN_PLATFORM_Y = 21

local function ensurePlayerSpawn(): SpawnLocation
    local existing = workspace:FindFirstChild("EpecuenPlayerSpawn")
    if existing and existing:IsA("SpawnLocation") then
        existing:Destroy()
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "EpecuenPlayerSpawn"
    spawn.CFrame = CFrame.new(SPAWN_POSITION.X, SPAWN_PLATFORM_Y, SPAWN_POSITION.Z)
    spawn.Size = Vector3.new(24, 1, 24)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.CanTouch = true
    spawn.CanQuery = true
    spawn.Transparency = 1
    spawn.Neutral = true
    spawn.AllowTeamChangeOnTouch = false
    spawn.Enabled = false
    spawn.Parent = workspace
    return spawn
end

local playerSpawn = ensurePlayerSpawn()

-- Do not let Roblox choose an old/default SpawnLocation.
Players.CharacterAutoLoads = false

local function placeCharacter(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root or not root:IsA("BasePart") then
        warn("[EPECUEN] Character components missing; cannot place player")
        return
    end

    local target = CFrame.new(SPAWN_POSITION) * CFrame.Angles(0, SPAWN_YAW, 0)
    character:PivotTo(target)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

    print(string.format("[EPECUEN] V4 SPAWN LOCKED: X=%.1f Y=%.1f Z=%.1f", SPAWN_POSITION.X, SPAWN_POSITION.Y, SPAWN_POSITION.Z))

    -- Re-assert the position after the character's physics/network ownership settles.
    for _, delayTime in ipairs({0.25, 0.75, 1.5}) do
        task.delay(delayTime, function()
            if character.Parent and root.Parent then
                character:PivotTo(target)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
end

local function setupPlayer(player: Player)
    player.RespawnLocation = nil

    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            placeCharacter(character)
        end)
    end)

    task.spawn(function()
        -- Give the generated map and server systems time to finish before loading the character.
        task.wait(0.5)
        if player.Parent and not player.Character then
            player:LoadCharacter()
        end
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

local CarRepairSystem = require(EpecuenServer:WaitForChild("CarRepairSystem") :: ModuleScript)
CarRepairSystem.Initialize()
print("[EPECUEN] CarRepairSystem initialized")

local CarRepairInteractionSystem = require(EpecuenServer:WaitForChild("CarRepairInteractionSystem") :: ModuleScript)
CarRepairInteractionSystem.Initialize()
print("[EPECUEN] CarRepairInteractionSystem initialized")

local EscapeSystem = require(EpecuenServer:WaitForChild("EscapeSystem") :: ModuleScript)
EscapeSystem.Initialize()
print("[EPECUEN] EscapeSystem initialized")

print("[EPECUEN] Vehicle progression systems ready")

print("[MainServer] EPECUÉN: NO ESCAPE server systems active and awaiting players.")
