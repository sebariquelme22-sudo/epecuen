--!strict
--[[
    ChurchLandmarkBuilder.luau
    Location: ServerScriptService/ChurchLandmarkBuilder.luau

    Procedural Landmark Architecture Builder for the Ruined Parish Church of Villa Epecuén.
    Visual Reference: Parroquia / Iglesia de Villa Epecuén (Adolfo Alsina, Buenos Aires, Argentina).

    Canonical Map Reference:
      - Location: Position = Vector3.new(60, 8, 150) (Zone: ZONE_CHURCH / Santuario Parroquial)
      - Footprint: Approximately 80 x 120 studs
      - Maximum Height: Approximately 48 studs (Iconic bell tower / campanario)
      - Street Context: Situated along Calle Rivadavia between Calle Mitre and Central Plaza

    Architectural & Historical Profile:
      The Parish Church of Villa Epecuén served both the permanent local community and thousands
      of seasonal tourists who visited the thermal saltwater resort. When the protective levee
      collapsed on November 10, 1985, the church was inundated under 10 meters of hyper-mineralized
      saline lagoon water for more than two decades.

      Upon the water's retreat, the church emerged as one of the most haunting and recognizable
      silhouettes of the ghost town:
        - Elongated church nave (~110 studs long, 68 studs total width with aisles).
        - Prominent, asymmetric bell tower (campanario) standing at the northwestern facade,
          reaching ~48 studs into the sky with arched bell chamber openings and cross remnant.
        - Broken main entrance portal facing north with fractured arch lintel and grand portal steps.
        - Catastrophic asymmetric wall collapse: the eastern lateral wall suffered deep breach
          from incoming flood currents, while the western lateral wall and buttresses stand higher.
        - Collapsed timber roof trusses angled steeply into the central nave floor, exposing
          the sky above cracked ecclesiastical flagstones.
        - Gothic and Romanesque lancet window openings along the standing clerestory walls.
        - Exposed Argentine red clay masonry (ladrillo común bonaerense) where salty stucco flaked away.
        - Thick, calcified white mineral salt waterline shelves encrusting the lower 4-8 studs.
        - High mounds of collapsed brick, cracked altar chancel, and plaster scree.
        - Hardy pampas salt shrubs, halophyte bushes, and wild weeds sprouting from cracks and damp rubble.

    Technical Constraints:
      - 100% native Roblox geometry: Part (Block, Cylinder), WedgePart, CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, sounds, AI, or ProximityPrompts.
      - ZERO automatic instantiation into Workspace on module require/load.
      - Fully deterministic through Random.new(seed).
      - Optimized budget: strictly ~90-150 parts.
      - Organized into designated sub-folders:
          Foundation, Nave, Walls, Belfry, Openings, RoofDamage, Rubble, SaltCrust, Vegetation.
--]]

local ChurchLandmarkBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type ChurchBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    Parent: Instance?,
    DamageLevel: number?, -- 0.0 to 1.0 (default 0.75)
    SaltLevel: number?,   -- 0.0 to 1.0 (default 0.80)
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
-- COLOR & MATERIAL PALETTE (Villa Epecuén Church Ruins)
-- ============================================================================

-- Stucco, Concrete & Weathered Mortar
local COLOR_STUCCO_WEATHERED    = Color3.fromRGB(168, 164, 154) -- Weathered saline exterior plaster
local COLOR_STUCCO_AGED_WARM    = Color3.fromRGB(185, 180, 168) -- Faded cream ecclesiastical stucco
local COLOR_CONCRETE_CORE       = Color3.fromRGB(142, 138, 130) -- Structural reinforced concrete
local COLOR_CONCRETE_DARK       = Color3.fromRGB(116, 112, 106) -- Damp waterline-stained concrete

-- Exposed Argentine Clay Masonry (Ladrillo Común Bonaerense)
local COLOR_BRICK_RED           = Color3.fromRGB(162, 88, 68)   -- Classic fired clay red brick
local COLOR_BRICK_DARK          = Color3.fromRGB(132, 70, 54)   -- Submerged inner brick core
local COLOR_BRICK_MORTAR_MIX    = Color3.fromRGB(152, 114, 98)  -- Crumbled brick and lime mortar

-- Mineral Salt Crusts & Waterline Evaporite Deposits
local COLOR_SALT_CRYSTAL_WHITE  = Color3.fromRGB(250, 250, 246) -- Pure calcified salt crust
local COLOR_SALT_OFFWHITE       = Color3.fromRGB(234, 236, 228) -- Thick mineral brine shelf
local COLOR_SALT_SILT_BLEND     = Color3.fromRGB(214, 216, 206) -- Brine watermark tide deposit

-- Corroded Metals & Structural Rebar
local COLOR_RUST_FLAKING        = Color3.fromRGB(120, 62, 40)   -- Oxidized iron bell / tie rods
local COLOR_RUST_DARK           = Color3.fromRGB(82, 46, 32)    -- Weathered wrought-iron cross

-- Weathered Timber & Floor Flagstones
local COLOR_DECAYED_WOOD        = Color3.fromRGB(105, 95, 82)   -- Rotten structural roof truss
local COLOR_CHURCH_FLAGSTONE    = Color3.fromRGB(135, 130, 122) -- Salt-stained nave paving stones
local COLOR_ALTAR_MARBLE_DIRT   = Color3.fromRGB(195, 192, 184) -- Cracked marble sanctuary stone

