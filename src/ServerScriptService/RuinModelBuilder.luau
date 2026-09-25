--!strict
--[[
    RuinModelBuilder.luau
    Location: ServerScriptService/RuinModelBuilder.luau
    
    Procedural 3D Ruin and Abandoned Building Builder for "EPECUÉN: NO ESCAPE".
    Visual Reference: Villa Epecuén (Adolfo Alsina, Buenos Aires Province, Argentina).
    
    Aesthetic & Architectural Principles:
      - 1920s-1970s Argentine resort architecture: Art Deco, mid-century modernism,
        neoclassical masonry, and vernacular brick/stucco chalets.
      - Submerged in 1985 under 10 meters of hyper-saline mineral water and re-emerged:
          * Crumbled brick masonry walls with cracked stucco (ladrillo a la vista & revoque desprendido)
          * Jagged, uneven wall heights capped with angled fracture wedges
          * Breached wall openings and blown-out window apertures with cracked lintels
          * Skeletons of collapsed concrete roof slabs and tilted rusted steel I-beams / rebar
          * Salt-calcified crust and brine deposit fringes at base / flood lines
          * Rubble heaps, mortar mounds, and fallen slab debris clustered inside and around walls
          * Rusted corrugated sheet metal and iron rebar ties
          * Weathered concrete floors and foundation curbs
      - Built ENTIRELY from native Roblox primitives:
        Part (Block, Cylinder), WedgePart, CornerWedgePart.
        0 MeshParts, 0 asset IDs, 0 external textures, 0 plugins.
      - Deterministic generation via seed option.
      - Reusable builder: does NOT automatically instantiate into Workspace on require.
--]]

local RuinModelBuilder = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type BuildingType = 
    | "HouseSmall"
    | "HouseMedium"
    | "HotelRuins"
    | "ShopRuins"
    | "WallRuins"

export type RuinBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    Parent: Instance?,
    BuildingType: BuildingType?,
    Width: number?,
    Depth: number?,
    Height: number?,
    DamageLevel: number?, -- 0.0 (mostly standing) to 1.0 (heavily collapsed/demolished). Default ~0.55
    SaltLevel: number?,   -- 0.0 (dry pampas dust) to 1.0 (encrusted thick white mineral salt). Default ~0.65
    Seed: number?,        -- Deterministic PRNG seed. Default random or fixed.
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

export type CylinderConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

-- ============================================================================
-- AUTHENTIC COLOR & MATERIAL PALETTE (Villa Epecuén Post-Flood)
-- ============================================================================

local COLOR_CONCRETE_WEATHERED = Color3.fromRGB(156, 152, 144) -- Salt-weathered Argentine cement
local COLOR_CONCRETE_LIGHT     = Color3.fromRGB(178, 175, 168) -- Pale stucco / plaster
local COLOR_CONCRETE_DARK      = Color3.fromRGB(124, 120, 114) -- Water-stained low concrete
local COLOR_BRICK_RED          = Color3.fromRGB(168, 92, 72)   -- Ladrillo común cocido bonaerense
local COLOR_BRICK_WEATHERED    = Color3.fromRGB(142, 80, 64)   -- Submerged brick core
local COLOR_BRICK_SALTWASHED   = Color3.fromRGB(184, 122, 102) -- Bleached brick
local COLOR_SALT_CRUST_WHITE   = Color3.fromRGB(242, 244, 240) -- Pure calcified mineral brine crust
local COLOR_SALT_CRUST_CREAM   = Color3.fromRGB(226, 228, 220) -- Thick mineral salt deposits
local COLOR_MORTAR_RUBBLE      = Color3.fromRGB(144, 140, 132) -- Crumbled mortar & plaster chunks
local COLOR_SLATE_DEBRIS       = Color3.fromRGB(108, 104, 98)  -- Submerged floor tile / slate
local COLOR_RUST_METAL         = Color3.fromRGB(116, 66, 44)   -- Severely corroded structural steel
local COLOR_RUST_DARK          = Color3.fromRGB(82, 74, 68)    -- Exposed oxidized rebar

-- ============================================================================
-- HELPER CONSTRUCTORS
-- ============================================================================

local function localToWorld(rootCF: CFrame, localPos: Vector3, localAngles: Vector3?): CFrame
    local cf = rootCF * CFrame.new(localPos)
    if localAngles then
        cf = cf * CFrame.Angles(
            math.rad(localAngles.X),
            math.rad(localAngles.Y),
            math.rad(localAngles.Z)
        )
    end
    return cf
end

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
    c.Color = cfg.Color or COLOR_CONCRETE_WEATHERED
    c.Transparency = cfg.Transparency or 0
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
-- COMMON ARCHITECTURAL RUIN SUB-ASSEMBLIES
-- ============================================================================

