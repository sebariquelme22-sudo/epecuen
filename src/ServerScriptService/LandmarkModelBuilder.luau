--!strict
--[[
    LandmarkModelBuilder.luau
    Location: ServerScriptService/LandmarkModelBuilder.luau

    Procedural Landmark Architecture Builder for "EPECUÉN: NO ESCAPE".
    Visual Reference: Villa Epecuén (Adolfo Alsina, Buenos Aires Province, Argentina).

    Historical Reference - Hotel Monte Real (Residencial Monte Real):
      One of Epecuén's premier grand thermal spa hotels. Before November 1985,
      it offered luxury accommodations, mud therapy, private dining rooms, and
      expansive sun terraces.
      Submerged under 10 meters of hyper-saline lagoon water for a quarter-century,
      it emerged as an iconic monument to the disaster:
        - Broad, two-story horizontal Argentine mid-century resort facade (~92 x 46 studs).
        - Ground floor covered portico with a colonnade of weathered concrete pillars.
        - Long first-floor guest room balcony terrace with repeated window apertures.
        - Asymmetrical catastrophic structural failure: Eastern guest wing suffered heavy
          roof and second-floor slab collapse, with sheared masonry and exposed beams.
        - Central grand entrance with stepped podium and reception ruins.
        - Peeling plaster revealing Argentine red brickwork (ladrillo común bonaerense).
        - Calcified salt brine crusts and waterline deposits blanketing the foundation.
        - Heavy piles of crumbled concrete, fallen lintels, and clay brick debris.

    Technical Constraints:
      - 100% native Roblox geometry: Part (Block, Cylinder), WedgePart, CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, sounds, AI, or ProximityPrompts.
      - ZERO automatic instantiation into Workspace on module require/load.
      - Fully deterministic through Random.new(seed).
      - Optimized budget: strictly ~100-180 parts for the complete landmark (~142 parts).
      - Organized into designated sub-folders:
          Foundation, Structure, Facade, Windows, InteriorFragments, Damage, Rubble, SaltCrust.
--]]

local LandmarkModelBuilder = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type LandmarkType = "HotelMonteReal"