-- Post-Flood Vegetation (Hardy Pampas Halophytes & Saline Weeds)
local COLOR_VEG_SAGE_SHRUB      = Color3.fromRGB(112, 128, 98)  -- Argentine halophyte scrub
local COLOR_VEG_DRY_THISTLE     = Color3.fromRGB(142, 140, 102) -- Bleached dry weeds in rubble
local COLOR_VEG_DARK_MOSS       = Color3.fromRGB(86, 98, 72)    -- Damp saline moss in crevices

-- Canonical Defaults
local CANONICAL_CHURCH_POSITION = Vector3.new(60, 8, 150)

-- ============================================================================
-- PRIMITIVE CONSTRUCTORS (100% NATIVE ROBLOX GEOMETRY, ANCHORED)
-- ============================================================================

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
    cw.Color = cfg.Color or COLOR_STUCCO_WEATHERED
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
    c.Color = cfg.Color or COLOR_STUCCO_WEATHERED
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
-- DETAILED CHURCH BUILD LOGIC
-- ============================================================================
-- Local Coordinate Space:
--   - Origin (0, 0, 0): Center of church ground plane.
--   - Length along Z: ~110 studs total (-54 to +54 studs)
--       * North (Z = -54 to -40): Front facade, portal entrance, belfry tower base.
--       * Central (Z = -40 to +28): Church nave, aisles, broken side walls.
--       * South (Z = +28 to +54): Altar sanctuary, chancel apse, sacristy remnants.
--   - Width along X: ~70 studs total (-35 to +35 studs)
--       * West (X = -35 to -18): Standing western nave wall, belfry corner, buttresses.
--       * Central (X = -18 to +18): Main central nave, processional aisle, altar.
--       * East (X = +18 to +35): Collapsed eastern lateral wall, breached masonry, scree.
--   - Height along Y: Ground at Y = 0.
--       * Nave walls reach Y = 16 to 28 studs.
--       * Bell tower belfry reaches Y = 46 to 48 studs (maximum landmark height).
-- ============================================================================

