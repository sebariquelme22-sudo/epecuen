--!strict
--[[
    SanityController.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/EpecuenClient/Controllers/SanityController (ModuleScript)
    Description: Client psychological effects: camera breathing, heartbeat audio pacing,
                 auditory hallucinations, ShadowSpecter, StaticVision, and MajorJumpscare
                 with Altered Epecuén local world manifestation.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local SanityTypes = require(EpecuenShared:WaitForChild("SanityTypes") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local SanityController = {}

local currentSanity = 100
local targetFOV = 70
local heartbeatSound: Sound?
local activeShadowSpecterModel: Model? = nil
local isStaticVisionActive = false
local isMajorJumpscareActive = false
local isDizzinessActive = false
local lastMajorJumpscareTime = 0.0
local MAJOR_JUMPSCARE_COOLDOWN = 240.0 -- 4 minutes minimum cooldown between major jumpscares

function SanityController.Init()
    local sanityUpdatedEv = NetworkBridge.GetEvent("SanityUpdated")
    local hallucinationEv = NetworkBridge.GetEvent("TriggerHallucination")

    sanityUpdatedEv.OnClientEvent:Connect(function(newSanity: number, reason: string?)
        currentSanity = math.clamp(newSanity, 0, 100)
    end)

    hallucinationEv.OnClientEvent:Connect(function(hallucinationType: string, duration: number)
        SanityController.ExecuteHallucination(hallucinationType, duration)
    end)

    -- Setup local horror sound effects
    SanityController.SetupAudio()

    -- Per-frame camera breathing and distortion loop
    RunService.RenderStepped:Connect(SanityController.OnRenderStep)

    print("[SanityController] Client psychological effects online.")
end

function SanityController.SetupAudio()
    heartbeatSound = Instance.new("Sound")
    heartbeatSound.Name = "HeartbeatSound"
    heartbeatSound.SoundId = "rbxassetid://9114223171" -- Ambient low thump
    heartbeatSound.Looped = true
    heartbeatSound.Volume = 0
    heartbeatSound.Parent = SoundService
    heartbeatSound:Play()
end

function SanityController.OnRenderStep(dt: number)
    if not Camera then
        Camera = Workspace.CurrentCamera
        return
    end

    local clock = os.clock()
    local insanityRatio = (100 - currentSanity) / 100

    -- Heartbeat volume & playback speed scaling with fear
    if heartbeatSound then
        if currentSanity < SanityTypes.SanityThresholds.Uneasy then
            heartbeatSound.Volume = math.clamp(insanityRatio * 0.85, 0, 1)
            heartbeatSound.PlaybackSpeed = 0.8 + (insanityRatio * 0.7) -- Accelerating pulse
        else
            heartbeatSound.Volume = 0
        end
    end

    -- Dynamic FOV pulsation when sanity is fractured
    if currentSanity < SanityTypes.SanityThresholds.Paranoid then
        local breathPulse = math.sin(clock * (2 + insanityRatio * 4)) * (3 * insanityRatio)
        Camera.FieldOfView = 70 + breathPulse
    else
        Camera.FieldOfView = 70
    end
end

function SanityController.ExecuteHallucination(hType: string, duration: number)
    print(`[SanityController] Manifesting Hallucination: {hType}`)

    if hType == "Whispers" then
        local whisper = Instance.new("Sound")
        whisper.SoundId = "rbxassetid://9114227097" -- Eerie gust/whisper
        whisper.Volume = 0.7
        whisper.Parent = SoundService
        whisper:Play()
        task.delay(duration, function()
            whisper:Destroy()
        end)

    elseif hType == "FakeFootsteps" then
        if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive or isDizzinessActive then return end
        SanityController.PlayFakeFootsteps(duration)

    elseif hType == "DisorientCamera" then
        if isMajorJumpscareActive or isDizzinessActive then return end
        if Camera then
            local originalCF = Camera.CFrame
            local jolt = CFrame.Angles(0, math.rad(math.random(-15, 15)), math.rad(math.random(-8, 8)))
            Camera.CFrame = originalCF * jolt
            TweenService:Create(Camera, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                CFrame = originalCF
            }):Play()
        end

    elseif hType == "SubmergedBell" then
        local bell = Instance.new("Sound")
        bell.SoundId = "rbxassetid://9113644408" -- Submerged low bell chime
        bell.Volume = 0.5
        bell.PlaybackSpeed = 0.65
        bell.Parent = SoundService
        bell:Play()
        task.delay(duration, function()
            bell:Destroy()
        end)

    elseif hType == "ShadowSpecter" then
        if isStaticVisionActive or isMajorJumpscareActive or isDizzinessActive then return end
        SanityController.SpawnShadowSpecter(duration)

    elseif hType == "StaticVision" then
        if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive or isDizzinessActive then return end
        SanityController.ExecuteStaticVision(math.clamp(duration, 0.4, 1.2))

    elseif hType == "MajorJumpscare" then
        if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive or isDizzinessActive then return end
        local now = os.clock()
        if now - lastMajorJumpscareTime >= MAJOR_JUMPSCARE_COOLDOWN then
            lastMajorJumpscareTime = now
            SanityController.ExecuteMajorJumpscareAndAlteredWorld()
        end

    elseif hType == "DizzinessSpecter" then
        if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive or isDizzinessActive then return end
        SanityController.ExecuteDizzinessSpecter(math.clamp(duration, 3.0, 5.0))
    end
end

function SanityController.ExecuteMajorJumpscareAndAlteredWorld()
    if isMajorJumpscareActive then return end
    isMajorJumpscareActive = true

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        isMajorJumpscareActive = false
        return
    end

    local hrp = character.HumanoidRootPart :: BasePart

    -- Save original Lighting state
    local origBrightness = Lighting.Brightness
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origAmbient = Lighting.Ambient
    local origFogColor = Lighting.FogColor
    local origFogEnd = Lighting.FogEnd
    local origExposure = Lighting.ExposureCompensation

    -- Failsafe cleanup container for temporary local illusion parts
    local illusionFolder = Instance.new("Folder")
    illusionFolder.Name = "AlteredEpecuenIllusionsLocal"
    illusionFolder.Parent = Workspace

    -- PHASE 2: LA CARA (First person jumpscare face)
    local jumpscareSound = Instance.new("Sound")
    jumpscareSound.SoundId = "rbxassetid://9075778850" -- Terrifying stinger
    jumpscareSound.Volume = 1.0
    jumpscareSound.Parent = SoundService
    jumpscareSound:Play()

    local faceModel = Instance.new("Model")
    faceModel.Name = "JumpscareFace"

    local faceHead = Instance.new("Part")
    faceHead.Size = Vector3.new(2.2, 2.2, 2.2)
    faceHead.CFrame = Camera.CFrame * CFrame.new(0, 0, -2.2)
    faceHead.Anchored = true
    faceHead.CanCollide = false
    faceHead.CanTouch = false
    faceHead.Material = Enum.Material.SmoothPlastic
    faceHead.Color = Color3.fromRGB(5, 5, 8)
    faceHead.Parent = faceModel

    local leftEye = Instance.new("Part")
    leftEye.Size = Vector3.new(0.3, 0.15, 0.1)
    leftEye.CFrame = faceHead.CFrame * CFrame.new(-0.4, 0.2, -1.15)
    leftEye.Anchored = true
    leftEye.CanCollide = false
    leftEye.Material = Enum.Material.Neon
    leftEye.Color = Color3.fromRGB(255, 255, 255)
    leftEye.Parent = faceModel

    local rightEye = Instance.new("Part")
    rightEye.Size = Vector3.new(0.3, 0.15, 0.1)
    rightEye.CFrame = faceHead.CFrame * CFrame.new(0.4, 0.2, -1.15)
    rightEye.Anchored = true
    rightEye.CanCollide = false
    rightEye.Material = Enum.Material.Neon
    rightEye.Color = Color3.fromRGB(255, 255, 255)
    rightEye.Parent = faceModel

    faceModel.Parent = Workspace

    -- Camera shake jolt
    if Camera then
        local origCF = Camera.CFrame
        Camera.CFrame = origCF * CFrame.Angles(math.rad(math.random(-12, 12)), math.rad(math.random(-12, 12)), 0)
    end

    -- PHASE 3 & 4: EPECUÉN ALTERADO (Local world transformation for 8 seconds)
    task.delay(1.5, function()
        if faceModel then faceModel:Destroy() end

        -- Shift lighting to eerie crimson pampas
        Lighting.Brightness = 0.15
        Lighting.OutdoorAmbient = Color3.fromRGB(35, 10, 10)
        Lighting.Ambient = Color3.fromRGB(20, 8, 12)
        Lighting.FogColor = Color3.fromRGB(45, 15, 15)
        Lighting.FogEnd = 50
        Lighting.ExposureCompensation = -0.5

        -- Spawn local ephemeral ghost structures / illusion props around the player
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2
            local dist = math.random(8, 16)
            local pos = hrp.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)

            local ghostPillar = Instance.new("Part")
            ghostPillar.Size = Vector3.new(3, math.random(8, 14), 3)
            ghostPillar.Position = pos + Vector3.new(0, ghostPillar.Size.Y / 2, 0)
            ghostPillar.Anchored = true
            ghostPillar.CanCollide = false
            ghostPillar.CanTouch = false
            ghostPillar.CanQuery = false
            ghostPillar.Material = Enum.Material.Slate
            ghostPillar.Color = Color3.fromRGB(25, 20, 22)
            ghostPillar.Transparency = 0.35
            ghostPillar.Parent = illusionFolder
        end
    end)

    -- PHASE 7: RESTAURACIÓN Y FAILSAFE (Total duration: 9.5 seconds)
    task.delay(9.5, function()
        SanityController.RestoreNormalWorld(origBrightness, origOutdoorAmbient, origAmbient, origFogColor, origFogEnd, origExposure, illusionFolder, jumpscareSound)
    end)
end

function SanityController.RestoreNormalWorld(
    origBrightness: number,
    origOutdoorAmbient: Color3,
    origAmbient: Color3,
    origFogColor: Color3,
    origFogEnd: number,
    origExposure: number,
    illusionFolder: Folder,
    jumpscareSound: Sound?
)
    pcall(function()
        if jumpscareSound and jumpscareSound.Parent then
            jumpscareSound:Destroy()
        end

        if illusionFolder then
            illusionFolder:Destroy()
        end

        Lighting.Brightness = origBrightness
        Lighting.OutdoorAmbient = origOutdoorAmbient
        Lighting.Ambient = origAmbient
        Lighting.FogColor = origFogColor
        Lighting.FogEnd = origFogEnd
        Lighting.ExposureCompensation = origExposure

        isMajorJumpscareActive = false
        print("[SanityController] Altered Epecuen world restored to normal safely.")
    end)
end

function SanityController.ExecuteStaticVision(duration: number)
    if isStaticVisionActive then return end
    isStaticVisionActive = true

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        isStaticVisionActive = false
        return
    end

    local hrp = character.HumanoidRootPart :: BasePart
    local origBrightness = Lighting.Brightness
    local origExposure = Lighting.ExposureCompensation

    -- Brief visual glitch / corruption pulse
    Lighting.Brightness = 0.1
    Lighting.ExposureCompensation = -0.8

    -- Quick camera glitch jolt
    if Camera then
        local origCF = Camera.CFrame
        Camera.CFrame = origCF * CFrame.Angles(math.rad(math.random(-4, 4)), math.rad(math.random(-4, 4)), 0)
        task.delay(0.15, function()
            if Camera then
                Camera.CFrame = origCF
            end
        end)
    end

    -- Fleeting glitch audio glitch/static transient
    local glitchSound = Instance.new("Sound")
    glitchSound.SoundId = "rbxassetid://9114227097"
    glitchSound.Volume = 0.4
    glitchSound.PlaybackSpeed = 2.0
    glitchSound.Parent = SoundService
    glitchSound:Play()

    task.delay(duration, function()
        if glitchSound then glitchSound:Destroy() end
        Lighting.Brightness = origBrightness
        Lighting.ExposureCompensation = origExposure
        isStaticVisionActive = false
    end)
end

function SanityController.PlayFakeFootsteps(duration: number)
    if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive then
        return -- Avoid simultaneous conflict
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local hrp = character.HumanoidRootPart :: BasePart
    local angle = math.rad(math.random(0, 360))
    local dist = math.random(6, 12)
    local offset = Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)

    local footPart = Instance.new("Part")
    footPart.Size = Vector3.new(1, 1, 1)
    footPart.Transparency = 1
    footPart.CanCollide = false
    footPart.Anchored = true
    footPart.Position = hrp.Position + offset
    footPart.Parent = Workspace

    task.spawn(function()
        local stepsCount = math.random(3, 6)
        for i = 1, stepsCount do
            if not footPart.Parent then break end
            local stepSound = Instance.new("Sound")
            stepSound.SoundId = "rbxassetid://9114227097" -- eerie subtle transient sound
            stepSound.Volume = 0.35
            stepSound.PlaybackSpeed = 0.8 + (i * 0.1)
            stepSound.Parent = footPart
            stepSound:Play()

            local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp then
                local dirToPlayer = (currentHrp.Position - footPart.Position).Unit
                footPart.Position += dirToPlayer * 1.5
            end

            task.wait(math.random(40, 70) / 100)
            if stepSound then stepSound:Destroy() end
        end

        task.delay(0.5, function()
            if footPart then footPart:Destroy() end
        end)
    end)
