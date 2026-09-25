--!strict
--[[
    VehicleModelBuilder.luau
    Location: ServerScriptService/VehicleModelBuilder.luau
    
    Procedural 3D Model Builder for the "Fiat Cronos" (Argentine B-segment 4-door sedan).
    Visual Reference: Fiat Cronos (Manufactured in Ferreyra, Córdoba, Argentina).
    
    Aesthetic & Environmental Condition:
      - Contemporary white four-door sedan (Fiat "Blanco Banchisa / Alaska").
      - Stranded in Villa Epecuén: weathered white paint with caustic salt residue,
        pampas road dust, slightly ajar hood, and weathered trim.
      - Missing five critical mechanical repair components:
          1. Battery (empty tray with loose terminal leads)
          2. Alternator (empty bracket and slack accessory belt)
          3. Spark Plugs (exposed cylinder head with disconnected plug boots)
          4. Radiator Hose (disconnected radiator inlet with missing hose gap)
          5. Fuel Canister (open fuel flap and empty auxiliary canister cradle)
      - Proportioned strictly to realistic sedan dimensions (~16 studs long, 6.8 studs wide, 5.2 studs high).
      - Built entirely from native Roblox Parts and WedgeParts (0 meshes, 0 external assets, 0 plugins).
      - Reusable builder: does NOT automatically instantiate into Workspace on require.
--]]

local VehicleModelBuilder = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

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
}

export type CylinderConfig = {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Transparency: number?,
    CanCollide: boolean?,
}

export type MissingComponentsState = {
    Battery: boolean,
    Alternator: boolean,
    SparkPlugs: boolean,
    RadiatorHose: boolean,
    FuelCanister: boolean,
}

export type BuildOptions = {
    Position: Vector3?,
    OrientationY: number?, -- in degrees
    Parent: Instance?,
    IsDamaged: boolean?,
    MissingComponents: MissingComponentsState?,
}

-- ============================================================================
-- CONSTANTS & PALETTE (FIAT CRONOS & EPECUÉN SALT ENVIRONMENT)
-- ============================================================================

local DEFAULT_SPAWN_POSITION = Vector3.new(-160, 19, -755)

-- Body Colors
local COLOR_BODY_WHITE         = Color3.fromRGB(224, 226, 222) -- Fiat Banchisa White base
local COLOR_BODY_WEATHERED     = Color3.fromRGB(214, 216, 208) -- Salt-weathered white panels
local COLOR_SALT_CRUST         = Color3.fromRGB(238, 238, 232) -- Dried saline crusting
local COLOR_DUST_PAMPAS        = Color3.fromRGB(182, 175, 158) -- Lower sill pampas dirt
local COLOR_TRIM_BLACK         = Color3.fromRGB(32, 34, 36)    -- Satin black window trim & pillars
local COLOR_GRILLE_DARK        = Color3.fromRGB(24, 25, 27)    -- Grille honeycomb & lower intake
local COLOR_CHROME             = Color3.fromRGB(200, 204, 208) -- Fiat emblem bar & accents
local COLOR_GLASS_WINDSHIELD   = Color3.fromRGB(175, 188, 195) -- Translucent tinted automotive glass
local COLOR_GLASS_DUSTY        = Color3.fromRGB(195, 198, 192) -- Salt-dusted glass
local COLOR_HEADLIGHT_LENS     = Color3.fromRGB(225, 235, 245) -- Clear polycarbonate headlight
local COLOR_HEADLIGHT_INNER    = Color3.fromRGB(45, 48, 52)    -- Dark chrome reflector housing
local COLOR_TAILLIGHT_RED      = Color3.fromRGB(185, 28, 28)   -- LED red lens
local COLOR_TAILLIGHT_AMBER    = Color3.fromRGB(220, 140, 25)  -- Turn indicator lens
local COLOR_TAILLIGHT_CLEAR    = Color3.fromRGB(220, 225, 228) -- Reverse light segment
local COLOR_TIRE_RUBBER        = Color3.fromRGB(36, 36, 38)    -- Weathered vulcanized rubber
local COLOR_ALLOY_WHEEL        = Color3.fromRGB(175, 178, 182) -- 16" silver alloy rim
local COLOR_BRAKE_DISC         = Color3.fromRGB(110, 114, 118) -- Steel brake disc rotor
local COLOR_INTERIOR_DARK      = Color3.fromRGB(42, 44, 48)    -- Dark charcoal dash & cabin
local COLOR_SEAT_FABRIC        = Color3.fromRGB(55, 58, 64)    -- Fabric upholstery
local COLOR_ENGINE_BLOCK       = Color3.fromRGB(78, 82, 86)    -- Cast aluminum/iron FireFly engine
local COLOR_ENGINE_HEAD        = Color3.fromRGB(48, 50, 54)    -- Cylinder valve cover
local COLOR_RUST_OXIDE         = Color3.fromRGB(138, 72, 48)   -- Light surface rust on damaged brackets
local COLOR_EXHAUST_PIPE       = Color3.fromRGB(120, 122, 125) -- Underbody exhaust steel

-- ============================================================================
-- HELPER UTILITIES
-- ============================================================================

local function makePart(parent: Instance, cfg: PartConfig): Part
    local part = Instance.new("Part")
    part.Name = cfg.Name
    part.Size = cfg.Size
    part.CFrame = cfg.CFrame
    part.Material = cfg.Material or Enum.Material.SmoothPlastic
    part.Color = cfg.Color or COLOR_BODY_WHITE
    part.Transparency = cfg.Transparency or 0
    part.Reflectance = cfg.Reflectance or 0.05
    part.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    part.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function makeWedge(parent: Instance, cfg: WedgeConfig): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Name = cfg.Name
    wedge.Size = cfg.Size
    wedge.CFrame = cfg.CFrame
    wedge.Material = cfg.Material or Enum.Material.SmoothPlastic
    wedge.Color = cfg.Color or COLOR_BODY_WHITE
    wedge.Transparency = cfg.Transparency or 0
    wedge.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    wedge.Anchored = true
    wedge.TopSurface = Enum.SurfaceType.Smooth
    wedge.BottomSurface = Enum.SurfaceType.Smooth
    wedge.Parent = parent
    return wedge
end

