--!strict
--[[
    ParanormalEncounterController.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/Controllers/ParanormalEncounterController.luau

    Description:
        Manages the first paranormal encounter, sporadic secondary psychological
        manifestations, rare close-range jumpscare encounters, following presence tracker,
        immersive Paranormal Pressure Zones, and subtle transient paranormal traces
        for the local player during exploration.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ParanormalEncounterController = {}

local hasTriggeredFirst = false
local isEncounterActive = false
local triggerPosition = Vector3.new(65, 3, -75)
local triggerRadius = 22
local timeSinceLastEncounter = 0.0
local minSafetyCooldown = 35.0 -- minimum seconds between secondary encounters
local hasExperiencedJumpscare = false
local jumpscareCooldown = 120.0 -- very long cooldown for jumpscares

-- Paranormal Pressure Zones configuration (no UI, purely immersive horror pacing)
local PRESSURE_ZONES = {
    { name = "HotelMonteReal", center = Vector3.new(0, 3, -120), radius = 38 },
    { name = "Matadero", center = Vector3.new(-100, 3, 50), radius = 38 },
    { name = "Darsena", center = Vector3.new(120, 3, 80), radius = 38 },
    { name = "Cementerio", center = Vector3.new(-80, 3, -100), radius = 38 },
    { name = "RuinasCentrales", center = Vector3.new(40, 3, 40), radius = 38 },
}

local timeInsideActiveZone = 0.0
local currentActiveZoneName: string? = nil
local zoneAmbientSound: Sound? = nil

function ParanormalEncounterController.Init()
    -- Background monitoring task
    task.spawn(function()
        while true do
            task.wait(1.0)
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                continue
            end

            local hrp = LocalPlayer.Character.HumanoidRootPart :: BasePart
            local playerPos = hrp.Position

            -- Check Pressure Zones
            local matchedZone: { name: string, center: Vector3, radius: number }? = nil
            for _, zone in ipairs(PRESSURE_ZONES) do
                if (playerPos - zone.center).Magnitude <= zone.radius then
                    matchedZone = zone
                    break
                end
            end

            if matchedZone then
                if currentActiveZoneName ~= matchedZone.name then
                    currentActiveZoneName = matchedZone.name
                    timeInsideActiveZone = 0.0
                else
                    timeInsideActiveZone += 1.0
                    ParanormalEncounterController.EvaluateZonePressure(hrp, timeInsideActiveZone)
                end
            else
                if currentActiveZoneName ~= nil then
                    -- Left zone: decay pressure / clean up zone atmosphere
                    currentActiveZoneName = nil
                    timeInsideActiveZone = math.max(0.0, timeInsideActiveZone - 5.0)
                    if zoneAmbientSound then
                        zoneAmbientSound:Destroy()
                        zoneAmbientSound = nil
                    end
                end
            end

            -- First encounter check
            if not hasTriggeredFirst then
                local dist = (playerPos - triggerPosition).Magnitude
                if dist <= triggerRadius then
                    hasTriggeredFirst = true
                    ParanormalEncounterController.ExecuteFirstEncounter(playerPos)
                    timeSinceLastEncounter = 0.0
                end
            else
                -- Secondary, Jumpscare, and Following Presence encounters loop
                if not isEncounterActive then
                    timeSinceLastEncounter += 1.0
                    if timeSinceLastEncounter >= minSafetyCooldown then
                        -- Rare Jumpscare check
                        if hasTriggeredFirst and (timeSinceLastEncounter >= jumpscareCooldown) and (math.random() < 0.04) then
                            isEncounterActive = true
                            timeSinceLastEncounter = 0.0
                            hasExperiencedJumpscare = true
                            ParanormalEncounterController.ExecuteJumpscareEncounter(hrp)
                        -- Following Presence check (after jumpscare experienced)
                        elseif hasExperiencedJumpscare and (math.random() < 0.08) then
                            isEncounterActive = true
                            timeSinceLastEncounter = 0.0
                            ParanormalEncounterController.ExecuteFollowingPresence(hrp)
                        elseif math.random() < 0.15 then
                            isEncounterActive = true
                            timeSinceLastEncounter = 0.0
                            ParanormalEncounterController.ExecuteSecondaryEncounter(hrp)
                        end
                    end
                end
            end
        end
    end)

    print("[ParanormalEncounterController] Paranormal encounter system armed (Traces active).")
end

function ParanormalEncounterController.EvaluateZonePressure(hrp: BasePart, timeInside: number)
    if timeInside == 12 then
        -- Phase 2: Inquietud (Subtle ambient sound)
        if not zoneAmbientSound or not zoneAmbientSound.Parent then
            zoneAmbientSound = Instance.new("Sound")
            zoneAmbientSound.SoundId = "rbxassetid://9114251234"
            zoneAmbientSound.Volume = 0.25
            zoneAmbientSound.Looped = true
            zoneAmbientSound.Parent = SoundService
            zoneAmbientSound:Play()
        end
    elseif timeInside == 28 then
        -- Phase 3: Presencia / Tensión sonora y ligera anomalía visual
        local origBrightness = Lighting.Brightness
        Lighting.Brightness = math.max(0.1, origBrightness - 0.2)
        task.delay(4.0, function()
            Lighting.Brightness = origBrightness
        end)
    elseif timeInside == 45 then
        -- Phase 4: Advertencia (Fuerte manifestación paranormal local, luego presión disminuye)
        if not isEncounterActive then
            isEncounterActive = true
            ParanormalEncounterController.ExecuteSecondaryEncounter(hrp)
        end
        -- Reset zone timer to allow pressure reduction / cycle
        timeInsideActiveZone = 5.0
    end
end

function ParanormalEncounterController.SpawnSilhouette(cframe: CFrame): (Model, Part, Part, Part, Part)
    local model = Instance.new("Model")
    model.Name = "ParanormalSilhouette"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 3, 1)
    torso.CFrame = cframe + Vector3.new(0, 1.5, 0)
    torso.Anchored = true
    torso.CanCollide = false
    torso.Material = Enum.Material.SmoothPlastic
    torso.Color = Color3.fromRGB(15, 15, 18)
    torso.Transparency = 1
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.1, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(15, 15, 18)
    head.Transparency = 1
    head.Parent = model

    local leftEye = Instance.new("Part")
    leftEye.Size = Vector3.new(0.15, 0.1, 0.1)
    leftEye.CFrame = head.CFrame * CFrame.new(-0.25, 0.1, -0.6)
    leftEye.Anchored = true
    leftEye.CanCollide = false
    leftEye.Material = Enum.Material.Neon
    leftEye.Color = Color3.fromRGB(220, 230, 240)
    leftEye.Transparency = 1
    leftEye.Parent = model

    local rightEye = Instance.new("Part")
    rightEye.Size = Vector3.new(0.15, 0.1, 0.1)
    rightEye.CFrame = head.CFrame * CFrame.new(0.25, 0.1, -0.6)
    rightEye.Anchored = true
    rightEye.CanCollide = false
    rightEye.Material = Enum.Material.Neon
    rightEye.Color = Color3.fromRGB(220, 230, 240)
    rightEye.Transparency = 1
    rightEye.Parent = model

    model.Parent = Workspace
    return model, torso, head, leftEye, rightEye
end

function ParanormalEncounterController.VanishSilhouette(model: Model, torso: Part, head: Part, leftEye: Part, rightEye: Part, hrp: BasePart?)
    local fadeOutInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(torso, fadeOutInfo, {Transparency = 1}):Play()
    TweenService:Create(head, fadeOutInfo, {Transparency = 1}):Play()
    TweenService:Create(leftEye, fadeOutInfo, {Transparency = 1}):Play()
    TweenService:Create(rightEye, fadeOutInfo, {Transparency = 1}):Play()

    task.delay(0.7, function()
        if model then
            local pos = model:GetPivot().Position
            model:Destroy()
            -- 30% chance to leave a subtle paranormal trace after vanishing
            if hrp and math.random() < 0.3 then
                ParanormalEncounterController.LeaveTrace(pos, hrp)
            end
        end
    end)
    isEncounterActive = false
end

function ParanormalEncounterController.LeaveTrace(pos: Vector3, hrp: BasePart)
    local traceType = math.random(1, 3)

    if traceType == 1 then
        -- A) Huellas (Dark moist temporary footprint marks)
        for i = 1, 3 do
            local mark = Instance.new("Part")
            mark.Size = Vector3.new(0.8, 0.1, 1.2)
            mark.CFrame = CFrame.new(pos + Vector3.new(i * 1.5, 0.05, i * 1.5))
            mark.Anchored = true
            mark.CanCollide = false
            mark.Color = Color3.fromRGB(20, 20, 22)
            mark.Material = Enum.Material.SmoothPlastic
            mark.Transparency = 0.4
            mark.Parent = Workspace

            task.delay(6.0, function()
                if mark then mark:Destroy() end
            end)
        end
    elseif traceType == 2 then
        -- B) Objeto alterado temporalmente (Debris shift)
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(1.2, 1.2, 1.2)
        debris.Position = pos + Vector3.new(0, 0.6, 0)
        debris.Anchored = true
        debris.Color = Color3.fromRGB(45, 40, 35)
        debris.Material = Enum.Material.Slate
        debris.Parent = Workspace

        task.delay(5.0, function()
            if debris then debris:Destroy() end
        end)
    else
        -- C) Marca / Mancha en la superficie cercana
        local stain = Instance.new("Part")
        stain.Size = Vector3.new(2, 0.1, 2)
        stain.CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0))
        stain.Anchored = true
        stain.CanCollide = false
        stain.Color = Color3.fromRGB(10, 10, 12)
        stain.Material = Enum.Material.SmoothPlastic
        stain.Transparency = 0.3
        stain.Parent = Workspace

        task.delay(6.0, function()
            if stain then stain:Destroy() end
        end)
    end
