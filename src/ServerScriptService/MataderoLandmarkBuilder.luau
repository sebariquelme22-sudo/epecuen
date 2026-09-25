--!strict
--[[
    MataderoLandmarkBuilder.luau
    Location: ServerScriptService/MataderoLandmarkBuilder.luau

    Procedural Landmark Architecture Builder for the Ruined Municipal Slaughterhouse
    of Villa Epecuén / Carhué, designed by famed architect Francisco Salamone (1938).

    Canonical Map Reference:
      - Location: Position = Vector3.new(650, 15, 480) (Zone: ZONE_MATADERO)
      - Footprint: Approximately 90 x 65 studs
      - Maximum Height: Approximately 56 studs (Monumental clocktower and fin blade)
      - Access: Connected to town via Camino al Matadero (RD_CAMINO_MATADERO)

    Architectural & Historical Profile:
      Built in 1937–1938 under the administration of Governor Manuel Fresco, the Matadero
      Municipal was designed by the visionary Italian-Argentine architect Francisco Salamone.
      Salamone transformed the flat Argentine pampas with monumental municipal palaces,
      cemetery portals, and slaughterhouses rendered in a dramatic synthesis of Art Deco,
      Italian Futurism, and Brutalist Monumentalism.

      Key Historical Features of the Epecuén / Guaminí Slaughterhouse:
        - Towering vertical clocktower with a razor-sharp aerodynamic fin blade (cuchilla)
          that pierces the sky and acts as an orienting navigation beacon visible for kilometers.
        - Recessed geometric clock dial set high into the concrete tower pylon.
        - Monumental cantilevered horizontal entrance portico and stepped facade wings.
        - Industrial slaughterhall (nave de faena) with high clerestory ventilation embrasures,
          curved transition walls, overhead meat rails (carril de faena), and drainage gutters.
        - Secondary industrial service wing (cold storage rooms, boiler stack, loading chutes).
        - Asymmetric flood catastrophe: when the hyper-saline waters of Laguna Epecuén
          rose in 1985, the building was partially inundated. The industrial wings suffered
          heavy roof collapse, sheared slabs, and exposed rebar, while Salamone's colossal
          tower stood undefeated against the brine.
        - Salt crusts and mineral waterline shelves encrusting the lower 4-8 studs.
        - Post-flood pampas halophytes and dry cardo weeds colonizing the cracked concrete.

    Technical Constraints:
      - 100% native Roblox geometry: Part (Block, Cylinder), WedgePart, CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, sounds, AI, or ProximityPrompts.
      - ZERO automatic instantiation into Workspace on module require/load.
      - Fully deterministic through Random.new(seed).
      - Optimized budget: strictly ~120-180 parts.
      - Organized into designated sub-folders:
          Foundation, MainStructure, Tower, Clock, Facade, IndustrialWing,
          Openings, RoofDamage, InteriorStructure, Rubble, SaltCrust, Vegetation.
--]]

local MataderoLandmarkBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type MataderoBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    Parent: Instance?,
    DamageLevel: number?, -- 0.0 to 1.0 (default 0.85)
    SaltLevel: number?,   -- 0.0 to 1.0 (default 0.85)
    Seed: number?,
    Scale: number?,
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
    Reflectance: number?,
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
    Reflectance: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

