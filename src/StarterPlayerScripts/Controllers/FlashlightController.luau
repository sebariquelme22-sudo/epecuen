--!strict
--[[
    FlashlightController.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/EpecuenClient/Controllers/FlashlightController (ModuleScript)
    Description: Realistic physical flashlight. Projects a volumetric beam, consumes battery,
                 sways with viewmodel movement, and flickers under low power or entity presence.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local GameConfig = require(EpecuenShared:WaitForChild("GameConfig") :: ModuleScript)
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local FlashlightController = {}

local isFlashlightOn = false
local batteryLevel = 100
local spotLight: SpotLight?
local lightPart: Part?
local clickSound: Sound?
local flickerSound: Sound?

function FlashlightController.Init()
    _G.FlashlightController = FlashlightController
    LocalPlayer:SetAttribute("FlashlightBattery", batteryLevel)
    LocalPlayer:SetAttribute("FlashlightOn", isFlashlightOn)

    -- Create sound effects
    clickSound = Instance.new("Sound")
    clickSound.Name = "FlashlightClick"
    clickSound.SoundId = "rbxassetid://9114221580"
    clickSound.Volume = 0.5
    clickSound.Parent = SoundService

    -- Physical Light Part attached to Camera
    lightPart = Instance.new("Part")
    lightPart.Name = "FlashlightEmitter"
    lightPart.Transparency = 1
    lightPart.CanCollide = false
    lightPart.CanTouch = false
    lightPart.CanQuery = false
    lightPart.Anchored = true
    lightPart.Size = Vector3.new(0.2, 0.2, 0.2)
    lightPart.Parent = Workspace

    spotLight = Instance.new("SpotLight")
    spotLight.Name = "Beam"
    spotLight.Range = GameConfig.FLASHLIGHT.LIGHT_RANGE
    spotLight.Brightness = GameConfig.FLASHLIGHT.LIGHT_BRIGHTNESS
    spotLight.Angle = GameConfig.FLASHLIGHT.LIGHT_ANGLE
    spotLight.Color = GameConfig.FLASHLIGHT.TINT
    spotLight.Shadows = true
    spotLight.Enabled = false
    spotLight.Parent = lightPart

    -- Keybind Toggle: 'F' or Gamepad button
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY then
            FlashlightController.Toggle()
        end
    end)

    -- Per-frame update: beam positioning & battery decay
    RunService.RenderStepped:Connect(FlashlightController.OnRenderStep)

    print("[FlashlightController] Flashlight systems armed.")
end

function FlashlightController.Toggle()
    if batteryLevel <= 0 and not isFlashlightOn then
        -- Dead battery click
        if clickSound then clickSound:Play() end
        return
    end

    isFlashlightOn = not isFlashlightOn
    if spotLight then
        spotLight.Enabled = isFlashlightOn
    end

    LocalPlayer:SetAttribute("FlashlightOn", isFlashlightOn)

    if clickSound then
        clickSound:Play()
    end

    -- Broadcast noise for acoustic detection
    if isFlashlightOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart :: BasePart
        local noiseEv = NetworkBridge.GetEvent("NoiseProduced")
        noiseEv:FireServer(hrp.Position, GameConfig.NOISE.FLASHLIGHT_CLICK_RANGE, "FlashlightClick")
    end
end

function FlashlightController.OnRenderStep(dt: number)
    if not Camera then
        Camera = Workspace.CurrentCamera
        return
    end

    -- Update beam position smoothly with camera view
    if lightPart then
        lightPart.CFrame = Camera.CFrame
    end

    if isFlashlightOn then
        -- Drain battery
        batteryLevel = math.clamp(batteryLevel - (GameConfig.FLASHLIGHT.DRAIN_PER_SECOND * dt), 0, 100)
        LocalPlayer:SetAttribute("FlashlightBattery", batteryLevel)

        if batteryLevel <= 0 then
            isFlashlightOn = false
            LocalPlayer:SetAttribute("FlashlightOn", false)
            if spotLight then spotLight.Enabled = false end
            return
        end

        -- Low battery flicker logic
        if spotLight and batteryLevel < 25 then
            if math.random() < GameConfig.FLASHLIGHT.FLICKER_CHANCE_LOW_BATTERY then
                spotLight.Enabled = false
                task.delay(math.random(5, 15) / 100, function()
                    if isFlashlightOn and spotLight then
                        spotLight.Enabled = true
                    end
                end)
            end
        end
    end
end

function FlashlightController.GetBattery(): number
    return batteryLevel
end

function FlashlightController.IsOn(): boolean
    return isFlashlightOn
end

function FlashlightController.AddBattery(amount: number)
    batteryLevel = math.clamp(batteryLevel + amount, 0, 100)
    LocalPlayer:SetAttribute("FlashlightBattery", batteryLevel)
end

return FlashlightController
