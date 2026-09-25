--!strict
--[[
    HUDController.client.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterGui/EpecuenGui/HUDController (LocalScript)
    Description: Diegetic survival HUD for Epecuén. Renders sanity heartbeat vignette,
                 flashlight battery indicator, salt crystallization frost overlay,
                 and pickup / journal inspection toasts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EpecuenHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- Sanity Vignette (Procedural UIGradient edge frames - no external asset dependencies)
local vignette = Instance.new("Frame")
vignette.Name = "SanityVignette"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.Position = UDim2.new(0, 0, 0, 0)
vignette.BackgroundTransparency = 1
vignette.Parent = screenGui

local vignetteEdges: { Frame } = {}

local function createVignetteEdge(name: string, size: UDim2, position: UDim2, rotation: number): Frame
    local edge = Instance.new("Frame")
    edge.Name = name
    edge.Size = size
    edge.Position = position
    edge.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
    edge.BackgroundTransparency = 1
    edge.BorderSizePixel = 0
    edge.Parent = vignette

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Parent = edge

    table.insert(vignetteEdges, edge)
    return edge
end

createVignetteEdge("TopEdge", UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0, 0), 90)
createVignetteEdge("BottomEdge", UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0.65, 0), 270)
createVignetteEdge("LeftEdge", UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0)
createVignetteEdge("RightEdge", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), 180)

local function setVignetteTransparency(alpha: number)
    local clamped = math.clamp(alpha, 0, 1)
    for _, edge in ipairs(vignetteEdges) do
        edge.BackgroundTransparency = clamped
    end
end

-- Salt Crust Overlay (Toxic brine frost on screen edges)
local saltFrost = Instance.new("Frame")
saltFrost.Name = "SaltFrost"
saltFrost.Size = UDim2.new(1, 0, 1, 0)
saltFrost.BackgroundTransparency = 1
saltFrost.Parent = screenGui

local saltBorderTop = Instance.new("Frame")
saltBorderTop.Size = UDim2.new(1, 0, 0, 8)
saltBorderTop.BackgroundColor3 = Color3.fromRGB(240, 245, 250)
saltBorderTop.BackgroundTransparency = 0.95
saltBorderTop.BorderSizePixel = 0
saltBorderTop.Parent = saltFrost

-- Battery Gauge container (bottom-right)
local batteryFrame = Instance.new("Frame")
batteryFrame.Name = "BatteryFrame"
batteryFrame.Size = UDim2.new(0, 140, 0, 32)
batteryFrame.Position = UDim2.new(1, -160, 1, -50)
batteryFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
batteryFrame.BackgroundTransparency = 0.4
batteryFrame.BorderSizePixel = 0
batteryFrame.Parent = screenGui

local batteryCorner = Instance.new("UICorner")
batteryCorner.CornerRadius = UDim.new(0, 6)
batteryCorner.Parent = batteryFrame

local batteryLabel = Instance.new("TextLabel")
batteryLabel.Size = UDim2.new(0, 40, 1, 0)
batteryLabel.BackgroundTransparency = 1
batteryLabel.Font = Enum.Font.GothamBold
batteryLabel.Text = "FL"
batteryLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
batteryLabel.TextSize = 13
batteryLabel.Parent = batteryFrame

local batteryBarBg = Instance.new("Frame")
batteryBarBg.Size = UDim2.new(0, 80, 0, 10)
batteryBarBg.Position = UDim2.new(0, 45, 0.5, -5)
batteryBarBg.BackgroundColor3 = Color3.fromRGB(30, 35, 42)
batteryBarBg.BorderSizePixel = 0
batteryBarBg.Parent = batteryFrame

local batteryFill = Instance.new("Frame")
batteryFill.Name = "Fill"
batteryFill.Size = UDim2.new(1, 0, 1, 0)
batteryFill.BackgroundColor3 = Color3.fromRGB(120, 200, 140)
batteryFill.BorderSizePixel = 0
batteryFill.Parent = batteryBarBg

