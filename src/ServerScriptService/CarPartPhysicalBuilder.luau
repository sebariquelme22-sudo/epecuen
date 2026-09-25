--!strict
-- ============================================================================
-- CarPartPhysicalBuilder.luau
-- Location: roblox/src/ServerScriptService/CarPartPhysicalBuilder.luau
--
-- EPECUÉN: NO ESCAPE - Fiat Cronos Vehicle-Repair Physical Components Builder
--
-- PURPOSE:
-- Constructs the five physical vehicle-repair components and places each one
-- at the corresponding HidePoint resolved by CarPartObjectiveSystem.
--
-- FIVE PHYSICAL VEHICLE COMPONENTS:
--   1. Battery      -> VehiclePart_Battery_12V
--   2. Alternator   -> VehiclePart_Alternator_14V
--   3. SparkPlugs   -> VehiclePart_SparkPlugs_Set
--   4. FuelCanister -> VehiclePart_FuelCanister_20L
--   5. RadiatorHose -> VehiclePart_RadiatorHose_Reinforced
--
-- DEDICATED CONTAINER:
--   Workspace.EpecuenWorld.CarRepairParts
--
-- GEOMETRY & ASSET CONSTRAINTS:
--   - 100% Native Roblox Geometry (Part, WedgePart, Cylinder).
--   - 0 custom mesh instances, 0 external meshes, 0 textures, 0 plugins, 0 asset IDs.
--   - Lightweight procedural parts (~12-15 parts per component).
--   - Anchored = true, CanCollide = true, CastShadow = true.
--   - Salt-encrusted and weathered appropriate for Laguna Epecuén's hyper-saline flood ruins.
--
-- RESOURCE SEPARATION:
--   The vehicle battery is strictly an automotive starter component for the
--   Fiat Cronos 1.3 Drive. It is completely isolated from any handheld camera/flashlight
--   battery mechanics and is tagged accordingly.
--
-- GAMEPLAY SEPARATION:
--   - Pure physical geometry builder only.
--   - No interaction prompts or triggers.
--   - No collision touch listeners or click detectors.
--   - No collection logic or player inventory interaction.
--   - No objective progress mutations.
--   - No automatic BuildAll() execution on module require.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- ----------------------------------------------------------------------------
-- DEPENDENCY RESOLUTION: CarPartObjectiveSystem
-- ----------------------------------------------------------------------------
local function getCarPartObjectiveSystem(): any
    local parent = script.Parent
    if parent and parent:FindFirstChild("CarPartObjectiveSystem") then
        return require(parent:FindFirstChild("CarPartObjectiveSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarPartObjectiveSystem") then
        return require(serverFolder:FindFirstChild("CarPartObjectiveSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("CarPartObjectiveSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("CarPartObjectiveSystem") :: ModuleScript)
end

local CarPartObjectiveSystem = getCarPartObjectiveSystem()

local CarPartPhysicalBuilder = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type ObjectiveId = "Battery" | "Alternator" | "SparkPlugs" | "FuelCanister" | "RadiatorHose"

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

-- ----------------------------------------------------------------------------
-- COLOR & MATERIAL PALETTE (Hyper-Saline Epecuén Automotive Wear)
-- ----------------------------------------------------------------------------

local COLOR_BLACK_PLASTIC      = Color3.fromRGB(32, 34, 36)
local COLOR_DARK_GRAY_CASING   = Color3.fromRGB(44, 46, 48)
local COLOR_TERMINAL_LEAD      = Color3.fromRGB(155, 160, 165)
local COLOR_TERMINAL_RED       = Color3.fromRGB(185, 42, 38)
local COLOR_TERMINAL_BLACK     = Color3.fromRGB(36, 38, 40)
local COLOR_HANDLE_STRAP       = Color3.fromRGB(175, 140, 45)
local COLOR_ALUMINUM_STATOR    = Color3.fromRGB(132, 138, 142)
local COLOR_COPPER_WINDING     = Color3.fromRGB(185, 108, 42)
local COLOR_PULLEY_STEEL       = Color3.fromRGB(48, 52, 56)
local COLOR_HARDWARE_ZINC      = Color3.fromRGB(165, 170, 175)
local COLOR_CERAMIC_WHITE      = Color3.fromRGB(242, 244, 245)
local COLOR_SPARK_HEX_STEEL    = Color3.fromRGB(85, 90, 95)
local COLOR_BRASS_ACCENT       = Color3.fromRGB(195, 165, 90)
local COLOR_CANISTER_RED       = Color3.fromRGB(132, 46, 38)
local COLOR_CANISTER_HANDLE    = Color3.fromRGB(105, 38, 32)
local COLOR_HOSE_RUBBER        = Color3.fromRGB(28, 30, 32)
local COLOR_HOSE_CLAMP_BAND    = Color3.fromRGB(175, 180, 185)
local COLOR_RUST_SCALE         = Color3.fromRGB(115, 62, 38)
local COLOR_SALT_CRUST         = Color3.fromRGB(235, 238, 230)
local COLOR_SALT_STAIN         = Color3.fromRGB(218, 222, 214)

-- ----------------------------------------------------------------------------
-- PRIMITIVE HELPERS
-- ----------------------------------------------------------------------------

local function makePart(parent: Instance, cfg: PartConfig): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Size = cfg.Size
    p.CFrame = cfg.CFrame
    p.Material = cfg.Material or Enum.Material.SmoothPlastic
    p.Color = cfg.Color or COLOR_BLACK_PLASTIC
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
    w.Material = cfg.Material or Enum.Material.SmoothPlastic
    w.Color = cfg.Color or COLOR_BLACK_PLASTIC
    w.Transparency = cfg.Transparency or 0.0
    w.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    w.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    w.Anchored = true
    w.TopSurface = Enum.SurfaceType.Smooth
    w.BottomSurface = Enum.SurfaceType.Smooth
    w.Parent = parent
    return w
end

--- Creates a Cylinder primitive. In Roblox, cylinder length natively aligns with X axis.
--- orientation "Y": rotates so cylinder length aligns along local Y.
--- orientation "Z": rotates so cylinder length aligns along local Z.
--- orientation "X": default Roblox orientation.
local function makeCylinder(parent: Instance, cfg: PartConfig, orientation: ("X" | "Y" | "Z")?): Part
    local p = Instance.new("Part")
    p.Name = cfg.Name
    p.Shape = Enum.PartType.Cylinder

    local orient = orientation or "Y"
    if orient == "Y" then
        -- cfg.Size: (diameter, height, diameter)
        p.Size = Vector3.new(cfg.Size.Y, cfg.Size.X, cfg.Size.Z)
        p.CFrame = cfg.CFrame * CFrame.Angles(0, 0, math.pi / 2)
    elseif orient == "Z" then
        -- cfg.Size: (diameter, diameter, length)
        p.Size = Vector3.new(cfg.Size.Z, cfg.Size.Y, cfg.Size.X)
        p.CFrame = cfg.CFrame * CFrame.Angles(0, math.pi / 2, 0)
    else
        p.Size = cfg.Size
        p.CFrame = cfg.CFrame
    end

    p.Material = cfg.Material or Enum.Material.Metal
    p.Color = cfg.Color or COLOR_HARDWARE_ZINC
    p.Transparency = cfg.Transparency or 0.0
    p.CanCollide = if cfg.CanCollide ~= nil then cfg.CanCollide else true
    p.CastShadow = if cfg.CastShadow ~= nil then cfg.CastShadow else true
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- ----------------------------------------------------------------------------
-- FOLDER MANAGEMENT
-- Target: Workspace.EpecuenWorld.CarRepairParts
-- ----------------------------------------------------------------------------

local function getOrCreateWorldFolder(): Instance
    local world = Workspace:FindFirstChild("EpecuenWorld")
    if not world then
        world = Instance.new("Folder")
        world.Name = "EpecuenWorld"
        world.Parent = Workspace
    end
    return world
end

function CarPartPhysicalBuilder.GetFolder(): Folder
    local world = getOrCreateWorldFolder()
    local folder = world:FindFirstChild("CarRepairParts")
    if folder and folder:IsA("Folder") then
        return folder
    end

    local newFolder = Instance.new("Folder")
    newFolder.Name = "CarRepairParts"
    newFolder.Parent = world
    return newFolder
end

-- ----------------------------------------------------------------------------
-- 1. BATTERY BUILDER: Fiat Cronos 12V 75Ah Automotive Battery
-- ----------------------------------------------------------------------------

--- Builds the physical model for the Fiat Cronos 12V lead-acid automotive battery.
--- Strictly an automotive starter part; fully isolated from camera flashlight batteries.
function CarPartPhysicalBuilder.BuildBattery(cframe: CFrame?, parent: Instance?): Model
    local rootCF = cframe or CFrame.new(0, 0, 0)
    local targetParent = parent or CarPartPhysicalBuilder.GetFolder()

    local model = Instance.new("Model")
    model.Name = "VehiclePart_Battery_12V"
    model:SetAttribute("ObjectiveId", "Battery")
    model:SetAttribute("PartType", "Battery")
    model:SetAttribute("ItemName", "Batería de Plomo 12V 75Ah")
    model:SetAttribute("IsVehiclePart", true)
    model:SetAttribute("VehicleComponent", "FiatCronosBattery")
    model:SetAttribute("System", "AutomotiveStarter")

    -- 1. Main battery casing (polypropylene block)
    local casing = makePart(model, {
        Name = "BatteryCasing",
        Size = Vector3.new(1.3, 0.75, 0.8),
        CFrame = rootCF * CFrame.new(0, 0.375, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_BLACK_PLASTIC,
    })
    model.PrimaryPart = casing

    -- 2. Bottom mounting foot ledge (clamp flange)
    makePart(model, {
        Name = "BaseFlange",
        Size = Vector3.new(1.4, 0.08, 0.9),
        CFrame = rootCF * CFrame.new(0, 0.04, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_BLACK_PLASTIC,
    })

    -- 3. Top cover lid
    makePart(model, {
        Name = "TopCoverLid",
        Size = Vector3.new(1.26, 0.12, 0.76),
        CFrame = rootCF * CFrame.new(0, 0.81, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_DARK_GRAY_CASING,
    })

    -- 4. Cell vent bridge (recessed central bar)
    makePart(model, {
        Name = "CellVentBridge",
        Size = Vector3.new(0.95, 0.05, 0.3),
        CFrame = rootCF * CFrame.new(0, 0.88, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_BLACK_PLASTIC,
    })

    -- 5. Positive Terminal Collar (Red warning ring)
    makeCylinder(model, {
        Name = "TerminalCollar_Pos",
        Size = Vector3.new(0.24, 0.04, 0.24),
        CFrame = rootCF * CFrame.new(-0.45, 0.89, -0.22),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TERMINAL_RED,
    }, "Y")

    -- 6. Positive Lead Post (+)
    makeCylinder(model, {
        Name = "TerminalPost_Pos",
        Size = Vector3.new(0.14, 0.16, 0.14),
        CFrame = rootCF * CFrame.new(-0.45, 0.97, -0.22),
        Material = Enum.Material.Metal,
        Color = COLOR_TERMINAL_LEAD,
    }, "Y")

    -- 7. Negative Terminal Collar (Black ring)
    makeCylinder(model, {
        Name = "TerminalCollar_Neg",
        Size = Vector3.new(0.24, 0.04, 0.24),
        CFrame = rootCF * CFrame.new(0.45, 0.89, -0.22),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_TERMINAL_BLACK,
    }, "Y")

    -- 8. Negative Lead Post (-)
    makeCylinder(model, {
        Name = "TerminalPost_Neg",
        Size = Vector3.new(0.14, 0.16, 0.14),
        CFrame = rootCF * CFrame.new(0.45, 0.97, -0.22),
        Material = Enum.Material.Metal,
        Color = COLOR_TERMINAL_LEAD,
    }, "Y")

    -- 9. Folded Nylon Carry Handle
    makePart(model, {
        Name = "CarryHandle",
        Size = Vector3.new(0.85, 0.05, 0.12),
        CFrame = rootCF * CFrame.new(0, 0.90, 0.2),
        Material = Enum.Material.Fabric,
        Color = COLOR_HANDLE_STRAP,
    })

    -- 10. Specification Label Plate (Front)
    makePart(model, {
        Name = "SpecLabelPlate",
        Size = Vector3.new(0.7, 0.35, 0.03),
        CFrame = rootCF * CFrame.new(0, 0.42, 0.41),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_CERAMIC_WHITE,
    })

    -- 11. Mineral Salt Crust (Post-flood deposit on casing side)
    makePart(model, {
        Name = "SaltCrustDeposit",
        Size = Vector3.new(0.4, 0.2, 0.04),
        CFrame = rootCF * CFrame.new(0.35, 0.22, 0.41),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST,
    })

    -- 12. Corroded Corner Wedge Detail
    makeWedge(model, {
        Name = "SaltCrustWedge",
        Size = Vector3.new(0.2, 0.15, 0.2),
        CFrame = rootCF * CFrame.new(-0.55, 0.12, -0.3),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_STAIN,
    })

    model.Parent = targetParent
    return model
end

-- ----------------------------------------------------------------------------
-- 2. ALTERNATOR BUILDER: 14V Automotive Charging Alternator
-- ----------------------------------------------------------------------------

--- Builds the physical model for the 14V heavy charging alternator.
function CarPartPhysicalBuilder.BuildAlternator(cframe: CFrame?, parent: Instance?): Model
    local rootCF = cframe or CFrame.new(0, 0, 0)
    local targetParent = parent or CarPartPhysicalBuilder.GetFolder()

    local model = Instance.new("Model")
    model.Name = "VehiclePart_Alternator_14V"
    model:SetAttribute("ObjectiveId", "Alternator")
    model:SetAttribute("PartType", "Alternator")
    model:SetAttribute("ItemName", "Alternador de Carga 14V")
    model:SetAttribute("IsVehiclePart", true)

    -- 1. Main Cylindrical Stator Body (Cast Aluminum Housing)
    local stator = makeCylinder(model, {
        Name = "StatorHousing",
        Size = Vector3.new(0.9, 0.75, 0.9),
        CFrame = rootCF * CFrame.new(0, 0.45, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_ALUMINUM_STATOR,
    }, "Z")
    model.PrimaryPart = stator

    -- 2. Copper Stator Winding Band (Visible through side cooling louvers)
    makeCylinder(model, {
        Name = "CopperWindings",
        Size = Vector3.new(0.82, 0.25, 0.82),
        CFrame = rootCF * CFrame.new(0, 0.45, 0),
        Material = Enum.Material.Foil,
        Color = COLOR_COPPER_WINDING,
    }, "Z")

    -- 3. Front Drive End Housing (Aluminum cap)
    makeCylinder(model, {
        Name = "FrontEndHousing",
        Size = Vector3.new(0.88, 0.18, 0.88),
        CFrame = rootCF * CFrame.new(0, 0.45, 0.42),
        Material = Enum.Material.Metal,
        Color = COLOR_ALUMINUM_STATOR,
    }, "Z")

    -- 4. V-Ribbed Serpentine Belt Pulley (Steel)
    makeCylinder(model, {
        Name = "SerpentinePulley",
        Size = Vector3.new(0.55, 0.22, 0.55),
        CFrame = rootCF * CFrame.new(0, 0.45, 0.58),
        Material = Enum.Material.Metal,
        Color = COLOR_PULLEY_STEEL,
    }, "Z")

    -- 5. Pulley Retention Center Locknut
    makeCylinder(model, {
        Name = "ShaftCenterNut",
        Size = Vector3.new(0.2, 0.08, 0.2),
        CFrame = rootCF * CFrame.new(0, 0.45, 0.72),
        Material = Enum.Material.Metal,
        Color = COLOR_HARDWARE_ZINC,
    }, "Z")

    -- 6. Top Pivot Mounting Lug / Ear
    makePart(model, {
        Name = "TopMountingEar",
        Size = Vector3.new(0.25, 0.35, 0.45),
        CFrame = rootCF * CFrame.new(0, 0.95, 0.05),
        Material = Enum.Material.Metal,
        Color = COLOR_ALUMINUM_STATOR,
    })

    -- 7. Bottom Tensioning Arm Bracket
    makePart(model, {
        Name = "BottomTensionEar",
        Size = Vector3.new(0.3, 0.25, 0.35),
        CFrame = rootCF * CFrame.new(-0.35, 0.12, -0.05),
        Material = Enum.Material.Metal,
        Color = COLOR_ALUMINUM_STATOR,
    })

    -- 8. Rear Rectifier / Brush Cover Box
    makePart(model, {
        Name = "RearRectifierCover",
        Size = Vector3.new(0.65, 0.65, 0.18),
        CFrame = rootCF * CFrame.new(0, 0.45, -0.45),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_BLACK_PLASTIC,
    })

    -- 9. B+ Battery Charging Copper Stud Terminal
    makeCylinder(model, {
        Name = "BPlusTerminalStud",
        Size = Vector3.new(0.1, 0.15, 0.1),
        CFrame = rootCF * CFrame.new(0.18, 0.62, -0.58),
        Material = Enum.Material.Metal,
        Color = COLOR_COPPER_WINDING,
    }, "Z")

    -- 10. Ground / Earth Terminal Lug
    makePart(model, {
        Name = "GroundLug",
        Size = Vector3.new(0.15, 0.1, 0.08),
        CFrame = rootCF * CFrame.new(-0.18, 0.32, -0.56),
        Material = Enum.Material.Metal,
        Color = COLOR_HARDWARE_ZINC,
    })

    -- 11. Rust Patina Accents (30 years saline exposure)
    makePart(model, {
        Name = "RustPatinaPatch",
        Size = Vector3.new(0.3, 0.18, 0.05),
        CFrame = rootCF * CFrame.new(0.25, 0.72, 0.1),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_SCALE,
    })

    -- 12. Mineral Salt Crust Band
    makePart(model, {
        Name = "SaltCrustCuff",
        Size = Vector3.new(0.25, 0.15, 0.15),
        CFrame = rootCF * CFrame.new(-0.35, 0.28, -0.3),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST,
    })

    model.Parent = targetParent
    return model
end

-- ----------------------------------------------------------------------------
-- 3. SPARK PLUGS BUILDER: 4-Piece Automotive Spark Plug Set in Metal Tray
-- ----------------------------------------------------------------------------

--- Builds the physical model for the set of 4 automotive ignition spark plugs.
function CarPartPhysicalBuilder.BuildSparkPlugs(cframe: CFrame?, parent: Instance?): Model
    local rootCF = cframe or CFrame.new(0, 0, 0)
    local targetParent = parent or CarPartPhysicalBuilder.GetFolder()

    local model = Instance.new("Model")
    model.Name = "VehiclePart_SparkPlugs_Set"
    model:SetAttribute("ObjectiveId", "SparkPlugs")
    model:SetAttribute("PartType", "SparkPlugs")
    model:SetAttribute("ItemName", "Juego de Bujías de Encendido")
    model:SetAttribute("IsVehiclePart", true)

    -- 1. Heavy Galvanized Metal Parts Carrier / Tool Tray Base
    local trayBase = makePart(model, {
        Name = "ToolTrayBase",
        Size = Vector3.new(1.1, 0.08, 0.7),
        CFrame = rootCF * CFrame.new(0, 0.04, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_SPARK_HEX_STEEL,
    })
    model.PrimaryPart = trayBase

    -- 2. Tray Rear Rim Flange
    makePart(model, {
        Name = "TrayRimRear",
        Size = Vector3.new(1.1, 0.18, 0.06),
        CFrame = rootCF * CFrame.new(0, 0.13, -0.32),
        Material = Enum.Material.Metal,
        Color = COLOR_SPARK_HEX_STEEL,
    })

    -- 3. Tray Front Rim Flange
    makePart(model, {
        Name = "TrayRimFront",
        Size = Vector3.new(1.1, 0.18, 0.06),
        CFrame = rootCF * CFrame.new(0, 0.13, 0.32),
        Material = Enum.Material.Metal,
        Color = COLOR_SPARK_HEX_STEEL,
    })

    -- 4. Tray Foam/Felt Partition Insert
    makePart(model, {
        Name = "FoamOrganizerInsert",
        Size = Vector3.new(0.98, 0.06, 0.58),
        CFrame = rootCF * CFrame.new(0, 0.09, 0),
        Material = Enum.Material.Fabric,
        Color = COLOR_BLACK_PLASTIC,
    })

    -- 4 Individual Spark Plugs arranged in order
    local plugOffsetsX = { -0.36, -0.12, 0.12, 0.36 }
    for i, posX in ipairs(plugOffsetsX) do
        -- Plug Hexagonal Steel Threaded Base
        makePart(model, {
            Name = "SparkPlugHexBase_" .. i,
            Size = Vector3.new(0.18, 0.18, 0.18),
            CFrame = rootCF * CFrame.new(posX, 0.18, 0),
            Material = Enum.Material.Metal,
            Color = COLOR_SPARK_HEX_STEEL,
        })

        -- Plug White Ceramic Ribbed Insulator Column
        makeCylinder(model, {
            Name = "CeramicInsulator_" .. i,
            Size = Vector3.new(0.14, 0.35, 0.14),
            CFrame = rootCF * CFrame.new(posX, 0.44, 0),
            Material = Enum.Material.SmoothPlastic,
            Color = COLOR_CERAMIC_WHITE,
        }, "Y")

        -- Brass / Nickel Top Terminal Stud Tip
        makeCylinder(model, {
            Name = "TerminalNipple_" .. i,
            Size = Vector3.new(0.08, 0.1, 0.08),
            CFrame = rootCF * CFrame.new(posX, 0.65, 0),
            Material = Enum.Material.Metal,
            Color = COLOR_BRASS_ACCENT,
        }, "Y")
    end

    -- Salt crust on tray rim from spray
    makePart(model, {
        Name = "SaltCrustSpray",
        Size = Vector3.new(0.35, 0.1, 0.12),
        CFrame = rootCF * CFrame.new(-0.35, 0.15, 0.28),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST,
    })

    -- Rust stain on tray corner
    makePart(model, {
        Name = "RustCorrosionEdge",
        Size = Vector3.new(0.2, 0.1, 0.15),
        CFrame = rootCF * CFrame.new(0.42, 0.12, -0.25),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_SCALE,
    })

    model.Parent = targetParent
    return model
end

-- ----------------------------------------------------------------------------
-- 4. FUEL CANISTER BUILDER: 20L Heavy Steel Jerrycan (Bidón de Nafta 20L)
-- ----------------------------------------------------------------------------

--- Builds the physical model for the 20L heavy steel stamped automotive fuel canister.
function CarPartPhysicalBuilder.BuildFuelCanister(cframe: CFrame?, parent: Instance?): Model
    local rootCF = cframe or CFrame.new(0, 0, 0)
    local targetParent = parent or CarPartPhysicalBuilder.GetFolder()

    local model = Instance.new("Model")
    model.Name = "VehiclePart_FuelCanister_20L"
    model:SetAttribute("ObjectiveId", "FuelCanister")
    model:SetAttribute("PartType", "FuelCanister")
    model:SetAttribute("ItemName", "Bidón de Nafta 20L")
    model:SetAttribute("IsVehiclePart", true)

    -- 1. Main Sheet Steel Stamped Body
    local canisterBody = makePart(model, {
        Name = "CanisterBody",
        Size = Vector3.new(1.1, 1.35, 0.6),
        CFrame = rootCF * CFrame.new(0, 0.72, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_RED,
    })
    model.PrimaryPart = canisterBody

    -- 2. Welded Bottom Base Rim Flange
    makePart(model, {
        Name = "BottomSeamFlange",
        Size = Vector3.new(1.16, 0.08, 0.66),
        CFrame = rootCF * CFrame.new(0, 0.04, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 3. Top Shoulder Bevel (Wedge Left)
    makeWedge(model, {
        Name = "ShoulderWedgeLeft",
        Size = Vector3.new(0.6, 0.22, 0.25),
        CFrame = rootCF * CFrame.new(-0.42, 1.45, 0) * CFrame.Angles(0, math.pi / 2, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_RED,
    })

    -- 4. Top Shoulder Bevel (Wedge Right)
    makeWedge(model, {
        Name = "ShoulderWedgeRight",
        Size = Vector3.new(0.6, 0.22, 0.25),
        CFrame = rootCF * CFrame.new(0.42, 1.45, 0) * CFrame.Angles(0, -math.pi / 2, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_RED,
    })

    -- 5. Stamped Cross Stiffener Indentation Plate (Front)
    makePart(model, {
        Name = "XStiffenerPlate_Front",
        Size = Vector3.new(0.7, 0.8, 0.04),
        CFrame = rootCF * CFrame.new(0, 0.72, 0.31),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 6. Stamped Cross Stiffener Indentation Plate (Back)
    makePart(model, {
        Name = "XStiffenerPlate_Back",
        Size = Vector3.new(0.7, 0.8, 0.04),
        CFrame = rootCF * CFrame.new(0, 0.72, -0.31),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 7. Center Carry Handle Tube
    makePart(model, {
        Name = "CarryHandleCenter",
        Size = Vector3.new(0.55, 0.08, 0.1),
        CFrame = rootCF * CFrame.new(0, 1.62, 0),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 8. Outer Left Carry Bar
    makePart(model, {
        Name = "CarryHandleLeft",
        Size = Vector3.new(0.55, 0.07, 0.08),
        CFrame = rootCF * CFrame.new(0, 1.61, -0.15),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 9. Outer Right Carry Bar
    makePart(model, {
        Name = "CarryHandleRight",
        Size = Vector3.new(0.55, 0.07, 0.08),
        CFrame = rootCF * CFrame.new(0, 1.61, 0.15),
        Material = Enum.Material.Metal,
        Color = COLOR_CANISTER_HANDLE,
    })

    -- 10. Angled Fuel Spout Neck
    makeCylinder(model, {
        Name = "PouringSpoutNeck",
        Size = Vector3.new(0.22, 0.28, 0.22),
        CFrame = rootCF * CFrame.new(-0.35, 1.55, 0.12) * CFrame.Angles(math.rad(20), 0, math.rad(-25)),
        Material = Enum.Material.Metal,
        Color = COLOR_SPARK_HEX_STEEL,
    }, "Y")

    -- 11. Heavy Cam-Locking Steel Cap
    makeCylinder(model, {
        Name = "CamLockCap",
        Size = Vector3.new(0.26, 0.12, 0.26),
        CFrame = rootCF * CFrame.new(-0.41, 1.68, 0.16) * CFrame.Angles(math.rad(20), 0, math.rad(-25)),
        Material = Enum.Material.Metal,
        Color = COLOR_HARDWARE_ZINC,
    }, "Y")

    -- 12. Pressure Release Breather Valve Pin
    makePart(model, {
        Name = "BreatherValvePin",
        Size = Vector3.new(0.08, 0.12, 0.08),
        CFrame = rootCF * CFrame.new(-0.25, 1.52, -0.12),
        Material = Enum.Material.Metal,
        Color = COLOR_BRASS_ACCENT,
    })

    -- 13. Weathered Salt Streak (North Entrance flood deposits)
    makePart(model, {
        Name = "SaltDepositStreak",
        Size = Vector3.new(0.3, 0.45, 0.03),
        CFrame = rootCF * CFrame.new(0.28, 0.52, 0.31),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST,
    })

    -- 14. Rust scaling on bottom edge
    makePart(model, {
        Name = "RustSeamFlange",
        Size = Vector3.new(0.5, 0.1, 0.06),
        CFrame = rootCF * CFrame.new(-0.2, 0.12, 0.32),
        Material = Enum.Material.CorrodedMetal,
        Color = COLOR_RUST_SCALE,
    })

    model.Parent = targetParent
    return model
end

-- ----------------------------------------------------------------------------
-- 5. RADIATOR HOSE BUILDER: Reinforced Automotive Coolant Hose with Clamps
-- ----------------------------------------------------------------------------

--- Builds the physical model for the reinforced automotive radiator coolant hose.
function CarPartPhysicalBuilder.BuildRadiatorHose(cframe: CFrame?, parent: Instance?): Model
    local rootCF = cframe or CFrame.new(0, 0, 0)
    local targetParent = parent or CarPartPhysicalBuilder.GetFolder()

    local model = Instance.new("Model")
    model.Name = "VehiclePart_RadiatorHose_Reinforced"
    model:SetAttribute("ObjectiveId", "RadiatorHose")
    model:SetAttribute("PartType", "RadiatorHose")
    model:SetAttribute("ItemName", "Manguera Reforzada de Refrigerante")
    model:SetAttribute("IsVehiclePart", true)

    -- 1. Central Curved Elbow Segment (Primary Body)
    local midHose = makeCylinder(model, {
        Name = "HoseMidElbow",
        Size = Vector3.new(0.42, 0.65, 0.42),
        CFrame = rootCF * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, math.rad(25), 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_HOSE_RUBBER,
    }, "X")
    model.PrimaryPart = midHose

    -- 2. Inlet Leg Segment (S-curve angled branch)
    makeCylinder(model, {
        Name = "HoseInletBranch",
        Size = Vector3.new(0.40, 0.55, 0.40),
        CFrame = rootCF * CFrame.new(-0.45, 0.25, -0.22) * CFrame.Angles(0, math.rad(-30), 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_HOSE_RUBBER,
    }, "X")

    -- 3. Outlet Leg Segment
    makeCylinder(model, {
        Name = "HoseOutletBranch",
        Size = Vector3.new(0.40, 0.55, 0.40),
        CFrame = rootCF * CFrame.new(0.45, 0.25, 0.22) * CFrame.Angles(0, math.rad(55), 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLOR_HOSE_RUBBER,
    }, "X")

    -- 4. Inlet Stainless Steel Worm-Gear Clamp Ring
    makeCylinder(model, {
        Name = "InletClampBand",
        Size = Vector3.new(0.44, 0.12, 0.44),
        CFrame = rootCF * CFrame.new(-0.62, 0.25, -0.32) * CFrame.Angles(0, math.rad(-30), 0),
        Material = Enum.Material.Metal,
        Color = COLOR_HOSE_CLAMP_BAND,
    }, "X")

    -- 5. Inlet Clamp Tightening Screw Box
    makePart(model, {
        Name = "InletClampScrewBox",
        Size = Vector3.new(0.12, 0.14, 0.16),
        CFrame = rootCF * CFrame.new(-0.62, 0.48, -0.32),
        Material = Enum.Material.Metal,
        Color = COLOR_HARDWARE_ZINC,
    })

    -- 6. Outlet Stainless Steel Worm-Gear Clamp Ring
    makeCylinder(model, {
        Name = "OutletClampBand",
        Size = Vector3.new(0.44, 0.12, 0.44),
        CFrame = rootCF * CFrame.new(0.62, 0.25, 0.32) * CFrame.Angles(0, math.rad(55), 0),
        Material = Enum.Material.Metal,
        Color = COLOR_HOSE_CLAMP_BAND,
    }, "X")

    -- 7. Outlet Clamp Tightening Screw Box
    makePart(model, {
        Name = "OutletClampScrewBox",
        Size = Vector3.new(0.12, 0.14, 0.16),
        CFrame = rootCF * CFrame.new(0.62, 0.48, 0.32),
        Material = Enum.Material.Metal,
        Color = COLOR_HARDWARE_ZINC,
    })

    -- 8. Textile Reinforcement Mesh Rib (Center)
    makeCylinder(model, {
        Name = "ReinforcementRib_Mid",
        Size = Vector3.new(0.43, 0.05, 0.43),
        CFrame = rootCF * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, math.rad(25), 0),
        Material = Enum.Material.Fabric,
        Color = COLOR_BLACK_PLASTIC,
    }, "X")

    -- 9. Textile Reinforcement Mesh Rib (Left)
    makeCylinder(model, {
        Name = "ReinforcementRib_Left",
        Size = Vector3.new(0.42, 0.05, 0.42),
        CFrame = rootCF * CFrame.new(-0.25, 0.25, -0.1) * CFrame.Angles(0, math.rad(10), 0),
        Material = Enum.Material.Fabric,
        Color = COLOR_BLACK_PLASTIC,
    }, "X")

    -- 10. Textile Reinforcement Mesh Rib (Right)
    makeCylinder(model, {
        Name = "ReinforcementRib_Right",
        Size = Vector3.new(0.42, 0.05, 0.42),
        CFrame = rootCF * CFrame.new(0.25, 0.25, 0.1) * CFrame.Angles(0, math.rad(35), 0),
        Material = Enum.Material.Fabric,
        Color = COLOR_BLACK_PLASTIC,
    }, "X")

    -- 11. White Dried Coolant & Mineral Salt Scaling
    makePart(model, {
        Name = "DriedCoolantSaltStain",
        Size = Vector3.new(0.25, 0.08, 0.15),
        CFrame = rootCF * CFrame.new(0.05, 0.42, 0.02),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_CRUST,
    })

    -- 12. Secondary salt crusting on clamp edge
    makePart(model, {
        Name = "ClampSaltScale",
        Size = Vector3.new(0.15, 0.06, 0.12),
        CFrame = rootCF * CFrame.new(-0.55, 0.15, -0.28),
        Material = Enum.Material.Sandstone,
        Color = COLOR_SALT_STAIN,
    })

    model.Parent = targetParent
    return model
end

-- ----------------------------------------------------------------------------
-- COMPONENT BUILDER REGISTRY
-- ----------------------------------------------------------------------------

local BUILDER_REGISTRY: {
    [ObjectiveId]: {
        ModelName: string,
        BuildFn: (cframe: CFrame?, parent: Instance?) -> Model,
    }
} = {
    Battery = {
        ModelName = "VehiclePart_Battery_12V",
        BuildFn = CarPartPhysicalBuilder.BuildBattery,
    },
    Alternator = {
        ModelName = "VehiclePart_Alternator_14V",
        BuildFn = CarPartPhysicalBuilder.BuildAlternator,
    },
    SparkPlugs = {
        ModelName = "VehiclePart_SparkPlugs_Set",
        BuildFn = CarPartPhysicalBuilder.BuildSparkPlugs,
    },
    FuelCanister = {
        ModelName = "VehiclePart_FuelCanister_20L",
        BuildFn = CarPartPhysicalBuilder.BuildFuelCanister,
    },
    RadiatorHose = {
        ModelName = "VehiclePart_RadiatorHose_Reinforced",
        BuildFn = CarPartPhysicalBuilder.BuildRadiatorHose,
    },
}

-- ----------------------------------------------------------------------------
-- PUBLIC API: BuildAll & Query Methods
-- ----------------------------------------------------------------------------

--- Returns the array of five component model names.
function CarPartPhysicalBuilder.GetComponentNames(): { string }
    return {
        "VehiclePart_Battery_12V",
        "VehiclePart_Alternator_14V",
        "VehiclePart_SparkPlugs_Set",
        "VehiclePart_FuelCanister_20L",
        "VehiclePart_RadiatorHose_Reinforced",
    }
end

--- Retrieves an existing built Model from Workspace.EpecuenWorld.CarRepairParts if present.
function CarPartPhysicalBuilder.GetModel(objectiveId: string): Model?
    local clean = string.gsub(objectiveId, "%s+", "")
    local info = BUILDER_REGISTRY[clean :: ObjectiveId]
    if not info then
        return nil
    end

    local folder = CarPartPhysicalBuilder.GetFolder()
    local existing = folder:FindFirstChild(info.ModelName)
    if existing and existing:IsA("Model") then
        return existing
    end

    return nil
end

--- Clears any existing physical vehicle repair models inside Workspace.EpecuenWorld.CarRepairParts.
function CarPartPhysicalBuilder.ClearAll(): ()
    local folder = CarPartPhysicalBuilder.GetFolder()
    for _, info in pairs(BUILDER_REGISTRY) do
        local existing = folder:FindFirstChild(info.ModelName)
        if existing then
            existing:Destroy()
        end
    end
end

--- Builds all five physical vehicle repair components and places each one at its
--- corresponding HidePoint provided by CarPartObjectiveSystem.
---
--- SAFE IDEMPOTENCY:
--- Replaces any previously generated models inside Workspace.EpecuenWorld.CarRepairParts
--- to prevent duplicate geometry.
---
--- CANONICAL PRESERVATION:
--- Uses the resolved HidePoint CFrame when available in Workspace. If the map has not
--- yet generated hideout structures, falls back gracefully to the canonical objective coordinate.
function CarPartPhysicalBuilder.BuildAll(): { [string]: Model }
    local folder = CarPartPhysicalBuilder.GetFolder()
    local order: { ObjectiveId } = CarPartObjectiveSystem.GetObjectiveOrder()
    local createdModels: { [string]: Model } = {}

    for _, objectiveId in ipairs(order) do
        local registryEntry = BUILDER_REGISTRY[objectiveId]
        if registryEntry then
            -- Safe idempotency: remove existing model if present
            local existing = folder:FindFirstChild(registryEntry.ModelName)
            if existing then
                existing:Destroy()
            end

            -- Resolve target placement CFrame from CarPartObjectiveSystem
            local targetCFrame: CFrame? = nil

            -- 1. Try to resolve physical HidePoint marker part
            local hidePoint = CarPartObjectiveSystem.GetHidePoint(objectiveId)
            if hidePoint and hidePoint:IsA("BasePart") then
                targetCFrame = hidePoint.CFrame
            else
                -- 2. Graceful fallback: canonical position from objective definition
                local def = CarPartObjectiveSystem.GetDefinition(objectiveId)
                if def then
                    targetCFrame = CFrame.new(def.CanonicalPosition)
                end
            end

            local model = registryEntry.BuildFn(targetCFrame, folder)
            if model and targetCFrame then
                model:PivotTo(targetCFrame)
            end

            createdModels[objectiveId] = model
            createdModels[registryEntry.ModelName] = model
        end
    end

    return createdModels
end

return CarPartPhysicalBuilder
