--!strict
--[[
    PlazaCentralLandmarkBuilder.luau
    Location: ServerScriptService/PlazaCentralLandmarkBuilder.luau

    Procedural Landmark Architecture Builder for the Ruined Central Plaza of Villa Epecuén.
    Visual Reference: Plaza Central / Cartel "Ud. Está Aquí" (Villa Epecuén, Adolfo Alsina, Argentina).

    Canonical Map Reference:
      - Canonical Center: Position = Vector3.new(65, 11, -140) (ZONE_CENTRAL_PLAZA)
      - Canonical Zone Bounds: X = -30 to 160, Z = -280 to 0 (Elevation Y = 9 to 14 studs)
      - Footprint: ~110 x 120 studs core civic square
      - Context: Flanked by Calle Mitre to the North, Calle Sarmiento to the South,
                 Avenida de Mayo to the East, and Calle Talcahuano to the West.

    Historical & Visual Profile:
      The Central Plaza was the beating civic and social heart of Villa Epecuén during its golden
      era as a premier saltwater thermal spa resort. Tourists congregated here around decorative
      flower beds, octagonal stone fountains, ornate cast-iron street lamps, and shaded wooden
      benches after bathing in the hyper-saline lagoon.

      Standing prominently in the square was the famous tourist orientation signboard ("Cartel Ud. Está Aquí"),
      which became one of the most haunting and iconic post-flood photo motifs of Epecuén after the waters
      receded decades later—a lonely concrete plinth with its faded yellow map standing starkly amid
      sunken paving, dried fountain basins, dead tamarisks, and thick white mineral crusts.

    Design Principles:
      - Open Civic Space: NOT a continuous ruin pile; maintains the clear, walkable layout of a town square.
      - 6 Distinct Visual Layers:
          1. Central open civic promenade & walkways
          2. Dried/damaged decorative octagonal fountain & civic orientation monument ("Ud. Está Aquí")
          3. Low perimeter retaining stone curbs and entrance bollards
          4. Damaged, heaved, and sunken cobblestone paving
          5. Environmental street furniture (broken benches, unlit rusted vintage lamp-posts, debris)
          6. Salt evaporite crusts and hardy pampas halophyte scrub
      - Generous Navigation Clearance: Over 25 studs of open walkable room across the center for player
        movement, vehicle maneuvering, and atmospheric exploration events.
      - Budget: 70–120 parts (~90 native parts total).

    Technical Constraints:
      - 100% native Roblox geometry: Part (Block, Cylinder), WedgePart, CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, sounds, or plugins.
      - ZERO unrequested lighting: Lamp posts are pure weathered wrought-iron geometry WITHOUT functional lights.
      - ZERO automatic instantiation into Workspace on module require/load.
      - Fully deterministic through Random.new(seed).
      - Organized into 10 designated sub-folders:
          Foundation, Paving, Fountain, Monument, Perimeter, StreetFurniture, Damage, Rubble, SaltCrust, Vegetation.
--]]

local PlazaCentralLandmarkBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type PlazaBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    Parent: Instance?,
    DamageLevel: number?, -- 0.0 to 1.0 (default 0.80)
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
-- COLOR & MATERIAL PALETTE (Villa Epecuén Plaza Ruins)
-- ============================================================================

-- Pavements, Terraces & Curb Concrete
local COLOR_PAVING_WEATHERED     = Color3.fromRGB(152, 148, 140) -- Weathered saline civic pavers
local COLOR_PAVING_SUNKEN        = Color3.fromRGB(132, 128, 122) -- Damp, mud-stained sunken stone
local COLOR_TERRACE_BASE         = Color3.fromRGB(140, 136, 128) -- Plaza foundation podium
local COLOR_CURB_CONCRETE        = Color3.fromRGB(164, 160, 152) -- Perimeter raised curb stone
local COLOR_SIDEWALK_SLAB        = Color3.fromRGB(158, 154, 146) -- Perimeter sidewalk flagstones

-- Fountain & Decorative Masonry
local COLOR_FOUNTAIN_STONE       = Color3.fromRGB(168, 164, 156) -- Bleached carved fountain stone
local COLOR_FOUNTAIN_BASIN       = Color3.fromRGB(128, 124, 116) -- Dried silt basin interior
local COLOR_FOUNTAIN_PIPE        = Color3.fromRGB(72, 48, 38)    -- Corroded iron fountain spout

-- Monument "Ud. Está Aquí" (Orientation Signboard)
local COLOR_MONUMENT_PLINTH      = Color3.fromRGB(156, 152, 144) -- Concrete signboard plinth
local COLOR_MONUMENT_YELLOW      = Color3.fromRGB(202, 170, 78)  -- Faded historic tourist yellow board
local COLOR_MONUMENT_FRAME       = Color3.fromRGB(118, 114, 108) -- Cast concrete border frame
local COLOR_MONUMENT_PLAQUE      = Color3.fromRGB(94, 78, 56)    -- Weathered bronze dedication plate