local function makeCylinder(parent: Instance, cfg: CylinderConfig): Part
    local cyl = Instance.new("Part")
    cyl.Name = cfg.Name
    cyl.Shape = Enum.PartType.Cylinder
    cyl.Size = cfg.Size
    cyl.CFrame = cfg.CFrame
    cyl.Material = cfg.Material or Enum.Material.Rubber
    cyl.Color = cfg.Color or COLOR_TIRE_RUBBER
    cyl.Transparency = cfg.Transparency or 0
    cyl.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    cyl.Anchored = true
    cyl.TopSurface = Enum.SurfaceType.Smooth
    cyl.BottomSurface = Enum.SurfaceType.Smooth
    cyl.Parent = parent
    return cyl
end

-- ============================================================================
-- CORE VEHICLE BUILD ROUTINE
-- ============================================================================

--[[
    Transforms local car coordinates (where car center is at 0, 0, 0, facing -Z)
    into World CFrame coordinates relative to the vehicle's origin.
--]]
local function localToWorld(rootCF: CFrame, relPos: Vector3, relAngles: Vector3?): CFrame
    local cf = rootCF * CFrame.new(relPos)
    if relAngles then
        cf = cf * CFrame.Angles(math.rad(relAngles.X), math.rad(relAngles.Y), math.rad(relAngles.Z))
    end
    return cf
end

