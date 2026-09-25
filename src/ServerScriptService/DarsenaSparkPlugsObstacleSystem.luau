--!strict
--[[
    DarsenaSparkPlugsObstacleSystem.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/DarsenaSparkPlugsObstacleSystem.luau

    Description:
        Server-side environmental obstacle system protecting the Set of Spark Plugs
        (VehiclePart_SparkPlugs_Set) at Dársena Central (Pier Crate Stack).

        Access to the crate stack at the southern tip of the lakeside pier is obstructed
        by a collapsed wooden pier section consisting of waterlogged timber beams,
        splintered deck planks, rusted iron mooring bitts, corroded steel brackets,
        heavy salt/calcium encrustations, and shallow brine wash across the damaged deck.

        Players must approach and interact with the obstruction ("Despejar" /
        "Restos del muelle") to physically clear access to the crate stack.

        Authoritative Guarantees:
        - Native Roblox geometry only (Part, WedgePart, CornerWedgePart, Cylinder).
        - ZERO MeshParts, external assets, asset IDs, textures, or decals.
        - Does NOT move the Spark Plugs (VehiclePart_SparkPlugs_Set) or its hideout.
        - Does NOT collect the Spark Plugs automatically.
        - The Spark Plugs ProximityPrompt remains 100% managed by CarPartCollectionSystem.
        - Safe in multiplayer: clearing removes the obstruction for the shared world,
          allowing all players to enter and collect on their individual progress tracks.
        - Exposes idempotent Initialize() and Clear().
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local DarsenaSparkPlugsObstacleSystem = {}

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL PLACEMENT
-- ----------------------------------------------------------------------------
local OBSTACLE_MODEL_NAME = "Obstacle_SparkPlugs_Darsena_PierCrateStack"
local PROMPT_NAME = "ObstacleDockPrompt"
local PROMPT_ACTION_TEXT = "Despejar"
local PROMPT_OBJECT_TEXT = "Restos del muelle"
local PROMPT_HOLD_DURATION = 1.5
local PROMPT_MAX_ACTIVATION_DISTANCE = 8.0

-- Canonical Spark Plugs hideout coordinates at Dársena Central pier tip
local CANONICAL_SPARK_PLUGS_POSITION = Vector3.new(-160, -1, 700)
local CANONICAL_SPARK_PLUGS_ROTATION_Y = 0

-- Color palette matching Epecuén shoreline pier decay, brine, and mineral salt
local COLOR_WATERLOGGED_TIMBER = Color3.fromRGB(56, 48, 40)
local COLOR_WEATHERED_PLANK = Color3.fromRGB(108, 98, 86)
local COLOR_ROTTED_WOOD = Color3.fromRGB(72, 60, 48)
local COLOR_RUSTED_IRON = Color3.fromRGB(84, 48, 28)
local COLOR_CORRODED_STEEL = Color3.fromRGB(96, 60, 40)
local COLOR_SALT_WHITE = Color3.fromRGB(226, 228, 222)
local COLOR_SALT_CRUST = Color3.fromRGB(208, 210, 202)
local COLOR_BRINE_WATER = Color3.fromRGB(48, 66, 64)

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

local function makeCornerWedge(parent: Instance, props: { [string]: any }): CornerWedgePart
    local corner = Instance.new("CornerWedgePart")
    corner.Anchored = true
    corner.CanCollide = true
    corner.TopSurface = Enum.TopSurface.Smooth
    corner.BottomSurface = Enum.BottomSurface.Smooth
    for k, v in pairs(props) do
        (corner :: any)[k] = v
    end
    corner.Parent = parent
    return corner
end

local function makeCylinder(parent: Instance, props: { [string]: any }): Part
    local cylinder = Instance.new("Part")
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Anchored = true
    cylinder.CanCollide = true
    cylinder.TopSurface = Enum.TopSurface.Smooth
    cylinder.BottomSurface = Enum.BottomSurface.Smooth
    for k, v in pairs(props) do
        (cylinder :: any)[k] = v
    end
    cylinder.Parent = parent
    return cylinder
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

--- Resolves the root CFrame of the Dársena Pier Crate Stack hideout.
--- If the physical hideout already exists in Workspace, derives its exact foundation CFrame.
local function resolveHideoutRootCF(): CFrame
    local world = getEpecuenWorld()
    if world then
        local hideoutsFolder = world:FindFirstChild("CarPartHideouts")
        if hideoutsFolder then
            local hideout = hideoutsFolder:FindFirstChild("Hideout_SparkPlugs_Darsena_PierCrateStack")
            if hideout and hideout:IsA("Model") then
                local runner = hideout:FindFirstChild("Crates_Runner2")
                if runner and runner:IsA("BasePart") then
                    return runner.CFrame * CFrame.new(0, -0.18, 0)
                end
                local primary = hideout.PrimaryPart or hideout:FindFirstChildWhichIsA("BasePart")
                if primary then
                    return CFrame.new(primary.Position.X, -1, primary.Position.Z)
                end
            end
        end
    end
    return CFrame.new(CANONICAL_SPARK_PLUGS_POSITION) * CFrame.Angles(0, math.rad(CANONICAL_SPARK_PLUGS_ROTATION_Y), 0)
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL OBSTACLE MODEL BUILDER
-- ----------------------------------------------------------------------------
--- Builds the physical collapsed pier obstruction blocking the walkway access
--- to the crate stack at Dársena Central.
--- Placement is immediately north of the crates (Z ~ 696.8 in world space),
--- directly obstructing players approaching the pier tip from the promenade.
local function buildObstacleModel(rootCF: CFrame, parent: Instance): Model
    local model = Instance.new("Model")
    model.Name = OBSTACLE_MODEL_NAME
    model:SetAttribute("IsObstacle", true)
    model:SetAttribute("TargetObjective", "SparkPlugs")
    model:SetAttribute("ZoneId", "ZONE_SHORELINE")
    model:SetAttribute("AssociatedHideout", "Hideout_SparkPlugs_Darsena_PierCrateStack")

    -- Primary interaction Part (invisible core serving as PrimaryPart and prompt host)
    -- Placed directly across the center of the collapsed access zone
    local primaryPart = makePart(model, {
        Name = "Obstacle_PrimaryCore",
        Size = Vector3.new(5.2, 3.2, 1.2),
        CFrame = rootCF * CFrame.new(0, 1.6, -3.2),
        Transparency = 1,
        CanCollide = true,
        CanQuery = true,
        CanTouch = true,
    })
    model.PrimaryPart = primaryPart

    -- 1. Main Heavy Collapsed Mooring Timber (large log lying diagonally across the walkway)
    makeCylinder(model, {
        Name = "Pier_MooringBeamMain",
        Size = Vector3.new(5.8, 0.75, 0.75),
        CFrame = rootCF * CFrame.new(-0.2, 1.1, -3.2) * CFrame.Angles(0, math.rad(14), math.rad(78)),
        Material = Enum.Material.Wood,
        Color = COLOR_WATERLOGGED_TIMBER,
    })

    -- 2. Secondary Broken Timber Pile (supporting the fallen beam on the left)
    makePart(model, {
        Name = "Pier_SupportTimberLeft",
        Size = Vector3.new(0.6, 2.8, 0.6),
        CFrame = rootCF * CFrame.new(-2.2, 1.3, -3.1) * CFrame.Angles(math.rad(12), 0, math.rad(-25)),
        Material = Enum.Material.Wood,
        Color = COLOR_ROTTED_WOOD,
    })

    -- 3. Collapsed Splintered Pier Deck Planks (angled upward against the beam)
    makePart(model, {
        Name = "Pier_CollapsedPlank_1",
        Size = Vector3.new(1.8, 0.22, 3.2),
        CFrame = rootCF * CFrame.new(-0.8, 1.2, -3.3) * CFrame.Angles(math.rad(-28), math.rad(8), math.rad(6)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_PLANK,
    })

    makePart(model, {
        Name = "Pier_CollapsedPlank_2",
        Size = Vector3.new(1.6, 0.22, 2.9),
        CFrame = rootCF * CFrame.new(0.7, 1.3, -3.1) * CFrame.Angles(math.rad(-22), math.rad(-12), math.rad(-8)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_PLANK,
    })

    makePart(model, {
        Name = "Pier_BrokenPlank_Cross",
        Size = Vector3.new(3.8, 0.25, 0.9),
        CFrame = rootCF * CFrame.new(0.1, 1.8, -3.0) * CFrame.Angles(math.rad(10), math.rad(18), math.rad(-14)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_ROTTED_WOOD,
    })

    -- 4. Broken Mooring Bitt / Bollard (cast-iron bollard sheared from pier deck)
    makeCylinder(model, {
        Name = "Pier_MooringBittColumn",
        Size = Vector3.new(1.4, 0.55, 0.55),
        CFrame = rootCF * CFrame.new(1.9, 0.9, -3.4) * CFrame.Angles(math.rad(18), 0, math.rad(90)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUSTED_IRON,
    })

    makePart(model, {
        Name = "Pier_MooringBittCap",
        Size = Vector3.new(0.7, 0.2, 0.7),
        CFrame = rootCF * CFrame.new(1.9, 1.6, -3.3) * CFrame.Angles(math.rad(18), 0, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUSTED_IRON,
    })

    -- 5. Rusted Iron Structural Brackets & Straps (binding decayed timbers together)
    makePart(model, {
        Name = "Pier_RustedStrapLeft",
        Size = Vector3.new(0.12, 1.4, 0.8),
        CFrame = rootCF * CFrame.new(-1.8, 1.6, -3.15) * CFrame.Angles(0, math.rad(14), math.rad(-20)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_STEEL,
    })

    makePart(model, {
        Name = "Pier_RustedStrapMid",
        Size = Vector3.new(0.8, 0.12, 0.8),
        CFrame = rootCF * CFrame.new(0.3, 1.5, -3.05) * CFrame.Angles(math.rad(12), 0, math.rad(15)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_STEEL,
    })

    -- 6. Tangled Heavy Mooring Cable / Steel Wire Remnant (draped across the timbers)
    makeCylinder(model, {
        Name = "Pier_MooringCableSegment1",
        Size = Vector3.new(2.8, 0.16, 0.16),
        CFrame = rootCF * CFrame.new(-0.5, 1.6, -2.85) * CFrame.Angles(math.rad(22), math.rad(-25), math.rad(45)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUSTED_IRON,
        CanCollide = false,
    })

    makeCylinder(model, {
        Name = "Pier_MooringCableSegment2",
        Size = Vector3.new(2.4, 0.16, 0.16),
        CFrame = rootCF * CFrame.new(1.1, 1.3, -2.9) * CFrame.Angles(math.rad(-15), math.rad(35), math.rad(-55)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUSTED_IRON,
        CanCollide = false,
    })

    -- 7. Heavy Salt and Calcium Mineral Crust Formations (from decades of hypersaline immersion)
    makePart(model, {
        Name = "Pier_SaltCrustBase",
        Size = Vector3.new(4.8, 0.3, 1.1),
        CFrame = rootCF * CFrame.new(0, 0.45, -3.3),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })

    makeWedge(model, {
        Name = "Pier_SaltWedgeLeft",
        Size = Vector3.new(1.4, 0.65, 1.2),
        CFrame = rootCF * CFrame.new(-2.0, 0.6, -3.2) * CFrame.Angles(0, math.rad(15), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    makeCornerWedge(model, {
        Name = "Pier_SaltCornerRight",
        Size = Vector3.new(1.2, 0.6, 1.1),
        CFrame = rootCF * CFrame.new(1.8, 0.55, -3.3) * CFrame.Angles(0, math.rad(-20), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- 8. Scattered Pier Deck Timber Splinters (flanking base)
    makeWedge(model, {
        Name = "Pier_SplinterBlockA",
        Size = Vector3.new(0.5, 0.4, 1.4),
        CFrame = rootCF * CFrame.new(-1.1, 0.5, -3.8) * CFrame.Angles(0, math.rad(40), 0),
        Material = Enum.Material.Wood,
        Color = COLOR_ROTTED_WOOD,
    })

    makePart(model, {
        Name = "Pier_SplinterBlockB",
        Size = Vector3.new(0.35, 0.35, 1.2),
        CFrame = rootCF * CFrame.new(1.2, 0.45, -3.9) * CFrame.Angles(math.rad(8), math.rad(-30), 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WATERLOGGED_TIMBER,
    })

    -- 9. Shallow Environmental Brine Water Layer (non-hazardous puddle around collapsed deck)
    makePart(model, {
        Name = "Pier_ShallowBrinePool",
        Size = Vector3.new(5.0, 0.08, 2.4),
        CFrame = rootCF * CFrame.new(0, 0.28, -3.4),
        Material = Enum.Material.Glass,
        Color = COLOR_BRINE_WATER,
        Transparency = 0.55,
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
        error("[DarsenaSparkPlugsObstacleSystem] Obstacle model missing valid primary BasePart for ProximityPrompt.")
    end

    -- Clean up any existing prompt if present
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

    -- Handle prompt activation: removes the obstruction and opens access to the crates
    promptTriggerConnection = prompt.Triggered:Connect(function(player: Player)
        if isCleared then
            return
        end

        print(string.format("[DarsenaSparkPlugsObstacleSystem] Player '%s' cleared the collapsed pier obstruction.", player.Name))

        -- Execute obstacle removal to open physical access to the Spark Plugs crate stack
        DarsenaSparkPlugsObstacleSystem.Clear()
    end)

    prompt.Parent = primaryPart
    return prompt
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Initializes the Dársena Central Spark Plugs environmental obstacle.
--- Idempotent: safe to call multiple times without duplicating geometry or connections.
function DarsenaSparkPlugsObstacleSystem.Initialize(): boolean
    if isCleared then
        -- Obstacle has already been cleared in this game session; remain cleared
        return true
    end

    if isInitialized and activeObstacleModel and activeObstacleModel.Parent ~= nil then
        -- Already initialized and active
        return true
    end

    -- Check if an obstacle model already exists in the world
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

    -- Build the obstacle model immediately before the crate stack walkway
    local hideoutRootCF = resolveHideoutRootCF()
    local model = buildObstacleModel(hideoutRootCF, envFolder)
    activeObstacleModel = model
    activePrompt = setupObstaclePrompt(model)
    isInitialized = true

    print(string.format("[DarsenaSparkPlugsObstacleSystem] Initialized obstacle '%s' at (%d, %d, %d).",
        OBSTACLE_MODEL_NAME,
        hideoutRootCF.Position.X,
        hideoutRootCF.Position.Y,
        hideoutRootCF.Position.Z
    ))

    return true
end

--- Clears and destroys the environmental obstacle, opening physical access to the crate stack.
--- Removes ONLY the obstacle created by this system.
--- Does NOT touch the Spark Plugs, the crate stack hideout, or the CarPartCollectionSystem.
function DarsenaSparkPlugsObstacleSystem.Clear(): ()
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
            -- Cleanly destroy the obstacle model from Workspace
            modelToDestroy:Destroy()
        end
    end

    print("[DarsenaSparkPlugsObstacleSystem] Obstacle successfully cleared. Pier crate stack is now accessible.")
end

--- Returns whether the obstacle has been cleared.
function DarsenaSparkPlugsObstacleSystem.IsCleared(): boolean
    return isCleared
end

--- Returns the active obstacle Model if still present in the world.
function DarsenaSparkPlugsObstacleSystem.GetModel(): Model?
    return activeObstacleModel
end

--- Returns the active ProximityPrompt if still present in the world.
function DarsenaSparkPlugsObstacleSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

return DarsenaSparkPlugsObstacleSystem
