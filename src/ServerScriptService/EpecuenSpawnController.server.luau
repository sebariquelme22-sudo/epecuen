--!strict
-- EPECUEN: NO ESCAPE - authoritative character spawn + anti-fall safeguard
-- Keeps the player on the real northern access road and recovers only from
-- an actual fall-through/abyss condition. It does not teleport the player
-- during normal movement.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local services = ServerScriptService:WaitForChild("EpecuenServer"):WaitForChild("Services")
local specification = require(services:WaitForChild("EpecuenMapSpecification") :: ModuleScript)

local spawnSpec = specification.PlayerSpawn
local targetPosition = Vector3.new(
    spawnSpec.Position.X,
    spawnSpec.Position.Y + 3.0,
    spawnSpec.Position.Z
)
local targetCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, math.rad(spawnSpec.FacingAngleY or 170), 0)

local function placeCharacter(character: Model)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        root = character:WaitForChild("HumanoidRootPart", 10)
    end
    if not root or not root:IsA("BasePart") then return end

    character:PivotTo(targetCFrame)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function handleCharacter(character: Model)
    task.defer(function()
        -- Only protect the initial placement. After this, the player is free
        -- to walk/run normally without being repeatedly teleported.
        for _ = 1, 6 do
            if character.Parent == nil then return end
            placeCharacter(character)
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root or not root:IsA("BasePart") then return end

        while character.Parent do
            task.wait(0.25)
            if not root.Parent then return end

            local p = root.Position
            -- Northern access road: if the player falls through the road and
            -- reaches the low terrain level, restore the canonical start.
            local onNorthAccess = p.X >= -780 and p.X <= 880 and p.Z >= -775 and p.Z <= -725
            local deepFall = p.Y < -25
            if (onNorthAccess and p.Y < 10) or deepFall then
                warn(string.format("[EPECUEN] Fall-through detected at X=%.1f Y=%.1f Z=%.1f; restoring spawn", p.X, p.Y, p.Z))
                placeCharacter(character)
                task.wait(0.5)
            end
        end
    end)
end

local function handlePlayer(player: Player)
    player.CharacterAdded:Connect(handleCharacter)
    if player.Character then handleCharacter(player.Character) end
end

Players.PlayerAdded:Connect(handlePlayer)
for _, player in Players:GetPlayers() do handlePlayer(player) end

-- EPECUEN: NO ESCAPE - authoritative character spawn safeguard
-- Keeps the player at the canonical Epecuen spawn even if Roblox's default spawn system
-- creates the character at the template origin.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local services = ServerScriptService:WaitForChild("EpecuenServer"):WaitForChild("Services")
local specification = require(services:WaitForChild("EpecuenMapSpecification") :: ModuleScript)

local spawnSpec = specification.PlayerSpawn
local targetPosition = Vector3.new(
    spawnSpec.Position.X,
    spawnSpec.Position.Y + 3.0,
    spawnSpec.Position.Z
)
local targetCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, math.rad(spawnSpec.FacingAngleY or 170), 0)

local function placeCharacter(character: Model)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        root = character:WaitForChild("HumanoidRootPart", 10)
    end
    if not root or not root:IsA("BasePart") then
        return
    end

    character:PivotTo(targetCFrame)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function handleCharacter(character: Model)
    task.defer(function()
        -- Roblox can apply its default SpawnLocation after CharacterAdded.
        -- Re-assert the canonical position during the first seconds only.
        for _ = 1, 6 do
            if character.Parent == nil then
                return
            end
            placeCharacter(character)
            task.wait(0.5)
        end
    end)
end

local function handlePlayer(player: Player)
    player.CharacterAdded:Connect(handleCharacter)
    if player.Character then
        handleCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(handlePlayer)
for _, player in Players:GetPlayers() do
    handlePlayer(player)
end
