--!strict
--[[
    HotelBatteryObstacleSystem.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/HotelBatteryObstacleSystem.luau

    Description:
        Server-side environmental obstacle system protecting the 12V Battery
        at the Hotel Monte Real generator shed.

        The generator shed entrance is obstructed by a collapsed steel security
        gate, salt-encrusted timber bracing, and fallen masonry rubble.
        Players must investigate and interact with the obstruction ("Apartar")
        to physically clear access to the shed interior.

        Authoritative Guarantees:
        - Native Roblox geometry only (Part, WedgePart, CornerWedgePart, Cylinder).
        - ZERO MeshParts, external assets, or asset IDs.
        - Does NOT move the Battery (VehiclePart_Battery_12V) or its hideout.
        - Does NOT collect the Battery automatically.
        - The Battery ProximityPrompt remains 100% managed by CarPartCollectionSystem.
        - Safe in multiplayer: clearing removes the physical obstruction for the world,
          allowing all players to investigate and collect on their own progress track.
        - Exposes idempotent Initialize() and Clear().
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local HotelBatteryObstacleSystem = {}

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL PLACEMENT
-- ----------------------------------------------------------------------------
local OBSTACLE_MODEL_NAME = "Obstacle_Battery_HotelMonteReal_GeneratorShed"
local PROMPT_NAME = "ObstacleClearPrompt"
local PROMPT_ACTION_TEXT = "Apartar"
local PROMPT_OBJECT_TEXT = "Obstrucción"
local PROMPT_HOLD_DURATION = 1.5
local PROMPT_MAX_ACTIVATION_DISTANCE = 8.0

-- Canonical generator shed coordinates at Hotel Monte Real rear yard
local CANONICAL_SHED_POSITION = Vector3.new(410, 11, -190)
local CANONICAL_SHED_ROTATION_Y = 0

-- Color palette matching Epecuen salt ruins and corroded industrial metal
local COLOR_RUST_DARK = Color3.fromRGB(90, 52, 32)
local COLOR_RUST_ORANGE = Color3.fromRGB(128, 68, 38)
local COLOR_WEATHERED_WOOD = Color3.fromRGB(135, 125, 110)
local COLOR_CONCRETE_GRAY = Color3.fromRGB(148, 144, 138)
local COLOR_CONCRETE_PALE = Color3.fromRGB(175, 172, 166)
local COLOR_BRICK_RED = Color3.fromRGB(145, 75, 60)
local COLOR_SALT_WHITE = Color3.fromRGB(228, 230, 224)
local COLOR_WARNING_YELLOW = Color3.fromRGB(165, 138, 48)

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

--- Resolves the root CFrame of the generator shed.
--- If the physical hideout already exists in Workspace, derives its exact foundation CFrame.
local function resolveShedRootCF(): CFrame
    local world = getEpecuenWorld()
    if world then
        local hideoutsFolder = world:FindFirstChild("CarPartHideouts")
        if hideoutsFolder then
            local shed = hideoutsFolder:FindFirstChild("Hideout_Battery_HotelMonteReal_GeneratorShed")
            if shed and shed:IsA("Model") then
                local foundation = shed:FindFirstChild("Shed_Foundation")
                if foundation and foundation:IsA("BasePart") then
                    -- Foundation was offset by CFrame.new(0, 0.25, 0) relative to shed root
                    return foundation.CFrame * CFrame.new(0, -0.25, 0)
                end
                local primary = shed.PrimaryPart or shed:FindFirstChildWhichIsA("BasePart")
                if primary then
                    return CFrame.new(primary.Position.X, 11, primary.Position.Z)
                end
            end
        end
    end
    return CFrame.new(CANONICAL_SHED_POSITION) * CFrame.Angles(0, math.rad(CANONICAL_SHED_ROTATION_Y), 0)
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL OBSTACLE MODEL BUILDER
-- ----------------------------------------------------------------------------
--- Builds the physical collapsed obstruction blocking the doorway of the generator shed.
--- Doorway coordinates: centered at rootCF * CFrame.new(0, 2.5, 2.3)
local function buildObstacleModel(rootCF: CFrame, parent: Instance): Model
    local model = Instance.new("Model")
    model.Name = OBSTACLE_MODEL_NAME
    model:SetAttribute("IsObstacle", true)
    model:SetAttribute("TargetObjective", "Battery")
    model:SetAttribute("ZoneId", "ZONE_HOTEL_MONTE_REAL")
    model:SetAttribute("AssociatedHideout", "Hideout_Battery_HotelMonteReal_GeneratorShed")

    -- Primary interaction Part (invisible core serving as PrimaryPart and prompt host)
    -- Placed directly across the center of the doorway opening
    local primaryPart = makePart(model, {
        Name = "Obstacle_PrimaryCore",
        Size = Vector3.new(4.2, 3.6, 0.8),
        CFrame = rootCF * CFrame.new(0, 2.4, 2.25),
        Transparency = 1,
        CanCollide = true,
        CanQuery = true,
        CanTouch = true,
    })
    model.PrimaryPart = primaryPart

    -- 1. Main Collapsed Steel Gate (tilted and violently wedged into the concrete door jambs)
    makePart(model, {
        Name = "Obstacle_CollapsedGateFrame",
        Size = Vector3.new(4.4, 3.4, 0.25),
        CFrame = rootCF * CFrame.new(0.1, 2.3, 2.2) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_ORANGE,
    })

    -- 2. Heavy Upper Angle-Iron Header Bar
    makePart(model, {
        Name = "Obstacle_GateHeaderBar",
        Size = Vector3.new(4.5, 0.35, 0.35),
        CFrame = rootCF * CFrame.new(0.05, 3.9, 2.05) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- 3. Heavy Lower Threshold Iron Bar
    makePart(model, {
        Name = "Obstacle_GateBottomBar",
        Size = Vector3.new(4.5, 0.35, 0.35),
        CFrame = rootCF * CFrame.new(0.15, 0.8, 2.35) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- 4. Five Vertical Security Grate Bars
    local barXOffsets = { -1.6, -0.8, 0.0, 0.8, 1.6 }
    for i, xOff in ipairs(barXOffsets) do
        makePart(model, {
            Name = "Obstacle_GrateBar_" .. tostring(i),
            Size = Vector3.new(0.18, 3.2, 0.18),
            CFrame = rootCF * CFrame.new(xOff + 0.1, 2.3, 2.2) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(8)),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
        })
    end

    -- 5. Heavy Collapsed Timber Bracing Beam (fallen diagonal beam pinning the gate shut)
    makePart(model, {
        Name = "Obstacle_CollapsedTimberBeam",
        Size = Vector3.new(0.5, 4.4, 0.5),
        CFrame = rootCF * CFrame.new(-0.2, 2.4, 2.4) * CFrame.Angles(math.rad(-14), math.rad(12), math.rad(-34)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_WOOD,
    })

    -- 6. Secondary Jammed Timber Prop
    makePart(model, {
        Name = "Obstacle_JammedTimberProp",
        Size = Vector3.new(0.4, 2.6, 0.4),
        CFrame = rootCF * CFrame.new(1.3, 1.6, 2.45) * CFrame.Angles(math.rad(22), math.rad(-18), math.rad(42)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_WOOD,
    })

    -- 7. Broken Concrete Lintel Masonry Rubble (wedged at base left)
    makeWedge(model, {
        Name = "Obstacle_MasonryRubbleLeft",
        Size = Vector3.new(1.4, 0.9, 1.2),
        CFrame = rootCF * CFrame.new(-1.5, 0.9, 2.3) * CFrame.Angles(0, math.rad(35), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_GRAY,
    })

    -- 8. Broken Masonry Chunk (wedged at base right)
    makePart(model, {
        Name = "Obstacle_MasonryRubbleRight",
        Size = Vector3.new(1.2, 0.7, 1.0),
        CFrame = rootCF * CFrame.new(1.6, 0.8, 2.35) * CFrame.Angles(math.rad(10), math.rad(-25), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- 9. Collapsed Red Brick Chunks from Hotel Outbuilding
    makePart(model, {
        Name = "Obstacle_FallenBricks",
        Size = Vector3.new(0.9, 0.45, 0.7),
        CFrame = rootCF * CFrame.new(0.7, 0.65, 2.5) * CFrame.Angles(math.rad(15), math.rad(40), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = false,
    })

    -- 10. Warped Corrugated Sheet Debris (plugging upper right opening)
    makePart(model, {
        Name = "Obstacle_CorrugatedSheetDebris",
        Size = Vector3.new(2.0, 1.4, 0.12),
        CFrame = rootCF * CFrame.new(1.1, 3.5, 2.1) * CFrame.Angles(math.rad(12), math.rad(-15), math.rad(-18)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_ORANGE,
    })

    -- 11. Old Generator Warning Hazard Plate (oxidized and bent onto the gate)
    makePart(model, {
        Name = "Obstacle_GeneratorHazardSign",
        Size = Vector3.new(0.8, 0.6, 0.08),
        CFrame = rootCF * CFrame.new(-0.6, 2.8, 2.38) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(14)),
        Material = Enum.Material.Metal,
        Color = COLOR_WARNING_YELLOW,
        CanCollide = false,
    })

    -- 12. Thick Evaporite Salt Crust Lines (corrosion encrusting the blockage)
    makePart(model, {
        Name = "Obstacle_SaltEncrustationMain",
        Size = Vector3.new(4.0, 0.28, 0.45),
        CFrame = rootCF * CFrame.new(0.1, 1.15, 2.4) * CFrame.Angles(math.rad(4), math.rad(-3), math.rad(6)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
        CanCollide = false,
    })

    makePart(model, {
        Name = "Obstacle_SaltEncrustationTimber",
        Size = Vector3.new(0.6, 1.6, 0.6),
        CFrame = rootCF * CFrame.new(-0.2, 1.5, 2.45) * CFrame.Angles(math.rad(-14), math.rad(12), math.rad(-34)),
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
        error("[HotelBatteryObstacleSystem] Obstacle model missing valid primary BasePart for ProximityPrompt.")
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

    -- Handle prompt activation: removes the obstruction and opens access
    promptTriggerConnection = prompt.Triggered:Connect(function(player: Player)
        if isCleared then
            return
        end

        print(string.format("[HotelBatteryObstacleSystem] Player '%s' cleared the generator shed obstruction.", player.Name))

        -- Execute obstacle removal to open physical access to the shed interior
        HotelBatteryObstacleSystem.Clear()
    end)

    prompt.Parent = primaryPart
    return prompt
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Initializes the Hotel Monte Real Battery obstacle.
--- Idempotent: safe to call multiple times without duplicating geometry or connections.
function HotelBatteryObstacleSystem.Initialize(): boolean
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

    -- Build the obstacle model in front of the generator shed doorway
    local shedRootCF = resolveShedRootCF()
    local model = buildObstacleModel(shedRootCF, envFolder)
    activeObstacleModel = model
    activePrompt = setupObstaclePrompt(model)
    isInitialized = true

    print(string.format("[HotelBatteryObstacleSystem] Initialized obstacle '%s' at (%d, %d, %d).",
        OBSTACLE_MODEL_NAME,
        shedRootCF.Position.X,
        shedRootCF.Position.Y,
        shedRootCF.Position.Z
    ))

    return true
end

--- Clears and destroys the environmental obstacle, opening physical access to the shed.
--- Removes ONLY the obstacle created by this system.
--- Does NOT touch the Battery, the shed hideout, or the CarPartCollectionSystem.
function HotelBatteryObstacleSystem.Clear(): ()
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

    print("[HotelBatteryObstacleSystem] Obstacle successfully cleared. Generator shed interior is now accessible.")
end

--- Returns whether the obstacle has been cleared.
function HotelBatteryObstacleSystem.IsCleared(): boolean
    return isCleared
end

--- Returns the active obstacle Model if still present in the world.
function HotelBatteryObstacleSystem.GetModel(): Model?
    return activeObstacleModel
end

--- Returns the active ProximityPrompt if still present in the world.
function HotelBatteryObstacleSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

return HotelBatteryObstacleSystem