end

function ParanormalEncounterController.ExecuteFirstEncounter(playerPos: Vector3)
    task.wait(1.5)

    local eerieSound = Instance.new("Sound")
    eerieSound.Name = "ParanormalStinger"
    eerieSound.SoundId = "rbxassetid://9075778850"
    eerieSound.Volume = 0.6
    eerieSound.Parent = SoundService
    eerieSound:Play()

    task.delay(5, function()
        if eerieSound then eerieSound:Destroy() end
    end)

    local spawnCFrame = CFrame.new(triggerPosition + Vector3.new(0, 0, 15), playerPos)
    local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(spawnCFrame)

    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(torso, tweenInfo, {Transparency = 0.25}):Play()
    TweenService:Create(head, tweenInfo, {Transparency = 0.25}):Play()
    TweenService:Create(leftEye, tweenInfo, {Transparency = 0.4}):Play()
    TweenService:Create(rightEye, tweenInfo, {Transparency = 0.4}):Play()

    local elapsed = 0
    local conn: RBXScriptConnection? = nil

    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart :: BasePart
            local dist = (hrp.Position - torso.Position).Magnitude

            if dist < 6 or elapsed >= 4.5 then
                if conn then conn:Disconnect() end
                ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, hrp)
            end
        end
    end)
end

function ParanormalEncounterController.ExecuteJumpscareEncounter(hrp: BasePart)
    local jumpSound = Instance.new("Sound")
    jumpSound.SoundId = "rbxassetid://9075778850"
    jumpSound.Volume = 0.9
    jumpSound.Parent = SoundService
    jumpSound:Play()

    task.delay(0.4, function()
        local sideOffset = (hrp.CFrame.RightVector * math.random(-3, 3)) + (hrp.CFrame.LookVector * math.random(3, 5))
        local spawnPos = hrp.Position + sideOffset
        local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(CFrame.new(spawnPos, hrp.Position))

        torso.Transparency = 0.15
        head.Transparency = 0.15
        leftEye.Transparency = 0.2
        rightEye.Transparency = 0.2

        local shakeElapsed = 0
        local shakeConn: RBXScriptConnection? = nil
        shakeConn = RunService.RenderStepped:Connect(function(dt)
            shakeElapsed += dt
            if shakeElapsed < 0.35 then
                local rx = math.random(-5, 5) * 0.01
                local ry = math.random(-5, 5) * 0.01
                Camera.CFrame = Camera.CFrame * CFrame.Angles(rx, ry, 0)
            else
                if shakeConn then shakeConn:Disconnect() end
            end
        end)

        task.delay(1.0, function()
            ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, hrp)
            if jumpSound then jumpSound:Destroy() end
        end)
    end)
