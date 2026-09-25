--!strict
--[[
    MataderoAlternatorObstacleSystem.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/MataderoAlternatorObstacleSystem.luau

    Description:
        Server-side environmental obstacle system protecting the 14V Alternator
        at the Matadero Municipal (Machinery Vault).

        Access to the subterranean cooling/machinery vault is blocked by a
        collapsed, rusted industrial steel gate, reinforced with bent structural
        angle-irons, buckled steel plates, fallen masonry debris, and mineral
        salt encrustations.

        Players must approach and interact with the obstruction ("Abrir" /
        "Portón oxidado") to physically open access to the machinery vault.

        Authoritative Guarantees:
        - Native Roblox geometry only (Part, WedgePart, CornerWedgePart, Cylinder).
        - ZERO MeshParts, external assets, asset IDs, textures, or decals.
        - Does NOT move the Alternator (VehiclePart_Alternator_14V) or its hideout.
        - Does NOT collect the Alternator automatically.
        - The Alternator ProximityPrompt remains 100% managed by CarPartCollectionSystem.
        - Safe in multiplayer: clearing removes the obstruction for the shared world,
          allowing all players to enter and collect on their individual progress tracks.
        - Exposes idempotent Initialize() and Clear().
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local MataderoAlternatorObstacleSystem = {}

-- ----------------------------------------------------------------------------
-- CONSTANTS & CANONICAL PLACEMENT
-- ----------------------------------------------------------------------------
local OBSTACLE_MODEL_NAME = "Obstacle_Alternator_Matadero_MachineryVault"
local PROMPT_NAME = "ObstacleGatePrompt"
local PROMPT_ACTION_TEXT = "Abrir"
local PROMPT_OBJECT_TEXT = "Portón oxidado"
local PROMPT_HOLD_DURATION = 1.5
local PROMPT_MAX_ACTIVATION_DISTANCE = 8.0

-- Canonical machinery vault coordinates at Matadero (Francisco Salamone)
local CANONICAL_VAULT_POSITION = Vector3.new(665, 16, 495)
local CANONICAL_VAULT_ROTATION_Y = 0

-- Color palette matching Matadero slaughterhouse industrial rust and salt decay
local COLOR_INDUSTRIAL_RUST_DARK = Color3.fromRGB(78, 46, 28)
local COLOR_INDUSTRIAL_RUST_ORANGE = Color3.fromRGB(122, 62, 34)
local COLOR_HEAVY_STEEL = Color3.fromRGB(88, 56, 38)
local COLOR_CONCRETE_DEBRIS = Color3.fromRGB(142, 138, 132)
local COLOR_CONCRETE_PALE = Color3.fromRGB(168, 165, 158)
local COLOR_SALT_ENCRUSTATION = Color3.fromRGB(226, 228, 222)
local COLOR_WARNING_AMBER = Color3.fromRGB(162, 132, 42)

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

--- Resolves the root CFrame of the Matadero Machinery Vault hideout.
--- If the physical hideout already exists in Workspace, derives its exact foundation CFrame.
local function resolveVaultRootCF(): CFrame
    local world = getEpecuenWorld()
    if world then
        local hideoutsFolder = world:FindFirstChild("CarPartHideouts")
        if hideoutsFolder then
            local vault = hideoutsFolder:FindFirstChild("Hideout_Alternator_Matadero_MachineryVault")
            if vault and vault:IsA("Model") then
                local sump = vault:FindFirstChild("Industrial_BaseSump")
                if sump and sump:IsA("BasePart") then
                    -- Base sump was offset by CFrame.new(0, 0.3, 0) relative to vault root
                    return sump.CFrame * CFrame.new(0, -0.3, 0)
                end
                local primary = vault.PrimaryPart or vault:FindFirstChildWhichIsA("BasePart")
                if primary then
                    return CFrame.new(primary.Position.X, 16, primary.Position.Z)
                end
            end
        end
    end
    return CFrame.new(CANONICAL_VAULT_POSITION) * CFrame.Angles(0, math.rad(CANONICAL_VAULT_ROTATION_Y), 0)
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL OBSTACLE MODEL BUILDER
-- ----------------------------------------------------------------------------
--- Builds the physical collapsed industrial gate blocking access to the machinery vault.
--- Vault doorway coordinates: centered at rootCF * CFrame.new(0, 2.3, 2.15)
local function buildObstacleModel(rootCF: CFrame, parent: Instance): Model
    local model = Instance.new("Model")
    model.Name = OBSTACLE_MODEL_NAME
    model:SetAttribute("IsObstacle", true)
    model:SetAttribute("TargetObjective", "Alternator")
    model:SetAttribute("ZoneId", "ZONE_MATADERO")
    model:SetAttribute("AssociatedHideout", "Hideout_Alternator_Matadero_MachineryVault")

    -- Primary interaction Part (invisible core serving as PrimaryPart and prompt host)
    -- Placed directly across the center of the vault entrance
    local primaryPart = makePart(model, {
        Name = "Obstacle_PrimaryCore",
        Size = Vector3.new(3.8, 3.8, 0.8),
        CFrame = rootCF * CFrame.new(0, 2.3, 2.15),
        Transparency = 1,
        CanCollide = true,
        CanQuery = true,
        CanTouch = true,
    })
    model.PrimaryPart = primaryPart

    -- 1. Left Vertical Steel Channel Post (heavy industrial door jamb)
    makePart(model, {
        Name = "Gate_LeftPost",
        Size = Vector3.new(0.4, 4.2, 0.45),
        CFrame = rootCF * CFrame.new(-1.85, 2.4, 2.1) * CFrame.Angles(0, 0, math.rad(-3)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_DARK,
    })

    -- 2. Right Vertical Steel Channel Post (bent inwards from ceiling spalling)
    makePart(model, {
        Name = "Gate_RightPost",
        Size = Vector3.new(0.4, 4.0, 0.45),
        CFrame = rootCF * CFrame.new(1.8, 2.3, 2.15) * CFrame.Angles(math.rad(4), 0, math.rad(-8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_DARK,
    })

    -- 3. Top Heavy Angle-Iron Header (buckled downward in the middle)
    makePart(model, {
        Name = "Gate_TopHeaderBar",
        Size = Vector3.new(3.9, 0.35, 0.4),
        CFrame = rootCF * CFrame.new(0, 4.1, 2.05) * CFrame.Angles(math.rad(5), 0, math.rad(2)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_DARK,
    })

    -- 4. Lower Threshold Heavy Iron Rail
    makePart(model, {
        Name = "Gate_BottomRail",
        Size = Vector3.new(3.9, 0.35, 0.4),
        CFrame = rootCF * CFrame.new(0, 0.75, 2.2),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_DARK,
    })

    -- 5. Main Heavy Collapsed Gate Leaf (rusted diamond-plate, jammed diagonally in the frame)
    makePart(model, {
        Name = "Gate_MainPanelLeaf",
        Size = Vector3.new(2.4, 3.4, 0.22),
        CFrame = rootCF * CFrame.new(-0.4, 2.3, 2.12) * CFrame.Angles(math.rad(8), math.rad(-5), math.rad(10)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_ORANGE,
    })

    -- 6. Secondary Jammed Gate Leaf (folded inward against the right jamb)
    makePart(model, {
        Name = "Gate_SecondaryPanelLeaf",
        Size = Vector3.new(1.8, 3.2, 0.22),
        CFrame = rootCF * CFrame.new(1.0, 2.2, 2.18) * CFrame.Angles(math.rad(-6), math.rad(18), math.rad(-14)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_HEAVY_STEEL,
    })

    -- 7. Four Vertical Reinforcing Heavy Rebar Struts
    local rebarOffsets = { -1.3, -0.7, 0.1, 0.9 }
    for i, xOff in ipairs(rebarOffsets) do
        makePart(model, {
            Name = "Gate_RebarStrut_" .. tostring(i),
            Size = Vector3.new(0.16, 3.2, 0.16),
            CFrame = rootCF * CFrame.new(xOff, 2.3, 2.1) * CFrame.Angles(math.rad(6), math.rad(-3), math.rad(8)),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_INDUSTRIAL_RUST_DARK,
        })
    end

    -- 8. Bent Heavy Industrial Steam/Ammonia Pipe (jamming the gate shut)
    makeCylinder(model, {
        Name = "Gate_JammedIndustrialPipe",
        Size = Vector3.new(3.6, 0.4, 0.4),
        CFrame = rootCF * CFrame.new(0.2, 2.1, 2.35) * CFrame.Angles(math.rad(15), math.rad(10), math.rad(48)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_INDUSTRIAL_RUST_DARK,
    })

    -- 9. Broken Concrete Lintel Masonry Rubble (fallen from vault entrance header)
    makeWedge(model, {
        Name = "Gate_MasonryRubbleLeft",
        Size = Vector3.new(1.3, 0.8, 1.1),
        CFrame = rootCF * CFrame.new(-1.3, 0.85, 2.25) * CFrame.Angles(0, math.rad(25), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DEBRIS,
    })

    makePart(model, {
        Name = "Gate_MasonryRubbleRight",
        Size = Vector3.new(1.1, 0.7, 0.9),
        CFrame = rootCF * CFrame.new(1.2, 0.8, 2.3) * CFrame.Angles(math.rad(8), math.rad(-30), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- 10. Corroded Machinery Vault Hazard Plate ("SALA DE MÁQUINAS")
    makePart(model, {
        Name = "Gate_MachineryHazardPlate",
        Size = Vector3.new(0.85, 0.55, 0.08),
        CFrame = rootCF * CFrame.new(-0.3, 3.1, 2.26) * CFrame.Angles(math.rad(8), math.rad(-5), math.rad(16)),
        Material = Enum.Material.Metal,
        Color = COLOR_WARNING_AMBER,
        CanCollide = false,
    })

    -- 11. Heavy Salt/Calcium Mineral Crust Formations (from 25+ years of brine immersion)
    makePart(model, {
        Name = "Gate_SaltDepositThreshold",
        Size = Vector3.new(3.6, 0.22, 0.5),
        CFrame = rootCF * CFrame.new(0, 0.7, 2.3),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_ENCRUSTATION,
        CanCollide = false,
    })

    makePart(model, {
        Name = "Gate_SaltDepositMidBar",
        Size = Vector3.new(1.4, 0.3, 0.35),
        CFrame = rootCF * CFrame.new(-0.8, 1.6, 2.22) * CFrame.Angles(math.rad(8), math.rad(-5), math.rad(10)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_ENCRUSTATION,
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
        error("[MataderoAlternatorObstacleSystem] Obstacle model missing valid primary BasePart for ProximityPrompt.")
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

        print(string.format("[MataderoAlternatorObstacleSystem] Player '%s' opened the Matadero machinery gate.", player.Name))

        -- Execute obstacle removal to open physical access to the machinery vault interior
        MataderoAlternatorObstacleSystem.Clear()
    end)

    prompt.Parent = primaryPart
    return prompt
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Initializes the Matadero Alternator environmental obstacle.
--- Idempotent: safe to call multiple times without duplicating geometry or connections.
function MataderoAlternatorObstacleSystem.Initialize(): boolean
    if isCleared then
        -- Obstacle has already been opened in this game session; remain cleared
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

    -- Build the obstacle model in front of the machinery vault doorway
    local vaultRootCF = resolveVaultRootCF()
    local model = buildObstacleModel(vaultRootCF, envFolder)
    activeObstacleModel = model
    activePrompt = setupObstaclePrompt(model)
    isInitialized = true

    print(string.format("[MataderoAlternatorObstacleSystem] Initialized obstacle '%s' at (%d, %d, %d).",
        OBSTACLE_MODEL_NAME,
        vaultRootCF.Position.X,
        vaultRootCF.Position.Y,
        vaultRootCF.Position.Z
    ))

    return true
end

--- Clears and destroys the environmental obstacle, opening physical access to the vault.
--- Removes ONLY the obstacle created by this system.
--- Does NOT touch the Alternator, the vault hideout, or the CarPartCollectionSystem.
function MataderoAlternatorObstacleSystem.Clear(): ()
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

    print("[MataderoAlternatorObstacleSystem] Obstacle successfully opened. Machinery vault interior is now accessible.")
end

--- Returns whether the obstacle has been cleared.
function MataderoAlternatorObstacleSystem.IsCleared(): boolean
    return isCleared
end

--- Returns the active obstacle Model if still present in the world.
function MataderoAlternatorObstacleSystem.GetModel(): Model?
    return activeObstacleModel
end

--- Returns the active ProximityPrompt if still present in the world.
function MataderoAlternatorObstacleSystem.GetPrompt(): ProximityPrompt?
    return activePrompt
end

return MataderoAlternatorObstacleSystem
