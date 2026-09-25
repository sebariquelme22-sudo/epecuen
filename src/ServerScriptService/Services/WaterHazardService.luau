--!strict
--[[
    WaterHazardService.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/EpecuenServer/Services/WaterHazardService (ModuleScript)
    Description: Simulates the hypersaline brine of Laguna Epecuén:
                 High buoyancy, corrosive chemical burn over time, salt mud movement penalty,
                 and salt crystallization on clothing/skin.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local WaterHazardService = {}

type PlayerWaterState = {
    Exposure: number,       -- 0 to 100
    IsSubmerged: boolean,
    OriginalWalkSpeed: number,
}

local playerWaterStates: { [Player]: PlayerWaterState } = {}
local waterExposureChangedEvent: RemoteEvent

-- Raycast parameters to detect Laguna Epecuén water zones or tagged parts
local waterRayParams = RaycastParams.new()
waterRayParams.FilterType = Enum.RaycastFilterType.Include

function WaterHazardService.Init()
    waterExposureChangedEvent = NetworkBridge.GetEvent("WaterExposureChanged")

    Players.PlayerAdded:Connect(function(player)
        playerWaterStates[player] = {
            Exposure = 0,
            IsSubmerged = false,
            OriginalWalkSpeed = 16,
        }

        player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
            if hum then
                local st = playerWaterStates[player]
                if st then
                    st.OriginalWalkSpeed = hum.WalkSpeed
                end
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        playerWaterStates[player] = nil
    end)

    -- Update loop checking character elevation vs water level / water volume
    task.spawn(function()
        while true do
            local dt = task.wait(GameConfig.SALT_WATER.EXPOSURE_DAMAGE_TICK)
            WaterHazardService.Update(dt)
        end
    end)

    print("[WaterHazardService] Initialized for Laguna Epecuén.")
end

-- Checks if player is in brine water (either tagged CollectionService or below brine plane)
function WaterHazardService.CheckSubmerged(character: Model): boolean
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end

    -- Check water plane height or collection tag
    local waterZone = Workspace:FindFirstChild("LagunaEpecuenWater") :: BasePart?
    if waterZone then
        local waterTop = waterZone.Position.Y + (waterZone.Size.Y / 2)
        if hrp.Position.Y <= waterTop + 1.5 then
            return true
        end
    end

    -- Also check Terrain water if terrain is used
    local region = Region3.new(hrp.Position - Vector3.new(2, 2, 2), hrp.Position + Vector3.new(2, 2, 2))
    local material = Workspace.Terrain:ReadVoxels(region:ExpandToGrid(4), 4)[1][1][1]
    if material == Enum.Material.Water then
        return true
    end

    return false
end

function WaterHazardService.Update(dt: number)
    for player, state in pairs(playerWaterStates) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

            if hum and hum.Health > 0 and hrp then
                local inWater = WaterHazardService.CheckSubmerged(char)
                state.IsSubmerged = inWater

                if inWater then
                    -- Accumulate corrosive salt exposure
                    state.Exposure = math.clamp(state.Exposure + (7 * dt), 0, GameConfig.SALT_WATER.MAX_EXPOSURE)
                    
                    -- Movement slowdown in dense salt brine
                    hum.WalkSpeed = state.OriginalWalkSpeed * GameConfig.SALT_WATER.SLOW_DOWN_FACTOR

                    -- Apply corrosive caustic burn damage if exposure is high
                    if state.Exposure >= 50 then
                        local dmg = GameConfig.SALT_WATER.CORROSION_DAMAGE * (state.Exposure / 100)
                        hum:TakeDamage(dmg)
                    end
                else
                    -- Gradual drying / crystallization on land
                    if state.Exposure > 0 then
                        state.Exposure = math.clamp(state.Exposure - (2.5 * dt), 0, GameConfig.SALT_WATER.MAX_EXPOSURE)
                    end
                    hum.WalkSpeed = state.OriginalWalkSpeed
                end

                waterExposureChangedEvent:FireClient(player, state.Exposure, state.IsSubmerged)
            end
        end
    end
end

return WaterHazardService