-- Mobile Flashlight Touch Button
local mobileButton = Instance.new("TextButton")
mobileButton.Name = "MobileFlashlightButton"
mobileButton.Size = UDim2.new(0, 50, 0, 50)
mobileButton.Position = UDim2.new(1, -70, 0, 70)
mobileButton.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
mobileButton.BackgroundTransparency = 0.4
mobileButton.Text = "🔦"
mobileButton.TextSize = 24
mobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileButton.Visible = UserInputService.TouchEnabled

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 25)
mCorner.Parent = mobileButton

local mStroke = Instance.new("UIStroke")
mStroke.Transparency = 0.7
mStroke.Color = Color3.fromRGB(100, 100, 100)
mStroke.Parent = mobileButton

mobileButton.MouseButton1Click:Connect(function()
    if _G.FlashlightController and typeof(_G.FlashlightController.Toggle) == "function" then
        _G.FlashlightController.Toggle()
    end
end)

mobileButton.Parent = screenGui

-- Notification Toast
local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "ToastLabel"
toastLabel.Size = UDim2.new(0, 400, 0, 35)
toastLabel.Position = UDim2.new(0.5, -200, 0.85, 0)
toastLabel.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
toastLabel.BackgroundTransparency = 1
toastLabel.TextTransparency = 1
toastLabel.Font = Enum.Font.GothamMedium
toastLabel.TextSize = 15
toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
toastLabel.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toastLabel

-- Connect network events
local sanityUpdated = NetworkBridge.GetEvent("SanityUpdated")
local waterChanged = NetworkBridge.GetEvent("WaterExposureChanged")
local interactCompleted = NetworkBridge.GetEvent("InteractCompleted")

local currentSanity = 100
local currentExposure = 0

sanityUpdated.OnClientEvent:Connect(function(newSanity: number)
    currentSanity = newSanity
end)

waterChanged.OnClientEvent:Connect(function(exposure: number, inWater: boolean)
    currentExposure = exposure
    -- Show brine salt frost when exposure rises
    local alpha = 1 - math.clamp(exposure / 100, 0, 0.85)
    saltBorderTop.BackgroundTransparency = alpha
end)

interactCompleted.OnClientEvent:Connect(function(item: Instance, success: boolean, msg: string?)
    if msg then
        toastLabel.Text = msg
        toastLabel.TextColor3 = success and Color3.fromRGB(180, 230, 200) or Color3.fromRGB(240, 130, 130)
        TweenService:Create(toastLabel, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.3,
            TextTransparency = 0
        }):Play()

        task.delay(3, function()
            TweenService:Create(toastLabel, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
        end)
    end
end)

-- Heartbeat pulsing loop for vignette & battery HUD synchronization
RunService.RenderStepped:Connect(function()
    if currentSanity < 60 then
        local fearFactor = (60 - currentSanity) / 60
        local pulse = (math.sin(os.clock() * (2 + fearFactor * 6)) + 1) / 2
        setVignetteTransparency(1 - (pulse * fearFactor * 0.7))
    else
        setVignetteTransparency(1)
    end

    -- Update battery gauge from FlashlightController / attribute
    local batteryPercent = 100
    if _G.FlashlightController and typeof(_G.FlashlightController.GetBattery) == "function" then
        batteryPercent = _G.FlashlightController.GetBattery()
    elseif LocalPlayer:GetAttribute("FlashlightBattery") ~= nil then
        batteryPercent = LocalPlayer:GetAttribute("FlashlightBattery") :: number
    end

    local fillAlpha = math.clamp(batteryPercent / 100, 0, 1)
    batteryFill.Size = UDim2.new(fillAlpha, 0, 1, 0)

    if batteryPercent <= 0 then
        batteryFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    elseif batteryPercent <= 25 then
        batteryFill.BackgroundColor3 = Color3.fromRGB(230, 160, 40)
    else
        batteryFill.BackgroundColor3 = Color3.fromRGB(120, 200, 140)
    end
end)

print("[HUDController] Survival horror GUI active.")