-- Street Furniture & Metals
local COLOR_IRON_RUST_DARK       = Color3.fromRGB(58, 44, 38)    -- Heavy oxidized wrought iron
local COLOR_IRON_RUST_LIGHT      = Color3.fromRGB(114, 62, 42)   -- Flaking orange iron rust
local COLOR_BENCH_WOOD           = Color3.fromRGB(94, 84, 72)    -- Rotten weathered timber slats
local COLOR_BENCH_CONCRETE       = Color3.fromRGB(148, 144, 138) -- Cast concrete bench stanchions

-- Mineral Salt Crusts & Evaporite Residues
local COLOR_SALT_PURE_WHITE      = Color3.fromRGB(250, 250, 246) -- Thick calcified mineral deposit
local COLOR_SALT_OFFWHITE        = Color3.fromRGB(236, 238, 230) -- Salt crust sheet on ground
local COLOR_SALT_TIDE_SHELF      = Color3.fromRGB(220, 222, 214) -- Waterline salt residue

-- Pampas Vegetation (Halophytes, Cardo, Tamarisco)
local COLOR_VEG_SAGE_SCRUB       = Color3.fromRGB(112, 126, 96)  -- Argentine saltbush / halophyte
local COLOR_VEG_DRY_THISTLE      = Color3.fromRGB(144, 140, 100) -- Bleached pampas thistle weeds
local COLOR_VEG_DAMP_MOSS        = Color3.fromRGB(82, 94, 70)    -- Shadowed saline moss in cracks

-- Canonical Defaults
local CANONICAL_PLAZA_POS = Vector3.new(65, 11, -140)

-- ============================================================================
-- PRIMITIVE CONSTRUCTORS (100% NATIVE ROBLOX GEOMETRY, ANCHORED)
-- ============================================================================

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.Concrete
    p.Color = cfg.Color or COLOR_PAVING_WEATHERED
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
    w.Color = cfg.Color or COLOR_PAVING_WEATHERED
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
    cw.Color = cfg.Color or COLOR_PAVING_WEATHERED
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
    c.Color = cfg.Color or COLOR_PAVING_WEATHERED
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
-- MAIN BUILD FUNCTION
-- ============================================================================

