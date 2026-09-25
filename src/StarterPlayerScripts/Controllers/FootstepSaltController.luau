--!strict
--[[
    FootstepSaltController.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/EpecuenClient/Controllers/FootstepSaltController (ModuleScript)
    Description: Plays atmospheric surface footsteps (brittle white salt crust, toxic brine mud,
                 cracked concrete) and sends acoustic signatures to the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local FootstepSaltController = {}
local noiseEvent: RemoteEvent
local lastStepTime = 0

function FootstepSaltController.Init()
    noiseEvent = NetworkBridge.GetEvent("NoiseProduced")

    LocalPlayer.CharacterAdded:Connect(FootstepSaltController.OnCharacterAdded)
    if LocalPlayer.Character then
        FootstepSaltController.OnCharacterAdded(LocalPlayer.Character)
    end

    print("[FootstepSaltController] Acoustic ground reaction system active.")
end

function FootstepSaltController.OnCharacterAdded(character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

    -- Listen for animation footstep events or humanoid state movement
    humanoid.Running:Connect(function(speed)
        if speed > 2 then
            local now = os.clock()
            local interval = (speed > 18) and 0.32 or 0.52 -- Sprint vs Walk cadence

            if now - lastStepTime >= interval then
                lastStepTime = now
                FootstepSaltController.PlayStepSound(hrp.Position, speed)
            end
        end
    end)
end

function FootstepSaltController.PlayStepSound(pos: Vector3, speed: number)
    -- Raycast down to find ground material
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = Workspace:Raycast(pos, Vector3.new(0, -4, 0), params)
    local mat = result and result.Material or Enum.Material.Sand
    local isSalt = (mat == Enum.Material.Sand or mat == Enum.Material.Concrete or mat == Enum.Material.Rock)
    local isWater = (mat == Enum.Material.Water)

    local noiseRadius = GameConfig.NOISE.NORMAL_WALK
    if speed > 18 then
        noiseRadius = GameConfig.NOISE.SPRINT
    end

    if isSalt then
        noiseRadius *= GameConfig.NOISE.SALT_CRUNCH_BOOST
    elseif isWater then
        noiseRadius *= GameConfig.NOISE.WATER_SPLASH_BOOST
    end

    -- Fire to server for monster hearing
    noiseEvent:FireServer(pos, noiseRadius, isWater and "WaterSplash" or "SaltCrunch")
end

return FootstepSaltController