-- Adds salt crust skirts along the foundation and lower wall edges
local function buildSaltCrustSkirt(
    folder: Folder,
    rootCF: CFrame,
    width: number,
    depth: number,
    saltLevel: number,
    rng: Random
)
    if saltLevel <= 0.05 then return end

    local crustHeight = math.clamp(0.6 + saltLevel * 1.8, 0.6, 2.5)
    local crustColor = (saltLevel > 0.6) and COLOR_SALT_CRUST_WHITE or COLOR_SALT_CRUST_CREAM

    -- Front salt deposit strip
    makePart(folder, {
        Name = "SaltCrust_Front",
        Size = Vector3.new(width + 1.2, crustHeight, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(0, crustHeight * 0.5, depth * 0.5 + 0.3)),
        Material = Enum.Material.Sandstone,
        Color = crustColor,
        CanCollide = false,
        CastShadow = false,
    })

    -- Rear salt deposit strip
    makePart(folder, {
        Name = "SaltCrust_Rear",
        Size = Vector3.new(width + 1.0, crustHeight * 0.9, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(0, crustHeight * 0.45, -depth * 0.5 - 0.3)),
        Material = Enum.Material.Sandstone,
        Color = crustColor,
        CanCollide = false,
        CastShadow = false,
    })

    -- Side salt deposit wedges (sloped mineral runoff)
    makeWedge(folder, {
        Name = "SaltRunoff_Left",
        Size = Vector3.new(0.8, crustHeight, depth * 0.7),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 - 0.3, crustHeight * 0.5, 0), Vector3.new(0, 90, 0)),
        Material = Enum.Material.Sandstone,
        Color = crustColor,
        CanCollide = false,
        CastShadow = false,
    })

    makeWedge(folder, {
        Name = "SaltRunoff_Right",
        Size = Vector3.new(0.8, crustHeight, depth * 0.7),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 + 0.3, crustHeight * 0.5, 0), Vector3.new(0, -90, 0)),
        Material = Enum.Material.Sandstone,
        Color = crustColor,
        CanCollide = false,
        CastShadow = false,
    })

    -- Clustered small salt mineral crust mounds
    local moundCount = math.floor(3 + saltLevel * 4)
    for i = 1, moundCount do
        local rx = rng:NextNumber(-width * 0.4, width * 0.4)
        local rz = rng:NextNumber(-depth * 0.4, depth * 0.4)
        local mRadius = rng:NextNumber(1.2, 2.8)
        local mHeight = rng:NextNumber(0.4, 0.9)
        makeCylinder(folder, {
            Name = "SaltDeposit_Mound_" .. i,
            Size = Vector3.new(mHeight, mRadius * 2, mRadius * 2),
            CFrame = localToWorld(rootCF, Vector3.new(rx, mHeight * 0.5, rz), Vector3.new(0, 0, 90)),
            Material = Enum.Material.SmoothPlastic,
            Color = crustColor,
            CanCollide = false,
            CastShadow = false,
        })
    end
end

-- Builds scattered rubble heaps, fallen brick clusters, and mortar chunks inside or outside
local function buildRubbleField(
    folder: Folder,
    rootCF: CFrame,
    width: number,
    depth: number,
    damageLevel: number,
    rng: Random
)
    local rubbleCount = math.floor(4 + damageLevel * 7)
    
    for i = 1, rubbleCount do
        local rx = rng:NextNumber(-width * 0.38, width * 0.38)
        local rz = rng:NextNumber(-depth * 0.38, depth * 0.38)
        local rRot = rng:NextNumber(0, 360)
        local rTilt = rng:NextNumber(-15, 25)
        
        local isBrick = (i % 2 == 0)
        local rMat = isBrick and Enum.Material.Brick or Enum.Material.Slate
        local rCol = isBrick and COLOR_BRICK_WEATHERED or COLOR_MORTAR_RUBBLE

        local sx = rng:NextNumber(2.0, 4.8)
        local sy = rng:NextNumber(0.8, 1.8)
        local sz = rng:NextNumber(2.0, 4.4)

        if i % 3 == 0 then
            -- Angled rubble wedge chunk
            makeWedge(folder, {
                Name = "Rubble_Wedge_" .. i,
                Size = Vector3.new(sx, sy, sz),
                CFrame = localToWorld(rootCF, Vector3.new(rx, sy * 0.5, rz), Vector3.new(rTilt, rRot, 0)),
                Material = rMat,
                Color = rCol,
                CanCollide = true,
                CastShadow = true,
            })
        else
            -- Irregular mortar block
            makePart(folder, {
                Name = "Rubble_Mound_" .. i,
                Size = Vector3.new(sx, sy, sz),
                CFrame = localToWorld(rootCF, Vector3.new(rx, sy * 0.5, rz), Vector3.new(rTilt * 0.5, rRot, 0)),
                Material = rMat,
                Color = rCol,
                CanCollide = true,
                CastShadow = true,
            })
        end
    end
end

