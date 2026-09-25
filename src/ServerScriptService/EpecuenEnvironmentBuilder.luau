--!strict
--[[
    EpecuenEnvironmentBuilder.luau
    Location: ServerScriptService/EpecuenEnvironmentBuilder.luau

    Procedural Environmental Detail Builder for "EPECUÉN: NO ESCAPE".
    Visual Reference: Villa Epecuén (Adolfo Alsina, Buenos Aires Province, Argentina).

    Historical & Environmental Context:
      Villa Epecuén was submerged under 10 meters of hyper-saline mineral water
      in November 1985. Decades later, when the water evaporated, it unveiled:
        1. Petrified Trees: Bleached, bare, twisted caldén and eucalyptus skeletons
           stripped of bark, encrusted in mineral salts, standing like white ghosts.
        2. Salt Crusts: Glistening crystalline brine deposits, mineral rims, and
           shelf-like salinas blanketing the ground, shoreline, and foundations.
        3. Rubble Piles: Collapsed brickwork (ladrillo común), crumbled mortar mounds,
           cracked concrete slabs, and dislodged structural lintels.
        4. Rusted Metal: Severely oxidized corrugated zinc roofing (chapa acanalada),
           corroded ductile iron water pipes, and distorted rebar frames.
        5. Dead Vegetation: Sparse, withered halophyte grass (cortadera/espartillo)
           stiffened and bleached by soil salinity.

    Technical Constraints:
      - 100% native Roblox primitives: Part (Block, Cylinder), WedgePart, CornerWedgePart.
      - ZERO MeshParts, external asset IDs, textures, sounds, AI, or ProximityPrompts.
      - ZERO automatic instantiation into Workspace on require.
      - Fully deterministic through Random.new(seed).
      - Optimized part budgets (5 to 18 parts per element).
--]]

local EpecuenEnvironmentBuilder = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type ElementType =
    | "PetrifiedTree"
    | "SaltCrust"
    | "RubblePile"
    | "RustedMetal"
    | "DeadVegetation"

