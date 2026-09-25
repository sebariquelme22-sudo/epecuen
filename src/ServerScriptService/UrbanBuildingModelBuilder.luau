--!strict
--[[
    UrbanBuildingModelBuilder.luau
    Location: ServerScriptService/UrbanBuildingModelBuilder.luau

    Procedural 3D Urban Building and Ruin Builder for "EPECUÉN: NO ESCAPE".
    Visual Reference: Villa Epecuén (Adolfo Alsina, Buenos Aires Province, Argentina).

    Design Language & Architectural Principles:
      - 1920s-1970s Argentine thermal-resort architecture:
          * Simple masonry construction (ladrillos comunes bonaerenses, revoque a la cal)
          * Flat parapet roofs (azoteas con cornisas y molduras desmoronadas)
          * Walkable entrance doorways, broken window apertures, transom frames
          * Verandas (aleros, galerías de entrada, ochavas comerciales)
          * Low boundary garden walls (muretes de jardín, veredas de entrada)
          * Flood destruction: sheared wall tops, exposed brickwork, fallen roof slabs
          * Hyper-saline evaporite crusts (costras de sal blanco-tiza y estantes de marea)
          * Scree rubble heaps, crumbled mortar chunks, and hardy pampas vegetation (halophytes/saltbush)
      - 100% Native Roblox Geometry: Part, WedgePart, CornerWedgePart ONLY.
      - 0 MeshParts, 0 external asset IDs, 0 textures, 0 plugins, 0 lights.
      - Pure functional library: NO automatic Workspace spawning on require.
--]]

local UrbanBuildingModelBuilder = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type BuildingType =
    | "HouseSmall"
    | "HouseMedium"
    | "ShopRuins"
    | "SmallHotel"
    | "FacadeRuins"
    | "WallRuins"

export type UrbanBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    BuildingType: (BuildingType | string)?,
    DamageLevel: number?, -- 0.0 (mostly standing) to 1.0 (heavy collapse), default ~0.65
    SaltLevel: number?,   -- 0.0 to 1.0 (mineral encrustation), default ~0.70
    Seed: number?,        -- Deterministic PRNG seed, default 4242
    Parent: Instance?,
    Name: string?,
}

export type PartConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    Reflectance: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

export type WedgeConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

export type CornerWedgeConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

export type BuildingMetric = {
    Type: string,
    EstimatedPartRange: string,
    Dimensions: Vector3,
    Description: string,
}

-- ============================================================================
-- COLOR & MATERIAL PALETTE (Authentic Post-Flood Epecuén)
-- ============================================================================

local COLOR_STUCCO_WEATHERED  = Color3.fromRGB(168, 164, 154) -- Weathered lime stucco
local COLOR_STUCCO_PALE       = Color3.fromRGB(188, 184, 175) -- Bleached plaster
local COLOR_STUCCO_OCHRE      = Color3.fromRGB(175, 158, 138) -- Aged resort ochre
local COLOR_CONCRETE_DARK     = Color3.fromRGB(120, 116, 110) -- Water-stained low concrete
local COLOR_CONCRETE_SLAB     = Color3.fromRGB(142, 138, 130) -- Structural roof slab
local COLOR_BRICK_EXPOSED     = Color3.fromRGB(162, 88, 68)   -- Ladrillo común cocido
local COLOR_BRICK_WEATHERED   = Color3.fromRGB(138, 76, 60)   -- Submerged brick core
local COLOR_SALT_CRUST_WHITE  = Color3.fromRGB(244, 246, 242) -- Pure white evaporite mineral
local COLOR_SALT_CRUST_CREAM  = Color3.fromRGB(228, 230, 222) -- Calcified waterline shelf
local COLOR_MORTAR_RUBBLE     = Color3.fromRGB(146, 142, 134) -- Debris scree
local COLOR_WOOD_ROTTED       = Color3.fromRGB(92, 80, 68)    -- Rotting transom / lintel
local COLOR_CORRODED_IRON     = Color3.fromRGB(98, 58, 42)    -- Corroded rebar / pipe
local COLOR_HALOPHYTE_WEED    = Color3.fromRGB(112, 118, 92)  -- Saline pampas saltbush
local COLOR_DEAD_THISTLE      = Color3.fromRGB(140, 132, 108) -- Dried cardo pampas weed

-- ============================================================================
-- HELPER PRIMITIVE BUILDERS
-- ============================================================================

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.Concrete
    p.Color = cfg.Color or COLOR_STUCCO_WEATHERED
    p.Transparency = cfg.Transparency or 0
    p.Reflectance = cfg.Reflectance or 0
    p.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    p.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    p.Anchored = true
    p.Parent = parent
    return p
end

local function makeWedge(parent: Instance, cfg: WedgeConfig): WedgePart
    local w = Instance.new("WedgePart")
    w.Name = cfg.Name
    w.Size = cfg.Size
    w.CFrame = cfg.CFrame
    w.Material = cfg.Material or Enum.Material.Concrete
    w.Color = cfg.Color or COLOR_STUCCO_WEATHERED
    w.Transparency = cfg.Transparency or 0
    w.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    w.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    w.Anchored = true
    w.Parent = parent
    return w
end

local function makeCornerWedge(parent: Instance, cfg: CornerWedgeConfig): CornerWedgePart
    local cw = Instance.new("CornerWedgePart")
    cw.Name = cfg.Name
    cw.Size = cfg.Size
    cw.CFrame = cfg.CFrame
    cw.Material = cfg.Material or Enum.Material.Concrete
    cw.Color = cfg.Color or COLOR_STUCCO_WEATHERED
    cw.Transparency = cfg.Transparency or 0
    cw.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    cw.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    cw.Anchored = true
    cw.Parent = parent
    return cw
end

-- ============================================================================
-- 1. HOUSE SMALL (Single-story vernacular Argentine brick/stucco chalet)
-- Target: 25–45 parts
-- ============================================================================

