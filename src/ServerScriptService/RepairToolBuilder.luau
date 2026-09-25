--!strict
-- ============================================================================
-- RepairToolBuilder.luau
-- Location: roblox/src/ServerScriptService/RepairToolBuilder.luau
--
-- EPECUÉN: NO ESCAPE - Physical Automotive Mechanic's Toolbox Builder
--
-- PURPOSE:
-- Procedural physical model builder for an abandoned, weathered automotive
-- mechanic's toolbox appropriate for Laguna Epecuén's hyper-saline flood ruins.
-- This physical kit contains realistic hand tools required for repairing
-- the stranded Fiat Cronos.
--
-- VISUAL DESIGN:
--   - Heavy old steel mechanic's toolbox with reinforced bottom and folded lips.
--   - Decades of exposure: heavy oxidation, rust pitting, and calcite/salt crusts.
--   - Partially open, slightly warped lid revealing interior compartments.
--   - Visible realistic hand tools inside:
--       * Combination open/box-end wrench
--       * Mechanic's flathead screwdriver with fluted grip
--       * Heavy-duty automotive slip-joint pliers
--       * Hex socket / drive ratchet tool
--   - Completely free of immersion-breaking quest text or labels.
--   - Looks like authentic abandoned Argentine garage equipment.
--
-- GEOMETRY & ASSET CONSTRAINTS:
--   - 100% native Roblox geometry: Part (Block, Cylinder), WedgePart, CornerWedgePart.
--   - Exactly ZERO MeshParts, external meshes, textures, asset IDs, or plugins.
--   - Targeted lightweight budget: exactly 30 parts (within 20–35 target range).
--   - Anchored = true on all geometry.
--   - Main chassis has CanCollide = true; small interior tools and decorative
--     surface deposits have CanCollide = false to avoid physics hitches.
--   - ZERO scripts, ProximityPrompts, ClickDetectors, or Touched listeners.
--   - ZERO collection, inventory, or repair gameplay logic.
--   - ZERO automatic instantiation or placement on require.
-- ============================================================================