-- Builds twisted rebar and rusted structural beams jutting out of broken walls
local function buildExposedRebarBeams(
    folder: Folder,
    rootCF: CFrame,
    anchorPos: Vector3,
    directionAngleY: number,
    beamLength: number,
    tiltAngleX: number
)
    -- Main rusted steel beam
    makePart(folder, {
        Name = "Exposed_SteelBeam",
        Size = Vector3.new(0.6, 0.6, beamLength),
        CFrame = localToWorld(rootCF, anchorPos, Vector3.new(tiltAngleX, directionAngleY, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_METAL,
        CanCollide = true,
        CastShadow = true,
    })

    -- Twisted rebar wire protruding from end
    makePart(folder, {
        Name = "Twisted_Rebar_End",
        Size = Vector3.new(0.2, 0.2, 2.5),
        CFrame = localToWorld(rootCF, anchorPos + Vector3.new(0, -beamLength * 0.35, 0), Vector3.new(tiltAngleX + 25, directionAngleY + 15, 10)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_DARK,
        CanCollide = false,
        CastShadow = false,
    })
end

-- ============================================================================
-- 1. HOUSE SMALL (Argentine Single-Story Vernacular Chalet Ruin)
-- ============================================================================
local function buildHouseSmall(
    model: Model,
    rootCF: CFrame,
    width: number,
    depth: number,
    height: number,
    damage: number,
    salt: number,
    rng: Random
)
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "RoofAndBeams")
    local fRubble     = getOrCreateFolder(model, "RubbleAndDebris")
    local fSalt       = getOrCreateFolder(model, "SaltCrust")

    -- 1. Foundation Slab (cracked concrete with salt-bleached floor)
    local fThick = 1.4
    makePart(fFoundation, {
        Name = "Foundation_FloorSlab",
        Size = Vector3.new(width, fThick, depth),
        CFrame = localToWorld(rootCF, Vector3.new(0, fThick * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Perimeter foundation curb step
    makePart(fFoundation, {
        Name = "Foundation_FrontStep",
        Size = Vector3.new(6.0, 0.6, 2.4),
        CFrame = localToWorld(rootCF, Vector3.new(0, 0.3, depth * 0.5 + 1.2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    local wallThick = 1.4
    local wBaseY = fThick
    local maxWallH = height - fThick

    -- 2. FRONT FACADE (Street side with broken doorway and window aperture)
    local frontH = maxWallH * (1.0 - damage * 0.3)
    local doorWidth = 4.2
    local winWidth = 4.8
    local doorHeight = frontH * 0.75

    -- Left front wall pillar (next to door)
    local fLeftW = (width - doorWidth - winWidth) * 0.45
    makePart(fWalls, {
        Name = "Wall_Front_Left",
        Size = Vector3.new(fLeftW, frontH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + fLeftW * 0.5, wBaseY + frontH * 0.5, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Jagged wedge on top of left front wall
    makeWedge(fWalls, {
        Name = "Wall_Front_Left_JaggedTop",
        Size = Vector3.new(fLeftW, 1.8, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + fLeftW * 0.5, wBaseY + frontH + 0.9, depth * 0.5 - wallThick * 0.5), Vector3.new(0, 180, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Doorway lintel above breached door
    local lintelH = frontH - doorHeight
    makePart(fWalls, {
        Name = "Doorway_Lintel_Upper",
        Size = Vector3.new(doorWidth + 0.6, lintelH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + fLeftW + doorWidth * 0.5, wBaseY + doorHeight + lintelH * 0.5, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- Central pier separating door and window
    local fMidW = (width - doorWidth - winWidth) * 0.3
    makePart(fWalls, {
        Name = "Wall_Front_CenterPier",
        Size = Vector3.new(fMidW, frontH * 0.9, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + fLeftW + doorWidth + fMidW * 0.5, wBaseY + frontH * 0.45, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Window sill (lower wall under broken window)
    local winSillH = frontH * 0.3
    makePart(fWalls, {
        Name = "Wall_Front_WindowSill",
        Size = Vector3.new(winWidth, winSillH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + fLeftW + doorWidth + fMidW + winWidth * 0.5, wBaseY + winSillH * 0.5, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Right front corner wall
    local fRightW = width - (fLeftW + doorWidth + fMidW + winWidth)
    local fRightH = frontH * 0.8
    makePart(fWalls, {
        Name = "Wall_Front_RightCorner",
        Size = Vector3.new(fRightW, fRightH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - fRightW * 0.5, wBaseY + fRightH * 0.5, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- 3. LEFT SIDE WALL (Partially standing with major fracture gap)
    local leftH = maxWallH * 0.85
    local leftSeg1Len = depth * 0.45
    makePart(fWalls, {
        Name = "Wall_Left_Segment1",
        Size = Vector3.new(wallThick, leftH, leftSeg1Len),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + leftH * 0.5, depth * 0.5 - leftSeg1Len * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Broken gap wedge
    makeWedge(fWalls, {
        Name = "Wall_Left_BrokenSlope",
        Size = Vector3.new(wallThick, 3.2, depth * 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + leftH * 0.5, -depth * 0.5 + depth * 0.45), Vector3.new(0, 0, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Rear segment of left wall (lower collapsed stump)
    local leftSeg2Len = depth * 0.3
    local leftSeg2H = maxWallH * 0.4
    makePart(fWalls, {
        Name = "Wall_Left_Segment2_Stump",
        Size = Vector3.new(wallThick, leftSeg2H, leftSeg2Len),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + leftSeg2H * 0.5, -depth * 0.5 + leftSeg2Len * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- 4. RIGHT SIDE WALL (Heavily cracked with exposed brick beneath plaster)
    local rightH = maxWallH * (0.95 - damage * 0.35)
    makePart(fWalls, {
        Name = "Wall_Right_Main",
        Size = Vector3.new(wallThick, rightH, depth * 0.8),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + rightH * 0.5, depth * 0.1)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })
    -- Exposed brick patch on right wall
    makePart(fWalls, {
        Name = "Wall_Right_ExposedBrickPatch",
        Size = Vector3.new(wallThick + 0.1, rightH * 0.45, depth * 0.35),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + rightH * 0.4, depth * 0.05)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- 5. REAR WALL (Low eroded parapet with open breach)
    local rearH = maxWallH * 0.55
    makePart(fWalls, {
        Name = "Wall_Rear_SolidPortion",
        Size = Vector3.new(width * 0.65, rearH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.15, wBaseY + rearH * 0.5, -depth * 0.5 + wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- 6. INTERIOR PARTITION WALL (Bathroom / kitchen divider)
    local partH = maxWallH * 0.6
    makePart(fWalls, {
        Name = "Wall_Interior_Partition",
        Size = Vector3.new(width * 0.4, partH, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.1, wBaseY + partH * 0.5, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_SALTWASHED,
    })

    -- 7. COLLAPSED ROOF SLAB (Angled concrete slab resting from wall into living room)
    local slabLen = depth * 0.65
    local slabW = width * 0.5
    local slabAngle = -28
    makePart(fRoof, {
        Name = "Collapsed_RoofSlab_Main",
        Size = Vector3.new(slabW, 0.8, slabLen),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.12, wBaseY + rightH * 0.6, depth * 0.05), Vector3.new(slabAngle, 12, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Exposed rebar beam supporting collapsed slab
    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(width * 0.35, wBaseY + rightH * 0.8, depth * 0.2), 35, slabLen * 0.9, -32)

    -- 8. RUBBLE & SALT ACCRETION
    buildRubbleField(fRubble, rootCF, width, depth, damage, rng)
    buildSaltCrustSkirt(fSalt, rootCF, width, depth, salt, rng)
end

-- ============================================================================
-- 2. HOUSE MEDIUM (Two-Room Argentine Chalet with Porch & Collapsed Gables)
-- ============================================================================
local function buildHouseMedium(
    model: Model,
    rootCF: CFrame,
    width: number,
    depth: number,
    height: number,
    damage: number,
    salt: number,
    rng: Random
)
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "RoofAndBeams")
    local fRubble     = getOrCreateFolder(model, "RubbleAndDebris")
    local fSalt       = getOrCreateFolder(model, "SaltCrust")

    -- Foundation slab with raised porch curb
    local fThick = 1.6
    makePart(fFoundation, {
        Name = "Foundation_MainSlab",
        Size = Vector3.new(width, fThick, depth),
        CFrame = localToWorld(rootCF, Vector3.new(0, fThick * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Porch steps
    makePart(fFoundation, {
        Name = "Porch_Step_Lower",
        Size = Vector3.new(8.0, 0.6, 2.2),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.15, 0.3, depth * 0.5 + 1.1)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    local wallThick = 1.6
    local wBaseY = fThick
    local maxWallH = height - fThick

    -- Front Porch Column (Left intact, Right snapped)
    local colH = maxWallH * 0.75
    makeCylinder(fWalls, {
        Name = "Porch_Column_Left_Intact",
        Size = Vector3.new(colH, 1.8, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.38, wBaseY + colH * 0.5, depth * 0.5 - 2.0), Vector3.new(0, 0, 90)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })
    -- Snapped right column stump
    makeCylinder(fWalls, {
        Name = "Porch_Column_Right_BrokenStump",
        Size = Vector3.new(colH * 0.35, 1.8, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.38, wBaseY + colH * 0.175, depth * 0.5 - 2.0), Vector3.new(0, 0, 90)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Front wall with entrance breach, wide bay window opening, and jagged gable
    local frontH = maxWallH * (0.95 - damage * 0.25)
    local leftWingW = width * 0.42
    makePart(fWalls, {
        Name = "Wall_Front_LeftWing",
        Size = Vector3.new(leftWingW, frontH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + leftWingW * 0.5, wBaseY + frontH * 0.5, depth * 0.5 - 4.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Triangular brick gable remnant on top of left wing
    makeWedge(fWalls, {
        Name = "Wall_Front_LeftGable_Remnant",
        Size = Vector3.new(wallThick, 3.4, leftWingW * 0.6),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + leftWingW * 0.5, wBaseY + frontH + 1.7, depth * 0.5 - 4.0), Vector3.new(0, 90, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Right front facade with missing window frame (open gap into room)
    local rightWingW = width * 0.4
    local rightFrontH = frontH * 0.8
    makePart(fWalls, {
        Name = "Wall_Front_RightWing_Solid",
        Size = Vector3.new(rightWingW * 0.45, rightFrontH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - rightWingW * 0.225, wBaseY + rightFrontH * 0.5, depth * 0.5 - 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })
    -- Concrete window lintel above breach
    makePart(fWalls, {
        Name = "Front_Window_CrackedLintel",
        Size = Vector3.new(rightWingW * 0.55, 0.8, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - rightWingW * 0.725, wBaseY + rightFrontH * 0.85, depth * 0.5 - 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Left Exterior Wall (Long unbroken brick run with salt stains)
    local leftWallH = maxWallH * 0.9
    makePart(fWalls, {
        Name = "Wall_Left_Long",
        Size = Vector3.new(wallThick, leftWallH, depth - 4.0),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + leftWallH * 0.5, -2.0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Right Exterior Wall (Severely cracked with collapsed midsection)
    local rightFrontSec = depth * 0.35
    makePart(fWalls, {
        Name = "Wall_Right_FrontSection",
        Size = Vector3.new(wallThick, maxWallH * 0.75, rightFrontSec),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + maxWallH * 0.375, depth * 0.5 - rightFrontSec * 0.5 - 4.0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })
    local rightBackSec = depth * 0.3
    makePart(fWalls, {
        Name = "Wall_Right_RearSection",
        Size = Vector3.new(wallThick, maxWallH * 0.6, rightBackSec),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + maxWallH * 0.3, -depth * 0.5 + rightBackSec * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Rear Wall with blown-out patio door
    local rearH = maxWallH * 0.7
    makePart(fWalls, {
        Name = "Wall_Rear_SolidHalf",
        Size = Vector3.new(width * 0.55, rearH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.2, wBaseY + rearH * 0.5, -depth * 0.5 + wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Central Corridor Spine Wall (Interior division)
    local spineH = maxWallH * 0.8
    makePart(fWalls, {
        Name = "Wall_Interior_Spine",
        Size = Vector3.new(1.0, spineH, depth * 0.6),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.05, wBaseY + spineH * 0.5, -depth * 0.1)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- Collapsed Concrete Ceiling Slab and Rusted Cross Beams
    local cSlabW = width * 0.55
    local cSlabD = depth * 0.45
    makePart(fRoof, {
        Name = "Roof_CollapsedSlab_Rear",
        Size = Vector3.new(cSlabW, 0.9, cSlabD),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.1, wBaseY + maxWallH * 0.45, -depth * 0.15), Vector3.new(-22, -10, 5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(-width * 0.35, wBaseY + leftWallH * 0.85, 0), -40, depth * 0.5, -28)
    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(width * 0.25, wBaseY + maxWallH * 0.65, -depth * 0.2), 60, depth * 0.4, -35)

    buildRubbleField(fRubble, rootCF, width, depth, damage, rng)
    buildSaltCrustSkirt(fSalt, rootCF, width, depth, salt, rng)
end

-- ============================================================================
-- 3. HOTEL RUINS (Two-Story Argentine Grand Resort / Thermal Hotel Shell)
-- ============================================================================
local function buildHotelRuins(
    model: Model,
    rootCF: CFrame,
    width: number,
    depth: number,
    height: number,
    damage: number,
    salt: number,
    rng: Random
)
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "RoofAndBeams")
    local fRubble     = getOrCreateFolder(model, "RubbleAndDebris")
    local fSalt       = getOrCreateFolder(model, "SaltCrust")

    -- 1. Grand Hotel Foundation Slab
    local fThick = 2.0
    makePart(fFoundation, {
        Name = "Hotel_Foundation_MainPlinth",
        Size = Vector3.new(width, fThick, depth),
        CFrame = localToWorld(rootCF, Vector3.new(0, fThick * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    local wallThick = 2.0
    local wBaseY = fThick
    local maxWallH = height - fThick
    local floor1H = maxWallH * 0.52
    local floor2H = maxWallH * 0.48

    -- 2. GROUND FLOOR FRONT COLONNADE (Art Deco Grand Lobby Entrance)
    local colCount = 5
    local colSpacing = (width - 8.0) / (colCount - 1)
    for i = 1, colCount do
        local colX = -width * 0.5 + 4.0 + (i - 1) * colSpacing
        -- If damaged, alternate broken/intact
        local isBroken = (damage > 0.4 and (i == 2 or i == 4))
        local curColH = isBroken and (floor1H * 0.4) or floor1H

        makePart(fWalls, {
            Name = "Hotel_LobbyColumn_" .. i,
            Size = Vector3.new(2.2, curColH, 2.2),
            CFrame = localToWorld(rootCF, Vector3.new(colX, wBaseY + curColH * 0.5, depth * 0.5 - 2.5)),
            Material = Enum.Material.Concrete,
            Color = isBroken and COLOR_CONCRETE_DARK or COLOR_CONCRETE_LIGHT,
        })

        if isBroken then
            -- Jagged fracture wedge atop broken pillar
            makeWedge(fWalls, {
                Name = "Hotel_LobbyColumn_Crack_" .. i,
                Size = Vector3.new(2.2, 1.2, 2.2),
                CFrame = localToWorld(rootCF, Vector3.new(colX, wBaseY + curColH + 0.6, depth * 0.5 - 2.5)),
                Material = Enum.Material.Concrete,
                Color = COLOR_CONCRETE_WEATHERED,
            })
        end
    end

    -- Grand Lobby Entablature / Architrave beam spanning columns
    makePart(fWalls, {
        Name = "Hotel_Entablature_Beam",
        Size = Vector3.new(width * 0.85, 1.8, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(0, wBaseY + floor1H + 0.9, depth * 0.5 - 2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- 3. SECOND FLOOR FACADE WITH BALCONY OPENINGS AND JAGGED CORNICE
    local secondFloorH = maxWallH - (floor1H + 1.8)
    local leftBalconyW = width * 0.42
    makePart(fWalls, {
        Name = "Hotel_UpperFacade_LeftWing",
        Size = Vector3.new(leftBalconyW, secondFloorH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.25, wBaseY + floor1H + 1.8 + secondFloorH * 0.5, depth * 0.5 - 2.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Jagged stepped parapet atop left wing (Art Deco silhouette)
    makePart(fWalls, {
        Name = "Hotel_ArtDeco_ParapetStep_1",
        Size = Vector3.new(leftBalconyW * 0.6, 2.2, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.25, wBaseY + maxWallH + 1.1, depth * 0.5 - 2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })
    makePart(fWalls, {
        Name = "Hotel_ArtDeco_ParapetStep_2",
        Size = Vector3.new(leftBalconyW * 0.3, 1.8, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.25, wBaseY + maxWallH + 3.1, depth * 0.5 - 2.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Right upper wing: collapsed downward with exposed rebar
    local rightUpperH = secondFloorH * 0.45
    makePart(fWalls, {
        Name = "Hotel_UpperFacade_RightRuin",
        Size = Vector3.new(width * 0.35, rightUpperH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.25, wBaseY + floor1H + 1.8 + rightUpperH * 0.5, depth * 0.5 - 2.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- 4. EXTERIOR SIDE WALLS (Towering 2-story brick shells)
    -- Left Side Wall: full height with upper window apertures
    makePart(fWalls, {
        Name = "Hotel_SideWall_Left",
        Size = Vector3.new(wallThick, maxWallH * 0.9, depth - 4.0),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + maxWallH * 0.45, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Window cutouts simulated with alternating piers on left wall
    for wIdx = 1, 3 do
        local winZ = -depth * 0.3 + (wIdx - 1) * (depth * 0.3)
        makePart(fWalls, {
            Name = "Hotel_LeftWindow_Sill_" .. wIdx,
            Size = Vector3.new(wallThick + 0.2, 1.0, 4.2),
            CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + floor1H * 0.4, winZ)),
            Material = Enum.Material.Concrete,
            Color = COLOR_CONCRETE_LIGHT,
        })
    end

    -- Right Side Wall: severely broken at floor 2
    makePart(fWalls, {
        Name = "Hotel_SideWall_Right_Lower",
        Size = Vector3.new(wallThick, floor1H * 1.1, depth - 4.0),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + floor1H * 0.55, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- 5. REAR WALL (Heavy masonry facade with collapsed service courtyard wing)
    local rearH = maxWallH * 0.65
    makePart(fWalls, {
        Name = "Hotel_RearWall_Main",
        Size = Vector3.new(width * 0.7, rearH, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.1, wBaseY + rearH * 0.5, -depth * 0.5 + wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- 6. INTERIOR CENTRAL CORRIDOR & COLLAPSED MEZZANINE
    -- Mezzanine Floor Slab (Partially collapsed into grand lobby)
    local mezzW = width * 0.6
    local mezzD = depth * 0.5
    makePart(fRoof, {
        Name = "Hotel_Mezzanine_CollapsedSlab",
        Size = Vector3.new(mezzW, 1.2, mezzD),
        CFrame = localToWorld(rootCF, Vector3.new(0, wBaseY + floor1H * 0.7, 0), Vector3.new(-18, 5, 4)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Massive exposed steel I-beam dangling from upper roof
    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(-width * 0.2, wBaseY + maxWallH * 0.85, depth * 0.1), 45, depth * 0.6, -38)
    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(width * 0.15, wBaseY + floor1H + 2.0, -depth * 0.1), -70, depth * 0.5, -25)

    -- 7. EXTENSIVE RUBBLE & DEEP SALT ACCRETIONS
    buildRubbleField(fRubble, rootCF, width, depth, damage * 1.2, rng)
    buildSaltCrustSkirt(fSalt, rootCF, width, depth, salt * 1.15, rng)
end

-- ============================================================================
-- 4. SHOP RUINS (Commercial Storefront with Broken Marquee & Stepped Parapet)
-- ============================================================================
local function buildShopRuins(
    model: Model,
    rootCF: CFrame,
    width: number,
    depth: number,
    height: number,
    damage: number,
    salt: number,
    rng: Random
)
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRoof       = getOrCreateFolder(model, "RoofAndBeams")
    local fRubble     = getOrCreateFolder(model, "RubbleAndDebris")
    local fSalt       = getOrCreateFolder(model, "SaltCrust")

    -- Foundation slab with entrance welcome mat recess
    local fThick = 1.4
    makePart(fFoundation, {
        Name = "Shop_FoundationSlab",
        Size = Vector3.new(width, fThick, depth),
        CFrame = localToWorld(rootCF, Vector3.new(0, fThick * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    local wallThick = 1.4
    local wBaseY = fThick
    local maxWallH = height - fThick

    -- Commercial Storefront: Wide display window breach & recessed entry
    local pierW = 3.2
    local displayWinW = width - (pierW * 2 + 5.0) -- remaining for display window
    local shopEntryW = 5.0

    -- Left store corner pier
    makePart(fWalls, {
        Name = "Shop_FrontPier_Left",
        Size = Vector3.new(pierW, maxWallH * 0.85, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + pierW * 0.5, wBaseY + maxWallH * 0.425, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- Right store corner pier
    makePart(fWalls, {
        Name = "Shop_FrontPier_Right",
        Size = Vector3.new(pierW, maxWallH * 0.9, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - pierW * 0.5, wBaseY + maxWallH * 0.45, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- Display window low masonry bulkhead (base under display glass)
    makePart(fWalls, {
        Name = "Shop_DisplayWindow_Bulkhead",
        Size = Vector3.new(displayWinW, 2.2, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + pierW + displayWinW * 0.5, wBaseY + 1.1, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Storefront lintel / cracked marquee band (Marquesina comercial)
    makePart(fWalls, {
        Name = "Shop_Marquee_Lintel",
        Size = Vector3.new(width - 2.0, 2.2, wallThick + 0.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, wBaseY + maxWallH * 0.65, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Art Deco stepped parapet atop storefront
    makePart(fWalls, {
        Name = "Shop_SteppedParapet_Center",
        Size = Vector3.new(width * 0.45, 2.8, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(0, wBaseY + maxWallH * 0.65 + 2.5, depth * 0.5 - wallThick * 0.5)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })

    -- Side walls (Party walls / medianeras separating shop plots)
    makePart(fWalls, {
        Name = "Shop_PartyWall_Left",
        Size = Vector3.new(wallThick, maxWallH * 0.8, depth - 2.0),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + wallThick * 0.5, wBaseY + maxWallH * 0.4, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    makePart(fWalls, {
        Name = "Shop_PartyWall_Right",
        Size = Vector3.new(wallThick, maxWallH * 0.75, depth - 2.0),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - wallThick * 0.5, wBaseY + maxWallH * 0.375, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Rear storage room wall with low breach
    makePart(fWalls, {
        Name = "Shop_RearWall_Storage",
        Size = Vector3.new(width * 0.75, maxWallH * 0.5, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.1, wBaseY + maxWallH * 0.25, -depth * 0.5 + wallThick * 0.5)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Rusted corrugated metal awning fragment dangling from marquee
    makePart(fRoof, {
        Name = "Shop_RustedAwning_Sheet",
        Size = Vector3.new(width * 0.45, 0.3, 3.8),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.1, wBaseY + maxWallH * 0.62, depth * 0.5 + 1.2), Vector3.new(-32, 10, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_METAL,
    })

    -- Collapsed roof beam
    buildExposedRebarBeams(fRoof, rootCF, Vector3.new(0, wBaseY + maxWallH * 0.7, -depth * 0.1), 0, depth * 0.65, -30)

    buildRubbleField(fRubble, rootCF, width, depth, damage, rng)
    buildSaltCrustSkirt(fSalt, rootCF, width, depth, salt, rng)
end

-- ============================================================================
-- 5. WALL RUINS (Freestanding Property Perimeter Wall & Broken Colonnade)
-- ============================================================================
local function buildWallRuins(
    model: Model,
    rootCF: CFrame,
    width: number,
    depth: number,
    height: number,
    damage: number,
    salt: number,
    rng: Random
)
    local fFoundation = getOrCreateFolder(model, "Foundation")
    local fWalls      = getOrCreateFolder(model, "Walls")
    local fRubble     = getOrCreateFolder(model, "RubbleAndDebris")
    local fSalt       = getOrCreateFolder(model, "SaltCrust")

    -- Foundation trench plinth
    local fThick = 1.0
    makePart(fFoundation, {
        Name = "WallRuin_FoundationBase",
        Size = Vector3.new(width, fThick, depth),
        CFrame = localToWorld(rootCF, Vector3.new(0, fThick * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    local wallThick = math.clamp(depth * 0.35, 1.2, 2.2)
    local wBaseY = fThick
    local maxWallH = height - fThick

    -- Three structural brick pilasters with broken wall infill
    local pillarW = 2.4
    local pCount = 3
    local spacing = (width - pillarW) / (pCount - 1)

    for i = 1, pCount do
        local px = -width * 0.5 + pillarW * 0.5 + (i - 1) * spacing
        local pHeight = (i == 2) and (maxWallH * (0.6 - damage * 0.2)) or (maxWallH * (0.95 - damage * 0.15))

        makePart(fWalls, {
            Name = "WallRuin_Pilaster_" .. i,
            Size = Vector3.new(pillarW, pHeight, wallThick + 0.6),
            CFrame = localToWorld(rootCF, Vector3.new(px, wBaseY + pHeight * 0.5, 0)),
            Material = Enum.Material.Brick,
            Color = COLOR_BRICK_RED,
        })

        -- Jagged top wedge on pilaster
        makeWedge(fWalls, {
            Name = "WallRuin_Pilaster_Fracture_" .. i,
            Size = Vector3.new(pillarW, 1.6, wallThick + 0.6),
            CFrame = localToWorld(rootCF, Vector3.new(px, wBaseY + pHeight + 0.8, 0), Vector3.new(0, (i % 2 == 0) and 180 or 0, 0)),
            Material = Enum.Material.Brick,
            Color = COLOR_BRICK_WEATHERED,
        })
    end

    -- Infill Wall Bay 1 (Left): partially standing with irregular wedge break
    local bay1W = spacing - pillarW
    local bay1H = maxWallH * 0.55
    makePart(fWalls, {
        Name = "WallRuin_Bay1_Lower",
        Size = Vector3.new(bay1W, bay1H, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + pillarW + bay1W * 0.5, wBaseY + bay1H * 0.5, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_LIGHT,
    })
    makeWedge(fWalls, {
        Name = "WallRuin_Bay1_TopSlope",
        Size = Vector3.new(bay1W * 0.7, 2.0, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(-width * 0.5 + pillarW + bay1W * 0.4, wBaseY + bay1H + 1.0, 0)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_WEATHERED,
    })

    -- Infill Wall Bay 2 (Right): mostly collapsed into rubble mound with gap
    local bay2W = spacing - pillarW
    local bay2H = maxWallH * 0.28
    makePart(fWalls, {
        Name = "WallRuin_Bay2_CollapsedStump",
        Size = Vector3.new(bay2W, bay2H, wallThick),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - pillarW - bay2W * 0.5, wBaseY + bay2H * 0.5, 0)),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_WEATHERED,
    })

    -- Fallen wall slab lying flat in the mud beside the breach
    makePart(fRubble, {
        Name = "WallRuin_FallenSlab",
        Size = Vector3.new(bay2W * 0.85, 0.8, 4.8),
        CFrame = localToWorld(rootCF, Vector3.new(width * 0.5 - pillarW - bay2W * 0.5, 0.4, depth * 0.35), Vector3.new(4, 12, -2)),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    buildRubbleField(fRubble, rootCF, width, depth * 1.5, damage, rng)
    buildSaltCrustSkirt(fSalt, rootCF, width, depth, salt, rng)
end

-- ============================================================================
-- MAIN BUILD ENTRY POINT
-- ============================================================================

--[[
    Builds a complete, geometrically authentic abandoned Villa Epecuén ruin.
    
    Usage Example:
      local RuinModelBuilder = require(ServerScriptService.RuinModelBuilder)
      local ruin = RuinModelBuilder.Build({
          BuildingType = "HouseSmall",
          Position = Vector3.new(-100, 16, -400),
          RotationY = 90,
          DamageLevel = 0.6,
          SaltLevel = 0.7,
      })
--]]
function RuinModelBuilder.Build(options: RuinBuildOptions?): Model
    local opts = options or {}

    local pos         = opts.Position or Vector3.new(0, 0, 0)
    local rotY        = opts.RotationY or 0
    local bType       = opts.BuildingType or "HouseSmall" :: BuildingType
    local damage      = math.clamp(opts.DamageLevel or 0.55, 0.0, 1.0)
    local salt        = math.clamp(opts.SaltLevel or 0.65, 0.0, 1.0)
    local seedVal     = opts.Seed or math.floor(math.abs(pos.X * 1000 + pos.Z))
    local rng         = Random.new(seedVal)

    -- Default building footprints tuned to realistic Argentine villa scale
    local width  = opts.Width
    local depth  = opts.Depth
    local height = opts.Height

    if bType == "HouseSmall" then
        width  = width or 24.0
        depth  = depth or 20.0
        height = height or 14.0
    elseif bType == "HouseMedium" then
        width  = width or 36.0
        depth  = depth or 28.0
        height = height or 18.0
    elseif bType == "HotelRuins" then
        width  = width or 54.0
        depth  = depth or 38.0
        height = height or 28.0
    elseif bType == "ShopRuins" then
        width  = width or 30.0
        depth  = depth or 24.0
        height = height or 16.0
    elseif bType == "WallRuins" then
        width  = width or 24.0
        depth  = depth or 6.0
        height = height or 10.0
    else
        -- Fallback default dimensions
        width  = width or 24.0
        depth  = depth or 20.0
        height = height or 14.0
    end

    local model = Instance.new("Model")
    model.Name = opts.Name or (bType .. "_Ruin")

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

    -- Dispatch to archetype constructor
    if bType == "HouseSmall" then
        buildHouseSmall(model, rootCF, width, depth, height, damage, salt, rng)
    elseif bType == "HouseMedium" then
        buildHouseMedium(model, rootCF, width, depth, height, damage, salt, rng)
    elseif bType == "HotelRuins" then
        buildHotelRuins(model, rootCF, width, depth, height, damage, salt, rng)
    elseif bType == "ShopRuins" then
        buildShopRuins(model, rootCF, width, depth, height, damage, salt, rng)
    elseif bType == "WallRuins" then
        buildWallRuins(model, rootCF, width, depth, height, damage, salt, rng)
    end

    -- Set PrimaryPart to the foundation slab if available
    local foundationFolder = model:FindFirstChild("Foundation")
    if foundationFolder then
        local primary = foundationFolder:FindFirstChildWhichIsA("BasePart")
        if primary then
            model.PrimaryPart = primary
        end
    end

    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

return RuinModelBuilder