end

function SanityController.SpawnShadowSpecter(duration: number)
    if activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive then
        return -- Only one active specter per player, respect mutual exclusion
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local hrp = character.HumanoidRootPart :: BasePart
    local sideOffset = (hrp.CFrame.RightVector * math.random(-12, 12)) + (-hrp.CFrame.LookVector * math.random(15, 22))
    local spawnCFrame = CFrame.new(hrp.Position + sideOffset, hrp.Position)

    -- Create Shadow Specter Model
    local model = Instance.new("Model")
    model.Name = "ShadowSpecter"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 3.2, 1)
    torso.CFrame = spawnCFrame + Vector3.new(0, 1.6, 0)
    torso.Anchored = true
    torso.CanCollide = false
    torso.Material = Enum.Material.SmoothPlastic
    torso.Color = Color3.fromRGB(8, 8, 10)
    torso.Transparency = 1
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.2, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(8, 8, 10)
    head.Transparency = 1
    head.Parent = model

    local leftEye = Instance.new("Part")
    leftEye.Size = Vector3.new(0.12, 0.08, 0.08)
    leftEye.CFrame = head.CFrame * CFrame.new(-0.25, 0.1, -0.6)
    leftEye.Anchored = true
    leftEye.CanCollide = false
    leftEye.Material = Enum.Material.Neon
    leftEye.Color = Color3.fromRGB(240, 245, 255)
    leftEye.Transparency = 1
    leftEye.Parent = model

    local rightEye = Instance.new("Part")
    rightEye.Size = Vector3.new(0.12, 0.08, 0.08)
    rightEye.CFrame = head.CFrame * CFrame.new(0.25, 0.1, -0.6)
    rightEye.Anchored = true
    rightEye.CanCollide = false
    rightEye.Material = Enum.Material.Neon
    rightEye.Color = Color3.fromRGB(240, 245, 255)
    rightEye.Transparency = 1
    rightEye.Parent = model

    model.Parent = Workspace
    activeShadowSpecterModel = model

    -- "El mundo se apaga" atmosphere effect
    local origBrightness = Lighting.Brightness
    Lighting.Brightness = math.max(0.05, origBrightness - 0.25)

    -- Fade in
    local fadeIn = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(torso, fadeIn, {Transparency = 0.15}):Play()
    TweenService:Create(head, fadeIn, {Transparency = 0.15}):Play()
    TweenService:Create(leftEye, fadeIn, {Transparency = 0.5}):Play()
    TweenService:Create(rightEye, fadeIn, {Transparency = 0.5}):Play()

    -- Monitoring connection to check if player looks directly at it or duration ends
    local elapsed = 0.0
    local conn: RBXScriptConnection? = nil
    local isFadingOut = false

    local function fadeAndDestroy()
        if isFadingOut then return end
        isFadingOut = true
        if conn then conn:Disconnect() end

        local fadeOut = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(torso, fadeOut, {Transparency = 1}):Play()
        TweenService:Create(head, fadeOut, {Transparency = 1}):Play()
        TweenService:Create(leftEye, fadeOut, {Transparency = 1}):Play()
        TweenService:Create(rightEye, fadeOut, {Transparency = 1}):Play()

        Lighting.Brightness = origBrightness

        task.delay(0.9, function()
            if model then model:Destroy() end
            if activeShadowSpecterModel == model then
                activeShadowSpecterModel = nil
            end
        end)
    end

    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            fadeAndDestroy()
            return
        end

        local curHrp = LocalPlayer.Character.HumanoidRootPart :: BasePart
        local toSpecter = (torso.Position - curHrp.Position).Unit
        local lookDot = curHrp.CFrame.LookVector:Dot(toSpecter)

        -- If player stares directly at it for too long or duration expires, vanish
        if lookDot > 0.65 or elapsed >= duration then
            fadeAndDestroy()
        end
    end)