function PlazaCentralLandmarkBuilder.Build(options: PlazaBuildOptions?): Model
    local opts = options or {}
    local basePos = opts.Position or CANONICAL_PLAZA_POS
    local rotY = opts.RotationY or 0
    local damageLevel = math.clamp(opts.DamageLevel or 0.80, 0, 1)
    local saltLevel = math.clamp(opts.SaltLevel or 0.85, 0, 1)
    local seed = opts.Seed or 4242
    local modelName = opts.Name or "PlazaCentral_Ruins"

    local rng = Random.new(seed)

    -- Root Model
    local model = Instance.new("Model")
    model.Name = modelName

    -- Model Transform CFrame
    local rootCF = CFrame.new(basePos) * CFrame.Angles(0, math.rad(rotY), 0)

    local function toWorld(localCF: CFrame): CFrame
        return rootCF * localCF
    end

    -- Create 10 Functional Folders
    local folderFoundation      = getOrCreateFolder(model, "Foundation")
    local folderPaving          = getOrCreateFolder(model, "Paving")
    local folderFountain        = getOrCreateFolder(model, "Fountain")
    local folderMonument        = getOrCreateFolder(model, "Monument")
    local folderPerimeter       = getOrCreateFolder(model, "Perimeter")
    local folderStreetFurniture = getOrCreateFolder(model, "StreetFurniture")
    local folderDamage          = getOrCreateFolder(model, "Damage")
    local folderRubble          = getOrCreateFolder(model, "Rubble")
    local folderSaltCrust       = getOrCreateFolder(model, "SaltCrust")
    local folderVegetation      = getOrCreateFolder(model, "Vegetation")

    -- ------------------------------------------------------------------------
    -- 1. FOUNDATION (8 parts)
    -- Ground sub-base plinth and perimeter sidewalk foundation slabs
    -- ------------------------------------------------------------------------
    -- Main plaza sub-plinth
    local primaryPart = makePart(folderFoundation, {
        Name = "PlazaBasePlinth",
        Size = Vector3.new(104, 1.4, 116),
        CFrame = toWorld(CFrame.new(0, -0.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_TERRACE_BASE,
    })
    model.PrimaryPart = primaryPart

    -- Elevated central civic terrace tier
    makePart(folderFoundation, {
        Name = "CentralTerracePodium",
        Size = Vector3.new(68, 0.6, 72),
        CFrame = toWorld(CFrame.new(0, 0.3, -4)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- North sidewalk foundation strip (Calle Mitre frontage)
    makePart(folderFoundation, {
        Name = "NorthSidewalkBase",
        Size = Vector3.new(108, 0.8, 12),
        CFrame = toWorld(CFrame.new(0, 0.2, -56)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SIDEWALK_SLAB,
    })

    -- South sidewalk foundation strip (Calle Sarmiento frontage)
    makePart(folderFoundation, {
        Name = "SouthSidewalkBase",
        Size = Vector3.new(108, 0.8, 12),
        CFrame = toWorld(CFrame.new(0, 0.2, 56)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SIDEWALK_SLAB,
    })

    -- West sidewalk foundation strip (Calle Talcahuano frontage)
    makePart(folderFoundation, {
        Name = "WestSidewalkBase",
        Size = Vector3.new(12, 0.8, 100),
        CFrame = toWorld(CFrame.new(-50, 0.2, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SIDEWALK_SLAB,
    })

    -- East sidewalk foundation strip (Avenida de Mayo frontage)
    makePart(folderFoundation, {
        Name = "EastSidewalkBase",
        Size = Vector3.new(12, 0.8, 100),
        CFrame = toWorld(CFrame.new(50, 0.2, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_SIDEWALK_SLAB,
    })

    -- Northwest radial approach base strip
    makePart(folderFoundation, {
        Name = "RadialWalkwayBase_NW",
        Size = Vector3.new(18, 0.4, 28),
        CFrame = toWorld(CFrame.new(-32, 0.4, -34) * CFrame.Angles(0, math.rad(45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Southwest radial approach base strip
    makePart(folderFoundation, {
        Name = "RadialWalkwayBase_SW",
        Size = Vector3.new(18, 0.4, 28),
        CFrame = toWorld(CFrame.new(-32, 0.4, 30) * CFrame.Angles(0, math.rad(-45), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- ------------------------------------------------------------------------
    -- 2. PAVING (10 parts)
    -- Worn cobblestone and flagstone surface quadrants, central circle, promenades
    -- ------------------------------------------------------------------------
    -- Central fountain flagstone circle apron (Cylinder)
    makeCylinder(folderPaving, {
        Name = "CentralPavingApronDisc",
        Size = Vector3.new(0.4, 34, 34), -- X is cylinder height in Roblox native cylinders
        CFrame = toWorld(CFrame.new(0, 0.7, 10) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- North-South central promenade spine (walkway connecting Mitre to Sarmiento)
    makePart(folderPaving, {
        Name = "CentralPromenadeSpine",
        Size = Vector3.new(16, 0.35, 96),
        CFrame = toWorld(CFrame.new(0, 0.7, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- East-West cross promenade walkway
    makePart(folderPaving, {
        Name = "CrossPromenadeWalkway",
        Size = Vector3.new(88, 0.35, 14),
        CFrame = toWorld(CFrame.new(0, 0.7, -4)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Northwest terrace quadrant (worn cobblestones)
    makePart(folderPaving, {
        Name = "PavingQuadrant_NW",
        Size = Vector3.new(24, 0.3, 26),
        CFrame = toWorld(CFrame.new(-22, 0.65, -22)),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Northeast terrace quadrant
    makePart(folderPaving, {
        Name = "PavingQuadrant_NE",
        Size = Vector3.new(24, 0.3, 26),
        CFrame = toWorld(CFrame.new(22, 0.65, -22)),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Southwest terrace quadrant
    makePart(folderPaving, {
        Name = "PavingQuadrant_SW",
        Size = Vector3.new(24, 0.3, 26),
        CFrame = toWorld(CFrame.new(-22, 0.65, 20)),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Southeast terrace quadrant
    makePart(folderPaving, {
        Name = "PavingQuadrant_SE",
        Size = Vector3.new(24, 0.3, 26),
        CFrame = toWorld(CFrame.new(22, 0.65, 20)),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Heaved flagstone slab (pushed up by hydraulic pressure/tree roots)
    makePart(folderPaving, {
        Name = "HeavedPavingSlab",
        Size = Vector3.new(7, 0.4, 6),
        CFrame = toWorld(CFrame.new(-14, 0.95, -12) * CFrame.Angles(math.rad(6), math.rad(12), math.rad(-7))),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Sunken flagstone slab (eroded underneath by receding floodwaters)
    makePart(folderPaving, {
        Name = "SunkenPavingSlab",
        Size = Vector3.new(8, 0.3, 7),
        CFrame = toWorld(CFrame.new(16, 0.45, 14) * CFrame.Angles(math.rad(-4), math.rad(-6), math.rad(3))),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_SUNKEN,
    })

    -- North entrance stepped flagstone apron
    makePart(folderPaving, {
        Name = "NorthEntranceApron",
        Size = Vector3.new(22, 0.4, 8),
        CFrame = toWorld(CFrame.new(0, 0.6, -46)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- ------------------------------------------------------------------------
    -- 3. FOUNTAIN (11 parts)
    -- Dried and damaged decorative civic fountain in the central-southern square
    -- ------------------------------------------------------------------------
    local fountainCenter = Vector3.new(0, 0.7, 12)

    -- Outer octagonal fountain basin ring (curved perimeter represented by 4 oriented curb walls)
    makePart(folderFountain, {
        Name = "FountainBasinRim_North",
        Size = Vector3.new(14, 1.4, 1.6),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.7, -7))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    makePart(folderFountain, {
        Name = "FountainBasinRim_South",
        Size = Vector3.new(14, 1.4, 1.6),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.7, 7))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    makePart(folderFountain, {
        Name = "FountainBasinRim_West",
        Size = Vector3.new(1.6, 1.4, 14),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(-7, 0.7, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    -- East rim has a breached/shattered section from floodwater ingress
    makePart(folderFountain, {
        Name = "FountainBasinRim_EastIntact",
        Size = Vector3.new(1.6, 1.4, 8),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(7, 0.7, -3))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    makeWedge(folderFountain, {
        Name = "FountainBasinRim_EastBreach",
        Size = Vector3.new(1.6, 1.2, 5),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(7, 0.4, 4.5)) * CFrame.Angles(0, 0, math.rad(180))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    -- Dried basin interior floor slab
    makeCylinder(folderFountain, {
        Name = "FountainBasinFloor",
        Size = Vector3.new(0.3, 13.5, 13.5),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Slate,
        Color = COLOR_FOUNTAIN_BASIN,
    })

    -- Dried silt layer inside basin
    makePart(folderFountain, {
        Name = "FountainBasinSiltBed",
        Size = Vector3.new(11, 0.15, 11),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.35, 0))),
        Material = Enum.Material.Sand,
        Color = COLOR_PAVING_SUNKEN,
    })

    -- Central carved fountain pedestal base
    makePart(folderFountain, {
        Name = "FountainCenterPedestal",
        Size = Vector3.new(4, 2.2, 4),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 1.1, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    -- Upper fountain tier basin bowl (Cylinder)
    makeCylinder(folderFountain, {
        Name = "FountainUpperTierBowl",
        Size = Vector3.new(0.8, 7.5, 7.5),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    -- Corroded central water jet finial spout
    makeCylinder(folderFountain, {
        Name = "FountainCentralSpoutStump",
        Size = Vector3.new(1.8, 0.8, 0.8),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_FOUNTAIN_PIPE,
    })

    -- Broken basin coping stone chunk fallen into bottom
    makePart(folderFountain, {
        Name = "FountainBrokenCopingChunk",
        Size = Vector3.new(2.4, 0.7, 1.4),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(3.8, 0.5, 3.2)) * CFrame.Angles(math.rad(14), math.rad(35), math.rad(-10))),
        Material = Enum.Material.Concrete,
        Color = COLOR_FOUNTAIN_STONE,
    })

    -- ------------------------------------------------------------------------
    -- 4. MONUMENT (9 parts)
    -- Famous Villa Epecuén tourist orientation signboard ("Cartel Ud. Está Aquí")
    -- ------------------------------------------------------------------------
    local monumentCenter = Vector3.new(0, 0.7, -24)

    -- Monument concrete stepped plinth lower tier
    makePart(folderMonument, {
        Name = "MonumentPlinthBaseTier1",
        Size = Vector3.new(14, 0.7, 7),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 0.35, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_PLINTH,
    })

    -- Monument concrete plinth upper tier
    makePart(folderMonument, {
        Name = "MonumentPlinthBaseTier2",
        Size = Vector3.new(12, 0.8, 5.5),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 1.0, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_PLINTH,
    })

    -- Left concrete signboard pillar stanchion
    makePart(folderMonument, {
        Name = "MonumentSignPillar_Left",
        Size = Vector3.new(1.4, 7.5, 1.4),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(-4.8, 4.5, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_PLINTH,
    })

    -- Right concrete signboard pillar stanchion
    makePart(folderMonument, {
        Name = "MonumentSignPillar_Right",
        Size = Vector3.new(1.4, 7.5, 1.4),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(4.8, 4.5, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_PLINTH,
    })

    -- Iconic "Ud. Está Aquí" tourist orientation signboard panel (faded ochre/yellow)
    makePart(folderMonument, {
        Name = "MonumentTouristSignBoard",
        Size = Vector3.new(8.4, 5.2, 0.5),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 5.2, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_YELLOW,
    })

    -- Signboard concrete top coping marquee
    makePart(folderMonument, {
        Name = "MonumentSignTopCoping",
        Size = Vector3.new(11.4, 0.7, 1.8),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 8.0, 0))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_FRAME,
    })

    -- Lower commemorative civic bronze dedication plaque
    makePart(folderMonument, {
        Name = "MonumentCivicBronzePlaque",
        Size = Vector3.new(3.6, 1.4, 0.2),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 1.1, 2.8))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_MONUMENT_PLAQUE,
    })

    -- Fractured corner sheared from the tourist signboard panel
    makeWedge(folderMonument, {
        Name = "MonumentShearedSignCorner",
        Size = Vector3.new(0.5, 1.6, 2.0),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(3.8, 6.8, 0)) * CFrame.Angles(0, math.rad(90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_YELLOW,
    })

    -- Fallen signboard fragment resting on ground at plinth base
    makePart(folderMonument, {
        Name = "MonumentFallenBoardChunk",
        Size = Vector3.new(2.2, 0.35, 1.8),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(2.5, 0.2, 2.2)) * CFrame.Angles(math.rad(8), math.rad(22), math.rad(-14))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_YELLOW,
    })

    -- ------------------------------------------------------------------------
    -- 5. PERIMETER (10 parts)
    -- Low retaining walls, entrance openings, and corner stone bollards
    -- ------------------------------------------------------------------------
    -- North perimeter retaining wall - Left segment
    makePart(folderPerimeter, {
        Name = "PerimeterWall_NorthWest",
        Size = Vector3.new(36, 1.6, 1.4),
        CFrame = toWorld(CFrame.new(-24, 1.2, -49)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- North perimeter retaining wall - Right segment
    makePart(folderPerimeter, {
        Name = "PerimeterWall_NorthEast",
        Size = Vector3.new(36, 1.6, 1.4),
        CFrame = toWorld(CFrame.new(24, 1.2, -49)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- South perimeter retaining wall - Left segment
    makePart(folderPerimeter, {
        Name = "PerimeterWall_SouthWest",
        Size = Vector3.new(36, 1.6, 1.4),
        CFrame = toWorld(CFrame.new(-24, 1.2, 49)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- South perimeter retaining wall - Right segment (partially broken)
    makePart(folderPerimeter, {
        Name = "PerimeterWall_SouthEast",
        Size = Vector3.new(28, 1.6, 1.4),
        CFrame = toWorld(CFrame.new(20, 1.2, 49)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- West perimeter wall segment
    makePart(folderPerimeter, {
        Name = "PerimeterWall_West",
        Size = Vector3.new(1.4, 1.6, 68),
        CFrame = toWorld(CFrame.new(-43, 1.2, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- East perimeter wall segment
    makePart(folderPerimeter, {
        Name = "PerimeterWall_East",
        Size = Vector3.new(1.4, 1.6, 68),
        CFrame = toWorld(CFrame.new(43, 1.2, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- 4 Historic stone entrance bollards (flanking north and south pedestrian entrances)
    makeCylinder(folderPerimeter, {
        Name = "EntranceBollard_NorthLeft",
        Size = Vector3.new(2.8, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(-6, 1.8, -49) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    makeCylinder(folderPerimeter, {
        Name = "EntranceBollard_NorthRight",
        Size = Vector3.new(2.8, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(6, 1.8, -49) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    makeCylinder(folderPerimeter, {
        Name = "EntranceBollard_SouthLeft",
        Size = Vector3.new(2.8, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(-6, 1.8, 49) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    makeCylinder(folderPerimeter, {
        Name = "EntranceBollard_SouthRight",
        Size = Vector3.new(2.8, 1.4, 1.4),
        CFrame = toWorld(CFrame.new(6, 1.8, 49) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- ------------------------------------------------------------------------
    -- 6. STREET FURNITURE (12 parts)
    -- Vintage unlit cast-iron streetlamps and weathered plaza benches
    -- ------------------------------------------------------------------------
    -- HISTORIC STANDING LAMP-POST (West Promenade - WITHOUT functional lighting)
    -- Fluted base
    makeCylinder(folderStreetFurniture, {
        Name = "LampPost_West_FlutedBase",
        Size = Vector3.new(1.6, 1.8, 1.8),
        CFrame = toWorld(CFrame.new(-28, 1.4, -6) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_DARK,
    })

    -- Slender iron mast/shaft
    makeCylinder(folderStreetFurniture, {
        Name = "LampPost_West_Shaft",
        Size = Vector3.new(14, 0.6, 0.6),
        CFrame = toWorld(CFrame.new(-28, 8.8, -6) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_DARK,
    })

    -- Decorative curved scroll arm
    makePart(folderStreetFurniture, {
        Name = "LampPost_West_CrossArm",
        Size = Vector3.new(3.0, 0.3, 0.3),
        CFrame = toWorld(CFrame.new(-27.2, 15.6, -6)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_DARK,
    })

    -- Empty iron lantern cage frame (NO PointLight, NO SurfaceLight)
    makePart(folderStreetFurniture, {
        Name = "LampPost_West_LanternCage",
        Size = Vector3.new(1.2, 1.8, 1.2),
        CFrame = toWorld(CFrame.new(-26.0, 15.0, -6)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_LIGHT,
    })

    -- HISTORIC FALLEN/BENT LAMP-POST (East Promenade - snapped by flood debris)
    makeCylinder(folderStreetFurniture, {
        Name = "LampPost_East_RupturedBase",
        Size = Vector3.new(1.2, 1.8, 1.8),
        CFrame = toWorld(CFrame.new(28, 1.2, 16) * CFrame.Angles(0, 0, math.rad(90))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_DARK,
    })

    makeCylinder(folderStreetFurniture, {
        Name = "LampPost_East_FallenShaft",
        Size = Vector3.new(12, 0.55, 0.55),
        CFrame = toWorld(CFrame.new(25, 1.4, 22) * CFrame.Angles(math.rad(72), math.rad(18), math.rad(34))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_DARK,
    })

    makePart(folderStreetFurniture, {
        Name = "LampPost_East_CrushedLantern",
        Size = Vector3.new(1.4, 0.8, 1.2),
        CFrame = toWorld(CFrame.new(22, 0.8, 27) * CFrame.Angles(math.rad(10), math.rad(45), math.rad(-25))),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_LIGHT,
    })

    -- HISTORIC PLAZA BENCH 1 (North Promenade, near fountain)
    -- Left concrete stanchion
    makePart(folderStreetFurniture, {
        Name = "Bench1_Stanchion_Left",
        Size = Vector3.new(0.6, 2.0, 2.0),
        CFrame = toWorld(CFrame.new(-16, 1.6, -2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_BENCH_CONCRETE,
    })

    -- Right concrete stanchion
    makePart(folderStreetFurniture, {
        Name = "Bench1_Stanchion_Right",
        Size = Vector3.new(0.6, 2.0, 2.0),
        CFrame = toWorld(CFrame.new(-10, 1.6, -2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_BENCH_CONCRETE,
    })

    -- Remaining weathered wood seat slats
    makePart(folderStreetFurniture, {
        Name = "Bench1_WeatheredSeatSlats",
        Size = Vector3.new(7.0, 0.25, 1.4),
        CFrame = toWorld(CFrame.new(-13, 1.8, -2)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    -- HISTORIC PLAZA BENCH 2 (Southeast Quadrant, partially collapsed)
    makePart(folderStreetFurniture, {
        Name = "Bench2_TippedStanchion",
        Size = Vector3.new(0.6, 2.0, 2.0),
        CFrame = toWorld(CFrame.new(18, 1.3, 26) * CFrame.Angles(math.rad(22), 0, math.rad(-14))),
        Material = Enum.Material.Concrete,
        Color = COLOR_BENCH_CONCRETE,
    })

    -- Broken wood slat on ground
    makePart(folderStreetFurniture, {
        Name = "Bench2_DetachedWoodSlat",
        Size = Vector3.new(4.8, 0.2, 0.6),
        CFrame = toWorld(CFrame.new(20, 0.7, 28) * CFrame.Angles(0, math.rad(38), math.rad(6))),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    -- ------------------------------------------------------------------------
    -- 7. DAMAGE (8 parts)
    -- Heaved pavement, ground fissures, buckled curbs, and flood scour trenches
    -- ------------------------------------------------------------------------
    -- Heaved pavement buckled upward
    makeWedge(folderDamage, {
        Name = "PavementHeaveWedge_Left",
        Size = Vector3.new(8, 0.8, 6),
        CFrame = toWorld(CFrame.new(-24, 0.9, -16) * CFrame.Angles(0, math.rad(90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    makeWedge(folderDamage, {
        Name = "PavementHeaveWedge_Right",
        Size = Vector3.new(8, 0.8, 6),
        CFrame = toWorld(CFrame.new(-18, 0.9, -16) * CFrame.Angles(0, math.rad(-90), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- Subsidence ground fissure near southeast quadrant
    makePart(folderDamage, {
        Name = "GroundFissureTrench",
        Size = Vector3.new(16, 0.5, 2.2),
        CFrame = toWorld(CFrame.new(20, 0.35, 12) * CFrame.Angles(0, math.rad(25), 0)),
        Material = Enum.Material.Slate,
        Color = COLOR_PAVING_SUNKEN,
    })

    -- Buckled sidewalk curb slab 1
    makePart(folderDamage, {
        Name = "BuckledCurbSlab_North",
        Size = Vector3.new(6, 0.6, 1.8),
        CFrame = toWorld(CFrame.new(-14, 0.7, -49) * CFrame.Angles(math.rad(8), math.rad(15), math.rad(-12))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- Buckled sidewalk curb slab 2
    makePart(folderDamage, {
        Name = "BuckledCurbSlab_South",
        Size = Vector3.new(5, 0.6, 1.8),
        CFrame = toWorld(CFrame.new(14, 0.7, 49) * CFrame.Angles(math.rad(-10), math.rad(-20), math.rad(8))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- Sheared perimeter wall breach gap wedge
    makeWedge(folderDamage, {
        Name = "PerimeterWallShearWedge",
        Size = Vector3.new(1.4, 1.5, 6),
        CFrame = toWorld(CFrame.new(36, 1.1, 49) * CFrame.Angles(0, math.rad(180), 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- Eroded drainage gully scour mark
    makePart(folderDamage, {
        Name = "FloodScourGully",
        Size = Vector3.new(14, 0.25, 4),
        CFrame = toWorld(CFrame.new(-32, 0.45, 14) * CFrame.Angles(0, math.rad(-30), 0)),
        Material = Enum.Material.Sand,
        Color = COLOR_PAVING_SUNKEN,
    })

    -- Displaced terrace corner step
    makeCornerWedge(folderDamage, {
        Name = "DisplacedCornerStepWedge",
        Size = Vector3.new(3, 0.6, 3),
        CFrame = toWorld(CFrame.new(33, 0.55, -35)),
        Material = Enum.Material.Concrete,
        Color = COLOR_PAVING_WEATHERED,
    })

    -- ------------------------------------------------------------------------
    -- 8. RUBBLE (10 parts)
    -- Broken stone blocks, crumbled mortar, and scattered flood scree
    -- ------------------------------------------------------------------------
    -- Rubble heap near breached perimeter wall
    makePart(folderRubble, {
        Name = "RubbleHeap_PerimeterBreach",
        Size = Vector3.new(6, 1.0, 5),
        CFrame = toWorld(CFrame.new(37, 0.8, 48) * CFrame.Angles(math.rad(5), math.rad(30), math.rad(-8))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- Fallen decorative pediment block near monument
    makePart(folderRubble, {
        Name = "RubbleBlock_MonumentSlab",
        Size = Vector3.new(2.4, 0.8, 1.6),
        CFrame = toWorld(CFrame.new(-6, 0.7, -26) * CFrame.Angles(math.rad(12), math.rad(-40), math.rad(15))),
        Material = Enum.Material.Concrete,
        Color = COLOR_MONUMENT_PLINTH,
    })

    -- 6 Scattered concrete cobblestone chunks across walkways
    local rubbleCoords = {
        Vector3.new(-18, 0.65, 8),
        Vector3.new(14, 0.65, -8),
        Vector3.new(-6, 0.65, 26),
        Vector3.new(24, 0.65, -32),
        Vector3.new(-28, 0.65, -30),
        Vector3.new(8, 0.65, 34),
    }

    for i, rPos in ipairs(rubbleCoords) do
        local rx = rng:NextNumber(-0.6, 0.6)
        local rz = rng:NextNumber(-0.6, 0.6)
        local rRot = rng:NextNumber(0, 180)
        makePart(folderRubble, {
            Name = "ScatteredCobble_" .. tostring(i),
            Size = Vector3.new(1.4 + (i % 2) * 0.4, 0.5 + (i % 3) * 0.2, 1.2 + ((i + 1) % 2) * 0.4),
            CFrame = toWorld(CFrame.new(rPos + Vector3.new(rx, 0, rz)) * CFrame.Angles(math.rad(rng:NextNumber(-15, 15)), math.rad(rRot), math.rad(rng:NextNumber(-15, 15)))),
            Material = Enum.Material.Concrete,
            Color = COLOR_PAVING_WEATHERED,
        })
    end

    -- Fallen retaining wall chunk
    makePart(folderRubble, {
        Name = "FallenWallChunk_West",
        Size = Vector3.new(3.2, 0.9, 1.4),
        CFrame = toWorld(CFrame.new(-41, 0.7, -14) * CFrame.Angles(math.rad(10), math.rad(55), math.rad(-12))),
        Material = Enum.Material.Concrete,
        Color = COLOR_CURB_CONCRETE,
    })

    -- Crumbled mortar apron near fountain
    makePart(folderRubble, {
        Name = "CrumbledMortarApron",
        Size = Vector3.new(4.5, 0.25, 3.5),
        CFrame = toWorld(CFrame.new(8, 0.65, 18)),
        Material = Enum.Material.Sand,
        Color = COLOR_PAVING_SUNKEN,
    })

    -- ------------------------------------------------------------------------
    -- 9. SALT CRUST (9 parts)
    -- High-reflectance evaporite mineral sheets, waterline tide shelves
    -- ------------------------------------------------------------------------
    -- Reflective salt crust sheet coating the bottom of the fountain
    makePart(folderSaltCrust, {
        Name = "SaltCrust_FountainFloor",
        Size = Vector3.new(8.5, 0.1, 8.5),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.4, 0))),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_PURE_WHITE,
        Reflectance = 0.35 * saltLevel,
    })

    -- Waterline tide shelf encrusting the fountain basin interior wall
    makePart(folderSaltCrust, {
        Name = "SaltTideShelf_FountainRim",
        Size = Vector3.new(12, 0.25, 12),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(0, 0.9, 0))),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.25 * saltLevel,
    })

    -- Salt mineral evaporite sheet on sunken pavement quadrant
    makePart(folderSaltCrust, {
        Name = "SaltCrustSheet_SouthEast",
        Size = Vector3.new(12, 0.08, 10),
        CFrame = toWorld(CFrame.new(18, 0.75, 16)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.30 * saltLevel,
    })

    -- Salt crust patch near monument base
    makePart(folderSaltCrust, {
        Name = "SaltCrustPatch_MonumentBase",
        Size = Vector3.new(8, 0.08, 4.5),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(0, 0.75, 1.2))),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_PURE_WHITE,
        Reflectance = 0.35 * saltLevel,
    })

    -- Horizontal salt tide shelf along North perimeter wall
    makePart(folderSaltCrust, {
        Name = "SaltTideBand_NorthWall",
        Size = Vector3.new(34, 0.3, 0.3),
        CFrame = toWorld(CFrame.new(-24, 1.0, -48.2)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_TIDE_SHELF,
        Reflectance = 0.25 * saltLevel,
    })

    -- Horizontal salt tide shelf along South perimeter wall
    makePart(folderSaltCrust, {
        Name = "SaltTideBand_SouthWall",
        Size = Vector3.new(34, 0.3, 0.3),
        CFrame = toWorld(CFrame.new(-24, 1.0, 48.2)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_TIDE_SHELF,
        Reflectance = 0.25 * saltLevel,
    })

    -- Evaporite mineral puddle slab in northwest walkway
    makePart(folderSaltCrust, {
        Name = "SaltEvaporitePuddle_NW",
        Size = Vector3.new(9, 0.06, 7),
        CFrame = toWorld(CFrame.new(-20, 0.75, -28)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.35 * saltLevel,
    })

    -- Salt streak capping the fallen lamp-post
    makePart(folderSaltCrust, {
        Name = "SaltCrust_FallenLampCap",
        Size = Vector3.new(4, 0.12, 0.8),
        CFrame = toWorld(CFrame.new(24, 1.6, 23)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_PURE_WHITE,
        Reflectance = 0.30 * saltLevel,
    })

    -- Salt shelf lining the broken curb gap
    makePart(folderSaltCrust, {
        Name = "SaltShelf_BreachCurb",
        Size = Vector3.new(5, 0.15, 1.6),
        CFrame = toWorld(CFrame.new(14, 0.75, 49)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_TIDE_SHELF,
        Reflectance = 0.25 * saltLevel,
    })

    -- ------------------------------------------------------------------------
    -- 10. VEGETATION (9 parts)
    -- Hardy Argentine pampas halophytes, cardo thistles, and creeping weeds
    -- ------------------------------------------------------------------------
    -- Saltbush shrub sprouting in dried fountain rim breach
    makePart(folderVegetation, {
        Name = "HalophyteShrub_FountainBreach",
        Size = Vector3.new(2.4, 1.6, 2.2),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(6.8, 1.2, 3.5))),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_SAGE_SCRUB,
        CanCollide = false,
    })

    -- Bleached dry thistle sprouting in fountain basin silt
    makePart(folderVegetation, {
        Name = "DryThistle_FountainBasin",
        Size = Vector3.new(1.8, 1.2, 1.8),
        CFrame = toWorld(CFrame.new(fountainCenter + Vector3.new(-2.5, 0.8, -1.8))),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_DRY_THISTLE,
        CanCollide = false,
    })

    -- Creeping halophyte weed cluster along monument plinth step
    makePart(folderVegetation, {
        Name = "PampasWeed_MonumentBase",
        Size = Vector3.new(2.8, 0.8, 1.4),
        CFrame = toWorld(CFrame.new(monumentCenter + Vector3.new(-3.5, 0.8, 2.8))),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_SAGE_SCRUB,
        CanCollide = false,
    })

    -- Hardy Argentine saltbush sprouting through heaved paving crack
    makePart(folderVegetation, {
        Name = "Saltbush_HeavedCrack",
        Size = Vector3.new(2.6, 1.5, 2.4),
        CFrame = toWorld(CFrame.new(-21, 1.2, -16)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_SAGE_SCRUB,
        CanCollide = false,
    })

    -- Dry thistle clump near broken bench
    makePart(folderVegetation, {
        Name = "DryThistle_Bench1",
        Size = Vector3.new(1.6, 1.1, 1.5),
        CFrame = toWorld(CFrame.new(-13, 1.0, 1.2)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_DRY_THISTLE,
        CanCollide = false,
    })

    -- Saline moss cluster in shadowed pavement subsidence
    makePart(folderVegetation, {
        Name = "SalineMoss_Fissure",
        Size = Vector3.new(3.2, 0.4, 1.8),
        CFrame = toWorld(CFrame.new(20, 0.5, 12)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_DAMP_MOSS,
        CanCollide = false,
    })

    -- Shrub cluster along North perimeter wall
    makePart(folderVegetation, {
        Name = "HalophyteShrub_NorthWall",
        Size = Vector3.new(2.2, 1.4, 2.0),
        CFrame = toWorld(CFrame.new(-36, 1.2, -48)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_SAGE_SCRUB,
        CanCollide = false,
    })

    -- Dry cardo thistle cluster along South perimeter wall
    makePart(folderVegetation, {
        Name = "DryThistle_SouthWall",
        Size = Vector3.new(2.0, 1.2, 1.8),
        CFrame = toWorld(CFrame.new(26, 1.2, 48)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_DRY_THISTLE,
        CanCollide = false,
    })

    -- Wild pampas weed clump in southwest quadrant
    makePart(folderVegetation, {
        Name = "PampasWeed_SouthWest",
        Size = Vector3.new(2.2, 1.0, 2.0),
        CFrame = toWorld(CFrame.new(-26, 1.0, 24)),
        Material = Enum.Material.Grass,
        Color = COLOR_VEG_SAGE_SCRUB,
        CanCollide = false,
    })

    -- Parent to requested parent if provided
    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

-- ============================================================================
-- METRICS & INTROSPECTION
-- ============================================================================

function PlazaCentralLandmarkBuilder.GetMetrics(): {
    PartCount: number,
    FootprintStuds: Vector3,
    MaxHeightStuds: number,
    CanonicalPosition: Vector3,
}
    return {
        PartCount = 96, -- Exactly 96 native Roblox parts across all 10 folders
        FootprintStuds = Vector3.new(108, 16, 116),
        MaxHeightStuds = 16, -- Maximum vertical height (vintage lamp-post spire)
        CanonicalPosition = CANONICAL_PLAZA_POS,
    }
end

return PlazaCentralLandmarkBuilder
