--!strict
--[[
    RailwayStationLandmarkBuilder.luau
    Location: ServerScriptService/RailwayStationLandmarkBuilder.luau

    Procedural Landmark Architecture Builder for the Ruined Railway Station of Villa Epecuén.
    Visual Reference: Ex-Estación de Ferrocarril Lago Epecuén (Ferrocarril Sarmiento / Ferrocarril del Sud,
                      Adolfo Alsina, Buenos Aires, Argentina).

    Canonical Map Reference:
      - Canonical Location: Position = Vector3.new(90, 16, -640)
      - Zone Context: Northern railway transit corridor (ZONE_NORTH_ENTRANCE / Hotel Colonia Ferroviaria)
      - Footprint: Approximately 88 x 60 studs
      - Maximum Vertical Height: Approximately 21 studs (Gabled roof ridge)

    Architectural & Historical Profile:
      The railway station of Lago Epecuén served as the principal artery through which tens of
      thousands of tourists arrived each summer from Buenos Aires to bathe in the hyper-mineralized,
      therapeutic saltwater lagoon. Built in classic provincial Argentine-British railway vernacular
      (masonry brick construction, horizontal proportions, rhythmic openings, and extended passenger platforms),
      the station was engulfed when the protective levee broke on November 10, 1985.
      Submerged for over two decades under 10 meters of brine, the ex-station emerged with:
        - Elongated masonry passenger building with high gabled zinc/timber roof.
        - Open central passenger waiting hall (sala de espera) accessible from both street and platform.
        - Station master office and ticket booth (boletería) with service counter and wicket opening.
        - Extended low passenger platform (andén) with stone coping curb edge.
        - Ruined covered veranda (galería techada) with cast-iron columns and hanging corrugated zinc sheets.
        - Broken railway signage board ("LAGO EPECUÉN") standing on weathered posts without image assets.
        - Trackbed remnants: sunken quebracho sleepers and twin corroded steel rails on ballast gravel.
        - Catastrophic structural trauma: partially collapsed roof exposing timber rafters, east wall breach.
        - Exposed Argentine fired red clay masonry where saline stucco peeled away.
        - Thick evaporite salt crust tide marks adhering to the lower walls, platform coping, and columns.
        - Rubble mounds of fallen masonry, fragmented tiles, and shattered roof trusses.
        - Desiccated petrified saltbushes and wild halophyte scrub sprouting from ballast and platform joints.

    Technical Constraints:
      - 100% native Roblox geometry: Part, WedgePart, and CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, plugins, lights, terrain, or NPCs.
      - ZERO automatic instantiation into Workspace on module require/load.
      - Fully deterministic through Random.new(seed).
      - Target budget: strictly ~100-160 parts (131 parts total).
      - Substantially open and walkable.
      - Organized into designated sub-folders:
          Foundation, Structure, Facade, Openings, Platform, Roof, Interior, Damage, Rubble, SaltCrust, Vegetation.
--]]

local RailwayStationLandmarkBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type RailwayStationBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    Parent: Instance?,
    DamageLevel: number?, -- 0.0 to 1.0 (default 0.75)
    SaltLevel: number?,   -- 0.0 to 1.0 (default 0.80)
    Seed: number?,
    Name: string?,
}

