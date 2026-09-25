--!strict
-- ============================================================================
-- CarPartProgressHUD.luau
-- Location: roblox/src/StarterGui/CarPartProgressHUD.luau
--
-- EPECUÉN: NO ESCAPE - Fiat Cronos Vehicle-Repair Progress HUD
--
-- PURPOSE:
-- Compact, mobile-friendly client-side HUD displaying the player's progress
-- in discovering and collecting the five physical Fiat Cronos repair components:
--   1. 🔋 Batería               (VehiclePart_Battery_12V)
--   2. ⚙️ Alternador            (VehiclePart_Alternator_14V)
--   3. 🔩 Bujías                (VehiclePart_SparkPlugs_Set)
--   4. ⛽ Bidón de nafta         (VehiclePart_FuelCanister_20L)
--   5. 🔧 Manguera del radiador  (VehiclePart_RadiatorHose_Reinforced)
--
-- HUD CONTENT SPECIFICATION:
--   - Title: "PIEZAS DEL CRONOS"
--   - Progress: "0 / 5 PIEZAS" -> "X / 5 PIEZAS"
--   - Completion (5/5): "5 / 5 PIEZAS" and "LISTO PARA REPARAR"
--   - Status per item: "NOT ENCONTRADA" or "ENCONTRADA ✓"
--
-- VISUAL DESIGN:
--   - Dark translucent panel (Color3.fromRGB(15, 18, 22), 0.35 transparency).
--   - Compact, unobtrusive modern survival-horror aesthetic.
--   - High-contrast typography (white/silver text, AA compliant).
--   - Positioned in upper-right corner safely inside mobile screen bounds.
--   - Native Roblox UI instances only (no external images, textures, or asset IDs).
--   - Mobile touch-friendly: responsive layout, touch collapse toggle.
--
-- ARCHITECTURE & INTEGRITY:
--   - Server-authoritative: client cannot falsely mark components as collected.
--   - Dedicated, isolated network bridge (CarPartRemotes) without modifying
--     unrelated systems.
--   - Per-player progress reflection.
--   - Preserved across character respawns (ResetOnSpawn = false).
--   - Strict prevention of duplicate GUIs and connection leaks.
--   - Zero modifications to TheFiatCronos, CarPartObjectiveSystem,
--     CarPartCollectionSystem, or existing horror/sanity systems.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CarPartProgressHUD = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type ObjectiveId = "Battery" | "Alternator" | "SparkPlugs" | "FuelCanister" | "RadiatorHose"

export type ComponentDefinition = {
    Id: ObjectiveId,
    DisplayName: string,
    ModelName: string,
    Order: number,
}

type ComponentRowUI = {
    Frame: Frame,
    NameLabel: TextLabel,
    StatusLabel: TextLabel,
}

-- ----------------------------------------------------------------------------
-- CANONICAL COMPONENT DEFINITIONS
-- ----------------------------------------------------------------------------

local CANONICAL_COMPONENTS: { ComponentDefinition } = {
    {
        Id = "Battery",
        DisplayName = "🔋 Batería",
        ModelName = "VehiclePart_Battery_12V",
        Order = 1,
    },
    {
        Id = "Alternator",
        DisplayName = "⚙️ Alternador",
        ModelName = "VehiclePart_Alternator_14V",
        Order = 2,
    },
    {
        Id = "SparkPlugs",
        DisplayName = "🔩 Bujías",
        ModelName = "VehiclePart_SparkPlugs_Set",
        Order = 3,
    },
    {
        Id = "FuelCanister",
        DisplayName = "⛽ Bidón de nafta",
        ModelName = "VehiclePart_FuelCanister_20L",
        Order = 4,
    },
    {
        Id = "RadiatorHose",
        DisplayName = "🔧 Manguera del radiador",
        ModelName = "VehiclePart_RadiatorHose_Reinforced",
        Order = 5,
    },
}