export type LandmarkBuildOptions = {
    LandmarkType: LandmarkType,
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
-- AUTHENTIC COLOR & MATERIAL PALETTE (Villa Epecuén Hotel Ruins)
-- ============================================================================

-- Argentine Stucco, Concrete & Mortar
local COLOR_STUCCO_WEATHERED    = Color3.fromRGB(168, 164, 154) -- Weathered saline exterior plaster
local COLOR_STUCCO_AGED_WARM    = Color3.fromRGB(182, 178, 166) -- Sun-faded cream facade finish
local COLOR_CONCRETE_CORE       = Color3.fromRGB(142, 138, 130) -- Structural reinforced concrete
local COLOR_CONCRETE_DARK       = Color3.fromRGB(116, 112, 106) -- Damp waterline-stained concrete

-- Exposed Clay Masonry
local COLOR_BRICK_RED           = Color3.fromRGB(162, 88, 68)   -- Ladrillo común bonaerense
local COLOR_BRICK_DARK          = Color3.fromRGB(132, 70, 54)   -- Submerged brick core
local COLOR_BRICK_MORTAR_MIX    = Color3.fromRGB(152, 114, 98)  -- Crumbled brick/mortar slurry

-- Mineral Salt Crusts & Waterline Brine
local COLOR_SALT_CRYSTAL_WHITE  = Color3.fromRGB(250, 250, 246) -- Pure mineral crust deposit
local COLOR_SALT_OFFWHITE       = Color3.fromRGB(234, 236, 228) -- Thick calcified brine shelf
local COLOR_SALT_SILT_BLEND     = Color3.fromRGB(214, 216, 206) -- Mineral tide-line deposit

-- Corroded Metals & Structural Rebar
local COLOR_RUST_FLAKING        = Color3.fromRGB(120, 62, 40)   -- Corroded rebar / metal lintel
local COLOR_RUST_DARK           = Color3.fromRGB(82, 46, 32)    -- Heavily oxidized iron

-- Weathered Timber & Floor Tile Fragments
local COLOR_DECAYED_WOOD        = Color3.fromRGB(110, 102, 92)  -- Bleached broken floor joist
local COLOR_TERRACOTTA_TILE     = Color3.fromRGB(148, 86, 62)   -- Spanish terrace floor tile

-- ============================================================================
-- PRIMITIVE CONSTRUCTORS (100% NATIVE GEOMETRY, ANCHORED)
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
-- HOTEL MONTE REAL BUILDER
-- ============================================================================
-- Coordinates Reference Frame:
--   - Width (X): 92 studs (-46 to +46)
--       * West Wing: X = -46 to -12 (relatively intact 2-story hotel facade)
--       * Central Portal: X = -12 to +12 (double-height entrance, portico, steps)
--       * East Wing: X = +12 to +46 (collapsed 2nd floor, sheared slab, rubble)
--   - Depth (Z): 44 studs (-22 to +22)
--       * Portico / Veranda: Z = +14 to +22
--       * Main Hotel Body: Z = -22 to +14
--   - Height (Y): 28 studs (0 to 28)
--       * Foundation Podium: Y = 0 to 1.8
--       * Ground Floor: Y = 1.8 to 13.5
--       * Second Floor & Balcony: Y = 13.5 to 24.5
--       * Roof Parapet & Cornice: Y = 24.5 to 27.5
-- Budget: ~142 parts
local function buildHotelMonteReal(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: LandmarkBuildOptions,
    rng: Random
): Part
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fStructure  = getOrCreateFolder(model, "Structure")
    local fFacade     = getOrCreateFolder(model, "Facade")
    local fWindows    = getOrCreateFolder(model, "Windows")
    local fInterior   = getOrCreateFolder(model, "InteriorFragments")
    local fDamage     = getOrCreateFolder(model, "Damage")
    local fRubble     = getOrCreateFolder(model, "Rubble")
    local fSaltCrust  = getOrCreateFolder(model, "SaltCrust")

    local damageLvl = opts.DamageLevel or 0.75
    local saltLvl   = opts.SaltLevel or 0.80

    -- ------------------------------------------------------------------------
    -- 1. FOUNDATION (Podium, Portico Slab, Entrance Stairs, Terrace Floor) [9 parts]
    -- ------------------------------------------------------------------------
    -- Main hotel foundation podium
    local primaryBasePart = makePart(fFoundation, {
        Name = "MainFoundationPodium",
        Size = Vector3.new(94 * scale, 1.8 * scale, 46 * scale),
        CFrame = rootCF * CFrame.new(0, 0.9 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Front Portico / Veranda raised terrace slab
    makePart(fFoundation, {
        Name = "PorticoTerraceSlab",
        Size = Vector3.new(94 * scale, 0.6 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(0, 1.5 * scale, 18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_TERRACOTTA_TILE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Central Grand Entrance Steps (stepped down to street level)
    makePart(fFoundation, {
        Name = "EntranceStep_Lower",
        Size = Vector3.new(24 * scale, 0.6 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(0, 0.3 * scale, 24 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFoundation, {
        Name = "EntranceStep_Upper",
        Size = Vector3.new(20 * scale, 0.6 * scale, 3 * scale),
        CFrame = rootCF * CFrame.new(0, 0.9 * scale, 21.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Sub-foundation mud & silt skirt (tide-eroded base)
    makePart(fFoundation, {
        Name = "ErodedFoundationSkirt_West",
        Size = Vector3.new(48 * scale, 0.8 * scale, 48 * scale),
        CFrame = rootCF * CFrame.new(-24 * scale, 0.4 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFoundation, {
        Name = "ErodedFoundationSkirt_East",
        Size = Vector3.new(48 * scale, 0.8 * scale, 48 * scale),
        CFrame = rootCF * CFrame.new(24 * scale, 0.4 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Rear service apron (kitchen / boiler access lane)
    makePart(fFoundation, {
        Name = "RearServiceApron",
        Size = Vector3.new(46 * scale, 0.6 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 0.5 * scale, -25 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Foundation corner erosion wedges (showing brine undercutting)
    makeWedge(fFoundation, {
        Name = "FoundationUndercut_SW",
        Size = Vector3.new(4 * scale, 1.2 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-45 * scale, 0.6 * scale, 21 * scale) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })
    makeWedge(fFoundation, {
        Name = "FoundationUndercut_SE",
        Size = Vector3.new(4 * scale, 1.2 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(45 * scale, 0.6 * scale, 21 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- ------------------------------------------------------------------------
    -- 2. STRUCTURE (Columns, Beams, Floor Slabs, Roof Slab, Rafters) [26 parts]
    -- ------------------------------------------------------------------------
    -- Ground floor front portico columns (6 reinforced concrete pillars)
    local colXPositions = { -42, -26, -10, 10, 26, 42 }
    for i, cx in ipairs(colXPositions) do
        -- Eastmost column is broken/partially collapsed due to asymmetrical damage
        local colHeight = if (i == 6 and damageLvl > 0.6) then 6.5 * scale else 12.0 * scale
        local colY = 1.8 * scale + colHeight * 0.5
        local colColor = if i >= 5 then COLOR_CONCRETE_DARK else COLOR_CONCRETE_CORE

        makePart(fStructure, {
            Name = string.format("PorticoColumn_%d", i),
            Size = Vector3.new(1.8 * scale, colHeight, 1.8 * scale),
            CFrame = rootCF * CFrame.new(cx * scale, colY, 22 * scale),
            Material = Enum.Material.Concrete,
            Color = colColor,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Portico lintel beam running horizontally across front columns (West & Center intact)
    makePart(fStructure, {
        Name = "PorticoBeam_WestCenter",
        Size = Vector3.new(62 * scale, 1.4 * scale, 2.2 * scale),
        CFrame = rootCF * CFrame.new(-16 * scale, 13.5 * scale, 22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Sheared portico lintel beam on East wing
    makePart(fStructure, {
        Name = "PorticoBeam_EastDamaged",
        Size = Vector3.new(20 * scale, 1.2 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(25 * scale, 13.2 * scale, 22 * scale) * CFrame.Angles(0, 0, math.rad(-6)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Intermediate floor dividing slab (First floor ceiling / Second floor deck)
    -- West section intact
    makePart(fStructure, {
        Name = "SecondFloorDeck_West",
        Size = Vector3.new(52 * scale, 1.0 * scale, 44 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 13.5 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    -- East section fractured / sheared (slanted collapsed slab fragment)
    makePart(fStructure, {
        Name = "SecondFloorDeck_EastFractured",
        Size = Vector3.new(34 * scale, 0.9 * scale, 38 * scale),
        CFrame = rootCF * CFrame.new(26 * scale, 11.2 * scale, -2 * scale) * CFrame.Angles(0, 0, math.rad(-14)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Upper floor front balcony terrace slab (running along West and Center)
    makePart(fStructure, {
        Name = "BalconyTerraceSlab_West",
        Size = Vector3.new(58 * scale, 0.6 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(-18 * scale, 13.8 * scale, 18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_TERRACOTTA_TILE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Balcony parapet/railing wall (West intact, missing on collapsed East)
    makePart(fStructure, {
        Name = "BalconyRailingWall_West",
        Size = Vector3.new(56 * scale, 2.4 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(-19 * scale, 15.3 * scale, 21.6 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })

    -- Upper roof deck (West half preserved, East half open / caved in)
    makePart(fStructure, {
        Name = "RoofDeck_WestPreserved",
        Size = Vector3.new(52 * scale, 1.0 * scale, 44 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 25.0 * scale, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Interior load-bearing concrete pillar grid (6 pillars)
    local interiorPillars = {
        Vector3.new(-28, 7.5, -6),
        Vector3.new(-12, 7.5, -6),
        Vector3.new(12, 7.5, -6),
        Vector3.new(28, 6.0, -6), -- Damaged eastern pillar
        Vector3.new(-28, 19.5, -6), -- Second floor pillar west
        Vector3.new(-12, 19.5, -6), -- Second floor pillar center
    }
    for idx, pPos in ipairs(interiorPillars) do
        local pH = if idx == 4 then 8.0 * scale else 11.0 * scale
        makePart(fStructure, {
            Name = string.format("InteriorPillar_%d", idx),
            Size = Vector3.new(2.0 * scale, pH, 2.0 * scale),
            CFrame = rootCF * CFrame.new(pPos.X * scale, pPos.Y * scale, pPos.Z * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_CORE,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Exposed roof ceiling joist rafters under West roof slab
    local joistZOffsets = { -14, -6, 2, 10 }
    for jIdx, jz in ipairs(joistZOffsets) do
        makePart(fStructure, {
            Name = string.format("RoofJoistBeam_%d", jIdx),
            Size = Vector3.new(48 * scale, 0.6 * scale, 0.8 * scale),
            CFrame = rootCF * CFrame.new(-22 * scale, 24.3 * scale, jz * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_DARK,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Transverse structural tie beams
    makePart(fStructure, {
        Name = "TransverseTieBeam_West",
        Size = Vector3.new(1.0 * scale, 1.0 * scale, 34 * scale),
        CFrame = rootCF * CFrame.new(-20 * scale, 13.5 * scale, -3 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fStructure, {
        Name = "TransverseTieBeam_Center",
        Size = Vector3.new(1.0 * scale, 1.0 * scale, 34 * scale),
        CFrame = rootCF * CFrame.new(0, 13.5 * scale, -3 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- ------------------------------------------------------------------------
    -- 3. FACADE (Ground Floor Walls, Upper Floor Walls, Parapet, Portal) [25 parts]
    -- ------------------------------------------------------------------------
    -- 3.1 Ground Floor Front Facade (Z = 13.5)
    -- West wing solid piers and entrance opening
    makePart(fFacade, {
        Name = "GroundFacade_WestCorner",
        Size = Vector3.new(6 * scale, 12 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-43 * scale, 7.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "GroundFacade_WestSpandrel",
        Size = Vector3.new(30 * scale, 4.0 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-26 * scale, 11.5 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "GroundFacade_WestBase",
        Size = Vector3.new(30 * scale, 2.5 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-26 * scale, 3.0 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })

    -- Central Grand Entrance Portal (Double door opening flanked by piers)
    makePart(fFacade, {
        Name = "EntrancePortalPier_Left",
        Size = Vector3.new(3.0 * scale, 12 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(-6.5 * scale, 7.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "EntrancePortalPier_Right",
        Size = Vector3.new(3.0 * scale, 12 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(6.5 * scale, 7.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "EntrancePortalArchitrave",
        Size = Vector3.new(16 * scale, 3.5 * scale, 2.2 * scale),
        CFrame = rootCF * CFrame.new(0, 11.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })

    -- East Wing Ground Facade (Breached / crumbled wall section)
    makePart(fFacade, {
        Name = "GroundFacade_EastBaseStub",
        Size = Vector3.new(22 * scale, 4.0 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 3.8 * scale, 13.5 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "GroundFacade_EastCornerPier",
        Size = Vector3.new(6 * scale, 8 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(43 * scale, 5.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- 3.2 Second Floor Front Facade (Guest rooms row)
    makePart(fFacade, {
        Name = "UpperFacade_WestSpandrelTop",
        Size = Vector3.new(50 * scale, 2.8 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-21 * scale, 23.6 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "UpperFacade_WestSpandrelBase",
        Size = Vector3.new(50 * scale, 2.0 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-21 * scale, 15.0 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })

    -- Central decorative Art Deco crowning pediment ("MONTE REAL" architectural crest)
    makePart(fFacade, {
        Name = "HotelMonteReal_CentralPediment",
        Size = Vector3.new(18 * scale, 3.5 * scale, 1.8 * scale),
        CFrame = rootCF * CFrame.new(0, 26.8 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "HotelMonteReal_ParapetCornice_West",
        Size = Vector3.new(36 * scale, 1.8 * scale, 1.6 * scale),
        CFrame = rootCF * CFrame.new(-26 * scale, 26.0 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "ArtDecoFinialPost_West",
        Size = Vector3.new(1.4 * scale, 2.6 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-45 * scale, 27.2 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "ArtDecoFinialPost_Center",
        Size = Vector3.new(1.4 * scale, 2.6 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(0, 29.0 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })

    -- 3.3 Side Exterior Walls (East & West gables)
    -- West Gable Wall (Fully standing, salt eroded at base)
    makePart(fFacade, {
        Name = "ExteriorWall_WestGable_Lower",
        Size = Vector3.new(1.6 * scale, 12 * scale, 36 * scale),
        CFrame = rootCF * CFrame.new(-46 * scale, 7.8 * scale, -4 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "ExteriorWall_WestGable_Upper",
        Size = Vector3.new(1.6 * scale, 11 * scale, 36 * scale),
        CFrame = rootCF * CFrame.new(-46 * scale, 19.5 * scale, -4 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_AGED_WARM,
        CanCollide = true,
        CastShadow = true,
    })

    -- Peeling plaster patch on West gable revealing red Argentine brick
    makePart(fFacade, {
        Name = "ExposedBrickPatch_WestGable",
        Size = Vector3.new(0.2 * scale, 5.0 * scale, 10 * scale),
        CFrame = rootCF * CFrame.new(-46.9 * scale, 14.5 * scale, -6 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = false,
        CastShadow = true,
    })

    -- East Gable Wall (Partially collapsed down to jagged angled height)
    makePart(fFacade, {
        Name = "ExteriorWall_EastGable_IntactBase",
        Size = Vector3.new(1.6 * scale, 8 * scale, 36 * scale),
        CFrame = rootCF * CFrame.new(46 * scale, 5.8 * scale, -4 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })
    makeWedge(fFacade, {
        Name = "ExteriorWall_EastGable_CollapsedSlope",
        Size = Vector3.new(1.6 * scale, 9 * scale, 24 * scale),
        CFrame = rootCF * CFrame.new(46 * scale, 14.3 * scale, -4 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- 3.4 Rear Exterior Wall (Z = -22, facing service alley / courtyard)
    makePart(fFacade, {
        Name = "RearWall_West_Lower",
        Size = Vector3.new(48 * scale, 12 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 7.8 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "RearWall_West_Upper",
        Size = Vector3.new(48 * scale, 11 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 19.5 * scale, -22 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fFacade, {
        Name = "RearWall_East_BreachedBase",
        Size = Vector3.new(44 * scale, 6 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(24 * scale, 4.8 * scale, -22 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })

    -- Balcony guest room doorway openings (connecting 2nd floor rooms to balcony)
    local doorXOffsets = { -36, -20, -4 }
    for dIdx, dx in ipairs(doorXOffsets) do
        makePart(fFacade, {
            Name = string.format("BalconyDoorwayOpening_%d", dIdx),
            Size = Vector3.new(3.0 * scale, 6.2 * scale, 1.4 * scale),
            CFrame = rootCF * CFrame.new(dx * scale, 17.1 * scale, 13.5 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_DARK,
            CanCollide = false,
            CastShadow = true,
        })
    end

    -- ------------------------------------------------------------------------
    -- 4. WINDOWS (Repeated Hotel Room Openings, Lintel & Sill Details) [24 parts]
    -- ------------------------------------------------------------------------
    -- Upper floor guest room window openings (repeated vertical mullions & sills)
    local upperWindowX = { -40, -32, -24, -16, -8, 0, 8 }
    for idx, wx in ipairs(upperWindowX) do
        -- Vertical window pier separator
        makePart(fWindows, {
            Name = string.format("UpperWindowPier_%d", idx),
            Size = Vector3.new(2.2 * scale, 6.6 * scale, 1.6 * scale),
            CFrame = rootCF * CFrame.new((wx + 4) * scale, 19.3 * scale, 13.5 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_STUCCO_WEATHERED,
            CanCollide = true,
            CastShadow = true,
        })
        -- Concrete window sill protruding below opening
        makePart(fWindows, {
            Name = string.format("UpperWindowSill_%d", idx),
            Size = Vector3.new(5.8 * scale, 0.4 * scale, 1.8 * scale),
            CFrame = rootCF * CFrame.new(wx * scale, 16.0 * scale, 13.6 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_DARK,
            CanCollide = true,
            CastShadow = true,
        })
        -- Decayed/broken wooden frame fragment inside window (glass long gone)
        if idx % 2 == 1 then
            makePart(fWindows, {
                Name = string.format("BrokenMullion_%d", idx),
                Size = Vector3.new(0.3 * scale, 4.5 * scale, 0.3 * scale),
                CFrame = rootCF * CFrame.new(wx * scale, 19.0 * scale, 13.5 * scale) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))),
                Material = Enum.Material.Wood,
                Color = COLOR_DECAYED_WOOD,
                CanCollide = false,
                CastShadow = true,
            })
        end
    end

    -- Ground floor dining salon large window apertures
    local groundWindowX = { -35, -23, -15 }
    for idx, gx in ipairs(groundWindowX) do
        makePart(fWindows, {
            Name = string.format("GroundSalonPier_%d", idx),
            Size = Vector3.new(2.5 * scale, 5.0 * scale, 1.6 * scale),
            CFrame = rootCF * CFrame.new((gx + 4) * scale, 7.0 * scale, 13.5 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_STUCCO_WEATHERED,
            CanCollide = true,
            CastShadow = true,
        })
        makePart(fWindows, {
            Name = string.format("GroundSalonSill_%d", idx),
            Size = Vector3.new(5.5 * scale, 0.5 * scale, 1.8 * scale),
            CFrame = rootCF * CFrame.new(gx * scale, 4.5 * scale, 13.6 * scale),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_DARK,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- ------------------------------------------------------------------------
    -- 5. INTERIOR FRAGMENTS (Reception Counter, Corridor Walls, Stair Landing) [13 parts]
    -- ------------------------------------------------------------------------
    -- Reception foyer desk ruin (curved/angular Argentine hotel counter)
    makePart(fInterior, {
        Name = "ReceptionDeskFront",
        Size = Vector3.new(10 * scale, 3.2 * scale, 1.6 * scale),
        CFrame = rootCF * CFrame.new(0, 3.4 * scale, 4 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fInterior, {
        Name = "ReceptionDeskTop",
        Size = Vector3.new(10.8 * scale, 0.4 * scale, 2.2 * scale),
        CFrame = rootCF * CFrame.new(0, 5.2 * scale, 4 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Central corridor spine wall (dividing guest rooms from rear services)
    makePart(fInterior, {
        Name = "CorridorSpineWall_West",
        Size = Vector3.new(44 * scale, 10 * scale, 1.0 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 6.8 * scale, -4 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fInterior, {
        Name = "CorridorSpineWall_EastRuined",
        Size = Vector3.new(26 * scale, 5.0 * scale, 1.0 * scale),
        CFrame = rootCF * CFrame.new(20 * scale, 4.3 * scale, -4 * scale),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Room partition wall stubs (transverse dividers)
    local roomStubs = { -34, -20, -6, 14, 28 }
    for idx, rx in ipairs(roomStubs) do
        local rH = if rx > 10 then 4.0 * scale else 8.5 * scale
        makePart(fInterior, {
            Name = string.format("RoomPartitionStub_%d", idx),
            Size = Vector3.new(1.0 * scale, rH, 12 * scale),
            CFrame = rootCF * CFrame.new(rx * scale, 1.8 * scale + rH * 0.5, 2 * scale),
            Material = Enum.Material.Brick,
            Color = COLOR_BRICK_RED,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Grand staircase landing fragment (concrete flight leading to broken 2nd floor)
    makeWedge(fInterior, {
        Name = "GrandStairFlight",
        Size = Vector3.new(6 * scale, 7.0 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 5.3 * scale, -12 * scale) * CFrame.Angles(0, math.rad(180), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fInterior, {
        Name = "StairLandingPlatform",
        Size = Vector3.new(8 * scale, 0.8 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 8.8 * scale, -18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Office safe alcove behind reception desk
    makePart(fInterior, {
        Name = "OfficeSafeAlcoveWall",
        Size = Vector3.new(6 * scale, 7.0 * scale, 1.0 * scale),
        CFrame = rootCF * CFrame.new(3 * scale, 5.3 * scale, -1.0 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })
    makePart(fInterior, {
        Name = "RustedKeyCabinetFragment",
        Size = Vector3.new(3 * scale, 4.0 * scale, 0.4 * scale),
        CFrame = rootCF * CFrame.new(3 * scale, 5.8 * scale, -0.4 * scale),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
        CanCollide = false,
        CastShadow = true,
    })

    -- ------------------------------------------------------------------------
    -- 6. DAMAGE (Sheared Gables, Caved Roof Wedges, Hanging Joists, Bent Rebar) [12 parts]
    -- ------------------------------------------------------------------------
    -- Caved-in roof slab wedged into upper East wing
    makeWedge(fDamage, {
        Name = "CollapsedRoofSlabSlope",
        Size = Vector3.new(28 * scale, 8.0 * scale, 26 * scale),
        CFrame = rootCF * CFrame.new(25 * scale, 18.0 * scale, 0) * CFrame.Angles(0, math.rad(-90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Jagged sheared wall fracture wedge on East upper facade
    makeWedge(fDamage, {
        Name = "ShearedFacadeFracture",
        Size = Vector3.new(12 * scale, 7.0 * scale, 1.8 * scale),
        CFrame = rootCF * CFrame.new(16 * scale, 19.5 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Exposed rusted structural rebar rods poking out of sheared concrete
    local rebarPositions = {
        Vector3.new(12, 14.5, 21),
        Vector3.new(22, 13.0, 22),
        Vector3.new(34, 11.5, 20),
        Vector3.new(18, 22.0, 13.5),
        Vector3.new(30, 15.0, -10),
    }
    for idx, rbPos in ipairs(rebarPositions) do
        local pitch = math.rad(rng:NextNumber(-30, 30))
        local yaw = math.rad(rng:NextNumber(0, 360))
        makePart(fDamage, {
            Name = string.format("ExposedRebarRod_%d", idx),
            Size = Vector3.new(0.25 * scale, 3.5 * scale, 0.25 * scale),
            CFrame = rootCF * CFrame.new(rbPos.X * scale, rbPos.Y * scale, rbPos.Z * scale) * CFrame.Angles(pitch, yaw, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = false,
            CastShadow = true,
        })
    end

    -- Hanging broken ceiling beam / joist dangling into reception
    makePart(fDamage, {
        Name = "HangingCeilingBeam",
        Size = Vector3.new(0.8 * scale, 8.5 * scale, 0.8 * scale),
        CFrame = rootCF * CFrame.new(8 * scale, 10.0 * scale, 8 * scale) * CFrame.Angles(math.rad(28), math.rad(15), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Fractured terrace floor breach hole rim
    makePart(fDamage, {
        Name = "FloorBreachCraterRim",
        Size = Vector3.new(14 * scale, 0.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(22 * scale, 1.8 * scale, 12 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Sheared second-floor balcony stump on East flank
    makePart(fDamage, {
        Name = "ShearedBalconyStump_East",
        Size = Vector3.new(6 * scale, 1.2 * scale, 2.0 * scale),
        CFrame = rootCF * CFrame.new(12 * scale, 13.8 * scale, 21.6 * scale) * CFrame.Angles(0, 0, math.rad(-12)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Fractured cornice parapet gap wedge on West roofline
    makeWedge(fDamage, {
        Name = "ParapetBreach_West",
        Size = Vector3.new(2 * scale, 1.6 * scale, 1.6 * scale),
        CFrame = rootCF * CFrame.new(-38 * scale, 26.2 * scale, 13.5 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Sagging rebar truss mesh hanging from ceiling
    makePart(fDamage, {
        Name = "SaggingRebarMesh",
        Size = Vector3.new(4 * scale, 0.3 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(18 * scale, 12.0 * scale, 4 * scale) * CFrame.Angles(math.rad(22), 0, math.rad(-15)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
        CanCollide = false,
        CastShadow = true,
    })

    -- ------------------------------------------------------------------------
    -- 7. RUBBLE (Collapsed Masonry, Concrete Slabs, Bricks, Fallen Lintels) [17 parts]
    -- ------------------------------------------------------------------------
    -- Massive collapsed pile under the collapsed East wing facade
    makePart(fRubble, {
        Name = "EastWingCollapseMound",
        Size = Vector3.new(26 * scale, 4.5 * scale, 16 * scale),
        CFrame = rootCF * CFrame.new(28 * scale, 2.5 * scale, 18 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Tilted fallen concrete roof chunk resting on rubble
    makePart(fRubble, {
        Name = "FallenRoofSlabChunk",
        Size = Vector3.new(12 * scale, 1.2 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(30 * scale, 4.8 * scale, 20 * scale) * CFrame.Angles(math.rad(18), math.rad(24), math.rad(-10)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
        CanCollide = true,
        CastShadow = true,
    })

    -- Fallen entrance portico lintel beam
    makePart(fRubble, {
        Name = "FallenEntranceLintel",
        Size = Vector3.new(1.8 * scale, 1.8 * scale, 14 * scale),
        CFrame = rootCF * CFrame.new(16 * scale, 1.6 * scale, 20 * scale) * CFrame.Angles(0, math.rad(35), math.rad(8)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_CORE,
        CanCollide = true,
        CastShadow = true,
    })

    -- Fallen concrete balcony balustrade chunk
    makePart(fRubble, {
        Name = "FallenBalustradeChunk",
        Size = Vector3.new(8 * scale, 1.6 * scale, 1.4 * scale),
        CFrame = rootCF * CFrame.new(24 * scale, 1.2 * scale, 26 * scale) * CFrame.Angles(0, math.rad(15), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_STUCCO_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })

    -- Individual broken red clay bricks scattered across the portico apron
    local brickOffsets = {
        Vector3.new(12, 1.2, 23),
        Vector3.new(19, 1.5, 25),
        Vector3.new(25, 2.2, 24),
        Vector3.new(32, 1.8, 22),
        Vector3.new(38, 1.2, 21),
        Vector3.new(4, 1.2, 22),
        Vector3.new(-12, 1.2, 23),
        Vector3.new(-28, 1.2, 22),
        Vector3.new(14, 1.2, 27),
        Vector3.new(-6, 1.2, 25),
    }
    for idx, bOff in ipairs(brickOffsets) do
        local bYaw = math.rad(rng:NextNumber(0, 360))
        makePart(fRubble, {
            Name = string.format("RubbleBrick_%d", idx),
            Size = Vector3.new(1.2 * scale, 0.6 * scale, 2.2 * scale),
            CFrame = rootCF * CFrame.new(bOff.X * scale, bOff.Y * scale, bOff.Z * scale) * CFrame.Angles(0, bYaw, 0),
            Material = Enum.Material.Brick,
            Color = if idx % 2 == 0 then COLOR_BRICK_RED else COLOR_BRICK_DARK,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Crumbled mortar/plaster gravel wedges around East rubble
    makeWedge(fRubble, {
        Name = "MortarRubbleSlope_Front",
        Size = Vector3.new(18 * scale, 3.0 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(26 * scale, 1.8 * scale, 25 * scale),
        Material = Enum.Material.Concrete,
        Color = COLOR_BRICK_MORTAR_MIX,
        CanCollide = true,
        CastShadow = true,
    })
    makeWedge(fRubble, {
        Name = "MortarRubbleSlope_Rear",
        Size = Vector3.new(16 * scale, 2.5 * scale, 6 * scale),
        CFrame = rootCF * CFrame.new(26 * scale, 1.5 * scale, -18 * scale) * CFrame.Angles(0, math.rad(180), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_BRICK_MORTAR_MIX,
        CanCollide = true,
        CastShadow = true,
    })

    -- Fallen interior partition slab fragment in dining area
    makePart(fRubble, {
        Name = "FallenInteriorPartitionChunk",
        Size = Vector3.new(5 * scale, 0.6 * scale, 4 * scale),
        CFrame = rootCF * CFrame.new(-18 * scale, 1.8 * scale, 6 * scale) * CFrame.Angles(0, math.rad(28), math.rad(6)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = true,
        CastShadow = true,
    })

    -- ------------------------------------------------------------------------
    -- 8. SALT CRUST (Mineral Rims, Tide-Line Watermark, Salinas Over Foundation) [16 parts]
    -- ------------------------------------------------------------------------
    -- Horizontal calcified tide-line watermarks (showing historical 10-meter flood level)
    makePart(fSaltCrust, {
        Name = "TideLineWatermark_West",
        Size = Vector3.new(48 * scale, 1.2 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(-22 * scale, 10.0 * scale, 14.3 * scale),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
        CanCollide = false,
        CastShadow = false,
    })
    makePart(fSaltCrust, {
        Name = "TideLineWatermark_GableWest",
        Size = Vector3.new(0.3 * scale, 1.2 * scale, 36 * scale),
        CFrame = rootCF * CFrame.new(-46.9 * scale, 10.0 * scale, -4 * scale),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.24,
        CanCollide = false,
        CastShadow = false,
    })
    makePart(fSaltCrust, {
        Name = "TideLineWatermark_InteriorFoyer",
        Size = Vector3.new(20 * scale, 1.0 * scale, 0.3 * scale),
        CFrame = rootCF * CFrame.new(-6 * scale, 10.0 * scale, -3.4 * scale),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.22,
        CanCollide = false,
        CastShadow = false,
    })

    -- Low organic salt crust shelf discs encroaching upon the front steps & terrace
    local saltPlates = {
        { Pos = Vector3.new(-36, 0.5, 23), Dia = 9.0 * scale },
        { Pos = Vector3.new(-22, 0.5, 24), Dia = 7.5 * scale },
        { Pos = Vector3.new(8, 0.5, 25),   Dia = 8.0 * scale },
        { Pos = Vector3.new(24, 0.5, 26),  Dia = 10.0 * scale },
        { Pos = Vector3.new(42, 0.5, 24),  Dia = 8.5 * scale },
        { Pos = Vector3.new(-45, 0.5, 5),  Dia = 7.0 * scale },
        { Pos = Vector3.new(45, 0.5, -6),  Dia = 9.5 * scale },
        { Pos = Vector3.new(15, 0.5, -23), Dia = 8.0 * scale },
        { Pos = Vector3.new(-18, 0.5, -23), Dia = 7.0 * scale },
        { Pos = Vector3.new(32, 0.5, 5),    Dia = 8.5 * scale },
    }
    for idx, sp in ipairs(saltPlates) do
        makeCylinder(fSaltCrust, {
            Name = string.format("SaltCrustPlate_%d", idx),
            Size = Vector3.new(0.4 * scale, sp.Dia, sp.Dia),
            CFrame = rootCF * CFrame.new(sp.Pos.X * scale, sp.Pos.Y * scale, sp.Pos.Z * scale) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.SmoothPlastic,
            Color = if idx % 2 == 0 then COLOR_SALT_CRYSTAL_WHITE else COLOR_SALT_OFFWHITE,
            Reflectance = 0.22,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- Salt mineral rim along collapsed East rubble
    makePart(fSaltCrust, {
        Name = "SaltRubbleDeposit_East",
        Size = Vector3.new(18 * scale, 0.4 * scale, 12 * scale),
        CFrame = rootCF * CFrame.new(30 * scale, 0.6 * scale, 18 * scale),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_SILT_BLEND,
        Reflectance = 0.18,
        CanCollide = false,
        CastShadow = false,
    })

    -- Salt encrustation rim along front entrance steps
    makePart(fSaltCrust, {
        Name = "SaltCrustStepLip",
        Size = Vector3.new(24 * scale, 0.2 * scale, 1.2 * scale),
        CFrame = rootCF * CFrame.new(0, 0.6 * scale, 25.4 * scale),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRYSTAL_WHITE,
        Reflectance = 0.25,
        CanCollide = false,
        CastShadow = false,
    })

    -- Salt rim along foundation base corner
    makeWedge(fSaltCrust, {
        Name = "SaltCrustCornerWedge_East",
        Size = Vector3.new(6 * scale, 0.8 * scale, 8 * scale),
        CFrame = rootCF * CFrame.new(46 * scale, 0.4 * scale, 14 * scale) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_OFFWHITE,
        Reflectance = 0.20,
        CanCollide = true,
        CastShadow = true,
    })

    return primaryBasePart
end

-- ============================================================================
-- MAIN BUILD API: LandmarkModelBuilder.Build(options)
-- ============================================================================

function LandmarkModelBuilder.Build(opts: LandmarkBuildOptions): Model
    assert(opts.LandmarkType ~= nil, "[LandmarkModelBuilder] LandmarkType is required")

    local lType = opts.LandmarkType
    local pos = opts.Position or Vector3.zero
    local rotY = opts.RotationY or 0
    local scale = opts.Scale or 1.0
    local seed = opts.Seed or 42

    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or lType

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    local primaryPart: Part? = nil

    if lType == "HotelMonteReal" then
        primaryPart = buildHotelMonteReal(model, rootCF, scale, opts, rng)
    else
        error(string.format("[LandmarkModelBuilder] Unsupported LandmarkType '%s'", tostring(lType)))
    end

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

function LandmarkModelBuilder.GetLandmarkMetrics(): { [LandmarkType]: { MinParts: number, MaxParts: number, TypicalParts: number } }
    return {
        HotelMonteReal = { MinParts = 125, MaxParts = 165, TypicalParts = 142 },
    }
end

return LandmarkModelBuilder