--[[
    Builds a complete, geometrically authentic Fiat Cronos sedan.
--]]
function VehicleModelBuilder.Build(options: BuildOptions?): Model
    local opts: BuildOptions = options or {}
    local spawnPos = opts.Position or DEFAULT_SPAWN_POSITION
    local rotY = opts.OrientationY or 25 -- default subtle diagonal parking angle
    local isDamaged = if opts.IsDamaged ~= nil then opts.IsDamaged else true
    local missing = opts.MissingComponents or {
        Battery = true,
        Alternator = true,
        SparkPlugs = true,
        RadiatorHose = true,
        FuelCanister = true,
    }

    local rootCF = CFrame.new(spawnPos) * CFrame.Angles(0, math.rad(rotY), 0)

    local model = Instance.new("Model")
    model.Name = "FiatCronos"

    -- Folders for clear organization
    local folderChassis = Instance.new("Folder")
    folderChassis.Name = "ChassisAndBody"
    folderChassis.Parent = model

    local folderGlazing = Instance.new("Folder")
    folderGlazing.Name = "WindowsAndGlass"
    folderGlazing.Parent = model

    local folderInterior = Instance.new("Folder")
    folderInterior.Name = "Interior"
    folderInterior.Parent = model

    local folderWheels = Instance.new("Folder")
    folderWheels.Name = "Wheels"
    folderWheels.Parent = model

    local folderEngine = Instance.new("Folder")
    folderEngine.Name = "EngineBay"
    folderEngine.Parent = model

    local folderDetails = Instance.new("Folder")
    folderDetails.Name = "ExteriorDetails"
    folderDetails.Parent = model

    -- ------------------------------------------------------------------------
    -- 1. PRIMARY ROOT & UNDERBODY CHASSIS
    -- ------------------------------------------------------------------------
    local rootPart = makePart(folderChassis, {
        Name = "Chassis_Root",
        Size = Vector3.new(6.2, 0.5, 14.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.2, 0)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(30, 32, 34),
        CanCollide = true,
        CastShadow = true,
    })
    model.PrimaryPart = rootPart

    -- Floor pan & subframe
    makePart(folderChassis, {
        Name = "FloorPan",
        Size = Vector3.new(5.8, 0.4, 9.6),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.45, 0.2)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(40, 42, 45),
        CanCollide = true,
    })

    -- Exhaust pipe running underneath
    makePart(folderChassis, {
        Name = "ExhaustPipe",
        Size = Vector3.new(0.3, 0.3, 11.2),
        CFrame = localToWorld(rootCF, Vector3.new(-1.2, 0.95, 1.0)),
        Material = Enum.Material.Metal,
        Color = COLOR_EXHAUST_PIPE,
        CanCollide = false,
    })

    -- Rear muffler
    makePart(folderChassis, {
        Name = "RearMuffler",
        Size = Vector3.new(1.8, 0.7, 1.2),
        CFrame = localToWorld(rootCF, Vector3.new(-1.1, 1.05, 6.4)),
        Material = Enum.Material.CorrodedMetal,
        Color = Color3.fromRGB(95, 96, 98),
        CanCollide = false,
    })

    -- Chrome exhaust tip angled downward
    makePart(folderChassis, {
        Name = "ExhaustTip",
        Size = Vector3.new(0.35, 0.35, 0.6),
        CFrame = localToWorld(rootCF, Vector3.new(-1.2, 0.9, 7.3)),
        Material = Enum.Material.Metal,
        Color = COLOR_CHROME,
        CanCollide = false,
    })

    -- ------------------------------------------------------------------------
    -- 2. EXTERIOR BODY PANELS (FIAT CRONOS NOTCHBACK PROFILE)
    -- ------------------------------------------------------------------------
    local paintColor = if isDamaged then COLOR_BODY_WEATHERED else COLOR_BODY_WHITE
    local lowerSillColor = if isDamaged then COLOR_DUST_PAMPAS else COLOR_TRIM_BLACK

    -- Lower Rocker Panels / Side Sills (Left & Right)
    makePart(folderChassis, {
        Name = "RockerPanel_L",
        Size = Vector3.new(0.5, 0.6, 9.4),
        CFrame = localToWorld(rootCF, Vector3.new(-3.1, 1.35, 0.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = lowerSillColor,
    })
    makePart(folderChassis, {
        Name = "RockerPanel_R",
        Size = Vector3.new(0.5, 0.6, 9.4),
        CFrame = localToWorld(rootCF, Vector3.new(3.1, 1.35, 0.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = lowerSillColor,
    })

    -- Salt residue layer along the lower sill edges
    if isDamaged then
        makePart(folderDetails, {
            Name = "SaltCrust_Sill_L",
            Size = Vector3.new(0.52, 0.25, 9.4),
            CFrame = localToWorld(rootCF, Vector3.new(-3.11, 1.25, 0.1)),
            Material = Enum.Material.Sandstone,
            Color = COLOR_SALT_CRUST,
            CanCollide = false,
        })
        makePart(folderDetails, {
            Name = "SaltCrust_Sill_R",
            Size = Vector3.new(0.52, 0.25, 9.4),
            CFrame = localToWorld(rootCF, Vector3.new(3.11, 1.25, 0.1)),
            Material = Enum.Material.Sandstone,
            Color = COLOR_SALT_CRUST,
            CanCollide = false,
        })
    end

    -- Front Quarter Panels / Fenders (Left & Right)
    makePart(folderChassis, {
        Name = "FrontFender_L",
        Size = Vector3.new(0.5, 1.4, 3.4),
        CFrame = localToWorld(rootCF, Vector3.new(-3.05, 2.3, -4.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    makePart(folderChassis, {
        Name = "FrontFender_R",
        Size = Vector3.new(0.5, 1.4, 3.4),
        CFrame = localToWorld(rootCF, Vector3.new(3.05, 2.3, -4.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Rear Quarter Panels (Left & Right - curving toward trunk)
    makePart(folderChassis, {
        Name = "RearQuarterPanel_L",
        Size = Vector3.new(0.5, 1.6, 3.8),
        CFrame = localToWorld(rootCF, Vector3.new(-3.05, 2.4, 5.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    makePart(folderChassis, {
        Name = "RearQuarterPanel_R",
        Size = Vector3.new(0.5, 1.6, 3.8),
        CFrame = localToWorld(rootCF, Vector3.new(3.05, 2.4, 5.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- ------------------------------------------------------------------------
    -- 3. FOUR DOORS WITH SEAMS, CREASES & HANDLES
    -- ------------------------------------------------------------------------
    -- Driver Front Door (Left)
    makePart(folderChassis, {
        Name = "Door_FrontLeft",
        Size = Vector3.new(0.45, 1.5, 2.7),
        CFrame = localToWorld(rootCF, Vector3.new(-3.05, 2.35, -1.85)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    -- Passenger Front Door (Right)
    makePart(folderChassis, {
        Name = "Door_FrontRight",
        Size = Vector3.new(0.45, 1.5, 2.7),
        CFrame = localToWorld(rootCF, Vector3.new(3.05, 2.35, -1.85)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    -- Rear Left Door
    makePart(folderChassis, {
        Name = "Door_RearLeft",
        Size = Vector3.new(0.45, 1.5, 2.6),
        CFrame = localToWorld(rootCF, Vector3.new(-3.05, 2.35, 1.25)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    -- Rear Right Door
    makePart(folderChassis, {
        Name = "Door_RearRight",
        Size = Vector3.new(0.45, 1.5, 2.6),
        CFrame = localToWorld(rootCF, Vector3.new(3.05, 2.35, 1.25)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Window Sill Weatherstrips (Thin satin-black beltline trim closing the 0.175-stud gap to side glazing)
    local beltlineSpecs = {
        { Name = "Door_Weatherstrip_FL", Pos = Vector3.new(-2.95, 3.19, -1.85), Size = Vector3.new(0.46, 0.18, 2.7) },
        { Name = "Door_Weatherstrip_FR", Pos = Vector3.new(2.95, 3.19, -1.85), Size = Vector3.new(0.46, 0.18, 2.7) },
        { Name = "Door_Weatherstrip_RL", Pos = Vector3.new(-2.95, 3.19, 1.25), Size = Vector3.new(0.46, 0.18, 2.6) },
        { Name = "Door_Weatherstrip_RR", Pos = Vector3.new(2.95, 3.19, 1.25), Size = Vector3.new(0.46, 0.18, 2.6) },
    }
    for _, strip in ipairs(beltlineSpecs) do
        makePart(folderChassis, {
            Name = strip.Name,
            Size = strip.Size,
            CFrame = localToWorld(rootCF, strip.Pos),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_TRIM_BLACK,
        })
    end

    -- Door handles (Horizontal pull-handles, Cronos style)
    local handlePositions = {
        { Name = "Handle_FL", Pos = Vector3.new(-3.3, 2.75, -0.9) },
        { Name = "Handle_FR", Pos = Vector3.new(3.3, 2.75, -0.9) },
        { Name = "Handle_RL", Pos = Vector3.new(-3.3, 2.75, 2.1) },
        { Name = "Handle_RR", Pos = Vector3.new(3.3, 2.75, 2.1) },
    }
    for _, h in ipairs(handlePositions) do
        makePart(folderDetails, {
            Name = h.Name,
            Size = Vector3.new(0.12, 0.22, 0.8),
            CFrame = localToWorld(rootCF, h.Pos),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_TRIM_BLACK,
            CanCollide = false,
        })
    end

    -- ------------------------------------------------------------------------
    -- 4. HOOD (BONNET) - AERODYNAMIC SLOPED WITH AJAR ANGLE
    -- ------------------------------------------------------------------------
    -- When damaged/abandoned, the hood is popped/ajar by a few degrees on its latch,
    -- allowing players to peek directly at the missing mechanical components.
    local hoodTilt = if isDamaged then -4.5 else 0
    local hoodOffset = if isDamaged then Vector3.new(0, 0.22, -0.05) else Vector3.zero

    -- Main hood surface
    makePart(folderChassis, {
        Name = "Hood_Main",
        Size = Vector3.new(5.6, 0.25, 3.4),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.95, -4.9) + hoodOffset, Vector3.new(-4 + hoodTilt, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Front hood leading slope wedge
    makeWedge(folderChassis, {
        Name = "Hood_FrontWedge",
        Size = Vector3.new(5.6, 0.45, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.75, -6.65) + hoodOffset, Vector3.new(0, 180, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Scuffed edge on the hood corner
    if isDamaged then
        makePart(folderDetails, {
            Name = "Hood_Scuff_Damage",
            Size = Vector3.new(0.8, 0.08, 0.6),
            CFrame = localToWorld(rootCF, Vector3.new(2.4, 3.02, -5.9) + hoodOffset),
            Material = Enum.Material.CorrodedMetal,
            Color = Color3.fromRGB(110, 105, 100),
            CanCollide = false,
        })
    end

    -- ------------------------------------------------------------------------
    -- 5. FRONT BUMPER, GRILLE & HEADLIGHTS (MODERN FIAT CRONOS FACE)
    -- ------------------------------------------------------------------------
    -- Front Bumper Core
    makePart(folderChassis, {
        Name = "FrontBumper_Core",
        Size = Vector3.new(6.4, 1.2, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.9, -7.0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Lower Bumper Air Dam / Splitter (Dark Matte)
    makePart(folderChassis, {
        Name = "FrontBumper_LowerLip",
        Size = Vector3.new(6.1, 0.4, 0.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.2, -7.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_GRILLE_DARK,
    })

    -- Characteristic Fiat Hexagonal Mesh Grille
    makePart(folderDetails, {
        Name = "FrontGrille_Main",
        Size = Vector3.new(4.6, 0.75, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.25, -7.42)),
        Material = Enum.Material.DiamondPlate,
        Color = COLOR_GRILLE_DARK,
        CanCollide = false,
    })

    -- Lower Air Intake
    makePart(folderDetails, {
        Name = "FrontGrille_LowerIntake",
        Size = Vector3.new(3.8, 0.45, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.5, -7.42)),
        Material = Enum.Material.DiamondPlate,
        Color = COLOR_GRILLE_DARK,
        CanCollide = false,
    })

    -- Fiat Chrome Center Accent Line & Badge Placeholder
    makePart(folderDetails, {
        Name = "FrontBadge_ChromeLine",
        Size = Vector3.new(3.0, 0.1, 0.22),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.45, -7.45)),
        Material = Enum.Material.Metal,
        Color = COLOR_CHROME,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "FiatBadge_Central",
        Size = Vector3.new(0.7, 0.35, 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.45, -7.47)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(165, 30, 35), -- Fiat red badge motif
        CanCollide = false,
    })

    -- Argentine Front License Plate ("AD 123 EP" format)
    makePart(folderDetails, {
        Name = "LicensePlate_Front",
        Size = Vector3.new(1.4, 0.45, 0.08),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.85, -7.48)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(240, 242, 245),
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "LicensePlate_Front_Stripe",
        Size = Vector3.new(1.4, 0.12, 0.09),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.02, -7.485)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(40, 90, 175), -- Argentine Mercosur blue top stripe
        CanCollide = false,
    })

    -- Headlights (Modern angular wrap-around styling)
    -- Left Headlight Assembly
    makePart(folderDetails, {
        Name = "Headlight_Housing_L",
        Size = Vector3.new(1.2, 0.6, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(-2.4, 2.4, -6.95), Vector3.new(-8, -15, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_HEADLIGHT_INNER,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Headlight_Lens_L",
        Size = Vector3.new(1.18, 0.55, 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(-2.42, 2.4, -7.38), Vector3.new(-8, -15, 0)),
        Material = Enum.Material.Glass,
        Color = COLOR_HEADLIGHT_LENS,
        Transparency = 0.35,
        Reflectance = 0.3,
        CanCollide = false,
    })

    -- Right Headlight Assembly (Slightly cracked / clouded in abandoned state)
    makePart(folderDetails, {
        Name = "Headlight_Housing_R",
        Size = Vector3.new(1.2, 0.6, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(2.4, 2.4, -6.95), Vector3.new(-8, 15, 0)),
        Material = Enum.Material.Metal,
        Color = COLOR_HEADLIGHT_INNER,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Headlight_Lens_R",
        Size = Vector3.new(1.18, 0.55, 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(2.42, 2.4, -7.38), Vector3.new(-8, 15, 0)),
        Material = Enum.Material.Glass,
        Color = if isDamaged then Color3.fromRGB(200, 205, 200) else COLOR_HEADLIGHT_LENS,
        Transparency = if isDamaged then 0.55 else 0.35,
        Reflectance = 0.2,
        CanCollide = false,
    })

    -- Fog light recesses
    makePart(folderDetails, {
        Name = "FogLight_Recess_L",
        Size = Vector3.new(0.6, 0.5, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(-2.4, 1.45, -7.35)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_GRILLE_DARK,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "FogLight_Recess_R",
        Size = Vector3.new(0.6, 0.5, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(2.4, 1.45, -7.35)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_GRILLE_DARK,
        CanCollide = false,
    })

    -- ------------------------------------------------------------------------
    -- 6. GREENHOUSE, ROOF & PILLARS (A, B, C PILLARS)
    -- ------------------------------------------------------------------------
    -- Roof Main Panel (Subtly curved sedan canopy)
    makePart(folderChassis, {
        Name = "Roof_Main",
        Size = Vector3.new(5.0, 0.22, 5.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, 4.85, 0.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Roof longitudinal aesthetic aerodynamic ribs (Cronos signature)
    makePart(folderDetails, {
        Name = "Roof_Rib_L",
        Size = Vector3.new(0.18, 0.08, 5.4),
        CFrame = localToWorld(rootCF, Vector3.new(-1.6, 4.96, 0.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Roof_Rib_R",
        Size = Vector3.new(0.18, 0.08, 5.4),
        CFrame = localToWorld(rootCF, Vector3.new(1.6, 4.96, 0.1)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
        CanCollide = false,
    })

    -- Roof Rear Shark Fin Antenna
    makePart(folderDetails, {
        Name = "Roof_SharkFin_Antenna",
        Size = Vector3.new(0.25, 0.45, 0.7),
        CFrame = localToWorld(rootCF, Vector3.new(0, 5.15, 2.5), Vector3.new(-15, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
        CanCollide = false,
    })

    -- A-Pillars (Front windshield frame, angled)
    makePart(folderChassis, {
        Name = "Pillar_A_Left",
        Size = Vector3.new(0.35, 0.35, 2.6),
        CFrame = localToWorld(rootCF, Vector3.new(-2.6, 3.95, -3.4), Vector3.new(38, -12, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    makePart(folderChassis, {
        Name = "Pillar_A_Right",
        Size = Vector3.new(0.35, 0.35, 2.6),
        CFrame = localToWorld(rootCF, Vector3.new(2.6, 3.95, -3.4), Vector3.new(38, 12, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- B-Pillars (Center door pillars in satin black trim)
    makePart(folderChassis, {
        Name = "Pillar_B_Left",
        Size = Vector3.new(0.4, 1.85, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(-2.85, 3.95, -0.45)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })
    makePart(folderChassis, {
        Name = "Pillar_B_Right",
        Size = Vector3.new(0.4, 1.85, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(2.85, 3.95, -0.45)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })

    -- C-Pillars (Rear pillars flowing into the high trunk deck)
    makePart(folderChassis, {
        Name = "Pillar_C_Left",
        Size = Vector3.new(0.5, 0.45, 3.1),
        CFrame = localToWorld(rootCF, Vector3.new(-2.65, 4.05, 3.9), Vector3.new(-34, 10, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })
    makePart(folderChassis, {
        Name = "Pillar_C_Right",
        Size = Vector3.new(0.5, 0.45, 3.1),
        CFrame = localToWorld(rootCF, Vector3.new(2.65, 4.05, 3.9), Vector3.new(-34, -10, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- ------------------------------------------------------------------------
    -- 7. WINDOWS & WINDSHIELD (TRANSLUCENT AUTOMOTIVE GLASS)
    -- ------------------------------------------------------------------------
    local glassColor = if isDamaged then COLOR_GLASS_DUSTY else COLOR_GLASS_WINDSHIELD
    local glassTransp = if isDamaged then 0.45 else 0.35

    -- Front Windshield (Sloped)
    makePart(folderGlazing, {
        Name = "Windshield_Front",
        Size = Vector3.new(4.9, 0.15, 2.5),
        CFrame = localToWorld(rootCF, Vector3.new(0, 3.9, -3.35), Vector3.new(38, 0, 0)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.25,
        CanCollide = true,
    })

    -- Windshield wiper wipers (black arms parked at bottom edge)
    makePart(folderDetails, {
        Name = "Wiper_Driver",
        Size = Vector3.new(1.6, 0.08, 0.08),
        CFrame = localToWorld(rootCF, Vector3.new(-1.1, 3.08, -4.35), Vector3.new(0, 0, 8)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Wiper_Passenger",
        Size = Vector3.new(1.6, 0.08, 0.08),
        CFrame = localToWorld(rootCF, Vector3.new(0.9, 3.08, -4.35), Vector3.new(0, 0, 8)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
        CanCollide = false,
    })

    -- Rear Sloped Windshield
    makePart(folderGlazing, {
        Name = "Windshield_Rear",
        Size = Vector3.new(4.8, 0.15, 2.7),
        CFrame = localToWorld(rootCF, Vector3.new(0, 4.05, 3.85), Vector3.new(-34, 0, 0)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.25,
        CanCollide = true,
    })

    -- Side Windows - Driver Side (Front & Rear)
    makePart(folderGlazing, {
        Name = "SideWindow_FL",
        Size = Vector3.new(0.12, 1.45, 2.2),
        CFrame = localToWorld(rootCF, Vector3.new(-2.75, 4.0, -1.8)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.2,
    })
    makePart(folderGlazing, {
        Name = "SideWindow_RL",
        Size = Vector3.new(0.12, 1.45, 2.1),
        CFrame = localToWorld(rootCF, Vector3.new(-2.75, 4.0, 0.95)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.2,
    })

    -- Side Windows - Passenger Side (Front & Rear)
    makePart(folderGlazing, {
        Name = "SideWindow_FR",
        Size = Vector3.new(0.12, 1.45, 2.2),
        CFrame = localToWorld(rootCF, Vector3.new(2.75, 4.0, -1.8)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.2,
    })
    makePart(folderGlazing, {
        Name = "SideWindow_RR",
        Size = Vector3.new(0.12, 1.45, 2.1),
        CFrame = localToWorld(rootCF, Vector3.new(2.75, 4.0, 0.95)),
        Material = Enum.Material.Glass,
        Color = glassColor,
        Transparency = glassTransp,
        Reflectance = 0.2,
    })

    -- ------------------------------------------------------------------------
    -- 8. SIDE MIRRORS
    -- ------------------------------------------------------------------------
    -- Driver Side Mirror
    makePart(folderDetails, {
        Name = "MirrorMount_L",
        Size = Vector3.new(0.3, 0.15, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(-3.15, 3.45, -2.85)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "MirrorHousing_L",
        Size = Vector3.new(0.35, 0.45, 0.75),
        CFrame = localToWorld(rootCF, Vector3.new(-3.45, 3.5, -2.85), Vector3.new(0, -10, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "MirrorGlass_L",
        Size = Vector3.new(0.08, 0.38, 0.65),
        CFrame = localToWorld(rootCF, Vector3.new(-3.4, 3.5, -2.85), Vector3.new(0, -10, 0)),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(230, 235, 240),
        Reflectance = 0.7,
        CanCollide = false,
    })

    -- Passenger Side Mirror
    makePart(folderDetails, {
        Name = "MirrorMount_R",
        Size = Vector3.new(0.3, 0.15, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(3.15, 3.45, -2.85)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "MirrorHousing_R",
        Size = Vector3.new(0.35, 0.45, 0.75),
        CFrame = localToWorld(rootCF, Vector3.new(3.45, 3.5, -2.85), Vector3.new(0, 10, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "MirrorGlass_R",
        Size = Vector3.new(0.08, 0.38, 0.65),
        CFrame = localToWorld(rootCF, Vector3.new(3.4, 3.5, -2.85), Vector3.new(0, 10, 0)),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(230, 235, 240),
        Reflectance = 0.7,
        CanCollide = false,
    })

    -- ------------------------------------------------------------------------
    -- 9. REAR TRUNK (BOOT) & REAR BUMPER
    -- ------------------------------------------------------------------------
    -- Trunk Deck Lid (High notchback sedan deck with subtle integrated lip)
    makePart(folderChassis, {
        Name = "Trunk_DeckLid",
        Size = Vector3.new(5.6, 0.25, 2.0),
        CFrame = localToWorld(rootCF, Vector3.new(0, 3.25, 5.8), Vector3.new(4, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Trunk Rear Vertical Face
    makePart(folderChassis, {
        Name = "Trunk_RearFace",
        Size = Vector3.new(5.6, 1.1, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.65, 6.9)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Rear Bumper Main
    makePart(folderChassis, {
        Name = "RearBumper_Main",
        Size = Vector3.new(6.4, 1.2, 0.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.9, 7.15)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
    })

    -- Rear Lower Diffuser (Dark Trim)
    makePart(folderChassis, {
        Name = "RearBumper_Diffuser",
        Size = Vector3.new(5.8, 0.5, 0.7),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.25, 7.2)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_GRILLE_DARK,
    })

    -- Rear License Plate ("AD 123 EP" format)
    makePart(folderDetails, {
        Name = "LicensePlate_Rear",
        Size = Vector3.new(1.4, 0.45, 0.08),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.4, 7.32)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(240, 242, 245),
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "LicensePlate_Rear_Stripe",
        Size = Vector3.new(1.4, 0.12, 0.09),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.57, 7.325)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(40, 90, 175),
        CanCollide = false,
    })

    -- Fiat Rear Central Emblem & Cronos Model Script Plate
    makePart(folderDetails, {
        Name = "FiatEmblem_Rear",
        Size = Vector3.new(0.65, 0.3, 0.1),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.95, 7.15)),
        Material = Enum.Material.Metal,
        Color = COLOR_CHROME,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Cronos_Badge_Script",
        Size = Vector3.new(0.8, 0.15, 0.08),
        CFrame = localToWorld(rootCF, Vector3.new(-1.8, 2.9, 7.15)),
        Material = Enum.Material.Metal,
        Color = COLOR_CHROME,
        CanCollide = false,
    })

    -- Taillights (Characteristic Cronos horizontal split units)
    -- Left Taillight (Outer red, inner clear reverse, and amber indicator)
    makePart(folderDetails, {
        Name = "Taillight_Outer_L",
        Size = Vector3.new(1.1, 0.55, 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(-2.35, 2.85, 7.15)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_RED,
        Transparency = 0.25,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Taillight_Inner_L",
        Size = Vector3.new(0.6, 0.2, 0.26),
        CFrame = localToWorld(rootCF, Vector3.new(-2.35, 2.75, 7.16)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_CLEAR,
        Transparency = 0.3,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Taillight_Indicator_L",
        Size = Vector3.new(0.5, 0.18, 0.26),
        CFrame = localToWorld(rootCF, Vector3.new(-2.6, 2.75, 7.16)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_AMBER,
        Transparency = 0.3,
        CanCollide = false,
    })

    -- Right Taillight (Outer red, inner clear reverse, and amber indicator)
    makePart(folderDetails, {
        Name = "Taillight_Outer_R",
        Size = Vector3.new(1.1, 0.55, 0.25),
        CFrame = localToWorld(rootCF, Vector3.new(2.35, 2.85, 7.15)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_RED,
        Transparency = 0.25,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Taillight_Inner_R",
        Size = Vector3.new(0.6, 0.2, 0.26),
        CFrame = localToWorld(rootCF, Vector3.new(2.35, 2.75, 7.16)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_CLEAR,
        Transparency = 0.3,
        CanCollide = false,
    })
    makePart(folderDetails, {
        Name = "Taillight_Indicator_R",
        Size = Vector3.new(0.5, 0.18, 0.26),
        CFrame = localToWorld(rootCF, Vector3.new(2.6, 2.75, 7.16)),
        Material = Enum.Material.Glass,
        Color = COLOR_TAILLIGHT_AMBER,
        Transparency = 0.3,
        CanCollide = false,
    })

    -- ------------------------------------------------------------------------
    -- 10. DETAILED INTERIOR (VISIBLE THROUGH GLASS)
    -- ------------------------------------------------------------------------
    -- Dashboard Base (Across full cabin width)
    makePart(folderInterior, {
        Name = "Dash_Base",
        Size = Vector3.new(5.2, 0.9, 1.6),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.9, -2.4)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_INTERIOR_DARK,
    })

    -- Instrument Cluster Binnacle (Driver side - Left Hand Drive for Argentina)
    makePart(folderInterior, {
        Name = "Instrument_Binnacle",
        Size = Vector3.new(1.4, 0.45, 0.8),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 3.45, -2.4)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(30, 32, 36),
    })

    -- Steering Column & 3-Spoke Steering Wheel
    makePart(folderInterior, {
        Name = "SteeringColumn",
        Size = Vector3.new(0.35, 0.35, 1.1),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 3.2, -1.8), Vector3.new(28, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })
    makePart(folderInterior, {
        Name = "SteeringWheel_Rim",
        Size = Vector3.new(1.1, 1.1, 0.15),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 3.45, -1.35), Vector3.new(28, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })
    makePart(folderInterior, {
        Name = "SteeringWheel_Hub",
        Size = Vector3.new(0.45, 0.45, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 3.45, -1.38), Vector3.new(28, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_CHROME,
    })

    -- Floating Infotainment Touchscreen Tablet (Fiat Uconnect 7")
    makePart(folderInterior, {
        Name = "InfotainmentScreen",
        Size = Vector3.new(1.1, 0.7, 0.15),
        CFrame = localToWorld(rootCF, Vector3.new(0, 3.65, -2.25), Vector3.new(-10, 0, 0)),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(20, 22, 25),
    })

    -- Center Console Tunnel & Gear Shifter
    makePart(folderInterior, {
        Name = "CenterConsole_Tunnel",
        Size = Vector3.new(1.2, 0.7, 3.4),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.9, -0.6)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_INTERIOR_DARK,
    })
    makePart(folderInterior, {
        Name = "GearShift_Lever",
        Size = Vector3.new(0.2, 0.6, 0.2),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.45, -1.2)),
        Material = Enum.Material.Metal,
        Color = COLOR_CHROME,
    })
    makePart(folderInterior, {
        Name = "GearShift_Knob",
        Size = Vector3.new(0.35, 0.35, 0.35),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.75, -1.2)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })
    makePart(folderInterior, {
        Name = "Handbrake_Lever",
        Size = Vector3.new(0.18, 0.3, 0.9),
        CFrame = localToWorld(rootCF, Vector3.new(0.2, 2.35, -0.4), Vector3.new(20, 0, 0)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TRIM_BLACK,
    })

    -- Front Driver Bucket Seat
    makePart(folderInterior, {
        Name = "Seat_Driver_Base",
        Size = Vector3.new(1.8, 0.6, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 1.7, -0.6)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })
    makePart(folderInterior, {
        Name = "Seat_Driver_Backrest",
        Size = Vector3.new(1.7, 2.0, 0.5),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 2.8, 0.3), Vector3.new(-12, 0, 0)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })
    makePart(folderInterior, {
        Name = "Seat_Driver_Headrest",
        Size = Vector3.new(0.9, 0.6, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(-1.4, 4.0, 0.55)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })

    -- Front Passenger Bucket Seat
    makePart(folderInterior, {
        Name = "Seat_Passenger_Base",
        Size = Vector3.new(1.8, 0.6, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(1.4, 1.7, -0.6)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })
    makePart(folderInterior, {
        Name = "Seat_Passenger_Backrest",
        Size = Vector3.new(1.7, 2.0, 0.5),
        CFrame = localToWorld(rootCF, Vector3.new(1.4, 2.8, 0.3), Vector3.new(-12, 0, 0)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })
    makePart(folderInterior, {
        Name = "Seat_Passenger_Headrest",
        Size = Vector3.new(0.9, 0.6, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(1.4, 4.0, 0.55)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })

    -- Rear Bench Seat
    makePart(folderInterior, {
        Name = "Seat_Rear_BenchBase",
        Size = Vector3.new(5.0, 0.6, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(0, 1.7, 2.2)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })
    makePart(folderInterior, {
        Name = "Seat_Rear_Backrest",
        Size = Vector3.new(4.9, 1.9, 0.5),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.7, 3.1), Vector3.new(-14, 0, 0)),
        Material = Enum.Material.Fabric,
        Color = COLOR_SEAT_FABRIC,
    })

    -- Interior Rearview Mirror
    makePart(folderInterior, {
        Name = "RearviewMirror",
        Size = Vector3.new(0.9, 0.3, 0.15),
        CFrame = localToWorld(rootCF, Vector3.new(0, 4.5, -2.7), Vector3.new(10, 0, 0)),
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(220, 225, 230),
        Reflectance = 0.6,
    })

    -- ------------------------------------------------------------------------
    -- 11. WHEELS, TIRES & 16" SILVER ALLOY RIMS
    -- ------------------------------------------------------------------------
    -- Fiat Cronos Wheelbase: ~9.0 studs. Front Axle: Z = -4.5. Rear Axle: Z = 4.5. Track Width: 5.8 studs.
    local wheelSpecs = {
        { Name = "Wheel_FL", Pos = Vector3.new(-2.95, 1.35, -4.5), IsLeft = true },
        { Name = "Wheel_FR", Pos = Vector3.new(2.95, 1.35, -4.5), IsLeft = false },
        { Name = "Wheel_RL", Pos = Vector3.new(-2.95, 1.35, 4.5), IsLeft = true },
        { Name = "Wheel_RR", Pos = Vector3.new(2.95, 1.35, 4.5), IsLeft = false },
    }

    for _, w in ipairs(wheelSpecs) do
        -- Outer Tire (Rubber Cylinder, oriented along X axis)
        makeCylinder(folderWheels, {
            Name = w.Name .. "_Tire",
            Size = Vector3.new(0.85, 2.7, 2.7),
            CFrame = localToWorld(rootCF, w.Pos),
            Material = Enum.Material.Rubber,
            Color = COLOR_TIRE_RUBBER,
            CanCollide = true,
        })

        -- Wheel Rim Hub (Silver Alloy)
        makeCylinder(folderWheels, {
            Name = w.Name .. "_Rim",
            Size = Vector3.new(0.88, 1.8, 1.8),
            CFrame = localToWorld(rootCF, w.Pos),
            Material = Enum.Material.Metal,
            Color = COLOR_ALLOY_WHEEL,
            CanCollide = false,
        })

        -- Center Hub Cap & Lug Bolts Accent
        local hubXOffset = if w.IsLeft then -0.05 else 0.05
        makeCylinder(folderWheels, {
            Name = w.Name .. "_HubCap",
            Size = Vector3.new(0.9, 0.6, 0.6),
            CFrame = localToWorld(rootCF, w.Pos + Vector3.new(hubXOffset, 0, 0)),
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(140, 142, 145),
            CanCollide = false,
        })

        -- Brake Disc behind the rim
        local brakeXOffset = if w.IsLeft then 0.25 else -0.25
        makeCylinder(folderWheels, {
            Name = w.Name .. "_BrakeDisc",
            Size = Vector3.new(0.3, 1.6, 1.6),
            CFrame = localToWorld(rootCF, w.Pos + Vector3.new(brakeXOffset, 0, 0)),
            Material = Enum.Material.Metal,
            Color = COLOR_BRAKE_DISC,
            CanCollide = false,
        })
    end

    -- ------------------------------------------------------------------------
    -- 12. ENGINE BAY & FIVE REPAIR COMPONENTS STATUS
    -- ------------------------------------------------------------------------
    -- Engine bay compartment well
    makePart(folderEngine, {
        Name = "EngineBay_Firewall",
        Size = Vector3.new(5.4, 2.1, 0.3),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.4, -3.2)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(35, 36, 38),
    })

    -- Main 1.3L FireFly Engine Block (Center bay)
    makePart(folderEngine, {
        Name = "Engine_Block",
        Size = Vector3.new(2.4, 1.4, 2.0),
        CFrame = localToWorld(rootCF, Vector3.new(-0.2, 2.0, -4.8)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_ENGINE_BLOCK,
    })
    makePart(folderEngine, {
        Name = "Engine_ValveCover",
        Size = Vector3.new(2.2, 0.4, 1.8),
        CFrame = localToWorld(rootCF, Vector3.new(-0.2, 2.8, -4.8)),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_ENGINE_HEAD,
    })

    -- Radiator core mounted behind front grille
    makePart(folderEngine, {
        Name = "Radiator_Core",
        Size = Vector3.new(4.2, 1.3, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(0, 2.0, -6.6)),
        Material = Enum.Material.DiamondPlate,
        Color = Color3.fromRGB(45, 48, 52),
    })

    -- Air filter housing box
    makePart(folderEngine, {
        Name = "AirFilter_Box",
        Size = Vector3.new(1.2, 0.7, 1.3),
        CFrame = localToWorld(rootCF, Vector3.new(-1.8, 2.5, -4.2)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(28, 30, 32),
    })

    -- ------------------------------------------------------------------------
    -- REPAIR ITEM 1: BATTERY (Front Left Compartment)
    -- ------------------------------------------------------------------------
    -- Battery mounting tray (always present)
    makePart(folderEngine, {
        Name = "Battery_MountTray",
        Size = Vector3.new(1.2, 0.2, 1.0),
        CFrame = localToWorld(rootCF, Vector3.new(-2.0, 1.9, -5.7)),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_OXIDE,
    })
    if missing.Battery then
        -- Damaged state: empty tray with loose red & black disconnected terminal cables
        makePart(folderEngine, {
            Name = "BatteryCable_Loose_Pos",
            Size = Vector3.new(0.1, 0.1, 0.6),
            CFrame = localToWorld(rootCF, Vector3.new(-1.75, 2.1, -5.6), Vector3.new(20, 15, 0)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(200, 35, 35), -- Red positive lead
            CanCollide = false,
        })
        makePart(folderEngine, {
            Name = "BatteryCable_Loose_Neg",
            Size = Vector3.new(0.1, 0.1, 0.55),
            CFrame = localToWorld(rootCF, Vector3.new(-2.25, 2.05, -5.6), Vector3.new(15, -25, 0)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(25, 25, 25), -- Black ground lead
            CanCollide = false,
        })
    else
        -- Installed state: Heavy duty 12V automotive battery in tray
        makePart(folderEngine, {
            Name = "Installed_Battery_12V",
            Size = Vector3.new(1.0, 0.8, 0.8),
            CFrame = localToWorld(rootCF, Vector3.new(-2.0, 2.4, -5.7)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(30, 30, 32),
        })
    end

    -- ------------------------------------------------------------------------
    -- REPAIR ITEM 2: ALTERNATOR (Engine Side Bracket)
    -- ------------------------------------------------------------------------
    -- Alternator mounting bracket on right side of engine block
    makePart(folderEngine, {
        Name = "Alternator_Bracket",
        Size = Vector3.new(0.4, 0.5, 0.6),
        CFrame = localToWorld(rootCF, Vector3.new(1.15, 2.1, -4.6)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(90, 94, 98),
    })
    if missing.Alternator then
        -- Damaged state: empty bracket with slack serpentine belt dangling
        makePart(folderEngine, {
            Name = "Alternator_SlackBelt",
            Size = Vector3.new(0.12, 0.8, 0.12),
            CFrame = localToWorld(rootCF, Vector3.new(1.2, 1.8, -4.6), Vector3.new(15, 0, 10)),
            Material = Enum.Material.Rubber,
            Color = Color3.fromRGB(20, 20, 22),
            CanCollide = false,
        })
    else
        -- Installed state: Alternator unit with pulley
        makeCylinder(folderEngine, {
            Name = "Installed_Alternator_Unit",
            Size = Vector3.new(0.7, 0.8, 0.8),
            CFrame = localToWorld(rootCF, Vector3.new(1.3, 2.2, -4.6), Vector3.new(0, 90, 0)),
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(160, 165, 170),
        })
    end

    -- ------------------------------------------------------------------------
    -- REPAIR ITEM 3: SPARK PLUGS (Top of Cylinder Head)
    -- ------------------------------------------------------------------------
    if missing.SparkPlugs then
        -- Damaged state: 4 exposed plug sockets with detached wires dangling
        for i = 1, 4 do
            local zOffset = -5.3 + (i - 1) * 0.35
            makePart(folderEngine, {
                Name = "SparkPlug_Socket_Empty_" .. i,
                Size = Vector3.new(0.25, 0.15, 0.25),
                CFrame = localToWorld(rootCF, Vector3.new(-0.2, 3.02, zOffset)),
                Material = Enum.Material.Metal,
                Color = Color3.fromRGB(30, 32, 35),
                CanCollide = false,
            })
            makePart(folderEngine, {
                Name = "IgnitionWire_Loose_" .. i,
                Size = Vector3.new(0.08, 0.3, 0.08),
                CFrame = localToWorld(rootCF, Vector3.new(-0.45, 3.15, zOffset), Vector3.new(35, 10 * i, 0)),
                Material = Enum.Material.Rubber,
                Color = Color3.fromRGB(40, 42, 46),
                CanCollide = false,
            })
        end
    else
        -- Installed state: connected ignition coils & spark plug rail
        makePart(folderEngine, {
            Name = "Installed_IgnitionRail",
            Size = Vector3.new(0.3, 0.25, 1.4),
            CFrame = localToWorld(rootCF, Vector3.new(-0.2, 3.1, -4.8)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(32, 34, 38),
        })
    end

    -- ------------------------------------------------------------------------
    -- REPAIR ITEM 4: RADIATOR HOSE (Coolant Flow Bridge)
    -- ------------------------------------------------------------------------
    -- Radiator outlet neck
    makePart(folderEngine, {
        Name = "Radiator_Neck_Upper",
        Size = Vector3.new(0.3, 0.3, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(-1.2, 2.5, -6.35)),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(40, 42, 45),
        CanCollide = false,
    })
    -- Thermostat housing neck on engine block
    makePart(folderEngine, {
        Name = "Engine_Thermostat_Neck",
        Size = Vector3.new(0.3, 0.3, 0.4),
        CFrame = localToWorld(rootCF, Vector3.new(-1.0, 2.6, -5.65)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(90, 94, 98),
        CanCollide = false,
    })
    if missing.RadiatorHose then
        -- Damaged state: empty gap with dried green/white coolant scale around the necks
        makePart(folderEngine, {
            Name = "CoolantLeak_Stain",
            Size = Vector3.new(0.35, 0.05, 0.35),
            CFrame = localToWorld(rootCF, Vector3.new(-1.2, 2.33, -6.35)),
            Material = Enum.Material.Sandstone,
            Color = Color3.fromRGB(120, 160, 130), -- dried ethylene glycol residue
            CanCollide = false,
        })
    else
        -- Installed state: Heavy-duty molded rubber upper radiator hose bridging both necks
        makePart(folderEngine, {
            Name = "Installed_RadiatorHose",
            Size = Vector3.new(0.35, 0.35, 0.9),
            CFrame = localToWorld(rootCF, Vector3.new(-1.1, 2.55, -6.0)),
            Material = Enum.Material.Rubber,
            Color = Color3.fromRGB(25, 26, 28),
        })
    end

    -- ------------------------------------------------------------------------
    -- REPAIR ITEM 5: FUEL CANISTER & FUEL FILLER SYSTEM
    -- ------------------------------------------------------------------------
    -- Exterior fuel filler door (Rear Right Quarter Panel)
    makePart(folderDetails, {
        Name = "FuelDoor_Panel",
        Size = Vector3.new(0.08, 0.6, 0.6),
        CFrame = localToWorld(rootCF, Vector3.new(3.32, 2.7, 4.4)),
        Material = Enum.Material.SmoothPlastic,
        Color = paintColor,
        CanCollide = false,
    })
    -- Fuel filler neck inside
    makePart(folderDetails, {
        Name = "FuelFiller_Neck",
        Size = Vector3.new(0.35, 0.35, 0.35),
        CFrame = localToWorld(rootCF, Vector3.new(3.15, 2.7, 4.4)),
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(40, 42, 45),
        CanCollide = false,
    })

    if missing.FuelCanister then
        -- Damaged state: open cap, empty auxiliary canister bracket in the trunk
        makePart(folderDetails, {
            Name = "Trunk_AuxCanister_Cradle_Empty",
            Size = Vector3.new(1.4, 0.3, 1.0),
            CFrame = localToWorld(rootCF, Vector3.new(1.5, 2.0, 5.6)),
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(60, 62, 65),
            CanCollide = false,
        })
    else
        -- Installed state: 20L red jerrycan / auxiliary fuel canister secured in trunk cradle
        makePart(folderDetails, {
            Name = "Installed_FuelCanister_20L",
            Size = Vector3.new(1.2, 1.4, 0.8),
            CFrame = localToWorld(rootCF, Vector3.new(1.5, 2.7, 5.6)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(195, 35, 30), -- Fuel canister red
        })
    end

    -- Parent the model to the designated container if provided
    if opts.Parent then
        model.Parent = opts.Parent
    end

    return model
end

--[[
    Convenience function that builds the Fiat Cronos specifically at the
    canonical Epecuén coordinates:
      X = -160, Y = 19, Z = -755
    Does NOT auto-run on require.
--]]
function VehicleModelBuilder.BuildAtDefaultPosition(parent: Instance?): Model
    return VehicleModelBuilder.Build({
        Position = DEFAULT_SPAWN_POSITION,
        OrientationY = 175,
        Parent = parent,
        IsDamaged = true,
    })
end

return VehicleModelBuilder