end

function ParanormalEncounterController.ExecuteFollowingPresence(initialHrp: BasePart)
    local ambientSound = Instance.new("Sound")
    ambientSound.SoundId = "rbxassetid://9114251234"
    ambientSound.Volume = 0.3
    ambientSound.Parent = SoundService
    ambientSound:Play()

    task.spawn(function()
        local maxPhases = 3
        local currentPhase = 0

        while currentPhase < maxPhases and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
            currentPhase += 1
            local hrp = LocalPlayer.Character.HumanoidRootPart :: BasePart

            local offsetDir = -hrp.CFrame.LookVector + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit * 0.5
            local spawnPos = hrp.Position + (offsetDir * math.random(22, 35))
            local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(CFrame.new(spawnPos, hrp.Position))

            local fadeIn = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(torso, fadeIn, {Transparency = 0.3}):Play()
            TweenService:Create(head, fadeIn, {Transparency = 0.3}):Play()
            TweenService:Create(leftEye, fadeIn, {Transparency = 0.5}):Play()
            TweenService:Create(rightEye, fadeIn, {Transparency = 0.5}):Play()

            local phaseElapsed = 0.0
            local phaseConn: RBXScriptConnection? = nil
            local vanished = false

            phaseConn = RunService.RenderStepped:Connect(function(dt)
                phaseElapsed += dt
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if phaseConn then phaseConn:Disconnect() end
                    return
                end

                local curHrp = LocalPlayer.Character.HumanoidRootPart :: BasePart
                local toSilhouette = (torso.Position - curHrp.Position).Unit
                local lookDot = curHrp.CFrame.LookVector:Dot(toSilhouette)

                if lookDot > 0.5 or phaseElapsed >= 3.5 then
                    if not vanished then
                        vanished = true
                        if phaseConn then phaseConn:Disconnect() end
                        if currentPhase == maxPhases then
                            ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, curHrp)
                        else
                            ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye)
                        end
                    end
                end
            end)

            while not vanished and phaseElapsed < 3.5 do
                task.wait(0.1)
            end

            if phaseConn then phaseConn:Disconnect() end
            task.wait(math.random(2, 4))
        end

        if ambientSound then ambientSound:Destroy() end
        isEncounterActive = false
    end)