local function buildHouseSmall(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "Roof")
    local fOpenings   = getOrCreateFolder(model, "Openings")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 22 wide x 18 deep x 11 high
    -- Foundation: sidewalk plinth & entrance stoop (2 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_Plinth",
        Size = Vector3.new(23, 1.2, 19),
        CFrame = toWorld(CFrame.new(0, -0.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Entrance_Stoop",
        Size = Vector3.new(5.0, 0.6, 3.0),
        CFrame = toWorld(CFrame.new(-3.0, -0.3, 10.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Walls: Front wall with walkable doorway (-3.0) and window aperture (+4.5) (6 parts)
    -- Left pier of front wall
    makePart(fWalls, {
        Name = "Wall_Front_Left",
        Size = Vector3.new(6.0, 9.0, 1.0),
        CFrame = toWorld(CFrame.new(-8.0, 4.5, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Doorway lintel
    makePart(fWalls, {
        Name = "Wall_Front_DoorLintel",
        Size = Vector3.new(4.0, 2.2, 1.0),
        CFrame = toWorld(CFrame.new(-3.0, 7.9, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Pier between door and window
    makePart(fWalls, {
        Name = "Wall_Front_CenterPier",
        Size = Vector3.new(3.5, 9.0, 1.0),
        CFrame = toWorld(CFrame.new(0.75, 4.5, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Window sill
    makePart(fWalls, {
        Name = "Wall_Front_WindowSill",
        Size = Vector3.new(4.0, 3.2, 1.0),
        CFrame = toWorld(CFrame.new(4.5, 1.6, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Window lintel
    makePart(fWalls, {
        Name = "Wall_Front_WindowLintel",
        Size = Vector3.new(4.0, 2.0, 1.0),
        CFrame = toWorld(CFrame.new(4.5, 8.0, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Right pier of front wall
    makePart(fWalls, {
        Name = "Wall_Front_Right",
        Size = Vector3.new(3.5, 9.0, 1.0),
        CFrame = toWorld(CFrame.new(8.75, 4.5, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Side & Back Walls (4 parts)
    -- Left side wall (standing)
    makePart(fWalls, {
        Name = "Wall_Side_Left",
        Size = Vector3.new(1.0, 8.8, 17.0),
        CFrame = toWorld(CFrame.new(-10.5, 4.4, -0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Right side wall (partially sheared with jagged breach)
    makePart(fWalls, {
        Name = "Wall_Side_Right_Standing",
        Size = Vector3.new(1.0, 6.2, 9.0),
        CFrame = toWorld(CFrame.new(10.5, 3.1, 3.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fWalls, {
        Name = "Wall_Side_Right_Fracture",
        Size = Vector3.new(1.0, 2.6, 6.0),
        CFrame = toWorld(CFrame.new(10.5, 7.5, 3.5) * CFrame.Angles(0, 0, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Back wall with breach
    makePart(fWalls, {
        Name = "Wall_Back_Main",
        Size = Vector3.new(16.0, 7.5, 1.0),
        CFrame = toWorld(CFrame.new(-2.5, 3.75, -8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Interior partition wall (1 part)
    makePart(fWalls, {
        Name = "Wall_Interior_Partition",
        Size = Vector3.new(1.0, 7.0, 9.0),
        CFrame = toWorld(CFrame.new(-1.5, 3.5, -3.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Roof: Partial collapsed flat concrete slab and tilted broken beam (3 parts)
    makePart(fRoof, {
        Name = "Roof_Standing_Slab",
        Size = Vector3.new(13.0, 0.8, 12.0),
        CFrame = toWorld(CFrame.new(-4.5, 9.2, -2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Collapsed_Slab_Tilted",
        Size = Vector3.new(8.0, 0.7, 7.0),
        CFrame = toWorld(CFrame.new(5.0, 4.2, 1.5) * CFrame.Angles(math.rad(18), math.rad(8), math.rad(-14))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Corroded_IBeam",
        Size = Vector3.new(0.4, 0.4, 11.0),
        CFrame = toWorld(CFrame.new(4.5, 6.5, -1.0) * CFrame.Angles(math.rad(-12), 0, math.rad(6))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    -- Openings: Rotted wooden transom frame and broken sill beam (2 parts)
    makePart(fOpenings, {
        Name = "Opening_Door_Jamb",
        Size = Vector3.new(0.3, 6.5, 0.4),
        CFrame = toWorld(CFrame.new(-4.4, 3.25, 8.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "Opening_Window_RottedFrame",
        Size = Vector3.new(3.8, 0.3, 0.4),
        CFrame = toWorld(CFrame.new(4.5, 3.3, 8.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Rubble: Scree heaps, fallen concrete chunks inside and outside (5 parts)
    makePart(fRubble, {
        Name = "Rubble_Interior_Heap",
        Size = Vector3.new(5.5, 1.4, 4.5),
        CFrame = toWorld(CFrame.new(5.5, 0.7, 2.0) * CFrame.Angles(0, math.rad(15), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Slab_Chunk_A",
        Size = Vector3.new(2.4, 0.8, 2.0),
        CFrame = toWorld(CFrame.new(6.8, 0.4, -4.5) * CFrame.Angles(math.rad(10), math.rad(35), math.rad(-8))),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_Scatter",
        Size = Vector3.new(1.8, 0.5, 1.4),
        CFrame = toWorld(CFrame.new(-2.0, 0.25, 4.0) * CFrame.Angles(0, math.rad(-22), 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makePart(fRubble, {
        Name = "Rubble_Exterior_Apron",
        Size = Vector3.new(3.5, 0.6, 2.5),
        CFrame = toWorld(CFrame.new(9.5, 0.3, 8.5) * CFrame.Angles(0, math.rad(12), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Wedge_Spill",
        Size = Vector3.new(2.2, 0.9, 2.6),
        CFrame = toWorld(CFrame.new(5.5, 0.45, 6.0) * CFrame.Angles(0, math.rad(45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    -- Salt Crust: Mineral tide lines & evaporite floor puddles (4 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Floor_Sheet",
        Size = Vector3.new(9.0, 0.1, 7.0),
        CFrame = toWorld(CFrame.new(-4.5, 0.05, 1.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.25,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Waterline_Front",
        Size = Vector3.new(22.0, 0.4, 1.2),
        CFrame = toWorld(CFrame.new(0, 1.8, 8.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Waterline_Left",
        Size = Vector3.new(1.2, 0.4, 17.0),
        CFrame = toWorld(CFrame.new(-10.5, 1.8, -0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Corner_Crust",
        Size = Vector3.new(2.5, 0.2, 2.5),
        CFrame = toWorld(CFrame.new(-9.0, 0.1, 7.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.3,
    })

    -- Vegetation: Hardy pampas halophytes & dead cardo thistle (3 parts)
    makePart(fVegetation, {
        Name = "Halophyte_Saltbush_Entrance",
        Size = Vector3.new(1.4, 1.8, 1.2),
        CFrame = toWorld(CFrame.new(-0.8, 0.9, 9.2) * CFrame.Angles(0, math.rad(28), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_Crevice_Interior",
        Size = Vector3.new(1.0, 1.5, 1.0),
        CFrame = toWorld(CFrame.new(-8.5, 0.75, -6.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_WallRoot",
        Size = Vector3.new(0.8, 1.2, 0.8),
        CFrame = toWorld(CFrame.new(9.8, 0.6, 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    return foundation
end

-- ============================================================================
-- 2. HOUSE MEDIUM (Two-room summer residence with veranda and low boundary wall)
-- Target: 35–60 parts
-- ============================================================================

local function buildHouseMedium(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "Roof")
    local fOpenings   = getOrCreateFolder(model, "Openings")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 32 wide x 24 deep x 13 high
    -- Foundation: Plinth, Veranda Porch, Sidewalk border (3 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_MainPlinth",
        Size = Vector3.new(34, 1.2, 26),
        CFrame = toWorld(CFrame.new(0, -0.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Foundation_VerandaSlab",
        Size = Vector3.new(20, 0.8, 6.0),
        CFrame = toWorld(CFrame.new(-4.0, -0.2, 14.5)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fFoundation, {
        Name = "Foundation_Entrance_Steps",
        Size = Vector3.new(6.0, 0.4, 2.5),
        CFrame = toWorld(CFrame.new(-4.0, -0.2, 18.25)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Walls: Front Veranda Columns & Architrave (4 parts)
    makePart(fWalls, {
        Name = "Veranda_Column_Left",
        Size = Vector3.new(1.2, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(-12.5, 4.05, 16.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Veranda_Column_Right",
        Size = Vector3.new(1.2, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(4.5, 4.05, 16.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Veranda_Beam_Lintel",
        Size = Vector3.new(20.0, 1.2, 1.2),
        CFrame = toWorld(CFrame.new(-4.0, 8.9, 16.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makeWedge(fWalls, {
        Name = "Veranda_Corner_Bracket",
        Size = Vector3.new(1.2, 1.5, 2.0),
        CFrame = toWorld(CFrame.new(-12.5, 7.8, 14.5) * CFrame.Angles(0, math.rad(180), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Front Main Wall: with wide doorway and double window apertures (6 parts)
    makePart(fWalls, {
        Name = "Wall_Front_WestWing",
        Size = Vector3.new(7.0, 10.5, 1.2),
        CFrame = toWorld(CFrame.new(-11.5, 5.25, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Front_DoorLintel",
        Size = Vector3.new(4.5, 2.8, 1.2),
        CFrame = toWorld(CFrame.new(-5.0, 9.1, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Front_CenterPier",
        Size = Vector3.new(4.0, 10.5, 1.2),
        CFrame = toWorld(CFrame.new(-0.75, 5.25, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Front_WindowSill",
        Size = Vector3.new(4.5, 3.2, 1.2),
        CFrame = toWorld(CFrame.new(3.5, 1.6, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Wall_Front_WindowLintel",
        Size = Vector3.new(4.5, 2.2, 1.2),
        CFrame = toWorld(CFrame.new(3.5, 9.4, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Front_EastWing",
        Size = Vector3.new(7.0, 10.5, 1.2),
        CFrame = toWorld(CFrame.new(9.5, 5.25, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Side and Rear Walls (6 parts)
    makePart(fWalls, {
        Name = "Wall_Side_Left_Solid",
        Size = Vector3.new(1.2, 10.2, 22.0),
        CFrame = toWorld(CFrame.new(-14.5, 5.1, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Side_Right_Lower",
        Size = Vector3.new(1.2, 6.0, 14.0),
        CFrame = toWorld(CFrame.new(14.5, 3.0, 4.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fWalls, {
        Name = "Wall_Side_Right_JaggedPeak",
        Size = Vector3.new(1.2, 3.5, 8.0),
        CFrame = toWorld(CFrame.new(14.5, 7.75, 5.0) * CFrame.Angles(0, math.rad(180), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Rear_WestSection",
        Size = Vector3.new(15.0, 9.5, 1.2),
        CFrame = toWorld(CFrame.new(-7.0, 4.75, -11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Rear_BreachedBase",
        Size = Vector3.new(12.0, 3.5, 1.2),
        CFrame = toWorld(CFrame.new(7.0, 1.75, -11.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Wall_Central_SpinePartition",
        Size = Vector3.new(1.0, 8.5, 14.0),
        CFrame = toWorld(CFrame.new(0, 4.25, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    -- Low Garden Boundary Wall in front (2 parts)
    makePart(fWalls, {
        Name = "Boundary_Wall_FrontLeft",
        Size = Vector3.new(9.0, 2.4, 0.8),
        CFrame = toWorld(CFrame.new(-11.5, 1.2, 20.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    makePart(fWalls, {
        Name = "Boundary_Wall_Pillar",
        Size = Vector3.new(1.4, 3.2, 1.4),
        CFrame = toWorld(CFrame.new(-7.0, 1.6, 20.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Roof: Overhang veranda slab and partial main roof slab (4 parts)
    makePart(fRoof, {
        Name = "Roof_Veranda_Awning",
        Size = Vector3.new(19.0, 0.6, 6.5),
        CFrame = toWorld(CFrame.new(-4.0, 9.6, 14.25)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_West_MainSlab",
        Size = Vector3.new(15.0, 0.8, 16.0),
        CFrame = toWorld(CFrame.new(-7.0, 10.6, 1.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Collapsed_EastSlab",
        Size = Vector3.new(11.0, 0.7, 10.0),
        CFrame = toWorld(CFrame.new(7.0, 4.5, -2.0) * CFrame.Angles(math.rad(16), math.rad(-10), math.rad(12))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Parapet_Cornice",
        Size = Vector3.new(15.5, 0.8, 1.4),
        CFrame = toWorld(CFrame.new(-7.0, 11.4, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Openings: Transom wooden lintels & rusted rebar ties (3 parts)
    makePart(fOpenings, {
        Name = "Door_Lintel_WoodBeam",
        Size = Vector3.new(4.8, 0.35, 1.3),
        CFrame = toWorld(CFrame.new(-5.0, 7.5, 11.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "Window_Mullion_Iron",
        Size = Vector3.new(0.2, 4.0, 0.2),
        CFrame = toWorld(CFrame.new(3.5, 5.2, 11.5)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    makePart(fOpenings, {
        Name = "Interior_Door_Frame",
        Size = Vector3.new(0.8, 6.0, 0.3),
        CFrame = toWorld(CFrame.new(0, 3.0, 2.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Rubble: Masonry debris, fallen bricks, collapsed plaster mounds (6 parts)
    makePart(fRubble, {
        Name = "Rubble_Mound_EastRoom",
        Size = Vector3.new(7.5, 1.8, 6.0),
        CFrame = toWorld(CFrame.new(7.0, 0.9, -1.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_Cluster",
        Size = Vector3.new(3.0, 0.8, 2.2),
        CFrame = toWorld(CFrame.new(8.0, 0.4, 5.5) * CFrame.Angles(0, math.rad(24), 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makePart(fRubble, {
        Name = "Rubble_Veranda_Debris",
        Size = Vector3.new(3.2, 0.6, 2.0),
        CFrame = toWorld(CFrame.new(3.0, 0.3, 14.5) * CFrame.Angles(0, math.rad(-18), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Spill_Wedge",
        Size = Vector3.new(3.0, 1.2, 3.5),
        CFrame = toWorld(CFrame.new(12.0, 0.6, -8.0) * CFrame.Angles(0, math.rad(-35), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_Cornice_Chunk",
        Size = Vector3.new(4.0, 0.7, 1.2),
        CFrame = toWorld(CFrame.new(-3.0, 0.35, 8.5) * CFrame.Angles(math.rad(6), math.rad(14), math.rad(-8))),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRubble, {
        Name = "Rubble_Sidewalk_Crack_Debris",
        Size = Vector3.new(2.2, 0.4, 1.6),
        CFrame = toWorld(CFrame.new(-10.5, 0.2, 17.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Salt Crust: Mineral tide line and calcified wall fringes (5 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Tide_FrontWall",
        Size = Vector3.new(32.0, 0.5, 1.4),
        CFrame = toWorld(CFrame.new(0, 2.0, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Tide_WestWall",
        Size = Vector3.new(1.4, 0.5, 22.0),
        CFrame = toWorld(CFrame.new(-14.5, 2.0, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Interior_FloorCrust",
        Size = Vector3.new(11.0, 0.1, 9.0),
        CFrame = toWorld(CFrame.new(-7.0, 0.05, 3.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.28,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Veranda_Puddle",
        Size = Vector3.new(6.0, 0.08, 4.0),
        CFrame = toWorld(CFrame.new(-4.0, 0.22, 14.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.35,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Column_Collar",
        Size = Vector3.new(1.6, 0.4, 1.6),
        CFrame = toWorld(CFrame.new(-12.5, 2.0, 16.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_WHITE,
    })

    -- Vegetation: Halophytes & saltbush (4 parts)
    makePart(fVegetation, {
        Name = "Halophyte_Veranda_Corner",
        Size = Vector3.new(1.6, 2.2, 1.4),
        CFrame = toWorld(CFrame.new(-13.5, 1.1, 18.0) * CFrame.Angles(0, math.rad(35), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_BoundaryWall",
        Size = Vector3.new(1.2, 1.8, 1.0),
        CFrame = toWorld(CFrame.new(-6.0, 0.9, 21.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Courtyard_Rubble",
        Size = Vector3.new(1.8, 1.4, 1.6),
        CFrame = toWorld(CFrame.new(9.5, 0.7, -8.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Interior_Weed",
        Size = Vector3.new(1.0, 1.2, 0.9),
        CFrame = toWorld(CFrame.new(-1.5, 0.6, -7.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    return foundation
end

-- ============================================================================
-- 3. SHOP RUINS (Local corner shop / almacén with ochava & display storefronts)
-- Target: 35–65 parts
-- ============================================================================

local function buildShopRuins(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "Roof")
    local fOpenings   = getOrCreateFolder(model, "Openings")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 26 wide x 22 deep x 13 high
    -- Foundation: Paved commercial sidewalk wrap & interior terrazzo slab (3 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_CommercialPlinth",
        Size = Vector3.new(28, 1.2, 24),
        CFrame = toWorld(CFrame.new(0, -0.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Foundation_Corner_SidewalkApron",
        Size = Vector3.new(8.0, 0.4, 8.0),
        CFrame = toWorld(CFrame.new(-10.5, -0.2, 10.5)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fFoundation, {
        Name = "Foundation_Store_Threshold",
        Size = Vector3.new(6.0, 0.3, 2.0),
        CFrame = toWorld(CFrame.new(-7.0, -0.05, 9.5) * CFrame.Angles(0, math.rad(-45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Storefront & Ochava Corner Entrance (8 parts)
    -- Angled corner entrance ochava lintel beam
    makePart(fWalls, {
        Name = "Ochava_Corner_Lintel",
        Size = Vector3.new(5.5, 2.4, 1.2),
        CFrame = toWorld(CFrame.new(-9.5, 8.8, 9.5) * CFrame.Angles(0, math.rad(-45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Ochava left pier
    makePart(fWalls, {
        Name = "Ochava_Left_Pier",
        Size = Vector3.new(1.4, 10.0, 1.4),
        CFrame = toWorld(CFrame.new(-11.5, 5.0, 7.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Ochava right pier
    makePart(fWalls, {
        Name = "Ochava_Right_Pier",
        Size = Vector3.new(1.4, 10.0, 1.4),
        CFrame = toWorld(CFrame.new(-7.5, 5.0, 11.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Front display window 1 sill
    makePart(fWalls, {
        Name = "Storefront_Window1_Sill",
        Size = Vector3.new(6.5, 2.0, 1.2),
        CFrame = toWorld(CFrame.new(-2.5, 1.0, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Front display window 1 lintel
    makePart(fWalls, {
        Name = "Storefront_Window1_Lintel",
        Size = Vector3.new(6.5, 2.2, 1.2),
        CFrame = toWorld(CFrame.new(-2.5, 8.9, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Front center pillar
    makePart(fWalls, {
        Name = "Storefront_Center_Pillar",
        Size = Vector3.new(1.6, 10.0, 1.2),
        CFrame = toWorld(CFrame.new(1.5, 5.0, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Front display window 2 (broken/blown out)
    makePart(fWalls, {
        Name = "Storefront_Window2_Sill",
        Size = Vector3.new(6.5, 2.0, 1.2),
        CFrame = toWorld(CFrame.new(5.5, 1.0, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Front right solid corner wall
    makePart(fWalls, {
        Name = "Storefront_East_CornerWall",
        Size = Vector3.new(3.5, 10.0, 1.2),
        CFrame = toWorld(CFrame.new(10.5, 5.0, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Side & Back Walls (6 parts)
    -- West side storefront display
    makePart(fWalls, {
        Name = "West_Side_Window_Sill",
        Size = Vector3.new(1.2, 2.0, 6.5),
        CFrame = toWorld(CFrame.new(-12.5, 1.0, 3.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "West_Side_Rear_Wall",
        Size = Vector3.new(1.2, 9.5, 10.0),
        CFrame = toWorld(CFrame.new(-12.5, 4.75, -5.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- East side wall (partially sheared)
    makePart(fWalls, {
        Name = "East_Side_Wall_Base",
        Size = Vector3.new(1.2, 5.5, 18.0),
        CFrame = toWorld(CFrame.new(12.5, 2.75, 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fWalls, {
        Name = "East_Side_Fracture_Wedge",
        Size = Vector3.new(1.2, 3.5, 7.0),
        CFrame = toWorld(CFrame.new(12.5, 7.25, 4.0) * CFrame.Angles(0, math.rad(180), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Rear warehouse storage wall
    makePart(fWalls, {
        Name = "Rear_Storage_Wall",
        Size = Vector3.new(24.0, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(0, 4.25, -10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Interior counter base (masonry counter where store owner served)
    makePart(fWalls, {
        Name = "Interior_Shop_Counter",
        Size = Vector3.new(7.0, 2.8, 1.6),
        CFrame = toWorld(CFrame.new(-3.0, 1.4, 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Roof & Cornice: Flat roof with decorative Art Deco parapet marquee (5 parts)
    makePart(fRoof, {
        Name = "Roof_Shop_MainSlab",
        Size = Vector3.new(16.0, 0.8, 14.0),
        CFrame = toWorld(CFrame.new(-3.5, 10.4, -2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Parapet_Ochava_Marquee",
        Size = Vector3.new(6.0, 1.8, 1.4),
        CFrame = toWorld(CFrame.new(-9.5, 10.9, 9.5) * CFrame.Angles(0, math.rad(-45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    makePart(fRoof, {
        Name = "Parapet_Front_Molding",
        Size = Vector3.new(15.0, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(1.5, 10.7, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    makePart(fRoof, {
        Name = "Roof_Collapsed_RearSlab",
        Size = Vector3.new(9.0, 0.7, 8.0),
        CFrame = toWorld(CFrame.new(6.5, 4.5, -4.5) * CFrame.Angles(math.rad(20), math.rad(10), math.rad(-15))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Hanging_Rebar",
        Size = Vector3.new(0.3, 0.3, 6.0),
        CFrame = toWorld(CFrame.new(6.0, 6.0, -1.0) * CFrame.Angles(math.rad(-35), 0, math.rad(20))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    -- Openings: Rusted shutter tracks & timber counter plank (3 parts)
    makePart(fOpenings, {
        Name = "Store_Rollup_ShutterTrack",
        Size = Vector3.new(0.3, 6.5, 0.4),
        CFrame = toWorld(CFrame.new(-6.0, 4.5, 10.5)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    makePart(fOpenings, {
        Name = "Store_Counter_TimberTop",
        Size = Vector3.new(7.2, 0.3, 1.8),
        CFrame = toWorld(CFrame.new(-3.0, 2.95, 4.0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "Store_Ochava_HeaderBeam",
        Size = Vector3.new(5.0, 0.4, 0.4),
        CFrame = toWorld(CFrame.new(-9.5, 7.5, 9.5) * CFrame.Angles(0, math.rad(-45), 0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Rubble: Store merchandise debris, broken brickwork, collapsed mortar (6 parts)
    makePart(fRubble, {
        Name = "Rubble_Store_FloorHeap",
        Size = Vector3.new(6.5, 1.5, 5.0),
        CFrame = toWorld(CFrame.new(6.0, 0.75, -2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_Scatter1",
        Size = Vector3.new(2.8, 0.6, 2.0),
        CFrame = toWorld(CFrame.new(2.0, 0.3, 3.5) * CFrame.Angles(0, math.rad(28), 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makePart(fRubble, {
        Name = "Rubble_Ochava_FallenBlock",
        Size = Vector3.new(2.2, 0.8, 1.8),
        CFrame = toWorld(CFrame.new(-11.0, 0.4, 11.0) * CFrame.Angles(math.rad(8), math.rad(40), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Spill_Sidewalk",
        Size = Vector3.new(2.5, 1.0, 3.0),
        CFrame = toWorld(CFrame.new(-3.0, 0.5, 11.5) * CFrame.Angles(0, math.rad(15), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Storage_BackHeap",
        Size = Vector3.new(4.0, 0.9, 2.5),
        CFrame = toWorld(CFrame.new(-5.0, 0.45, -8.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Corner_Debris",
        Size = Vector3.new(1.8, 0.5, 1.5),
        CFrame = toWorld(CFrame.new(9.5, 0.25, 8.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Salt Crust: Evaporite shelves & tide lines (5 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Tide_CommercialFront",
        Size = Vector3.new(26.0, 0.45, 1.4),
        CFrame = toWorld(CFrame.new(0, 1.9, 10.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Tide_WestWall",
        Size = Vector3.new(1.4, 0.45, 20.0),
        CFrame = toWorld(CFrame.new(-12.5, 1.9, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Shop_FloorCrust",
        Size = Vector3.new(8.0, 0.08, 6.0),
        CFrame = toWorld(CFrame.new(-3.0, 0.04, -1.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.3,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Counter_Fringe",
        Size = Vector3.new(7.2, 0.2, 0.8),
        CFrame = toWorld(CFrame.new(-3.0, 1.8, 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_WHITE,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Sidewalk_Crust",
        Size = Vector3.new(4.5, 0.06, 3.5),
        CFrame = toWorld(CFrame.new(-8.0, 0.03, 12.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.25,
    })

    -- Vegetation: Halophytes & dried cardo thistle (4 parts)
    makePart(fVegetation, {
        Name = "Halophyte_Ochava_Crack",
        Size = Vector3.new(1.5, 1.9, 1.3),
        CFrame = toWorld(CFrame.new(-12.5, 0.95, 12.5) * CFrame.Angles(0, math.rad(42), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_Store_WindowSill",
        Size = Vector3.new(0.9, 1.4, 0.9),
        CFrame = toWorld(CFrame.new(5.5, 2.7, 10.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Rear_Yard",
        Size = Vector3.new(1.8, 1.5, 1.4),
        CFrame = toWorld(CFrame.new(8.0, 0.75, -8.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Sidewalk_Edge",
        Size = Vector3.new(1.2, 1.1, 1.0),
        CFrame = toWorld(CFrame.new(3.0, 0.55, 12.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    return foundation
end

-- ============================================================================
-- 4. SMALL HOTEL (Two-story resort accommodation with central hallway & balconies)
-- Target: 55–90 parts
-- ============================================================================

local function buildSmallHotel(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "Roof")
    local fOpenings   = getOrCreateFolder(model, "Openings")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 42 wide x 30 deep x 20 high (Ground floor + Upper floor)
    -- Foundation: Large hotel podium, entrance patio, concrete approach steps (4 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_HotelPlinth",
        Size = Vector3.new(44, 1.4, 32),
        CFrame = toWorld(CFrame.new(0, -0.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Foundation_Entrance_Portico",
        Size = Vector3.new(14, 0.6, 6),
        CFrame = toWorld(CFrame.new(0, -0.3, 17)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fFoundation, {
        Name = "Foundation_Portico_Steps",
        Size = Vector3.new(10, 0.3, 3),
        CFrame = toWorld(CFrame.new(0, -0.15, 20.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Foundation_Side_Walkway",
        Size = Vector3.new(3, 0.4, 28),
        CFrame = toWorld(CFrame.new(-21.5, -0.4, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Ground Floor Front Facade: Entrance portal and symmetrically flanking guestroom windows (8 parts)
    -- Left ground wing
    makePart(fWalls, {
        Name = "GF_Front_Wing_West",
        Size = Vector3.new(12.0, 9.5, 1.4),
        CFrame = toWorld(CFrame.new(-14.0, 4.75, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Left entrance portal jamb
    makePart(fWalls, {
        Name = "GF_Front_Portal_JambWest",
        Size = Vector3.new(2.5, 9.5, 1.4),
        CFrame = toWorld(CFrame.new(-5.25, 4.75, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Walkable grand entrance doorway architrave
    makePart(fWalls, {
        Name = "GF_Front_Portal_Lintel",
        Size = Vector3.new(6.0, 2.5, 1.4),
        CFrame = toWorld(CFrame.new(0, 8.25, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Right entrance portal jamb
    makePart(fWalls, {
        Name = "GF_Front_Portal_JambEast",
        Size = Vector3.new(2.5, 9.5, 1.4),
        CFrame = toWorld(CFrame.new(5.25, 4.75, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Right ground wing window sill
    makePart(fWalls, {
        Name = "GF_Front_Wing_EastSill",
        Size = Vector3.new(6.0, 3.2, 1.4),
        CFrame = toWorld(CFrame.new(11.0, 1.6, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Right ground wing window lintel
    makePart(fWalls, {
        Name = "GF_Front_Wing_EastLintel",
        Size = Vector3.new(6.0, 2.2, 1.4),
        CFrame = toWorld(CFrame.new(11.0, 8.4, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Right ground wing outer corner pier
    makePart(fWalls, {
        Name = "GF_Front_Wing_EastCorner",
        Size = Vector3.new(4.0, 9.5, 1.4),
        CFrame = toWorld(CFrame.new(18.0, 4.75, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Grand portico decorative balcony support corbel
    makePart(fWalls, {
        Name = "GF_Portico_Balcony_Corbel",
        Size = Vector3.new(12.0, 1.2, 3.0),
        CFrame = toWorld(CFrame.new(0, 9.6, 16.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Intermediate Floor Slab (Mezzanine / 1st Floor Slab) (3 parts)
    makePart(fRoof, {
        Name = "Intermediate_FloorSlab_West",
        Size = Vector3.new(20.0, 0.8, 28.0),
        CFrame = toWorld(CFrame.new(-10.0, 9.9, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Intermediate_FloorSlab_East_Collapsed",
        Size = Vector3.new(16.0, 0.8, 18.0),
        CFrame = toWorld(CFrame.new(10.0, 5.5, -2.0) * CFrame.Angles(math.rad(14), math.rad(6), math.rad(-16))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Intermediate_Hallway_Slab",
        Size = Vector3.new(6.0, 0.8, 10.0),
        CFrame = toWorld(CFrame.new(0, 9.9, 8.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    -- Upper Floor (First Floor) Facade & Guestroom Walls (8 parts)
    makePart(fWalls, {
        Name = "UF_Front_Balcony_WallWest",
        Size = Vector3.new(12.0, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(-14.0, 14.55, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "UF_Front_Center_BalconyDoor_Left",
        Size = Vector3.new(2.0, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(-4.0, 14.55, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "UF_Front_Center_BalconyLintel",
        Size = Vector3.new(5.0, 2.2, 1.2),
        CFrame = toWorld(CFrame.new(0, 17.7, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "UF_Front_Center_BalconyDoor_Right",
        Size = Vector3.new(2.0, 8.5, 1.2),
        CFrame = toWorld(CFrame.new(4.0, 14.55, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "UF_Front_Balustrade_Parapet",
        Size = Vector3.new(10.0, 2.5, 0.8),
        CFrame = toWorld(CFrame.new(0, 11.55, 17.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Sheared east upper wall
    makePart(fWalls, {
        Name = "UF_Front_East_StandingStub",
        Size = Vector3.new(6.0, 5.0, 1.2),
        CFrame = toWorld(CFrame.new(12.0, 12.8, 14.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fWalls, {
        Name = "UF_Front_East_ShearWedge",
        Size = Vector3.new(1.2, 3.2, 5.0),
        CFrame = toWorld(CFrame.new(16.0, 13.9, 14.5) * CFrame.Angles(0, math.rad(90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Parapet decorative roof marquee
    makePart(fWalls, {
        Name = "UF_Roof_Parapet_Marquee",
        Size = Vector3.new(14.0, 1.8, 1.4),
        CFrame = toWorld(CFrame.new(-8.0, 19.7, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Outer Perimeter Walls & Rear Wings (8 parts)
    -- West side exterior wall (two stories)
    makePart(fWalls, {
        Name = "West_Side_GF_Wall",
        Size = Vector3.new(1.4, 9.5, 28.0),
        CFrame = toWorld(CFrame.new(-19.5, 4.75, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "West_Side_UF_Wall",
        Size = Vector3.new(1.2, 8.5, 20.0),
        CFrame = toWorld(CFrame.new(-19.5, 14.55, 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- East side exterior wall (partially standing ground, sheared upper)
    makePart(fWalls, {
        Name = "East_Side_GF_Wall",
        Size = Vector3.new(1.4, 9.5, 28.0),
        CFrame = toWorld(CFrame.new(19.5, 4.75, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "East_Side_UF_Wall_Stump",
        Size = Vector3.new(1.2, 4.5, 12.0),
        CFrame = toWorld(CFrame.new(19.5, 12.55, 8.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    -- Rear hotel wall with courtyard service doors
    makePart(fWalls, {
        Name = "Rear_Hotel_Wall_West",
        Size = Vector3.new(18.0, 9.5, 1.4),
        CFrame = toWorld(CFrame.new(-10.0, 4.75, -14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Rear_Hotel_Wall_East",
        Size = Vector3.new(18.0, 6.0, 1.4),
        CFrame = toWorld(CFrame.new(10.0, 3.0, -14.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Central corridor hotel partition walls (creating walkable guestroom suites)
    makePart(fWalls, {
        Name = "Interior_Spine_Hallway_West",
        Size = Vector3.new(0.8, 9.0, 20.0),
        CFrame = toWorld(CFrame.new(-3.5, 4.5, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makePart(fWalls, {
        Name = "Interior_Spine_Hallway_East",
        Size = Vector3.new(0.8, 9.0, 20.0),
        CFrame = toWorld(CFrame.new(3.5, 4.5, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    -- Roof: Upper concrete roof slab and structural rebar / tilted beams (5 parts)
    makePart(fRoof, {
        Name = "Roof_Upper_WestSlab",
        Size = Vector3.new(18.0, 0.8, 22.0),
        CFrame = toWorld(CFrame.new(-10.0, 19.2, 3.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Upper_Cornice_Molding",
        Size = Vector3.new(18.5, 0.8, 1.2),
        CFrame = toWorld(CFrame.new(-10.0, 20.0, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRoof, {
        Name = "Roof_Upper_Collapsed_Slab",
        Size = Vector3.new(12.0, 0.7, 12.0),
        CFrame = toWorld(CFrame.new(8.0, 12.0, 0) * CFrame.Angles(math.rad(24), math.rad(-12), math.rad(18))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_SLAB,
    })

    makePart(fRoof, {
        Name = "Roof_Hanging_SteelBeam1",
        Size = Vector3.new(0.4, 0.4, 14.0),
        CFrame = toWorld(CFrame.new(5.0, 14.5, 2.0) * CFrame.Angles(math.rad(-28), 0, math.rad(15))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    makePart(fRoof, {
        Name = "Roof_Hanging_SteelBeam2",
        Size = Vector3.new(0.4, 0.4, 10.0),
        CFrame = toWorld(CFrame.new(12.0, 10.5, -6.0) * CFrame.Angles(math.rad(15), math.rad(20), math.rad(-30))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    -- Openings: Rotted timber lintels, lobby reception counter stump (4 parts)
    makePart(fOpenings, {
        Name = "Lobby_Reception_Counter",
        Size = Vector3.new(6.0, 3.0, 1.8),
        CFrame = toWorld(CFrame.new(-7.5, 1.5, 6.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fOpenings, {
        Name = "Lobby_Counter_TimberTop",
        Size = Vector3.new(6.4, 0.3, 2.0),
        CFrame = toWorld(CFrame.new(-7.5, 3.15, 6.0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "GrandDoor_Jamb_TimberLeft",
        Size = Vector3.new(0.4, 7.0, 0.4),
        CFrame = toWorld(CFrame.new(-2.8, 3.5, 14.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "GrandDoor_Jamb_TimberRight",
        Size = Vector3.new(0.4, 7.0, 0.4),
        CFrame = toWorld(CFrame.new(2.8, 3.5, 14.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Rubble: Major collapsed concrete slabs, masonry piles, plaster heaps (10 parts)
    makePart(fRubble, {
        Name = "Rubble_Lobby_MainHeap",
        Size = Vector3.new(9.0, 2.0, 7.0),
        CFrame = toWorld(CFrame.new(10.0, 1.0, 2.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Courtyard_Mound",
        Size = Vector3.new(8.0, 1.8, 6.0),
        CFrame = toWorld(CFrame.new(6.0, 0.9, -8.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_BalconyChunk",
        Size = Vector3.new(4.5, 1.0, 2.5),
        CFrame = toWorld(CFrame.new(5.0, 0.5, 16.5) * CFrame.Angles(math.rad(10), math.rad(25), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_MoundEast",
        Size = Vector3.new(4.0, 1.2, 3.5),
        CFrame = toWorld(CFrame.new(17.0, 0.6, 5.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makePart(fRubble, {
        Name = "Rubble_Hallway_Scatter",
        Size = Vector3.new(2.5, 0.5, 2.0),
        CFrame = toWorld(CFrame.new(0, 0.25, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Spill_Wedge1",
        Size = Vector3.new(3.5, 1.5, 4.0),
        CFrame = toWorld(CFrame.new(14.0, 0.75, -4.0) * CFrame.Angles(0, math.rad(-25), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Spill_Wedge2",
        Size = Vector3.new(3.0, 1.2, 3.0),
        CFrame = toWorld(CFrame.new(8.0, 0.6, 12.0) * CFrame.Angles(0, math.rad(45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_WestRoom_Debris",
        Size = Vector3.new(3.0, 0.6, 2.5),
        CFrame = toWorld(CFrame.new(-12.0, 0.3, -4.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_CorniceBlock",
        Size = Vector3.new(3.5, 0.7, 1.4),
        CFrame = toWorld(CFrame.new(-8.0, 0.35, 16.5) * CFrame.Angles(0, math.rad(-15), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRubble, {
        Name = "Rubble_Exterior_ApronChunk",
        Size = Vector3.new(2.4, 0.5, 1.8),
        CFrame = toWorld(CFrame.new(-18.0, 0.25, 15.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Salt Crust: Thick mineral shelves, tide lines, evaporite sheets (6 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Tide_HotelFront",
        Size = Vector3.new(42.0, 0.5, 1.6),
        CFrame = toWorld(CFrame.new(0, 2.2, 14.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Tide_WestWall",
        Size = Vector3.new(1.6, 0.5, 28.0),
        CFrame = toWorld(CFrame.new(-19.5, 2.2, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Lobby_EvaporiteFloor",
        Size = Vector3.new(12.0, 0.1, 10.0),
        CFrame = toWorld(CFrame.new(-8.0, 0.05, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.32,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Portico_Crust",
        Size = Vector3.new(8.0, 0.08, 4.0),
        CFrame = toWorld(CFrame.new(0, 0.04, 18.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.3,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Balcony_Waterline",
        Size = Vector3.new(10.0, 0.3, 1.0),
        CFrame = toWorld(CFrame.new(0, 12.0, 17.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_WHITE,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Rear_CornerDeposit",
        Size = Vector3.new(4.0, 0.4, 4.0),
        CFrame = toWorld(CFrame.new(17.0, 0.2, -12.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    -- Vegetation: Halophyte bushes & dead thistles (5 parts)
    makePart(fVegetation, {
        Name = "Halophyte_Portico_Shrub",
        Size = Vector3.new(2.0, 2.5, 1.8),
        CFrame = toWorld(CFrame.new(-6.5, 1.25, 18.5) * CFrame.Angles(0, math.rad(20), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Courtyard_Bush",
        Size = Vector3.new(2.4, 2.0, 2.0),
        CFrame = toWorld(CFrame.new(12.0, 1.0, -10.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_UpperBalcony",
        Size = Vector3.new(1.0, 1.6, 0.9),
        CFrame = toWorld(CFrame.new(3.5, 11.2, 15.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Lobby_Crack",
        Size = Vector3.new(1.4, 1.5, 1.2),
        CFrame = toWorld(CFrame.new(-2.0, 0.75, 4.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_WestPath",
        Size = Vector3.new(1.2, 1.4, 1.1),
        CFrame = toWorld(CFrame.new(-21.5, 0.7, 5.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    return foundation
end

-- ============================================================================
-- 5. FACADE RUINS (Iconic Epecuén standalone facade wall with doorway & windows)
-- Target: 20–40 parts
-- ============================================================================

local function buildFacadeRuins(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "Roof")
    local fOpenings   = getOrCreateFolder(model, "Openings")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 24 wide x 8 deep x 12 high
    -- Foundation: Street curb & entry stoop (2 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_FacadePlinth",
        Size = Vector3.new(26, 1.0, 8),
        CFrame = toWorld(CFrame.new(0, -0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Entrance_Threshold_Stoop",
        Size = Vector3.new(5.0, 0.4, 2.5),
        CFrame = toWorld(CFrame.new(-3.0, -0.2, 2.5)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Standing Facade: Pier left of door, door lintel, pier between door and window,
    -- window sill, window lintel, right pier, decorative top cornice (7 parts)
    makePart(fWalls, {
        Name = "Facade_Left_Pier",
        Size = Vector3.new(5.5, 10.0, 1.4),
        CFrame = toWorld(CFrame.new(-8.25, 5.0, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Facade_Door_Lintel",
        Size = Vector3.new(4.5, 2.6, 1.4),
        CFrame = toWorld(CFrame.new(-3.0, 8.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Facade_Center_Pier",
        Size = Vector3.new(3.5, 10.0, 1.4),
        CFrame = toWorld(CFrame.new(1.0, 5.0, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Facade_Window_Sill",
        Size = Vector3.new(4.0, 3.4, 1.4),
        CFrame = toWorld(CFrame.new(4.75, 1.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Facade_Window_Lintel",
        Size = Vector3.new(4.0, 2.2, 1.4),
        CFrame = toWorld(CFrame.new(4.75, 8.9, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fWalls, {
        Name = "Facade_Right_Pier_Fractured",
        Size = Vector3.new(4.5, 7.0, 1.4),
        CFrame = toWorld(CFrame.new(9.0, 3.5, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fWalls, {
        Name = "Facade_Top_Fracture_Wedge",
        Size = Vector3.new(1.4, 2.5, 5.0),
        CFrame = toWorld(CFrame.new(9.0, 8.25, 0) * CFrame.Angles(0, math.rad(90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Butressing side stubs (former return walls) (3 parts)
    makePart(fWalls, {
        Name = "Facade_Left_ReturnWall_Stub",
        Size = Vector3.new(1.2, 6.5, 3.5),
        CFrame = toWorld(CFrame.new(-10.4, 3.25, -2.25)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makeWedge(fWalls, {
        Name = "Facade_Left_ReturnWall_Wedge",
        Size = Vector3.new(1.2, 2.5, 3.0),
        CFrame = toWorld(CFrame.new(-10.4, 7.75, -2.0) * CFrame.Angles(0, math.rad(180), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(fWalls, {
        Name = "Facade_Right_ReturnWall_LowStub",
        Size = Vector3.new(1.2, 3.0, 3.0),
        CFrame = toWorld(CFrame.new(10.65, 1.5, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Parapet cornice moulding (2 parts)
    makePart(fRoof, {
        Name = "Facade_Cornice_Main",
        Size = Vector3.new(16.0, 1.4, 1.6),
        CFrame = toWorld(CFrame.new(-3.0, 10.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRoof, {
        Name = "Facade_Cornice_Dentil",
        Size = Vector3.new(14.0, 0.4, 1.8),
        CFrame = toWorld(CFrame.new(-3.0, 11.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Openings: Rotted wooden frame beam & transom splinter (2 parts)
    makePart(fOpenings, {
        Name = "Door_Header_RottedWood",
        Size = Vector3.new(4.4, 0.35, 1.2),
        CFrame = toWorld(CFrame.new(-3.0, 7.25, 0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    makePart(fOpenings, {
        Name = "Window_Mullion_Corroded",
        Size = Vector3.new(0.2, 3.5, 0.2),
        CFrame = toWorld(CFrame.new(4.75, 5.2, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CORRODED_IRON,
    })

    -- Rubble: Scree mounds front and back, fallen cornice chunk, scattered bricks (5 parts)
    makePart(fRubble, {
        Name = "Rubble_Back_ScreeMound",
        Size = Vector3.new(8.0, 1.4, 4.0),
        CFrame = toWorld(CFrame.new(3.0, 0.7, -2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Front_DebrisApron",
        Size = Vector3.new(5.0, 0.7, 2.5),
        CFrame = toWorld(CFrame.new(6.0, 0.35, 2.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_CorniceBlock",
        Size = Vector3.new(3.0, 0.8, 1.5),
        CFrame = toWorld(CFrame.new(8.5, 0.4, 2.5) * CFrame.Angles(0, math.rad(30), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_Scatter",
        Size = Vector3.new(2.0, 0.5, 1.6),
        CFrame = toWorld(CFrame.new(-7.0, 0.25, 2.0) * CFrame.Angles(0, math.rad(-20), 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Debris_Wedge",
        Size = Vector3.new(2.5, 0.8, 2.5),
        CFrame = toWorld(CFrame.new(-6.0, 0.4, -2.5) * CFrame.Angles(0, math.rad(45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    -- Salt Crust: Waterline shelf and evaporite base crust (4 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Tide_FrontFacade",
        Size = Vector3.new(24.0, 0.4, 1.5),
        CFrame = toWorld(CFrame.new(0, 1.8, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Evaporite_Threshold",
        Size = Vector3.new(4.0, 0.08, 2.5),
        CFrame = toWorld(CFrame.new(-3.0, 0.04, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.3,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Back_Puddle",
        Size = Vector3.new(6.0, 0.08, 3.5),
        CFrame = toWorld(CFrame.new(2.0, 0.04, -2.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.25,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Pier_Collar",
        Size = Vector3.new(5.8, 0.3, 1.6),
        CFrame = toWorld(CFrame.new(-8.25, 0.8, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_WHITE,
    })

    -- Vegetation: Halophytes & pampas thistle (3 parts)
    makePart(fVegetation, {
        Name = "Halophyte_Facade_Threshold",
        Size = Vector3.new(1.4, 1.7, 1.2),
        CFrame = toWorld(CFrame.new(-0.8, 0.85, 1.8) * CFrame.Angles(0, math.rad(25), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_Facade_WindowSill",
        Size = Vector3.new(0.8, 1.3, 0.8),
        CFrame = toWorld(CFrame.new(4.75, 3.9, 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Back_Rubble",
        Size = Vector3.new(1.6, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(7.0, 0.7, -3.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    return foundation
end

-- ============================================================================
-- 6. WALL RUINS (Boundary perimeter masonry wall with fracture breach & pillars)
-- Target: 15–30 parts
-- ============================================================================

local function buildWallRuins(
    model: Model,
    rootCF: CFrame,
    damage: number,
    salt: number,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local fVegetation = getOrCreateFolder(model, "Vegetation")

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Dimensions: 26 wide x 6 deep x 8 high
    -- Foundation: Concrete footings / sidewalk curb (2 parts)
    local foundation = makePart(fFoundation, {
        Name = "Foundation_WallFooting",
        Size = Vector3.new(28, 0.8, 5),
        CFrame = toWorld(CFrame.new(0, -0.4, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(fFoundation, {
        Name = "Foundation_Sidewalk_Curb",
        Size = Vector3.new(28, 0.3, 1.2),
        CFrame = toWorld(CFrame.new(0, 0.15, 2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- Standing Masonry Wall Sections (6 parts)
    -- Left intact pillar
    makePart(fWalls, {
        Name = "Wall_Pillar_West",
        Size = Vector3.new(1.8, 7.5, 1.8),
        CFrame = toWorld(CFrame.new(-12.5, 3.75, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Left pillar decorative pyramidal cap
    makePart(fWalls, {
        Name = "Wall_Pillar_WestCap",
        Size = Vector3.new(2.2, 0.8, 2.2),
        CFrame = toWorld(CFrame.new(-12.5, 7.9, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- West main wall section (standing)
    makePart(fWalls, {
        Name = "Wall_Span_West",
        Size = Vector3.new(8.0, 5.8, 1.0),
        CFrame = toWorld(CFrame.new(-7.5, 2.9, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    -- West wall coping beam
    makePart(fWalls, {
        Name = "Wall_Coping_West",
        Size = Vector3.new(8.2, 0.6, 1.3),
        CFrame = toWorld(CFrame.new(-7.5, 6.1, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Center breached wall section (partially crumbled, creating a walkable opening)
    makePart(fWalls, {
        Name = "Wall_Breach_LowStump",
        Size = Vector3.new(5.0, 1.6, 1.0),
        CFrame = toWorld(CFrame.new(0, 0.8, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- East wall section with fracture wedge
    makePart(fWalls, {
        Name = "Wall_Span_East",
        Size = Vector3.new(7.0, 4.5, 1.0),
        CFrame = toWorld(CFrame.new(6.5, 2.25, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makeWedge(fWalls, {
        Name = "Wall_East_ShearWedge",
        Size = Vector3.new(1.0, 2.4, 4.0),
        CFrame = toWorld(CFrame.new(6.5, 5.7, 0) * CFrame.Angles(0, math.rad(90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- East fallen pillar stub
    makePart(fWalls, {
        Name = "Wall_Pillar_EastStub",
        Size = Vector3.new(1.8, 3.2, 1.8),
        CFrame = toWorld(CFrame.new(11.5, 1.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_OCHRE,
    })

    -- Rubble: Crumbled bricks, fallen mortar, displaced coping stone (5 parts)
    makePart(fRubble, {
        Name = "Rubble_Breach_Heap",
        Size = Vector3.new(4.5, 0.9, 3.0),
        CFrame = toWorld(CFrame.new(0, 0.45, 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_PillarCap",
        Size = Vector3.new(2.0, 0.7, 2.0),
        CFrame = toWorld(CFrame.new(12.5, 0.35, 1.5) * CFrame.Angles(math.rad(12), math.rad(28), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    makePart(fRubble, {
        Name = "Rubble_Brick_Scatter",
        Size = Vector3.new(2.4, 0.5, 1.6),
        CFrame = toWorld(CFrame.new(-3.0, 0.25, -1.5) * CFrame.Angles(0, math.rad(-35), 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EXPOSED,
    })

    makeWedge(fRubble, {
        Name = "Rubble_Spill_Wedge",
        Size = Vector3.new(2.2, 0.8, 2.2),
        CFrame = toWorld(CFrame.new(3.0, 0.4, 1.5) * CFrame.Angles(0, math.rad(30), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(fRubble, {
        Name = "Rubble_Fallen_CopingChunk",
        Size = Vector3.new(3.0, 0.5, 1.0),
        CFrame = toWorld(CFrame.new(8.0, 0.25, -1.5) * CFrame.Angles(0, math.rad(18), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_PALE,
    })

    -- Salt Crust: Tide line across wall & base evaporite deposit (3 parts)
    makePart(fSaltCrust, {
        Name = "Salt_Tide_WallBand",
        Size = Vector3.new(26.0, 0.35, 1.2),
        CFrame = toWorld(CFrame.new(0, 1.8, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_CREAM,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Base_EvaporiteSheet",
        Size = Vector3.new(8.0, 0.06, 3.0),
        CFrame = toWorld(CFrame.new(-5.0, 0.03, 1.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_WHITE,
        Reflectance = 0.3,
    })

    makePart(fSaltCrust, {
        Name = "Salt_Pillar_BaseCrust",
        Size = Vector3.new(2.2, 0.3, 2.2),
        CFrame = toWorld(CFrame.new(-12.5, 0.6, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST_WHITE,
    })

    -- Vegetation: Halophytes & saltbush (3 parts)
    makePart(fVegetation, {
        Name = "Halophyte_WallBreach",
        Size = Vector3.new(1.5, 1.8, 1.3),
        CFrame = toWorld(CFrame.new(-1.8, 0.9, 0.8) * CFrame.Angles(0, math.rad(30), 0)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    makePart(fVegetation, {
        Name = "Thistle_PillarWest",
        Size = Vector3.new(1.0, 1.5, 0.9),
        CFrame = toWorld(CFrame.new(-13.5, 0.75, 1.2)),
        Material = Enum.Material.Grass,
        Color = COLOR_DEAD_THISTLE,
    })

    makePart(fVegetation, {
        Name = "Halophyte_Rubble_East",
        Size = Vector3.new(1.4, 1.3, 1.2),
        CFrame = toWorld(CFrame.new(10.5, 0.65, -1.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_HALOPHYTE_WEED,
    })

    return foundation
end

-- ============================================================================
-- METRICS REGISTRY
-- ============================================================================

local METRICS: { [string]: BuildingMetric } = {
    HouseSmall = {
        Type = "HouseSmall",
        EstimatedPartRange = "25–45 parts (30 parts)",
        Dimensions = Vector3.new(23, 11, 19),
        Description = "Single-story vernacular brick/stucco chalet with walkable entrance, window aperture, collapsed flat roof, and rubble scree.",
    },
    HouseMedium = {
        Type = "HouseMedium",
        EstimatedPartRange = "35–60 parts (43 parts)",
        Dimensions = Vector3.new(34, 13, 26),
        Description = "Two-room summer residence with veranda porch columns, entrance steps, low boundary garden wall, and interior hallway spine.",
    },
    ShopRuins = {
        Type = "ShopRuins",
        EstimatedPartRange = "35–65 parts (40 parts)",
        Dimensions = Vector3.new(28, 13, 24),
        Description = "Commercial almacén with 45-degree corner ochava entrance, display storefront openings, interior masonry counter, and Art Deco parapet.",
    },
    SmallHotel = {
        Type = "SmallHotel",
        EstimatedPartRange = "55–90 parts (61 parts)",
        Dimensions = Vector3.new(44, 20, 32),
        Description = "Two-story resort accommodation with central hallway, lobby reception desk, grand entrance portico, upper balcony, and collapsed wing.",
    },
    FacadeRuins = {
        Type = "FacadeRuins",
        EstimatedPartRange = "20–40 parts (28 parts)",
        Dimensions = Vector3.new(26, 12, 8),
        Description = "Iconic standalone facade wall with entrance doorway architrave, window aperture, dentil cornice molding, and buttressing return stubs.",
    },
    WallRuins = {
        Type = "WallRuins",
        EstimatedPartRange = "15–30 parts (21 parts)",
        Dimensions = Vector3.new(28, 8, 5),
        Description = "Boundary perimeter masonry wall with entrance breach opening, decorative pillars, coping stones, and salt tide shelves.",
    },
}

function UrbanBuildingModelBuilder.GetMetrics(): { [string]: BuildingMetric }
    return METRICS
end

-- ============================================================================
-- MAIN BUILD DISPATCHER
-- ============================================================================

function UrbanBuildingModelBuilder.Build(options: UrbanBuildOptions?): Model
    local opts = options or {}
    local pos = opts.Position or Vector3.zero
    local rotY = opts.RotationY or 0
    local rawType = opts.BuildingType or "HouseSmall"
    local bType = rawType :: BuildingType
    local damage = math.clamp(opts.DamageLevel or 0.65, 0.0, 1.0)
    local salt = math.clamp(opts.SaltLevel or 0.70, 0.0, 1.0)
    local seed = opts.Seed or 4242
    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or (tostring(bType) .. "_UrbanRuin")

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    local primaryPart: Part? = nil

    if bType == "HouseSmall" then
        primaryPart = buildHouseSmall(model, rootCF, damage, salt, rng)
    elseif bType == "HouseMedium" then
        primaryPart = buildHouseMedium(model, rootCF, damage, salt, rng)
    elseif bType == "ShopRuins" then
        primaryPart = buildShopRuins(model, rootCF, damage, salt, rng)
    elseif bType == "SmallHotel" then
        primaryPart = buildSmallHotel(model, rootCF, damage, salt, rng)
    elseif bType == "FacadeRuins" then
        primaryPart = buildFacadeRuins(model, rootCF, damage, salt, rng)
    elseif bType == "WallRuins" then
        primaryPart = buildWallRuins(model, rootCF, damage, salt, rng)
    else
        -- Fallback to HouseSmall
        primaryPart = buildHouseSmall(model, rootCF, damage, salt, rng)
    end

    if primaryPart then
        model.PrimaryPart = primaryPart
    end

    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

return UrbanBuildingModelBuilder
