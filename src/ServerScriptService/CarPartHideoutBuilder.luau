--!strict
--[[
    CarPartHideoutBuilder.luau
    Location: ServerScriptService/CarPartHideoutBuilder.luau

    Reusable Physical Hideout Structure Builder for "EPECUÉN: NO ESCAPE".
    Visual Reference: Post-flood ruins of Villa Epecuén (Adolfo Alsina, Buenos Aires, Argentina).

    PURPOSE:
      Constructs authentic, compact, salt-damaged architectural hideouts for the 40 canonical
      vehicle repair part locations defined in CarPartObjectiveSystem.
      Each structure provides believable environmental concealment so components are NOT
      sitting out in the open.

    STRICT CONSTRAINTS:
      - 100% Native Roblox Geometry: Part, WedgePart, CornerWedgePart ONLY.
      - 0 MeshParts, 0 external asset IDs, 0 textures, 0 plugins, 0 lights.
      - Pure environmental geometry: NO vehicle parts, NO items, NO gameplay, NO UI.
      - NO automatic Workspace spawning on require.
      - Target: 12–25 parts per hideout archetype.
      - Provides an internal invisible marker part named "HidePoint" for downstream positioning.
--]]

local CarPartHideoutBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type HideoutType =
    | "StorageCabinet"
    | "WorkshopBench"
    | "WoodenCrates"
    | "UtilityShed"
    | "RuinedShelving"
    | "Locker"
    | "ArchiveStorage"
    | "IndustrialStorage"

export type HideoutBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    HideoutType: (HideoutType | string)?,
    Seed: number?,
    DamageLevel: number?, -- 0.0 (minimal damage) to 1.0 (heavy destruction)
    SaltLevel: number?,   -- 0.0 (clean) to 1.0 (heavy white mineral crust)
    Parent: Instance?,
    Name: string?,
}

export type HideoutMetric = {
    HideoutType: string,
    PartCount: number,
    Footprint: Vector3,
    Description: string,
    ConcealmentMechanism: string,
}