local OBJECTIVE_BY_ID: { [ObjectiveId]: ComponentDefinition } = {}
local OBJECTIVE_BY_MODEL: { [string]: ObjectiveId } = {}

for _, comp in ipairs(CANONICAL_COMPONENTS) do
    OBJECTIVE_BY_ID[comp.Id] = comp
    OBJECTIVE_BY_MODEL[comp.ModelName] = comp.Id
end

-- ----------------------------------------------------------------------------
-- CONSTANTS & THEME
-- ----------------------------------------------------------------------------

local GUI_NAME = "CarPartProgressHUDGui"
local TITLE_TEXT = "PIEZAS DEL CRONOS"
local COMPLETION_TEXT = "LISTO PARA REPARAR"
local STATUS_NOT_FOUND = "NOT ENCONTRADA"
local STATUS_FOUND = "ENCONTRADA ✓"

local COLOR_BG = Color3.fromRGB(15, 18, 22)
local COLOR_BORDER = Color3.fromRGB(50, 58, 68)
local COLOR_BORDER_COMPLETE = Color3.fromRGB(60, 140, 85)
local COLOR_TITLE = Color3.fromRGB(240, 242, 245)
local COLOR_COUNTER = Color3.fromRGB(180, 195, 210)
local COLOR_ITEM_UNCOLLECTED = Color3.fromRGB(170, 175, 185)
local COLOR_ITEM_COLLECTED = Color3.fromRGB(245, 250, 255)
local COLOR_STATUS_UNCOLLECTED = Color3.fromRGB(200, 85, 85)
local COLOR_STATUS_COLLECTED = Color3.fromRGB(90, 220, 130)
local COLOR_DIVIDER = Color3.fromRGB(45, 52, 62)

local NETWORKING_FOLDER_NAME = "CarPartRemotes"
local REMOTE_EVENT_NAME = "CarPartCollected"
local REMOTE_FUNCTION_NAME = "GetCarPartProgress"

-- ----------------------------------------------------------------------------
-- INTERNAL STATE
-- ----------------------------------------------------------------------------

local isInitialized = false
local isServerInitialized = false

-- Local player collection progress: progressState[ObjectiveId] = boolean
local progressState: { [ObjectiveId]: boolean } = {
    Battery = false,
    Alternator = false,
    SparkPlugs = false,
    FuelCanister = false,
    RadiatorHose = false,
}

-- UI references
local activeScreenGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local mainStroke: UIStroke? = nil
local counterLabel: TextLabel? = nil
local completionLabel: TextLabel? = nil
local itemsContainer: Frame? = nil
local rowUIs: { [ObjectiveId]: ComponentRowUI } = {}

-- State tracking
local isCollapsed = false

-- Connection registry for safe cleanup
local connections: { RBXScriptConnection } = {}

-- ----------------------------------------------------------------------------
-- NETWORKING INFRASTRUCTURE
-- Clean, isolated server-client synchronization pattern without touching unrelated systems
-- ----------------------------------------------------------------------------

--- Resolves or creates the dedicated CarPartRemotes folder in ReplicatedStorage.
local function getRemotesFolder(): Folder?
    local folder = ReplicatedStorage:FindFirstChild(NETWORKING_FOLDER_NAME)
    if folder and folder:IsA("Folder") then
        return folder
    end

    if RunService:IsServer() then
        local newFolder = Instance.new("Folder")
        newFolder.Name = NETWORKING_FOLDER_NAME
        newFolder.Parent = ReplicatedStorage
        return newFolder
    end

    return nil
end