local RepairToolBuilder = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type ToolboxBuildOptions = {
    Position: Vector3?,
    RotationY: number?,
    DamageLevel: number?, -- 0.0 to 1.0 (default: 0.75)
    SaltLevel: number?,   -- 0.0 to 1.0 (default: 0.80)
    Parent: Instance?,
    Name: string?,
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

type CylinderConfig = {
    Name: string,
    Size: Vector3, -- (Diameter, Length, Diameter) when aligned with Z or Y
    CFrame: CFrame,
    Orientation: ("X" | "Y" | "Z")?,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

type WedgeConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

type CornerWedgeConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
}

-- ----------------------------------------------------------------------------
-- PALETTE: EPECUÉN HYPER-SALINE WEATHERING & INDUSTRIAL WEAR
-- ----------------------------------------------------------------------------

-- Toolbox Body & Sheet Metal
local COLOR_TOOLBOX_RED_OXIDE  = Color3.fromRGB(118, 46, 36)   -- Faded Argentine industrial red
local COLOR_TOOLBOX_RUST_DARK  = Color3.fromRGB(68, 50, 44)    -- Deep ferric oxidation
local COLOR_TOOLBOX_METAL_RAW  = Color3.fromRGB(85, 82, 78)    -- Exposed worn steel
local COLOR_TOOLBOX_LATCH_ZINC = Color3.fromRGB(135, 132, 126) -- Tarnished zinc clasp

-- Salt / Calcite Deposits (Laguna Epecuén Brine Minerals)
local COLOR_SALT_CRUST_CHALK   = Color3.fromRGB(232, 229, 222) -- Thick evaporite calcite crust
local COLOR_SALT_CRUST_STAIN   = Color3.fromRGB(210, 206, 196) -- Semi-translucent brine residue

-- Hand Tools
local COLOR_TOOL_STEEL         = Color3.fromRGB(138, 142, 145) -- Weathered forged tool steel
local COLOR_TOOL_STEEL_DARK    = Color3.fromRGB(98, 102, 105)  -- Shadowed / oxidized tool body
local COLOR_SCREWDRIVER_HANDLE = Color3.fromRGB(145, 62, 32)   -- Vintage translucent amber-red acetate
local COLOR_PLIERS_GRIP        = Color3.fromRGB(48, 50, 52)    -- Weathered vulcanized rubber / dark iron

-- ----------------------------------------------------------------------------
-- PRIMITIVE INSTANTIATION HELPERS
-- ----------------------------------------------------------------------------

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Shape = Enum.PartType.Block
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.CorrodedMetal
    p.Color = cfg.Color or COLOR_TOOLBOX_RED_OXIDE
    p.Transparency = cfg.Transparency or 0.0
    p.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    p.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeCylinder(parent: Instance, cfg: CylinderConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Shape = Enum.PartType.Cylinder

    local orient = cfg.Orientation or "Y"
    if orient == "Y" then
        -- Native Roblox Cylinder length is on X axis. Rotate to align with local Y.
        p.Size = Vector3.new(cfg.Size.Y, cfg.Size.X, cfg.Size.Z)
        p.CFrame = cfg.CFrame * CFrame.Angles(0, 0, math.pi / 2)
    elseif orient == "Z" then
        -- Rotate to align with local Z.
        p.Size = Vector3.new(cfg.Size.Z, cfg.Size.Y, cfg.Size.X)
        p.CFrame = cfg.CFrame * CFrame.Angles(0, math.pi / 2, 0)
    else
        p.Size = cfg.Size
        p.CFrame = cfg.CFrame
    end

    p.Material = cfg.Material or Enum.Material.Metal
    p.Color = cfg.Color or COLOR_TOOL_STEEL
    p.Transparency = cfg.Transparency or 0.0
    p.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    p.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeWedge(parent: Instance, cfg: WedgeConfig): WedgePart
    local w = Instance.new("WedgePart")
    w.Name = cfg.Name
    w.Size = cfg.Size
    w.CFrame = cfg.CFrame
    w.Material = cfg.Material or Enum.Material.CorrodedMetal
    w.Color = cfg.Color or COLOR_TOOL_STEEL
    w.Transparency = cfg.Transparency or 0.0
    w.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    w.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    w.Anchored = true
    w.TopSurface = Enum.SurfaceType.Smooth
    w.BottomSurface = Enum.SurfaceType.Smooth
    w.Parent = parent
    return w
end

local function makeCornerWedge(parent: Instance, cfg: CornerWedgeConfig): CornerWedgePart
    local cw = Instance.new("CornerWedgePart")
    cw.Name = cfg.Name
    cw.Size = cfg.Size
    cw.CFrame = cfg.CFrame
    cw.Material = cfg.Material or Enum.Material.Sandstone
    cw.Color = cfg.Color or COLOR_SALT_CRUST_CHALK
    cw.Transparency = cfg.Transparency or 0.0
    cw.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    cw.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    cw.Anchored = true
    cw.TopSurface = Enum.SurfaceType.Smooth
    cw.BottomSurface = Enum.SurfaceType.Smooth
    cw.Parent = parent
    return cw
end

-- ----------------------------------------------------------------------------
-- MAIN BUILD ENGINE
-- ----------------------------------------------------------------------------

--- Builds a realistic, abandoned automotive mechanic's toolbox model.
--- Target part budget: exactly 30 parts (within 20–35 target range).
function RepairToolBuilder.Build(options: ToolboxBuildOptions?): Model
    local opts = options or {}
    local pos = opts.Position or Vector3.zero
    local rotY = opts.RotationY or 0
    local damage = math.clamp(if opts.DamageLevel ~= nil then opts.DamageLevel else 0.75, 0.0, 1.0)
    local salt = math.clamp(if opts.SaltLevel ~= nil then opts.SaltLevel else 0.80, 0.0, 1.0)
    local modelName = opts.Name or "MechanicToolbox_HeavyDuty"

    local rootCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

    local function localToWorld(offset: Vector3, rotationDegrees: Vector3?): CFrame
        local rot = if rotationDegrees then CFrame.Angles(math.rad(rotationDegrees.X), math.rad(rotationDegrees.Y), math.rad(rotationDegrees.Z)) else CFrame.identity
        return rootCF * CFrame.new(offset) * rot
    end

    local model = Instance.new("Model")
    model.Name = modelName

    -- Sub-folders for clean hierarchical inspection
    local folderChassis = Instance.new("Folder")
    folderChassis.Name = "ChassisAndLid"
    folderChassis.Parent = model

    local folderTools = Instance.new("Folder")
    folderTools.Name = "InteriorTools"
    folderTools.Parent = model

    local folderWeathering = Instance.new("Folder")
    folderWeathering.Name = "WeatheringAndSalt"
    folderWeathering.Parent = model

    -- ========================================================================
    -- 1. TOOLBOX CHASSIS & OUTER BODY (Parts 1 to 6)
    -- Overall dimensions: ~2.5 studs long (X) x ~0.8 studs high (Y) x ~1.3 studs wide (Z)
    -- ========================================================================

    -- Part 1: PrimaryPart Base Plate (Ground clearance Y = 0 to 0.16)
    local basePart = makePart(folderChassis, {
        Name = "Toolbox_Base",
        Size = Vector3.new(2.4, 0.16, 1.2),
        CFrame = localToWorld(Vector3.new(0, 0.08, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = true,
    })
    model.PrimaryPart = basePart

    -- Part 2: Front Wall
    makePart(folderChassis, {
        Name = "Toolbox_Wall_Front",
        Size = Vector3.new(2.4, 0.65, 0.1),
        CFrame = localToWorld(Vector3.new(0, 0.445, 0.55)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RED_OXIDE,
        CanCollide = true,
    })

    -- Part 3: Back Wall (Hinge side)
    makePart(folderChassis, {
        Name = "Toolbox_Wall_Back",
        Size = Vector3.new(2.4, 0.72, 0.1),
        CFrame = localToWorld(Vector3.new(0, 0.48, -0.55)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = true,
    })

    -- Part 4: Left Side Wall
    makePart(folderChassis, {
        Name = "Toolbox_Wall_Left",
        Size = Vector3.new(0.1, 0.65, 1.0),
        CFrame = localToWorld(Vector3.new(-1.15, 0.445, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RED_OXIDE,
        CanCollide = true,
    })

    -- Part 5: Right Side Wall
    makePart(folderChassis, {
        Name = "Toolbox_Wall_Right",
        Size = Vector3.new(0.1, 0.65, 1.0),
        CFrame = localToWorld(Vector3.new(1.15, 0.445, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RED_OXIDE,
        CanCollide = true,
    })

    -- Part 6: Internal Compartment Divider (Separates sockets & large wrenches)
    makePart(folderChassis, {
        Name = "Toolbox_Divider",
        Size = Vector3.new(0.08, 0.45, 1.0),
        CFrame = localToWorld(Vector3.new(-0.25, 0.365, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_METAL_RAW,
        CanCollide = false,
    })

    -- ========================================================================
    -- 2. HINGE, PARTIALLY OPEN LID & HARDWARE (Parts 7 to 13)
    -- Lid is tilted open ~38° to reveal the tool tray inside.
    -- ========================================================================

    -- Part 7: Piano Hinge Pin (Spans back edge)
    makeCylinder(folderChassis, {
        Name = "Toolbox_Hinge",
        Size = Vector3.new(0.09, 2.36, 0.09),
        CFrame = localToWorld(Vector3.new(0, 0.82, -0.56)),
        Orientation = "X",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_METAL_RAW,
        CanCollide = false,
    })

    -- Lid tilt angle: Opens backward between 30° and 45° depending on damage
    local lidAngleDeg = 32 + (damage * 14) -- ~32° to ~46°
    local lidCos = math.cos(math.rad(lidAngleDeg))
    local lidSin = math.sin(math.rad(lidAngleDeg))
    local lidCenterOffset = Vector3.new(0, 0.82 + (0.58 * lidSin), -0.56 + (0.58 * lidCos))

    -- Part 8: Main Stamped Steel Lid (Ajar)
    makePart(folderChassis, {
        Name = "Toolbox_Lid",
        Size = Vector3.new(2.44, 0.08, 1.22),
        CFrame = localToWorld(lidCenterOffset, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RED_OXIDE,
        CanCollide = true,
    })

    -- Part 9: Bent Front Lip of Lid (Overhang flap)
    local lipOffset = lidCenterOffset + (Vector3.new(0, 0.58 * lidSin, 0.58 * lidCos))
    makePart(folderChassis, {
        Name = "Toolbox_Lid_Lip",
        Size = Vector3.new(2.44, 0.14, 0.06),
        CFrame = localToWorld(lipOffset, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = false,
    })

    -- Part 10: Heavy Steel Lid Handle (Center crossbar)
    local handleOffset = lidCenterOffset + Vector3.new(0, 0.14 * lidCos, -0.14 * lidSin)
    makeCylinder(folderChassis, {
        Name = "Toolbox_Handle_Bar",
        Size = Vector3.new(0.1, 1.0, 0.1),
        CFrame = localToWorld(handleOffset, Vector3.new(-lidAngleDeg, 0, 0)),
        Orientation = "X",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_METAL_RAW,
        CanCollide = false,
    })

    -- Part 11: Left Handle Mounting Stanchion
    local stanchionL = handleOffset + Vector3.new(-0.48, -0.07 * lidCos, 0.07 * lidSin)
    makePart(folderChassis, {
        Name = "Toolbox_Handle_Bracket_L",
        Size = Vector3.new(0.08, 0.15, 0.08),
        CFrame = localToWorld(stanchionL, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = false,
    })

    -- Part 12: Right Handle Mounting Stanchion
    local stanchionR = handleOffset + Vector3.new(0.48, -0.07 * lidCos, 0.07 * lidSin)
    makePart(folderChassis, {
        Name = "Toolbox_Handle_Bracket_R",
        Size = Vector3.new(0.08, 0.15, 0.08),
        CFrame = localToWorld(stanchionR, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = false,
    })

    -- Part 13: Loose Front Toggle Latch Clasp (Hangs unlatched on front wall)
    makePart(folderChassis, {
        Name = "Toolbox_Latch",
        Size = Vector3.new(0.16, 0.32, 0.05),
        CFrame = localToWorld(Vector3.new(0, 0.62, 0.62), Vector3.new(12, 0, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOLBOX_LATCH_ZINC,
        CanCollide = false,
    })

    -- ========================================================================
    -- 3. VISIBLE HAND TOOLS INSIDE TRAY (Parts 14 to 25)
    -- Hand tools are resting realistically inside the open compartment.
    -- ========================================================================

    -- --- Tool A: Heavy Combination Wrench (Parts 14 to 16) ---
    -- Tilted across the right side of the tray
    local wrenchPos = Vector3.new(0.48, 0.28, -0.05)
    local wrenchRot = Vector3.new(6, 24, -4)

    -- Part 14: Wrench Shaft
    makePart(folderTools, {
        Name = "Tool_Wrench_Shaft",
        Size = Vector3.new(0.85, 0.06, 0.12),
        CFrame = localToWorld(wrenchPos, wrenchRot),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL,
        CanCollide = false,
    })

    -- Part 15: Wrench Open Jaw Head
    makeWedge(folderTools, {
        Name = "Tool_Wrench_Jaw",
        Size = Vector3.new(0.24, 0.07, 0.24),
        CFrame = localToWorld(wrenchPos + Vector3.new(0.48, 0.02, 0.14), wrenchRot),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL,
        CanCollide = false,
    })

    -- Part 16: Wrench Box Ring Head
    makeCylinder(folderTools, {
        Name = "Tool_Wrench_Ring",
        Size = Vector3.new(0.22, 0.07, 0.22),
        CFrame = localToWorld(wrenchPos + Vector3.new(-0.48, -0.02, -0.14), wrenchRot),
        Orientation = "Y",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL_DARK,
        CanCollide = false,
    })

    -- --- Tool B: Mechanic's Flathead Screwdriver (Parts 17 to 19) ---
    -- Resting longitudinally on the left divider compartment
    local sdPos = Vector3.new(-0.72, 0.26, 0.08)
    local sdRot = Vector3.new(4, -12, 0)

    -- Part 17: Fluted Amber/Red Acetate Handle
    makeCylinder(folderTools, {
        Name = "Tool_Screwdriver_Handle",
        Size = Vector3.new(0.18, 0.42, 0.18),
        CFrame = localToWorld(sdPos + Vector3.new(-0.28, 0, -0.06), sdRot),
        Orientation = "Z",
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_SCREWDRIVER_HANDLE,
        CanCollide = false,
    })

    -- Part 18: Steel Shank
    makeCylinder(folderTools, {
        Name = "Tool_Screwdriver_Shank",
        Size = Vector3.new(0.06, 0.58, 0.06),
        CFrame = localToWorld(sdPos + Vector3.new(0.18, 0, 0.04), sdRot),
        Orientation = "Z",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL,
        CanCollide = false,
    })

    -- Part 19: Keystone Flat Tip
    makeWedge(folderTools, {
        Name = "Tool_Screwdriver_Tip",
        Size = Vector3.new(0.03, 0.10, 0.09),
        CFrame = localToWorld(sdPos + Vector3.new(0.50, 0, 0.10), sdRot),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL_DARK,
        CanCollide = false,
    })

    -- --- Tool C: Automotive Slip-Joint Pliers (Parts 20 to 23) ---
    -- Laying flat in the center floor
    local pliersPos = Vector3.new(0.32, 0.22, 0.28)
    local pliersRot = Vector3.new(0, 16, 0)

    -- Part 20: Left Grip Arm
    makePart(folderTools, {
        Name = "Tool_Pliers_Grip_L",
        Size = Vector3.new(0.48, 0.07, 0.09),
        CFrame = localToWorld(pliersPos + Vector3.new(-0.22, 0, -0.08), Vector3.new(0, 24, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_PLIERS_GRIP,
        CanCollide = false,
    })

    -- Part 21: Right Grip Arm
    makePart(folderTools, {
        Name = "Tool_Pliers_Grip_R",
        Size = Vector3.new(0.48, 0.07, 0.09),
        CFrame = localToWorld(pliersPos + Vector3.new(-0.22, 0, 0.08), Vector3.new(0, 8, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_PLIERS_GRIP,
        CanCollide = false,
    })

    -- Part 22: Pivot Joint Pin
    makeCylinder(folderTools, {
        Name = "Tool_Pliers_Pivot",
        Size = Vector3.new(0.14, 0.09, 0.14),
        CFrame = localToWorld(pliersPos + Vector3.new(0.04, 0, 0), pliersRot),
        Orientation = "Y",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL,
        CanCollide = false,
    })

    -- Part 23: Serrated Gripping Beak / Jaws
    makeWedge(folderTools, {
        Name = "Tool_Pliers_Jaws",
        Size = Vector3.new(0.24, 0.08, 0.14),
        CFrame = localToWorld(pliersPos + Vector3.new(0.20, 0, 0), pliersRot),
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL_DARK,
        CanCollide = false,
    })

    -- --- Tool D: Hex Socket & Ratchet Extension (Parts 24 and 25) ---
    -- Resting across the back edge
    local ratchetPos = Vector3.new(-0.70, 0.23, -0.28)
    local ratchetRot = Vector3.new(0, 82, 0)

    -- Part 24: Knurled Steel Ratchet Handle
    makeCylinder(folderTools, {
        Name = "Tool_Socket_Handle",
        Size = Vector3.new(0.08, 0.55, 0.08),
        CFrame = localToWorld(ratchetPos, ratchetRot),
        Orientation = "X",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL,
        CanCollide = false,
    })

    -- Part 25: Drive Socket Head
    makeCylinder(folderTools, {
        Name = "Tool_Socket_Head",
        Size = Vector3.new(0.16, 0.18, 0.16),
        CFrame = localToWorld(ratchetPos + Vector3.new(0.04, 0, 0.28), ratchetRot),
        Orientation = "Y",
        Material = Enum.Material.Metal,
        Color = COLOR_TOOL_STEEL_DARK,
        CanCollide = false,
    })

    -- ========================================================================
    -- 4. WEATHERING, CORROSION & LAGUNA EPECUÉN SALT CRUST (Parts 26 to 30)
    -- Characteristic mineral crust from 25 years submerged in salt lagoon.
    -- ========================================================================

    -- Part 26: Calcite Salt Crust Base Rim (Crusted saline waterline deposit)
    local saltThickness = 0.08 + (salt * 0.06)
    makePart(folderWeathering, {
        Name = "Salt_Crust_Base",
        Size = Vector3.new(2.46, saltThickness, 1.26),
        CFrame = localToWorld(Vector3.new(0, saltThickness * 0.5, 0)),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST_CHALK,
        CanCollide = false,
    })

    -- Part 27: Heavy Calcite Accretion Wedge on Back Corner
    makeCornerWedge(folderWeathering, {
        Name = "Salt_Deposit_Corner",
        Size = Vector3.new(0.42, 0.38 * salt, 0.42),
        CFrame = localToWorld(Vector3.new(-1.02, 0.20, -0.42), Vector3.new(0, 90, 0)),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST_CHALK,
        CanCollide = false,
    })

    -- Part 28: Flaking Rust Corrosion Patch on Front Wall
    makePart(folderWeathering, {
        Name = "Rust_Patch_Front",
        Size = Vector3.new(0.55, 0.32, 0.04),
        CFrame = localToWorld(Vector3.new(0.42, 0.42, 0.59)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = false,
    })

    -- Part 29: Corroded Pitting Patch on Upper Lid Surface
    local lidRustOffset = lidCenterOffset + Vector3.new(0.38, 0.05 * lidCos, -0.05 * lidSin)
    makePart(folderWeathering, {
        Name = "Rust_Patch_Lid",
        Size = Vector3.new(0.65, 0.04, 0.45),
        CFrame = localToWorld(lidRustOffset, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_TOOLBOX_RUST_DARK,
        CanCollide = false,
    })

    -- Part 30: Whitish Calcite Salt Streak Across Ajar Lid
    local lidSaltOffset = lidCenterOffset + Vector3.new(-0.45, 0.05 * lidCos, -0.05 * lidSin)
    makePart(folderWeathering, {
        Name = "Salt_Stain_Lid",
        Size = Vector3.new(0.52, 0.03, 0.58),
        CFrame = localToWorld(lidSaltOffset, Vector3.new(-lidAngleDeg, 0, 0)),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST_STAIN,
        CanCollide = false,
    })

    -- ========================================================================
    -- FINALIZE MODEL
    -- ========================================================================

    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

--- Returns the standard part count generated by RepairToolBuilder.Build() (exactly 30).
function RepairToolBuilder.GetPartCount(): number
    return 30
end

return RepairToolBuilder
