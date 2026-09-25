--!strict
--[[
    FuelCanisterTerminalObstacleSystem.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/FuelCanisterTerminalObstacleSystem.luau

    Description:
        Server-side environmental obstacle system protecting the 20L Fuel Canister
        at the Terminal de Ómnibus Epecuén (Luggage Cabinet hideout).

        Access to the luggage cabinet storage alcove is blocked by toppled
        corroded metal storage lockers, old weathered baggage, salt-crusted wooden
        planks, and concrete debris.

        Players must approach and interact with the obstruction ("Apartar" /
        "Equipaje y escombros") to physically clear access to the fuel canister storage.

        Authoritative Guarantees:
        - Native Roblox geometry only (Part, WedgePart, CornerWedgePart, Cylinder).
        - ZERO MeshParts, external assets, asset IDs, textures, or decals.
        - Does NOT move the Fuel Canister (VehiclePart_FuelCanister_20L) or its hideout.
        - Does NOT collect the Fuel Canister automatically.
        - The Fuel Canister ProximityPrompt remains 100% managed by CarPartCollectionSystem.
        - Safe in multiplayer: clearing removes the physical obstruction for the world,
          allowing all players to investigate and collect on their own progress track.
        - Exposes idempotent Initialize() and Clear().
        - NO automatic initialization on module load.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local FuelCanisterTerminalObstacleSystem = {}

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL PLACEMENT
-- ----------------------------------------------------------------------------
local OBSTACLE_MODEL_NAME = "Obstacle_FuelCanister_Terminal_LuggageCabinet"
local PROMPT_NAME = "ObstacleTerminalPrompt"
local PROMPT_ACTION_TEXT = "Apartar"
local PROMPT_OBJECT_TEXT = "Equipaje y escombros"
local PROMPT_HOLD_DURATION = 1.5
local PROMPT_MAX_ACTIVATION_DISTANCE = 8.0

-- Canonical Terminal hideout coordinates for FuelCanister
local CANONICAL_TERMINAL_POSITION = Vector3.new(-120, 18, -670)
local CANONICAL_TERMINAL_ROTATION_Y = 0

-- Color palette matching Epecuen terminal ruins, corroded lockers, and salt deposits
local COLOR_LOCKER_RUST = Color3.fromRGB(88, 54, 38)
local COLOR_LOCKER_ORANGE = Color3.fromRGB(122, 65, 40)
local COLOR_WEATHERED_WOOD = Color3.fromRGB(120, 102, 85)
local COLOR_CONCRETE_GRAY = Color3.fromRGB(145, 140, 134)
local COLOR_CONCRETE_PALE = Color3.fromRGB(172, 168, 160)
local COLOR_OLD_LEATHER = Color3.fromRGB(72, 55, 42)
local COLOR_SALT_WHITE = Color3.fromRGB(230, 232, 226)

-- ----------------------------------------------------------------------------
-- INTERNAL STATE
-- ----------------------------------------------------------------------------
local isInitialized: boolean = false
local isCleared: boolean = false
local activeObstacleModel: Model? = nil
local activePrompt: ProximityPrompt? = nil
local promptTriggerConnection: RBXScriptConnection? = nil

-- ----------------------------------------------------------------------------
-- HELPER BUILDERS (Native Geometry Only)
-- ----------------------------------------------------------------------------
local function makePart(parent: Instance, props: { [string]: any }): Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = true
    part.TopSurface = Enum.TopSurface.Smooth
    part.BottomSurface = Enum.BottomSurface.Smooth
    for k, v in pairs(props) do
        (part :: any)[k] = v
    end
    part.Parent = parent
    return part
end

local function makeWedge(parent: Instance, props: { [string]: any }): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Anchored = true
    wedge.CanCollide = true
    wedge.TopSurface = Enum.TopSurface.Smooth
    wedge.BottomSurface = Enum.BottomSurface.Smooth
    for k, v in pairs(props) do
        (wedge :: any)[k] = v
    end
    wedge.Parent = parent
    return wedge
end

-- ----------------------------------------------------------------------------
-- RESOLUTION HELPERS
-- ----------------------------------------------------------------------------
local function getEpecuenWorld(): Instance?
    return Workspace:FindFirstChild("EpecuenWorld")
end

local function getEnvironmentFolder(): Instance
    local world = getEpecuenWorld()
    if world then
        local env = world:FindFirstChild("EnvironmentDetails")
        if env then
            return env
        end
        return world
    end
    return Workspace
end

--- Resolves the root CFrame of the Terminal hideout.
--- If the physical hideout already exists in Workspace, derives its exact foundation CFrame.
local function resolveCabinetRootCF(): CFrame
    local world = getEpecuenWorld()
    if world then
        local hideoutsFolder = world:FindFirstChild("CarPartHideouts")
        if hideoutsFolder then
            local hideout = hideoutsFolder:FindFirstChild("Hideout_FuelCanister_Terminal_LuggageCabinet")
            if hideout and hideout:IsA("Model") then
                local hidePoint = hideout:FindFirstChild("HidePoint")
                if hidePoint and hidePoint:IsA("BasePart") then
                    return hidePoint.CFrame
                end
                local primary = hideout.PrimaryPart or hideout:FindFirstChildWhichIsA("BasePart")
                if primary then
                    return CFrame.new(primary.Position.X, primary.Position.Y, primary.Position.Z)
                end
            end
        end
    end
    return CFrame.new(CANONICAL_TERMINAL_POSITION) * CFrame.Angles(0, math.rad(CANONICAL_TERMINAL_ROTATION_Y), 0)
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL OBSTACLE MODEL BUILDER
-- ----------------------------------------------------------------------------
--- Builds the physical toppled lockers and debris obstruction blocking access to the luggage cabinet.
local function buildObstacleModel(rootCF: CFrame, parent: Instance): Model
    local model = Instance.new("Model")
    model.Name = OBSTACLE_MODEL_NAME
    model:SetAttribute("IsObstacle", true)
    model:SetAttribute("TargetObjective", "FuelCanister")
    model:SetAttribute("ZoneId", "ZONE_TERMINAL")
    model:SetAttribute("AssociatedHideout", "Hideout_FuelCanister_Terminal_LuggageCabinet")

    -- Primary interaction Part (invisible core serving as PrimaryPart and prompt host)
    local primaryPart = makePart(model, {
        Name = "Obstacle_PrimaryCore",
        Size = Vector3.new(3.8, 3.2, 0.8),
        CFrame = rootCF * CFrame.new(0, 1.6, 2.0),
        Transparency = 1,
        CanCollide = true,
        CanQuery = true,
        CanTouch = true,
    })
    model.PrimaryPart = primaryPart

    -- 1. Toppled Metal Storage Locker Body
    makePart(model, {
        Name = "Obstacle_ToppledLockerBody",
        Size = Vector3.new(3.4, 3.8, 1.4),
        CFrame = rootCF * CFrame.new(0.1, 1.8, 1.9) * CFrame.Angles(math.rad(12), math.rad(-8), math.rad(22)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_LOCKER_RUST,
    })

    -- 2. Warped Locker Door Hanging Open / Blockading
    makePart(model, {
        Name = "Obstacle_WarpedLockerDoor",
        Size = Vector3.new(1.4, 3.6, 0.15),
        CFrame = rootCF * CFrame.new(-1.2, 1.7, 2.2) * CFrame.Angles(math.rad(8), math.rad(35), math.rad(-14)),
        Material = Enum.Material.Metal,
        Color = COLOR_LOCKER_ORANGE,
    })

    -- 3. Old Weathered Suitcases / Luggage Stacked in Front
    makePart(model, {
        Name = "Obstacle_OldSuitcaseA",
        Size = Vector3.new(1.6, 1.1, 1.0),
        CFrame = rootCF * CFrame.new(1.0, 0.7, 2.1) * CFrame.Angles(math.rad(5), math.rad(-20), math.rad(10)),
        Material = Enum.Material.Wood,
        Color = COLOR_OLD_LEATHER,
    })

    makePart(model, {
        Name = "Obstacle_OldSuitcaseB",
        Size = Vector3.new(1.2, 0.8, 0.9),
        CFrame = rootCF * CFrame.new(0.6, 1.5, 2.2) * CFrame.Angles(math.rad(-10), math.rad(15), math.rad(-25)),
        Material = Enum.Material.Fabric,
        Color = COLOR_OLD_LEATHER,
    })

    -- 4. Broken Wooden Terminal Bench Planks
    makePart(model, {
        Name = "Obstacle_BrokenBenchPlank",
        Size = Vector3.new(3.8, 0.3, 0.45),
        CFrame = rootCF * CFrame.new(-0.2, 0.5, 2.3) * CFrame.Angles(math.rad(18), math.rad(-12), math.rad(-38)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_WOOD,
    })

    -- 5. Concrete Masonry Rubble Chunk
    makeWedge(model, {
        Name = "Obstacle_TerminalDebrisWedge",
        Size = Vector3.new(1.5, 0.9, 1.3),
        CFrame = rootCF * CFrame.new(-1.4, 0.6, 2.0) * CFrame.Angles(0, math.rad(40), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_GRAY,
    })

    -- 6. Fallen Wall Panel Debris
    makePart(model, {
        Name = "Obstacle_FallenWallPanel",
        Size = Vector3.new(2.2, 1.6, 0.2),
        CFrame = rootCF * CFrame.new(1.3, 2.4, 1.8) * CFrame.Angles(math.rad(-14), math.rad(28), math.rad(16)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- 7. Evaporite Salt Crust Layers Encrusting the Obstacle
    makePart(model, {
        Name = "Obstacle_SaltCrustTop",
        Size = Vector3.new(3.2, 0.22, 1.2),
        CFrame = rootCF * CFrame.new(0.2, 3.5, 1.9) * CFrame.Angles(math.rad(12), math.rad(-8), math.rad(22)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
        CanCollide = false,
    })

    makePart(model, {
        Name = "Obstacle_SaltCrustBase",
        Size = Vector3.new(3.6, 0.3, 1.5),
        CFrame = rootCF * CFrame.new(0, 0.2, 2.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
        CanCollide = false,
    })

    model.Parent = parent
    return model
end

-- ----------------------------------------------------------------------------
-- PROXIMITY PROMPT SETUP & INTERACTION LIFECYCLE
-- ----------------------------------------------------------------------------
--- Arms the single authoritative ProximityPrompt on the obstacle.
local function setupObstaclePrompt(obstacleModel: Model): ProximityPrompt
    local primaryPart = obstacleModel.PrimaryPart or obstacleModel:FindFirstChild("Obstacle_PrimaryCore")
    if not primaryPart or not primaryPart:IsA("BasePart") then
        error("[FuelCanisterTerminalObstacleSystem] Obstacle model missing valid primary BasePart for ProximityPrompt.")
    end

    local existingPrompt = primaryPart:FindFirstChild(PROMPT_NAME) :: ProximityPrompt?
    if existingPrompt and existingPrompt:IsA("ProximityPrompt") then
        return existingPrompt
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = PROMPT_NAME
    prompt.ActionText = PROMPT_ACTION_TEXT
    prompt.ObjectText = PROMPT_OBJECT_TEXT
    prompt.HoldDuration = PROMPT_HOLD_DURATION
    prompt.MaxActivationDistance = PROMPT_MAX_ACTIVATION_DISTANCE
    prompt.RequiresLineOfSight = true
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton

    -- Handle prompt activation: removes the obstruction and opens access
    promptTriggerConnection = prompt.Triggered:Connect(function(player: Player)
        if isCleared then
            return
        end

        print(string.format("[FuelCanisterTerminalObstacleSystem] Player '%s' cleared the terminal obstruction.", player.Name))

        -- Execute obstacle removal to open physical access to the luggage cabinet hideout
        FuelCanisterTerminalObstacleSystem.Clear()
    end)

    prompt.Parent = primaryPart
    return prompt
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Initializes the Terminal FuelCanister obstacle.
--- Idempotent: safe to call multiple times without duplicating geometry or connections.
function FuelCanisterTerminalObstacleSystem.Initialize(): boolean
    if isCleared then
        return true
    end

    if isInitialized and activeObstacleModel and activeObstacleModel.Parent ~= nil then
        return true
    end

    local envFolder = getEnvironmentFolder()
    local existingModel = envFolder:FindFirstChild(OBSTACLE_MODEL_NAME)
    if not existingModel then
        local world = getEpecuenWorld()
        if world then
            existingModel = world:FindFirstChild(OBSTACLE_MODEL_NAME, true)
        end
    end

    if existingModel and existingModel:IsA("Model") then
        activeObstacleModel = existingModel
        activePrompt = setupObstaclePrompt(existingModel)
        isInitialized = true
        return true
    end

    local rootCF = resolveCabinetRootCF()
    local model = buildObstacleModel(rootCF, envFolder)
    activeObstacleModel = model
    activePrompt = setupObstaclePrompt(model)
    isInitialized = true

    print(string.format("[FuelCanisterTerminalObstacleSystem] Initialized obstacle '%s' at (%d, %d, %d).",
        OBSTACLE_MODEL_NAME,
        rootCF.Position.X,
        rootCF.Position.Y,
        rootCF.Position.Z
    ))

    return true
end

--- Clears and destroys the environmental obstacle, opening physical access to the luggage cabinet.
--- Removes ONLY the obstacle created by this system.
--- Does NOT touch the Fuel Canister, the hideout, or the CarPartCollectionSystem.
function FuelCanisterTerminalObstacleSystem.Clear(): ()
    isCleared = true

    if promptTriggerConnection then
        promptTriggerConnection:Disconnect()
        promptTriggerConnection = nil
    end

    activePrompt = nil

    if activeObstacleModel then
        local modelToDestroy = activeObstacleModel
        activeObstacleModel = nil

        if modelToDestroy.Parent ~= nil then
            modelToDestroy:Destroy()
        end
    end

    print("[FuelCanisterTerminalObstacleSystem] Obstacle successfully cleared. Luggage cabinet hideout is now accessible.")
end

--- Returns whether the obstacle has been cleared.
function FuelCanisterTerminalObstacleSystem.IsCleared(): boolean
    return isCleared
end

--- Returns the active obstacle Model if still present in the world.
function FuelCanisterTerminalObstacleSystem.GetModel(): Model?
    return activeObstacleModel
end

--- Returns the active ProximityPrompt if still present in the world.
function FuelCanisterTerminalObstacleSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

return FuelCanisterTerminalObstacleSystem
