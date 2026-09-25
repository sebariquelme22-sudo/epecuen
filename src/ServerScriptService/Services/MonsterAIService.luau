--!strict
--[[
    MonsterAIService.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/EpecuenServer/Services/MonsterAIService (ModuleScript)
    Description: AI Controller for "El Vigilante de la Sal" (The Salinized Stalker).
                 Features acoustic sound tracking, pathfinding, flashlight detection,
                 and stealth stalking behaviors through the ruins of Villa Epecuén.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local SanityTypes = require(EpecuenShared:WaitForChild("SanityTypes") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local MonsterAIService = {}

type EntityInstance = {
    Model: Model,
    Humanoid: Humanoid,
    RootPart: BasePart,
    State: SanityTypes.MonsterState,
    CurrentTarget: Player?,
    LastKnownTargetPos: Vector3?,
    InvestigatingUntil: number,
}

local activeMonsters: { EntityInstance } = {}
local noiseProducedEvent: RemoteEvent

function MonsterAIService.Init()
    noiseProducedEvent = NetworkBridge.GetEvent("NoiseProduced")

    -- Listen for player noise (footsteps on salt, flashlight clicks, doors)
    noiseProducedEvent.OnServerEvent:Connect(function(player: Player, originPos: any, radius: any, noiseType: any)
        if typeof(originPos) == "Vector3" and typeof(radius) == "number" then
            MonsterAIService.OnSoundHeard(player, originPos, radius, tostring(noiseType))
        end
    end)

    -- Auto-register any existing monster in Workspace or spawners
    local monsterFolder = Workspace:FindFirstChild("Monsters")
    if monsterFolder then
        for _, child in ipairs(monsterFolder:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                MonsterAIService.RegisterMonster(child)
            end
        end
    end

    task.spawn(MonsterAIService.MainLoop)
    print("[MonsterAIService] El Vigilante de la Sal AI initialized.")
end

function MonsterAIService.RegisterMonster(model: Model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?

    if hum and hrp then
        hum.WalkSpeed = GameConfig.MONSTER.DEFAULT_WALK_SPEED
        hum.MaxHealth = 10000
        hum.Health = 10000

        local entry: EntityInstance = {
            Model = model,
            Humanoid = hum,
            RootPart = hrp,
            State = "Dormant",
            CurrentTarget = nil,
            LastKnownTargetPos = nil,
            InvestigatingUntil = 0,
        }

        table.insert(activeMonsters, entry)
        print(`[MonsterAIService] Registered entity: {model.Name}`)
    end
end

function MonsterAIService.OnSoundHeard(sourcePlayer: Player, originPos: Vector3, radius: number, noiseType: string)
    for _, entity in ipairs(activeMonsters) do
        local dist = (entity.RootPart.Position - originPos).Magnitude
        if dist <= radius + GameConfig.MONSTER.HEARING_RADIUS then
            -- Monster heard the acoustic sound wave
            if entity.State ~= "Charging" then
                entity.State = "InvestigatingSound"
                entity.LastKnownTargetPos = originPos
                entity.InvestigatingUntil = os.clock() + 10
                entity.Humanoid.WalkSpeed = GameConfig.MONSTER.DEFAULT_WALK_SPEED * 1.2

                print(`[MonsterAIService] Sound heard ({noiseType}) at dist {math.floor(dist)}. Investigating...`)
            end
        end
    end
end

function MonsterAIService.MainLoop()
    while true do
        local dt = task.wait(0.3)
        for _, entity in ipairs(activeMonsters) do
            if entity.Model.Parent and entity.Humanoid.Health > 0 then
                MonsterAIService.UpdateEntity(entity, dt)
            end
        end
    end
end

function MonsterAIService.UpdateEntity(entity: EntityInstance, dt: number)
    local myPos = entity.RootPart.Position
    local closestPlayer: Player? = nil
    local closestDist = math.huge
    local canSee = false

    -- Check all nearby players
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                    
                    -- Sight / Vision Cone Raycast check
                    if dist <= GameConfig.MONSTER.SIGHT_RANGE then
                        local toTarget = (hrp.Position - myPos).Unit
                        local lookDir = entity.RootPart.CFrame.LookVector
                        local dot = lookDir:Dot(toTarget)
                        local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))

                        if angle <= (GameConfig.MONSTER.FIELD_OF_VIEW_DEG / 2) then
                            -- Perform raycast obstacle check
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = { entity.Model }
                            params.FilterType = Enum.RaycastFilterType.Exclude

                            local rayResult = Workspace:Raycast(myPos, hrp.Position - myPos, params)
                            if rayResult and rayResult.Instance:IsDescendantOf(char) then
                                canSee = true
                            end
                        end
                    end
                end
            end
        end
    end

    -- State Machine
    if canSee and closestPlayer and closestPlayer.Character then
        entity.State = "Charging"
        entity.CurrentTarget = closestPlayer
        entity.Humanoid.WalkSpeed = GameConfig.MONSTER.CHASE_WALK_SPEED

        local targetHrp = closestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if targetHrp then
            entity.Humanoid:MoveTo(targetHrp.Position)

            -- Kill trigger
            if closestDist <= GameConfig.MONSTER.KILL_DISTANCE then
                local targetHum = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
                if targetHum then
                    targetHum:TakeDamage(100)
                    local diedEvent = NetworkBridge.GetEvent("PlayerDiedHorror")
                    diedEvent:FireClient(closestPlayer, "Consumed by El Vigilante de la Sal")
                end
            end
        end

    elseif entity.State == "InvestigatingSound" and entity.LastKnownTargetPos then
        local distToSound = (entity.RootPart.Position - entity.LastKnownTargetPos).Magnitude
        if distToSound <= 5 or os.clock() > entity.InvestigatingUntil then
            entity.State = "Stalking"
            entity.LastKnownTargetPos = nil
        else
            entity.Humanoid:MoveTo(entity.LastKnownTargetPos)
        end

    else
        -- Idle / Stalking roam near ruins
        entity.State = "Stalking"
        entity.Humanoid.WalkSpeed = GameConfig.MONSTER.DEFAULT_WALK_SPEED
    end
end

return MonsterAIService