type PartConfig = {
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
-- COLOR & MATERIAL PALETTE (Post-Flood Hyper-Saline Epecuén)
-- ============================================================================

local COLOR_WOOD_OLD          = Color3.fromRGB(112, 94, 76)
local COLOR_WOOD_ROTTED       = Color3.fromRGB(82, 68, 54)
local COLOR_WOOD_PLANK        = Color3.fromRGB(128, 108, 88)
local COLOR_METAL_RUST_DARK   = Color3.fromRGB(86, 52, 38)
local COLOR_METAL_RUST_ORANGE = Color3.fromRGB(124, 68, 44)
local COLOR_METAL_GALVANIZED  = Color3.fromRGB(130, 134, 132)
local COLOR_CONCRETE_PALE     = Color3.fromRGB(168, 164, 154)
local COLOR_CONCRETE_DARK     = Color3.fromRGB(118, 114, 108)
local COLOR_BRICK_RED         = Color3.fromRGB(152, 78, 58)
local COLOR_SALT_WHITE        = Color3.fromRGB(242, 244, 240)
local COLOR_SALT_CRUST        = Color3.fromRGB(224, 226, 218)
local COLOR_DEBRIS_GRAY       = Color3.fromRGB(140, 136, 128)

-- Supported Archetypes List
local SUPPORTED_TYPES: { HideoutType } = {
    "StorageCabinet",
    "WorkshopBench",
    "WoodenCrates",
    "UtilityShed",
    "RuinedShelving",
    "Locker",
    "ArchiveStorage",
    "IndustrialStorage",
}

-- ============================================================================
-- PRIMITIVE CREATION HELPERS
-- ============================================================================

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.Concrete
    p.Color = cfg.Color or COLOR_CONCRETE_PALE
    p.Transparency = cfg.Transparency or 0.0
    p.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    p.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeWedge(parent: Instance, cfg: PartConfig): WedgePart
    local w = Instance.new("WedgePart")
    w.Name = cfg.Name
    w.Size = cfg.Size
    w.CFrame = cfg.CFrame
    w.Material = cfg.Material or Enum.Material.Concrete
    w.Color = cfg.Color or COLOR_CONCRETE_PALE
    w.Transparency = cfg.Transparency or 0.0
    w.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    w.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    w.Anchored = true
    w.TopSurface = Enum.SurfaceType.Smooth
    w.BottomSurface = Enum.SurfaceType.Smooth
    w.Parent = parent
    return w
end

local function makeCornerWedge(parent: Instance, cfg: PartConfig): CornerWedgePart
    local cw = Instance.new("CornerWedgePart")
    cw.Name = cfg.Name
    cw.Size = cfg.Size
    cw.CFrame = cfg.CFrame
    cw.Material = cfg.Material or Enum.Material.Concrete
    cw.Color = cfg.Color or COLOR_CONCRETE_PALE
    cw.Transparency = cfg.Transparency or 0.0
    cw.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    cw.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    cw.Anchored = true
    cw.TopSurface = Enum.SurfaceType.Smooth
    cw.BottomSurface = Enum.SurfaceType.Smooth
    cw.Parent = parent
    return cw
end

local function makeHidePoint(parent: Instance, cframe: CFrame): Part
    local hp = Instance.new("Part")
    hp.Name = "HidePoint"
    hp.Size = Vector3.new(0.6, 0.6, 0.6)
    hp.CFrame = cframe
    hp.Transparency = 1.0
    hp.CanCollide = false
    hp.CanTouch = false
    hp.CanQuery = true
    hp.CastShadow = false
    hp.Anchored = true
    hp:SetAttribute("IsHidePoint", true)
    hp.Parent = parent
    return hp
end

-- ============================================================================
-- ARCHETYPE BUILDERS (12–25 Parts Each)
-- ============================================================================

-- 1. StorageCabinet (~17 parts)
-- Double-door steel/wood utility cupboard with warped door, internal shelf and salt deposits
local function buildStorageCabinet(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Plinth Base
    makePart(parent, {
        Name = "Cabinet_Plinth",
        Size = Vector3.new(3.6, 0.4, 2.0),
        CFrame = rootCF * CFrame.new(0, 0.2, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Back Wall
    makePart(parent, {
        Name = "Cabinet_Back",
        Size = Vector3.new(3.4, 5.0, 0.2),
        CFrame = rootCF * CFrame.new(0, 2.9, -0.9),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Left Wall
    makePart(parent, {
        Name = "Cabinet_SideLeft",
        Size = Vector3.new(0.2, 5.0, 1.8),
        CFrame = rootCF * CFrame.new(-1.7, 2.9, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })

    -- Right Wall
    makePart(parent, {
        Name = "Cabinet_SideRight",
        Size = Vector3.new(0.2, 5.0, 1.8),
        CFrame = rootCF * CFrame.new(1.7, 2.9, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Top Cap
    makePart(parent, {
        Name = "Cabinet_TopCap",
        Size = Vector3.new(3.6, 0.3, 2.0),
        CFrame = rootCF * CFrame.new(0, 5.45, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Interior Mid Shelf
    makePart(parent, {
        Name = "Cabinet_ShelfMid",
        Size = Vector3.new(3.2, 0.15, 1.6),
        CFrame = rootCF * CFrame.new(0, 3.2, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Interior Bottom Shelf
    makePart(parent, {
        Name = "Cabinet_ShelfBottom",
        Size = Vector3.new(3.2, 0.15, 1.6),
        CFrame = rootCF * CFrame.new(0, 0.5, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Left Door (Hanging Ajar at angle)
    local doorAngle = math.rad(-35 - (damage * 30))
    makePart(parent, {
        Name = "Cabinet_DoorLeft",
        Size = Vector3.new(1.6, 4.8, 0.15),
        CFrame = rootCF * CFrame.new(-1.6, 2.85, 0.9) * CFrame.Angles(0, doorAngle, 0) * CFrame.new(0.8, 0, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_ORANGE,
        CanCollide = false,
    })

    -- Right Door (Fallen / Tilted into cabinet cavity)
    local tiltAngle = math.rad(15 + (damage * 25))
    makePart(parent, {
        Name = "Cabinet_DoorRight",
        Size = Vector3.new(1.5, 4.6, 0.15),
        CFrame = rootCF * CFrame.new(0.9, 1.8, 0.5) * CFrame.Angles(math.rad(12), 0, tiltAngle),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
        CanCollide = false,
    })

    -- Door Hinge Brackets (2 parts)
    makePart(parent, {
        Name = "Cabinet_HingeTop",
        Size = Vector3.new(0.2, 0.4, 0.2),
        CFrame = rootCF * CFrame.new(-1.65, 4.9, 0.9),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Cabinet_HingeBottom",
        Size = Vector3.new(0.2, 0.4, 0.2),
        CFrame = rootCF * CFrame.new(-1.65, 0.9, 0.9),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Salt Evaporite Shelf on Top (2 parts)
    if salt > 0.25 then
        makePart(parent, {
            Name = "Cabinet_SaltCrustTop",
            Size = Vector3.new(3.8, 0.2, 2.1),
            CFrame = rootCF * CFrame.new(0, 5.65, 0),
            Material = Enum.Material.Concrete,
            Color = COLOR_SALT_WHITE,
        })
    end
    makeWedge(parent, {
        Name = "Cabinet_SaltDriftLeft",
        Size = Vector3.new(1.8, 0.5, 0.6),
        CFrame = rootCF * CFrame.new(-1.8, 0.25, 0) * CFrame.Angles(0, math.rad(90), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- Fallen Debris & Rubble at Foot (2 parts)
    makePart(parent, {
        Name = "Cabinet_MortarSpall",
        Size = Vector3.new(0.9, 0.4, 0.7),
        CFrame = rootCF * CFrame.new(1.1, 0.2, 1.2) * CFrame.Angles(math.rad(10), math.rad(25), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_DEBRIS_GRAY,
        CanCollide = false,
    })
    makeWedge(parent, {
        Name = "Cabinet_RubbleWedge",
        Size = Vector3.new(0.7, 0.35, 0.8),
        CFrame = rootCF * CFrame.new(-0.8, 0.18, 1.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_DEBRIS_GRAY,
        CanCollide = false,
    })

    -- Concealment Anchor Point
    -- Tucked on the lower interior shelf, shielded behind the ajar left door
    makeHidePoint(parent, rootCF * CFrame.new(-0.5, 1.1, 0.1))
end

-- 2. WorkshopBench (~18 parts)
-- Heavy timber & iron angle mechanic's bench with tool backsplash and lower shelf
local function buildWorkshopBench(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Main Heavy Work Surface Slab
    makePart(parent, {
        Name = "Bench_TopSlab",
        Size = Vector3.new(5.2, 0.4, 2.4),
        CFrame = rootCF * CFrame.new(0, 2.8, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
    })

    -- Backsplash Tool Rack Board
    makePart(parent, {
        Name = "Bench_Backboard",
        Size = Vector3.new(5.2, 2.0, 0.25),
        CFrame = rootCF * CFrame.new(0, 4.0, -1.08),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- 4 Heavy Angle-Iron Legs
    local legPositions = {
        Vector3.new(-2.3, 1.3, -0.9),
        Vector3.new(2.3, 1.3, -0.9),
        Vector3.new(-2.3, 1.3, 0.9),
        Vector3.new(2.3, 1.3, 0.9),
    }
    for i, lPos in ipairs(legPositions) do
        makePart(parent, {
            Name = string.format("Bench_Leg_%d", i),
            Size = Vector3.new(0.35, 2.6, 0.35),
            CFrame = rootCF * CFrame.new(lPos),
            Material = Enum.Material.CorrodedMetal,
            Color = COLOR_METAL_RUST_DARK,
        })
    end

    -- Bottom Foot Shelf (Slats) (3 parts)
    for i = 1, 3 do
        local zOffset = -0.6 + (i - 1) * 0.6
        makePart(parent, {
            Name = string.format("Bench_BottomSlat_%d", i),
            Size = Vector3.new(4.6, 0.15, 0.45),
            CFrame = rootCF * CFrame.new(0, 0.45, zOffset),
            Material = Enum.Material.WoodPlanks,
            Color = COLOR_WOOD_ROTTED,
        })
    end

    -- Side Cross Braces (2 parts)
    makePart(parent, {
        Name = "Bench_SideBraceLeft",
        Size = Vector3.new(0.2, 0.25, 1.8),
        CFrame = rootCF * CFrame.new(-2.3, 1.5, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })
    makePart(parent, {
        Name = "Bench_SideBraceRight",
        Size = Vector3.new(0.2, 0.25, 1.8),
        CFrame = rootCF * CFrame.new(2.3, 1.5, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Broken Bench Vise Bracket
    makePart(parent, {
        Name = "Bench_ViseBase",
        Size = Vector3.new(0.7, 0.6, 0.8),
        CFrame = rootCF * CFrame.new(2.0, 3.25, 0.7),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })

    -- Slanted Storage Tool Caddy under bench (conceals hiding recess)
    makePart(parent, {
        Name = "Bench_ToolCaddy",
        Size = Vector3.new(1.4, 0.9, 1.2),
        CFrame = rootCF * CFrame.new(0.8, 0.9, 0.1) * CFrame.Angles(0, math.rad(14), 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_OLD,
    })

    -- Salt Crust Base Footing (2 parts)
    makePart(parent, {
        Name = "Bench_SaltFootingLeft",
        Size = Vector3.new(0.9, 0.35, 2.2),
        CFrame = rootCF * CFrame.new(-2.3, 0.18, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })
    makePart(parent, {
        Name = "Bench_SaltFootingRight",
        Size = Vector3.new(0.9, 0.35, 2.2),
        CFrame = rootCF * CFrame.new(2.3, 0.18, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })

    -- Concealment Anchor Point
    -- Deeply sheltered underneath the heavy top slab on the lower bottom shelf behind the tool caddy
    makeHidePoint(parent, rootCF * CFrame.new(-0.7, 1.0, -0.2))
end

-- 3. WoodenCrates (~18 parts)
-- Cluster of broken Argentine supply and agricultural shipping crates with open slats
local function buildWoodenCrates(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Base Pallet Timber Runners (3 parts)
    makePart(parent, {
        Name = "Crates_Runner1",
        Size = Vector3.new(0.3, 0.35, 4.2),
        CFrame = rootCF * CFrame.new(-1.5, 0.18, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Crates_Runner2",
        Size = Vector3.new(0.3, 0.35, 4.2),
        CFrame = rootCF * CFrame.new(0, 0.18, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Crates_Runner3",
        Size = Vector3.new(0.3, 0.35, 4.2),
        CFrame = rootCF * CFrame.new(1.5, 0.18, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Pallet Deck Planks (3 parts)
    makePart(parent, {
        Name = "Crates_PalletPlankA",
        Size = Vector3.new(3.4, 0.12, 1.1),
        CFrame = rootCF * CFrame.new(0, 0.42, -1.2),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })
    makePart(parent, {
        Name = "Crates_PalletPlankB",
        Size = Vector3.new(3.4, 0.12, 1.1),
        CFrame = rootCF * CFrame.new(0, 0.42, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })
    makePart(parent, {
        Name = "Crates_PalletPlankC",
        Size = Vector3.new(3.4, 0.12, 1.1),
        CFrame = rootCF * CFrame.new(0, 0.42, 1.2),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })

    -- Crate A: Large Solid Bottom Crate Left
    makePart(parent, {
        Name = "Crates_MainBoxA",
        Size = Vector3.new(2.0, 2.2, 2.0),
        CFrame = rootCF * CFrame.new(-0.8, 1.58, -0.8),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_OLD,
    })

    -- Crate B: Open/Broken Crate Right (Creates the hollow hiding cavity)
    makePart(parent, {
        Name = "Crates_CavityWallBack",
        Size = Vector3.new(1.8, 2.0, 0.18),
        CFrame = rootCF * CFrame.new(0.9, 1.48, -0.8),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Crates_CavityWallRight",
        Size = Vector3.new(0.18, 2.0, 1.8),
        CFrame = rootCF * CFrame.new(1.7, 1.48, 0.1),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Crate C: Stacked Upper Crate (Offset diagonal)
    makePart(parent, {
        Name = "Crates_TopBoxC",
        Size = Vector3.new(1.7, 1.6, 1.7),
        CFrame = rootCF * CFrame.new(-0.4, 3.48, -0.6) * CFrame.Angles(0, math.rad(18), 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })

    -- Fallen Planks Leaning Across Front (Conceals internal cavity) (3 parts)
    makePart(parent, {
        Name = "Crates_LeaningPlank1",
        Size = Vector3.new(0.2, 2.8, 0.5),
        CFrame = rootCF * CFrame.new(0.3, 1.5, 0.9) * CFrame.Angles(math.rad(-22), math.rad(12), 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Crates_LeaningPlank2",
        Size = Vector3.new(0.2, 2.5, 0.4),
        CFrame = rootCF * CFrame.new(0.7, 1.4, 0.8) * CFrame.Angles(math.rad(-26), math.rad(-8), 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
    })
    makePart(parent, {
        Name = "Crates_ShatteredLid",
        Size = Vector3.new(1.8, 0.15, 1.4),
        CFrame = rootCF * CFrame.new(0.8, 2.6, 0.1) * CFrame.Angles(math.rad(16), 0, math.rad(-14)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Salt Encrustation on base corners & top (3 parts)
    makePart(parent, {
        Name = "Crates_SaltRindA",
        Size = Vector3.new(2.2, 0.25, 0.6),
        CFrame = rootCF * CFrame.new(-0.8, 0.55, 0.5),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makeWedge(parent, {
        Name = "Crates_SaltWedge",
        Size = Vector3.new(1.2, 0.5, 1.2),
        CFrame = rootCF * CFrame.new(1.6, 0.35, 1.2) * CFrame.Angles(0, math.rad(45), 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- Concealment Anchor Point
    -- Safely enclosed inside the hollow nook of Crate B behind the leaning planks
    makeHidePoint(parent, rootCF * CFrame.new(0.8, 1.1, 0.1))
end

-- 4. UtilityShed (~19 parts)
-- Compact brick foundation shelter with corrugated iron roof and meter board
local function buildUtilityShed(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Concrete Base Foundation Slab
    makePart(parent, {
        Name = "Shed_Foundation",
        Size = Vector3.new(6.0, 0.5, 5.0),
        CFrame = rootCF * CFrame.new(0, 0.25, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Back Masonry Wall
    makePart(parent, {
        Name = "Shed_BackWall",
        Size = Vector3.new(5.6, 5.2, 0.6),
        CFrame = rootCF * CFrame.new(0, 2.9, -2.1),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Left Masonry Wall
    makePart(parent, {
        Name = "Shed_LeftWall",
        Size = Vector3.new(0.6, 5.2, 4.4),
        CFrame = rootCF * CFrame.new(-2.6, 2.9, 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
    })

    -- Right Front Return Wall (Partial)
    makePart(parent, {
        Name = "Shed_RightWall",
        Size = Vector3.new(0.6, 4.2, 2.6),
        CFrame = rootCF * CFrame.new(2.6, 2.4, -0.9),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- Concrete Roof Lintel Beam
    makePart(parent, {
        Name = "Shed_LintelBeam",
        Size = Vector3.new(5.8, 0.5, 0.7),
        CFrame = rootCF * CFrame.new(0, 5.3, -2.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- Slanted Corrugated Sheet Roof (Partially collapsed) (2 parts)
    makePart(parent, {
        Name = "Shed_RoofSheetA",
        Size = Vector3.new(3.2, 0.15, 4.6),
        CFrame = rootCF * CFrame.new(-1.2, 5.2, 0) * CFrame.Angles(0, 0, math.rad(-8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })
    makePart(parent, {
        Name = "Shed_RoofSheetB",
        Size = Vector3.new(2.6, 0.15, 3.8),
        CFrame = rootCF * CFrame.new(1.3, 4.6, -0.4) * CFrame.Angles(math.rad(6), 0, math.rad(-22)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Interior Electrical / Valve Enclosure Cabinet
    makePart(parent, {
        Name = "Shed_MeterCabinet",
        Size = Vector3.new(1.8, 2.4, 0.7),
        CFrame = rootCF * CFrame.new(-1.3, 3.2, -1.5),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_GALVANIZED,
    })

    -- Meter Cabinet Door Ajar
    makePart(parent, {
        Name = "Shed_MeterDoor",
        Size = Vector3.new(0.9, 2.3, 0.1),
        CFrame = rootCF * CFrame.new(-0.8, 3.2, -1.1) * CFrame.Angles(0, math.rad(40), 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
        CanCollide = false,
    })

    -- Lower Concrete Sump Trench Kerb
    makePart(parent, {
        Name = "Shed_SumpKerb",
        Size = Vector3.new(2.4, 0.6, 0.3),
        CFrame = rootCF * CFrame.new(-1.3, 0.75, -0.3),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Fallen Masonry Rubble / Slump (3 parts)
    makeWedge(parent, {
        Name = "Shed_RubbleSlope",
        Size = Vector3.new(1.8, 1.0, 1.4),
        CFrame = rootCF * CFrame.new(1.8, 0.9, 0.8),
        Material = Enum.Material.Concrete,
        Color = COLOR_DEBRIS_GRAY,
    })
    makePart(parent, {
        Name = "Shed_BrokenBrickChunk",
        Size = Vector3.new(0.8, 0.5, 0.7),
        CFrame = rootCF * CFrame.new(1.5, 0.7, -0.6) * CFrame.Angles(math.rad(15), math.rad(30), 0),
        Material = Enum.Material.Brick,
        Color = COLOR_BRICK_RED,
        CanCollide = false,
    })

    -- Salt Evaporite Shelf & White Encrustations (3 parts)
    makePart(parent, {
        Name = "Shed_SaltTideLine",
        Size = Vector3.new(5.8, 0.4, 0.3),
        CFrame = rootCF * CFrame.new(0, 1.2, -2.25),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makePart(parent, {
        Name = "Shed_SaltPuddle",
        Size = Vector3.new(2.2, 0.1, 2.0),
        CFrame = rootCF * CFrame.new(0.4, 0.55, 0.4),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- Concealment Anchor Point
    -- Concealed deep inside the meter cabinet recess against the back wall
    makeHidePoint(parent, rootCF * CFrame.new(-1.3, 2.6, -1.45))
end

-- 5. RuinedShelving (~18 parts)
-- Slotted angle-iron industrial shelving unit deformed and warped by flood currents
local function buildRuinedShelving(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- 4 Vertical Steel Angle Uprights
    local posts = {
        { name = "Shelving_PostFL", cf = CFrame.new(-2.1, 3.0, 0.9) },
        { name = "Shelving_PostFR", cf = CFrame.new(2.1, 2.8, 0.9) * CFrame.Angles(0, 0, math.rad(-5)) },
        { name = "Shelving_PostBL", cf = CFrame.new(-2.1, 3.0, -0.9) },
        { name = "Shelving_PostBR", cf = CFrame.new(2.1, 2.8, -0.9) * CFrame.Angles(0, 0, math.rad(-5)) },
    }
    for _, p in ipairs(posts) do
        makePart(parent, {
            Name = p.name,
            Size = Vector3.new(0.2, 5.8, 0.2),
            CFrame = rootCF * p.cf,
            Material = Enum.Material.Metal,
            Color = COLOR_METAL_RUST_DARK,
        })
    end

    -- 3 Horizontal Tier Shelves
    makePart(parent, {
        Name = "Shelving_TierBottom",
        Size = Vector3.new(4.3, 0.15, 1.9),
        CFrame = rootCF * CFrame.new(0, 0.8, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })
    makePart(parent, {
        Name = "Shelving_TierMid",
        Size = Vector3.new(4.3, 0.15, 1.9),
        CFrame = rootCF * CFrame.new(0, 2.9, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })
    -- Top Shelf (Buckled downward in middle)
    makePart(parent, {
        Name = "Shelving_TierTopLeft",
        Size = Vector3.new(2.3, 0.15, 1.9),
        CFrame = rootCF * CFrame.new(-1.1, 5.1, 0) * CFrame.Angles(0, 0, math.rad(-7)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Shelving_TierTopRight",
        Size = Vector3.new(2.3, 0.15, 1.9),
        CFrame = rootCF * CFrame.new(1.1, 4.9, 0) * CFrame.Angles(0, 0, math.rad(9)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Rear Cross-Bracing Straps (2 parts)
    makePart(parent, {
        Name = "Shelving_Brace1",
        Size = Vector3.new(4.4, 0.1, 0.05),
        CFrame = rootCF * CFrame.new(0, 3.1, -0.92) * CFrame.Angles(0, 0, math.rad(28)),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Shelving_Brace2",
        Size = Vector3.new(4.4, 0.1, 0.05),
        CFrame = rootCF * CFrame.new(0, 3.1, -0.92) * CFrame.Angles(0, 0, math.rad(-28)),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Fallen / Slumped Metal Shelf Divider (Shields hiding compartment)
    makePart(parent, {
        Name = "Shelving_ShieldPanel",
        Size = Vector3.new(1.6, 2.0, 0.15),
        CFrame = rootCF * CFrame.new(0.6, 1.9, 0.8) * CFrame.Angles(math.rad(14), math.rad(10), 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })

    -- Footing Anchor Pads with Mineral Crust (4 parts)
    makePart(parent, {
        Name = "Shelving_FootingL",
        Size = Vector3.new(1.0, 0.3, 2.4),
        CFrame = rootCF * CFrame.new(-2.1, 0.15, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makePart(parent, {
        Name = "Shelving_FootingR",
        Size = Vector3.new(1.0, 0.3, 2.4),
        CFrame = rootCF * CFrame.new(2.1, 0.15, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })
    makeWedge(parent, {
        Name = "Shelving_SaltDebris",
        Size = Vector3.new(0.8, 0.4, 1.0),
        CFrame = rootCF * CFrame.new(-0.8, 0.2, 0.6),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
        CanCollide = false,
    })

    -- Concealment Anchor Point
    -- Stationed on the middle tier shelf, tucked in behind the slumped metal shield panel
    makeHidePoint(parent, rootCF * CFrame.new(0.4, 3.2, -0.2))
end

-- 6. Locker (~17 parts)
-- Dual-column employee locker bank; one door ripped ajar, one crushed inward
local function buildLocker(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Plinth Base
    makePart(parent, {
        Name = "Locker_BasePlinth",
        Size = Vector3.new(3.4, 0.4, 1.8),
        CFrame = rootCF * CFrame.new(0, 0.2, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Outer Carcass Shell (Back, Left, Right, Top) (4 parts)
    makePart(parent, {
        Name = "Locker_BackWall",
        Size = Vector3.new(3.2, 5.4, 0.15),
        CFrame = rootCF * CFrame.new(0, 3.1, -0.85),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Locker_SideLeft",
        Size = Vector3.new(0.15, 5.4, 1.7),
        CFrame = rootCF * CFrame.new(-1.6, 3.1, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_GALVANIZED,
    })
    makePart(parent, {
        Name = "Locker_SideRight",
        Size = Vector3.new(0.15, 5.4, 1.7),
        CFrame = rootCF * CFrame.new(1.6, 3.1, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_ORANGE,
    })
    makePart(parent, {
        Name = "Locker_TopRoof",
        Size = Vector3.new(3.4, 0.25, 1.8),
        CFrame = rootCF * CFrame.new(0, 5.85, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Central Divider Mullion
    makePart(parent, {
        Name = "Locker_CenterDivider",
        Size = Vector3.new(0.15, 5.4, 1.6),
        CFrame = rootCF * CFrame.new(0, 3.1, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Internal Hat Shelves (2 parts)
    makePart(parent, {
        Name = "Locker_ShelfLeft",
        Size = Vector3.new(1.4, 0.1, 1.5),
        CFrame = rootCF * CFrame.new(-0.8, 4.6, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_ORANGE,
    })
    makePart(parent, {
        Name = "Locker_ShelfRight",
        Size = Vector3.new(1.4, 0.1, 1.5),
        CFrame = rootCF * CFrame.new(0.8, 4.6, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Left Compartment Door: Wide Open Ajar
    makePart(parent, {
        Name = "Locker_DoorLeftOpen",
        Size = Vector3.new(1.45, 5.1, 0.12),
        CFrame = rootCF * CFrame.new(-1.55, 3.0, 0.85) * CFrame.Angles(0, math.rad(-48), 0) * CFrame.new(0.72, 0, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_GALVANIZED,
        CanCollide = false,
    })

    -- Right Compartment Door: Buckled and Crushed Inward
    makePart(parent, {
        Name = "Locker_DoorRightCrushed",
        Size = Vector3.new(1.4, 5.0, 0.12),
        CFrame = rootCF * CFrame.new(0.8, 2.95, 0.55) * CFrame.Angles(math.rad(8), math.rad(14), math.rad(-6)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
        CanCollide = false,
    })

    -- Lower Salt Crust Bedding & Drift (3 parts)
    makePart(parent, {
        Name = "Locker_SaltBed",
        Size = Vector3.new(3.8, 0.3, 2.2),
        CFrame = rootCF * CFrame.new(0, 0.15, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makeWedge(parent, {
        Name = "Locker_SaltWedgeFront",
        Size = Vector3.new(1.6, 0.4, 0.8),
        CFrame = rootCF * CFrame.new(0.8, 0.2, 1.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })
    makePart(parent, {
        Name = "Locker_FloorSediment",
        Size = Vector3.new(1.3, 0.25, 1.3),
        CFrame = rootCF * CFrame.new(-0.8, 0.5, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
        CanCollide = false,
    })

    -- Concealment Anchor Point
    -- Deep within the shadowed base recess of the left locker compartment behind the open door
    makeHidePoint(parent, rootCF * CFrame.new(-0.8, 1.1, -0.2))
end

-- 7. ArchiveStorage (~18 parts)
-- Weathered wooden parish / municipal document cabinet with pigeonhole registers and broken drawers
local function buildArchiveStorage(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Solid Timber Plinth
    makePart(parent, {
        Name = "Archive_Plinth",
        Size = Vector3.new(4.2, 0.45, 2.2),
        CFrame = rootCF * CFrame.new(0, 0.22, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Main Cabinet Structure (Back, Left, Right, Crown) (4 parts)
    makePart(parent, {
        Name = "Archive_Backing",
        Size = Vector3.new(3.8, 5.0, 0.2),
        CFrame = rootCF * CFrame.new(0, 2.9, -0.95),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Archive_UprightLeft",
        Size = Vector3.new(0.3, 5.0, 2.0),
        CFrame = rootCF * CFrame.new(-1.85, 2.9, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
    })
    makePart(parent, {
        Name = "Archive_UprightRight",
        Size = Vector3.new(0.3, 5.0, 2.0),
        CFrame = rootCF * CFrame.new(1.85, 2.9, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
    })
    makePart(parent, {
        Name = "Archive_CorniceTop",
        Size = Vector3.new(4.3, 0.4, 2.3),
        CFrame = rootCF * CFrame.new(0, 5.5, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
    })

    -- Horizontal Shelves (3 parts)
    makePart(parent, {
        Name = "Archive_ShelfLow",
        Size = Vector3.new(3.4, 0.2, 1.8),
        CFrame = rootCF * CFrame.new(0, 1.8, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })
    makePart(parent, {
        Name = "Archive_ShelfMid",
        Size = Vector3.new(3.4, 0.2, 1.8),
        CFrame = rootCF * CFrame.new(0, 3.4, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })
    makePart(parent, {
        Name = "Archive_ShelfTop",
        Size = Vector3.new(3.4, 0.2, 1.8),
        CFrame = rootCF * CFrame.new(0, 4.8, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_PLANK,
    })

    -- Vertical Pigeonhole Cubby Dividers (2 parts)
    makePart(parent, {
        Name = "Archive_Divider1",
        Size = Vector3.new(0.15, 1.4, 1.7),
        CFrame = rootCF * CFrame.new(-0.6, 4.1, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Archive_Divider2",
        Size = Vector3.new(0.15, 1.4, 1.7),
        CFrame = rootCF * CFrame.new(0.6, 4.1, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_ROTTED,
    })

    -- Fallen Slumped Drawer Box (Conceals bottom corner) (2 parts)
    makePart(parent, {
        Name = "Archive_FallenDrawer",
        Size = Vector3.new(1.6, 0.9, 1.5),
        CFrame = rootCF * CFrame.new(-0.7, 0.9, 0.3) * CFrame.Angles(0, math.rad(16), math.rad(6)),
        Material = Enum.Material.WoodPlanks,
        Color = COLOR_WOOD_ROTTED,
    })
    makePart(parent, {
        Name = "Archive_DrawerFront",
        Size = Vector3.new(1.5, 0.8, 0.15),
        CFrame = rootCF * CFrame.new(0.9, 1.0, 0.8) * CFrame.Angles(math.rad(22), 0, 0),
        Material = Enum.Material.Wood,
        Color = COLOR_WOOD_OLD,
        CanCollide = false,
    })

    -- Calcified Plaster & Mineral Encrustations (3 parts)
    makePart(parent, {
        Name = "Archive_SaltSpall",
        Size = Vector3.new(4.4, 0.25, 1.2),
        CFrame = rootCF * CFrame.new(0, 5.7, -0.4),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makeWedge(parent, {
        Name = "Archive_SaltCornerWedge",
        Size = Vector3.new(1.2, 0.6, 1.0),
        CFrame = rootCF * CFrame.new(1.8, 0.3, 0.9),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- Concealment Anchor Point
    -- Deeply sheltered in the lower right archive compartment behind the drawer front
    makeHidePoint(parent, rootCF * CFrame.new(0.9, 1.0, -0.3))
end

-- 8. IndustrialStorage (~19 parts)
-- Heavy reinforced concrete & steel bunker containment for slaughterhouse / water infrastructure
local function buildIndustrialStorage(parent: Model, rootCF: CFrame, rng: Random, damage: number, salt: number)
    -- Concrete Base Sump Foundation
    makePart(parent, {
        Name = "Industrial_BaseSump",
        Size = Vector3.new(5.6, 0.6, 4.4),
        CFrame = rootCF * CFrame.new(0, 0.3, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Reinforced Concrete Back Wall
    makePart(parent, {
        Name = "Industrial_BackWall",
        Size = Vector3.new(5.4, 4.6, 0.7),
        CFrame = rootCF * CFrame.new(0, 2.7, -1.8),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_DARK,
    })

    -- Concrete Left Retaining Wall
    makePart(parent, {
        Name = "Industrial_WallLeft",
        Size = Vector3.new(0.7, 4.6, 3.8),
        CFrame = rootCF * CFrame.new(-2.3, 2.7, 0.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- Concrete Right Retaining Wall
    makePart(parent, {
        Name = "Industrial_WallRight",
        Size = Vector3.new(0.7, 4.6, 3.8),
        CFrame = rootCF * CFrame.new(2.3, 2.7, 0.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- Heavy Overhead Header Slab
    makePart(parent, {
        Name = "Industrial_RoofHeader",
        Size = Vector3.new(5.6, 0.6, 1.6),
        CFrame = rootCF * CFrame.new(0, 4.8, -1.2),
        Material = Enum.Material.Concrete,
        Color = COLOR_CONCRETE_PALE,
    })

    -- Rusted Heavy Diamond-Plate Hatch Frame
    makePart(parent, {
        Name = "Industrial_HatchFrame",
        Size = Vector3.new(3.8, 0.25, 2.6),
        CFrame = rootCF * CFrame.new(0, 4.5, 0.7) * CFrame.Angles(math.rad(10), 0, 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_DARK,
    })

    -- Slanted Dislodged Iron Inspection Cover (Conceals chamber inside)
    makePart(parent, {
        Name = "Industrial_HatchCover",
        Size = Vector3.new(3.2, 0.18, 2.2),
        CFrame = rootCF * CFrame.new(0.2, 2.4, 1.2) * CFrame.Angles(math.rad(-28), math.rad(8), 0),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })

    -- Corroded Industrial Pipe Stubs / Valve Flange (3 parts)
    makePart(parent, {
        Name = "Industrial_PipeA",
        Size = Vector3.new(0.5, 2.2, 0.5),
        CFrame = rootCF * CFrame.new(-1.4, 2.2, -1.2),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Industrial_PipeB",
        Size = Vector3.new(1.8, 0.5, 0.5),
        CFrame = rootCF * CFrame.new(-0.7, 3.1, -1.2),
        Material = Enum.Material.Metal,
        Color = COLOR_METAL_RUST_DARK,
    })
    makePart(parent, {
        Name = "Industrial_ValveWheel",
        Size = Vector3.new(0.9, 0.2, 0.9),
        CFrame = rootCF * CFrame.new(0.2, 3.1, -1.2),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_METAL_RUST_ORANGE,
    })

    -- Concrete Rubble & Debris Chunks (2 parts)
    makePart(parent, {
        Name = "Industrial_SpallChunk",
        Size = Vector3.new(1.2, 0.7, 0.9),
        CFrame = rootCF * CFrame.new(1.4, 0.9, 0.8) * CFrame.Angles(0, math.rad(35), math.rad(12)),
        Material = Enum.Material.Concrete,
        Color = COLOR_DEBRIS_GRAY,
        CanCollide = false,
    })
    makeWedge(parent, {
        Name = "Industrial_ConcreteWedge",
        Size = Vector3.new(1.0, 0.6, 1.4),
        CFrame = rootCF * CFrame.new(-1.6, 0.8, 1.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_DEBRIS_GRAY,
        CanCollide = false,
    })

    -- Salt Evaporite High Waterline & Shelf (3 parts)
    makePart(parent, {
        Name = "Industrial_SaltLineLeft",
        Size = Vector3.new(0.8, 0.35, 3.9),
        CFrame = rootCF * CFrame.new(-2.3, 1.6, 0.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makePart(parent, {
        Name = "Industrial_SaltLineRight",
        Size = Vector3.new(0.8, 0.35, 3.9),
        CFrame = rootCF * CFrame.new(2.3, 1.6, 0.1),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_WHITE,
    })
    makePart(parent, {
        Name = "Industrial_SaltFloorBed",
        Size = Vector3.new(3.8, 0.15, 2.6),
        CFrame = rootCF * CFrame.new(0, 0.65, 0),
        Material = Enum.Material.Concrete,
        Color = COLOR_SALT_CRUST,
    })

    -- Concealment Anchor Point
    -- Sheltered in the dry recessed sump pit beneath the pipe manifold and behind the fallen iron hatch
    makeHidePoint(parent, rootCF * CFrame.new(0.3, 1.2, -0.4))
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Builds a procedural, deterministic hideout environmental structure.
--- Returns the constructed Model containing all geometry and the "HidePoint" marker.
function CarPartHideoutBuilder.Build(options: HideoutBuildOptions): Model
    local pos = options.Position or Vector3.new(0, 0, 0)
    local rotY = options.RotationY or 0
    local rawType = options.HideoutType or "StorageCabinet"
    local seed = options.Seed or 5151
    local damage = math.clamp(options.DamageLevel or 0.65, 0.0, 1.0)
    local salt = math.clamp(options.SaltLevel or 0.70, 0.0, 1.0)

    -- Normalize archetype selection
    local hideoutType: HideoutType = "StorageCabinet"
    for _, st in ipairs(SUPPORTED_TYPES) do
        if string.lower(st) == string.lower(rawType) then
            hideoutType = st
            break
        end
    end

    local rng = Random.new(seed)

    local model = Instance.new("Model")
    model.Name = options.Name or string.format("Hideout_%s", hideoutType)

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

    if hideoutType == "StorageCabinet" then
        buildStorageCabinet(model, rootCF, rng, damage, salt)
    elseif hideoutType == "WorkshopBench" then
        buildWorkshopBench(model, rootCF, rng, damage, salt)
    elseif hideoutType == "WoodenCrates" then
        buildWoodenCrates(model, rootCF, rng, damage, salt)
    elseif hideoutType == "UtilityShed" then
        buildUtilityShed(model, rootCF, rng, damage, salt)
    elseif hideoutType == "RuinedShelving" then
        buildRuinedShelving(model, rootCF, rng, damage, salt)
    elseif hideoutType == "Locker" then
        buildLocker(model, rootCF, rng, damage, salt)
    elseif hideoutType == "ArchiveStorage" then
        buildArchiveStorage(model, rootCF, rng, damage, salt)
    elseif hideoutType == "IndustrialStorage" then
        buildIndustrialStorage(model, rootCF, rng, damage, salt)
    end

    -- Designate PrimaryPart
    local primary = model:FindFirstChildWhichIsA("BasePart")
    if primary then
        model.PrimaryPart = primary
    end

    if options.Parent then
        model.Parent = options.Parent
    end

    return model
end

--- Returns comprehensive metrics, part count estimates, and footprint data for all 8 archetypes.
function CarPartHideoutBuilder.GetMetrics(): { [string]: HideoutMetric }
    return {
        StorageCabinet = {
            HideoutType = "StorageCabinet",
            PartCount = 16,
            Footprint = Vector3.new(3.8, 5.7, 2.2),
            Description = "Weathered double-door utility cabinet with ajar door and interior shelving.",
            ConcealmentMechanism = "Interior lower shelf behind tilted ajar door.",
        },
        WorkshopBench = {
            HideoutType = "WorkshopBench",
            PartCount = 18,
            Footprint = Vector3.new(5.2, 4.2, 2.6),
            Description = "Heavy timber mechanic's workbench with tool backsplash, lower shelf and vice mount.",
            ConcealmentMechanism = "Lower foot-shelf cavity sheltered under work slab and behind tool caddy.",
        },
        WoodenCrates = {
            HideoutType = "WoodenCrates",
            PartCount = 17,
            Footprint = Vector3.new(4.2, 3.8, 4.2),
            Description = "Stack of cracked transport and farm supply crates with broken wooden slats.",
            ConcealmentMechanism = "Hollow interior pocket formed between pallet runners and leaning planks.",
        },
        UtilityShed = {
            HideoutType = "UtilityShed",
            PartCount = 19,
            Footprint = Vector3.new(6.0, 5.5, 5.0),
            Description = "Compact brick and corrugated iron electrical/pump shelter with meter cabinet.",
            ConcealmentMechanism = "Recessed wall-mounted utility cabinet with open access door.",
        },
        RuinedShelving = {
            HideoutType = "RuinedShelving",
            PartCount = 18,
            Footprint = Vector3.new(4.4, 5.8, 2.4),
            Description = "Deformed angle-iron industrial shelving with slumped structural tiers.",
            ConcealmentMechanism = "Middle storage tier recessed behind a collapsed metal shield panel.",
        },
        Locker = {
            HideoutType = "Locker",
            PartCount = 16,
            Footprint = Vector3.new(3.8, 5.9, 2.2),
            Description = "Twin institutional locker bank with one ajar door and one crushed compartment.",
            ConcealmentMechanism = "Dark floor recess of left locker unit sheltered by open outer door.",
        },
        ArchiveStorage = {
            HideoutType = "ArchiveStorage",
            PartCount = 18,
            Footprint = Vector3.new(4.4, 5.7, 2.4),
            Description = "Solid wood administrative record rack with pigeonholes and fallen register drawer.",
            ConcealmentMechanism = "Lower right archive compartment shielded behind dislodged drawer front.",
        },
        IndustrialStorage = {
            HideoutType = "IndustrialStorage",
            PartCount = 19,
            Footprint = Vector3.new(5.6, 5.1, 4.4),
            Description = "Reinforced concrete bunker sump with rusted pipe manifold and iron hatch cover.",
            ConcealmentMechanism = "Dry recessed concrete sump trench sheltered under pipework and hatch.",
        },
    }
end

--- Exposes list of all supported archetype names
function CarPartHideoutBuilder.GetSupportedTypes(): { HideoutType }
    return table.clone(SUPPORTED_TYPES)
end

return CarPartHideoutBuilder
