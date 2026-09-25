--!strict
--[[
    RadiatorHoseCorralonObstacleSystem.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/RadiatorHoseCorralonObstacleSystem.luau

    Description:
        Server-side environmental obstacle system protecting the Reinforced
        Radiator Hose at the Corralón Municipal Epecuén (Repair Bench hideout).

        Access to the municipal workshop parts alcove is blocked by collapsed
        workshop benches, rusted metal sheet debris, heavy industrial spare parts,
        salt-crusted concrete blocks, and weathered timber planks.

        Players must approach and interact with the obstruction ("Despejar" /
        "Escombros del corralón") to physically clear access to the radiator hose storage.

        Authoritative Guarantees:
        - Native Roblox geometry only (Part, WedgePart, CornerWedgePart, Cylinder).
        - ZERO MeshParts, external assets, asset IDs, textures, or decals.
        - Does NOT move the Radiator Hose (VehiclePart_RadiatorHose) or its hideout.
        - Does NOT collect the Radiator Hose automatically.
        - The Radiator Hose ProximityPrompt remains 100% managed by CarPartCollectionSystem.
        - Safe in multiplayer: clearing removes the physical obstruction for the world,
          allowing all players to investigate and collect on their own progress track.
        - Exposes idempotent Initialize() and Clear().
        - NO automatic initialization on module load.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RadiatorHoseCorralonObstacleSystem = {}

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL PLACEMENT
-- ----------------------------------------------------------------------------
local OBSTACLE_MODEL_NAME = "Obstacle_RadiatorHose_Corralon_RepairBench"
local PROMPT_NAME = "ObstacleCorralonPrompt"
local PROMPT_ACTION_TEXT = "Despejar"
local PROMPT_OBJECT_TEXT = "Escombros del corralón"
local PROMPT_HOLD_DURATION = 1.5
local PROMPT_MAX_ACTIVATION_DISTANCE = 8.0

-- Canonical Corralon hideout coordinates for RadiatorHose
local CANONICAL_CORRALON_POSITION = Vector3.new(-275, 17, -690)
local CANONICAL_CORRALON_ROTATION_Y = 0

-- Color palette matching Epecuen municipal garage ruins, rusted sheet metal, and salt deposits
local COLOR_CORRALON_RUST = Color3.fromRGB(82, 50, 32)
local COLOR_CORRALON_ORANGE = Color3.fromRGB(114, 60, 36)
local COLOR_WEATHERED_WOOD = Color3.fromRGB(115, 98, 80)
local COLOR_CONCRETE_GRAY = Color3.fromRGB(138, 134, 128)
local COLOR_CONCRETE_DARK = Color3.fromRGB(105, 102, 98)
local COLOR_INDUSTRIAL_STEEL = Color3.fromRGB(72, 68, 62)
local COLOR_SALT_WHITE = Color3.fromRGB(228, 230, 224)

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

--- Resolves the root CFrame of the Corralon hideout.
--- If the physical hideout already exists in Workspace, derives its exact foundation CFrame.
local function resolveCorralonRootCF(): CFrame
    local world = getEpecuenWorld()
    if world then
        local hideoutsFolder = world:FindFirstChild("CarPartHideouts")
        if hideoutsFolder then
            local hideout = hideoutsFolder:FindFirstChild("Hideout_RadiatorHose_Corralon_RepairBench")
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
    return CFrame.new(CANONICAL_CORRALON_POSITION) * CFrame.Angles(0, math.rad(CANONICAL_CORRALON_ROTATION_Y), 0)
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL OBSTACLE MODEL BUILDER
-- ----------------------------------------------------------------------------
--- Builds the physical toppled workshop benches and debris obstruction blocking access to the repair bench hideout.
local function buildObstacleModel(rootCF: CFrame, parent: Instance): Model
    local model = Instance.new("Model")
    model.Name = OBSTACLE_MODEL_NAME
    model:SetAttribute("IsObstacle", true)
    model:SetAttribute("TargetObjective", "RadiatorHose")
    model:SetAttribute("ZoneId", "ZONE_NORTH_ENTRANCE")
    model:SetAttribute("AssociatedHideout", "Hideout_RadiatorHose_Corralon_RepairBench")

    -- Primary interaction Part (invisible core serving as PrimaryPart and prompt host)
    local primaryPart = makePart(model, {
        Name = "Obstacle_PrimaryCore",
        Size = Vector3.new(4.0, 3.2, 0.8),
        CFrame = rootCF * CFrame.new(0, 1.6, 2.0),
        Transparency = 1,
        CanCollide = true,
        CanQuery = true,
        CanTouch = true,
    })
    model.PrimaryPart = primaryPart

    -- 1. Toppled Heavy Workshop Workbench Frame
    makePart(model, {
        Name = "Obstacle_ToppledWorkbench",
        Size = Vector3.new(3.8, 3.0, 1.4),
        CFrame = rootCF * CFrame.new(0, 1.5, 1.9) * CFrame.Angles(math.rad(10), math.rad(12), math.rad(-18)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WEATHERED_WOOD,
    })

    -- 2. Rusted Corrugated Sheet Metal Barrier
    makePart(model, {
        Name = "Obstacle_RustedSheetMetal",
        Size = Vector3.new(3.2, 3.4, 0.2),
        CFrame = rootCF * CFrame.new(0.3, 1.7, 2.2) * CFrame.Angles(math.rad(6), math.rad(-25), math.rad(12)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRALON_RUST,
    })

    -- 3. Heavy Industrial Spare Parts / Cast Iron Gear
    makePart(model, {
        Name = "Obstacle_HeavyGearBlock",
        Size = Vector3.new(1.6, 1.4, 1.2),
        CFrame = rootCF * CFrame.new(-1.2, 0.8, 2.0) * CFrame.Angles(math.rad(15), math.rad(30), 0),
        Material = Enum.Material.Metal,
        Color = COLOR_INDUSTRIAL_STEEL,
    })

    -- 4. Broken Wooden Storage Crates Stack
    makePart(model, {
        Name = "Obstacle_BrokenCratesStack",
        Size = Vector3.new(1.5, 1.8, 1.3),
        CFrame = rootCF * CFrame.new(1.3, 1.0, 2.1) * CFrame.Angles(math.rad(-8), math.rad(18), math.rad(24)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_CORRALON_ORANGE,
    })

    -- 5. Concrete Masonry Rubble Chunk
    makeWedge(model, {
        Name = "Obstacle_CorralonMasonryWedge",
        Size = Vector3.new(1.6, 1.0, 1.4),
        CFrame = rootCF * CFrame.new(-0.8, 0.7, 2.2) * CFrame.Angles(0, math.rad(-35), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_GRAY,
    })

    -- 6. Heavy Concrete Block Debris
    makePart(model, {
        Name = "Obstacle_ConcreteBlockDebris",
        Size = Vector3.new(1.4, 1.1, 1.1),
        CFrame = rootCF * CFrame.new(0.9, 0.6, 2.3) * CFrame.Angles(math.rad(12), math.rad(-15), math.rad(8)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- 7. Evaporite Salt Crust Layers Encrusting the Obstacle
    makePart(model, {
        Name = "Obstacle_SaltCrustTop",
        Size = Vector3.new(3.5, 0.25, 1.3),
        CFrame = rootCF * CFrame.new(0, 3.2, 1.9) * CFrame.Angles(math.rad(10), math.rad(12), math.rad(-18)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
        CanCollide = false,
    })

    makePart(model, {
        Name = "Obstacle_SaltCrustBase",
        Size = Vector3.new(4.0, 0.3, 1.6),
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
        error("[RadiatorHoseCorralonObstacleSystem] Obstacle model missing valid primary BasePart for ProximityPrompt.")
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

        print(string.format("[RadiatorHoseCorralonObstacleSystem] Player '%s' cleared the corralon obstruction.", player.Name))

        -- Execute obstacle removal to open physical access to the repair bench hideout
        RadiatorHoseCorralonObstacleSystem.Clear()
    end)

    prompt.Parent = primaryPart
    return prompt
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Initializes the Corralon RadiatorHose obstacle.
--- Idempotent: safe to call multiple times without duplicating geometry or connections.
function RadiatorHoseCorralonObstacleSystem.Initialize(): boolean
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

    local rootCF = resolveCorralonRootCF()
    local model = buildObstacleModel(rootCF, envFolder)
    activeObstacleModel = model
    activePrompt = setupObstaclePrompt(model)
    isInitialized = true

    print(string.format("[RadiatorHoseCorralonObstacleSystem] Initialized obstacle '%s' at (%d, %d, %d).",
        OBSTACLE_MODEL_NAME,
        rootCF.Position.X,
        rootCF.Position.Y,
        rootCF.Position.Z
    ))

    return true
end

--- Clears and destroys the environmental obstacle, opening physical access to the repair bench.
--- Removes ONLY the obstacle created by this system.
--- Does NOT touch the Radiator Hose, the hideout, or the CarPartCollectionSystem.
function RadiatorHoseCorralonObstacleSystem.Clear(): ()
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

    print("[RadiatorHoseCorralonObstacleSystem] Obstacle successfully cleared. Repair bench hideout is now accessible.")
end

--- Returns whether the obstacle has been cleared.
function RadiatorHoseCorralonObstacleSystem.IsCleared(): boolean
    return isCleared
end

--- Returns the active obstacle Model if still present in the world.
function RadiatorHoseCorralonObstacleSystem.GetModel(): Model?
    return activeObstacleModel
end

--- Returns the active ProximityPrompt if still present in the world.
function RadiatorHoseCorralonObstacleSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

return RadiatorHoseCorralonObstacleSystem