export type EnvironmentBuildOptions = {
    ElementType: ElementType,
    Position: Vector3?,
    RotationY: number?,
    Scale: number?,
    Seed: number?,
    Variant: string?,
    Name: string?,
    Parent: Instance?,

    -- Element-specific tuning (optional overrides)
    Height: number?,        -- Tree height or pile height
    Radius: number?,        -- Footprint radius for crust / rubble
    BrokenTrunk: boolean?,  -- Force snapped trunk for PetrifiedTree
    SaltLevel: number?,     -- 0.0 to 1.0 salt encrustation
    DamageLevel: number?,   -- 0.0 to 1.0 structural degradation
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
-- AUTHENTIC PALETTE & MATERIALS (Villa Epecuén Saline Landscape)
-- ============================================================================

-- Calcified & Bleached Petrified Wood
local COLOR_BLEACHED_TREE_WHITE = Color3.fromRGB(240, 240, 235) -- Sun-bleached outer wood
local COLOR_BLEACHED_TREE_BONE  = Color3.fromRGB(222, 222, 214) -- Weathered calcified trunk
local COLOR_BLEACHED_TREE_GRAY  = Color3.fromRGB(196, 194, 186) -- Salt-weathered heartwood
local COLOR_BLEACHED_TREE_DARK  = Color3.fromRGB(168, 164, 156) -- Waterline staining

-- Mineral Salt Crusts
local COLOR_SALT_CRYSTAL_PURE   = Color3.fromRGB(252, 252, 250) -- Pure calcified brine surface
local COLOR_SALT_CRUST_OFFWHITE = Color3.fromRGB(236, 238, 230) -- Thick mineralized crust
local COLOR_SALT_SILT_MIX       = Color3.fromRGB(216, 218, 208) -- Saline soil blend
local COLOR_SALT_CREAM          = Color3.fromRGB(226, 228, 218) -- Evaporated lagoon deposit

-- Crumbled Masonry & Concrete
local COLOR_CONCRETE_WEATHERED  = Color3.fromRGB(156, 152, 144) -- Salt-eroded Argentine cement
local COLOR_CONCRETE_LIGHT      = Color3.fromRGB(178, 175, 168) -- Pale plaster / mortar
local COLOR_BRICK_RED           = Color3.fromRGB(168, 92, 72)   -- Ladrillo común bonaerense
local COLOR_BRICK_DARK          = Color3.fromRGB(138, 76, 60)   -- Submerged brick core
local COLOR_SLATE_DEBRIS        = Color3.fromRGB(112, 108, 102) -- Submerged tile / foundation slab

-- Corroded Metals (High salinity exposure)
local COLOR_RUST_FLAKING        = Color3.fromRGB(124, 66, 42)   -- Flaking ferric oxide
local COLOR_RUST_DARK           = Color3.fromRGB(86, 50, 34)    -- Deep corroded ductile iron
local COLOR_RUST_ORANGE         = Color3.fromRGB(150, 84, 52)   -- Weathered rust crust
local COLOR_ZINC_WEATHERED      = Color3.fromRGB(118, 114, 110) -- Corroded sheet zinc

-- Dead Pampas Halophyte Vegetation
local COLOR_DEAD_REED_BLEACHED  = Color3.fromRGB(188, 178, 142) -- Pale straw reed
local COLOR_DEAD_REED_DRY       = Color3.fromRGB(164, 152, 116) -- Withered cortadera grass
local COLOR_DEAD_REED_MUD       = Color3.fromRGB(138, 126, 96)  -- Saline silt mud base

-- ============================================================================
-- PRIMITIVE CONSTRUCTORS (ANCHORED NATIVE GEOMETRY ONLY)
-- ============================================================================

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.Concrete
    p.Color = cfg.Color or COLOR_CONCRETE_WEATHERED
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
    w.Color = cfg.Color or COLOR_CONCRETE_WEATHERED
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
    cw.Color = cfg.Color or COLOR_CONCRETE_WEATHERED
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
    c.Material = cfg.Material or Enum.Material.SmoothPlastic
    c.Color = cfg.Color or COLOR_SALT_CRYSTAL_PURE
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
-- 1. PETRIFIED TREE BUILDER
-- ============================================================================
-- Bleached, bare, dead trees (caldén / eucalyptus) characteristic of Epecuén.
-- Features:
--   - Organic segmented multi-angle trunk (crooked, off-vertical silhouette)
--   - Salt-calcified base flare skirt
--   - Tapering bare dead branches extending upward and outward
--   - Snapped/fractured trunk variation with splintered jagged wedge top
--   - Pale bone-white, salt-washed color palette
-- Approx parts: 9 to 16 parts
function EpecuenEnvironmentBuilder.BuildPetrifiedTree(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: EnvironmentBuildOptions,
    rng: Random
): Part
    local folderTrunk = getOrCreateFolder(model, "Trunk")
    local folderBranches = getOrCreateFolder(model, "Branches")
    local folderBase = getOrCreateFolder(model, "BaseSaltSkirt")

    local height = (opts.Height or rng:NextNumber(15, 26)) * scale
    local isBroken = if opts.BrokenTrunk ~= nil then opts.BrokenTrunk else (rng:NextNumber() < 0.35)
    local trunkDiameter = (opts.Radius or rng:NextNumber(1.6, 2.6)) * scale

    -- 1. Base Salt Flare / Root Pad
    local baseSkirtPart = makeCylinder(folderBase, {
        Name = "SaltRootSkirt",
        Size = Vector3.new(0.6 * scale, trunkDiameter * 1.8, trunkDiameter * 1.8),
        CFrame = rootCF * CFrame.new(0, 0.3 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_OFFWHITE,
        Reflectance = 0.15,
        CanCollide = true,
        CastShadow = true,
    })

    -- 2. Organic Segmented Trunk
    local segmentCount = if isBroken then rng:NextInteger(2, 3) else rng:NextInteger(3, 4)
    local segmentHeight = height / segmentCount
    local currentCF = rootCF * CFrame.new(0, 0.3 * scale, 0)
    local currentDiameter = trunkDiameter

    local primaryBasePart = baseSkirtPart

    for segIdx = 1, segmentCount do
        local topSegDiameter = currentDiameter * rng:NextNumber(0.78, 0.88)
        local segLen = segmentHeight * rng:NextNumber(0.92, 1.08)

        -- Organic organic lean (tilt 3 to 8 degrees in varied compass directions)
        local leanAngle = math.rad(rng:NextNumber(3, 8))
        local leanYaw = math.rad(rng:NextNumber(0, 360))
        local segmentRotation = CFrame.Angles(0, leanYaw, 0) * CFrame.Angles(leanAngle, 0, 0) * CFrame.Angles(0, -leanYaw, 0)

        local midCF = currentCF * segmentRotation * CFrame.new(0, segLen * 0.5, 0)

        -- Material alternates between calcified wood and weathered slate
        local woodColor = if segIdx == 1 then COLOR_BLEACHED_TREE_DARK
            elseif segIdx == 2 then COLOR_BLEACHED_TREE_BONE
            else COLOR_BLEACHED_TREE_WHITE

        local trunkPart = makePart(folderTrunk, {
            Name = string.format("TrunkSeg_%d", segIdx),
            Size = Vector3.new(currentDiameter, segLen, currentDiameter),
            CFrame = midCF,
            Material = Enum.Material.SmoothPlastic,
            Color = woodColor,
            Reflectance = 0.08,
            CanCollide = true,
            CastShadow = true,
        })

        if segIdx == 1 then
            primaryBasePart = trunkPart
        end

        currentCF = currentCF * segmentRotation * CFrame.new(0, segLen, 0)
        currentDiameter = topSegDiameter
    end

    -- 3. Snapped Trunk Fracture or Crown
    if isBroken then
        -- Jagged splinter wedge on top of the snapped trunk
        local fractureYaw = math.rad(rng:NextNumber(0, 360))
        makeWedge(folderTrunk, {
            Name = "FracturedTopSplinter",
            Size = Vector3.new(currentDiameter * 0.8, 1.8 * scale, currentDiameter * 0.8),
            CFrame = currentCF * CFrame.Angles(0, fractureYaw, 0) * CFrame.new(0, 0.9 * scale, 0),
            Material = Enum.Material.Wood,
            Color = COLOR_BLEACHED_TREE_WHITE,
            CanCollide = true,
            CastShadow = true,
        })
    else
        -- High crown bare branch cluster
        local crownBranchCount = rng:NextInteger(2, 3)
        for b = 1, crownBranchCount do
            local bYaw = math.rad((b - 1) * (360 / crownBranchCount) + rng:NextNumber(-25, 25))
            local bPitch = math.rad(rng:NextNumber(25, 55))
            local bLen = rng:NextNumber(4.0, 7.5) * scale
            local bThick = currentDiameter * rng:NextNumber(0.45, 0.65)

            local bCF = currentCF * CFrame.Angles(0, bYaw, 0) * CFrame.Angles(bPitch, 0, 0) * CFrame.new(0, bLen * 0.5, 0)

            makePart(folderBranches, {
                Name = string.format("CrownBranch_%d", b),
                Size = Vector3.new(bThick, bLen, bThick),
                CFrame = bCF,
                Material = Enum.Material.SmoothPlastic,
                Color = COLOR_BLEACHED_TREE_WHITE,
                Reflectance = 0.05,
                CanCollide = false,
                CastShadow = true,
            })
        end
    end

    -- 4. Lateral Dead Limbs (reaching outward, crooked bare branches)
    local lateralBranchCount = if isBroken then rng:NextInteger(1, 2) else rng:NextInteger(3, 5)
    for i = 1, lateralBranchCount do
        local heightRatio = rng:NextNumber(0.35, 0.75)
        local branchElevation = height * heightRatio
        local branchYaw = math.rad(rng:NextNumber(0, 360))
        local branchPitch = math.rad(rng:NextNumber(35, 65))
        local branchLength = rng:NextNumber(4.5, 8.5) * scale
        local branchThickness = (trunkDiameter * 0.45) * scale

        local branchRootCF = rootCF * CFrame.new(0, branchElevation, 0) * CFrame.Angles(0, branchYaw, 0)
        local branchMidCF = branchRootCF * CFrame.Angles(branchPitch, 0, 0) * CFrame.new(0, branchLength * 0.5, 0)

        makePart(folderBranches, {
            Name = string.format("DeadBranch_%d", i),
            Size = Vector3.new(branchThickness, branchLength, branchThickness),
            CFrame = branchMidCF,
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_BLEACHED_TREE_BONE,
            Reflectance = 0.05,
            CanCollide = false,
            CastShadow = true,
        })

        -- Secondary offshoot twig on longer branches (50% chance)
        if branchLength > 5.5 * scale and rng:NextNumber() < 0.55 then
            local subPitch = math.rad(rng:NextNumber(-30, 30))
            local subYaw = math.rad(rng:NextNumber(40, 90))
            local subLen = rng:NextNumber(2.5, 4.2) * scale
            local subThick = branchThickness * 0.65

            local subCF = branchMidCF * CFrame.new(0, branchLength * 0.35, 0)
                * CFrame.Angles(0, subYaw, subPitch)
                * CFrame.new(0, subLen * 0.5, 0)

            makePart(folderBranches, {
                Name = string.format("BranchTwig_%d", i),
                Size = Vector3.new(subThick, subLen, subThick),
                CFrame = subCF,
                Material = Enum.Material.SmoothPlastic,
                Color = COLOR_BLEACHED_TREE_WHITE,
                CanCollide = false,
                CastShadow = true,
            })
        end
    end

    return primaryBasePart
end

-- ============================================================================
-- 2. SALT CRUST FORMATION BUILDER
-- ============================================================================
-- Irregular calcified mineral brine crusts, salina rims, and shelf deposits.
-- Features:
--   - Low overlapping flattened discs and irregular plates forming natural organic contour
--   - Stepped salt mineral nodules / mounds with calcified sheen
--   - Jagged brittle perimeter fracture wedges along the dry perimeter
-- Approx parts: 7 to 14 parts
function EpecuenEnvironmentBuilder.BuildSaltCrust(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: EnvironmentBuildOptions,
    rng: Random
): Part
    local folderPlates = getOrCreateFolder(model, "CrustPlates")
    local folderMounds = getOrCreateFolder(model, "Mounds")
    local folderFringes = getOrCreateFolder(model, "PerimeterFringes")

    local radius = (opts.Radius or rng:NextNumber(5.0, 11.0)) * scale
    local crustHeight = (opts.Height or rng:NextNumber(0.35, 0.85)) * scale

    -- 1. Main Base Shelf (Central low disc)
    local mainBasePart = makeCylinder(folderPlates, {
        Name = "BaseCrustPlate",
        Size = Vector3.new(crustHeight, radius * 1.9, radius * 1.9),
        CFrame = rootCF * CFrame.new(0, crustHeight * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_OFFWHITE,
        Reflectance = 0.22,
        CanCollide = true,
        CastShadow = true,
    })

    -- 2. Secondary Overlapping Organic Lobes (2 to 3 lobes)
    local lobeCount = rng:NextInteger(2, 3)
    for l = 1, lobeCount do
        local lobeAngle = math.rad((l - 1) * (360 / lobeCount) + rng:NextNumber(-35, 35))
        local lobeDist = radius * rng:NextNumber(0.40, 0.70)
        local lobeRadius = radius * rng:NextNumber(0.55, 0.85)
        local lobeH = crustHeight * rng:NextNumber(0.8, 1.1)

        local lobePos = Vector3.new(math.cos(lobeAngle) * lobeDist, lobeH * 0.5, math.sin(lobeAngle) * lobeDist)

        makeCylinder(folderPlates, {
            Name = string.format("CrustLobe_%d", l),
            Size = Vector3.new(lobeH, lobeRadius * 1.8, lobeRadius * 1.8),
            CFrame = rootCF * CFrame.new(lobePos) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_SALT_SILT_MIX,
            Reflectance = 0.18,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- 3. Raised Mineral Nodule Mounds (small glistening bumps)
    local moundCount = rng:NextInteger(2, 4)
    for m = 1, moundCount do
        local mYaw = math.rad(rng:NextNumber(0, 360))
        local mDist = radius * rng:NextNumber(0.15, 0.65)
        local mDia = radius * rng:NextNumber(0.35, 0.55)
        local mH = crustHeight * rng:NextNumber(1.3, 2.2)

        local mPos = Vector3.new(math.cos(mYaw) * mDist, mH * 0.5, math.sin(mYaw) * mDist)

        makeCylinder(folderMounds, {
            Name = string.format("MineralMound_%d", m),
            Size = Vector3.new(mH, mDia, mDia),
            CFrame = rootCF * CFrame.new(mPos) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_SALT_CRYSTAL_PURE,
            Reflectance = 0.28,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- 4. Perimeter Cracked Edge Wedges
    local fringeCount = rng:NextInteger(2, 4)
    for f = 1, fringeCount do
        local fYaw = math.rad(rng:NextNumber(0, 360))
        local fDist = radius * rng:NextNumber(0.75, 0.95)
        local fW = rng:NextNumber(1.5, 3.5) * scale
        local fL = rng:NextNumber(1.2, 2.8) * scale
        local fH = crustHeight * 0.7

        local fPos = Vector3.new(math.cos(fYaw) * fDist, fH * 0.5, math.sin(fYaw) * fDist)

        makeWedge(folderFringes, {
            Name = string.format("CrackedEdge_%d", f),
            Size = Vector3.new(fW, fH, fL),
            CFrame = rootCF * CFrame.new(fPos) * CFrame.Angles(0, fYaw, 0),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_SALT_CREAM,
            Reflectance = 0.15,
            CanCollide = true,
            CastShadow = false,
        })
    end

    return mainBasePart
end

-- ============================================================================
-- 3. RUBBLE PILE BUILDER
-- ============================================================================
-- Optimized heaps of broken Argentine brickwork, crumbled concrete slabs,
-- mortar gravel mounds, and fallen structural lintels.
-- Approx parts: 9 to 16 parts
function EpecuenEnvironmentBuilder.BuildRubblePile(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: EnvironmentBuildOptions,
    rng: Random
): Part
    local folderCore = getOrCreateFolder(model, "CoreMound")
    local folderSlabs = getOrCreateFolder(model, "ConcreteSlabs")
    local folderBricks = getOrCreateFolder(model, "BrickDebris")
    local folderBeams = getOrCreateFolder(model, "FallenLintels")

    local radius = (opts.Radius or rng:NextNumber(3.5, 6.5)) * scale
    local height = (opts.Height or rng:NextNumber(1.2, 2.5)) * scale

    -- 1. Base Mortar & Gravel Core
    local baseCore = makePart(folderCore, {
        Name = "MortarCoreBase",
        Size = Vector3.new(radius * 1.8, height * 0.7, radius * 1.8),
        CFrame = rootCF * CFrame.new(0, height * 0.35, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
        CanCollide = true,
        CastShadow = true,
    })

    -- 2. Weathered Broken Concrete Slabs (tilted at jagged angles)
    local slabCount = rng:NextInteger(2, 4)
    for s = 1, slabCount do
        local sYaw = math.rad(rng:NextNumber(0, 360))
        local sPitch = math.rad(rng:NextNumber(12, 28))
        local sRoll = math.rad(rng:NextNumber(-15, 15))
        local sW = rng:NextNumber(2.0, 3.8) * scale
        local sL = rng:NextNumber(2.5, 4.5) * scale
        local sThick = rng:NextNumber(0.4, 0.8) * scale
        local sDist = radius * rng:NextNumber(0.15, 0.55)

        local sPos = Vector3.new(math.cos(sYaw) * sDist, height * 0.5 + (s * 0.25 * scale), math.sin(sYaw) * sDist)

        makePart(folderSlabs, {
            Name = string.format("ConcreteChunk_%d", s),
            Size = Vector3.new(sW, sThick, sL),
            CFrame = rootCF * CFrame.new(sPos) * CFrame.Angles(sPitch, sYaw, sRoll),
            Material = Enum.Material.Concrete,
            Color = if s % 2 == 0 then COLOR_CONCRETE_LIGHT else COLOR_SLATE_DEBRIS,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- 3. Exposed Clay Masonry Bricks (Ladrillos comunes bonaerenses)
    local brickCount = rng:NextInteger(3, 6)
    for b = 1, brickCount do
        local bYaw = math.rad(rng:NextNumber(0, 360))
        local bPitch = math.rad(rng:NextNumber(-20, 20))
        local bDist = radius * rng:NextNumber(0.35, 0.85)
        local bPos = Vector3.new(math.cos(bYaw) * bDist, 0.4 * scale, math.sin(bYaw) * bDist)

        local brickColor = if b % 2 == 0 then COLOR_BRICK_RED else COLOR_BRICK_DARK

        makePart(folderBricks, {
            Name = string.format("MasonryBrick_%d", b),
            Size = Vector3.new(0.9 * scale, 0.45 * scale, 1.8 * scale),
            CFrame = rootCF * CFrame.new(bPos) * CFrame.Angles(bPitch, bYaw, 0),
            Material = Enum.Material.Brick,
            Color = brickColor,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- 4. Fallen Structural Lintel / Timber Beam (1 to 2 beams resting across)
    local beamCount = rng:NextInteger(1, 2)
    for bm = 1, beamCount do
        local bmYaw = math.rad(rng:NextNumber(0, 180))
        local bmPitch = math.rad(rng:NextNumber(14, 26))
        local bmL = rng:NextNumber(4.5, 7.5) * scale
        local bmThick = rng:NextNumber(0.6, 0.9) * scale

        local bmPos = Vector3.new(rng:NextNumber(-0.6, 0.6) * scale, height * 0.7, rng:NextNumber(-0.6, 0.6) * scale)

        makePart(folderBeams, {
            Name = string.format("FallenBeam_%d", bm),
            Size = Vector3.new(bmThick, bmThick, bmL),
            CFrame = rootCF * CFrame.new(bmPos) * CFrame.Angles(bmPitch, bmYaw, 0),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_WEATHERED,
            CanCollide = true,
            CastShadow = true,
        })
    end

    -- 5. Saline Crust Patch on Base Edge
    makePart(folderCore, {
        Name = "DebrisSaltDeposit",
        Size = Vector3.new(radius * 0.9, 0.25 * scale, radius * 0.9),
        CFrame = rootCF * CFrame.new(radius * 0.4, 0.12 * scale, radius * 0.3),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_OFFWHITE,
        Reflectance = 0.18,
        CanCollide = false,
        CastShadow = false,
    })

    return baseCore
end

-- ============================================================================
-- 4. RUSTED METAL DEBRIS BUILDER
-- ============================================================================
-- Abandoned metal artifacts corroded by decades of mineral brine:
--   - Sub-types: Bent corrugated sheet zinc ("SheetMetal"), Severed pipes ("BrokenPipe"),
--     Rusted structural frame/rebar ("RustedFrame").
-- Approx parts: 5 to 11 parts
function EpecuenEnvironmentBuilder.BuildRustedMetal(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: EnvironmentBuildOptions,
    rng: Random
): Part
    local folderMetal = getOrCreateFolder(model, "MetalComponents")

    local variant = opts.Variant or (if rng:NextNumber() < 0.40 then "SheetMetal"
        elseif rng:NextNumber() < 0.70 then "BrokenPipe"
        else "RustedFrame")

    local primaryPart: Part

    if variant == "SheetMetal" then
        -- Bent Corrugated Zinc Roofing / Siding plates
        local sheetLen = rng:NextNumber(4.5, 7.0) * scale
        local sheetWidth = rng:NextNumber(2.5, 4.0) * scale
        local tiltAngle = math.rad(rng:NextNumber(20, 45))
        local yawAngle = math.rad(rng:NextNumber(0, 360))

        -- Ground anchor plate
        primaryPart = makePart(folderMetal, {
            Name = "SheetBasePlate",
            Size = Vector3.new(sheetWidth, 0.18 * scale, sheetLen * 0.55),
            CFrame = rootCF * CFrame.new(0, 0.1 * scale, 0) * CFrame.Angles(0, yawAngle, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = true,
            CastShadow = true,
        })

        -- Bent upward upper section
        makePart(folderMetal, {
            Name = "SheetBentUpper",
            Size = Vector3.new(sheetWidth, 0.18 * scale, sheetLen * 0.6),
            CFrame = rootCF * CFrame.Angles(0, yawAngle, 0)
                * CFrame.new(0, 0.1 * scale, -sheetLen * 0.25)
                * CFrame.Angles(tiltAngle, 0, 0)
                * CFrame.new(0, 0, -sheetLen * 0.3),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_ORANGE,
            CanCollide = true,
            CastShadow = true,
        })

        -- Severed corner wedge flap
        makeWedge(folderMetal, {
            Name = "SheetTornFlap",
            Size = Vector3.new(sheetWidth * 0.45, 0.8 * scale, sheetLen * 0.35),
            CFrame = rootCF * CFrame.Angles(0, yawAngle, 0)
                * CFrame.new(sheetWidth * 0.25, 0.4 * scale, sheetLen * 0.15)
                * CFrame.Angles(0, math.rad(180), 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
            CanCollide = true,
            CastShadow = true,
        })

    elseif variant == "BrokenPipe" then
        -- Corroded water pipe sections emerging from saline mud
        local pipeDiameter = rng:NextNumber(1.0, 1.8) * scale
        local pipeLength = rng:NextNumber(4.5, 7.5) * scale
        local pipeTilt = math.rad(rng:NextNumber(22, 48))
        local pipeYaw = math.rad(rng:NextNumber(0, 360))

        -- Pipe base sticking out of the ground
        primaryPart = makeCylinder(folderMetal, {
            Name = "SeveredPipeStem",
            Size = Vector3.new(pipeLength, pipeDiameter, pipeDiameter),
            CFrame = rootCF * CFrame.Angles(0, pipeYaw, 0)
                * CFrame.Angles(0, 0, math.rad(90) - pipeTilt)
                * CFrame.new(0, pipeLength * 0.45, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
            CanCollide = true,
            CastShadow = true,
        })

        -- Pipe flange / connector collar
        makeCylinder(folderMetal, {
            Name = "PipeFlangeCollar",
            Size = Vector3.new(0.4 * scale, pipeDiameter * 1.35, pipeDiameter * 1.35),
            CFrame = primaryPart.CFrame * CFrame.new(pipeLength * 0.2, 0, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = true,
            CastShadow = true,
        })

        -- Dislodged fallen pipe segment on the ground nearby
        makeCylinder(folderMetal, {
            Name = "FallenPipeSegment",
            Size = Vector3.new(pipeLength * 0.65, pipeDiameter, pipeDiameter),
            CFrame = rootCF * CFrame.new(pipeDiameter * 1.8, pipeDiameter * 0.5, pipeDiameter * 1.2)
                * CFrame.Angles(0, pipeYaw + math.rad(70), math.rad(90)),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = true,
            CastShadow = true,
        })

    else -- "RustedFrame"
        -- Angled iron strut / distorted rebar grid
        local frameW = rng:NextNumber(3.0, 4.5) * scale
        local frameH = rng:NextNumber(2.5, 4.0) * scale
        local barThick = 0.3 * scale
        local frameTilt = math.rad(rng:NextNumber(15, 35))
        local frameYaw = math.rad(rng:NextNumber(0, 360))

        local frameRoot = rootCF * CFrame.Angles(0, frameYaw, 0) * CFrame.Angles(frameTilt, 0, 0)

        -- Left rail
        primaryPart = makePart(folderMetal, {
            Name = "FrameRail_Left",
            Size = Vector3.new(barThick, frameH, barThick),
            CFrame = frameRoot * CFrame.new(-frameW * 0.5, frameH * 0.5, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
            CanCollide = true,
            CastShadow = true,
        })

        -- Right rail
        makePart(folderMetal, {
            Name = "FrameRail_Right",
            Size = Vector3.new(barThick, frameH, barThick),
            CFrame = frameRoot * CFrame.new(frameW * 0.5, frameH * 0.5, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_DARK,
            CanCollide = true,
            CastShadow = true,
        })

        -- Cross bar top
        makePart(folderMetal, {
            Name = "FrameCross_Top",
            Size = Vector3.new(frameW, barThick, barThick),
            CFrame = frameRoot * CFrame.new(0, frameH - barThick * 0.5, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = true,
            CastShadow = true,
        })

        -- Cross bar bottom
        makePart(folderMetal, {
            Name = "FrameCross_Bottom",
            Size = Vector3.new(frameW, barThick, barThick),
            CFrame = frameRoot * CFrame.new(0, barThick * 0.5, 0),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_FLAKING,
            CanCollide = true,
            CastShadow = true,
        })

        -- Diagonal twisted rebar tie
        local diagLen = math.sqrt(frameW * frameW + frameH * frameH)
        local diagAngle = math.atan2(frameH, frameW)
        makePart(folderMetal, {
            Name = "FrameRebar_Diagonal",
            Size = Vector3.new(barThick * 0.8, diagLen, barThick * 0.8),
            CFrame = frameRoot * CFrame.new(0, frameH * 0.5, 0) * CFrame.Angles(0, 0, -diagAngle + math.pi * 0.5),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_RUST_ORANGE,
            CanCollide = true,
            CastShadow = true,
        })
    end

    return primaryPart
end

-- ============================================================================
-- 5. DEAD VEGETATION (HALOPHYTE REEDS / PAMPAS CORTADERAS)
-- ============================================================================
-- Sparse, dry, salt-bleached reeds and withered grass clusters.
-- Features:
--   - Low mud/salt tuft base
--   - Angled radiating thin blade parts creating natural dry pampas tussock
--   - Non-colliding blades to prevent player movement obstruction
-- Approx parts: 6 to 10 parts
function EpecuenEnvironmentBuilder.BuildDeadVegetation(
    model: Model,
    rootCF: CFrame,
    scale: number,
    opts: EnvironmentBuildOptions,
    rng: Random
): Part
    local folderReeds = getOrCreateFolder(model, "DryReeds")
    local folderBase = getOrCreateFolder(model, "TuftBase")

    local tuftRadius = (opts.Radius or rng:NextNumber(1.2, 2.2)) * scale
    local bladeHeight = (opts.Height or rng:NextNumber(2.4, 4.5)) * scale
    local bladeCount = rng:NextInteger(5, 8)

    -- 1. Base Saline Silt Tuft
    local baseTuft = makeCylinder(folderBase, {
        Name = "SalineRootTuft",
        Size = Vector3.new(0.3 * scale, tuftRadius * 1.5, tuftRadius * 1.5),
        CFrame = rootCF * CFrame.new(0, 0.15 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_DEAD_REED_MUD,
        CanCollide = false,
        CastShadow = true,
    })

    -- 2. Radiating Dry Pampas Reeds
    for i = 1, bladeCount do
        local yaw = math.rad((i - 1) * (360 / bladeCount) + rng:NextNumber(-20, 20))
        local outwardTilt = math.rad(rng:NextNumber(16, 42))
        local bLen = bladeHeight * rng:NextNumber(0.75, 1.25)
        local bThick = rng:NextNumber(0.18, 0.32) * scale
        local bWidth = rng:NextNumber(0.35, 0.65) * scale

        local bColor = if i % 2 == 0 then COLOR_DEAD_REED_BLEACHED else COLOR_DEAD_REED_DRY

        local bladeCF = rootCF * CFrame.Angles(0, yaw, 0)
            * CFrame.Angles(outwardTilt, 0, 0)
            * CFrame.new(0, bLen * 0.5, 0)

        makePart(folderReeds, {
            Name = string.format("ReedBlade_%d", i),
            Size = Vector3.new(bWidth, bLen, bThick),
            CFrame = bladeCF,
            Material = Enum.Material.Wood,
            Color = bColor,
            CanCollide = false, -- Non-colliding to allow smooth player walking through sparse reeds
            CastShadow = true,
        })
    end

    -- 3. Small Salt Encrustation on Tuft Core
    makePart(folderBase, {
        Name = "TuftSaltRim",
        Size = Vector3.new(tuftRadius * 0.8, 0.12 * scale, tuftRadius * 0.8),
        CFrame = rootCF * CFrame.new(0, 0.22 * scale, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SALT_CRUST_OFFWHITE,
        Reflectance = 0.20,
        CanCollide = false,
        CastShadow = false,
    })

    return baseTuft
end

-- ============================================================================
-- MAIN BUILD API: EpecuenEnvironmentBuilder.Build(options)
-- ============================================================================

function EpecuenEnvironmentBuilder.Build(opts: EnvironmentBuildOptions): Model
    assert(opts.ElementType ~= nil, "[EpecuenEnvironmentBuilder] ElementType is required")

    local eType = opts.ElementType
    local pos = opts.Position or Vector3.zero
    local rotY = opts.RotationY or 0
    local scale = opts.Scale or 1.0
    local seed = opts.Seed or 42

    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = opts.Name or (eType .. "_Detail")

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
    local primaryPart: Part? = nil

    if eType == "PetrifiedTree" then
        primaryPart = EpecuenEnvironmentBuilder.BuildPetrifiedTree(model, rootCF, scale, opts, rng)
    elseif eType == "SaltCrust" then
        primaryPart = EpecuenEnvironmentBuilder.BuildSaltCrust(model, rootCF, scale, opts, rng)
    elseif eType == "RubblePile" then
        primaryPart = EpecuenEnvironmentBuilder.BuildRubblePile(model, rootCF, scale, opts, rng)
    elseif eType == "RustedMetal" then
        primaryPart = EpecuenEnvironmentBuilder.BuildRustedMetal(model, rootCF, scale, opts, rng)
    elseif eType == "DeadVegetation" then
        primaryPart = EpecuenEnvironmentBuilder.BuildDeadVegetation(model, rootCF, scale, opts, rng)
    else
        error(string.format("[EpecuenEnvironmentBuilder] Unknown ElementType '%s'", tostring(eType)))
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
-- METRIC HELPER
-- ============================================================================

function EpecuenEnvironmentBuilder.GetPartCounts(): { [ElementType]: { Min: number, Max: number, Typical: number } }
    return {
        PetrifiedTree = { Min = 8, Max = 16, Typical = 12 },
        SaltCrust = { Min = 7, Max = 14, Typical = 10 },
        RubblePile = { Min = 9, Max = 16, Typical = 12 },
        RustedMetal = { Min = 5, Max = 10, Typical = 7 },
        DeadVegetation = { Min = 6, Max = 10, Typical = 8 },
    }
end

return EpecuenEnvironmentBuilder