export type StationMetrics = {
    PartCount: number,
    FootprintStuds: Vector3,
    MaxHeightStuds: number,
    CanonicalPosition: Vector3,
    ComponentBreakdown: { [string]: number },
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

-- ============================================================================
-- COLOR & MATERIAL PALETTE (Villa Epecuén Railway Ruins)
-- ============================================================================

-- Stucco, Concrete & Weathered Plaster
local COLOR_STUCCO_WEATHERED    = Color3.fromRGB(188, 180, 166) -- Faded provincial railway cream/ochre stucco
local COLOR_STUCCO_SALTED       = Color3.fromRGB(202, 198, 188) -- Saline-bleached upper plaster
local COLOR_CONCRETE_PLINTH     = Color3.fromRGB(138, 132, 124) -- Base plinth concrete
local COLOR_CONCRETE_DARK       = Color3.fromRGB(112, 108, 100) -- Damp waterline-stained concrete
local COLOR_STONE_COPING        = Color3.fromRGB(124, 120, 114) -- Platform bullnose stone curb

-- Exposed Argentine Clay Masonry (Ladrillo Común Bonaerense)
local COLOR_BRICK_RED           = Color3.fromRGB(158, 82, 62)   -- Classic fired clay red brick
local COLOR_BRICK_EFFLORESCE    = Color3.fromRGB(142, 76, 58)   -- Salt-effloresced dark clay brick
local COLOR_MORTAR_RUBBLE       = Color3.fromRGB(156, 146, 134) -- Crumbled lime mortar and brick fragments

-- Mineral Salt Crusts & Evaporite Tide Marks
local COLOR_SALT_CRUST_WHITE    = Color3.fromRGB(250, 250, 246) -- Thick calcified mineral brine crust
local COLOR_SALT_TIDEMARK       = Color3.fromRGB(232, 234, 226) -- Evaporite high-water tide mark
local COLOR_SALT_SILT           = Color3.fromRGB(212, 214, 204) -- Saline sediment silt deposit

-- Corroded Metals & Structural Iron
local COLOR_IRON_RUST_HEAVY     = Color3.fromRGB(98, 52, 36)    -- Heavily oxidized rail steel
local COLOR_IRON_CAST_COLUMN    = Color3.fromRGB(68, 64, 60)    -- Weathered cast iron veranda column
local COLOR_ZINC_ROOF_RUST      = Color3.fromRGB(116, 82, 66)   -- Rusted corrugated zinc roof sheet

-- Weathered Timber & Sleepers (Quebracho & Pino Tea)
local COLOR_QUEBRACHO_SLEEPER   = Color3.fromRGB(76, 66, 56)    -- Dark durable Argentine quebracho railway tie
local COLOR_TIMBER_BLEACHED     = Color3.fromRGB(126, 120, 110) -- Brine-bleached timber truss
local COLOR_BENCH_WOOD          = Color3.fromRGB(112, 98, 84)   -- Passenger waiting bench wood

-- Paving & Ballast
local COLOR_FLOOR_FLAGSTONE     = Color3.fromRGB(130, 126, 118) -- Interior waiting room flagstone
local COLOR_BALLAST_GRAVEL      = Color3.fromRGB(108, 104, 98)  -- Crushed granite rail ballast

-- Dead Vegetation (Petrified Pampas Flora)
local COLOR_DEAD_STEM           = Color3.fromRGB(88, 80, 68)    -- Petrified saltbush wood
local COLOR_WITHERED_THISTLE    = Color3.fromRGB(128, 124, 92)  -- Bleached dry pampas thistle

-- Canonical Defaults
local CANONICAL_STATION_POSITION = Vector3.new(90, 16, -640)

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

local function localCF(rootCF: CFrame, localPos: Vector3, localAnglesDeg: Vector3?): CFrame
    local cf = rootCF * CFrame.new(localPos)
    if localAnglesDeg then
        cf = cf * CFrame.Angles(
            math.rad(localAnglesDeg.X),
            math.rad(localAnglesDeg.Y),
            math.rad(localAnglesDeg.Z)
        )
    end
    return cf
end

-- ============================================================================
-- MAIN BUILD IMPLEMENTATION
-- ============================================================================

local function buildRailwayStation(
    model: Model,
    rootCF: CFrame,
    opts: RailwayStationBuildOptions,
    rng: Random
): Part
    local damageLevel = math.clamp(opts.DamageLevel or 0.75, 0.0, 1.0)
    local saltLevel = math.clamp(opts.SaltLevel or 0.80, 0.0, 1.0)

    -- Deterministic variation parameters
    local saltColorBlend = COLOR_SALT_CRUST_WHITE:Lerp(COLOR_SALT_TIDEMARK, rng:NextNumber(0.0, 0.25) * saltLevel)
    local rubbleOffset = (damageLevel - 0.5) * 0.4

    -- ------------------------------------------------------------------------
    -- SUB-FOLDERS CREATION
    -- ------------------------------------------------------------------------
    local folderFoundation = Instance.new("Folder")
    folderFoundation.Name = "Foundation"
    folderFoundation.Parent = model

    local folderStructure = Instance.new("Folder")
    folderStructure.Name = "Structure"
    folderStructure.Parent = model

    local folderFacade = Instance.new("Folder")
    folderFacade.Name = "Facade"
    folderFacade.Parent = model

    local folderOpenings = Instance.new("Folder")
    folderOpenings.Name = "Openings"
    folderOpenings.Parent = model

    local folderPlatform = Instance.new("Folder")
    folderPlatform.Name = "Platform"
    folderPlatform.Parent = model

    local folderRoof = Instance.new("Folder")
    folderRoof.Name = "Roof"
    folderRoof.Parent = model

    local folderInterior = Instance.new("Folder")
    folderInterior.Name = "Interior"
    folderInterior.Parent = model

    local folderDamage = Instance.new("Folder")
    folderDamage.Name = "Damage"
    folderDamage.Parent = model

    local folderRubble = Instance.new("Folder")
    folderRubble.Name = "Rubble"
    folderRubble.Parent = model

    local folderSaltCrust = Instance.new("Folder")
    folderSaltCrust.Name = "SaltCrust"
    folderSaltCrust.Parent = model

    local folderVegetation = Instance.new("Folder")
    folderVegetation.Name = "Vegetation"
    folderVegetation.Parent = model

    -- ------------------------------------------------------------------------
    -- 1. FOUNDATION (8 parts)
    -- ------------------------------------------------------------------------
    local primaryPart = makePart(folderFoundation, {
        Name = "Foundation_MainSlab_West",
        Size = Vector3.new(28.0, 1.6, 22.0),
        CFrame = localCF(rootCF, Vector3.new(-13.0, 0.8, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_MainSlab_East",
        Size = Vector3.new(26.0, 1.6, 22.0),
        CFrame = localCF(rootCF, Vector3.new(14.0, 0.8, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_StreetTerrace",
        Size = Vector3.new(24.0, 1.2, 5.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.6, -13.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_StreetStep1",
        Size = Vector3.new(20.0, 0.6, 3.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.3, -17.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_InteriorTileBase_West",
        Size = Vector3.new(18.0, 0.2, 20.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 1.7, 0.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_FLOOR_FLAGSTONE,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_InteriorTileBase_Center",
        Size = Vector3.new(19.0, 0.2, 20.0),
        CFrame = localCF(rootCF, Vector3.new(2.5, 1.7, 0.0)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_FLOOR_FLAGSTONE,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_InteriorTileBase_East",
        Size = Vector3.new(13.0, 0.2, 20.0),
        CFrame = localCF(rootCF, Vector3.new(18.5, 1.7, 0.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_FLOOR_FLAGSTONE,
        CanCollide = true,
    })

    makePart(folderFoundation, {
        Name = "Foundation_BallastBed",
        Size = Vector3.new(86.0, 0.6, 12.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.3, 35.5)),
        Material = Enum.Material.Slate,
        Color = COLOR_BALLAST_GRAVEL,
        CanCollide = true,
    })

    -- ------------------------------------------------------------------------
    -- 2. STRUCTURE (16 parts)
    -- ------------------------------------------------------------------------
    makePart(folderStructure, {
        Name = "Structure_CornerPier_NW",
        Size = Vector3.new(2.5, 13.0, 2.5),
        CFrame = localCF(rootCF, Vector3.new(-24.75, 8.1, -9.75)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_CornerPier_SW",
        Size = Vector3.new(2.5, 13.0, 2.5),
        CFrame = localCF(rootCF, Vector3.new(-24.75, 8.1, 9.75)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_CornerPier_NE",
        Size = Vector3.new(2.5, 13.0, 2.5),
        CFrame = localCF(rootCF, Vector3.new(24.75, 8.1, -9.75)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_CornerPier_SE",
        Size = Vector3.new(2.5, 9.0, 2.5),
        CFrame = localCF(rootCF, Vector3.new(24.75, 6.1, 9.75)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Ticket_South",
        Size = Vector3.new(1.6, 13.0, 7.0),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 8.1, 6.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Ticket_North",
        Size = Vector3.new(1.6, 13.0, 7.0),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 8.1, -6.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Ticket_Lintel",
        Size = Vector3.new(1.6, 4.0, 6.0),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 12.6, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Parcel_North",
        Size = Vector3.new(1.6, 13.0, 7.0),
        CFrame = localCF(rootCF, Vector3.new(12.0, 8.1, -6.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Parcel_South",
        Size = Vector3.new(1.6, 13.0, 7.0),
        CFrame = localCF(rootCF, Vector3.new(12.0, 8.1, 6.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_Partition_Parcel_Lintel",
        Size = Vector3.new(1.6, 3.5, 6.0),
        CFrame = localCF(rootCF, Vector3.new(12.0, 12.85, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderStructure, {
        Name = "Structure_VerandaColumn_1",
        Size = Vector3.new(1.0, 10.0, 1.0),
        CFrame = localCF(rootCF, Vector3.new(-24.0, 6.8, 22.5)),
        Material = Enum.Material.Metal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    makePart(folderStructure, {
        Name = "Structure_VerandaColumn_2",
        Size = Vector3.new(1.0, 10.0, 1.0),
        CFrame = localCF(rootCF, Vector3.new(-8.0, 6.8, 22.5)),
        Material = Enum.Material.Metal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    makePart(folderStructure, {
        Name = "Structure_VerandaColumn_3",
        Size = Vector3.new(1.0, 10.0, 1.0),
        CFrame = localCF(rootCF, Vector3.new(8.0, 6.8, 22.5)),
        Material = Enum.Material.Metal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    makePart(folderStructure, {
        Name = "Structure_VerandaColumn_4",
        Size = Vector3.new(1.0, 7.0, 1.0),
        CFrame = localCF(rootCF, Vector3.new(24.0, 5.3, 22.5), Vector3.new(6.0, 0.0, -8.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makePart(folderStructure, {
        Name = "Structure_Veranda_Beam_West",
        Size = Vector3.new(33.0, 1.2, 1.2),
        CFrame = localCF(rootCF, Vector3.new(-8.5, 11.4, 22.5)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderStructure, {
        Name = "Structure_Veranda_Beam_East",
        Size = Vector3.new(17.0, 1.2, 1.2),
        CFrame = localCF(rootCF, Vector3.new(16.5, 11.4, 22.5)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    -- ------------------------------------------------------------------------
    -- 3. FACADE (14 parts)
    -- ------------------------------------------------------------------------
    makePart(folderFacade, {
        Name = "Facade_Street_Wall_West",
        Size = Vector3.new(14.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 8.1, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Street_Wall_CenterWest",
        Size = Vector3.new(4.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-6.0, 8.1, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Street_Wall_CenterEast",
        Size = Vector3.new(4.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(6.0, 8.1, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Street_Wall_East",
        Size = Vector3.new(14.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(16.0, 8.1, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Street_Cornice_Main",
        Size = Vector3.new(54.0, 1.0, 2.2),
        CFrame = localCF(rootCF, Vector3.new(0.0, 14.6, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderFacade, {
        Name = "Facade_Platform_Wall_West",
        Size = Vector3.new(14.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 8.1, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Platform_Wall_CenterWest",
        Size = Vector3.new(4.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-5.0, 8.1, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Platform_Wall_CenterEast",
        Size = Vector3.new(4.0, 13.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(7.0, 8.1, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Platform_Wall_East",
        Size = Vector3.new(12.0, 9.0, 1.6),
        CFrame = localCF(rootCF, Vector3.new(18.0, 6.1, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_Platform_Cornice",
        Size = Vector3.new(44.0, 0.8, 1.8),
        CFrame = localCF(rootCF, Vector3.new(-5.0, 14.6, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderFacade, {
        Name = "Facade_WestGable_Lower",
        Size = Vector3.new(1.6, 13.0, 20.0),
        CFrame = localCF(rootCF, Vector3.new(-25.2, 8.1, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makeWedge(folderFacade, {
        Name = "Facade_WestGable_Peak_South",
        Size = Vector3.new(1.6, 6.0, 10.0),
        CFrame = localCF(rootCF, Vector3.new(-25.2, 17.6, 5.0), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makeWedge(folderFacade, {
        Name = "Facade_WestGable_Peak_North",
        Size = Vector3.new(1.6, 6.0, 10.0),
        CFrame = localCF(rootCF, Vector3.new(-25.2, 17.6, -5.0), Vector3.new(0.0, 180.0, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderFacade, {
        Name = "Facade_EastGable_Standing",
        Size = Vector3.new(1.6, 10.0, 11.0),
        CFrame = localCF(rootCF, Vector3.new(25.2, 6.6, -4.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    -- ------------------------------------------------------------------------
    -- 4. OPENINGS (13 parts)
    -- ------------------------------------------------------------------------
    makePart(folderOpenings, {
        Name = "Opening_MainPortal_Lintel",
        Size = Vector3.new(8.0, 2.5, 2.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 11.85, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_MainPortal_Threshold",
        Size = Vector3.new(8.0, 0.4, 2.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 1.8, -10.2)),
        Material = Enum.Material.Slate,
        Color = COLOR_FLOOR_FLAGSTONE,
    })

    makePart(folderOpenings, {
        Name = "Opening_PlatformDoor_Lintel",
        Size = Vector3.new(8.0, 2.5, 2.0),
        CFrame = localCF(rootCF, Vector3.new(1.0, 11.85, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_PlatformDoor_Threshold",
        Size = Vector3.new(8.0, 0.4, 2.0),
        CFrame = localCF(rootCF, Vector3.new(1.0, 1.8, 10.2)),
        Material = Enum.Material.Slate,
        Color = COLOR_FLOOR_FLAGSTONE,
    })

    makePart(folderOpenings, {
        Name = "Opening_StreetWindow_West_Sill",
        Size = Vector3.new(4.5, 0.6, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 4.3, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_StreetWindow_West_Lintel",
        Size = Vector3.new(4.5, 0.8, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 10.6, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_StreetWindow_East_Sill",
        Size = Vector3.new(4.5, 0.6, 2.0),
        CFrame = localCF(rootCF, Vector3.new(16.0, 4.3, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_StreetWindow_East_Lintel",
        Size = Vector3.new(4.5, 0.8, 2.0),
        CFrame = localCF(rootCF, Vector3.new(16.0, 10.6, -10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_PlatformWindow_West_Sill",
        Size = Vector3.new(4.0, 0.6, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 4.3, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_PlatformWindow_West_Lintel",
        Size = Vector3.new(4.0, 0.8, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 10.6, 10.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_SALTED,
    })

    makePart(folderOpenings, {
        Name = "Opening_Ticket_CounterShelf",
        Size = Vector3.new(1.8, 0.5, 4.5),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 4.8, 0.0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderOpenings, {
        Name = "Opening_Ticket_GrilleFrame",
        Size = Vector3.new(1.6, 3.5, 0.4),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 6.8, -1.8)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderOpenings, {
        Name = "Opening_Ticket_GrilleTop",
        Size = Vector3.new(1.6, 0.4, 4.5),
        CFrame = localCF(rootCF, Vector3.new(-7.0, 8.6, 0.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    -- ------------------------------------------------------------------------
    -- 5. PLATFORM (17 parts)
    -- ------------------------------------------------------------------------
    makePart(folderPlatform, {
        Name = "Platform_Slab_West",
        Size = Vector3.new(28.0, 1.8, 19.0),
        CFrame = localCF(rootCF, Vector3.new(-28.0, 0.9, 19.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Slab_Center",
        Size = Vector3.new(28.0, 1.8, 19.0),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.9, 19.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Slab_East",
        Size = Vector3.new(28.0, 1.8, 19.0),
        CFrame = localCF(rootCF, Vector3.new(28.0, 0.9, 19.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Coping_West",
        Size = Vector3.new(28.0, 0.4, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-28.0, 1.9, 28.7)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STONE_COPING,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Coping_Center",
        Size = Vector3.new(28.0, 0.4, 1.6),
        CFrame = localCF(rootCF, Vector3.new(0.0, 1.9, 28.7)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STONE_COPING,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Coping_East",
        Size = Vector3.new(28.0, 0.4, 1.6),
        CFrame = localCF(rootCF, Vector3.new(28.0, 1.9, 28.7)),
        Material = Enum.Material.Cobblestone,
        Color = COLOR_STONE_COPING,
        CanCollide = true,
    })

    makeWedge(folderPlatform, {
        Name = "Platform_Step_WestEnd",
        Size = Vector3.new(3.0, 1.8, 8.0),
        CFrame = localCF(rootCF, Vector3.new(-42.5, 0.9, 20.0), Vector3.new(0.0, -90.0, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makeWedge(folderPlatform, {
        Name = "Platform_Step_EastEnd",
        Size = Vector3.new(3.0, 1.8, 8.0),
        CFrame = localCF(rootCF, Vector3.new(42.5, 0.9, 20.0), Vector3.new(0.0, 90.0, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PLINTH,
        CanCollide = true,
    })

    makePart(folderPlatform, {
        Name = "Platform_Rail_South",
        Size = Vector3.new(84.0, 0.6, 0.4),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.8, 33.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makePart(folderPlatform, {
        Name = "Platform_Rail_North",
        Size = Vector3.new(84.0, 0.6, 0.4),
        CFrame = localCF(rootCF, Vector3.new(0.0, 0.8, 37.8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makePart(folderPlatform, {
        Name = "Platform_Sleeper_1",
        Size = Vector3.new(1.2, 0.5, 7.5),
        CFrame = localCF(rootCF, Vector3.new(-30.0, 0.5, 35.4)),
        Material = Enum.Material.Wood,
        Color = COLOR_QUEBRACHO_SLEEPER,
    })

    makePart(folderPlatform, {
        Name = "Platform_Sleeper_2",
        Size = Vector3.new(1.2, 0.5, 7.5),
        CFrame = localCF(rootCF, Vector3.new(-10.0, 0.5, 35.4)),
        Material = Enum.Material.Wood,
        Color = COLOR_QUEBRACHO_SLEEPER,
    })

    makePart(folderPlatform, {
        Name = "Platform_Sleeper_3",
        Size = Vector3.new(1.2, 0.5, 7.5),
        CFrame = localCF(rootCF, Vector3.new(10.0, 0.5, 35.4)),
        Material = Enum.Material.Wood,
        Color = COLOR_QUEBRACHO_SLEEPER,
    })

    makePart(folderPlatform, {
        Name = "Platform_Sleeper_4",
        Size = Vector3.new(1.2, 0.5, 7.5),
        CFrame = localCF(rootCF, Vector3.new(30.0, 0.5, 35.4)),
        Material = Enum.Material.Wood,
        Color = COLOR_QUEBRACHO_SLEEPER,
    })

    makePart(folderPlatform, {
        Name = "Platform_StationSign_PostWest",
        Size = Vector3.new(0.6, 7.5, 0.6),
        CFrame = localCF(rootCF, Vector3.new(32.0, 4.65, 23.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderPlatform, {
        Name = "Platform_StationSign_PostEast",
        Size = Vector3.new(0.6, 7.5, 0.6),
        CFrame = localCF(rootCF, Vector3.new(38.0, 4.65, 23.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderPlatform, {
        Name = "Platform_StationSign_Board",
        Size = Vector3.new(7.6, 2.2, 0.3),
        CFrame = localCF(rootCF, Vector3.new(35.0, 7.0, 23.0)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    -- ------------------------------------------------------------------------
    -- 6. ROOF (12 parts)
    -- ------------------------------------------------------------------------
    makeWedge(folderRoof, {
        Name = "Roof_MainSlope_North_West",
        Size = Vector3.new(26.0, 6.0, 11.0),
        CFrame = localCF(rootCF, Vector3.new(-13.0, 17.6, -5.5), Vector3.new(0.0, 180.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makeWedge(folderRoof, {
        Name = "Roof_MainSlope_South_West",
        Size = Vector3.new(26.0, 6.0, 11.0),
        CFrame = localCF(rootCF, Vector3.new(-13.0, 17.6, 5.5), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makeWedge(folderRoof, {
        Name = "Roof_MainSlope_North_East",
        Size = Vector3.new(14.0, 6.0, 11.0),
        CFrame = localCF(rootCF, Vector3.new(19.0, 17.6, -5.5), Vector3.new(0.0, 180.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makePart(folderRoof, {
        Name = "Roof_Truss_Chord_1",
        Size = Vector3.new(0.6, 1.0, 20.5),
        CFrame = localCF(rootCF, Vector3.new(-18.0, 15.0, 0.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderRoof, {
        Name = "Roof_Truss_Chord_2",
        Size = Vector3.new(0.6, 1.0, 20.5),
        CFrame = localCF(rootCF, Vector3.new(-5.0, 15.0, 0.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderRoof, {
        Name = "Roof_Truss_Chord_3",
        Size = Vector3.new(0.6, 1.0, 20.5),
        CFrame = localCF(rootCF, Vector3.new(8.0, 15.0, 0.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderRoof, {
        Name = "Roof_RidgeBeam_West",
        Size = Vector3.new(28.0, 0.8, 0.8),
        CFrame = localCF(rootCF, Vector3.new(-12.0, 20.6, 0.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makeWedge(folderRoof, {
        Name = "Roof_Veranda_Canopy_West",
        Size = Vector3.new(20.0, 2.6, 12.0),
        CFrame = localCF(rootCF, Vector3.new(-14.0, 12.7, 16.5), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makeWedge(folderRoof, {
        Name = "Roof_Veranda_Canopy_Center",
        Size = Vector3.new(14.0, 2.6, 12.0),
        CFrame = localCF(rootCF, Vector3.new(3.0, 12.7, 16.5), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makeWedge(folderRoof, {
        Name = "Roof_Veranda_Bracket_1",
        Size = Vector3.new(0.4, 2.0, 3.0),
        CFrame = localCF(rootCF, Vector3.new(-24.0, 10.4, 21.0), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makeWedge(folderRoof, {
        Name = "Roof_Veranda_Bracket_2",
        Size = Vector3.new(0.4, 2.0, 3.0),
        CFrame = localCF(rootCF, Vector3.new(-8.0, 10.4, 21.0), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makeWedge(folderRoof, {
        Name = "Roof_Veranda_Bracket_3",
        Size = Vector3.new(0.4, 2.0, 3.0),
        CFrame = localCF(rootCF, Vector3.new(8.0, 10.4, 21.0), Vector3.new(0.0, 0.0, 0.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    -- ------------------------------------------------------------------------
    -- 7. INTERIOR (8 parts)
    -- ------------------------------------------------------------------------
    makePart(folderInterior, {
        Name = "Interior_WaitingBench_Seat",
        Size = Vector3.new(9.0, 0.4, 1.8),
        CFrame = localCF(rootCF, Vector3.new(3.0, 2.8, -8.5)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderInterior, {
        Name = "Interior_WaitingBench_Back",
        Size = Vector3.new(9.0, 1.6, 0.4),
        CFrame = localCF(rootCF, Vector3.new(3.0, 3.7, -9.2)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderInterior, {
        Name = "Interior_WaitingBench_Leg1",
        Size = Vector3.new(0.4, 1.0, 1.8),
        CFrame = localCF(rootCF, Vector3.new(-1.0, 2.2, -8.5)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    makePart(folderInterior, {
        Name = "Interior_WaitingBench_Leg2",
        Size = Vector3.new(0.4, 1.0, 1.8),
        CFrame = localCF(rootCF, Vector3.new(7.0, 2.2, -8.5)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    makePart(folderInterior, {
        Name = "Interior_TicketOffice_Desk",
        Size = Vector3.new(6.5, 2.6, 3.0),
        CFrame = localCF(rootCF, Vector3.new(-16.0, 3.0, -3.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderInterior, {
        Name = "Interior_TicketOffice_CabinetFallen",
        Size = Vector3.new(5.0, 1.5, 2.2),
        CFrame = localCF(rootCF, Vector3.new(-21.0, 2.4, 4.0), Vector3.new(5.0, -12.0, 8.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderInterior, {
        Name = "Interior_ParcelRoom_Shelf",
        Size = Vector3.new(7.0, 4.5, 1.4),
        CFrame = localCF(rootCF, Vector3.new(22.0, 4.0, -6.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    makePart(folderInterior, {
        Name = "Interior_TelegraphDesk_Board",
        Size = Vector3.new(3.5, 0.3, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-12.0, 3.2, 7.5)),
        Material = Enum.Material.Wood,
        Color = COLOR_BENCH_WOOD,
    })

    -- ------------------------------------------------------------------------
    -- 8. DAMAGE (11 parts)
    -- ------------------------------------------------------------------------
    makeCornerWedge(folderDamage, {
        Name = "Damage_EastWall_Breach_Corner",
        Size = Vector3.new(1.8, 4.0, 4.0),
        CFrame = localCF(rootCF, Vector3.new(25.2, 9.0, 2.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makeWedge(folderDamage, {
        Name = "Damage_EastWall_Breach_Jagg1",
        Size = Vector3.new(1.8, 3.5, 3.0),
        CFrame = localCF(rootCF, Vector3.new(25.2, 7.0, 6.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
    })

    makePart(folderDamage, {
        Name = "Damage_PeelingPlaster_Street1",
        Size = Vector3.new(5.0, 4.0, 0.3),
        CFrame = localCF(rootCF, Vector3.new(-14.0, 5.0, -9.3)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    makePart(folderDamage, {
        Name = "Damage_PeelingPlaster_Street2",
        Size = Vector3.new(4.0, 3.5, 0.3),
        CFrame = localCF(rootCF, Vector3.new(14.0, 4.5, -9.3)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EFFLORESCE,
    })

    makePart(folderDamage, {
        Name = "Damage_PeelingPlaster_Platform",
        Size = Vector3.new(6.0, 4.5, 0.3),
        CFrame = localCF(rootCF, Vector3.new(-14.0, 5.5, 9.3)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    makePart(folderDamage, {
        Name = "Damage_HangingCanopy_Beam",
        Size = Vector3.new(0.8, 0.8, 9.0),
        CFrame = localCF(rootCF, Vector3.new(18.0, 8.5, 20.0), Vector3.new(15.0, -10.0, 25.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderDamage, {
        Name = "Damage_Bent_SheetMetal1",
        Size = Vector3.new(3.5, 0.2, 4.0),
        CFrame = localCF(rootCF, Vector3.new(14.0, 9.2, 17.5), Vector3.new(-18.0, 12.0, 10.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makePart(folderDamage, {
        Name = "Damage_Bent_SheetMetal2",
        Size = Vector3.new(2.5, 0.2, 3.5),
        CFrame = localCF(rootCF, Vector3.new(22.0, 6.0, 18.0), Vector3.new(22.0, -15.0, 30.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ZINC_ROOF_RUST,
    })

    makePart(folderDamage, {
        Name = "Damage_WallCrack_West",
        Size = Vector3.new(0.4, 6.0, 0.4),
        CFrame = localCF(rootCF, Vector3.new(-25.2, 7.0, -4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(folderDamage, {
        Name = "Damage_ExposedRebar_East",
        Size = Vector3.new(0.3, 3.5, 0.3),
        CFrame = localCF(rootCF, Vector3.new(24.5, 9.5, 8.0), Vector3.new(10.0, 20.0, -15.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_RUST_HEAVY,
    })

    makePart(folderDamage, {
        Name = "Damage_SeveredLamp_Post",
        Size = Vector3.new(0.6, 7.0, 0.6),
        CFrame = localCF(rootCF, Vector3.new(-20.0, 5.3, 23.0), Vector3.new(-4.0, 0.0, 6.0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_IRON_CAST_COLUMN,
    })

    -- ------------------------------------------------------------------------
    -- 9. RUBBLE (13 parts)
    -- ------------------------------------------------------------------------
    makePart(folderRubble, {
        Name = "Rubble_Mound_EastCollapsed",
        Size = Vector3.new(7.0, 2.0, 8.0),
        CFrame = localCF(rootCF, Vector3.new(24.0 + rubbleOffset, 2.5, 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(folderRubble, {
        Name = "Rubble_Mound_CenterHall",
        Size = Vector3.new(5.5, 1.4, 5.0),
        CFrame = localCF(rootCF, Vector3.new(3.0, 2.3, 1.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(folderRubble, {
        Name = "Rubble_Mound_Platform",
        Size = Vector3.new(6.0, 1.2, 4.5),
        CFrame = localCF(rootCF, Vector3.new(18.0, 2.3, 16.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(folderRubble, {
        Name = "Rubble_Collapsed_TrussBeam1",
        Size = Vector3.new(0.8, 0.8, 14.0),
        CFrame = localCF(rootCF, Vector3.new(1.5, 4.5, 2.0), Vector3.new(-25.0, 15.0, -10.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderRubble, {
        Name = "Rubble_Collapsed_TrussBeam2",
        Size = Vector3.new(0.6, 0.6, 11.0),
        CFrame = localCF(rootCF, Vector3.new(5.0, 3.2, -1.0), Vector3.new(18.0, -30.0, 20.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_TIMBER_BLEACHED,
    })

    makePart(folderRubble, {
        Name = "Rubble_BrickCluster_1",
        Size = Vector3.new(2.5, 0.8, 2.0),
        CFrame = localCF(rootCF, Vector3.new(-4.0, 2.0, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    makePart(folderRubble, {
        Name = "Rubble_BrickCluster_2",
        Size = Vector3.new(2.8, 0.7, 2.2),
        CFrame = localCF(rootCF, Vector3.new(19.0, 2.0, 6.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_EFFLORESCE,
    })

    makePart(folderRubble, {
        Name = "Rubble_BrickCluster_3",
        Size = Vector3.new(2.0, 0.6, 1.8),
        CFrame = localCF(rootCF, Vector3.new(8.0, 2.0, 17.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    makePart(folderRubble, {
        Name = "Rubble_ConcreteBlock_1",
        Size = Vector3.new(2.2, 1.2, 1.8),
        CFrame = localCF(rootCF, Vector3.new(26.0, 1.5, 12.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makePart(folderRubble, {
        Name = "Rubble_ConcreteBlock_2",
        Size = Vector3.new(1.8, 1.0, 1.5),
        CFrame = localCF(rootCF, Vector3.new(-18.0, 2.2, 15.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    makeCornerWedge(folderRubble, {
        Name = "Rubble_CornerFragment",
        Size = Vector3.new(1.6, 1.2, 1.6),
        CFrame = localCF(rootCF, Vector3.new(21.0, 2.2, 7.5), Vector3.new(0.0, 45.0, 0.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_MORTAR_RUBBLE,
    })

    makePart(folderRubble, {
        Name = "Rubble_ShatteredTileScree",
        Size = Vector3.new(4.0, 0.3, 3.5),
        CFrame = localCF(rootCF, Vector3.new(-1.0, 1.85, -5.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_FLOOR_FLAGSTONE,
    })

    makePart(folderRubble, {
        Name = "Rubble_TrackBallastHeap",
        Size = Vector3.new(6.0, 0.8, 3.5),
        CFrame = localCF(rootCF, Vector3.new(20.0, 0.8, 34.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_BALLAST_GRAVEL,
    })

    -- ------------------------------------------------------------------------
    -- 10. SALT CRUST (11 parts)
    -- ------------------------------------------------------------------------
    makePart(folderSaltCrust, {
        Name = "SaltCrust_Waterline_Street_West",
        Size = Vector3.new(25.0, 2.2, 0.4),
        CFrame = localCF(rootCF, Vector3.new(-13.0, 2.8, -10.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_Waterline_Street_East",
        Size = Vector3.new(25.0, 2.2, 0.4),
        CFrame = localCF(rootCF, Vector3.new(13.0, 2.8, -10.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_Waterline_Platform_West",
        Size = Vector3.new(25.0, 2.2, 0.4),
        CFrame = localCF(rootCF, Vector3.new(-13.0, 2.8, 10.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_Waterline_Platform_East",
        Size = Vector3.new(20.0, 2.2, 0.4),
        CFrame = localCF(rootCF, Vector3.new(14.0, 2.8, 10.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_Waterline_WestGable",
        Size = Vector3.new(0.4, 2.2, 20.0),
        CFrame = localCF(rootCF, Vector3.new(-25.9, 2.8, 0.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_PlatformEdge_Shelf",
        Size = Vector3.new(36.0, 0.6, 0.8),
        CFrame = localCF(rootCF, Vector3.new(-10.0, 1.5, 29.8)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_InteriorShelf_Hall",
        Size = Vector3.new(10.0, 1.8, 0.3),
        CFrame = localCF(rootCF, Vector3.new(-2.0, 2.6, 9.8)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_FloorDeposit_Center",
        Size = Vector3.new(6.0, 0.15, 5.0),
        CFrame = localCF(rootCF, Vector3.new(5.0, 1.82, -3.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_TrackDeposit",
        Size = Vector3.new(18.0, 0.3, 4.0),
        CFrame = localCF(rootCF, Vector3.new(-5.0, 0.7, 35.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_ColumnRing_1",
        Size = Vector3.new(1.4, 1.2, 1.4),
        CFrame = localCF(rootCF, Vector3.new(-8.0, 2.2, 22.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    makePart(folderSaltCrust, {
        Name = "SaltCrust_ColumnRing_2",
        Size = Vector3.new(1.4, 1.2, 1.4),
        CFrame = localCF(rootCF, Vector3.new(8.0, 2.2, 22.5)),
        Material = Enum.Material.SmoothPlastic,
        Color = saltColorBlend,
        CanCollide = false,
    })

    -- ------------------------------------------------------------------------
    -- 11. VEGETATION (8 parts)
    -- ------------------------------------------------------------------------
    makePart(folderVegetation, {
        Name = "Veg_DeadShrub_PlatformWest_Stem",
        Size = Vector3.new(0.6, 3.5, 0.6),
        CFrame = localCF(rootCF, Vector3.new(-36.0, 3.2, 18.0), Vector3.new(-8.0, 15.0, 12.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_DEAD_STEM,
    })

    makePart(folderVegetation, {
        Name = "Veg_DeadShrub_PlatformWest_Twig",
        Size = Vector3.new(1.8, 0.4, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-36.0, 4.8, 18.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_WITHERED_THISTLE,
    })

    makePart(folderVegetation, {
        Name = "Veg_DeadShrub_Track_Stem",
        Size = Vector3.new(0.5, 2.8, 0.5),
        CFrame = localCF(rootCF, Vector3.new(14.0, 1.8, 37.5), Vector3.new(10.0, -8.0, -6.0)),
        Material = Enum.Material.Wood,
        Color = COLOR_DEAD_STEM,
    })

    makePart(folderVegetation, {
        Name = "Veg_DeadShrub_Track_Twig",
        Size = Vector3.new(1.5, 0.4, 1.5),
        CFrame = localCF(rootCF, Vector3.new(14.0, 3.0, 37.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_WITHERED_THISTLE,
    })

    makePart(folderVegetation, {
        Name = "Veg_DryThistle_Street_1",
        Size = Vector3.new(1.6, 1.2, 1.6),
        CFrame = localCF(rootCF, Vector3.new(-18.0, 1.6, -15.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_WITHERED_THISTLE,
    })

    makePart(folderVegetation, {
        Name = "Veg_DryThistle_Street_2",
        Size = Vector3.new(1.4, 1.0, 1.4),
        CFrame = localCF(rootCF, Vector3.new(12.0, 1.5, -15.0)),
        Material = Enum.Material.Slate,
        Color = COLOR_WITHERED_THISTLE,
    })

    makePart(folderVegetation, {
        Name = "Veg_HalophyteScrub_Rubble",
        Size = Vector3.new(2.2, 0.9, 1.8),
        CFrame = localCF(rootCF, Vector3.new(23.0, 3.2, 3.5)),
        Material = Enum.Material.Grass,
        Color = COLOR_WITHERED_THISTLE,
    })

    makePart(folderVegetation, {
        Name = "Veg_PlatformCrack_Weeds",
        Size = Vector3.new(3.0, 0.3, 0.8),
        CFrame = localCF(rootCF, Vector3.new(-12.0, 1.9, 21.0)),
        Material = Enum.Material.Grass,
        Color = COLOR_WITHERED_THISTLE,
    })

    return primaryPart
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function RailwayStationLandmarkBuilder.Build(options: RailwayStationBuildOptions?): Model
    local opts = options or {}
    local pos = opts.Position or CANONICAL_STATION_POSITION
    local rotY = opts.RotationY or 0
    local seed = opts.Seed or 5001
    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or "EstacionFerrocarrilEpecuen"

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    local primaryPart = buildRailwayStation(model, rootCF, opts, rng)

    if primaryPart then
        model.PrimaryPart = primaryPart
    end

    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

function RailwayStationLandmarkBuilder.GetMetrics(): StationMetrics
    return {
        PartCount = 131,
        FootprintStuds = Vector3.new(88.0, 21.0, 60.0),
        MaxHeightStuds = 21.0,
        CanonicalPosition = CANONICAL_STATION_POSITION,
        ComponentBreakdown = {
            Foundation = 8,
            Structure = 16,
            Facade = 14,
            Openings = 13,
            Platform = 17,
            Roof = 12,
            Interior = 8,
            Damage = 11,
            Rubble = 13,
            SaltCrust = 11,
            Vegetation = 8,
        },
    }
end

return RailwayStationLandmarkBuilder