local function buildChurchLandmark(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: ChurchBuildOptions,
    rng: Random
): Part
    -- Sub-folders as strictly specified
    local folderFoundation = getOrCreateFolder(model, "Foundation")
    local folderNave       = getOrCreateFolder(model, "Nave")
    local folderWalls      = getOrCreateFolder(model, "Walls")
    local folderBelfry     = getOrCreateFolder(model, "Belfry")
    local folderOpenings   = getOrCreateFolder(model, "Openings")
    local folderRoofDamage = getOrCreateFolder(model, "RoofDamage")
    local folderRubble     = getOrCreateFolder(model, "Rubble")
    local folderSaltCrust  = getOrCreateFolder(model, "SaltCrust")
    local folderVegetation = getOrCreateFolder(model, "Vegetation")

    local _damage = opts.DamageLevel or 0.75
    local _salt = opts.SaltLevel or 0.80

    -- ------------------------------------------------------------------------
    -- 1. FOUNDATION (~10 parts)
    -- ------------------------------------------------------------------------
    -- Primary Part: Massive foundation slab
    local primaryFoundation = makePart(folderFoundation, {
        Name = "MainNaveFoundation",
        Size = Vector3.new(68 * scale, 1.8 * scale, 108 * scale),
        CFrame = rootCF * CFrame.new(0, 0.9 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CastShadow = true,
    })

    -- Front entrance portal steps (3 stepped tiers)
    makePart(folderFoundation, {
        Name = "EntranceStep_Lower",
        Size = Vector3.new(28 * scale, 0.6 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(0, 0.3 * scale, -56 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderFoundation, {
        Name = "EntranceStep_Mid",
        Size = Vector3.new(24 * scale, 0.6 * scale, 7 * scale),
        CFrame = rootCF * CFrame.new(0, 0.9 * scale, -54.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderFoundation, {
        Name = "EntranceStep_Upper",
        Size = Vector3.new(20 * scale, 0.6 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(0, 1.5 * scale, -53 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })

    -- Raised sanctuary / chancel altar podium
    makePart(folderFoundation, {
        Name = "ChancelPodiumBase",
        Size = Vector3.new(44 * scale, 1.4 * scale, 28 * scale),
        CFrame = rootCF * CFrame.new(0, 2.3 * scale, 38 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })
    makePart(folderFoundation, {
        Name = "AltarDaisStep",
        Size = Vector3.new(26 * scale, 0.8 * scale, 14 * scale),
        CFrame = rootCF * CFrame.new(0, 3.4 * scale, 40 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_ALTAR_MARBLE_DIRT,
    })

    -- Belfry corner massive foundation pad (Northwest corner)
    makePart(folderFoundation, {
        Name = "BelfryFoundationPad",
        Size = Vector3.new(22 * scale, 2.2 * scale, 22 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 1.1 * scale, -44 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Sub-base perimeter grade skirt
    makePart(folderFoundation, {
        Name = "GradeSkirt_West",
        Size = Vector3.new(4 * scale, 1.2 * scale, 96 * scale),
        CFrame = rootCF * CFrame.new(-34 * scale, 0.6 * scale, 2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })
    makePart(folderFoundation, {
        Name = "GradeSkirt_East",
        Size = Vector3.new(4 * scale, 1.0 * scale, 96 * scale),
        CFrame = rootCF * CFrame.new(34 * scale, 0.5 * scale, 2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 2. NAVE & INTERIOR (~12 parts)
    -- ------------------------------------------------------------------------
    -- Central processional flagstone aisle
    makePart(folderNave, {
        Name = "NaveCentralAislePaving",
        Size = Vector3.new(14 * scale, 0.4 * scale, 68 * scale),
        CFrame = rootCF * CFrame.new(0, 1.9 * scale, -8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CHURCH_FLAGSTONE,
    })

    -- Broken church altar mensa (stone sacrificial table)
    makePart(folderNave, {
        Name = "AltarTable_Mensa",
        Size = Vector3.new(16 * scale, 3.2 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(0, 5.4 * scale, 42 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_ALTAR_MARBLE_DIRT,
    })
    -- Altar fractured reredos / backdrop fragment
    makePart(folderNave, {
        Name = "AltarReredosBackdrop",
        Size = Vector3.new(20 * scale, 10 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(0, 10.5 * scale, 49 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Nave interior structural colonnade (West arcade pillars: standing; East arcade: fractured)
    local westPillarZs = { -28, -10, 8, 26 }
    for i, pz in ipairs(westPillarZs) do
        makePart(folderNave, {
            Name = string.format("NavePillar_West_%d", i),
            Size = Vector3.new(3.2 * scale, 18 * scale, 3.2 * scale),
            CFrame = rootCF * CFrame.new(-16 * scale, 10.8 * scale, pz * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_STUCCO_WEATHERED,
        })
    end

    -- East arcade pillars (only 2 remain standing, heavily damaged and truncated)
    makePart(folderNave, {
        Name = "NavePillar_East_1",
        Size = Vector3.new(3.2 * scale, 12 * scale, 3.2 * scale),
        CFrame = rootCF * CFrame.new(16 * scale, 7.8 * scale, -28 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })
    makePart(folderNave, {
        Name = "NavePillar_East_2",
        Size = Vector3.new(3.2 * scale, 6 * scale, 3.2 * scale),
        CFrame = rootCF * CFrame.new(16 * scale, 4.8 * scale, -10 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
    })

    -- Shattered communion rail remnant
    makePart(folderNave, {
        Name = "CommunionRail_Fragment",
        Size = Vector3.new(12 * scale, 1.8 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(-8 * scale, 3.5 * scale, 24 * scale) * CFrame.Angles(0, math.rad(12), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })

    -- Broken baptismal font basin (Cylinder)
    makeCylinder(folderNave, {
        Name = "BaptismalFont_Basin",
        Size = Vector3.new(3.0 * scale, 3.6 * scale, 3.6 * scale),
        CFrame = rootCF * CFrame.new(-12 * scale, 3.3 * scale, -38 * scale) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- ------------------------------------------------------------------------
    -- 3. MASONRY WALLS (~22 parts)
    -- ------------------------------------------------------------------------
    -- West Wall (High standing lateral wall, 3 interlocking vertical segments)
    makePart(folderWalls, {
        Name = "Wall_West_Bay1",
        Size = Vector3.new(3.2 * scale, 24 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 13.8 * scale, -24 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderWalls, {
        Name = "Wall_West_Bay2",
        Size = Vector3.new(3.2 * scale, 22 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 12.8 * scale, 0 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderWalls, {
        Name = "Wall_West_Bay3",
        Size = Vector3.new(3.2 * scale, 19 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 11.3 * scale, 24 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    -- West Wall Jagged Crest Wedge (simulates broken masonry top)
    makeWedge(folderWalls, {
        Name = "Wall_West_CrestBroken",
        Size = Vector3.new(3.2 * scale, 5 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 27.5 * scale, -18 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })

    -- West Wall Exterior Structural Buttresses (3 buttresses providing deep silhouette)
    local buttressZs = { -24, 0, 24 }
    for i, bz in ipairs(buttressZs) do
        makeWedge(folderWalls, {
            Name = string.format("Buttress_West_%d", i),
            Size = Vector3.new(2.4 * scale, 18 * scale, 6 * scale),
            CFrame = rootCF * CFrame.new(-35 * scale, 10.8 * scale, bz * scale) * CFrame.Angles(0, math.rad(90), 0),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_CORE,
        })
    end

    -- East Wall (Heavily breached, collapsed asymmetrical disaster)
    makePart(folderWalls, {
        Name = "Wall_East_StandingStump1",
        Size = Vector3.new(3.2 * scale, 12 * scale, 18 * scale),
        CFrame = rootCF * CFrame.new(32 * scale, 7.8 * scale, -32 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makeWedge(folderWalls, {
        Name = "Wall_East_BreachSlope",
        Size = Vector3.new(3.2 * scale, 8 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(32 * scale, 8.8 * scale, -15 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
    })
    -- Huge collapsed breach opening in middle of East wall (X=32, Z=-6 to +18)
    makePart(folderWalls, {
        Name = "Wall_East_RubbleLip",
        Size = Vector3.new(4.5 * scale, 3.5 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(32 * scale, 3.5 * scale, 6 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })
    makePart(folderWalls, {
        Name = "Wall_East_RearStanding",
        Size = Vector3.new(3.2 * scale, 10 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(32 * scale, 6.8 * scale, 26 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makeWedge(folderWalls, {
        Name = "Buttress_East_Intact",
        Size = Vector3.new(2.4 * scale, 10 * scale, 5 * scale),
        CFrame = rootCF * CFrame.new(34.5 * scale, 6.8 * scale, -32 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- North Front Facade Walls (surrounding the portal)
    makePart(folderWalls, {
        Name = "Facade_EastWing",
        Size = Vector3.new(20 * scale, 22 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 12.8 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    makeWedge(folderWalls, {
        Name = "Facade_EastGableSlope",
        Size = Vector3.new(3.4 * scale, 8 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 27.8 * scale, -51 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderWalls, {
        Name = "Facade_WestShoulder",
        Size = Vector3.new(8 * scale, 26 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-10 * scale, 14.8 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })

    -- South Sanctuary Apse Wall (Rear curved/polygonal chancel back wall)
    makePart(folderWalls, {
        Name = "Apse_BackWall",
        Size = Vector3.new(32 * scale, 18 * scale, 3.2 * scale),
        CFrame = rootCF * CFrame.new(0, 10.8 * scale, 52 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderWalls, {
        Name = "Apse_Corner_West",
        Size = Vector3.new(3.2 * scale, 16 * scale, 14 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 9.8 * scale, 44 * scale) * CFrame.Angles(0, math.rad(30), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderWalls, {
        Name = "Apse_Corner_East",
        Size = Vector3.new(3.2 * scale, 12 * scale, 14 * scale),
        CFrame = rootCF * CFrame.new(20 * scale, 7.8 * scale, 44 * scale) * CFrame.Angles(0, math.rad(-30), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })

    -- ------------------------------------------------------------------------
    -- 4. RECOGNIZABLE BELFRY / BELL TOWER (~18 parts)
    -- ------------------------------------------------------------------------
    -- The iconic silhouette beacon: Northwest corner of church facade, reaching Y ~ 48 studs.
    -- Tier 1: Lower Tower Shaft (Y = 0 to 20)
    makePart(folderBelfry, {
        Name = "Tower_Shaft_WestFace",
        Size = Vector3.new(2.4 * scale, 20 * scale, 18 * scale),
        CFrame = rootCF * CFrame.new(-33 * scale, 11.8 * scale, -44 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderBelfry, {
        Name = "Tower_Shaft_NorthFace",
        Size = Vector3.new(18 * scale, 20 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 11.8 * scale, -53 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderBelfry, {
        Name = "Tower_Shaft_SouthFace",
        Size = Vector3.new(18 * scale, 20 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 11.8 * scale, -35 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Mid-tier stringcourse cornice band (Y = 20 to 22)
    makePart(folderBelfry, {
        Name = "Tower_Cornice_Lower",
        Size = Vector3.new(20 * scale, 1.6 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 21.6 * scale, -44 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Tier 2: Mid Tower Clock / Lancet Tier (Y = 22 to 34)
    makePart(folderBelfry, {
        Name = "Tower_MidShaft_CornerNW",
        Size = Vector3.new(4.2 * scale, 12 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-31 * scale, 28.4 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    makePart(folderBelfry, {
        Name = "Tower_MidShaft_CornerNE",
        Size = Vector3.new(4.2 * scale, 12 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-17 * scale, 28.4 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    makePart(folderBelfry, {
        Name = "Tower_MidShaft_CornerSW",
        Size = Vector3.new(4.2 * scale, 12 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-31 * scale, 28.4 * scale, -37 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderBelfry, {
        Name = "Tower_MidShaft_CornerSE",
        Size = Vector3.new(4.2 * scale, 12 * scale, 4.2 * scale),
        CFrame = rootCF * CFrame.new(-17 * scale, 28.4 * scale, -37 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Empty clock aperture / rosette frame (North face of tower)
    makeCylinder(folderBelfry, {
        Name = "Tower_ClockFrame_North",
        Size = Vector3.new(1.2 * scale, 6.4 * scale, 6.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 28.4 * scale, -52.6 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Upper belfry balcony slab (Y = 34 to 35.5)
    makePart(folderBelfry, {
        Name = "Belfry_ChamberFloor",
        Size = Vector3.new(19 * scale, 1.4 * scale, 19 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 34.9 * scale, -44 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Tier 3: Open Bell Chamber Columns (Y = 35.5 to 44)
    makePart(folderBelfry, {
        Name = "Belfry_Pillar_NW",
        Size = Vector3.new(3.0 * scale, 8.5 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-31 * scale, 39.8 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderBelfry, {
        Name = "Belfry_Pillar_NE",
        Size = Vector3.new(3.0 * scale, 8.5 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-17 * scale, 39.8 * scale, -51 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makePart(folderBelfry, {
        Name = "Belfry_Pillar_SW",
        Size = Vector3.new(3.0 * scale, 8.5 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-31 * scale, 39.8 * scale, -37 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makePart(folderBelfry, {
        Name = "Belfry_Pillar_SE_Broken",
        Size = Vector3.new(3.0 * scale, 4.5 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-17 * scale, 37.8 * scale, -37 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
    })

    -- Wooden Bell Beam / Yoke and Oxidized Bronze Bell Silhouette
    makePart(folderBelfry, {
        Name = "Belfry_TimberBeam",
        Size = Vector3.new(15 * scale, 1.2 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 42.5 * scale, -44 * scale),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })
    makeCylinder(folderBelfry, {
        Name = "Belfry_OldBronzeBell",
        Size = Vector3.new(2.8 * scale, 3.4 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 40.2 * scale, -44 * scale) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- Belfry Pyramid Cap Remnant (Broken spire stump)
    makeCornerWedge(folderBelfry, {
        Name = "Belfry_CapSpire_West",
        Size = Vector3.new(8 * scale, 3.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-27.5 * scale, 45.8 * scale, -47.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    makeWedge(folderBelfry, {
        Name = "Belfry_CapSpire_EastBroken",
        Size = Vector3.new(3.6 * scale, 2.6 * scale, 7 * scale),
        CFrame = rootCF * CFrame.new(-20.5 * scale, 45.2 * scale, -47.5 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })

    -- Oxidized Wrought-Iron Church Cross (reaches highest point Y ~ 48 studs)
    makePart(folderBelfry, {
        Name = "Belfry_IronCross_Vertical",
        Size = Vector3.new(0.6 * scale, 3.6 * scale, 0.6 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 47.6 * scale, -47.5 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderBelfry, {
        Name = "Belfry_IronCross_Horizontal",
        Size = Vector3.new(2.4 * scale, 0.6 * scale, 0.6 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 48.2 * scale, -47.5 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 5. ARCHED OPENINGS & PORTAL ENTRANCE (~14 parts)
    -- ------------------------------------------------------------------------
    -- Grand Entrance Portal (Central Front, Z = -51)
    -- Portal flanking columns
    makePart(folderOpenings, {
        Name = "PortalColumn_West",
        Size = Vector3.new(2.4 * scale, 15 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 9.3 * scale, -51.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    makePart(folderOpenings, {
        Name = "PortalColumn_East",
        Size = Vector3.new(2.4 * scale, 15 * scale, 3.0 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 9.3 * scale, -51.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })
    -- Arched portal lintel wedges forming pointed arch apex
    makeWedge(folderOpenings, {
        Name = "PortalArch_WedgeWest",
        Size = Vector3.new(3.0 * scale, 4.2 * scale, 6.2 * scale),
        CFrame = rootCF * CFrame.new(-3 * scale, 18.7 * scale, -51.5 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    makeWedge(folderOpenings, {
        Name = "PortalArch_WedgeEast",
        Size = Vector3.new(3.0 * scale, 4.2 * scale, 6.2 * scale),
        CFrame = rootCF * CFrame.new(3 * scale, 18.7 * scale, -51.5 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })
    -- Fractured keystone fallen slightly down
    makePart(folderOpenings, {
        Name = "PortalKeystone_Fractured",
        Size = Vector3.new(2.0 * scale, 2.2 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(0, 19.8 * scale, -51.5 * scale) * CFrame.Angles(0, 0, math.rad(10)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Rose window / Oculus opening above grand portal
    makeCylinder(folderOpenings, {
        Name = "Facade_RoseWindowRim",
        Size = Vector3.new(2.0 * scale, 9 * scale, 9 * scale),
        CFrame = rootCF * CFrame.new(0, 27.5 * scale, -51 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Lancet Window Openings along standing West Wall (3 arched frames)
    local lancetZs = { -24, 0, 24 }
    for i, lz in ipairs(lancetZs) do
        -- Window Sill
        makePart(folderOpenings, {
            Name = string.format("Lancet_Sill_West_%d", i),
            Size = Vector3.new(4.2 * scale, 1.2 * scale, 8 * scale),
            CFrame = rootCF * CFrame.new(-32 * scale, 8.2 * scale, lz * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_STUCCO_WEATHERED,
        })
        -- Arched window top lintel wedges
        makeWedge(folderOpenings, {
            Name = string.format("Lancet_ArchL_West_%d", i),
            Size = Vector3.new(3.6 * scale, 3.0 * scale, 3.8 * scale),
            CFrame = rootCF * CFrame.new(-32 * scale, 19.2 * scale, (lz - 2) * scale),
            Material = Enum.Material.Brick,
            Color = COLOR_BRICK_RED,
        })
        makeWedge(folderOpenings, {
            Name = string.format("Lancet_ArchR_West_%d", i),
            Size = Vector3.new(3.6 * scale, 3.0 * scale, 3.8 * scale),
            CFrame = rootCF * CFrame.new(-32 * scale, 19.2 * scale, (lz + 2) * scale) * CFrame.Angles(0, math.rad(180), 0),
            Material = Enum.Material.Brick,
            Color = COLOR_BRICK_RED,
        })
    end

    -- Sacristy side entrance portal (South-East corner, breached opening)
    makePart(folderOpenings, {
        Name = "Sacristy_BrokenJamb",
        Size = Vector3.new(2.0 * scale, 7.5 * scale, 2.2 * scale),
        CFrame = rootCF * CFrame.new(28 * scale, 5.5 * scale, 48 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })

    -- ------------------------------------------------------------------------
    -- 6. ROOF DAMAGE & FALLEN TIMBERS (~12 parts)
    -- ------------------------------------------------------------------------
    -- Massive wooden rafters that gave way under floodwaters and crashed into the nave
    -- Rafter 1: Angled from standing West wall down to nave floor
    makePart(folderRoofDamage, {
        Name = "FallenRafter_West_1",
        Size = Vector3.new(1.2 * scale, 32 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-14 * scale, 12.0 * scale, -12 * scale) * CFrame.Angles(0, math.rad(15), math.rad(38)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })
    -- Rafter 2: Crossed beam fallen into central chancel
    makePart(folderRoofDamage, {
        Name = "FallenRafter_Chancel_2",
        Size = Vector3.new(1.2 * scale, 28 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(4 * scale, 8.5 * scale, 18 * scale) * CFrame.Angles(math.rad(22), math.rad(-25), math.rad(-32)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })
    -- Rafter 3: Broken splintered joist
    makePart(folderRoofDamage, {
        Name = "BrokenJoist_3",
        Size = Vector3.new(1.0 * scale, 18 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(8 * scale, 4.2 * scale, -2 * scale) * CFrame.Angles(math.rad(-10), math.rad(65), math.rad(14)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })
    -- Rafter 4: Fallen truss near belfry exit
    makePart(folderRoofDamage, {
        Name = "FallenRafter_Front_4",
        Size = Vector3.new(1.2 * scale, 22 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 6.2 * scale, -32 * scale) * CFrame.Angles(0, math.rad(-40), math.rad(26)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })

    -- Broken purlin plank remnants resting across fallen beams
    makePart(folderRoofDamage, {
        Name = "RoofPurlinPlank_A",
        Size = Vector3.new(14 * scale, 0.5 * scale, 2.8 * scale),
        CFrame = rootCF * CFrame.new(-10 * scale, 8.8 * scale, -8 * scale) * CFrame.Angles(math.rad(18), math.rad(8), math.rad(15)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })
    makePart(folderRoofDamage, {
        Name = "RoofPurlinPlank_B",
        Size = Vector3.new(12 * scale, 0.5 * scale, 2.4 * scale),
        CFrame = rootCF * CFrame.new(6 * scale, 7.2 * scale, 14 * scale) * CFrame.Angles(math.rad(-12), math.rad(30), math.rad(-20)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })

    -- Hanging collapsed roof truss remnant still clinging to upper West wall
    makePart(folderRoofDamage, {
        Name = "HangingTruss_WestCrown",
        Size = Vector3.new(12 * scale, 1.4 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 23.5 * scale, 8 * scale) * CFrame.Angles(0, 0, math.rad(-18)),
        Material = Enum.Material.Wood,
        Color = COLOR_DECAYED_WOOD,
    })

    -- Corrugated zinc / clay tile sheet remnants crumpled on floor
    makePart(folderRoofDamage, {
        Name = "ShatteredRoofTileSheet_1",
        Size = Vector3.new(8 * scale, 0.4 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(2 * scale, 2.1 * scale, -18 * scale) * CFrame.Angles(math.rad(8), math.rad(24), math.rad(4)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })
    makePart(folderRoofDamage, {
        Name = "ShatteredRoofTileSheet_2",
        Size = Vector3.new(10 * scale, 0.4 * scale, 5 * scale),
        CFrame = rootCF * CFrame.new(-8 * scale, 2.2 * scale, 6 * scale) * CFrame.Angles(math.rad(-6), math.rad(-35), math.rad(12)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_FLAKING,
    })

    -- Iron tie rods (corroded tension bars spanning broken nave)
    makePart(folderRoofDamage, {
        Name = "IronTieRod_Bent",
        Size = Vector3.new(24 * scale, 0.4 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(-4 * scale, 18.5 * scale, -4 * scale) * CFrame.Angles(0, 0, math.rad(-8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })
    makePart(folderRoofDamage, {
        Name = "IronTieRod_Snapped",
        Size = Vector3.new(14 * scale, 0.4 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(14 * scale, 14.2 * scale, 18 * scale) * CFrame.Angles(math.rad(12), 0, math.rad(24)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
    })

    -- ------------------------------------------------------------------------
    -- 7. RUBBLE & DEBRIS HEAPS (~16 parts)
    -- ------------------------------------------------------------------------
    -- Catastrophic masonry scree outside breached East wall (X = 30 to 42)
    makePart(folderRubble, {
        Name = "EastBreach_RubbleHeapMain",
        Size = Vector3.new(12 * scale, 3.6 * scale, 22 * scale),
        CFrame = rootCF * CFrame.new(34 * scale, 2.5 * scale, 2 * scale) * CFrame.Angles(0, math.rad(8), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_MORTAR_MIX,
    })
    makeWedge(folderRubble, {
        Name = "EastBreach_RubbleSlopeNorth",
        Size = Vector3.new(8 * scale, 3.2 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(35 * scale, 2.2 * scale, -14 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })
    makeWedge(folderRubble, {
        Name = "EastBreach_RubbleSlopeSouth",
        Size = Vector3.new(8 * scale, 2.8 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(35 * scale, 2.0 * scale, 18 * scale) * CFrame.Angles(0, math.rad(180), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
    })

    -- Scattered concrete blocks and fallen masonry lintels
    local rubbleBlocks = {
        { Pos = Vector3.new(6, 2.5, -34), Size = Vector3.new(4.2, 2.2, 3.6), RotY = 28, Mat = Enum.Material.Brick, Col = COLOR_BRICK_RED },
        { Pos = Vector3.new(-10, 2.4, -20), Size = Vector3.new(3.8, 1.8, 3.2), RotY = -45, Mat = Enum.Material.Concrete, Col = COLOR_CONCRETE_CORE },
        { Pos = Vector3.new(10, 2.6, 2), Size = Vector3.new(5.0, 2.4, 4.0), RotY = 62, Mat = Enum.Material.Brick, Col = COLOR_BRICK_MORTAR_MIX },
        { Pos = Vector3.new(-4, 2.3, 16), Size = Vector3.new(3.4, 2.0, 3.0), RotY = -18, Mat = Enum.Material.Concrete, Col = COLOR_STUCCO_WEATHERED },
        { Pos = Vector3.new(12, 2.5, 28), Size = Vector3.new(4.6, 2.2, 3.8), RotY = 35, Mat = Enum.Material.Brick, Col = COLOR_BRICK_DARK },
        { Pos = Vector3.new(-22, 2.4, 34), Size = Vector3.new(3.6, 1.9, 3.4), RotY = -70, Mat = Enum.Material.Concrete, Col = COLOR_CONCRETE_DARK },
        { Pos = Vector3.new(-8, 3.8, 38), Size = Vector3.new(5.2, 1.6, 4.4), RotY = 12, Mat = Enum.Material.Concrete, Col = COLOR_ALTAR_MARBLE_DIRT },
    }

    for i, rb in ipairs(rubbleBlocks) do
        makePart(folderRubble, {
            Name = string.format("RubbleBlock_%d", i),
            Size = rb.Size * scale,
            CFrame = rootCF * CFrame.new(rb.Pos * scale) * CFrame.Angles(0, math.rad(rb.RotY), 0),
            Material = rb.Mat,
            Color = rb.Col,
        })
    end

    -- Fallen stone arch keystone segment on nave floor
    makeWedge(folderRubble, {
        Name = "FallenArchKeystone_Floor",
        Size = Vector3.new(3.2 * scale, 2.2 * scale, 4.0 * scale),
        CFrame = rootCF * CFrame.new(4 * scale, 2.4 * scale, -10 * scale) * CFrame.Angles(math.rad(15), math.rad(40), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
    })

    -- Rubble wedge pile flanking main entrance stairs
    makeWedge(folderRubble, {
        Name = "EntranceStair_RubbleWedge",
        Size = Vector3.new(5.0 * scale, 2.0 * scale, 7.0 * scale),
        CFrame = rootCF * CFrame.new(14 * scale, 1.6 * scale, -52 * scale) * CFrame.Angles(0, math.rad(45), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Crumbled mortar mounds along western wall base
    makePart(folderRubble, {
        Name = "MortarMound_WestBay",
        Size = Vector3.new(4.2 * scale, 1.8 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(-28 * scale, 2.0 * scale, 8 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_BRICK_MORTAR_MIX,
    })

    -- ------------------------------------------------------------------------
    -- 8. SALT CRUST & WATERLINE WEATHERING (~12 parts)
    -- ------------------------------------------------------------------------
    -- The defining visual signature of Villa Epecuén: thick calcified white mineral deposits
    -- and tide-line shelves left by 25 years under hypersaline lagoon brine.
    -- High waterline shelf on standing West wall (at Y = 6 studs)
    makePart(folderSaltCrust, {
        Name = "WaterlineSaltShelf_WestWall",
        Size = Vector3.new(4.2 * scale, 1.4 * scale, 72 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 6.2 * scale, 0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.22,
    })
    -- Lower saline tide rim on West wall base
    makePart(folderSaltCrust, {
        Name = "SaltBaseCrust_WestWall",
        Size = Vector3.new(4.8 * scale, 2.0 * scale, 76 * scale),
        CFrame = rootCF * CFrame.new(-32 * scale, 2.4 * scale, 0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.18,
    })

    -- Waterline ring encircling Belfry Tower base (North & West faces)
    makePart(folderSaltCrust, {
        Name = "Tower_SaltShelf_North",
        Size = Vector3.new(20 * scale, 1.2 * scale, 3.4 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 6.4 * scale, -53 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.22,
    })
    makePart(folderSaltCrust, {
        Name = "Tower_SaltShelf_West",
        Size = Vector3.new(3.4 * scale, 1.2 * scale, 20 * scale),
        CFrame = rootCF * CFrame.new(-33 * scale, 6.4 * scale, -44 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.22,
    })

    -- Salt apron coating the lower altar podium steps
    makePart(folderSaltCrust, {
        Name = "Altar_SaltApron_Front",
        Size = Vector3.new(32 * scale, 0.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(0, 2.6 * scale, 28 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.20,
    })

    -- Salt crust deposit on East breach rubble pile
    makePart(folderSaltCrust, {
        Name = "EastBreach_SaltDeposit",
        Size = Vector3.new(10 * scale, 1.2 * scale, 18 * scale),
        CFrame = rootCF * CFrame.new(34 * scale, 3.8 * scale, 2 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
    })

    -- Saline evaporite sheets clinging to nave floor cracks
    local floorSaltSheets = {
        { Pos = Vector3.new(-8, 2.05, -28), Size = Vector3.new(10, 0.3, 8), RotY = 15 },
        { Pos = Vector3.new(4, 2.05, -4), Size = Vector3.new(12, 0.3, 10), RotY = -25 },
        { Pos = Vector3.new(-6, 2.05, 18), Size = Vector3.new(9, 0.3, 7), RotY = 40 },
        { Pos = Vector3.new(18, 2.05, -36), Size = Vector3.new(8, 0.3, 6), RotY = -10 },
    }

    for i, ss in ipairs(floorSaltSheets) do
        makePart(folderSaltCrust, {
            Name = string.format("FloorSaltSheet_%d", i),
            Size = ss.Size * scale,
            CFrame = rootCF * CFrame.new(ss.Pos * scale) * CFrame.Angles(0, math.rad(ss.RotY), 0),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALT_OFFWHITE,
            Reflectance = 0.18,
        })
    end

    -- ------------------------------------------------------------------------
    -- 9. VEGETATION & POST-FLOOD GROWTH (~12 parts)
    -- ------------------------------------------------------------------------
    -- Resilient halophyte shrubs and dry pampas scrub colonizing the ruins
    local vegetationClusters = {
        -- Scrub outside East breach in rich silt
        { Name = "Shrub_EastBreach_1", Pos = Vector3.new(40, 1.8, -6), Size = Vector3.new(5.0, 3.2, 5.0), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "Shrub_EastBreach_2", Pos = Vector3.new(38, 2.0, 10), Size = Vector3.new(4.2, 2.8, 4.4), Col = COLOR_VEG_DRY_THISTLE },
        -- Tufted grass thriving in nave floor rubble dampness
        { Name = "NaveWeeds_Aisle_1", Pos = Vector3.new(-6, 2.4, -2), Size = Vector3.new(3.8, 2.2, 3.4), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "NaveWeeds_Aisle_2", Pos = Vector3.new(8, 2.4, 22), Size = Vector3.new(4.0, 2.0, 3.6), Col = COLOR_VEG_DRY_THISTLE },
        -- Moss / creepers along shaded West buttress footing
        { Name = "CreepingMoss_WestButtress1", Pos = Vector3.new(-36, 1.4, -22), Size = Vector3.new(3.2, 1.8, 4.8), Col = COLOR_VEG_DARK_MOSS },
        { Name = "CreepingMoss_WestButtress2", Pos = Vector3.new(-36, 1.4, 2), Size = Vector3.new(3.4, 1.6, 5.0), Col = COLOR_VEG_DARK_MOSS },
        -- Dry thistle sprouting on broken altar podium
        { Name = "AltarWeed_Crevice", Pos = Vector3.new(-10, 3.8, 42), Size = Vector3.new(2.8, 2.4, 2.6), Col = COLOR_VEG_DRY_THISTLE },
        -- Halophyte bush at front facade entrance steps
        { Name = "FacadeBush_FrontWest", Pos = Vector3.new(-18, 1.6, -56), Size = Vector3.new(4.4, 2.6, 4.0), Col = COLOR_VEG_SAGE_SHRUB },
        { Name = "FacadeBush_FrontEast", Pos = Vector3.new(16, 1.4, -58), Size = Vector3.new(3.8, 2.2, 3.6), Col = COLOR_VEG_DRY_THISTLE },
        -- Rear apse weed cluster
        { Name = "ApseWeeds_Back", Pos = Vector3.new(0, 1.6, 56), Size = Vector3.new(5.2, 2.8, 4.2), Col = COLOR_VEG_SAGE_SHRUB },
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
-- MAIN BUILD API: ChurchLandmarkBuilder.Build(options)
-- ============================================================================

function ChurchLandmarkBuilder.Build(opts: ChurchBuildOptions): Model
    local pos = opts.Position or CANONICAL_CHURCH_POSITION
    local rotY = opts.RotationY or 0
    local scale = opts.Scale or 1.0
    local seed = opts.Seed or 4001

    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or "IglesiaDeEpecuen"

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

    local primaryPart = buildChurchLandmark(model, rootCF, scale, opts, rng)

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

function ChurchLandmarkBuilder.GetMetrics(): {
    PartCount: number,
    FootprintStuds: Vector3,
    MaxHeightStuds: number,
    CanonicalPosition: Vector3,
}
    return {
        PartCount = 118, -- Exactly 118 native Roblox parts across all 9 folders
        FootprintStuds = Vector3.new(76, 48, 116),
        MaxHeightStuds = 48,
        CanonicalPosition = CANONICAL_CHURCH_POSITION,
    }
end

return ChurchLandmarkBuilder