end

function ParanormalEncounterController.ExecuteSecondaryEncounter(hrp: BasePart)
    local encounterType = math.random(1, 9)

    if encounterType == 1 then
        -- Type A: Silueta lejana (Far silhouette)
        local offset = (hrp.CFrame.LookVector * math.random(35, 50)) + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
        local spawnPos = hrp.Position + offset
        local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(CFrame.new(spawnPos, hrp.Position))

        local fadeIn = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(torso, fadeIn, {Transparency = 0.3}):Play()
        TweenService:Create(head, fadeIn, {Transparency = 0.3}):Play()
        TweenService:Create(leftEye, fadeIn, {Transparency = 0.5}):Play()
        TweenService:Create(rightEye, fadeIn, {Transparency = 0.5}):Play()

        local elapsed = 0
        local conn: RBXScriptConnection? = nil
        conn = RunService.RenderStepped:Connect(function(dt)
            elapsed += dt
            local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp then
                local dist = (currentHrp.Position - torso.Position).Magnitude
                if dist < 12 or elapsed >= 3.5 then
                    if conn then conn:Disconnect() end
                    ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, currentHrp)
                end
            end
        end)

    elseif encounterType == 2 then
        -- Type B: Movimiento en las ruinas (Ruins movement)
        local sideOffset = (hrp.CFrame.RightVector * math.random(-20, 20)) + (hrp.CFrame.LookVector * math.random(15, 25))
        local spawnPos = hrp.Position + sideOffset
        local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(CFrame.new(spawnPos, hrp.Position))

        torso.Transparency = 0.3
        head.Transparency = 0.3
        leftEye.Transparency = 0.5
        rightEye.Transparency = 0.5

        task.delay(2.0, function()
            if model and model.Parent then
                ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, hrp)
            else
                isEncounterActive = false
            end
        end)

    elseif encounterType == 3 then
        -- Type C: Presencia detrás del jugador (Behind player)
        local behindOffset = -hrp.CFrame.LookVector * math.random(8, 12)
        local spawnPos = hrp.Position + behindOffset
        local model, torso, head, leftEye, rightEye = ParanormalEncounterController.SpawnSilhouette(CFrame.new(spawnPos, hrp.Position))

        torso.Transparency = 0.2
        head.Transparency = 0.2
        leftEye.Transparency = 0.4
        rightEye.Transparency = 0.4

        local elapsed = 0
        local conn: RBXScriptConnection? = nil
        conn = RunService.RenderStepped:Connect(function(dt)
            elapsed += dt
            local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp then
                local toSilhouette = (torso.Position - currentHrp.Position).Unit
                local lookDot = currentHrp.CFrame.LookVector:Dot(toSilhouette)

                if lookDot > 0.4 or elapsed >= 2.5 then
                    if conn then conn:Disconnect() end
                    ParanormalEncounterController.VanishSilhouette(model, torso, head, leftEye, rightEye, currentHrp)
                end
            end
        end)

    elseif encounterType == 4 then
        -- Type D: Anomalía ambiental (Environmental anomaly)
        local originalBrightness = Lighting.Brightness
        local originalAmbient = Lighting.OutdoorAmbient

        Lighting.Brightness = math.max(0.1, originalBrightness - 0.25)
        Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 8)

        local ambientSound = Instance.new("Sound")
        ambientSound.SoundId = "rbxassetid://9114251234"
        ambientSound.Volume = 0.4
        ambientSound.Parent = SoundService
        ambientSound:Play()

        task.delay(3.5, function()
            Lighting.Brightness = originalBrightness
            Lighting.OutdoorAmbient = originalAmbient
            if ambientSound then ambientSound:Destroy() end
            isEncounterActive = false
        end)

    elseif encounterType == 5 then
        -- Type E: Puerta Imposible (Impossible door / wall temporary state shift)
        local tempPart = Instance.new("Part")
        tempPart.Size = Vector3.new(4, 6, 1)
        tempPart.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * 12) + Vector3.new(0, 3, 0)
        tempPart.Anchored = true
        tempPart.Transparency = 0.8
        tempPart.Color = Color3.fromRGB(80, 70, 60)
        tempPart.Material = Enum.Material.Slate
        tempPart.Parent = Workspace

        task.delay(3.0, function()
            if tempPart then tempPart:Destroy() end
            isEncounterActive = false
        end)

    elseif encounterType == 6 then
        -- Type F: Objeto que cambia de lugar (Shifting object illusion)
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(1.5, 1.5, 1.5)
        debris.Position = hrp.Position + (hrp.CFrame.RightVector * math.random(-8, 8)) + Vector3.new(0, 1, 0)
        debris.Anchored = true
        debris.Color = Color3.fromRGB(50, 45, 40)
        debris.Material = Enum.Material.CorrugatedMetal
        debris.Parent = Workspace

        task.delay(2.5, function()
            if debris then debris:Destroy() end
            isEncounterActive = false
        end)

    elseif encounterType == 7 then
        -- Type G: Luces a la distancia (Distant light flicker)
        local lightPart = Instance.new("Part")
        lightPart.Size = Vector3.new(0.5, 0.5, 0.5)
        lightPart.Transparency = 1
        lightPart.Position = hrp.Position + (hrp.CFrame.LookVector * math.random(25, 40)) + Vector3.new(0, 6, 0)
        lightPart.Anchored = true
        lightPart.Parent = Workspace

        local pLight = Instance.new("PointLight")
        pLight.Range = 25
        pLight.Brightness = 3
        pLight.Color = Color3.fromRGB(255, 200, 150)
        pLight.Parent = lightPart

        task.delay(2.5, function()
            if lightPart then lightPart:Destroy() end
            isEncounterActive = false
        end)

    elseif encounterType == 8 then
        -- Type H: Camino que parece cambiar (Altered path vibe / fog shift)
        local origFogEnd = Lighting.FogEnd
        Lighting.FogEnd = 45

        task.delay(3.0, function()
            Lighting.FogEnd = origFogEnd
            isEncounterActive = false
        end)

    else
        -- Type I: Silencio repentino (Sudden silence)
        local silenceSound = Instance.new("Sound")
        silenceSound.SoundId = "rbxassetid://9114221580"
        silenceSound.Volume = 0.1
        silenceSound.Parent = SoundService
        silenceSound:Play()

        task.delay(3.0, function()
            if silenceSound then silenceSound:Destroy() end
            isEncounterActive = false
        end)
    end
end

return ParanormalEncounterController