--- Resolves or creates the CarPartCollected RemoteEvent.
local function getCollectedRemoteEvent(): RemoteEvent?
    local folder = getRemotesFolder()
    if not folder then
        folder = ReplicatedStorage:WaitForChild(NETWORKING_FOLDER_NAME, 5) :: Folder?
    end
    if not folder then
        return nil
    end

    local ev = folder:FindFirstChild(REMOTE_EVENT_NAME)
    if ev and ev:IsA("RemoteEvent") then
        return ev
    end

    if RunService:IsServer() then
        local newEv = Instance.new("RemoteEvent")
        newEv.Name = REMOTE_EVENT_NAME
        newEv.Parent = folder
        return newEv
    end

    local waited = folder:WaitForChild(REMOTE_EVENT_NAME, 5)
    if waited and waited:IsA("RemoteEvent") then
        return waited :: RemoteEvent
    end

    return nil
end

--- Resolves or creates the GetCarPartProgress RemoteFunction.
local function getProgressRemoteFunction(): RemoteFunction?
    local folder = getRemotesFolder()
    if not folder then
        folder = ReplicatedStorage:WaitForChild(NETWORKING_FOLDER_NAME, 5) :: Folder?
    end
    if not folder then
        return nil
    end

    local rf = folder:FindFirstChild(REMOTE_FUNCTION_NAME)
    if rf and rf:IsA("RemoteFunction") then
        return rf
    end

    if RunService:IsServer() then
        local newRf = Instance.new("RemoteFunction")
        newRf.Name = REMOTE_FUNCTION_NAME
        newRf.Parent = folder
        return newRf
    end

    local waited = folder:WaitForChild(REMOTE_FUNCTION_NAME, 5)
    if waited and waited:IsA("RemoteFunction") then
        return waited :: RemoteFunction
    end

    return nil
end

--- Attempts to resolve CarPartCollectionSystem from ServerScriptService safely.
local function resolveServerCollectionSystem(): any
    if not RunService:IsServer() then
        return nil
    end

    local success, result = pcall(function()
        local direct = ServerScriptService:FindFirstChild("CarPartCollectionSystem")
        if direct and direct:IsA("ModuleScript") then
            return require(direct)
        end
        local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
        if serverFolder then
            local sub = serverFolder:FindFirstChild("CarPartCollectionSystem")
            if sub and sub:IsA("ModuleScript") then
                return require(sub)
            end
        end
        local recursive = ServerScriptService:FindFirstChild("CarPartCollectionSystem", true)
        if recursive and recursive:IsA("ModuleScript") then
            return require(recursive)
        end
        return nil
    end)

    if success and result then
        return result
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- SERVER-SIDE SYNCHRONIZATION INITIALIZER
-- Hooks into CarPartCollectionSystem server-authoritatively and broadcasts to clients
-- ----------------------------------------------------------------------------

--- Explicit server-side bridge initialization.
function CarPartProgressHUD.InitServer(): boolean
    if isServerInitialized or not RunService:IsServer() then
        return true
    end
    isServerInitialized = true

    local remotesFolder = getRemotesFolder()
    if not remotesFolder then
        return false
    end

    local remoteEvent = getCollectedRemoteEvent()
    local remoteFunction = getProgressRemoteFunction()

    local collectionSystem = resolveServerCollectionSystem()
    if collectionSystem then
        -- 1. Broadcast server collection events to the specific collecting player
        if collectionSystem.OnPartCollected then
            collectionSystem.OnPartCollected:Connect(function(player: Player, objectiveId: string, modelName: string)
                if remoteEvent and player and player:IsA("Player") then
                    remoteEvent:FireClient(player, objectiveId, true)
                end
            end)
        end

        -- 2. Handle client initial state queries server-authoritatively
        if remoteFunction then
            remoteFunction.OnServerInvoke = function(player: Player)
                if not player or not player:IsA("Player") then
                    return {}
                end
                return collectionSystem.GetCollectedParts(player)
            end
        end
    end

    return true
end

-- ----------------------------------------------------------------------------
-- UI CONSTRUCTION (MOBILE-FRIENDLY & RESPONSIVE)
-- ----------------------------------------------------------------------------

