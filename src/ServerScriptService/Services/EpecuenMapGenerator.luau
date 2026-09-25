--!strict
--[[
    EpecuenMapGenerator.luau
    Base 3D World Structural Geography Generator for "EPECUÉN: NO ESCAPE"
    
    Reads EpecuenMapSpecification.luau and builds the continuous open-world foundation:
      - World boundaries & terrain base plate
      - Paved & unpaved streets and access roads
      - Road intersections
      - Urban grid blocks (manzanas) and radial park sectors
      - Central Plaza ("Ud. Está Aquí")
      - Lagoon shoreline and central U-shaped pier
      - Deep water and semi-flooded shallow areas
      - Deteriorated road to El Matadero
      - Zone boundary volumes & major landmark structural placeholders
      - Player spawn, Fiat Cronos, car-part search zones & tactical markers
      
    Target Folder Hierarchy:
      Workspace
      └── EpecuenWorld
          ├── Roads
          ├── Blocks
          ├── Water
          ├── Zones
          ├── Landmarks
          └── Markers
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local EpecuenMapSpecification = require(EpecuenShared:WaitForChild("EpecuenMapSpecification") :: ModuleScript)

local function getVehicleModelBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("VehicleModelBuilder") then
        return require(parent.Parent:FindFirstChild("VehicleModelBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("VehicleModelBuilder") then
        return require(serverFolder:FindFirstChild("VehicleModelBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("VehicleModelBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("VehicleModelBuilder") :: ModuleScript)
end

local VehicleModelBuilder = getVehicleModelBuilder()

local function getRuinModelBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("RuinModelBuilder") then
        return require(parent.Parent:FindFirstChild("RuinModelBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("RuinModelBuilder") then
        return require(serverFolder:FindFirstChild("RuinModelBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("RuinModelBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("RuinModelBuilder") :: ModuleScript)
end

local RuinModelBuilder = getRuinModelBuilder()

local function getEpecuenEnvironmentBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("EpecuenEnvironmentBuilder") then
        return require(parent.Parent:FindFirstChild("EpecuenEnvironmentBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("EpecuenEnvironmentBuilder") then
        return require(serverFolder:FindFirstChild("EpecuenEnvironmentBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("EpecuenEnvironmentBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("EpecuenEnvironmentBuilder") :: ModuleScript)
end

local EpecuenEnvironmentBuilder = getEpecuenEnvironmentBuilder()

local function getLandmarkModelBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("LandmarkModelBuilder") then
        return require(parent.Parent:FindFirstChild("LandmarkModelBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("LandmarkModelBuilder") then
        return require(serverFolder:FindFirstChild("LandmarkModelBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("LandmarkModelBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("LandmarkModelBuilder") :: ModuleScript)
end

local LandmarkModelBuilder = getLandmarkModelBuilder()

local function getChurchLandmarkBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("ChurchLandmarkBuilder") then
        return require(parent.Parent:FindFirstChild("ChurchLandmarkBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("ChurchLandmarkBuilder") then
        return require(serverFolder:FindFirstChild("ChurchLandmarkBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("ChurchLandmarkBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("ChurchLandmarkBuilder") :: ModuleScript)
end

local ChurchLandmarkBuilder = getChurchLandmarkBuilder()

local function getMataderoLandmarkBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("MataderoLandmarkBuilder") then
        return require(parent.Parent:FindFirstChild("MataderoLandmarkBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("MataderoLandmarkBuilder") then
        return require(serverFolder:FindFirstChild("MataderoLandmarkBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("MataderoLandmarkBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("MataderoLandmarkBuilder") :: ModuleScript)
end

local MataderoLandmarkBuilder = getMataderoLandmarkBuilder()

local function getPlazaCentralLandmarkBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("PlazaCentralLandmarkBuilder") then
        return require(parent.Parent:FindFirstChild("PlazaCentralLandmarkBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("PlazaCentralLandmarkBuilder") then
        return require(serverFolder:FindFirstChild("PlazaCentralLandmarkBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("PlazaCentralLandmarkBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("PlazaCentralLandmarkBuilder") :: ModuleScript)
end

local PlazaCentralLandmarkBuilder = getPlazaCentralLandmarkBuilder()

local function getUrbanBuildingModelBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("UrbanBuildingModelBuilder") then
        return require(parent.Parent:FindFirstChild("UrbanBuildingModelBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("UrbanBuildingModelBuilder") then
        return require(serverFolder:FindFirstChild("UrbanBuildingModelBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("UrbanBuildingModelBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("UrbanBuildingModelBuilder") :: ModuleScript)
end

local UrbanBuildingModelBuilder = getUrbanBuildingModelBuilder()

local function getRailwayStationLandmarkBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("RailwayStationLandmarkBuilder") then
        return require(parent.Parent:FindFirstChild("RailwayStationLandmarkBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("RailwayStationLandmarkBuilder") then
        return require(serverFolder:FindFirstChild("RailwayStationLandmarkBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("RailwayStationLandmarkBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("RailwayStationLandmarkBuilder") :: ModuleScript)
end

local RailwayStationLandmarkBuilder = getRailwayStationLandmarkBuilder()

local function getUrbanPopulationPlanner(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("UrbanPopulationPlanner") then
        return require(parent.Parent:FindFirstChild("UrbanPopulationPlanner") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("UrbanPopulationPlanner") then
        return require(serverFolder:FindFirstChild("UrbanPopulationPlanner") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("UrbanPopulationPlanner", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("UrbanPopulationPlanner") :: ModuleScript)
end

local UrbanPopulationPlanner = getUrbanPopulationPlanner()

local function getCarPartHideoutBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("CarPartHideoutBuilder") then
        return require(parent.Parent:FindFirstChild("CarPartHideoutBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarPartHideoutBuilder") then
        return require(serverFolder:FindFirstChild("CarPartHideoutBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("CarPartHideoutBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("CarPartHideoutBuilder") :: ModuleScript)
end

local CarPartHideoutBuilder = getCarPartHideoutBuilder()

local function getRepairToolWorldPlacement(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("RepairToolWorldPlacement") then
        return require(parent.Parent:FindFirstChild("RepairToolWorldPlacement") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("RepairToolWorldPlacement") then
        return require(serverFolder:FindFirstChild("RepairToolWorldPlacement") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("RepairToolWorldPlacement", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("RepairToolWorldPlacement") :: ModuleScript)
end

local RepairToolWorldPlacement = getRepairToolWorldPlacement()

local function getCarPartPhysicalBuilder(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("CarPartPhysicalBuilder") then
        return require(parent.Parent:FindFirstChild("CarPartPhysicalBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarPartPhysicalBuilder") then
        return require(serverFolder:FindFirstChild("CarPartPhysicalBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("CarPartPhysicalBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("CarPartPhysicalBuilder") :: ModuleScript)
end

local CarPartPhysicalBuilder = getCarPartPhysicalBuilder()

local function getCarPartCollectionSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("CarPartCollectionSystem") then
        return require(parent.Parent:FindFirstChild("CarPartCollectionSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("CarPartCollectionSystem") then
        return require(serverFolder:FindFirstChild("CarPartCollectionSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("CarPartCollectionSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("CarPartCollectionSystem") :: ModuleScript)
end

local CarPartCollectionSystem = getCarPartCollectionSystem()

local function getHotelBatteryObstacleSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("HotelBatteryObstacleSystem") then
        return require(parent.Parent:FindFirstChild("HotelBatteryObstacleSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("HotelBatteryObstacleSystem") then
        return require(serverFolder:FindFirstChild("HotelBatteryObstacleSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("HotelBatteryObstacleSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("HotelBatteryObstacleSystem") :: ModuleScript)
end

local HotelBatteryObstacleSystem = getHotelBatteryObstacleSystem()

local function getMataderoAlternatorObstacleSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("MataderoAlternatorObstacleSystem") then
        return require(parent.Parent:FindFirstChild("MataderoAlternatorObstacleSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("MataderoAlternatorObstacleSystem") then
        return require(serverFolder:FindFirstChild("MataderoAlternatorObstacleSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("MataderoAlternatorObstacleSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("MataderoAlternatorObstacleSystem") :: ModuleScript)
end

local MataderoAlternatorObstacleSystem = getMataderoAlternatorObstacleSystem()

local function getDarsenaSparkPlugsObstacleSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("DarsenaSparkPlugsObstacleSystem") then
        return require(parent.Parent:FindFirstChild("DarsenaSparkPlugsObstacleSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("DarsenaSparkPlugsObstacleSystem") then
        return require(serverFolder:FindFirstChild("DarsenaSparkPlugsObstacleSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("DarsenaSparkPlugsObstacleSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("DarsenaSparkPlugsObstacleSystem") :: ModuleScript)
end

local DarsenaSparkPlugsObstacleSystem = getDarsenaSparkPlugsObstacleSystem()

local function getFuelCanisterTerminalObstacleSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("FuelCanisterTerminalObstacleSystem") then
        return require(parent.Parent:FindFirstChild("FuelCanisterTerminalObstacleSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("FuelCanisterTerminalObstacleSystem") then
        return require(serverFolder:FindFirstChild("FuelCanisterTerminalObstacleSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("FuelCanisterTerminalObstacleSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("FuelCanisterTerminalObstacleSystem") :: ModuleScript)
end

local FuelCanisterTerminalObstacleSystem = getFuelCanisterTerminalObstacleSystem()

local function getRadiatorHoseCorralonObstacleSystem(): any
    local parent = script.Parent
    if parent and parent.Parent and parent.Parent:FindFirstChild("RadiatorHoseCorralonObstacleSystem") then
        return require(parent.Parent:FindFirstChild("RadiatorHoseCorralonObstacleSystem") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("RadiatorHoseCorralonObstacleSystem") then
        return require(serverFolder:FindFirstChild("RadiatorHoseCorralonObstacleSystem") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("RadiatorHoseCorralonObstacleSystem", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("RadiatorHoseCorralonObstacleSystem") :: ModuleScript)
end

local RadiatorHoseCorralonObstacleSystem = getRadiatorHoseCorralonObstacleSystem()

local EpecuenMapGenerator = {}

export type GenerationStats = {
    RoadsCount: number,
    BlocksCount: number,
    ZonesCount: number,
    LandmarksCount: number,
    MarkersCount: number,
    RuinsCount: number,
    EnvironmentDetailsCount: number,
    UrbanBuildingsCount: number?,
    CarPartHideoutsCount: number?,
    RepairToolCount: number?,
    CarPartsCount: number?,
    CarPartCollectionInitialized: boolean?,
    HotelBatteryObstacleInitialized: boolean?,
    MataderoAlternatorObstacleInitialized: boolean?,
    DarsenaSparkPlugsObstacleInitialized: boolean?,
    FuelCanisterTerminalObstacleInitialized: boolean?,
    RadiatorHoseCorralonObstacleInitialized: boolean?,
}

-- ============================================================================
-- REUSABLE HELPER FUNCTIONS
-- ============================================================================

local function toVector3(pos: { X: number, Y: number, Z: number }): Vector3
    return Vector3.new(pos.X, pos.Y, pos.Z)
end

-- 1. CreateRoad: Generates an anchored road segment between two points
function EpecuenMapGenerator.CreateRoad(
    parent: Instance,
    name: string,
    startPos: Vector3,
    endPos: Vector3,
    width: number,
    isPaved: boolean
): Part
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local midpoint = startPos + direction * 0.5

    local roadPart = Instance.new("Part")
    roadPart.Name = name
    roadPart.Anchored = true
    roadPart.CanCollide = true
    roadPart.CastShadow = true
    roadPart.Size = Vector3.new(width, 1.2, distance)
    roadPart.CFrame = CFrame.lookAt(midpoint, endPos)
    
    if isPaved then
        roadPart.Material = Enum.Material.Asphalt
        roadPart.Color = Color3.fromRGB(45, 48, 52)
    else
        roadPart.Material = Enum.Material.Sand
        roadPart.Color = Color3.fromRGB(150, 140, 125) -- Bleached saltern dirt
    end

    roadPart.TopSurface = Enum.SurfaceType.Smooth
    roadPart.BottomSurface = Enum.SurfaceType.Smooth
    roadPart.Parent = parent

    -- Invisible collision shoulder under the northern access road. This is a
    -- safety foundation: if the visible road ever has a physics seam or the
    -- player clips through its edge, the character remains above the town
    -- terrain instead of falling into the void. It follows the same slope as
    -- the road and is slightly wider, but remains completely invisible.
    if name == "RD_NORTH_ACCESS" then
        local safety = Instance.new("Part")
        safety.Name = "RD_NORTH_ACCESS_SafetyCollision"
        safety.Anchored = true
        safety.CanCollide = true
        safety.CanTouch = false
        safety.CanQuery = true
        safety.Transparency = 1
        safety.Size = Vector3.new(width + 8, 5, distance)
        safety.CFrame = roadPart.CFrame * CFrame.new(0, -2.2, 0)
        safety.Material = Enum.Material.SmoothPlastic
        safety.Parent = parent
    end

    -- Side curbs for paved avenues
    if isPaved and width >= 32 then
        local curbOffset = width * 0.5 + 1
        for _, side in ipairs({ -1, 1 }) do
            local curb = Instance.new("Part")
            curb.Name = name .. "_Curb_" .. (side == -1 and "L" or "R")
            curb.Anchored = true
            curb.CanCollide = true
            curb.Size = Vector3.new(1.8, 1.8, distance)
            curb.CFrame = roadPart.CFrame * CFrame.new(curbOffset * side, 0.3, 0)
            curb.Material = Enum.Material.Concrete
            curb.Color = Color3.fromRGB(180, 185, 190)
            curb.Parent = roadPart
        end
    end

    return roadPart
end

-- 2. CreateBlock: Generates an urban block foundation or civic plaza platform
function EpecuenMapGenerator.CreateBlock(
    parent: Instance,
    name: string,
    cf: CFrame,
    size: Vector3,
    material: Enum.Material,
    color: Color3
): Part
    local block = Instance.new("Part")
    block.Name = name
    block.Anchored = true
    block.CanCollide = true
    block.CastShadow = true
    block.Size = size
    block.CFrame = cf
    block.Material = material
    block.Color = color
    block.TopSurface = Enum.SurfaceType.Smooth
    block.BottomSurface = Enum.SurfaceType.Smooth
    block.Parent = parent
    return block
end

-- 3. CreateZone: Generates a non-collidable spatial zone bounding box with label
function EpecuenMapGenerator.CreateZone(
    parent: Instance,
    zoneData: any
): Part
    local min = zoneData.Bounds.Min
    local max = zoneData.Bounds.Max
    local size = Vector3.new(
        math.abs(max.X - min.X),
        math.abs(max.Y - min.Y),
        math.abs(max.Z - min.Z)
    )
    local center = Vector3.new(
        (min.X + max.X) * 0.5,
        (min.Y + max.Y) * 0.5,
        (min.Z + max.Z) * 0.5
    )

    local zonePart = Instance.new("Part")
    zonePart.Name = zoneData.Id
    zonePart.Anchored = true
    zonePart.CanCollide = false
    zonePart.CastShadow = false
    zonePart.Transparency = 0.85
    zonePart.Size = size
    zonePart.CFrame = CFrame.new(center)
    zonePart.Material = Enum.Material.ForceField

    local threatColor = Color3.fromRGB(100, 180, 255)
    if zoneData.ThreatLevel == "High" then
        threatColor = Color3.fromRGB(255, 140, 40)
    elseif zoneData.ThreatLevel == "Deadly" then
        threatColor = Color3.fromRGB(255, 50, 50)
    end
    zonePart.Color = threatColor
    zonePart.Parent = parent

    -- Zone title billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ZoneLabel"
    billboard.Size = UDim2.new(0, 260, 0, 50)
    billboard.StudsOffset = Vector3.new(0, size.Y * 0.5 + 6, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 450
    billboard.Adornee = zonePart
    billboard.Parent = zonePart

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "[" .. zoneData.Name .. "]"
    textLabel.TextColor3 = threatColor
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SpecialElite
    textLabel.Parent = billboard

    return zonePart
end

-- 4. CreateLandmarkMarker: Generates structural placeholder volumes for iconic landmarks
function EpecuenMapGenerator.CreateLandmarkMarker(
    parent: Instance,
    landmarkData: any
): Model
    local model = Instance.new("Model")
    model.Name = landmarkData.Id
    model.Parent = parent

    local basePos = toVector3(landmarkData.Position)
    local footprint = landmarkData.FootprintStuds
    local height = landmarkData.VerticalHeightStuds
    local adorneePart: BasePart? = nil

    if landmarkData.Id == "LMK_HOTEL_MONTE_REAL" then
        -- Detailed architectural landmark generated via LandmarkModelBuilder
        local hotelModel = LandmarkModelBuilder.Build({
            LandmarkType = "HotelMonteReal",
            Position = Vector3.new(400, 10, -200),
            RotationY = 0,
            Parent = model,
            DamageLevel = 0.85,
            SaltLevel = 0.90,
            Seed = 7001,
        })
        if hotelModel and hotelModel.PrimaryPart then
            model.PrimaryPart = hotelModel.PrimaryPart
            adorneePart = hotelModel.PrimaryPart
        end
    elseif landmarkData.Id == "LMK_IGLESIA" then
        -- Detailed architectural church landmark generated via ChurchLandmarkBuilder
        local churchPos = toVector3(landmarkData.Position)
        local churchModel = ChurchLandmarkBuilder.Build({
            Position = churchPos,
            RotationY = 0,
            Parent = model,
            DamageLevel = 0.90,
            SaltLevel = 0.90,
            Seed = 8001,
        })
        if churchModel and churchModel.PrimaryPart then
            model.PrimaryPart = churchModel.PrimaryPart
            adorneePart = churchModel.PrimaryPart
        end
    elseif landmarkData.Id == "LMK_MATADERO" then
        -- Detailed architectural Matadero landmark generated via MataderoLandmarkBuilder
        local mataderoModel = MataderoLandmarkBuilder.Build({
            Position = Vector3.new(650, 15, 480),
            RotationY = 0,
            Parent = model,
            DamageLevel = 0.85,
            SaltLevel = 0.90,
            Seed = 9001,
        })
        if mataderoModel and mataderoModel.PrimaryPart then
            model.PrimaryPart = mataderoModel.PrimaryPart
            adorneePart = mataderoModel.PrimaryPart
        end
    elseif landmarkData.Id == "LMK_PLAZA_MONUMENT" then
        -- Detailed civic landmark generated via PlazaCentralLandmarkBuilder
        local plazaModel = PlazaCentralLandmarkBuilder.Build({
            Position = Vector3.new(65, 11, -140),
            RotationY = 0,
            Parent = model,
            DamageLevel = 0.80,
            SaltLevel = 0.85,
            Seed = 4242,
        })
        if plazaModel and plazaModel.PrimaryPart then
            model.PrimaryPart = plazaModel.PrimaryPart
            adorneePart = plazaModel.PrimaryPart
        end
    elseif landmarkData.Id == "LMK_HOTEL_COLONIA_FERROV"
        or landmarkData.Id == "LMK_HOTEL_COLONIA_FERROVIARIA"
        or landmarkData.Id == "LMK_EX_ESTACION_FERROCARRIL"
        or landmarkData.Id == "LMK_ESTACION_FERROCARRIL"
        or landmarkData.Id == "LMK_ESTACION"
        or (typeof(landmarkData.Id) == "string" and string.find(string.upper(landmarkData.Id), "FERRO") ~= nil) then
        -- Detailed architectural railway station landmark generated via RailwayStationLandmarkBuilder
        local stationPos = toVector3(landmarkData.Position)
        local stationRotY = if landmarkData.RotationY ~= nil then landmarkData.RotationY else 0
        local stationModel = RailwayStationLandmarkBuilder.Build({
            Position = stationPos,
            RotationY = stationRotY,
            Parent = model,
            DamageLevel = 0.85,
            SaltLevel = 0.90,
            Seed = 5151,
        })
        if stationModel and stationModel.PrimaryPart then
            model.PrimaryPart = stationModel.PrimaryPart
            adorneePart = stationModel.PrimaryPart
        end
    else
        -- Main foundation/structure block
        local mainBody = Instance.new("Part")
        mainBody.Name = "MainStructure"
        mainBody.Anchored = true
        mainBody.CanCollide = true
        mainBody.CastShadow = true
        mainBody.Size = Vector3.new(footprint.X, height * 0.5, footprint.Z)
        mainBody.CFrame = CFrame.new(basePos + Vector3.new(0, height * 0.25, 0))
        mainBody.Material = Enum.Material.Concrete
        mainBody.Color = Color3.fromRGB(165, 160, 150) -- Salt-weathered concrete
        mainBody.Parent = model
        model.PrimaryPart = mainBody
        adorneePart = mainBody

        -- Distinctive vertical feature (Tower, Belfry, Canopy, etc.)
        if landmarkData.Id == "LMK_DARSENA_CENTRAL" then
            -- U-shaped pier promenade walls
            local pierWallL = Instance.new("Part")
            pierWallL.Name = "PierArmLeft"
            pierWallL.Anchored = true
            pierWallL.CanCollide = true
            pierWallL.Size = Vector3.new(16, 8, footprint.Z)
            pierWallL.CFrame = CFrame.new(basePos + Vector3.new(-footprint.X * 0.4, 2, 0))
            pierWallL.Material = Enum.Material.Concrete
            pierWallL.Color = Color3.fromRGB(130, 135, 140)
            pierWallL.Parent = model

            local pierWallR = Instance.new("Part")
            pierWallR.Name = "PierArmRight"
            pierWallR.Anchored = true
            pierWallR.CanCollide = true
            pierWallR.Size = Vector3.new(16, 8, footprint.Z)
            pierWallR.CFrame = CFrame.new(basePos + Vector3.new(footprint.X * 0.4, 2, 0))
            pierWallR.Material = Enum.Material.Concrete
            pierWallR.Color = Color3.fromRGB(130, 135, 140)
            pierWallR.Parent = model
        end
    end

    -- Floating landmark billboard label
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LandmarkLabel"
    billboard.Size = UDim2.new(0, 240, 0, 45)
    billboard.StudsOffset = Vector3.new(0, height + 8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.Adornee = adorneePart or model.PrimaryPart
    billboard.Parent = model

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = landmarkData.Name
    text.TextColor3 = Color3.fromRGB(240, 235, 220)
    text.TextScaled = true
    text.Font = Enum.Font.SpecialElite
    text.Parent = billboard

    return model
end

-- 5. CreateWater: Generates deep brine lake slab or shallow flooded area
function EpecuenMapGenerator.CreateWater(
    parent: Instance,
    name: string,
    cf: CFrame,
    size: Vector3,
    isSemiFlooded: boolean
): Part
    local water = Instance.new("Part")
    water.Name = name
    water.Anchored = true
    water.CanCollide = false
    water.CastShadow = false
    water.Size = size
    water.CFrame = cf

    if isSemiFlooded then
        -- Caustic shallow brine puddle/sheet
        water.Transparency = 0.45
        water.Material = Enum.Material.Glass
        water.Color = Color3.fromRGB(35, 55, 60) -- Murky dark greenish-grey brine
    else
        -- Deep lake water volume
        water.Transparency = 0.25
        water.Material = Enum.Material.Glass
        water.Color = Color3.fromRGB(20, 32, 40)
    end

    water.TopSurface = Enum.SurfaceType.Smooth
    water.BottomSurface = Enum.SurfaceType.Smooth
    water.Parent = parent
    return water
end

-- 6. CreateMarker: Generates an indicator/beacon for spawns, items, and POIs
function EpecuenMapGenerator.CreateMarker(
    parent: Instance,
    name: string,
    position: Vector3,
    color: Color3,
    labelText: string,
    radius: number?
): Part
    local marker = Instance.new("Part")
    marker.Name = name
    marker.Shape = Enum.PartType.Cylinder
    marker.Anchored = true
    marker.CanCollide = false
    marker.CastShadow = false
    marker.Size = Vector3.new(1, radius or 12, radius or 12)
    marker.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    marker.Material = Enum.Material.Neon
    marker.Color = color
    marker.Transparency = 0.4
    marker.Parent = parent

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MarkerBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 36)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 350
    billboard.Adornee = marker
    billboard.Parent = marker

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    return marker
end

-- ============================================================================
-- MAIN BUILD ENGINE
-- ============================================================================

function EpecuenMapGenerator.Clear()
    local existing = Workspace:FindFirstChild("EpecuenWorld")
    if existing then
        existing:Destroy()
    end
    if HotelBatteryObstacleSystem and typeof(HotelBatteryObstacleSystem.Clear) == "function" then
        HotelBatteryObstacleSystem.Clear()
    end
    if MataderoAlternatorObstacleSystem and typeof(MataderoAlternatorObstacleSystem.Clear) == "function" then
        MataderoAlternatorObstacleSystem.Clear()
    end
    if DarsenaSparkPlugsObstacleSystem and typeof(DarsenaSparkPlugsObstacleSystem.Clear) == "function" then
        DarsenaSparkPlugsObstacleSystem.Clear()
    end
    if FuelCanisterTerminalObstacleSystem and typeof(FuelCanisterTerminalObstacleSystem.Clear) == "function" then
        FuelCanisterTerminalObstacleSystem.Clear()
    end
    if RadiatorHoseCorralonObstacleSystem and typeof(RadiatorHoseCorralonObstacleSystem.Clear) == "function" then
        RadiatorHoseCorralonObstacleSystem.Clear()
    end
    if RepairToolWorldPlacement and typeof(RepairToolWorldPlacement.Clear) == "function" then
        RepairToolWorldPlacement.Clear()
    end
    if CarPartPhysicalBuilder and typeof(CarPartPhysicalBuilder.ClearAll) == "function" then
        CarPartPhysicalBuilder.ClearAll()
    end
    if CarPartCollectionSystem and typeof(CarPartCollectionSystem.Cleanup) == "function" then
        CarPartCollectionSystem.Cleanup()
    end
end

function EpecuenMapGenerator.Generate(): GenerationStats
    -- Idempotency check: Remove existing generated folder
    EpecuenMapGenerator.Clear()

    local root = Instance.new("Folder")
    root.Name = "EpecuenWorld"
    root.Parent = Workspace

    local folderRoads = Instance.new("Folder")
    folderRoads.Name = "Roads"
    folderRoads.Parent = root

    local folderBlocks = Instance.new("Folder")
    folderBlocks.Name = "Blocks"
    folderBlocks.Parent = root

    local folderWater = Instance.new("Folder")
    folderWater.Name = "Water"
    folderWater.Parent = root

    local folderZones = Instance.new("Folder")
    folderZones.Name = "Zones"
    folderZones.Parent = root

    local folderLandmarks = Instance.new("Folder")
    folderLandmarks.Name = "Landmarks"
    folderLandmarks.Parent = root

    local folderMarkers = Instance.new("Folder")
    folderMarkers.Name = "Markers"
    folderMarkers.Parent = root

    local folderRuins = Instance.new("Folder")
    folderRuins.Name = "Ruins"
    folderRuins.Parent = root

    local folderEnvironment = Instance.new("Folder")
    folderEnvironment.Name = "EnvironmentDetails"
    folderEnvironment.Parent = root

    local folderUrbanBuildings = Instance.new("Folder")
    folderUrbanBuildings.Name = "UrbanBuildings"
    folderUrbanBuildings.Parent = root

    local folderCarPartHideouts = Instance.new("Folder")
    folderCarPartHideouts.Name = "CarPartHideouts"
    folderCarPartHideouts.Parent = root

    local roadsCount = 0
    local blocksCount = 0
    local zonesCount = 0
    local landmarksCount = 0
    local markersCount = 0
    local ruinsCount = 0
    local environmentDetailsCount = 0
    local urbanBuildingsCount = 0
    local carPartHideoutsCount = 0

    -- ------------------------------------------------------------------------
    -- 1. BASE TERRAIN FOUNDATION & WORLD BOUNDARIES
    -- ------------------------------------------------------------------------
    local bounds = EpecuenMapSpecification.WorldBounds

    -- Dry town terrain foundation (ends at Z=490, top surface at Y=0)
    -- Extends from Z=-950 to Z=490 (Length: 1440, Center Z: -230)
    local _townTerrain = EpecuenMapGenerator.CreateBlock(
        folderBlocks,
        "TownTerrainFoundation",
        CFrame.new(bounds.Center.X, -2, -230),
        Vector3.new(bounds.TotalWidthStuds, 4, 1440),
        Enum.Material.Ground,
        Color3.fromRGB(115, 110, 95) -- Dried pampas earth with salt dust
    )
    blocksCount += 1

    -- Submerged lakebed foundation (recessed from Z=490 to Z=1100 at approximately Y=-8)
    -- Extends from Z=490 to Z=1100 (Length: 610, Center Z: 795, Center Y: -10, top surface at Y=-8)
    local _lakebedTerrain = EpecuenMapGenerator.CreateBlock(
        folderBlocks,
        "LagoonLakebedFoundation",
        CFrame.new(bounds.Center.X, -10, 795),
        Vector3.new(bounds.TotalWidthStuds, 4, 610),
        Enum.Material.Ground,
        Color3.fromRGB(75, 80, 75) -- Submerged saline silt and calcified mud
    )
    blocksCount += 1

    -- Peripheral pampas perimeter walls (Boundary indicators)
    local halfW = bounds.TotalWidthStuds * 0.5
    local wallThickness = 12
    local wallHeight = 40
    local perimeterSegments = {
        { Name = "Boundary_North", Pos = Vector3.new(bounds.Center.X, 15, -950), Size = Vector3.new(bounds.TotalWidthStuds, wallHeight, wallThickness) },
        { Name = "Boundary_South", Pos = Vector3.new(bounds.Center.X, 15, 1100), Size = Vector3.new(bounds.TotalWidthStuds, wallHeight, wallThickness) },
        { Name = "Boundary_West", Pos = Vector3.new(bounds.Center.X - halfW, 15, 75), Size = Vector3.new(wallThickness, wallHeight, bounds.TotalLengthStuds) },
        { Name = "Boundary_East", Pos = Vector3.new(bounds.Center.X + halfW, 15, 75), Size = Vector3.new(wallThickness, wallHeight, bounds.TotalLengthStuds) },
    }
    for _, seg in ipairs(perimeterSegments) do
        local pWall = Instance.new("Part")
        pWall.Name = seg.Name
        pWall.Anchored = true
        pWall.CanCollide = true
        pWall.Transparency = 1 -- Invisible boundary wall keeping players within the explorable world
        pWall.Size = seg.Size
        pWall.CFrame = CFrame.new(seg.Pos)
        pWall.Parent = folderBlocks
    end

    -- ------------------------------------------------------------------------
    -- 2. STREETS AND AVENUES (16 roads defined in EpecuenMapSpecification)
    -- ------------------------------------------------------------------------
    for _, street in ipairs(EpecuenMapSpecification.Streets) do
        local startPos = toVector3(street.StartPos)
        local endPos = toVector3(street.EndPos)
        EpecuenMapGenerator.CreateRoad(
            folderRoads,
            street.Id,
            startPos,
            endPos,
            street.WidthStuds,
            street.IsPaved
        )
        roadsCount += 1
    end

    -- ------------------------------------------------------------------------
    -- 3. ROAD INTERSECTIONS
    -- ------------------------------------------------------------------------
    for _, inter in ipairs(EpecuenMapSpecification.Intersections) do
        local pos = toVector3(inter.Position)
        local interPart = Instance.new("Part")
        interPart.Name = inter.Id
        interPart.Anchored = true
        interPart.CanCollide = true
        interPart.Size = Vector3.new(44, 1.4, 44)
        interPart.CFrame = CFrame.new(pos)
        interPart.Material = inter.IsPavedCrossroad and Enum.Material.Asphalt or Enum.Material.Sand
        interPart.Color = inter.IsPavedCrossroad and Color3.fromRGB(42, 45, 48) or Color3.fromRGB(155, 145, 130)
        interPart.Parent = folderRoads

        -- Intersection tactical indicator
        EpecuenMapGenerator.CreateMarker(
            folderMarkers,
            "Marker_" .. inter.Id,
            pos + Vector3.new(0, 1.2, 0),
            inter.IsPavedCrossroad and Color3.fromRGB(180, 190, 205) or Color3.fromRGB(160, 150, 130),
            inter.Id,
            8
        )
        markersCount += 1
    end

    -- ------------------------------------------------------------------------
    -- 4. URBAN BLOCKS (Manzanas) AND PLAZA CENTRAL
    -- ------------------------------------------------------------------------
    -- 7 Columns (West to East) and 6 Rows (North to South)
    local colBounds = {
        { MinX = -320, MaxX = -160, Name = "Col1_Talcahuano_Mayo" },
        { MinX = -160, MaxX = 0,    Name = "Col2_Mayo_Cerrito" },
        { MinX = 0,    MaxX = 150,  Name = "Col3_Cerrito_Pellegrini" },
        { MinX = 150,  MaxX = 300,  Name = "Col4_Pellegrini_Suipacha" },
        { MinX = 300,  MaxX = 450,  Name = "Col5_Suipacha_Esmeralda" },
        { MinX = 450,  MaxX = 600,  Name = "Col6_Esmeralda_Maipu" },
        { MinX = 600,  MaxX = 750,  Name = "Col7_Maipu_Florida" },
    }

    local rowBounds = {
        { MinZ = -700, MaxZ = -450, Y = 16, Name = "Row1_North_Sarmiento" },
        { MinZ = -450, MaxZ = -250, Y = 13, Name = "Row2_Sarmiento_Cangallo" },
        { MinZ = -250, MaxZ = 0,    Y = 10, Name = "Row3_Cangallo_Mitre" },
        { MinZ = 0,    MaxZ = 200,  Y = 7,  Name = "Row4_Mitre_Rivadavia" },
        { MinZ = 200,  MaxZ = 380,  Y = 5,  Name = "Row5_Rivadavia_Victoria" },
        { MinZ = 380,  MaxZ = 490,  Y = 2,  Name = "Row6_Victoria_Alsina" },
    }

    for cIdx, col in ipairs(colBounds) do
        for rIdx, row in ipairs(rowBounds) do
            -- Check if this cell is the Plaza Central
            local isPlazaCell = (col.MinX == 0 and col.MaxX == 150 and row.MinZ == -250 and row.MaxZ == 0)
            local blockName = string.format("Manzana_C%d_R%d_%s", cIdx, rIdx, col.Name)

            local paddingX = 18
            local paddingZ = 18
            local width = math.abs(col.MaxX - col.MinX) - paddingX * 2
            local length = math.abs(row.MaxZ - row.MinZ) - paddingZ * 2
            local centerX = (col.MinX + col.MaxX) * 0.5
            local centerZ = (row.MinZ + row.MaxZ) * 0.5

            if isPlazaCell then
                -- Plaza Central is constructed exclusively via PlazaCentralLandmarkBuilder within
                -- the LMK_PLAZA_MONUMENT container to prevent duplicate primitive foundation/fountain geometry.
            else
                -- Standard urban block foundation (raised sidewalk with rubble interior)
                local urbanBlock = EpecuenMapGenerator.CreateBlock(
                    folderBlocks,
                    blockName,
                    CFrame.new(centerX, row.Y, centerZ),
                    Vector3.new(width, 1.8, length),
                    Enum.Material.Concrete,
                    Color3.fromRGB(130, 125, 115) -- Salt-stained cracked concrete
                )
                blocksCount += 1

                -- Inner foundation rubble slab
                local rubble = Instance.new("Part")
                rubble.Name = "InnerRubble"
                rubble.Anchored = true
                rubble.CanCollide = true
                rubble.Size = Vector3.new(width - 8, 1.4, length - 8)
                rubble.CFrame = CFrame.new(centerX, row.Y + 0.6, centerZ)
                rubble.Material = Enum.Material.Slate
                rubble.Color = Color3.fromRGB(110, 105, 95)
                rubble.Parent = urbanBlock
            end
        end
    end

    -- Western Radial Park geometric blocks (4 grand circular/diagonal sectors)
    local radialSectors = {
        { Name = "RadialPark_NW", Center = Vector3.new(-580, 12, -350), Radius = 120 },
        { Name = "RadialPark_SW", Center = Vector3.new(-580, 7, -100),  Radius = 130 },
        { Name = "RadialPark_FarW", Center = Vector3.new(-750, 9, -200), Radius = 100 },
        { Name = "RadialPark_South", Center = Vector3.new(-500, 5, 200), Radius = 110 },
    }
    for _, sector in ipairs(radialSectors) do
        local rBlock = Instance.new("Part")
        rBlock.Name = sector.Name
        rBlock.Shape = Enum.PartType.Cylinder
        rBlock.Anchored = true
        rBlock.CanCollide = true
        rBlock.Size = Vector3.new(2, sector.Radius * 2, sector.Radius * 2)
        rBlock.CFrame = CFrame.new(sector.Center) * CFrame.Angles(0, 0, math.rad(90))
        rBlock.Material = Enum.Material.Ground
        rBlock.Color = Color3.fromRGB(135, 130, 115)
        rBlock.Parent = folderBlocks
        blocksCount += 1
    end

    -- Coastal promenade block (Costanera boardwalk base along Z=490 shoreline)
    local costaneraPromenade = EpecuenMapGenerator.CreateBlock(
        folderBlocks,
        "Costanera_Promenade_Base",
        CFrame.new(0, 1, 490),
        Vector3.new(1400, 1.6, 28),
        Enum.Material.Concrete,
        Color3.fromRGB(170, 175, 180)
    )
    blocksCount += 1

    -- ------------------------------------------------------------------------
    -- 5. LAGOON WATER, SHORELINE & SEMI-FLOODED SHALLOWS
    -- ------------------------------------------------------------------------
    -- Deep water of Laguna Epecuén (Southern basin spanning Z=490 to Z=1100; surface at Y=0, lakebed at Y=-8)
    local deepWater = EpecuenMapGenerator.CreateWater(
        folderWater,
        "LagunaEpecuen_DeepBrine",
        CFrame.new(bounds.Center.X, -4, 795),
        Vector3.new(bounds.TotalWidthStuds, 8, 610),
        false
    )

    -- Semi-flooded shallow water sheet 1: Foot of Av. de Mayo & Pier Base
    local shallowWaterMayo = EpecuenMapGenerator.CreateWater(
        folderWater,
        "SemiFlooded_MayoPromenade",
        CFrame.new(-160, 0.4, 560),
        Vector3.new(180, 1.2, 140),
        true
    )

    -- Semi-flooded shallow water sheet 2: Eastern littoral curve (Calle Florida bay)
    local shallowWaterEast = EpecuenMapGenerator.CreateWater(
        folderWater,
        "SemiFlooded_EasternLittoralCurve",
        CFrame.new(650, 0.8, 380),
        Vector3.new(380, 1.2, 280),
        true
    )

    -- Semi-flooded shallow water sheet 3: Southwestern marshland
    local shallowWaterWest = EpecuenMapGenerator.CreateWater(
        folderWater,
        "SemiFlooded_SouthwestMarsh",
        CFrame.new(-550, 0.5, 420),
        Vector3.new(400, 1.2, 200),
        true
    )

    -- ------------------------------------------------------------------------
    -- 6. ZONES (10 Geographic zones from EpecuenMapSpecification)
    -- ------------------------------------------------------------------------
    for _, zone in ipairs(EpecuenMapSpecification.Zones) do
        EpecuenMapGenerator.CreateZone(folderZones, zone)
        zonesCount += 1
    end

    -- ------------------------------------------------------------------------
    -- 7. LANDMARKS (11 Landmarks including Matadero, Monte Real, Iglesia, etc.)
    -- ------------------------------------------------------------------------
    for _, landmark in ipairs(EpecuenMapSpecification.Landmarks) do
        EpecuenMapGenerator.CreateLandmarkMarker(folderLandmarks, landmark)
        landmarksCount += 1
    end

    -- ------------------------------------------------------------------------
    -- 8. MARKERS (Spawn, Vehicle, 5 Car Parts, and POIs)
    -- ------------------------------------------------------------------------
    -- 8.1 Player Spawn Marker
    local pSpawn = EpecuenMapSpecification.PlayerSpawn
    local spawnMarker = EpecuenMapGenerator.CreateMarker(
        folderMarkers,
        "Spawn_" .. pSpawn.Id,
        toVector3(pSpawn.Position) + Vector3.new(0, 0.5, 0),
        Color3.fromRGB(80, 255, 120),
        "PUNTO DE INICIO (PLAYER SPAWN)",
        14
    )
    markersCount += 1

    -- 8.2 Fiat Cronos Marker
    local fCronos = EpecuenMapSpecification.FiatCronos
    local cronosMarker = EpecuenMapGenerator.CreateMarker(
        folderMarkers,
        "Vehicle_FiatCronos",
        toVector3(fCronos.Position) + Vector3.new(0, 0.5, 0),
        Color3.fromRGB(255, 215, 0),
        "OBJETIVO: FIAT CRONOS",
        18
    )
    -- Procedural Fiat Cronos 3D Model
    VehicleModelBuilder.Build({
        Position = toVector3(fCronos.Position),
        OrientationY = fCronos.RotationY,
        Parent = cronosMarker,
        IsDamaged = true,
    })
    markersCount += 1

    -- 8.3 Five Car-Part Search Zone Markers
    for _, partZone in ipairs(EpecuenMapSpecification.CarPartSearchZones) do
        local partPos = toVector3(partZone.ApproximatePosition)
        EpecuenMapGenerator.CreateMarker(
            folderMarkers,
            "CarPart_" .. partZone.PartType,
            partPos + Vector3.new(0, 0.6, 0),
            Color3.fromRGB(255, 70, 70),
            "REPUESTO: " .. partZone.ItemName,
            partZone.SearchRadiusStuds * 0.4
        )
        markersCount += 1
    end

    -- 8.4 Points of Interest Markers
    for _, poi in ipairs(EpecuenMapSpecification.PointsOfInterest) do
        local poiPos = toVector3(poi.Position)
        EpecuenMapGenerator.CreateMarker(
            folderMarkers,
            "POI_" .. poi.Id,
            poiPos + Vector3.new(0, 0.5, 0),
            Color3.fromRGB(100, 200, 255),
            poi.Name,
            10
        )
        markersCount += 1
    end

    -- ------------------------------------------------------------------------
    -- 9. VISUAL TEST: RUINS ALONG NORTH AVENIDA DE MAYO
    --    (Between Fiat Cronos [Z = -755] and Plaza Central [Z = -250])
    --    Total: 14 ruins (6 HouseSmall, 3 HouseMedium, 2 ShopRuins, 2 WallRuins, 1 HotelRuins)
    -- ------------------------------------------------------------------------
    local visualTestRuins = {
        -- WEST FLANK (Col 1: Between Av. de Mayo [X = -160] and Talcahuano [X = -320])
        -- Row 1: North of Sarmiento (Z = -700 to -450, Y = 17.0)
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_W1",
            Position = Vector3.new(-204, 17.0, -615),
            OrientationY = 90, -- Faces East toward Av. de Mayo
            DamageLevel = 0.45,
            SaltCrustLevel = 0.35,
            Seed = 101,
        },
        {
            Type = "WallRuins",
            Name = "Ruin_Wall_W1",
            Position = Vector3.new(-198, 17.0, -582),
            OrientationY = 90,
            DamageLevel = 0.65,
            SaltCrustLevel = 0.40,
            Seed = 102,
        },
        {
            Type = "HouseMedium",
            Name = "Ruin_HouseMedium_W1",
            Position = Vector3.new(-208, 17.0, -542),
            OrientationY = 90,
            DamageLevel = 0.55,
            SaltCrustLevel = 0.30,
            Seed = 103,
        },
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_W2",
            Position = Vector3.new(-204, 17.0, -500),
            OrientationY = 90,
            DamageLevel = 0.70,
            SaltCrustLevel = 0.45,
            Seed = 104,
        },

        -- EAST FLANK (Col 2: Between Av. de Mayo [X = -160] and Cerrito [X = 0])
        -- Row 1: North of Sarmiento (Z = -700 to -450, Y = 17.0)
        {
            Type = "ShopRuins",
            Name = "Ruin_Shop_E1",
            Position = Vector3.new(-114, 17.0, -615),
            OrientationY = -90, -- Faces West toward Av. de Mayo
            DamageLevel = 0.50,
            SaltCrustLevel = 0.30,
            Seed = 105,
        },
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_E1",
            Position = Vector3.new(-116, 17.0, -565),
            OrientationY = -90,
            DamageLevel = 0.60,
            SaltCrustLevel = 0.40,
            Seed = 106,
        },
        {
            Type = "HouseMedium",
            Name = "Ruin_HouseMedium_E1",
            Position = Vector3.new(-112, 17.0, -515),
            OrientationY = -90,
            DamageLevel = 0.40,
            SaltCrustLevel = 0.35,
            Seed = 107,
        },

        -- WEST FLANK (Col 1: Between Av. de Mayo [X = -160] and Talcahuano [X = -320])
        -- Row 2: Between Sarmiento [Z = -450] and Cangallo [Z = -250], Y = 14.0
        {
            Type = "HotelRuins",
            Name = "Ruin_Hotel_W1",
            Position = Vector3.new(-215, 14.0, -385),
            OrientationY = 90, -- Faces East toward Av. de Mayo
            DamageLevel = 0.60,
            SaltCrustLevel = 0.50,
            Seed = 108,
        },
        {
            Type = "WallRuins",
            Name = "Ruin_Wall_W2",
            Position = Vector3.new(-198, 14.0, -340),
            OrientationY = 90,
            DamageLevel = 0.70,
            SaltCrustLevel = 0.55,
            Seed = 109,
        },
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_W3",
            Position = Vector3.new(-204, 14.0, -305),
            OrientationY = 90,
            DamageLevel = 0.65,
            SaltCrustLevel = 0.45,
            Seed = 110,
        },

        -- EAST FLANK (Col 2: Between Av. de Mayo [X = -160] and Cerrito [X = 0])
        -- Row 2: Between Sarmiento [Z = -450] and Cangallo [Z = -250], Y = 14.0
        {
            Type = "ShopRuins",
            Name = "Ruin_Shop_E2",
            Position = Vector3.new(-114, 14.0, -400),
            OrientationY = -90, -- Faces West toward Av. de Mayo
            DamageLevel = 0.55,
            SaltCrustLevel = 0.40,
            Seed = 111,
        },
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_E2",
            Position = Vector3.new(-116, 14.0, -360),
            OrientationY = -90,
            DamageLevel = 0.50,
            SaltCrustLevel = 0.45,
            Seed = 112,
        },
        {
            Type = "HouseMedium",
            Name = "Ruin_HouseMedium_E2",
            Position = Vector3.new(-112, 14.0, -320),
            OrientationY = -90,
            DamageLevel = 0.65,
            SaltCrustLevel = 0.40,
            Seed = 113,
        },
        {
            Type = "HouseSmall",
            Name = "Ruin_HouseSmall_E3",
            Position = Vector3.new(-116, 14.0, -282),
            OrientationY = -90,
            DamageLevel = 0.75,
            SaltCrustLevel = 0.50,
            Seed = 114,
        },
    }

    for _, rData in ipairs(visualTestRuins) do
        local ruinModel = RuinModelBuilder.Build({
            BuildingType = rData.Type :: any,
            Position = rData.Position,
            OrientationY = rData.OrientationY,
            DamageLevel = rData.DamageLevel,
            SaltCrustLevel = rData.SaltCrustLevel,
            RandomSeed = rData.Seed,
            Parent = folderRuins,
        })
        if ruinModel then
            ruinModel.Name = rData.Name
            ruinsCount += 1
        end
    end

    -- ------------------------------------------------------------------------
    -- 10. VISUAL TEST: ENVIRONMENTAL DETAILS AROUND AVENIDA DE MAYO CORRIDOR
    --     (Between Fiat Cronos [Z = -755] and Plaza Central [Z = -250])
    --     Counts: PetrifiedTree: 12, SaltCrust: 18, RubblePile: 16,
    --             RustedMetal: 8, DeadVegetation: 12 (Total: 66)
    -- ------------------------------------------------------------------------
    local visualTestEnvironment = {
        -- --------------------------------------------------------------------
        -- PETRIFIED TREES (12 total: 6 West flank, 6 East flank)
        -- --------------------------------------------------------------------
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W1",
            Position = Vector3.new(-190, 17.0, -628),
            RotationY = 15,
            Scale = 1.0,
            Seed = 1001,
            Height = 22,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W2",
            Position = Vector3.new(-224, 17.0, -598),
            RotationY = 45,
            Scale = 0.95,
            Seed = 1002,
            Height = 18,
            BrokenTrunk = true,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W3",
            Position = Vector3.new(-190, 17.0, -562),
            RotationY = 120,
            Scale = 1.0,
            Seed = 1003,
            Height = 20,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W4",
            Position = Vector3.new(-226, 17.0, -520),
            RotationY = 70,
            Scale = 1.05,
            Seed = 1004,
            Height = 24,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W5",
            Position = Vector3.new(-191, 14.0, -418),
            RotationY = 200,
            Scale = 0.9,
            Seed = 1005,
            Height = 17,
            BrokenTrunk = true,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_W6",
            Position = Vector3.new(-228, 14.0, -322),
            RotationY = 310,
            Scale = 1.0,
            Seed = 1006,
            Height = 21,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E1",
            Position = Vector3.new(-130, 17.0, -628),
            RotationY = 80,
            Scale = 0.95,
            Seed = 1007,
            Height = 19,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E2",
            Position = Vector3.new(-96, 17.0, -590),
            RotationY = 160,
            Scale = 1.05,
            Seed = 1008,
            Height = 23,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E3",
            Position = Vector3.new(-130, 17.0, -540),
            RotationY = 250,
            Scale = 0.85,
            Seed = 1009,
            Height = 16,
            BrokenTrunk = true,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E4",
            Position = Vector3.new(-94, 17.0, -495),
            RotationY = 35,
            Scale = 1.0,
            Seed = 1010,
            Height = 21,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E5",
            Position = Vector3.new(-130, 14.0, -380),
            RotationY = 145,
            Scale = 1.1,
            Seed = 1011,
            Height = 25,
            BrokenTrunk = false,
        },
        {
            Type = "PetrifiedTree",
            Name = "Env_Tree_E6",
            Position = Vector3.new(-98, 14.0, -300),
            RotationY = 225,
            Scale = 0.95,
            Seed = 1012,
            Height = 18,
            BrokenTrunk = true,
        },

        -- --------------------------------------------------------------------
        -- SALT CRUST FORMATIONS (18 total: 9 West flank, 9 East flank)
        -- --------------------------------------------------------------------
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W1",
            Position = Vector3.new(-204, 17.0, -630),
            Radius = 4.5,
            Scale = 1.0,
            Seed = 2001,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W2",
            Position = Vector3.new(-188, 17.0, -605),
            Radius = 3.5,
            Scale = 0.9,
            Seed = 2002,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W3",
            Position = Vector3.new(-212, 17.0, -580),
            Radius = 5.0,
            Scale = 1.0,
            Seed = 2003,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W4",
            Position = Vector3.new(-220, 17.0, -555),
            Radius = 4.0,
            Scale = 1.0,
            Seed = 2004,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W5",
            Position = Vector3.new(-189, 17.0, -525),
            Radius = 3.8,
            Scale = 0.9,
            Seed = 2005,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W6",
            Position = Vector3.new(-218, 14.0, -402),
            Radius = 6.0,
            Scale = 1.1,
            Seed = 2006,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W7",
            Position = Vector3.new(-200, 14.0, -365),
            Radius = 4.5,
            Scale = 1.0,
            Seed = 2007,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W8",
            Position = Vector3.new(-215, 14.0, -338),
            Radius = 4.0,
            Scale = 0.9,
            Seed = 2008,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_W9",
            Position = Vector3.new(-189, 14.0, -290),
            Radius = 3.5,
            Scale = 0.9,
            Seed = 2009,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E1",
            Position = Vector3.new(-114, 17.0, -630),
            Radius = 4.2,
            Scale = 1.0,
            Seed = 2010,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E2",
            Position = Vector3.new(-131, 17.0, -590),
            Radius = 3.6,
            Scale = 0.9,
            Seed = 2011,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E3",
            Position = Vector3.new(-102, 17.0, -565),
            Radius = 4.5,
            Scale = 1.0,
            Seed = 2012,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E4",
            Position = Vector3.new(-124, 17.0, -530),
            Radius = 4.0,
            Scale = 0.9,
            Seed = 2013,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E5",
            Position = Vector3.new(-100, 17.0, -500),
            Radius = 5.0,
            Scale = 1.0,
            Seed = 2014,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E6",
            Position = Vector3.new(-131, 14.0, -415),
            Radius = 3.8,
            Scale = 0.9,
            Seed = 2015,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E7",
            Position = Vector3.new(-104, 14.0, -360),
            Radius = 4.5,
            Scale = 1.0,
            Seed = 2016,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E8",
            Position = Vector3.new(-131, 14.0, -340),
            Radius = 3.5,
            Scale = 0.9,
            Seed = 2017,
        },
        {
            Type = "SaltCrust",
            Name = "Env_Salt_E9",
            Position = Vector3.new(-104, 14.0, -278),
            Radius = 4.2,
            Scale = 1.0,
            Seed = 2018,
        },

        -- --------------------------------------------------------------------
        -- RUBBLE PILES (16 total: 8 West flank, 8 East flank)
        -- --------------------------------------------------------------------
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W1",
            Position = Vector3.new(-212, 17.0, -622),
            Radius = 3.2,
            Scale = 0.9,
            Seed = 3001,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W2",
            Position = Vector3.new(-196, 17.0, -572),
            Radius = 3.5,
            Scale = 1.0,
            Seed = 3002,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W3",
            Position = Vector3.new(-220, 17.0, -548),
            Radius = 4.0,
            Scale = 1.1,
            Seed = 3003,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W4",
            Position = Vector3.new(-198, 17.0, -512),
            Radius = 3.0,
            Scale = 0.9,
            Seed = 3004,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W5",
            Position = Vector3.new(-210, 17.0, -490),
            Radius = 3.4,
            Scale = 1.0,
            Seed = 3005,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W6",
            Position = Vector3.new(-228, 14.0, -392),
            Radius = 4.8,
            Scale = 1.2,
            Seed = 3006,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W7",
            Position = Vector3.new(-196, 14.0, -332),
            Radius = 3.2,
            Scale = 0.9,
            Seed = 3007,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_W8",
            Position = Vector3.new(-212, 14.0, -298),
            Radius = 3.5,
            Scale = 1.0,
            Seed = 3008,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E1",
            Position = Vector3.new(-104, 17.0, -622),
            Radius = 3.6,
            Scale = 1.0,
            Seed = 3009,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E2",
            Position = Vector3.new(-124, 17.0, -574),
            Radius = 3.0,
            Scale = 0.85,
            Seed = 3010,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E3",
            Position = Vector3.new(-104, 17.0, -556),
            Radius = 3.4,
            Scale = 0.95,
            Seed = 3011,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E4",
            Position = Vector3.new(-122, 17.0, -506),
            Radius = 3.2,
            Scale = 0.9,
            Seed = 3012,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E5",
            Position = Vector3.new(-104, 14.0, -408),
            Radius = 3.5,
            Scale = 1.0,
            Seed = 3013,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E6",
            Position = Vector3.new(-124, 14.0, -370),
            Radius = 3.0,
            Scale = 0.85,
            Seed = 3014,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E7",
            Position = Vector3.new(-102, 14.0, -314),
            Radius = 3.8,
            Scale = 1.05,
            Seed = 3015,
        },
        {
            Type = "RubblePile",
            Name = "Env_Rubble_E8",
            Position = Vector3.new(-124, 14.0, -274),
            Radius = 3.2,
            Scale = 0.9,
            Seed = 3016,
        },

        -- --------------------------------------------------------------------
        -- RUSTED METAL DEBRIS (8 total: 4 West flank, 4 East flank)
        -- --------------------------------------------------------------------
        {
            Type = "RustedMetal",
            Name = "Env_Metal_W1",
            Position = Vector3.new(-220, 17.0, -608),
            Variant = "SheetMetal",
            Scale = 1.0,
            Seed = 4001,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_W2",
            Position = Vector3.new(-192, 17.0, -532),
            Variant = "BrokenPipe",
            Scale = 1.0,
            Seed = 4002,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_W3",
            Position = Vector3.new(-224, 14.0, -376),
            Variant = "RustedFrame",
            Scale = 1.0,
            Seed = 4003,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_W4",
            Position = Vector3.new(-192, 14.0, -312),
            Variant = "SheetMetal",
            Scale = 0.9,
            Seed = 4004,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_E1",
            Position = Vector3.new(-106, 17.0, -606),
            Variant = "SheetMetal",
            Scale = 1.0,
            Seed = 4005,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_E2",
            Position = Vector3.new(-128, 17.0, -522),
            Variant = "BrokenPipe",
            Scale = 1.0,
            Seed = 4006,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_E3",
            Position = Vector3.new(-106, 14.0, -392),
            Variant = "RustedFrame",
            Scale = 1.0,
            Seed = 4007,
        },
        {
            Type = "RustedMetal",
            Name = "Env_Metal_E4",
            Position = Vector3.new(-128, 14.0, -308),
            Variant = "SheetMetal",
            Scale = 0.95,
            Seed = 4008,
        },

        -- --------------------------------------------------------------------
        -- DEAD VEGETATION CLUSTERS (12 total: 6 West flank, 6 East flank)
        -- --------------------------------------------------------------------
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W1",
            Position = Vector3.new(-191, 17.0, -638),
            Scale = 0.95,
            Seed = 5001,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W2",
            Position = Vector3.new(-222, 17.0, -588),
            Scale = 1.05,
            Seed = 5002,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W3",
            Position = Vector3.new(-191, 17.0, -492),
            Scale = 0.90,
            Seed = 5003,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W4",
            Position = Vector3.new(-226, 14.0, -408),
            Scale = 1.10,
            Seed = 5004,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W5",
            Position = Vector3.new(-191, 14.0, -350),
            Scale = 0.95,
            Seed = 5005,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_W6",
            Position = Vector3.new(-222, 14.0, -288),
            Scale = 1.00,
            Seed = 5006,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E1",
            Position = Vector3.new(-129, 17.0, -638),
            Scale = 0.90,
            Seed = 5007,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E2",
            Position = Vector3.new(-94, 17.0, -580),
            Scale = 1.05,
            Seed = 5008,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E3",
            Position = Vector3.new(-129, 17.0, -490),
            Scale = 0.95,
            Seed = 5009,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E4",
            Position = Vector3.new(-96, 14.0, -418),
            Scale = 1.00,
            Seed = 5010,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E5",
            Position = Vector3.new(-129, 14.0, -350),
            Scale = 0.90,
            Seed = 5011,
        },
        {
            Type = "DeadVegetation",
            Name = "Env_DeadVeg_E6",
            Position = Vector3.new(-96, 14.0, -270),
            Scale = 1.05,
            Seed = 5012,
        },
    }

    for _, eData in ipairs(visualTestEnvironment) do
        local envModel = EpecuenEnvironmentBuilder.Build({
            ElementType = eData.Type :: any,
            Name = eData.Name,
            Position = eData.Position,
            RotationY = eData.RotationY or 0,
            Scale = eData.Scale or 1.0,
            Seed = eData.Seed,
            Variant = eData.Variant,
            Height = eData.Height,
            Radius = eData.Radius,
            BrokenTrunk = eData.BrokenTrunk,
            Parent = folderEnvironment,
        })
        if envModel then
            environmentDetailsCount += 1
        end
    end

    -- ------------------------------------------------------------------------
    -- 11. VISUAL TEST: PROCEDURAL URBAN BUILDINGS ALONG CENTRAL AVENIDA DE MAYO
    --     (Between Calle Cangallo [Z = -250] and Calle Mitre [Z = 0])
    --     Away from Player Spawn, Fiat Cronos, Plaza Central, Hotel Monte Real,
    --     Church, Matadero, Cemetery and Lagoon.
    --     Total: 12 buildings
    --       - 4 HouseSmall
    --       - 3 HouseMedium
    --       - 2 ShopRuins
    --       - 1 SmallHotel
    --       - 1 FacadeRuins
    --       - 1 WallRuins
    -- ------------------------------------------------------------------------
    local urbanTestBuildings = {
        -- WEST FLANK (Col 1: Between Av. de Mayo [X = -160] and Talcahuano [X = -320])
        -- Row 3: Between Cangallo [Z = -250] and Mitre [Z = 0], Base Y = 11.0
        -- RotationY = 90 (Facing East toward Avenida de Mayo)
        {
            Type = "ShopRuins",
            Name = "Urban_ShopRuins_W1",
            Position = Vector3.new(-202.0, 11.0, -213.75),
            RotationY = 90,
            DamageLevel = 0.50,
            SaltLevel = 0.35,
            Seed = 201,
        },
        {
            Type = "HouseSmall",
            Name = "Urban_HouseSmall_W1",
            Position = Vector3.new(-199.0, 11.0, -182.50),
            RotationY = 90,
            DamageLevel = 0.60,
            SaltLevel = 0.40,
            Seed = 202,
        },
        {
            Type = "HouseMedium",
            Name = "Urban_HouseMedium_W1",
            Position = Vector3.new(-209.0, 11.0, -148.50),
            RotationY = 90,
            DamageLevel = 0.45,
            SaltLevel = 0.30,
            Seed = 203,
        },
        {
            Type = "SmallHotel",
            Name = "Urban_SmallHotel_W1",
            Position = Vector3.new(-210.0, 11.0, -103.50),
            RotationY = 90,
            DamageLevel = 0.55,
            SaltLevel = 0.45,
            Seed = 204,
        },
        {
            Type = "FacadeRuins",
            Name = "Urban_FacadeRuins_W1",
            Position = Vector3.new(-192.0, 11.0, -62.50),
            RotationY = 90,
            DamageLevel = 0.70,
            SaltLevel = 0.50,
            Seed = 205,
        },
        {
            Type = "HouseSmall",
            Name = "Urban_HouseSmall_W2",
            Position = Vector3.new(-199.0, 11.0, -34.50),
            RotationY = 90,
            DamageLevel = 0.65,
            SaltLevel = 0.35,
            Seed = 206,
        },

        -- EAST FLANK (Col 2: Between Av. de Mayo [X = -160] and Cerrito [X = 0])
        -- Row 3: Between Cangallo [Z = -250] and Mitre [Z = 0], Base Y = 11.0
        -- RotationY = -90 (Facing West toward Avenida de Mayo)
        {
            Type = "HouseMedium",
            Name = "Urban_HouseMedium_E1",
            Position = Vector3.new(-111.0, 11.0, -211.00),
            RotationY = -90,
            DamageLevel = 0.40,
            SaltLevel = 0.30,
            Seed = 207,
        },
        {
            Type = "ShopRuins",
            Name = "Urban_ShopRuins_E1",
            Position = Vector3.new(-118.0, 11.0, -174.75),
            RotationY = -90,
            DamageLevel = 0.55,
            SaltLevel = 0.40,
            Seed = 208,
        },
        {
            Type = "HouseSmall",
            Name = "Urban_HouseSmall_E1",
            Position = Vector3.new(-121.0, 11.0, -144.00),
            RotationY = -90,
            DamageLevel = 0.50,
            SaltLevel = 0.45,
            Seed = 209,
        },
        {
            Type = "WallRuins",
            Name = "Urban_WallRuins_E1",
            Position = Vector3.new(-129.0, 11.0, -113.50),
            RotationY = -90,
            DamageLevel = 0.75,
            SaltLevel = 0.50,
            Seed = 210,
        },
        {
            Type = "HouseMedium",
            Name = "Urban_HouseMedium_E2",
            Position = Vector3.new(-111.0, 11.0, -77.50),
            RotationY = -90,
            DamageLevel = 0.60,
            SaltLevel = 0.35,
            Seed = 211,
        },
        {
            Type = "HouseSmall",
            Name = "Urban_HouseSmall_E2",
            Position = Vector3.new(-121.0, 11.0, -44.00),
            RotationY = -90,
            DamageLevel = 0.70,
            SaltLevel = 0.40,
            Seed = 212,
        },
    }

    for _, bData in ipairs(urbanTestBuildings) do
        local buildingModel = UrbanBuildingModelBuilder.Build({
            BuildingType = bData.Type,
            Position = bData.Position,
            RotationY = bData.RotationY,
            DamageLevel = bData.DamageLevel,
            SaltLevel = bData.SaltLevel,
            Seed = bData.Seed,
            Parent = folderUrbanBuildings,
        })
        if buildingModel then
            buildingModel.Name = bData.Name
            urbanBuildingsCount += 1
        end
    end

    -- ------------------------------------------------------------------------
    -- 12. FULL URBAN POPULATION GENERATION VIA URBAN POPULATION PLANNER
    --     Generates deterministic urban ruin distribution across eligible blocks
    --     Preserves the 12 Avenida de Mayo test buildings and all protected zones
    -- ------------------------------------------------------------------------
    local existingTestBuildingPositions: { Vector3 } = {}
    for _, bData in ipairs(urbanTestBuildings) do
        table.insert(existingTestBuildingPositions, bData.Position)
    end

    local populationPlan = UrbanPopulationPlanner.GeneratePlan({
        Seed = 5151,
        Density = 1.0,
        MaxBuildings = 140,
        ExistingBuildingPositions = existingTestBuildingPositions,
    })

    for index, record in ipairs(populationPlan.Buildings) do
        -- Deterministic salt level scaling with southern proximity (Z: -670 to 180)
        local normZ = math.clamp((record.Position.Z - (-670.0)) / (200.0 - (-670.0)), 0.0, 1.0)
        local baseSalt = 0.25 + (normZ * 0.45)
        local saltVariation = (((record.Seed % 29) / 28.0) - 0.5) * 0.12
        local finalSalt = math.clamp(baseSalt + saltVariation, 0.20, 0.88)

        -- Deterministic damage level scaling with salt and elevation
        local baseDamage = 0.45 + (normZ * 0.35)
        local damageVariation = (((record.Seed % 37) / 36.0) - 0.5) * 0.15
        local finalDamage = math.clamp(baseDamage + damageVariation, 0.35, 0.95)

        local buildingModel = UrbanBuildingModelBuilder.Build({
            BuildingType = record.BuildingType,
            Position = record.Position,
            RotationY = record.RotationY,
            Seed = record.Seed,
            Parent = folderUrbanBuildings,
            DamageLevel = finalDamage,
            SaltLevel = finalSalt,
        })
        if buildingModel then
            buildingModel.Name = string.format("Urban_%s_%s_%d", record.BlockId, record.BuildingType, index)
            urbanBuildingsCount += 1
        end
    end

    -- ------------------------------------------------------------------------
    -- 13. PHYSICAL VEHICLE-PART HIDEOUT STRUCTURES
    --     Constructs physical environmental hideout structures for the five canonical
    --     vehicle-part locations specified in EpecuenMapSpecification.CarPartSearchZones.
    --     Uses CarPartHideoutBuilder to generate realistic, salt-encrusted hiding spots.
    --     Each hideout contains an internal invisible "HidePoint" marker part as the intended
    --     future placement point for the corresponding vehicle part.
    --     Pure environmental geometry: NO vehicle parts, NO items, NO gameplay/prompts.
    -- ------------------------------------------------------------------------
    local canonicalHideoutConfigs: {
        [string]: {
            Archetype: string,
            Name: string,
            RotationY: number,
            Seed: number,
            DamageLevel: number,
            SaltLevel: number,
        }
    } = {
        Battery = {
            Archetype = "UtilityShed",
            Name = "Hideout_Battery_HotelMonteReal_GeneratorShed",
            RotationY = 0,
            Seed = 5101,
            DamageLevel = 0.75,
            SaltLevel = 0.70,
        },
        Alternator = {
            Archetype = "IndustrialStorage",
            Name = "Hideout_Alternator_Matadero_MachineryVault",
            RotationY = 0,
            Seed = 5102,
            DamageLevel = 0.80,
            SaltLevel = 0.85,
        },
        SparkPlugs = {
            Archetype = "WoodenCrates",
            Name = "Hideout_SparkPlugs_Darsena_PierCrateStack",
            RotationY = 0,
            Seed = 5103,
            DamageLevel = 0.85,
            SaltLevel = 0.95,
        },
        FuelCanister = {
            Archetype = "StorageCabinet",
            Name = "Hideout_FuelCanister_Terminal_LuggageCabinet",
            RotationY = 0,
            Seed = 5104,
            DamageLevel = 0.65,
            SaltLevel = 0.50,
        },
        RadiatorHose = {
            Archetype = "WorkshopBench",
            Name = "Hideout_RadiatorHose_Corralon_RepairBench",
            RotationY = 0,
            Seed = 5105,
            DamageLevel = 0.70,
            SaltLevel = 0.45,
        },
    }

    for _, searchZone in ipairs(EpecuenMapSpecification.CarPartSearchZones) do
        local config = canonicalHideoutConfigs[searchZone.PartType]
        if config then
            local canonicalPos = toVector3(searchZone.ApproximatePosition)
            local hideoutModel = CarPartHideoutBuilder.Build({
                Position = canonicalPos,
                RotationY = config.RotationY,
                HideoutType = config.Archetype,
                Seed = config.Seed,
                DamageLevel = config.DamageLevel,
                SaltLevel = config.SaltLevel,
                Parent = folderCarPartHideouts,
                Name = config.Name,
            })
            if hideoutModel then
                carPartHideoutsCount += 1
            end
        end
    end

    -- ------------------------------------------------------------------------
    -- 14. ENVIRONMENTAL AUTOMOTIVE TOOLBOX (RepairToolWorldPlacement)
    --     Single physical abandoned mechanic's toolbox tucked into the
    --     Corralón Municipal workshop yard. Non-objective environmental detail.
    -- ------------------------------------------------------------------------
    local toolboxModel = nil
    if RepairToolWorldPlacement and typeof(RepairToolWorldPlacement.Build) == "function" then
        toolboxModel = RepairToolWorldPlacement.Build(folderEnvironment)
        if toolboxModel then
            environmentDetailsCount += 1
        end
    end

    -- ------------------------------------------------------------------------
    -- 15. PHYSICAL VEHICLE REPAIR COMPONENTS (CarPartPhysicalBuilder)
    --     Generates the five physical Fiat Cronos repair components inside
    --     Workspace.EpecuenWorld.CarRepairParts, anchored at their corresponding
    --     HidePoints inside the CarPartHideouts created in Step 13.
    -- ------------------------------------------------------------------------
    local carPartsCount = 0
    if CarPartPhysicalBuilder and typeof(CarPartPhysicalBuilder.BuildAll) == "function" then
        local createdModels = CarPartPhysicalBuilder.BuildAll()
        if typeof(createdModels) == "table" then
            for _, componentName in ipairs(CarPartPhysicalBuilder.GetComponentNames()) do
                if createdModels[componentName] then
                    carPartsCount += 1
                end
            end
        end
    end

    -- ------------------------------------------------------------------------
    -- 16. CAR PART COLLECTION SYSTEM INITIALIZATION (CarPartCollectionSystem)
    --     Arms ProximityPrompts on the five physical components and hooks
    --     server-authoritative player collection lifecycle.
    -- ------------------------------------------------------------------------
    local collectionInitialized = false
    if CarPartCollectionSystem and typeof(CarPartCollectionSystem.Initialize) == "function" then
        collectionInitialized = CarPartCollectionSystem.Initialize()
    end

    -- ------------------------------------------------------------------------
    -- 17. HOTEL MONTE REAL BATTERY OBSTACLE (HotelBatteryObstacleSystem)
    --     Generates the single environmental collapsed gate/rubble obstruction
    --     blocking the entrance to the Hotel Monte Real generator shed, protecting
    --     the Battery until cleared by a player.
    -- ------------------------------------------------------------------------
    local batteryObstacleInitialized = false
    if HotelBatteryObstacleSystem and typeof(HotelBatteryObstacleSystem.Initialize) == "function" then
        batteryObstacleInitialized = HotelBatteryObstacleSystem.Initialize()
    end

    -- ------------------------------------------------------------------------
    -- 18. MATADERO ALTERNATOR OBSTACLE (MataderoAlternatorObstacleSystem)
    --     Generates the single industrial collapsed gate/rebar obstruction
    --     blocking the entrance to the Matadero machinery vault, protecting
    --     the Alternator until opened by a player.
    -- ------------------------------------------------------------------------
    local alternatorObstacleInitialized = false
    if MataderoAlternatorObstacleSystem and typeof(MataderoAlternatorObstacleSystem.Initialize) == "function" then
        alternatorObstacleInitialized = MataderoAlternatorObstacleSystem.Initialize()
    end

    -- ------------------------------------------------------------------------
    -- 19. DÁRSENA CENTRAL SPARK PLUGS OBSTACLE (DarsenaSparkPlugsObstacleSystem)
    --     Generates the single environmental collapsed pier/mooring obstruction
    --     blocking the walkway to the Dársena pier crate stack, protecting
    --     the Spark Plugs until cleared by a player.
    -- ------------------------------------------------------------------------
    local sparkPlugsObstacleInitialized = false
    if DarsenaSparkPlugsObstacleSystem and typeof(DarsenaSparkPlugsObstacleSystem.Initialize) == "function" then
        sparkPlugsObstacleInitialized = DarsenaSparkPlugsObstacleSystem.Initialize()
    end

    -- ------------------------------------------------------------------------
    -- 20. TERMINAL FUEL CANISTER OBSTACLE (FuelCanisterTerminalObstacleSystem)
    --     Generates the single environmental toppled locker and debris obstruction
    --     blocking access to the Terminal luggage cabinet hideout, protecting
    --     the Fuel Canister until cleared by a player.
    -- ------------------------------------------------------------------------
    local fuelCanisterObstacleInitialized = false
    if FuelCanisterTerminalObstacleSystem and typeof(FuelCanisterTerminalObstacleSystem.Initialize) == "function" then
        fuelCanisterObstacleInitialized = FuelCanisterTerminalObstacleSystem.Initialize()
    end

    -- ------------------------------------------------------------------------
    -- 21. CORRALÓN RADIATOR HOSE OBSTACLE (RadiatorHoseCorralonObstacleSystem)
    --     Generates the single environmental toppled workbench and sheet metal
    --     obstruction blocking access to the Corralón repair bench hideout,
    --     protecting the Radiator Hose until cleared by a player.
    -- ------------------------------------------------------------------------
    local radiatorHoseObstacleInitialized = false
    if RadiatorHoseCorralonObstacleSystem and typeof(RadiatorHoseCorralonObstacleSystem.Initialize) == "function" then
        radiatorHoseObstacleInitialized = RadiatorHoseCorralonObstacleSystem.Initialize()
    end

    local stats: GenerationStats = {
        RoadsCount = roadsCount,
        BlocksCount = blocksCount,
        ZonesCount = zonesCount,
        LandmarksCount = landmarksCount,
        MarkersCount = markersCount,
        RuinsCount = ruinsCount,
        EnvironmentDetailsCount = environmentDetailsCount,
        UrbanBuildingsCount = urbanBuildingsCount,
        CarPartHideoutsCount = carPartHideoutsCount,
        RepairToolCount = toolboxModel and 1 or 0,
        CarPartsCount = carPartsCount,
        CarPartCollectionInitialized = collectionInitialized,
        HotelBatteryObstacleInitialized = batteryObstacleInitialized,
        MataderoAlternatorObstacleInitialized = alternatorObstacleInitialized,
        DarsenaSparkPlugsObstacleInitialized = sparkPlugsObstacleInitialized,
        FuelCanisterTerminalObstacleInitialized = fuelCanisterObstacleInitialized,
        RadiatorHoseCorralonObstacleInitialized = radiatorHoseObstacleInitialized,
    }

    return stats
end

-- Auto-generate on server boot if running in a live Roblox Studio/Server environment
task.defer(function()
    if Workspace:FindFirstChild("EpecuenWorld") == nil then
        EpecuenMapGenerator.Generate()
    end
end)

return EpecuenMapGenerator
