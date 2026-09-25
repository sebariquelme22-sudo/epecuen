--!strict
-- ============================================================================
-- EpecuenTutorialController.client.luau
-- Location: roblox/src/StarterPlayer/StarterPlayerScripts/EpecuenTutorialController.client.luau
--
-- EPECUÉN: NO ESCAPE - Onboarding / Tutorial System
--
-- PURPOSE:
-- Displays a dark, atmospheric initial tutorial UI for new players upon joining.
-- Fully compliant with PC and mobile, server/client separation, no gameplay blocking.
-- ============================================================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local function createTutorialUi()
    local existing = playerGui:FindFirstChild("EpecuenTutorialGui")
    if existing then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EpecuenTutorialGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.IgnoreGuiInset = true

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
    overlay.BackgroundTransparency = 0.25
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 440, 0, 480)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.new(0.5, 0, 0.5, 0)
    window.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    window.BorderColor3 = Color3.fromRGB(50, 55, 65)
    window.BorderSizePixel = 1
    window.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = window

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 24)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = window

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 14)
    layout.Parent = window

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.LayoutOrder = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 36)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "EPECUÉN: NO HAY SALIDA"
    titleLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = window

    local introLabel = Instance.new("TextLabel")
    introLabel.Name = "IntroLabel"
    introLabel.LayoutOrder = 2
    introLabel.Size = UDim2.new(1, 0, 0, 70)
    introLabel.BackgroundTransparency = 1
    introLabel.Font = Enum.Font.Gotham
    introLabel.Text = "Despertaste cerca del acceso norte.\nEl pueblo está abandonado.\nEncontrá una forma de reparar el Fiat Cronos y escapar."
    introLabel.TextColor3 = Color3.fromRGB(200, 205, 210)
    introLabel.TextSize = 14
    introLabel.TextWrapped = true
    introLabel.TextXAlignment = Enum.TextXAlignment.Left
    introLabel.Parent = window

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.LayoutOrder = 3
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    divider.BorderSizePixel = 0
    divider.Parent = window

    local objectiveLabel = Instance.new("TextLabel")
    objectiveLabel.Name = "ObjectiveLabel"
    objectiveLabel.LayoutOrder = 4
    objectiveLabel.Size = UDim2.new(1, 0, 0, 130)
    objectiveLabel.BackgroundTransparency = 1
    objectiveLabel.Font = Enum.Font.Gotham
    objectiveLabel.Text = "TU OBJETIVO:\n• Explora Epecuén.\n• Encuentra las 5 piezas del Cronos y la caja de herramientas.\n• Repara el vehículo.\n• Escapa por el Acceso Norte."
    objectiveLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
    objectiveLabel.TextSize = 13
    objectiveLabel.TextWrapped = true
    objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
    objectiveLabel.Parent = window

    local warningLabel = Instance.new("TextLabel")
    warningLabel.Name = "WarningLabel"
    warningLabel.LayoutOrder = 5
    warningLabel.Size = UDim2.new(1, 0, 0, 30)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.Text = "No estás solo."
    warningLabel.TextColor3 = Color3.fromRGB(210, 120, 80)
    warningLabel.TextSize = 14
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center
    warningLabel.Parent = window

    local btnContainer = Instance.new("Frame")
    btnContainer.Name = "BtnContainer"
    btnContainer.LayoutOrder = 6
    btnContainer.Size = UDim2.new(1, 0, 0, 48)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = window

    local continueBtn = Instance.new("TextButton")
    continueBtn.Name = "ContinueButton"
    continueBtn.Size = UDim2.new(1, 0, 1, 0)
    continueBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
    continueBtn.BorderColor3 = Color3.fromRGB(220, 70, 70)
    continueBtn.BorderSizePixel = 1
    continueBtn.Font = Enum.Font.GothamBold
    continueBtn.Text = "CONTINUAR"
    continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    continueBtn.TextSize = 14
    continueBtn.Parent = btnContainer

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = continueBtn

    continueBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    screenGui.Parent = playerGui
end

task.defer(function()
    createTutorialUi()
end)