end

function SanityController.ExecuteDizzinessSpecter(duration: number)
    if isDizzinessActive or activeShadowSpecterModel or isStaticVisionActive or isMajorJumpscareActive then return end
    isDizzinessActive = true

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        isDizzinessActive = false
        return
    end

    local hrp = character.HumanoidRootPart :: BasePart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        isDizzinessActive = false
        return
    end

    local origWalkSpeed = humanoid.WalkSpeed
    local origFOV = Camera and Camera.FieldOfView or 70

    -- 1. Low hum sound
    local humSound = Instance.new("Sound")
    humSound.SoundId = "rbxassetid://9114223171"
    humSound.Volume = 0.6
    humSound.PlaybackSpeed = 0.6
    humSound.Looped = true
    humSound.Parent = SoundService
    humSound:Play()

    -- 2. Progressive Blur Effect in Lighting
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting
    TweenService:Create(blur, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 16}):Play()

    -- 3. Peripheral Specter Model (~8 studs away)
    local angle = math.rad(math.random(0, 360))
    local offset = Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
    local spawnCF = CFrame.new(hrp.Position + offset, hrp.Position)

    local model = Instance.new("Model")
    model.Name = "DizzinessSpecter"

    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 3, 1)
    torso.CFrame = spawnCF + Vector3.new(0, 1.5, 0)
    torso.Anchored = true
    torso.CanCollide = false
    torso.Material = Enum.Material.SmoothPlastic
    torso.Color = Color3.fromRGB(10, 10, 12)
    torso.Transparency = 0.25
    torso.Parent = model

    local head = Instance.new("Part")
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.1, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(10, 10, 12)
    head.Transparency = 0.25
    head.Parent = model

    local lEye = Instance.new("Part")
    lEye.Size = Vector3.new(0.1, 0.05, 0.05)
    lEye.CFrame = head.CFrame * CFrame.new(-0.25, 0.1, -0.6)
    lEye.Anchored = true
    lEye.CanCollide = false
    lEye.Material = Enum.Material.Neon
    lEye.Color = Color3.fromRGB(240, 245, 255)
    lEye.Transparency = 0.3
    lEye.Parent = model

    local rEye = Instance.new("Part")
    rEye.Size = Vector3.new(0.1, 0.05, 0.05)
    rEye.CFrame = head.CFrame * CFrame.new(0.25, 0.1, -0.6)
    rEye.Anchored = true
    rEye.CanCollide = false
    rEye.Material = Enum.Material.Neon
    rEye.Color = Color3.fromRGB(240, 245, 255)
    rEye.Transparency = 0.3
    rEye.Parent = model

    model.Parent = Workspace

    -- 4. Loop for Camera Roll, FOV oscillation and WalkSpeed reduction
    local elapsed = 0.0
    local conn: RBXScriptConnection? = nil

    local function cleanupDizziness()
        if conn then conn:Disconnect() end
        pcall(function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = origWalkSpeed
            end
            if Camera then
                Camera.FieldOfView = origFOV
            end
            if humSound then humSound:Destroy() end
            if blur then
                TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 0}):Play()
                task.delay(0.5, function()
                    if blur then blur:Destroy() end
                end)
            end
            if model then model:Destroy() end
        end)
        isDizzinessActive = false
    end

    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if elapsed >= duration or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            cleanupDizziness()
            return
        end

        local curHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if curHumanoid and curHumanoid.Health > 0 then
            curHumanoid.WalkSpeed = origWalkSpeed * 0.4
        else
            cleanupDizziness()
            return
        end

        if Camera then
            local clock = os.clock()
            local roll = math.sin(clock * 5) * 0.04
            local fovOsc = math.sin(clock * 6) * 5
            Camera.FieldOfView = 70 + fovOsc
            local currentCF = Camera.CFrame
            Camera.CFrame = currentCF * CFrame.Angles(0, 0, roll)
        end
    end)

    -- Failsafe timeout
    task.delay(duration + 0.1, function()
        if isDizzinessActive then
            cleanupDizziness()
        end
    end)
end

function SanityController.GetSanity(): number
    return currentSanity
end

return SanityController