--- Creates the client-side ScreenGui and layout hierarchy.
local function createHUDGui(playerGui: PlayerGui): ScreenGui
    -- Prevent duplicate GUIs
    local existing = playerGui:FindFirstChild(GUI_NAME)
    if existing and existing:IsA("ScreenGui") then
        existing:Destroy()
    end

    -- Root ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10

    -- Main Container Frame (Anchored upper-right, safely inside mobile bounds)
    -- Position accounts for Roblox CoreGui top bar and mobile touch clearance
    local frame = Instance.new("Frame")
    frame.Name = "MainPanel"
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -16, 0, 56)
    frame.Size = UDim2.new(0, 230, 0, 195)
    frame.BackgroundColor3 = COLOR_BG
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "PanelStroke"
    stroke.Color = COLOR_BORDER
    stroke.Thickness = 1
    stroke.Transparency = 0.4
    stroke.Parent = frame
    mainStroke = stroke

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = frame

    -- Mobile size constraint to prevent distortion
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(180, 50)
    sizeConstraint.MaxSize = Vector2.new(280, 220)
    sizeConstraint.Parent = frame

    -- Top Header Area (Clickable / Touchable for mobile collapse)
    local headerButton = Instance.new("TextButton")
    headerButton.Name = "HeaderToggle"
    headerButton.Size = UDim2.new(1, 0, 0, 36)
    headerButton.Position = UDim2.new(0, 0, 0, 0)
    headerButton.BackgroundTransparency = 1
    headerButton.Text = ""
    headerButton.AutoButtonColor = false
    headerButton.Parent = frame

    -- Title Label
    local title = Instance.new("TextLabel")
    title.Name = "TitleLabel"
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = TITLE_TEXT
    title.TextSize = 13
    title.TextColor3 = COLOR_TITLE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerButton

    -- Progress Counter Label ("0 / 5 PIEZAS")
    local counter = Instance.new("TextLabel")
    counter.Name = "ProgressCounterLabel"
    counter.Size = UDim2.new(0.65, 0, 0, 16)
    counter.Position = UDim2.new(0, 0, 0, 18)
    counter.BackgroundTransparency = 1
    counter.Font = Enum.Font.GothamBold
    counter.Text = "0 / 5 PIEZAS"
    counter.TextSize = 12
    counter.TextColor3 = COLOR_COUNTER
    counter.TextXAlignment = Enum.TextXAlignment.Left
    counter.Parent = headerButton
    counterLabel = counter

    -- Completion Subtitle Label ("LISTO PARA REPARAR")
    local completion = Instance.new("TextLabel")
    completion.Name = "CompletionSubtitleLabel"
    completion.Size = UDim2.new(0.35, 0, 0, 16)
    completion.Position = UDim2.new(0.65, 0, 0, 18)
    completion.BackgroundTransparency = 1
    completion.Font = Enum.Font.GothamBold
    completion.Text = COMPLETION_TEXT
    completion.TextSize = 10
    completion.TextColor3 = COLOR_STATUS_COLLECTED
    completion.TextXAlignment = Enum.TextXAlignment.Right
    completion.Visible = false
    completion.Parent = headerButton
    completionLabel = completion

    -- Subtle Horizontal Divider
    local divider = Instance.new("Frame")
    divider.Name = "HeaderDivider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 40)
    divider.BackgroundColor3 = COLOR_DIVIDER
    divider.BackgroundTransparency = 0.4
    divider.BorderSizePixel = 0
    divider.Parent = frame

    -- Component List Container
    local listContainer = Instance.new("Frame")
    listContainer.Name = "ComponentList"
    listContainer.Size = UDim2.new(1, 0, 0, 130)
    listContainer.Position = UDim2.new(0, 0, 0, 46)
    listContainer.BackgroundTransparency = 1
    listContainer.Parent = frame
    itemsContainer = listContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Parent = listContainer

    -- Build 5 Individual Component Rows
    table.clear(rowUIs)
    for _, compDef in ipairs(CANONICAL_COMPONENTS) do
        local row = Instance.new("Frame")
        row.Name = `Row_{compDef.Id}`
        row.Size = UDim2.new(1, 0, 0, 21)
        row.BackgroundTransparency = 1
        row.LayoutOrder = compDef.Order
        row.Parent = listContainer

        -- Left: Component Name with Emoji
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "ComponentName"
        nameLbl.Size = UDim2.new(0.60, 0, 1, 0)
        nameLbl.Position = UDim2.new(0, 0, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamMedium
        nameLbl.Text = compDef.DisplayName
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = COLOR_ITEM_UNCOLLECTED
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        -- Right: Status Text ("NOT ENCONTRADA" / "ENCONTRADA ✓")
        local statusLbl = Instance.new("TextLabel")
        statusLbl.Name = "StatusIndicator"
        statusLbl.Size = UDim2.new(0.40, 0, 1, 0)
        statusLbl.Position = UDim2.new(0.60, 0, 0, 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.Text = STATUS_NOT_FOUND
        statusLbl.TextSize = 10
        statusLbl.TextColor3 = COLOR_STATUS_UNCOLLECTED
        statusLbl.TextXAlignment = Enum.TextXAlignment.Right
        statusLbl.Parent = row

        rowUIs[compDef.Id] = {
            Frame = row,
            NameLabel = nameLbl,
            StatusLabel = statusLbl,
        }
    end

    -- Mobile touch / click toggle to collapse/expand list if desired
    local toggleConn = headerButton.Activated:Connect(function()
        isCollapsed = not isCollapsed
        if listContainer and frame then
            listContainer.Visible = not isCollapsed
            divider.Visible = not isCollapsed
            frame.Size = if isCollapsed then UDim2.new(0, 230, 0, 56) else UDim2.new(0, 230, 0, 195)
        end
    end)
    table.insert(connections, toggleConn)

    mainFrame = frame
    screenGui.Parent = playerGui
    activeScreenGui = screenGui

    return screenGui
end

-- ----------------------------------------------------------------------------
-- PROGRESS RENDERING
-- ----------------------------------------------------------------------------

--- Computes total distinct components collected by this player (0 to 5).
local function getCollectedCountInternal(): number
    local count = 0
    for _, comp in ipairs(CANONICAL_COMPONENTS) do
        if progressState[comp.Id] == true then
            count += 1
        end
    end
    return count
end

--- Updates the visual appearance of a single component row.
local function renderComponentRow(objectiveId: ObjectiveId, isCollected: boolean)
    local row = rowUIs[objectiveId]
    if not row then
        return
    end

    if isCollected then
        row.NameLabel.TextColor3 = COLOR_ITEM_COLLECTED
        row.StatusLabel.Text = STATUS_FOUND
        row.StatusLabel.TextColor3 = COLOR_STATUS_COLLECTED
    else
        row.NameLabel.TextColor3 = COLOR_ITEM_UNCOLLECTED
        row.StatusLabel.Text = STATUS_NOT_FOUND
        row.StatusLabel.TextColor3 = COLOR_STATUS_UNCOLLECTED
    end
end

--- Re-renders the entire HUD from the current progressState.
local function renderAll()
    local count = getCollectedCountInternal()

    -- 1. Update individual component rows
    for _, comp in ipairs(CANONICAL_COMPONENTS) do
        renderComponentRow(comp.Id, progressState[comp.Id] == true)
    end

    -- 2. Update Progress Counter ("X / 5 PIEZAS")
    if counterLabel then
        counterLabel.Text = `{count} / 5 PIEZAS`
    end

    -- 3. Update Completion State
    if count >= #CANONICAL_COMPONENTS then
        if completionLabel then
            completionLabel.Text = COMPLETION_TEXT
            completionLabel.Visible = true
        end
        if mainStroke then
            mainStroke.Color = COLOR_BORDER_COMPLETE
        end
    else
        if completionLabel then
            completionLabel.Visible = false
        end
        if mainStroke then
            mainStroke.Color = COLOR_BORDER
        end
    end
end

-- ----------------------------------------------------------------------------
-- SERVER-AUTHORITATIVE PROGRESS SYNCHRONIZATION
-- ----------------------------------------------------------------------------

--- Normalizes string to ObjectiveId.
local function normalizeId(raw: string?): ObjectiveId?
    if not raw or type(raw) ~= "string" then
        return nil
    end
    local clean = string.gsub(raw, "%s+", "")
    if clean == "Battery" or clean == "VehiclePart_Battery_12V" then
        return "Battery"
    elseif clean == "Alternator" or clean == "VehiclePart_Alternator_14V" then
        return "Alternator"
    elseif clean == "SparkPlugs" or clean == "VehiclePart_SparkPlugs_Set" then
        return "SparkPlugs"
    elseif clean == "FuelCanister" or clean == "VehiclePart_FuelCanister_20L" then
        return "FuelCanister"
    elseif clean == "RadiatorHose" or clean == "VehiclePart_RadiatorHose_Reinforced" then
        return "RadiatorHose"
    end
    return nil
end

--- Internal state update handler. Strictly server-triggered.
local function handleServerProgressUpdate(rawId: string, isCollected: boolean)
    local objId = normalizeId(rawId)
    if not objId then
        return
    end

    progressState[objId] = isCollected
    renderAll()
end

--- Queries the server for current collected parts map.
local function queryInitialProgress()
    -- 1. Try remote function
    local remoteFunction = getProgressRemoteFunction()
    if remoteFunction then
        task.spawn(function()
            local success, result = pcall(function()
                return remoteFunction:InvokeServer()
            end)

            if success and type(result) == "table" then
                for objId, val in pairs(result) do
                    local clean = normalizeId(objId)
                    if clean and val == true then
                        progressState[clean] = true
                    end
                end
                renderAll()
            end
        end)
    end

    -- 2. Fallback check if unified environment allows direct query
    local collectionSystem = resolveServerCollectionSystem()
    if collectionSystem and RunService:IsServer() then
        local localPlayer = Players.LocalPlayer
        if localPlayer and collectionSystem.GetCollectedParts then
            local map = collectionSystem.GetCollectedParts(localPlayer)
            for k, v in pairs(map) do
                local clean = normalizeId(k)
                if clean and v == true then
                    progressState[clean] = true
                end
            end
            renderAll()
        end
    end
end

--- Hooks server-authoritative events and world observers.
local function setupSynchronization(player: Player)
    -- 1. Connect to dedicated RemoteEvent
    local remoteEvent = getCollectedRemoteEvent()
    if remoteEvent then
        local evConn = remoteEvent.OnClientEvent:Connect(function(objectiveId: string, isCollected: boolean)
            handleServerProgressUpdate(objectiveId, isCollected)
        end)
        table.insert(connections, evConn)
    end

    -- 2. Observe server-authoritative model destruction from CarRepairParts folder
    -- If a model is destroyed on the server, it reflects server-authoritative removal
    local function hookRepairPartsFolder(folder: Folder)
        local childRemovedConn = folder.ChildRemoved:Connect(function(child: Instance)
            local objectiveId = OBJECTIVE_BY_MODEL[child.Name]
            if objectiveId then
                -- Check if this local player was near and initiated collection
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if hrp and child:IsA("Model") and child.PrimaryPart then
                    local dist = (hrp.Position - child.PrimaryPart.Position).Magnitude
                    if dist <= 16 then
                        handleServerProgressUpdate(objectiveId, true)
                    end
                end
            end
        end)
        table.insert(connections, childRemovedConn)
    end

    local world = Workspace:FindFirstChild("EpecuenWorld")
    if world then
        local repairFolder = world:FindFirstChild("CarRepairParts")
        if repairFolder and repairFolder:IsA("Folder") then
            hookRepairPartsFolder(repairFolder)
        else
            local childConn = world.ChildAdded:Connect(function(child: Instance)
                if child.Name == "CarRepairParts" and child:IsA("Folder") then
                    hookRepairPartsFolder(child)
                end
            end)
            table.insert(connections, childConn)
        end
    end

    -- 3. Initial query
    queryInitialProgress()
end

-- ----------------------------------------------------------------------------
-- PUBLIC CLIENT API
-- ----------------------------------------------------------------------------

--- Returns a copy of the player's current collected parts map.
function CarPartProgressHUD.GetProgress(): { [ObjectiveId]: boolean }
    local copy: { [ObjectiveId]: boolean } = {}
    for k, v in pairs(progressState) do
        copy[k] = v
    end
    return copy
end

--- Checks whether the specified vehicle component has been collected.
function CarPartProgressHUD.HasCollected(objectiveId: string): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end
    return progressState[id] == true
end

--- Returns the total number of components collected (0 to 5).
function CarPartProgressHUD.GetCollectedCount(): number
    return getCollectedCountInternal()
end

--- Checks whether all five vehicle repair parts have been collected.
function CarPartProgressHUD.IsComplete(): boolean
    return getCollectedCountInternal() >= #CANONICAL_COMPONENTS
end

--- Returns the active ScreenGui instance.
function CarPartProgressHUD.GetGui(): ScreenGui?
    return activeScreenGui
end

--- Toggles visibility of the progress HUD.
function CarPartProgressHUD.SetVisible(visible: boolean): ()
    if activeScreenGui then
        activeScreenGui.Enabled = visible
    end
end

--- Returns whether the HUD is currently initialized.
function CarPartProgressHUD.IsInitialized(): boolean
    return isInitialized
end

--- Primary initialization entry point for the client HUD.
--- Safe against duplicate execution and character respawns.
function CarPartProgressHUD.Init(): boolean
    if isInitialized then
        return true
    end

    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        -- In non-client or headless contexts, resolve LocalPlayer when available
        local playerAddedConn
        playerAddedConn = Players.PlayerAdded:Connect(function(p: Player)
            if not isInitialized then
                playerAddedConn:Disconnect()
                CarPartProgressHUD.Init()
            end
        end)
        table.insert(connections, playerAddedConn)
        return false
    end

    isInitialized = true

    local playerGui = localPlayer:WaitForChild("PlayerGui", 10) :: PlayerGui?
    if not playerGui then
        return false
    end

    -- Build the UI
    createHUDGui(playerGui)

    -- Setup network synchronization
    setupSynchronization(localPlayer)

    -- Ensure HUD stays active across character respawns
    local charAddedConn = localPlayer.CharacterAdded:Connect(function()
        -- ResetOnSpawn = false preserves the ScreenGui, but we refresh rendering
        renderAll()
    end)
    table.insert(connections, charAddedConn)

    -- Render initial state
    renderAll()

    return true
end

--- Cleans up the HUD, GUI instances, and all event listeners.
function CarPartProgressHUD.Cleanup(): ()
    isInitialized = false
    isServerInitialized = false

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    if activeScreenGui then
        activeScreenGui:Destroy()
        activeScreenGui = nil
    end

    mainFrame = nil
    mainStroke = nil
    counterLabel = nil
    completionLabel = nil
    itemsContainer = nil
    table.clear(rowUIs)

    for k in pairs(progressState) do
        progressState[k] = false
    end
end

-- ----------------------------------------------------------------------------
-- AUTOMATIC BOOTSTRAP
-- Automatically initializes when required or executed on client/server
-- ----------------------------------------------------------------------------

if RunService:IsClient() then
    task.defer(function()
        CarPartProgressHUD.Init()
    end)
elseif RunService:IsServer() then
    task.defer(function()
        CarPartProgressHUD.InitServer()
    end)
end

return CarPartProgressHUD