export type CylinderConfig = {
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

-- ============================================================================
-- AUTHENTIC COLOR & MATERIAL PALETTE (Francisco Salamone Monumental Concrete)
-- ============================================================================

-- Salamone White & Grey Monumental Concrete (Cemento Armado Blanco / Gris)
local COLOR_SALAMONE_WHITE       = Color3.fromRGB(205, 202, 194) -- Classic Salamone bleached monumental white
local COLOR_SALAMONE_WARM_CREAM  = Color3.fromRGB(192, 188, 178) -- Sun-weathered concrete face
local COLOR_CONCRETE_MID         = Color3.fromRGB(165, 162, 154) -- Weathered saline exterior plaster
local COLOR_CONCRETE_CORE        = Color3.fromRGB(138, 134, 126) -- Structural reinforced concrete core
local COLOR_CONCRETE_DARK        = Color3.fromRGB(112, 108, 102) -- Damp waterline-stained foundation

-- Exposed Clay Masonry & Submerged Brickwork
local COLOR_BRICK_RED            = Color3.fromRGB(162, 88, 68)   -- Ladrillo común bonaerense behind cracked plaster
local COLOR_BRICK_DARK           = Color3.fromRGB(130, 70, 54)   -- Damp submerged brick
local COLOR_BRICK_MORTAR_MIX     = Color3.fromRGB(152, 114, 98)  -- Crumbled brick/concrete slurry

-- Clock Face & Dial Elements
local COLOR_CLOCK_DIAL           = Color3.fromRGB(235, 234, 226) -- Recessed clock dial disc
local COLOR_CLOCK_HANDS          = Color3.fromRGB(48, 44, 42)    -- Corroded iron hands & hour markers
local COLOR_CLOCK_BEZEL          = Color3.fromRGB(95, 92, 86)    -- Dark recessed clock surround frame

-- Industrial Corroded Metals & Structural Rebar
local COLOR_RUST_FLAKING         = Color3.fromRGB(118, 60, 38)   -- Corroded steel I-beams & shutter
local COLOR_RUST_DARK            = Color3.fromRGB(80, 44, 32)    -- Heavy oxidized iron meat rail & rebar

-- Mineral Salt Crusts & Laguna Epecuén Waterline Deposits
local COLOR_SALT_CRYSTAL_WHITE   = Color3.fromRGB(252, 252, 248) -- Pure calcified mineral crust
local COLOR_SALT_OFFWHITE        = Color3.fromRGB(236, 238, 230) -- Thick calcified brine shelf
local COLOR_SALT_SILT_BLEND      = Color3.fromRGB(216, 218, 208) -- Tide-line evaporite silt

-- Post-Flood Pampas Vegetation (Halophytes & Saline Weeds)
local COLOR_VEG_SAGE_SHRUB       = Color3.fromRGB(110, 126, 96)  -- Argentine pampas halophyte scrub
local COLOR_VEG_DRY_THISTLE      = Color3.fromRGB(140, 138, 100) -- Bleached cardo / dry thistle
local COLOR_VEG_DARK_MOSS        = Color3.fromRGB(84, 96, 70)    -- Damp brine moss in dock shadows

-- Canonical Location Default
local CANONICAL_MATADERO_POS     = Vector3.new(650, 15, 480)

-- ============================================================================
-- PRIMITIVE CONSTRUCTORS (100% NATIVE ROBLOX GEOMETRY, ANCHORED)
-- ============================================================================

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.Concrete
    p.Color = cfg.Color or COLOR_SALAMONE_WHITE
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
    w.Color = cfg.Color or COLOR_SALAMONE_WHITE
    w.Transparency = cfg.Transparency or 0
    w.Reflectance = cfg.Reflectance or 0
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
    cw.Color = cfg.Color or COLOR_SALAMONE_WHITE
    cw.Transparency = cfg.Transparency or 0
    cw.Reflectance = cfg.Reflectance or 0
    cw.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    cw.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    cw.Anchored = true
    cw.Parent = parent
    return cw
end

local function makeCylinder(parent: Instance, cfg: CylinderConfig): Part
    local c = Instance.new("Part")
    c.Name = cfg.Name
    c.Shape = Enum.PartType.Cylinder
    c.Size = cfg.Size
    c.CFrame = cfg.CFrame
    c.Material = cfg.Material or Enum.Material.Concrete
    c.Color = cfg.Color or COLOR_SALAMONE_WHITE
    c.Transparency = cfg.Transparency or 0
    c.Reflectance = cfg.Reflectance or 0
    c.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    c.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    c.Anchored = true
    c.Parent = parent
    return c
end

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local f = parent:FindFirstChild(name)
    if not f or not f:IsA("Folder") then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f :: Folder
end

-- ============================================================================
-- MATADERO MUNICIPAL BUILD LOGIC
-- ============================================================================
-- Local Coordinate Space:
--   - Origin (0, 0, 0): Center of slaughterhouse base.
--   - Footprint: ~88 x 64 studs (-44 to +44 studs X, -32 to +32 studs Z)
--   - Width (X Axis):
--       * West Wing / Cattle Chute & Service (X = -44 to -18)
--       * Central Salamone Pylon & Tower (X = -18 to +14)
--       * East Industrial Slaughterhall & Cold Storage (X = +14 to +44)
--   - Depth (Z Axis):
--       * Front Facade, Portico & Tower (Z = -30 to -12)
--       * Main Processing Hall & Abattoir (Z = -12 to +16)
--       * Rear Cattle Pens & Loading Dock (Z = +16 to +32)
--   - Height (Y Axis):
--       * Ground at Y = 0 (Canonical World Y = 15).
--       * Main Slaughterhall walls reach Y = 18 to 24 studs.
--       * Monumental Entrance Marquee reaches Y = 12 studs.
--       * Salamone Clocktower reaches Y = 46 studs.
--       * Monumental Fin Blade (Cuchilla) crest reaches Y = 56 studs max!
-- ============================================================================

local function buildMataderoLandmark(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: MataderoBuildOptions,
    rng: Random
): Part
    -- Sub-folders as strictly specified
    local folderFoundation        = getOrCreateFolder(model, "Foundation")
    local folderMainStructure     = getOrCreateFolder(model, "MainStructure")
    local folderTower             = getOrCreateFolder(model, "Tower")
    local folderClock             = getOrCreateFolder(model, "Clock")
    local folderFacade            = getOrCreateFolder(model, "Facade")
    local folderIndustrialWing    = getOrCreateFolder(model, "IndustrialWing")
    local folderOpenings          = getOrCreateFolder(model, "Openings")
    local folderRoofDamage        = getOrCreateFolder(model, "RoofDamage")
    local folderInteriorStructure = getOrCreateFolder(model, "InteriorStructure")
    local folderRubble            = getOrCreateFolder(model, "Rubble")
    local folderSaltCrust         = getOrCreateFolder(model, "SaltCrust")
    local folderVegetation        = getOrCreateFolder(model, "Vegetation")

    local _damage = opts.DamageLevel or 0.85
    local _salt = opts.SaltLevel or 0.85

    -- ------------------------------------------------------------------------
    -- 1. FOUNDATION (~12 parts)
    -- ------------------------------------------------------------------------
    -- Primary Part: Central monumental foundation slab
    local primaryFoundation = makePart(folderFoundation, {
        Name = "MataderoBasePlinth",
        Size = Vector3.new(88 * scale, 1.8 * scale, 62 * scale),
        CFrame = rootCF * CFrame.new(0, 0.9 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CastShadow = true,
    })

    -- Raised slaughterhall floor slab
    makePart(folderFoundation, {
        Name = "SlaughterHall_RaisedFloor",
        Size = Vector3.new(46 * scale, 1.0 * scale, 36 * scale),
        CFrame = rootCF * CFrame.new(16 * scale, 2.3 * scale, 2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })

    -- Monumental front entrance stepped podium (3 stepped tiers)
    makePart(folderFoundation, {
        Name = "MonumentalSteps_Lower",
        Size = Vector3.new(28 * scale, 0.6 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 0.3 * scale, -32 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFoundation, {
        Name = "MonumentalSteps_Mid",
        Size = Vector3.new(24 * scale, 0.6 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 0.9 * scale, -30 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFoundation, {
        Name = "MonumentalSteps_Upper",
        Size = Vector3.new(20 * scale, 0.6 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 1.5 * scale, -28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Tower colossal foundation pad (under Salamone tower base)
    makePart(folderFoundation, {
        Name = "TowerFoundationPad",
        Size = Vector3.new(24 * scale, 2.4 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 1.2 * scale, -20 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Rear cattle unloading dock and ramp
    makePart(folderFoundation, {
        Name = "LoadingDock_MainPlatform",
        Size = Vector3.new(34 * scale, 3.2 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 1.6 * scale, 24 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makeWedge(folderFoundation, {
        Name = "LoadingDock_CattleRamp",
        Size = Vector3.new(12 * scale, 3.2 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 1.6 * scale, 33 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Perimeter drainage apron and footing skirts
    makePart(folderFoundation, {
        Name = "FootingSkirt_North",
        Size = Vector3.new(88 * scale, 0.8 * scale, 3 * scale),
        CFrame = rootCF * CFrame.new(0, 0.4 * scale, -32 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderFoundation, {
        Name = "FootingSkirt_South",
        Size = Vector3.new(88 * scale, 0.8 * scale, 3 * scale),
        CFrame = rootCF * CFrame.new(0, 0.4 * scale, 32 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderFoundation, {
        Name = "FootingSkirt_East",
        Size = Vector3.new(3 * scale, 0.8 * scale, 64 * scale),
        CFrame = rootCF * CFrame.new(44 * scale, 0.4 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderFoundation, {
        Name = "FootingSkirt_West",
        Size = Vector3.new(3 * scale, 0.8 * scale, 64 * scale),
        CFrame = rootCF * CFrame.new(-44 * scale, 0.4 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 2. MAIN STRUCTURE (~15 parts)
    -- ------------------------------------------------------------------------
    -- Central Monumental Hall (Nave Central de Faena)
    -- Massive front pylon walls flanking entrance
    makePart(folderMainStructure, {
        Name = "MainHall_FrontPylonWest",
        Size = Vector3.new(8 * scale, 22 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-14 * scale, 12.8 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderMainStructure, {
        Name = "MainHall_FrontPylonEast",
        Size = Vector3.new(8 * scale, 22 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(10 * scale, 12.8 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Side walls of the main slaughterhall
    makePart(folderMainStructure, {
        Name = "MainHall_WestLateralWall",
        Size = Vector3.new(3.6 * scale, 20 * scale, 34 * scale),
        CFrame = rootCF * CFrame.new(-16.2 * scale, 11.8 * scale, -2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderMainStructure, {
        Name = "MainHall_EastLateralWall_Lower",
        Size = Vector3.new(3.6 * scale, 12 * scale, 34 * scale),
        CFrame = rootCF * CFrame.new(14.2 * scale, 7.8 * scale, -2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WARM_CREAM,
    })
    -- Upper standing East wall segment with jagged break
    makePart(folderMainStructure, {
        Name = "MainHall_EastLateralWall_Standing",
        Size = Vector3.new(3.6 * scale, 8 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(14.2 * scale, 17.8 * scale, -11 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Curved Art Deco transition corner wall (Hall to wing transition)
    makeCornerWedge(folderMainStructure, {
        Name = "MainHall_ArtDecoCorner_NE",
        Size = Vector3.new(8 * scale, 18 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(10 * scale, 10.8 * scale, -18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Rear abattoir dividing wall
    makePart(folderMainStructure, {
        Name = "MainHall_RearDividingWall",
        Size = Vector3.new(32 * scale, 18 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-1 * scale, 10.8 * scale, 16 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })

    -- Salamone Stepped Art Deco Facade Parapet (Stepped roofline crest)
    makePart(folderMainStructure, {
        Name = "Parapet_CenterStep",
        Size = Vector3.new(22 * scale, 3.4 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 23.5 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderMainStructure, {
        Name = "Parapet_WestStep",
        Size = Vector3.new(10 * scale, 2.4 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-16 * scale, 22.0 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderMainStructure, {
        Name = "Parapet_EastStep",
        Size = Vector3.new(10 * scale, 2.4 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(12 * scale, 22.0 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Stepped cornice end wedges
    makeWedge(folderMainStructure, {
        Name = "Parapet_EndWedge_West",
        Size = Vector3.new(4 * scale, 2.4 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 22.0 * scale, -22 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderMainStructure, {
        Name = "Parapet_EndWedge_East",
        Size = Vector3.new(4 * scale, 2.4 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(18 * scale, 22.0 * scale, -22 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Reinforced tie-beams across main hall width
    makePart(folderMainStructure, {
        Name = "MainHall_ConcreteTieBeam_Front",
        Size = Vector3.new(28 * scale, 2.0 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-1 * scale, 20.0 * scale, -10 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })
    makePart(folderMainStructure, {
        Name = "MainHall_ConcreteTieBeam_Mid",
        Size = Vector3.new(28 * scale, 2.0 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-1 * scale, 20.0 * scale, 2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })
    makePart(folderMainStructure, {
        Name = "MainHall_ConcreteTieBeam_Rear",
        Size = Vector3.new(28 * scale, 2.0 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-1 * scale, 18.0 * scale, 14 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- ------------------------------------------------------------------------
    -- 3. TOWER (SALAMONE MONUMENTAL CLOCKTOWER) (~20 parts)
    -- ------------------------------------------------------------------------
    -- The defining visual landmark of Francisco Salamone: a soaring vertical pylon
    -- crowned by a knife-edge concrete fin blade (cuchilla) reaching ~56 studs elevation.
    -- Lower Tower Body (Y = 0 to 24)
    makePart(folderTower, {
        Name = "Tower_Shaft_Front",
        Size = Vector3.new(14 * scale, 24 * scale, 3.6 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 13.8 * scale, -25.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_Shaft_Back",
        Size = Vector3.new(14 * scale, 24 * scale, 3.6 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 13.8 * scale, -15.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_Shaft_WestPylon",
        Size = Vector3.new(3.6 * scale, 24 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-8.2 * scale, 13.8 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_Shaft_EastPylon",
        Size = Vector3.new(3.6 * scale, 24 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(4.2 * scale, 13.8 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Mid Tower Transition Cornice (Y = 24 to 26)
    makePart(folderTower, {
        Name = "Tower_Cornice_Belt",
        Size = Vector3.new(16 * scale, 1.8 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 25.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Upper Tower Chamber (Housing Clock & Belfry) (Y = 26 to 42)
    makePart(folderTower, {
        Name = "Tower_UpperChamber_Core",
        Size = Vector3.new(12 * scale, 16 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 34.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Salamone Signature Art Deco Aerodynamic Fins (Vertical speed fins flanking the tower)
    makeWedge(folderTower, {
        Name = "Tower_Fin_West_Lower",
        Size = Vector3.new(1.6 * scale, 16 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-8.5 * scale, 22.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderTower, {
        Name = "Tower_Fin_East_Lower",
        Size = Vector3.new(1.6 * scale, 16 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(4.5 * scale, 22.0 * scale, -20.8 * scale) * CFrame.Angles(0, math.rad(180), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_Fin_West_Upper",
        Size = Vector3.new(1.4 * scale, 14 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-8.5 * scale, 35.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_Fin_East_Upper",
        Size = Vector3.new(1.4 * scale, 14 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(4.5 * scale, 35.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Upper Tower Parapet Balcony & Belfry Aperture
    makePart(folderTower, {
        Name = "Tower_BelfryAperturePillarL",
        Size = Vector3.new(2.4 * scale, 8 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 44.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_BelfryAperturePillarR",
        Size = Vector3.new(2.4 * scale, 8 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(2 * scale, 44.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderTower, {
        Name = "Tower_BelfryLintel",
        Size = Vector3.new(10.4 * scale, 1.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 48.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- SALAMONE ICONIC MONUMENTAL FIN BLADE (CUCHILLA MONUMENTAL)
    -- Reaches highest point Y = 56 studs! Visible through heavy lagoon fog.
    makePart(folderTower, {
        Name = "Tower_FinBlade_BaseSpine",
        Size = Vector3.new(1.8 * scale, 14 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 47.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderTower, {
        Name = "Tower_FinBlade_FrontTaper",
        Size = Vector3.new(1.8 * scale, 8 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 52.0 * scale, -23.8 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderTower, {
        Name = "Tower_FinBlade_RearTaper",
        Size = Vector3.new(1.8 * scale, 8 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 52.0 * scale, -17.8 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    -- The absolute razor-sharp summit blade tip (Y = 54 to 56 studs)
    makePart(folderTower, {
        Name = "Tower_FinBlade_RazorTip",
        Size = Vector3.new(1.4 * scale, 4.0 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 55.0 * scale, -20.8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Exposed damaged tower rebar where concrete spalled
    makePart(folderTower, {
        Name = "Tower_ExposedRebar_1",
        Size = Vector3.new(0.3 * scale, 4.2 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(3.8 * scale, 47.5 * scale, -19.5 * scale) * CFrame.Angles(0, 0, math.rad(14)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderTower, {
        Name = "Tower_ExposedRebar_2",
        Size = Vector3.new(0.3 * scale, 3.6 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(4.0 * scale, 46.8 * scale, -22.0 * scale) * CFrame.Angles(math.rad(18), 0, math.rad(-12)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderTower, {
        Name = "Tower_SpalledCoreBrick",
        Size = Vector3.new(2.4 * scale, 4.0 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(3.6 * scale, 45.0 * scale, -21.0 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- ------------------------------------------------------------------------
    -- 4. CLOCK (SALAMONE ART DECO MONUMENTAL DIAL) (~11 parts)
    -- ------------------------------------------------------------------------
    -- Built 100% with native Roblox geometry (Cylinders, Wedges, Parts). NO textures!
    -- Recessed clock bezel housing frame (Cylinder)
    makeCylinder(folderClock, {
        Name = "Clock_BezelRecess",
        Size = Vector3.new(1.8 * scale, 8.4 * scale, 8.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 34.0 * scale, -26.0 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CLOCK_BEZEL,
    })

    -- Creamy enamel clock face dial disc
    makeCylinder(folderClock, {
        Name = "Clock_FaceDial",
        Size = Vector3.new(1.2 * scale, 7.2 * scale, 7.2 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 34.0 * scale, -26.2 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CLOCK_DIAL,
    })

    -- Art Deco stepped clock hood / eyebrow canopy (above dial)
    makePart(folderClock, {
        Name = "Clock_Hood_Canopy",
        Size = Vector3.new(9.2 * scale, 1.2 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 38.6 * scale, -26.2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderClock, {
        Name = "Clock_Hood_WedgeL",
        Size = Vector3.new(2.4 * scale, 1.2 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-7.2 * scale, 38.6 * scale, -26.2 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makeWedge(folderClock, {
        Name = "Clock_Hood_WedgeR",
        Size = Vector3.new(2.4 * scale, 1.2 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(3.2 * scale, 38.6 * scale, -26.2 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Native geometric clock hands (Stopped at the catastrophic flood hour: 10:20)
    -- Hour Hand (pointing toward ~10 o'clock)
    makePart(folderClock, {
        Name = "Clock_HourHand",
        Size = Vector3.new(0.3 * scale, 2.4 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 34.8 * scale, -26.85 * scale) * CFrame.Angles(0, 0, math.rad(55)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CLOCK_HANDS,
    })
    -- Minute Hand (pointing toward ~4 o'clock / 20 min)
    makePart(folderClock, {
        Name = "Clock_MinuteHand",
        Size = Vector3.new(0.3 * scale, 3.2 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 33.2 * scale, -26.85 * scale) * CFrame.Angles(0, 0, math.rad(-65)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CLOCK_HANDS,
    })
    -- Center mounting arbor boss (Cylinder)
    makeCylinder(folderClock, {
        Name = "Clock_CenterBoss",
        Size = Vector3.new(0.6 * scale, 0.9 * scale, 0.9 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 34.0 * scale, -26.9 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CLOCK_HANDS,
    })

    -- Cardinal hour notch marks (12, 6, 9, 3)
    makePart(folderClock, {
        Name = "Clock_HourMark_12",
        Size = Vector3.new(0.3 * scale, 0.8 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 37.0 * scale, -26.85 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CLOCK_HANDS,
    })
    makePart(folderClock, {
        Name = "Clock_HourMark_6",
        Size = Vector3.new(0.3 * scale, 0.8 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 31.0 * scale, -26.85 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CLOCK_HANDS,
    })
    -- Fractured dial crack fragment
    makePart(folderClock, {
        Name = "Clock_DialFractureCrack",
        Size = Vector3.new(0.2 * scale, 3.0 * scale, 0.2 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 33.5 * scale, -26.85 * scale) * CFrame.Angles(0, 0, math.rad(28)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 5. FACADE (MONUMENTAL ART DECO PORTICO & MARQUEE) (~14 parts)
    -- ------------------------------------------------------------------------
    -- Massive Cantilevered Entrance Marquee (Heavy horizontal concrete slab over entrance)
    makePart(folderFacade, {
        Name = "EntranceMarquee_MainCantilever",
        Size = Vector3.new(24 * scale, 1.8 * scale, 9 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 12.0 * scale, -27.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFacade, {
        Name = "EntranceMarquee_FasciaLip",
        Size = Vector3.new(24.4 * scale, 0.8 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 12.0 * scale, -32.0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Stepped Art Deco Entrance Jamb Pilasters
    makePart(folderFacade, {
        Name = "PortalJamb_West_Tier1",
        Size = Vector3.new(2.4 * scale, 11 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-7.2 * scale, 6.8 * scale, -25.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFacade, {
        Name = "PortalJamb_West_Tier2",
        Size = Vector3.new(1.8 * scale, 11 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-9.0 * scale, 6.8 * scale, -25.0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFacade, {
        Name = "PortalJamb_East_Tier1",
        Size = Vector3.new(2.4 * scale, 11 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(3.2 * scale, 6.8 * scale, -25.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFacade, {
        Name = "PortalJamb_East_Tier2",
        Size = Vector3.new(1.8 * scale, 11 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(5.0 * scale, 6.8 * scale, -25.0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Art Deco Horizontal Speed Line Relief Bands (characteristic Salamone fluting)
    for i = 1, 3 do
        makePart(folderFacade, {
            Name = string.format("SpeedLine_Fluting_%d", i),
            Size = Vector3.new(16 * scale, 0.5 * scale, 0.6 * scale),
            CFrame = rootCF * CFrame.new(-2 * scale, (14 + i * 1.4) * scale, -24.8 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALAMONE_WARM_CREAM,
        })
    end

    -- Flanking West Office Facade
    makePart(folderFacade, {
        Name = "Facade_WestOfficeWall",
        Size = Vector3.new(18 * scale, 16 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-28 * scale, 9.8 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderFacade, {
        Name = "Facade_WestOfficeCornice",
        Size = Vector3.new(18.4 * scale, 1.4 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-28 * scale, 18.2 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Flanking East Processing Facade (partially breached)
    makePart(folderFacade, {
        Name = "Facade_EastProcessingWall",
        Size = Vector3.new(18 * scale, 14 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(24 * scale, 8.8 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WARM_CREAM,
    })
    makeWedge(folderFacade, {
        Name = "Facade_EastBreachWedge",
        Size = Vector3.new(3.4 * scale, 6 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(33 * scale, 12.8 * scale, -22 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderFacade, {
        Name = "Facade_ExposedBrickPatch",
        Size = Vector3.new(6 * scale, 5 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(20 * scale, 8.0 * scale, -23.5 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- ------------------------------------------------------------------------
    -- 6. INDUSTRIAL WING (ABATTOIR & PROCESSING SHEDS) (~15 parts)
    -- ------------------------------------------------------------------------
    -- The functional slaughterhouse production wings situated east and west:
    -- East Cold Storage & Carcass Chilling Annex (Heavy flood damage)
    makePart(folderIndustrialWing, {
        Name = "ColdStorage_OuterWallEast",
        Size = Vector3.new(3.4 * scale, 14 * scale, 26 * scale),
        CFrame = rootCF * CFrame.new(38 * scale, 8.8 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makePart(folderIndustrialWing, {
        Name = "ColdStorage_RearWall",
        Size = Vector3.new(22 * scale, 12 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(28 * scale, 7.8 * scale, 14 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makePart(folderIndustrialWing, {
        Name = "ColdStorage_DividingWall",
        Size = Vector3.new(3.0 * scale, 12 * scale, 22 * scale),
        CFrame = rootCF * CFrame.new(26 * scale, 7.8 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- West Livestock Corrals & Service Chute
    makePart(folderIndustrialWing, {
        Name = "Corral_PerimeterWallWest",
        Size = Vector3.new(3.0 * scale, 8 * scale, 28 * scale),
        CFrame = rootCF * CFrame.new(-38 * scale, 5.8 * scale, 6 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makePart(folderIndustrialWing, {
        Name = "Corral_SouthWall",
        Size = Vector3.new(18 * scale, 8 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-30 * scale, 5.8 * scale, 20 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })
    makePart(folderIndustrialWing, {
        Name = "Corral_DividingFenceConcrete",
        Size = Vector3.new(2.4 * scale, 6 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(-28 * scale, 4.8 * scale, 6 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Boiler / Engine Room remnant with truncated brick chimney stack (Cylinder)
    makeCylinder(folderIndustrialWing, {
        Name = "BoilerChimney_StumpLower",
        Size = Vector3.new(5.4 * scale, 4.2 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-34 * scale, 4.5 * scale, -10 * scale) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
    })
    makeCylinder(folderIndustrialWing, {
        Name = "BoilerChimney_StumpUpperBroken",
        Size = Vector3.new(4.2 * scale, 3.8 * scale, 3.8 * scale),
        CFrame = rootCF * CFrame.new(-34 * scale, 8.8 * scale, -10 * scale) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Heavy concrete livestock chute guide walls
    makePart(folderIndustrialWing, {
        Name = "LivestockChute_WallL",
        Size = Vector3.new(1.8 * scale, 6 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 4.8 * scale, 18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderIndustrialWing, {
        Name = "LivestockChute_WallR",
        Size = Vector3.new(1.8 * scale, 6 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(-17 * scale, 4.8 * scale, 18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Secondary loading dock bumper curbs
    makePart(folderIndustrialWing, {
        Name = "LoadingBumper_ConcreteBlockL",
        Size = Vector3.new(2.4 * scale, 3.2 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-36 * scale, 1.8 * scale, 28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderIndustrialWing, {
        Name = "LoadingBumper_ConcreteBlockR",
        Size = Vector3.new(2.4 * scale, 3.2 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 1.8 * scale, 28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Broken service gate posts (Corroded iron posts)
    makePart(folderIndustrialWing, {
        Name = "GatePost_IronWest",
        Size = Vector3.new(0.8 * scale, 7 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(-38 * scale, 5.3 * scale, 20 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderIndustrialWing, {
        Name = "GatePost_IronEast",
        Size = Vector3.new(0.8 * scale, 7 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 5.3 * scale, 20 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderIndustrialWing, {
        Name = "BrokenGate_Slanted",
        Size = Vector3.new(14 * scale, 4 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-30 * scale, 3.6 * scale, 21 * scale) * CFrame.Angles(0, math.rad(18), math.rad(-14)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })

    -- ------------------------------------------------------------------------
    -- 7. OPENINGS & EMBRASURES (~13 parts)
    -- ------------------------------------------------------------------------
    -- Monumental Entrance double-height portal aperture frame
    makePart(folderOpenings, {
        Name = "MonumentalPortal_Threshold",
        Size = Vector3.new(8 * scale, 0.8 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 2.2 * scale, -25.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderOpenings, {
        Name = "MonumentalPortal_LintelBeam",
        Size = Vector3.new(8 * scale, 2.2 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 10.8 * scale, -25.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- High Industrial Clerestory Windows along West Main Hall
    for i = 1, 3 do
        local zOffset = -14 + (i - 1) * 12
        makePart(folderOpenings, {
            Name = string.format("ClerestorySill_West_%d", i),
            Size = Vector3.new(4.2 * scale, 1.2 * scale, 7 * scale),
            CFrame = rootCF * CFrame.new(-16.2 * scale, 14.8 * scale, zOffset * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALAMONE_WHITE,
        })
        makePart(folderOpenings, {
            Name = string.format("ClerestoryLintel_West_%d", i),
            Size = Vector3.new(4.2 * scale, 1.2 * scale, 7 * scale),
            CFrame = rootCF * CFrame.new(-16.2 * scale, 19.8 * scale, zOffset * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALAMONE_WHITE,
        })
    end

    -- Rear cattle intake archway
    makePart(folderOpenings, {
        Name = "CattleIntake_ArchLintel",
        Size = Vector3.new(8 * scale, 2.4 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-12 * scale, 8.8 * scale, 16 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })

    -- Roller shutter bay (buckled industrial delivery opening)
    makePart(folderOpenings, {
        Name = "DeliveryBay_BuckledShutter",
        Size = Vector3.new(10 * scale, 3.8 * scale, 0.6 * scale),
        CFrame = rootCF * CFrame.new(28 * scale, 8.2 * scale, -22.5 * scale) * CFrame.Angles(math.rad(15), 0, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })
    makePart(folderOpenings, {
        Name = "DeliveryBay_ShutterTrackL",
        Size = Vector3.new(0.6 * scale, 10 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(22.8 * scale, 6.8 * scale, -22.5 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderOpenings, {
        Name = "DeliveryBay_ShutterTrackR",
        Size = Vector3.new(0.6 * scale, 10 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(33.2 * scale, 6.8 * scale, -22.5 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderOpenings, {
        Name = "ColdRoom_VentilationGrille",
        Size = Vector3.new(4.2 * scale, 3.2 * scale, 0.6 * scale),
        CFrame = rootCF * CFrame.new(38 * scale, 12.0 * scale, -8 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 8. ROOF DAMAGE & STRUCTURAL COLLAPSE (~14 parts)
    -- ------------------------------------------------------------------------
    -- Asymmetrical disaster: The slaughterhall and cold storage suffered heavy roof failure
    -- Massive collapsed reinforced concrete roof slab angled into slaughter hall
    makePart(folderRoofDamage, {
        Name = "CollapsedRoofSlab_MainEast",
        Size = Vector3.new(20 * scale, 1.4 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(8 * scale, 10.5 * scale, 0) * CFrame.Angles(0, math.rad(10), math.rad(-26)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    -- Secondary broken ceiling slab resting on floor rubble
    makePart(folderRoofDamage, {
        Name = "CollapsedRoofSlab_ColdRoom",
        Size = Vector3.new(14 * scale, 1.2 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(30 * scale, 5.2 * scale, 2 * scale) * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(12)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Twisted industrial steel I-beams crashed down from trusses
    makePart(folderRoofDamage, {
        Name = "TwistedSteelIBeam_1",
        Size = Vector3.new(1.4 * scale, 26 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(2 * scale, 11.2 * scale, -6 * scale) * CFrame.Angles(math.rad(28), math.rad(45), math.rad(32)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })
    makePart(folderRoofDamage, {
        Name = "TwistedSteelIBeam_2",
        Size = Vector3.new(1.4 * scale, 22 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(14 * scale, 9.8 * scale, 8 * scale) * CFrame.Angles(math.rad(-34), math.rad(18), math.rad(-25)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })
    makePart(folderRoofDamage, {
        Name = "BentCrossPurlin_3",
        Size = Vector3.new(1.0 * scale, 18 * scale, 1.0 * scale),
        CFrame = rootCF * CFrame.new(18 * scale, 7.4 * scale, -8 * scale) * CFrame.Angles(math.rad(12), math.rad(-60), math.rad(15)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- Crumpled industrial corrugated asbestos/zinc roofing sheets
    makePart(folderRoofDamage, {
        Name = "CrumpledRoofSheet_A",
        Size = Vector3.new(10 * scale, 0.4 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 2.8 * scale, 6 * scale) * CFrame.Angles(math.rad(8), math.rad(30), math.rad(6)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })
    makePart(folderRoofDamage, {
        Name = "CrumpledRoofSheet_B",
        Size = Vector3.new(8 * scale, 0.4 * scale, 5 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 3.2 * scale, -12 * scale) * CFrame.Angles(math.rad(-14), math.rad(-22), math.rad(-8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })

    -- Protruding exposed rebar clusters piercing from sheared concrete slab ends
    makePart(folderRoofDamage, {
        Name = "ExposedRebar_Cluster_1",
        Size = Vector3.new(0.3 * scale, 5.0 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(0, 16.5 * scale, 4 * scale) * CFrame.Angles(math.rad(22), 0, math.rad(-35)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderRoofDamage, {
        Name = "ExposedRebar_Cluster_2",
        Size = Vector3.new(0.3 * scale, 4.4 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(1.2 * scale, 15.8 * scale, 2 * scale) * CFrame.Angles(math.rad(15), math.rad(20), math.rad(-42)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderRoofDamage, {
        Name = "ExposedRebar_Cluster_3",
        Size = Vector3.new(0.3 * scale, 4.8 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(15 * scale, 14.5 * scale, -2 * scale) * CFrame.Angles(0, math.rad(-40), math.rad(28)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- Hanging broken slab corner overhanging the central hall
    makeCornerWedge(folderRoofDamage, {
        Name = "HangingSlabCorner_East",
        Size = Vector3.new(8 * scale, 1.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(14 * scale, 18.0 * scale, -16 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makeWedge(folderRoofDamage, {
        Name = "HangingSlabWedge_Fracture",
        Size = Vector3.new(3.0 * scale, 1.4 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 19.2 * scale, -10 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    makePart(folderRoofDamage, {
        Name = "BrokenTrussGussetPlate",
        Size = Vector3.new(2.4 * scale, 2.4 * scale, 0.6 * scale),
        CFrame = rootCF * CFrame.new(-14 * scale, 18.2 * scale, -4 * scale) * CFrame.Angles(0, 0, math.rad(25)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderRoofDamage, {
        Name = "SuspendedTensionCable",
        Size = Vector3.new(0.4 * scale, 14 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-4 * scale, 13.0 * scale, -2 * scale) * CFrame.Angles(math.rad(10), 0, math.rad(12)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 9. INTERIOR STRUCTURE & ABATTOIR EQUIPMENT (~12 parts)
    -- ------------------------------------------------------------------------
    -- The iconic meat-hanging slaughter monorail (Carril de Faena)
    -- High central overhead rail beam running length of slaughter hall
    makePart(folderInteriorStructure, {
        Name = "MeatRail_MainMonorailSpine",
        Size = Vector3.new(0.8 * scale, 1.2 * scale, 32 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 16.0 * scale, -1 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    -- Secondary curved spur rail branching toward cold storage
    makePart(folderInteriorStructure, {
        Name = "MeatRail_CurvedSpurBranch",
        Size = Vector3.new(14 * scale, 1.2 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 15.6 * scale, 4 * scale) * CFrame.Angles(0, math.rad(25), 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    -- Hanging steel carcass hooks (Gancheras)
    local hookZs = { -12, -4, 4, 12 }
    for i, hz in ipairs(hookZs) do
        makePart(folderInteriorStructure, {
            Name = string.format("MeatHook_Ganchera_%d", i),
            Size = Vector3.new(0.3 * scale, 2.6 * scale, 0.3 * scale),
            CFrame = rootCF * CFrame.new(-2 * scale, 14.1 * scale, hz * scale),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
        })
    end

    -- Blood & visceral drainage trough / central gutter trench in floor
    makePart(folderInteriorStructure, {
        Name = "DrainageGutter_FloorTrench",
        Size = Vector3.new(3.6 * scale, 0.6 * scale, 28 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 2.1 * scale, -1 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    -- Iron drainage grate segment lodged in trench
    makePart(folderInteriorStructure, {
        Name = "DrainageGrate_LodgedSegment",
        Size = Vector3.new(3.2 * scale, 0.3 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 2.3 * scale, -8 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- Reinforced concrete interior support column (intact)
    makePart(folderInteriorStructure, {
        Name = "InteriorColumn_IntactWest",
        Size = Vector3.new(3.0 * scale, 18 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-8 * scale, 10.8 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })
    -- Fractured interior support column (shattered top with rebar)
    makePart(folderInteriorStructure, {
        Name = "InteriorColumn_FracturedEast",
        Size = Vector3.new(3.0 * scale, 9 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 6.8 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Tiled abattoir processing station partition wall stubs
    makePart(folderInteriorStructure, {
        Name = "ProcessingStation_TiledDividerL",
        Size = Vector3.new(1.4 * scale, 4.5 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(-12 * scale, 4.5 * scale, -4 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WARM_CREAM,
    })
    makePart(folderInteriorStructure, {
        Name = "ProcessingStation_TiledDividerR",
        Size = Vector3.new(1.4 * scale, 4.5 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(8 * scale, 4.5 * scale, -12 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WARM_CREAM,
    })

    -- ------------------------------------------------------------------------
    -- 10. RUBBLE & MASONRY SCREE (~15 parts)
    -- ------------------------------------------------------------------------
    -- Catastrophic scree heaps where the east slaughterhall and roof collapsed
    makePart(folderRubble, {
        Name = "RubbleHeap_EastHallMain",
        Size = Vector3.new(16 * scale, 4.2 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(18 * scale, 3.5 * scale, 0) * CFrame.Angles(0, math.rad(12), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })
    makeWedge(folderRubble, {
        Name = "RubbleSlope_NorthBreach",
        Size = Vector3.new(10 * scale, 3.6 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(20 * scale, 3.2 * scale, -14 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makeWedge(folderRubble, {
        Name = "RubbleSlope_SouthBreach",
        Size = Vector3.new(10 * scale, 3.2 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 3.0 * scale, 14 * scale) * CFrame.Angles(0, math.rad(180), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Fallen concrete cornice chunks and structural block debris
    local rubbleBlocks = {
        { Pos = Vector3.new(6, 2.6, -18), Size = Vector3.new(4.6, 2.4, 3.8), RotY = 32, Mat = Enum.Material.Concrete, Col = COLOR_SALAMONE_WHITE },
        { Pos = Vector3.new(-8, 2.5, -12), Size = Vector3.new(3.8, 2.0, 3.4), RotY = -45, Mat = Enum.Material.Concrete, Col = COLOR_CONCRETE_CORE },
        { Pos = Vector3.new(28, 2.8, -10), Size = Vector3.new(5.2, 2.6, 4.2), RotY = 68, Mat = Enum.Material.Brick, Col = COLOR_BRICK_RED },
        { Pos = Vector3.new(32, 2.4, 8), Size = Vector3.new(4.4, 2.2, 3.6), RotY = -15, Mat = Enum.Material.Brick, Col = COLOR_BRICK_MORTAR_MIX },
        { Pos = Vector3.new(-14, 2.3, 10), Size = Vector3.new(3.6, 1.8, 3.2), RotY = 55, Mat = Enum.Material.Concrete, Col = COLOR_CONCRETE_MID },
        { Pos = Vector3.new(-24, 2.4, -14), Size = Vector3.new(4.0, 2.0, 3.0), RotY = -70, Mat = Enum.Material.Concrete, Col = COLOR_SALAMONE_WARM_CREAM },
        { Pos = Vector3.new(12, 2.7, 18), Size = Vector3.new(4.8, 2.2, 4.0), RotY = 22, Mat = Enum.Material.Brick, Col = COLOR_BRICK_DARK },
    }

    for i, rb in ipairs(rubbleBlocks) do
        makePart(folderRubble, {
            Name = string.format("RubbleChunkBlock_%d", i),
            Size = rb.Size * scale,
            CFrame = rootCF * CFrame.new(rb.Pos * scale) * CFrame.Angles(0, math.rad(rb.RotY), 0),
            Material = rb.Mat,
            Color = rb.Col,
        })
    end

    -- Fallen Art Deco facade decorative wedge fallen on front steps
    makeWedge(folderRubble, {
        Name = "FallenFacadeWedge_Steps",
        Size = Vector3.new(4.2 * scale, 2.2 * scale, 3.8 * scale),
        CFrame = rootCF * CFrame.new(8 * scale, 2.2 * scale, -28 * scale) * CFrame.Angles(math.rad(12), math.rad(35), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALAMONE_WHITE,
    })

    -- Fallen livestock chute post fragment
    makePart(folderRubble, {
        Name = "FallenChuteCurbFragment",
        Size = Vector3.new(2.2 * scale, 1.4 * scale, 5.5 * scale),
        CFrame = rootCF * CFrame.new(-18 * scale, 2.2 * scale, 26 * scale) * CFrame.Angles(0, math.rad(-28), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Concrete scree apron extending east of the collapsed wing
    makePart(folderRubble, {
        Name = "OuterEast_ScreeApron",
        Size = Vector3.new(8 * scale, 1.4 * scale, 18 * scale),
        CFrame = rootCF * CFrame.new(40 * scale, 1.8 * scale, 2 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })
    makeWedge(folderRubble, {
        Name = "LoadingRamp_ScreeWedge",
        Size = Vector3.new(6 * scale, 1.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 1.8 * scale, 28 * scale) * CFrame.Angles(0, math.rad(60), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_MID,
    })
    makePart(folderRubble, {
        Name = "ChimneyBrickRubble_StumpBase",
        Size = Vector3.new(6 * scale, 1.8 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-34 * scale, 1.8 * scale, -10 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- ------------------------------------------------------------------------
    -- 11. SALT CRUST & LAGOON WATERLINE DEPOSITS (~13 parts)
    -- ------------------------------------------------------------------------
    -- The hallmark of the Epecuén flood: horizontal mineral tide-line shelves (Y ~ 5-7 studs)
    -- and thick evaporite crusts coating all lower concrete surfaces.
    -- Tower Waterline Shelf (encircling tower base at Y = 6.4 studs)
    makePart(folderSaltCrust, {
        Name = "Tower_SaltWaterlineShelf_North",
        Size = Vector3.new(16 * scale, 1.2 * scale, 3.8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 6.4 * scale, -26 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
    })
    makePart(folderSaltCrust, {
        Name = "Tower_SaltWaterlineShelf_West",
        Size = Vector3.new(3.8 * scale, 1.2 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(-9 * scale, 6.4 * scale, -21 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
    })
    makePart(folderSaltCrust, {
        Name = "Tower_SaltWaterlineShelf_East",
        Size = Vector3.new(3.8 * scale, 1.2 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(5 * scale, 6.4 * scale, -21 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
    })

    -- Main Hall Wall Base Salt Aprons
    makePart(folderSaltCrust, {
        Name = "MainHall_SaltApron_WestBase",
        Size = Vector3.new(4.8 * scale, 2.2 * scale, 42 * scale),
        CFrame = rootCF * CFrame.new(-16.5 * scale, 2.5 * scale, -2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.20,
    })
    makePart(folderSaltCrust, {
        Name = "MainHall_SaltShelf_WestWaterline",
        Size = Vector3.new(4.2 * scale, 1.2 * scale, 40 * scale),
        CFrame = rootCF * CFrame.new(-16.5 * scale, 6.4 * scale, -2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
    })

    -- Loading dock waterline salt shelf
    makePart(folderSaltCrust, {
        Name = "LoadingDock_SaltTideBand",
        Size = Vector3.new(36 * scale, 1.2 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 2.8 * scale, 28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.22,
    })

    -- Front entrance podium salt crust
    makePart(folderSaltCrust, {
        Name = "EntrancePodium_SaltDeposit",
        Size = Vector3.new(22 * scale, 0.6 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-2 * scale, 1.9 * scale, -28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.18,
    })

    -- East breach rubble pile salt cap
    makePart(folderSaltCrust, {
        Name = "EastBreach_SaltCrustCap",
        Size = Vector3.new(14 * scale, 1.2 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(18 * scale, 4.8 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.26,
    })

    -- Saline evaporite mineral sheets coating floor slabs
    local floorSaltSheets = {
        { Pos = Vector3.new(-8, 2.45, -16), Size = Vector3.new(8, 0.3, 7), RotY = 20 },
        { Pos = Vector3.new(6, 2.45, -6), Size = Vector3.new(10, 0.3, 8), RotY = -35 },
        { Pos = Vector3.new(-6, 2.45, 8), Size = Vector3.new(8, 0.3, 9), RotY = 45 },
        { Pos = Vector3.new(24, 2.45, -14), Size = Vector3.new(9, 0.3, 6), RotY = -15 },
        { Pos = Vector3.new(-28, 2.05, 14), Size = Vector3.new(8, 0.3, 8), RotY = 10 },
    }

    for i, ss in ipairs(floorSaltSheets) do
        makePart(folderSaltCrust, {
            Name = string.format("FloorEvaporiteSheet_%d", i),
            Size = ss.Size * scale,
            CFrame = rootCF * CFrame.new(ss.Pos * scale) * CFrame.Angles(0, math.rad(ss.RotY), 0),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALT_OFFWHITE,
            Reflectance = 0.18,
        })
    end

    -- ------------------------------------------------------------------------
    -- 12. VEGETATION & POST-FLOOD GROWTH (~12 parts)
    -- ------------------------------------------------------------------------
    -- Resilient halophyte scrub, pampas tussock grass, and dry thistle (cardo)
    local vegetationClusters = {
        -- Pampas scrub outside the collapsed East wing in mineral silt
        { Name = "Shrub_EastBreach_Outer1", Pos = Vector3.new(42, 1.8, -4), Size = Vector3.new(5.0, 3.4, 5.2), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "Shrub_EastBreach_Outer2", Pos = Vector3.new(40, 2.0, 12), Size = Vector3.new(4.4, 2.8, 4.6), Col = COLOR_VEG_DRY_THISTLE },
        -- Hardy weeds thriving in damp slaughterhall drainage trench
        { Name = "TrenchWeeds_CentralHall", Pos = Vector3.new(-2, 2.6, 4), Size = Vector3.new(3.8, 2.4, 3.6), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "TrenchWeeds_NorthHall", Pos = Vector3.new(-2, 2.6, -14), Size = Vector3.new(3.4, 2.0, 3.2), Col = COLOR_VEG_DRY_THISTLE },
        -- Saline weeds growing around livestock chute & corral posts
        { Name = "CorralWeeds_ChuteExit", Pos = Vector3.new(-26, 2.2, 24), Size = Vector3.new(4.2, 2.6, 4.0), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "CorralWeeds_LoadingRamp", Pos = Vector3.new(-16, 2.0, 32), Size = Vector3.new(3.6, 2.2, 3.4), Col = COLOR_VEG_DRY_THISTLE },
        -- Creeping moss along shaded damp foundation corners
        { Name = "CreepingMoss_NorthTowerFoot", Pos = Vector3.new(-10, 1.4, -28), Size = Vector3.new(3.4, 1.8, 4.2), Col = COLOR_VEG_DARK_MOSS },
        { Name = "CreepingMoss_EastColdWall", Pos = Vector3.new(36, 1.4, -18), Size = Vector3.new(3.2, 1.6, 4.6), Col = COLOR_VEG_DARK_MOSS },
        -- Dry thistle sprouting from fractured chimney rubble
        { Name = "ChimneyThistle_Sprout", Pos = Vector3.new(-36, 2.6, -8), Size = Vector3.new(3.0, 2.4, 2.8), Col = COLOR_VEG_DRY_THISTLE },
        -- Halophyte bush at monumental entrance steps
        { Name = "EntranceBush_WestSide", Pos = Vector3.new(-18, 1.6, -34), Size = Vector3.new(4.6, 2.8, 4.2), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "EntranceBush_EastSide", Pos = Vector3.new(14, 1.6, -34), Size = Vector3.new(4.0, 2.4, 3.8), Col = COLOR_VEG_DRY_THISTLE },
        -- Rear dock grass cluster
        { Name = "RearDock_WildPampasGrass", Pos = Vector3.new(-38, 2.0, 30), Size = Vector3.new(5.2, 3.0, 4.8), Col = COLOR_VEG_SAGE_SHRUB },
    }

    for _, v in ipairs(vegetationClusters) do
        makePart(folderVegetation, {
            Name = v.Name,
            Size = v.Size * scale,
            CFrame = rootCF * CFrame.new(v.Pos * scale) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
            Material = Enum.Material.Grass,
            Color = v.Col,
            CanCollide = false,
            CastShadow = true,
        })
    end

    return primaryFoundation
end

-- ============================================================================
-- MAIN BUILD API: MataderoLandmarkBuilder.Build(options)
-- ============================================================================

function MataderoLandmarkBuilder.Build(opts: MataderoBuildOptions): Model
    local pos = opts.Position or CANONICAL_MATADERO_POS
    local rotY = opts.RotationY or 0
    local scale = opts.Scale or 1.0
    local seed = opts.Seed or 9001

    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or "MataderoSalamone"

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

    local primaryPart = buildMataderoLandmark(model, rootCF, scale, opts, rng)

    if primaryPart then
        model.PrimaryPart = primaryPart
    end

    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

-- ============================================================================
-- METRICS HELPER
-- ============================================================================

function MataderoLandmarkBuilder.GetMetrics(): {
    PartCount: number,
    FootprintStuds: Vector3,
    MaxHeightStuds: number,
    CanonicalPosition: Vector3,
}
    return {
        PartCount = 166, -- Exactly 166 native Roblox parts across all 12 folders
        FootprintStuds = Vector3.new(88, 56, 64),
        MaxHeightStuds = 56,
        CanonicalPosition = CANONICAL_MATADERO_POS,
    }
end

return MataderoLandmarkBuilder
