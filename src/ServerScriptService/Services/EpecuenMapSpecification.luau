--!strict
--[[
    EpecuenMapSpecification.luau
    Master Geographic, Spatial & Architectural Specification Data for "EPECUÉN: NO ESCAPE"
    
    Source Reference: Historical Municipal Tourist Plan ("Plano - Villa Turística Lago Epecuén")
    Municipalidad de Adolfo Alsina - Dirección de Turismo & Archivo Histórico de Carhué.
    
    Coordinate System (Roblox Studs, 1 stud ≈ 0.28m):
      Origin (0, 0, 0): Central Plaza ("Ud. Está Aquí") at Calle Cerrito & Calle Mitre
      +X: East (toward Calle Florida, Eastern Littoral Basin, and El Matadero)
      -X: West (toward Western Radial Plazas, Cemetery, and Calle Talcahuano)
      +Z: South (toward Calle Alsina, Shoreline Pier, and Laguna Epecuén)
      -Z: North (toward Terminal de Ómnibus, School, Corralón, and Carhué Access Road)
      +Y: Elevation (Pampas high ground +20 studs -> Lakebed brine -8 studs)

    DESIGN PRINCIPLES:
      1. Open-world continuity: One cohesive seamless world map, zero disconnected rooms or teleports.
      2. Geographic authenticity: Faithfully mirrors the real 1985 layout before the flood.
      3. Matadero as an accessible peripheral sector: Connected by road at (X: 650, Y: 15, Z: 480).
      4. Submerged littoral fringe: Massive lagoon and flooded streets with caustic brine hazards.
      5. Procedural readiness: Fully typed data structures for blocks, streets, props, hazards, and horror anchors.
--]]

export type Vector2D = {
    X: number,
    Z: number,
}

export type Vector3D = {
    X: number,
    Y: number,
    Z: number,
}

export type BoundingBox = {
    Min: Vector3D,
    Max: Vector3D,
}

export type StreetOrientation = "NorthSouth" | "EastWest" | "Diagonal" | "CurvedCoast"

export type Street = {
    Id: string,
    Name: string,
    HistoricalName: string,
    Orientation: StreetOrientation,
    IsPaved: boolean,
    WidthStuds: number,
    StartPos: Vector3D,
    EndPos: Vector3D,
    SubmergedSegment: { StartZ: number, EndZ: number, DepthStuds: number }?,
    Description: string,
}

export type Intersection = {
    Id: string,
    StreetA: string,
    StreetB: string,
    Position: Vector3D,
    IsPavedCrossroad: boolean,
    IsFlooded: boolean,
    TacticalNote: string,
}

export type BlockRuinsProfile = {
    RubbleDensity: "Sparse" | "Medium" | "Dense" | "ImpassableCore",
    WallCollapseRatio: number, -- 0.0 (intact facades) to 1.0 (flat concrete rubble)
    PetrifiedTreeCount: number,
    ConcreteLightPoleCount: number,
    BleachedSaltCrustLevel: number, -- 0 to 100
    PrimaryStyle: "ArtDeco" | "Neoclassical" | "ThermalSpa" | "CommercialRow" | "RuralResidential",
}

export type UrbanBlock = {
    Id: string,
    ColumnIndex: number,
    RowIndex: number,
    Name: string,
    Bounds: BoundingBox,
    Center: Vector3D,
    ElevationY: number,
    RuinsProfile: BlockRuinsProfile,
    HistoricalOccupants: { string },
    HasSearchableInterior: boolean,
}

export type WaterChannel = {
    Id: string,
    Name: string,
    Bounds: BoundingBox,
    WaterLevelY: number,
    FlowDirection: Vector2D,
    IsCausticBrine: boolean,
    SalinityToxicityRate: number, -- Sanity/health damage per sec if immersed
    MovementSpeedPenalty: number, -- e.g. 0.4 = 40% slowdown
    VisualTurbidity: "CrystalSalt" | "MurkyBrine" | "BlackAlgaeSilt",
}

export type ZoneType = 
    | "UrbanGrid"
    | "RadialPark"
    | "CivicCenter"
    | "HospitalityResort"
    | "ShorelineWaterfront"
    | "IndustrialSlaughterhouse"
    | "TransitDepot"
    | "RuralAccess"
    | "FloodedCemetery"
    | "SubmergedBrine"

export type GeographicZone = {
    Id: string,
    Name: string,
    Category: ZoneType,
    Bounds: BoundingBox,
    Center: Vector3D,
    ElevationRange: { Min: number, Max: number },
    SalinityHazardLevel: number, -- 0 (dry) to 100 (caustic flood)
    ThreatLevel: "Low" | "Medium" | "High" | "Deadly",
    AcousticProfile: "MuffledFog" | "EchoingConcrete" | "OpenWind" | "WaterSloshing" | "CryptEmanations",
    Description: string,
    NorthOf: string,
    SouthOf: string,
    EastOf: string,
    WestOf: string,
}

export type Landmark = {
    Id: string,
    IndexOnMap: number?, -- Number on the municipal tourist map
    Name: string,
    HistoricalCategory: string,
    Position: Vector3D,
    FootprintStuds: Vector2D,
    VerticalHeightStuds: number,
    VisualSilhouette: string,
    GameplayRole: string,
    FogVisibilityStuds: number,
    HistoricalNotes: string,
}

export type CarPartType = "Battery" | "Alternator" | "SparkPlugs" | "FuelCanister" | "RadiatorHose"

export type CarPartSearchZone = {
    PartType: CarPartType,
    ItemName: string,
    ZoneId: string,
    LandmarkAnchor: string,
    SearchRadiusStuds: number,
    ApproximatePosition: Vector3D,
    EnvironmentalHazard: string,
    PuzzleOrThreat: string,
    LoreHint: string,
}

export type ParanormalEventType = 
    | "PhantomFootstepsInBrine"
    | "SubmergedBellChime"
    | "CryptVaultWhispers"
    | "SlaughterhouseChainRattle"
    | "StreetlightFlickerBurst"
    | "ShadowSilhouetteCrosswalk"
    | "PianoEchoInHotelRuins"
    | "SinkingMudPull"

export type ParanormalAnchor = {
    Id: string,
    EventType: ParanormalEventType,
    Position: Vector3D,
    TriggerRadiusStuds: number,
    SanityImpact: number, -- Negative delta to player sanity
    CooldownSeconds: number,
    VisualCueDescription: string,
    AudioCueDescription: string,
}

export type ProceduralPropDensity = {
    DebrisPilesPer100StudsSq: number,
    DeadCalamiteTreesPer100StudsSq: number,
    CorrugatedMetalSheetsPer100StudsSq: number,
    SaltEncrustedMoundsPer100StudsSq: number,
    SubmergedFurniturePer100StudsSq: number,
}

-- ============================================================================
-- MASTER SPECIFICATION TABLE
-- ============================================================================

local EpecuenMapSpecification = {}

-- 1. WORLD ORIGIN & OVERALL BOUNDS
EpecuenMapSpecification.WorldBounds = {
    Origin = { X = 0, Y = 0, Z = 0 }, -- Plaza Central "Ud. Está Aquí" (Mitre & Cerrito)
    Min = { X = -1200, Y = -10, Z = -950 },
    Max = { X = 1500, Y = 95, Z = 1100 },
    TotalWidthStuds = 2700,
    TotalLengthStuds = 2050,
    SeaLevelBrineY = 0.0,
    GroundBaseY = -2.0,
    MaxTowerZenithY = 85.0,
    Center = { X = 150, Y = 0, Z = 75 },
    FogStartStuds = 40,
    FogEndStuds = 280,
    DayNightCycleMinutes = 0, -- Permadusk / post-apocalyptic saline gloom
}

-- 2. MAIN ACCESS ROADS & STARTING LOCATION
EpecuenMapSpecification.PlayerSpawn = {
    Id = "SPAWN_ACCESO_NORTE",
    Name = "Acceso Norte / Llegada a Villa Epecuén",
    Position = { X = -180, Y = 20, Z = -780 },
    FacingAngleY = 170, -- Facing South toward the ruined skyline and fog
    Description = "The mud-spattered asphalt highway terminates here. Beyond the barricade lies the salt-bleached ghost town.",
}

EpecuenMapSpecification.FiatCronos = {
    Id = "VEHICLE_FIAT_CRONOS",
    Name = "Fiat Cronos 1.3 Drive (Vehículo Varado)",
    Position = { X = -160, Y = 19, Z = -755 },
    RotationY = 175,
    RequiredParts = {
        "Battery",
        "Alternator",
        "SparkPlugs",
        "FuelCanister",
        "RadiatorHose",
    },
    CurrentCondition = "Engine seized, drained battery, cracked radiator hose, dry fuel tank, rusted plugs. Headlights flicker faintly.",
    EscapeRouteRoad = "RD_ACCESO_NORTE",
}

-- 3. STREETS AND AVENUES NETWORK
EpecuenMapSpecification.Streets = {
    -- North-South Thoroughfares (West to East)
    {
        Id = "ST_TALCAHUANO",
        Name = "Calle Talcahuano",
        HistoricalName = "Calle Talcahuano",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -320, Y = 18, Z = -680 },
        EndPos = { X = -320, Y = 2, Z = 450 },
        SubmergedSegment = { StartZ = 280, EndZ = 450, DepthStuds = 2 },
        Description = "Westernmost boundary street of the orthogonal grid, bordering the vast circular radial parks and petrified forests.",
    },
    {
        Id = "ST_MAYO",
        Name = "Avenida de Mayo",
        HistoricalName = "Avenida de Mayo",
        Orientation = "NorthSouth",
        IsPaved = true,
        WidthStuds = 48,
        StartPos = { X = -160, Y = 20, Z = -780 },
        EndPos = { X = -160, Y = 0, Z = 520 },
        SubmergedSegment = { StartZ = 380, EndZ = 520, DepthStuds = 4 },
        Description = "Grand central boulevard. Paved with wide sidewalks and central light posts, running from the northern access barricade down to the lakefront pier.",
    },
    {
        Id = "ST_CERRITO",
        Name = "Calle Cerrito",
        HistoricalName = "Calle Cerrito",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 0, Y = 16, Z = -650 },
        EndPos = { X = 0, Y = 2, Z = 460 },
        SubmergedSegment = { StartZ = 340, EndZ = 460, DepthStuds = 3 },
        Description = "Western boundary of Plaza Central. Lined by collapsed tea houses, ice cream parlors, and souvenir stalls.",
    },
    {
        Id = "ST_PELLEGRINI",
        Name = "Calle Carlos Pellegrini",
        HistoricalName = "Calle Pellegrini",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 150, Y = 16, Z = -650 },
        EndPos = { X = 150, Y = 2, Z = 460 },
        SubmergedSegment = { StartZ = 320, EndZ = 460, DepthStuds = 3 },
        Description = "Eastern boundary of Plaza Central. Houses commercial fronts, barber shops, and modest residential hotels.",
    },
    {
        Id = "ST_SUIPACHA",
        Name = "Calle Suipacha",
        HistoricalName = "Calle Suipacha",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 300, Y = 14, Z = -650 },
        EndPos = { X = 300, Y = 2, Z = 450 },
        SubmergedSegment = { StartZ = 300, EndZ = 450, DepthStuds = 3 },
        Description = "Residential avenue leading down to thermal treatment centers and the rear garden courtyards of larger hotels.",
    },
    {
        Id = "ST_ESMERALDA",
        Name = "Calle Esmeralda",
        HistoricalName = "Calle Esmeralda",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 450, Y = 14, Z = -650 },
        EndPos = { X = 450, Y = 2, Z = 450 },
        SubmergedSegment = { StartZ = 280, EndZ = 450, DepthStuds = 4 },
        Description = "Street bordering the eastern side of Hotel Monte Real. Heavily obstructed by collapsed second-story balconies and tiled roofs.",
    },
    {
        Id = "ST_MAIPU",
        Name = "Calle Maipú",
        HistoricalName = "Calle Maipú",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 600, Y = 12, Z = -650 },
        EndPos = { X = 600, Y = 2, Z = 420 },
        SubmergedSegment = { StartZ = 260, EndZ = 420, DepthStuds = 4 },
        Description = "Eastern hotel corridor. Flanked by boarding houses and family vacation chalets surrounded by bleached eucalyptus stumps.",
    },
    {
        Id = "ST_FLORIDA",
        Name = "Calle Florida",
        HistoricalName = "Calle Florida",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 750, Y = 10, Z = -650 },
        EndPos = { X = 750, Y = 1, Z = 380 },
        SubmergedSegment = { StartZ = 220, EndZ = 380, DepthStuds = 5 },
        Description = "Eastern edge of the built town grid, overlooking the vast saline mudflats and the southeastern lagoon inlet.",
    },

    -- East-West Thoroughfares (North to South)
    {
        Id = "ST_SARMIENTO",
        Name = "Calle Domingo F. Sarmiento",
        HistoricalName = "Calle Sarmiento",
        Orientation = "EastWest",
        IsPaved = true,
        WidthStuds = 36,
        StartPos = { X = -350, Y = 16, Z = -450 },
        EndPos = { X = 780, Y = 14, Z = -450 },
        SubmergedSegment = nil,
        Description = "Northern arterial street connecting the Railway Station district, Escuela N° 17, and the entrance to the residential quarters.",
    },
    {
        Id = "ST_CANGALLO",
        Name = "Calle Cangallo",
        HistoricalName = "Calle Cangallo",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -350, Y = 14, Z = -250 },
        EndPos = { X = 780, Y = 12, Z = -250 },
        SubmergedSegment = nil,
        Description = "Mid-town residential street traversing backyards, private water pump towers, and boarding house courtyards.",
    },
    {
        Id = "ST_MITRE",
        Name = "Calle Bartolomé Mitre",
        HistoricalName = "Calle Mitre",
        Orientation = "EastWest",
        IsPaved = true,
        WidthStuds = 44,
        StartPos = { X = -350, Y = 12, Z = 0 },
        EndPos = { X = 780, Y = 8, Z = 0 },
        SubmergedSegment = nil,
        Description = "Prime commercial artery bisecting Plaza Central. Once filled with luxury bakeries, photo studios, and artisanal salt boutiques.",
    },
    {
        Id = "ST_RIVADAVIA",
        Name = "Calle Bernardino Rivadavia",
        HistoricalName = "Calle Rivadavia",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -350, Y = 8, Z = 200 },
        EndPos = { X = 780, Y = 5, Z = 200 },
        SubmergedSegment = { StartZ = 200, EndZ = 200, DepthStuds = 1 },
        Description = "Border of the lower town. Water regularly floods this street during strong south winds pushing brine inland.",
    },
    {
        Id = "ST_VICTORIA",
        Name = "Calle Victoria",
        HistoricalName = "Calle Victoria",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -350, Y = 5, Z = 380 },
        EndPos = { X = 780, Y = 2, Z = 380 },
        SubmergedSegment = { StartZ = 380, EndZ = 380, DepthStuds = 3 },
        Description = "Lower residential street severely eroded by brine. Foundations here are reduced to white concrete slabs and skeletal rebar.",
    },
    {
        Id = "ST_ALSINA",
        Name = "Calle Adolfo Alsina (Costanera)",
        HistoricalName = "Costanera Balnearia",
        Orientation = "CurvedCoast",
        IsPaved = true,
        WidthStuds = 36,
        StartPos = { X = -350, Y = 2, Z = 490 },
        EndPos = { X = 780, Y = 0, Z = 490 },
        SubmergedSegment = { StartZ = 490, EndZ = 490, DepthStuds = 4 },
        Description = "The historic seaside promenade. Half-submerged concrete benches, broken balustrades, and steps leading directly into the caustic brine.",
    },

    -- Regional Connecting Roads
    {
        Id = "RD_ACCESO_NORTE",
        Name = "Ruta de Acceso Norte (Carhué)",
        HistoricalName = "Camino Pavimentado a Carhué",
        Orientation = "NorthSouth",
        IsPaved = true,
        WidthStuds = 40,
        StartPos = { X = -160, Y = 24, Z = -950 },
        EndPos = { X = -160, Y = 20, Z = -780 },
        SubmergedSegment = nil,
        Description = "Sole dry ingress to Villa Epecuén from Carhué. Blockaded by police wooden barriers and rusted flood warning signs.",
    },
    {
        Id = "RD_CAMINO_MATADERO",
        Name = "Camino al Matadero",
        HistoricalName = "Huella Rural al Matadero",
        Orientation = "Diagonal",
        IsPaved = false,
        WidthStuds = 24,
        StartPos = { X = 500, Y = 3, Z = 380 },
        EndPos = { X = 650, Y = 15, Z = 480 },
        SubmergedSegment = { StartZ = 390, EndZ = 420, DepthStuds = 2 },
        Description = "Deteriorated gravel and cracked asphalt track connecting Calle Victoria to the peripheral Francisco Salamone slaughterhouse.",
    },
    {
        Id = "RD_HUELLA_CEMENTERIO",
        Name = "Huella al Cementerio Inundado",
        HistoricalName = "Camino del Bajo al Cementerio",
        Orientation = "Diagonal",
        IsPaved = false,
        WidthStuds = 22,
        StartPos = { X = -320, Y = 4, Z = 380 },
        EndPos = { X = -650, Y = 1, Z = 550 },
        SubmergedSegment = { StartZ = 420, EndZ = 550, DepthStuds = 3 },
        Description = "Submerged dirt track wading through petrified trees and briny mud toward the half-drowned municipal necropolis.",
    },
    {
        Id = "RD_RADIAL_WEST",
        Name = "Avenida Radial Diagonal Oeste",
        HistoricalName = "Diagonal de las Plazas",
        Orientation = "Diagonal",
        IsPaved = false,
        WidthStuds = 30,
        StartPos = { X = -320, Y = 14, Z = -250 },
        EndPos = { X = -720, Y = 8, Z = -100 },
        SubmergedSegment = nil,
        Description = "Diagonal radiant parkway shooting outward into the circular Beaux-Arts garden plazas and dead forests.",
    },
} :: { Street }

-- 4. IMPORTANT INTERSECTIONS
EpecuenMapSpecification.Intersections = {
    {
        Id = "INT_MAYO_SARMIENTO",
        StreetA = "ST_MAYO",
        StreetB = "ST_SARMIENTO",
        Position = { X = -160, Y = 18, Z = -450 },
        IsPavedCrossroad = true,
        IsFlooded = false,
        TacticalNote = "Northern entry crossroad. High visibility, clear escape line back to vehicle.",
    },
    {
        Id = "INT_MAYO_MITRE",
        StreetA = "ST_MAYO",
        StreetB = "ST_MITRE",
        Position = { X = -160, Y = 12, Z = 0 },
        IsPavedCrossroad = true,
        IsFlooded = false,
        TacticalNote = "Primary central crossroads adjacent to Plaza Central and Teatro Bowling.",
    },
    {
        Id = "INT_CERRITO_MITRE",
        StreetA = "ST_CERRITO",
        StreetB = "ST_MITRE",
        Position = { X = 0, Y = 11, Z = 0 },
        IsPavedCrossroad = false,
        IsFlooded = false,
        TacticalNote = "World coordinate origin reference. Landmark sign 'Ud. Está Aquí' stands on the northeast curb.",
    },
    {
        Id = "INT_PELLEGRINI_MITRE",
        StreetA = "ST_PELLEGRINI",
        StreetB = "ST_MITRE",
        Position = { X = 150, Y = 10, Z = 0 },
        IsPavedCrossroad = false,
        IsFlooded = false,
        TacticalNote = "Southeast corner of Plaza Central. Path heading south leads toward the church ruins.",
    },
    {
        Id = "INT_ESMERALDA_CANGALLO",
        StreetA = "ST_ESMERALDA",
        StreetB = "ST_CANGALLO",
        Position = { X = 450, Y = 12, Z = -250 },
        IsPavedCrossroad = false,
        IsFlooded = false,
        TacticalNote = "Northeast corner of Residencial Monte Real block. Heavy shadow cover from crumbling walls.",
    },
    {
        Id = "INT_MAYO_ALSINA",
        StreetA = "ST_MAYO",
        StreetB = "ST_ALSINA",
        Position = { X = -160, Y = 0, Z = 490 },
        IsPavedCrossroad = true,
        IsFlooded = true,
        TacticalNote = "The flooded pier embarkation gate. Knee-deep salt water begins here, extending to the central pier.",
    },
    {
        Id = "INT_VICTORIA_MATADERO",
        StreetA = "ST_VICTORIA",
        StreetB = "RD_CAMINO_MATADERO",
        Position = { X = 500, Y = 3, Z = 380 },
        IsPavedCrossroad = false,
        IsFlooded = true,
        TacticalNote = "Fork at the southeast edge of town where Calle Victoria branches onto the deteriorated path toward the Matadero.",
    },
    {
        Id = "INT_TALCAHUANO_CEMENTERIO",
        StreetA = "ST_TALCAHUANO",
        StreetB = "RD_HUELLA_CEMENTERIO",
        Position = { X = -320, Y = 4, Z = 380 },
        IsPavedCrossroad = false,
        IsFlooded = true,
        TacticalNote = "Southwest water gate branching out toward the submerged cemetery and the dead caldén groves.",
    },
} :: { Intersection }

-- 5. URBAN BLOCKS & RESIDENTIAL RUINS (PROCEDURAL GEOMETRY LAYOUT)
-- Structured in 7 longitudinal columns (West -> East) and 6 latitudinal rows (North -> South)
EpecuenMapSpecification.UrbanBlocks = {
    -- Row 1 (North Grid, High Elevation Y: 16-18 studs)
    {
        Id = "BLK_R1_C1",
        ColumnIndex = 1,
        RowIndex = 1,
        Name = "Manzana Terminal y Garajes",
        Bounds = { Min = { X = -300, Y = 16, Z = -670 }, Max = { X = -180, Y = 28, Z = -470 } },
        Center = { X = -240, Y = 17, Z = -570 },
        ElevationY = 17,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.45,
            PetrifiedTreeCount = 4,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 15,
            PrimaryStyle = "CommercialRow",
        },
        HistoricalOccupants = { "Terminal de Ómnibus Empresa La Estrella", "Taller Mecánico Epecuén", "Estación de Servicio YPF" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R1_C2",
        ColumnIndex = 2,
        RowIndex = 1,
        Name = "Manzana Escuela e Institucional",
        Bounds = { Min = { X = -140, Y = 16, Z = -670 }, Max = { X = -20, Y = 28, Z = -470 } },
        Center = { X = -80, Y = 17, Z = -570 },
        ElevationY = 17,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.50,
            PetrifiedTreeCount = 6,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 18,
            PrimaryStyle = "Neoclassical",
        },
        HistoricalOccupants = { "Escuela Primaria N° 17", "Destacamento Policial", "Oficina Postal ENCOTEL" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R1_C3",
        ColumnIndex = 3,
        RowIndex = 1,
        Name = "Manzana Ferroviaria Central",
        Bounds = { Min = { X = 20, Y = 15, Z = -670 }, Max = { X = 130, Y = 26, Z = -470 } },
        Center = { X = 75, Y = 16, Z = -570 },
        ElevationY = 16,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.65,
            PetrifiedTreeCount = 8,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 22,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hotel Colonia Ferroviaria", "Pensionado San Cayetano", "Depósitos de Mercadería" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R1_C4",
        ColumnIndex = 4,
        RowIndex = 1,
        Name = "Manzana Chalets del Norte",
        Bounds = { Min = { X = 170, Y = 15, Z = -670 }, Max = { X = 280, Y = 24, Z = -470 } },
        Center = { X = 225, Y = 15, Z = -570 },
        ElevationY = 15,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.55,
            PetrifiedTreeCount = 10,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 20,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Residencial Las Flores", "Viviendas familiares de veraneo", "Quinta de Olivos" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R1_C5",
        ColumnIndex = 5,
        RowIndex = 1,
        Name = "Manzana Residencial Este 1",
        Bounds = { Min = { X = 320, Y = 14, Z = -670 }, Max = { X = 430, Y = 24, Z = -470 } },
        Center = { X = 375, Y = 14, Z = -570 },
        ElevationY = 14,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.60,
            PetrifiedTreeCount = 7,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 24,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hospedaje El Trebol", "Panadería La Espiga de Oro" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R1_C6",
        ColumnIndex = 6,
        RowIndex = 1,
        Name = "Manzana Residencial Este 2",
        Bounds = { Min = { X = 470, Y = 13, Z = -670 }, Max = { X = 580, Y = 22, Z = -470 } },
        Center = { X = 525, Y = 13, Z = -570 },
        ElevationY = 13,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.70,
            PetrifiedTreeCount = 12,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 25,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Quintas suburbanas", "Molinos de viento y aguadas" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R1_C7",
        ColumnIndex = 7,
        RowIndex = 1,
        Name = "Manzana Límite Este",
        Bounds = { Min = { X = 620, Y = 12, Z = -670 }, Max = { X = 730, Y = 20, Z = -470 } },
        Center = { X = 675, Y = 12, Z = -570 },
        ElevationY = 12,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.85,
            PetrifiedTreeCount = 15,
            ConcreteLightPoleCount = 0,
            BleachedSaltCrustLevel = 30,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Pastizales pampeanos", "Alambrados caídos" },
        HasSearchableInterior = false,
    },

    -- Row 2 (Sarmiento to Cangallo, Elevation Y: 13-15 studs)
    {
        Id = "BLK_R2_C1",
        ColumnIndex = 1,
        RowIndex = 2,
        Name = "Manzana Hoteles del Oeste",
        Bounds = { Min = { X = -300, Y = 14, Z = -430 }, Max = { X = -180, Y = 26, Z = -270 } },
        Center = { X = -240, Y = 14, Z = -350 },
        ElevationY = 14,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.50,
            PetrifiedTreeCount = 5,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 25,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Gran Hotel Las Delicias", "Pensión La Porteña" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R2_C2",
        ColumnIndex = 2,
        RowIndex = 2,
        Name = "Manzana Comercial Av. de Mayo Norte",
        Bounds = { Min = { X = -140, Y = 14, Z = -430 }, Max = { X = -20, Y = 26, Z = -270 } },
        Center = { X = -80, Y = 14, Z = -350 },
        ElevationY = 14,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.40,
            PetrifiedTreeCount = 6,
            ConcreteLightPoleCount = 3,
            BleachedSaltCrustLevel = 25,
            PrimaryStyle = "CommercialRow",
        },
        HistoricalOccupants = { "Farmacia Epecuén", "Bazar y Regalería El Cisne", "Confitería París" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R2_C3",
        ColumnIndex = 3,
        RowIndex = 2,
        Name = "Manzana Hotel Bristol y Termas",
        Bounds = { Min = { X = 20, Y = 13, Z = -430 }, Max = { X = 130, Y = 26, Z = -270 } },
        Center = { X = 75, Y = 13, Z = -350 },
        ElevationY = 13,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.45,
            PetrifiedTreeCount = 6,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 28,
            PrimaryStyle = "Neoclassical",
        },
        HistoricalOccupants = { "Hotel Bristol", "Pensión Mayo", "Lavandería a Vapor" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R2_C4",
        ColumnIndex = 4,
        RowIndex = 2,
        Name = "Manzana Hotelería Familiar",
        Bounds = { Min = { X = 170, Y = 13, Z = -430 }, Max = { X = 280, Y = 24, Z = -270 } },
        Center = { X = 225, Y = 13, Z = -350 },
        ElevationY = 13,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.55,
            PetrifiedTreeCount = 8,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 26,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hotel Playa", "Residencial Edén", "Cine Petit" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R2_C5",
        ColumnIndex = 5,
        RowIndex = 2,
        Name = "Manzana Residencial Monte Real (Norte)",
        Bounds = { Min = { X = 320, Y = 12, Z = -430 }, Max = { X = 430, Y = 30, Z = -270 } },
        Center = { X = 375, Y = 12, Z = -350 },
        ElevationY = 12,
        RuinsProfile = {
            RubbleDensity = "ImpassableCore",
            WallCollapseRatio = 0.35,
            PetrifiedTreeCount = 10,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 30,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Jardines y Parque Privado de Residencial Monte Real" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R2_C6",
        ColumnIndex = 6,
        RowIndex = 2,
        Name = "Manzana Chalets del Este 2",
        Bounds = { Min = { X = 470, Y = 11, Z = -430 }, Max = { X = 580, Y = 20, Z = -270 } },
        Center = { X = 525, Y = 11, Z = -350 },
        ElevationY = 11,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.65,
            PetrifiedTreeCount = 9,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 32,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Hostería El Ombú", "Cabañas de temporada" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R2_C7",
        ColumnIndex = 7,
        RowIndex = 2,
        Name = "Manzana Salitral Este 2",
        Bounds = { Min = { X = 620, Y = 10, Z = -430 }, Max = { X = 730, Y = 18, Z = -270 } },
        Center = { X = 675, Y = 10, Z = -350 },
        ElevationY = 10,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.90,
            PetrifiedTreeCount = 14,
            ConcreteLightPoleCount = 0,
            BleachedSaltCrustLevel = 40,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Ruinas de adobe disgregadas", "Tanque australiano semihundido" },
        HasSearchableInterior = false,
    },

    -- Row 3 (Cangallo to Mitre - Heartland / Plaza Central, Elevation Y: 10-12 studs)
    {
        Id = "BLK_R3_C1",
        ColumnIndex = 1,
        RowIndex = 3,
        Name = "Manzana Teatro Bowling y Comercio Oeste",
        Bounds = { Min = { X = -300, Y = 12, Z = -230 }, Max = { X = -180, Y = 28, Z = -20 } },
        Center = { X = -240, Y = 12, Z = -125 },
        ElevationY = 12,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.35,
            PetrifiedTreeCount = 4,
            ConcreteLightPoleCount = 3,
            BleachedSaltCrustLevel = 30,
            PrimaryStyle = "ArtDeco",
        },
        HistoricalOccupants = { "Teatro Bowling Epecuén", "Restaurante El Ancla", "Billiards & Bar Social" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R3_C2",
        ColumnIndex = 2,
        RowIndex = 3,
        Name = "Manzana Oeste de Plaza Central",
        Bounds = { Min = { X = -140, Y = 12, Z = -230 }, Max = { X = -20, Y = 28, Z = -20 } },
        Center = { X = -80, Y = 12, Z = -125 },
        ElevationY = 12,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.40,
            PetrifiedTreeCount = 6,
            ConcreteLightPoleCount = 3,
            BleachedSaltCrustLevel = 32,
            PrimaryStyle = "CommercialRow",
        },
        HistoricalOccupants = { "Heladería El Polo", "Fotografía Salgado", "Sastrería Mitre" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R3_C3",
        ColumnIndex = 3,
        RowIndex = 3,
        Name = "PLAZA CENTRAL (Plaza General San Martín)",
        Bounds = { Min = { X = 20, Y = 11, Z = -230 }, Max = { X = 130, Y = 18, Z = -20 } },
        Center = { X = 75, Y = 11, Z = -125 },
        ElevationY = 11,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.10,
            PetrifiedTreeCount = 18,
            ConcreteLightPoleCount = 4,
            BleachedSaltCrustLevel = 35,
            PrimaryStyle = "Neoclassical",
        },
        HistoricalOccupants = { "Monumento Central", "Mástil de la Bandera", "Pérgola Ornamental", "Cartel 'Ud. Está Aquí'" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R3_C4",
        ColumnIndex = 4,
        RowIndex = 3,
        Name = "Manzana Termas y Balneario Integral",
        Bounds = { Min = { X = 170, Y = 11, Z = -230 }, Max = { X = 280, Y = 28, Z = -20 } },
        Center = { X = 225, Y = 11, Z = -125 },
        ElevationY = 11,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.45,
            PetrifiedTreeCount = 8,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 35,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Termas Centrales y Baños Termales", "Hotel Royal", "Peluquería Central" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R3_C5",
        ColumnIndex = 5,
        RowIndex = 3,
        Name = "MANZANA HOTEL MONTE REAL (Epicentro)",
        Bounds = { Min = { X = 320, Y = 10, Z = -240 }, Max = { X = 440, Y = 38, Z = -160 } },
        Center = { X = 380, Y = 10, Z = -200 },
        ElevationY = 10,
        RuinsProfile = {
            RubbleDensity = "ImpassableCore",
            WallCollapseRatio = 0.30,
            PetrifiedTreeCount = 8,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 35,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Residencial Monte Real (Edificio Principal de 2 plantas)", "Sala de Calderas", "Conserjería" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R3_C6",
        ColumnIndex = 6,
        RowIndex = 3,
        Name = "Manzana Hotel Venecia",
        Bounds = { Min = { X = 470, Y = 9, Z = -230 }, Max = { X = 580, Y = 24, Z = -20 } },
        Center = { X = 525, Y = 9, Z = -125 },
        ElevationY = 9,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.60,
            PetrifiedTreeCount = 10,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 40,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hotel Venecia", "Hospedaje Belgrano" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R3_C7",
        ColumnIndex = 7,
        RowIndex = 3,
        Name = "Manzana Salitral Este 3",
        Bounds = { Min = { X = 620, Y = 8, Z = -230 }, Max = { X = 730, Y = 16, Z = -20 } },
        Center = { X = 675, Y = 8, Z = -125 },
        ElevationY = 8,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.95,
            PetrifiedTreeCount = 16,
            ConcreteLightPoleCount = 0,
            BleachedSaltCrustLevel = 50,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Estructuras agropecuarias derruidas" },
        HasSearchableInterior = false,
    },

    -- Row 4 (Mitre to Rivadavia, Elevation Y: 7-9 studs - South Fringe Transition)
    {
        Id = "BLK_R4_C1",
        ColumnIndex = 1,
        RowIndex = 4,
        Name = "Manzana Cervecería y Rambla Oeste",
        Bounds = { Min = { X = -300, Y = 9, Z = 20 }, Max = { X = -180, Y = 22, Z = 180 } },
        Center = { X = -240, Y = 9, Z = 100 },
        ElevationY = 9,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.55,
            PetrifiedTreeCount = 6,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 42,
            PrimaryStyle = "CommercialRow",
        },
        HistoricalOccupants = { "Cervecería Munich", "Pizzería Las Ramblas" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R4_C2",
        ColumnIndex = 2,
        RowIndex = 4,
        Name = "Manzana Parroquia e Iglesia de Epecuén",
        Bounds = { Min = { X = -140, Y = 8, Z = 20 }, Max = { X = -20, Y = 48, Z = 180 } },
        Center = { X = -80, Y = 8, Z = 100 },
        ElevationY = 8,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.40,
            PetrifiedTreeCount = 8,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 45,
            PrimaryStyle = "Neoclassical",
        },
        HistoricalOccupants = { "Iglesia Parroquial Nuestra Señora del Carmen", "Casa Parroquial", "Salón de Caritas" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R4_C3",
        ColumnIndex = 3,
        RowIndex = 4,
        Name = "Manzana Hotel Las Palmeras",
        Bounds = { Min = { X = 20, Y = 7, Z = 20 }, Max = { X = 130, Y = 22, Z = 180 } },
        Center = { X = 75, Y = 7, Z = 100 },
        ElevationY = 7,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.65,
            PetrifiedTreeCount = 12,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 48,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hotel Las Palmeras", "Pileta Termal descubierta" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R4_C4",
        ColumnIndex = 4,
        RowIndex = 4,
        Name = "Manzana Balneario Este 1",
        Bounds = { Min = { X = 170, Y = 6, Z = 20 }, Max = { X = 280, Y = 20, Z = 180 } },
        Center = { X = 225, Y = 6, Z = 100 },
        ElevationY = 6,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.70,
            PetrifiedTreeCount = 10,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 55,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Hotel Horizonte", "Pensión Primavera" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R4_C5",
        ColumnIndex = 5,
        RowIndex = 4,
        Name = "Manzana Balneario Este 2",
        Bounds = { Min = { X = 320, Y = 5, Z = 20 }, Max = { X = 430, Y = 18, Z = 180 } },
        Center = { X = 375, Y = 5, Z = 100 },
        ElevationY = 5,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.75,
            PetrifiedTreeCount = 11,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 60,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Casas de alquiler veraniego" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R4_C6",
        ColumnIndex = 6,
        RowIndex = 4,
        Name = "Manzana Salitral Costero Este 1",
        Bounds = { Min = { X = 470, Y = 4, Z = 20 }, Max = { X = 580, Y = 16, Z = 180 } },
        Center = { X = 525, Y = 4, Z = 100 },
        ElevationY = 4,
        RuinsProfile = {
            RubbleDensity = "Medium",
            WallCollapseRatio = 0.85,
            PetrifiedTreeCount = 14,
            ConcreteLightPoleCount = 0,
            BleachedSaltCrustLevel = 65,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Bungalows inundables" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R4_C7",
        ColumnIndex = 7,
        RowIndex = 4,
        Name = "Manzana Salitral Costero Este 2",
        Bounds = { Min = { X = 620, Y = 3, Z = 20 }, Max = { X = 730, Y = 14, Z = 180 } },
        Center = { X = 675, Y = 3, Z = 100 },
        ElevationY = 3,
        RuinsProfile = {
            RubbleDensity = "Sparse",
            WallCollapseRatio = 0.95,
            PetrifiedTreeCount = 18,
            ConcreteLightPoleCount = 0,
            BleachedSaltCrustLevel = 75,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Planicie de salitre y fango" },
        HasSearchableInterior = false,
    },

    -- Row 5 & 6 (Victoria & Alsina / Costanera - Severe Submergence Zone, Elevation Y: 0-4 studs)
    {
        Id = "BLK_R5_COSTANERA_WEST",
        ColumnIndex = 1,
        RowIndex = 5,
        Name = "Manzana Costanera Balnearia Oeste",
        Bounds = { Min = { X = -300, Y = 2, Z = 220 }, Max = { X = -180, Y = 12, Z = 470 } },
        Center = { X = -240, Y = 2, Z = 345 },
        ElevationY = 2,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.80,
            PetrifiedTreeCount = 16,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 85,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Balneario Municipal Oeste", "Vestuarios y Duchas de Agua Dulce" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R5_DARSENA_PROMENADE",
        ColumnIndex = 2,
        RowIndex = 5,
        Name = "Manzana Espigón y Dársena Central",
        Bounds = { Min = { X = -140, Y = 1, Z = 220 }, Max = { X = -20, Y = 14, Z = 470 } },
        Center = { X = -80, Y = 1, Z = 345 },
        ElevationY = 1,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.70,
            PetrifiedTreeCount = 14,
            ConcreteLightPoleCount = 2,
            BleachedSaltCrustLevel = 90,
            PrimaryStyle = "Neoclassical",
        },
        HistoricalOccupants = { "Confitería La Dársena", "Muelle de Embarcaciones a Motor" },
        HasSearchableInterior = true,
    },
    {
        Id = "BLK_R5_COSTANERA_CENTRAL",
        ColumnIndex = 3,
        RowIndex = 5,
        Name = "Manzana Piletas Saladas Costanera",
        Bounds = { Min = { X = 20, Y = 1, Z = 220 }, Max = { X = 130, Y = 10, Z = 470 } },
        Center = { X = 75, Y = 1, Z = 345 },
        ElevationY = 1,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.85,
            PetrifiedTreeCount = 12,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 95,
            PrimaryStyle = "ThermalSpa",
        },
        HistoricalOccupants = { "Piletas Olímpicas de Salmuera Concentrada", "Casetas de Bañistas" },
        HasSearchableInterior = false,
    },
    {
        Id = "BLK_R5_SOUTHEAST_RUINS",
        ColumnIndex = 4,
        RowIndex = 5,
        Name = "Manzana Sureste Inundada",
        Bounds = { Min = { X = 170, Y = 0, Z = 220 }, Max = { X = 450, Y = 8, Z = 470 } },
        Center = { X = 310, Y = 1, Z = 345 },
        ElevationY = 1,
        RuinsProfile = {
            RubbleDensity = "Dense",
            WallCollapseRatio = 0.90,
            PetrifiedTreeCount = 20,
            ConcreteLightPoleCount = 1,
            BleachedSaltCrustLevel = 100,
            PrimaryStyle = "RuralResidential",
        },
        HistoricalOccupants = { "Estructuras residenciales completamente tapadas por fango salino" },
        HasSearchableInterior = false,
    },
} :: { UrbanBlock }

-- 6. LAGOON SHORELINE, CHANNELS & FLOODED CANALS
EpecuenMapSpecification.WaterBodies = {
    -- The Great Brine Sea: Laguna Epecuén
    {
        Id = "WATER_LAGUNA_EPECUEN",
        Name = "Laguna Epecuén (Mar Interior Hipersalino)",
        Bounds = {
            Min = { X = -1200, Y = -8, Z = 490 },
            Max = { X = 1500, Y = 0, Z = 1100 },
        },
        WaterLevelY = 0.0,
        FlowDirection = { X = 0.0, Z = -1.0 }, -- Surge flows North during gales
        IsCausticBrine = true,
        SalinityToxicityRate = 3.5, -- Toxic burn to bare skin / damaged sanity
        MovementSpeedPenalty = 0.45,
        VisualTurbidity = "CrystalSalt",
    },

    -- Flooded Channel: Lower Avenida de Mayo
    {
        Id = "CHANNEL_MAYO_INLET",
        Name = "Canal de Inundación Avenida de Mayo",
        Bounds = {
            Min = { X = -184, Y = -3, Z = 380 },
            Max = { X = -136, Y = 0, Z = 520 },
        },
        WaterLevelY = 0.0,
        FlowDirection = { X = 0.0, Z = 1.0 },
        IsCausticBrine = true,
        SalinityToxicityRate = 2.0,
        MovementSpeedPenalty = 0.35,
        VisualTurbidity = "MurkyBrine",
    },

    -- Flooded Channel: Eastern Littoral Bay
    {
        Id = "CHANNEL_EAST_LITTORAL",
        Name = "Marisma y Salitral del Este",
        Bounds = {
            Min = { X = 500, Y = -4, Z = 260 },
            Max = { X = 850, Y = 0, Z = 550 },
        },
        WaterLevelY = 0.0,
        FlowDirection = { X = -0.5, Z = 0.5 },
        IsCausticBrine = true,
        SalinityToxicityRate = 3.0,
        MovementSpeedPenalty = 0.50,
        VisualTurbidity = "BlackAlgaeSilt",
    },

    -- Flooded Channel: Southwestern Necropolis Marsh
    {
        Id = "CHANNEL_WEST_CEMETERY_MARSH",
        Name = "Bofedal del Cementerio Inundado",
        Bounds = {
            Min = { X = -800, Y = -4, Z = 350 },
            Max = { X = -350, Y = 0, Z = 650 },
        },
        WaterLevelY = 0.0,
        FlowDirection = { X = 0.7, Z = -0.3 },
        IsCausticBrine = true,
        SalinityToxicityRate = 4.0,
        MovementSpeedPenalty = 0.55,
        VisualTurbidity = "BlackAlgaeSilt",
    },
} :: { WaterChannel }

-- 7. GEOGRAPHIC ZONES & PERIPHERIES
EpecuenMapSpecification.Zones = {
    -- 1. Northern Ingress & Vehicle Area
    {
        Id = "ZONE_NORTH_ENTRANCE",
        Name = "Acceso Norte / Puesto de Guardia",
        Category = "RuralAccess",
        Bounds = {
            Min = { X = -350, Y = 15, Z = -950 },
            Max = { X = 50, Y = 35, Z = -700 },
        },
        Center = { X = -150, Y = 20, Z = -820 },
        ElevationRange = { Min = 18, Max = 24 },
        SalinityHazardLevel = 0,
        ThreatLevel = "Low",
        AcousticProfile = "OpenWind",
        Description = "Dry elevated ground on the edge of the pampas. The player starts here beside the disabled Fiat Cronos.",
        NorthOf = "Open highway toward Carhué",
        SouthOf = "ZONE_CIVIC_INSTITUTIONAL",
        EastOf = "ZONE_RESIDENTIAL_EAST",
        WestOf = "Western agricultural pastures",
    },

    -- 2. Civic & Institutional Quarter
    {
        Id = "ZONE_CIVIC_INSTITUTIONAL",
        Name = "Barrio Cívico e Institucional",
        Category = "TransitDepot",
        Bounds = {
            Min = { X = -320, Y = 14, Z = -700 },
            Max = { X = 150, Y = 30, Z = -450 },
        },
        Center = { X = -85, Y = 17, Z = -575 },
        ElevationRange = { Min = 15, Max = 18 },
        SalinityHazardLevel = 5,
        ThreatLevel = "Medium",
        AcousticProfile = "EchoingConcrete",
        Description = "Transit hub with bus depot, police post, school, and municipal storage yards. Abundant automotive salvage.",
        NorthOf = "ZONE_NORTH_ENTRANCE",
        SouthOf = "ZONE_CENTRAL_TOWN",
        EastOf = "ZONE_RESIDENTIAL_EAST",
        WestOf = "ZONE_RADIAL_PARKS",
    },

    -- 3. Central Town & Commercial Grid
    {
        Id = "ZONE_CENTRAL_TOWN",
        Name = "Centro Urbano y Comercial",
        Category = "UrbanGrid",
        Bounds = {
            Min = { X = -320, Y = 8, Z = -450 },
            Max = { X = 300, Y = 25, Z = 0 },
        },
        Center = { X = -10, Y = 12, Z = -225 },
        ElevationRange = { Min = 10, Max = 15 },
        SalinityHazardLevel = 15,
        ThreatLevel = "Medium",
        AcousticProfile = "EchoingConcrete",
        Description = "Dense orthogonal grid of shops, bakeries, bowling theater, and boarding houses. Narrow streets with debris chokepoints.",
        NorthOf = "ZONE_CIVIC_INSTITUTIONAL",
        SouthOf = "ZONE_CIVIC_PLAZA",
        EastOf = "ZONE_HOTEL_MONTE_REAL",
        WestOf = "ZONE_RADIAL_PARKS",
    },

    -- 4. Plaza Central "Ud. Está Aquí"
    {
        Id = "ZONE_CIVIC_PLAZA",
        Name = "Plaza Central General San Martín",
        Category = "CivicCenter",
        Bounds = {
            Min = { X = 0, Y = 9, Z = -250 },
            Max = { X = 150, Y = 22, Z = 0 },
        },
        Center = { X = 75, Y = 11, Z = -125 },
        ElevationRange = { Min = 10, Max = 12 },
        SalinityHazardLevel = 20,
        ThreatLevel = "Medium",
        AcousticProfile = "MuffledFog",
        Description = "Civic heart of Epecuén with the famous 'Ud. Está Aquí' orientation placard, broken concrete pergolas, and flagpole base.",
        NorthOf = "ZONE_CENTRAL_TOWN",
        SouthOf = "ZONE_CHURCH_RUINS",
        EastOf = "ZONE_HOTEL_MONTE_REAL",
        WestOf = "Calle Cerrito & Commercial blocks",
    },

    -- 5. Hotel Monte Real Complex
    {
        Id = "ZONE_HOTEL_MONTE_REAL",
        Name = "Sector Residencial Monte Real",
        Category = "HospitalityResort",
        Bounds = {
            Min = { X = 300, Y = 8, Z = -350 },
            Max = { X = 600, Y = 45, Z = -50 },
        },
        Center = { X = 450, Y = 11, Z = -200 },
        ElevationRange = { Min = 9, Max = 13 },
        SalinityHazardLevel = 25,
        ThreatLevel = "High",
        AcousticProfile = "EchoingConcrete",
        Description = "Labyrinthine two-story luxury hotel complex with collapsed tile roofs, inner courtyards, and generator outbuilding.",
        NorthOf = "ZONE_RESIDENTIAL_EAST",
        SouthOf = "ZONE_SHORELINE",
        EastOf = "Eastern saltern plain",
        WestOf = "ZONE_CIVIC_PLAZA",
    },

    -- 6. Church Ruins of Epecuén
    {
        Id = "ZONE_CHURCH_RUINS",
        Name = "Ruinas de la Parroquia Nuestra Señora del Carmen",
        Category = "CivicCenter",
        Bounds = {
            Min = { X = -140, Y = 6, Z = 0 },
            Max = { X = 150, Y = 55, Z = 200 },
        },
        Center = { X = 5, Y = 8, Z = 100 },
        ElevationRange = { Min = 6, Max = 10 },
        SalinityHazardLevel = 35,
        ThreatLevel = "High",
        AcousticProfile = "EchoingConcrete",
        Description = "Half-collapsed parish church with intact gothic belfry tower. Offers temporary acoustic haven when bell is rung.",
        NorthOf = "ZONE_CIVIC_PLAZA",
        SouthOf = "ZONE_SHORELINE",
        EastOf = "ZONE_HOTEL_MONTE_REAL",
        WestOf = "Calle Mayo lower shops",
    },

    -- 7. Waterfront, Balneario & Shoreline
    {
        Id = "ZONE_SHORELINE",
        Name = "Costanera Balnearia y Rambla",
        Category = "ShorelineWaterfront",
        Bounds = {
            Min = { X = -400, Y = -4, Z = 380 },
            Max = { X = 800, Y = 15, Z = 600 },
        },
        Center = { X = 200, Y = 1, Z = 490 },
        ElevationRange = { Min = -2, Max = 4 },
        SalinityHazardLevel = 60,
        ThreatLevel = "High",
        AcousticProfile = "WaterSloshing",
        Description = "Waterfront promenade along Calle Alsina. Knee-deep to chest-deep caustic brine submerging piers, bathhouses, and kiosks.",
        NorthOf = "ZONE_CHURCH_RUINS & ZONE_CENTRAL_TOWN",
        SouthOf = "ZONE_DEEP_LAGOON",
        EastOf = "ZONE_MATADERO",
        WestOf = "ZONE_CEMETERY",
    },

    -- 8. Submerged Cementerio Inundado (Real Historical Site)
    {
        Id = "ZONE_CEMETERY",
        Name = "Cementerio Inundado de Epecuén",
        Category = "FloodedCemetery",
        Bounds = {
            Min = { X = -850, Y = -6, Z = 400 },
            Max = { X = -400, Y = 20, Z = 800 },
        },
        Center = { X = -620, Y = 0, Z = 600 },
        ElevationRange = { Min = -3, Max = 5 },
        SalinityHazardLevel = 75,
        ThreatLevel = "Deadly",
        AcousticProfile = "CryptEmanations",
        Description = "Eerie flooded municipal necropolis. Submerged white stone vaults, cracked mausoleums, corroded iron crosses, and exposed bone crypts protruding from caustic brine.",
        NorthOf = "ZONE_RADIAL_PARKS",
        SouthOf = "Laguna Epecuén southwest shallows",
        EastOf = "ZONE_SHORELINE",
        WestOf = "Western reedbeds and mudflats",
    },

    -- 9. El Matadero de Francisco Salamone (Peripheral Sector)
    {
        Id = "ZONE_MATADERO",
        Name = "El Matadero de Francisco Salamone",
        Category = "IndustrialSlaughterhouse",
        Bounds = {
            Min = { X = 560, Y = 5, Z = 390 },
            Max = { X = 760, Y = 80, Z = 600 },
        },
        Center = { X = 650, Y = 15, Z = 480 },
        ElevationRange = { Min = 8, Max = 22 },
        SalinityHazardLevel = 25,
        ThreatLevel = "Deadly",
        AcousticProfile = "OpenWind",
        Description = "Monumental Art Deco/Brutalist slaughterhouse with towering 70-stud blade clocktower. Standalone complex on the southeastern perimeter.",
        NorthOf = "Open salterns and eastern lagoon littoral plain",
        SouthOf = "Rural pampas perimeter and ancient cattle corrals",
        EastOf = "Laguna Epecuén southeastern basin",
        WestOf = "Calle Alsina costanera and Camino al Matadero",
    },

    -- 10. Western Radial Plazas & Petrified Forests
    {
        Id = "ZONE_RADIAL_PARKS",
        Name = "Plazas Radiales y Bosque Petrificado",
        Category = "RadialPark",
        Bounds = {
            Min = { X = -850, Y = 3, Z = -550 },
            Max = { X = -320, Y = 25, Z = 450 },
        },
        Center = { X = -580, Y = 10, Z = -50 },
        ElevationRange = { Min = 5, Max = 16 },
        SalinityHazardLevel = 35,
        ThreatLevel = "High",
        AcousticProfile = "MuffledFog",
        Description = "Geometric circular plazas and 45-degree radiant avenues filled with bleached, salt-petrified dead caldén and eucalyptus trees.",
        NorthOf = "Western agricultural pastures",
        SouthOf = "ZONE_CEMETERY",
        EastOf = "Calle Talcahuano & Central Town Grid",
        WestOf = "Outer western marshlands",
    },

    -- 11. Deep Brine Sea of Laguna Epecuén
    {
        Id = "ZONE_DEEP_LAGOON",
        Name = "Laguna Epecuén (Aguas Profundas)",
        Category = "SubmergedBrine",
        Bounds = {
            Min = { X = -1200, Y = -10, Z = 600 },
            Max = { X = 1500, Y = 0, Z = 1100 },
        },
        Center = { X = 150, Y = -4, Z = 850 },
        ElevationRange = { Min = -8, Max = 0 },
        SalinityHazardLevel = 100,
        ThreatLevel = "Deadly",
        AcousticProfile = "WaterSloshing",
        Description = "Impenetrable, caustic saline lake bed. Walking too deep results in fatal buoyancy failure and caustic lung damage.",
        NorthOf = "ZONE_SHORELINE",
        SouthOf = "Infinite brine expanse toward Carhué",
        EastOf = "Eastern marshlands",
        WestOf = "Western lagoon shallows",
    },
} :: { GeographicZone }

-- 8. IMPORTANT LANDMARKS & MONUMENTS
EpecuenMapSpecification.Landmarks = {
    {
        Id = "LMK_MATADERO",
        IndexOnMap = nil,
        Name = "El Matadero (Francisco Salamone)",
        HistoricalCategory = "Matadero Municipal / Obra de Francisco Salamone (1938)",
        Position = { X = 650, Y = 15, Z = 480 },
        FootprintStuds = { X = 140, Z = 90 },
        VerticalHeightStuds = 70,
        VisualSilhouette = "Towering 70-stud concrete blade clocktower with curved Art Deco slaughter hall; landmark beacon visible through fog.",
        GameplayRole = "Major visual landmark and expedition destination. Contains high-tier mechanical salvage and alternator.",
        FogVisibilityStuds = 350,
        HistoricalNotes = "Designed by famed architect Francisco Salamone; its brutalist tower survived the flood and acts as an orienting beacon across the southeastern ruins.",
    },
    {
        Id = "LMK_HOTEL_MONTE_REAL",
        IndexOnMap = 10,
        Name = "Residencial Monte Real",
        HistoricalCategory = "Residencial / Hotel de Lujo",
        Position = { X = 400, Y = 10, Z = -200 },
        FootprintStuds = { X = 110, Z = 75 },
        VerticalHeightStuds = 38,
        VisualSilhouette = "Two-story Mediterranean facade with arched balconies and collapsed red tile roofs.",
        GameplayRole = "Primary interior exploration maze. Houses guest rooms, office safes, and vehicle battery in maintenance room.",
        FogVisibilityStuds = 180,
        HistoricalNotes = "Premier high-end hotel accommodating thermal therapy patients and VIP guests.",
    },
    {
        Id = "LMK_IGLESIA",
        IndexOnMap = 22,
        Name = "Iglesia de Epecuén",
        HistoricalCategory = "Edificio Religioso / Parroquia",
        Position = { X = 60, Y = 8, Z = 150 },
        FootprintStuds = { X = 80, Z = 120 },
        VerticalHeightStuds = 48,
        VisualSilhouette = "Single belfry tower with gothic arched window frames and cracked altar floor.",
        GameplayRole = "Bell ringing acoustic mechanic to divert monster away; safe haven candle circles.",
        FogVisibilityStuds = 220,
        HistoricalNotes = "Central place of worship for the permanent residents and seasonal workers of the town.",
    },
    {
        Id = "LMK_CEMENTERIO",
        IndexOnMap = nil,
        Name = "Cementerio Inundado de Epecuén",
        HistoricalCategory = "Necrópolis Municipal (1920-1985)",
        Position = { X = -620, Y = 0, Z = 600 },
        FootprintStuds = { X = 180, Z = 220 },
        VerticalHeightStuds = 28,
        VisualSilhouette = "Cluster of white marble pantheons and bleached concrete crypts protruding from murky brine with rusted wrought iron crosses.",
        GameplayRole = "High-threat search zone for paranormal artifacts, keys, and cryptic lore plaques.",
        FogVisibilityStuds = 160,
        HistoricalNotes = "The cemetery was submerged during the 1985 flood, creating the haunting image of coffins floating among bleached trees.",
    },
    {
        Id = "LMK_PLAZA_MONUMENT",
        IndexOnMap = 1,
        Name = "Monumento de la Plaza Central",
        HistoricalCategory = "Monumento Cívico / Plaza San Martín",
        Position = { X = 65, Y = 11, Z = -140 },
        FootprintStuds = { X = 25, Z = 25 },
        VerticalHeightStuds = 22,
        VisualSilhouette = "Broken obelisk on octagonal stepped marble dais with dried ornamental fountain ring.",
        GameplayRole = "Central map orientation node ('Ud. Está Aquí'). Safe zone with ambient lantern light.",
        FogVisibilityStuds = 140,
        HistoricalNotes = "Focal gathering point of Villa Epecuén where tourists posed for commemorative postcard photographs.",
    },
    {
        Id = "LMK_DARSENA_CENTRAL",
        IndexOnMap = 30,
        Name = "Dársena Central y Rambla Sur",
        HistoricalCategory = "Instalación Portuaria / Balneario",
        Position = { X = -160, Y = 0, Z = 620 },
        FootprintStuds = { X = 70, Z = 160 },
        VerticalHeightStuds = 14,
        VisualSilhouette = "U-shaped concrete pier reaching deep into dark brine with rusted handrails and navigation light pylon.",
        GameplayRole = "Water-hazard expedition challenge. Location of spark plugs box at the pier tip.",
        FogVisibilityStuds = 190,
        HistoricalNotes = "Departure jetty for rowboats and motor launches cruising the hyper-saline waters of Laguna Epecuén.",
    },
    {
        Id = "LMK_TERMINAL_OMNIBUS",
        IndexOnMap = 4,
        Name = "Terminal de Ómnibus Epecuén",
        HistoricalCategory = "Transporte Automotor",
        Position = { X = -140, Y = 18, Z = -650 },
        FootprintStuds = { X = 90, Z = 60 },
        VerticalHeightStuds = 24,
        VisualSilhouette = "Curved corrugated roof canopy resting on rusted steel girders with stranded intercity coach bus.",
        GameplayRole = "Early game fuel siphoning puzzle. Fuel canister search zone.",
        FogVisibilityStuds = 150,
        HistoricalNotes = "Point of arrival for the thousands of seasonal bathers arriving every summer from Buenos Aires and Bahía Blanca.",
    },
    {
        Id = "LMK_CORRALON_MUNICIPAL",
        IndexOnMap = 28,
        Name = "Corralón y Taller Municipal",
        HistoricalCategory = "Depósito de Infraestructura",
        Position = { X = -280, Y = 17, Z = -670 },
        FootprintStuds = { X = 80, Z = 90 },
        VerticalHeightStuds = 20,
        VisualSilhouette = "Walled yard with rusted machinery, steamrollers, and reinforced corrugated steel workshops.",
        GameplayRole = "Heavy mechanical salvage. Radiator hose search zone.",
        FogVisibilityStuds = 130,
        HistoricalNotes = "Base of operations for municipal workers who desperately built the earthen dykes in November 1985.",
    },
    {
        Id = "LMK_HOTEL_COLONIA_FERROVIARIA",
        IndexOnMap = 3,
        Name = "Hotel Colonia Ferroviaria",
        HistoricalCategory = "Complejo Social / Sindicato Ferroviario",
        Position = { X = 75, Y = 16, Z = -580 },
        FootprintStuds = { X = 120, Z = 80 },
        VerticalHeightStuds = 32,
        VisualSilhouette = "Three-story brick building with collapsed center floorboards and prominent entrance arch.",
        GameplayRole = "Multi-level vertical exploration; vantage point over the northern streets.",
        FogVisibilityStuds = 200,
        HistoricalNotes = "Trade union holiday colony where hundreds of railway worker families spent thermal vacations.",
    },
    {
        Id = "LMK_TERMAS_CENTRALES",
        IndexOnMap = 14,
        Name = "Balneario y Termas Centrales",
        HistoricalCategory = "Centro Hidrotermal",
        Position = { X = 225, Y = 11, Z = -150 },
        FootprintStuds = { X = 90, Z = 100 },
        VerticalHeightStuds = 26,
        VisualSilhouette = "Tiled thermal pools surrounded by shattered glass skylights and calcified pipe networks.",
        GameplayRole = "Puzzle area with valve mechanics and mineral mud samples for healing.",
        FogVisibilityStuds = 160,
        HistoricalNotes = "Famous medicinal spa boasting that its water had ten times the mineral density of the ocean.",
    },
    {
        Id = "LMK_TEATRO_BOWLING",
        IndexOnMap = 17,
        Name = "Teatro y Confitería Bowling",
        HistoricalCategory = "Centro Social y Recreativo",
        Position = { X = -240, Y = 12, Z = -130 },
        FootprintStuds = { X = 95, Z = 70 },
        VerticalHeightStuds = 30,
        VisualSilhouette = "Streamline Moderne facade with vertical neon signage brackets and collapsed dance floor.",
        GameplayRole = "Acoustic hazard area: fragile glassware and rotted floorboards that creak loudly.",
        FogVisibilityStuds = 170,
        HistoricalNotes = "Nightlife epicenter of the resort town where tangos and jazz orchestras played during peak season.",
    },
    {
        Id = "LMK_CASTILLO",
        IndexOnMap = 35,
        Name = "El Castillo de Epecuén",
        HistoricalCategory = "Mansión Aristocrática (Chalet de estilo francés)",
        Position = { X = -500, Y = 12, Z = -200 },
        FootprintStuds = { X = 75, Z = 75 },
        VerticalHeightStuds = 42,
        VisualSilhouette = "Ornate conical turret with weathered slate mansard roof rising above bleached petrified trees.",
        GameplayRole = "High-tier safehouse containing historical diaries, maps, and flare gun ammunition.",
        FogVisibilityStuds = 210,
        HistoricalNotes = "Sumptuous private summer residence built by French noblewoman Ernestina María Le Brun in the 1920s.",
    },
} :: { Landmark }

-- 9. CAR PART SEARCH ZONES (FIVE CRITICAL OBJECTIVES)
EpecuenMapSpecification.CarPartSearchZones = {
    -- 1. Heavy 12V Battery
    {
        PartType = "Battery",
        ItemName = "Batería de Plomo 12V 75Ah",
        ZoneId = "ZONE_HOTEL_MONTE_REAL",
        LandmarkAnchor = "LMK_HOTEL_MONTE_REAL",
        SearchRadiusStuds = 60,
        ApproximatePosition = { X = 410, Y = 11, Z = -190 },
        EnvironmentalHazard = "Pisos superiores inestables y derrumbes de mampostería.",
        PuzzleOrThreat = "Ubicada en el cuarto de generadores traseros del hotel. Requiere llave de conserjería o palanca.",
        LoreHint = "El viejo conserje del Monte Real guardaba baterías de repuesto para el generador de emergencia durante las tormentas de 1985.",
    },

    -- 2. Heavy Alternator
    {
        PartType = "Alternator",
        ItemName = "Alternador de Carga 14V",
        ZoneId = "ZONE_MATADERO",
        LandmarkAnchor = "LMK_MATADERO",
        SearchRadiusStuds = 80,
        ApproximatePosition = { X = 665, Y = 16, Z = 495 },
        EnvironmentalHazard = "Viento aullante y eco distante de cadenas oxidadas. Refugio de El Vigilante.",
        PuzzleOrThreat = "Montado en el motor diésel de la sala de enfriamiento del Matadero Salamone.",
        LoreHint = "En el Matadero aún quedan maquinarias industriales con alternadores intactos en la sala de faena.",
    },

    -- 3. Set of Spark Plugs
    {
        PartType = "SparkPlugs",
        ItemName = "Juego de Bujías de Encendido",
        ZoneId = "ZONE_SHORELINE",
        LandmarkAnchor = "LMK_DARSENA_CENTRAL",
        SearchRadiusStuds = 50,
        ApproximatePosition = { X = -160, Y = -1, Z = 700 },
        EnvironmentalHazard = "Agua hipersalina cáustica y niebla espesa; reduce velocidad de movimiento un 45%.",
        PuzzleOrThreat = "Dentro de una caja de herramientas estanca abandonada en la punta del espigón en U.",
        LoreHint = "Un mecánico del balneario intentó reparar una lancha de rescate en el muelle antes de que el agua tapara la rambla.",
    },

    -- 4. Fuel Canister (Nafta 20L)
    {
        PartType = "FuelCanister",
        ItemName = "Bidón de Nafta 20L",
        ZoneId = "ZONE_NORTH_ENTRANCE",
        LandmarkAnchor = "LMK_TERMINAL_OMNIBUS",
        SearchRadiusStuds = 70,
        ApproximatePosition = { X = -120, Y = 18, Z = -670 },
        EnvironmentalHazard = "Humo tóxico de tanques fermentados y cristales rotos que delatan pasos.",
        PuzzleOrThreat = "Sifonar combustible del tanque de un micro de larga distancia varado en la dársena.",
        LoreHint = "Los últimos micros de evacuación quedaron estacionados en la terminal con tanques llenos.",
    },

    -- 5. Radiator Reinforced Hose
    {
        PartType = "RadiatorHose",
        ItemName = "Manguera Reforzada de Refrigerante",
        ZoneId = "ZONE_NORTH_ENTRANCE",
        LandmarkAnchor = "LMK_CORRALON_MUNICIPAL",
        SearchRadiusStuds = 55,
        ApproximatePosition = { X = -275, Y = 17, Z = -690 },
        EnvironmentalHazard = "Portones de chapa batientes que hacen ruido metálico con el viento.",
        PuzzleOrThreat = "Extraer manguera de alta presión de una bomba centrífuga de desagote municipal.",
        LoreHint = "Las bombas de achique abandonadas en el corralón municipal tienen mangueras de goma sintética intactas.",
    },
} :: { CarPartSearchZone }

-- 10. LOCATIONS SUITABLE FOR PARANORMAL & HORROR EVENTS
EpecuenMapSpecification.ParanormalAnchors = {
    {
        Id = "EVT_CHURCH_BELL",
        EventType = "SubmergedBellChime",
        Position = { X = 60, Y = 28, Z = 150 },
        TriggerRadiusStuds = 90,
        SanityImpact = 15,
        CooldownSeconds = 120,
        VisualCueDescription = "La campana de bronce oxidada del campanario oscila sola entre la niebla espesa.",
        AudioCueDescription = "Eco metálico sordo y fúnebre que resuena por toda la cuadrícula urbana.",
    },
    {
        Id = "EVT_MONTE_REAL_PIANO",
        EventType = "PianoEchoInHotelRuins",
        Position = { X = 400, Y = 14, Z = -200 },
        TriggerRadiusStuds = 70,
        SanityImpact = 20,
        CooldownSeconds = 180,
        VisualCueDescription = "Teclas rotas de un piano de cola bajo escombros vibrando con polvo de cal.",
        AudioCueDescription = "Notas disonantes de un vals lento de 1940 tocado con cuerdas desafinadas por la salitre.",
    },
    {
        Id = "EVT_CEMETERY_WHISPERS",
        EventType = "CryptVaultWhispers",
        Position = { X = -620, Y = 3, Z = 600 },
        TriggerRadiusStuds = 85,
        SanityImpact = 25,
        CooldownSeconds = 90,
        VisualCueDescription = "Agua burbujeando alrededor de sarcófagos de mármol blanco agrietados.",
        AudioCueDescription = "Murmullos en múltiples voces rezando el rosario en español antiguo.",
    },
    {
        Id = "EVT_MATADERO_CHAINS",
        EventType = "SlaughterhouseChainRattle",
        Position = { X = 650, Y = 18, Z = 480 },
        TriggerRadiusStuds = 100,
        SanityImpact = 30,
        CooldownSeconds = 150,
        VisualCueDescription = "Ganchos de carnicería oxidados balanceándose en rieles aéreos en penumbra.",
        AudioCueDescription = "Arrastre de cadenas pesadas de hierro sobre losas de hormigón mojadas.",
    },
    {
        Id = "EVT_SHORELINE_FOOTSTEPS",
        EventType = "PhantomFootstepsInBrine",
        Position = { X = -160, Y = 1, Z = 550 },
        TriggerRadiusStuds = 65,
        SanityImpact = 15,
        CooldownSeconds = 75,
        VisualCueDescription = "Ondas circulares en el agua salada sin ningún cuerpo visible que las produzca.",
        AudioCueDescription = "Chapoteo rítmico de pasos acelerados que se acercan desde la oscuridad del lago.",
    },
    {
        Id = "EVT_PLAZA_CROSSWALK_SHADOW",
        EventType = "ShadowSilhouetteCrosswalk",
        Position = { X = 75, Y = 11, Z = -125 },
        TriggerRadiusStuds = 80,
        SanityImpact = 20,
        CooldownSeconds = 140,
        VisualCueDescription = "Silueta humana alargada y petrificada proyectada contra la pérgola de la plaza.",
        AudioCueDescription = "Susurro agudo que corta el viento pampeano.",
    },
    {
        Id = "EVT_TERMINAL_LIGHT_FLICKER",
        EventType = "StreetlightFlickerBurst",
        Position = { X = -140, Y = 22, Z = -650 },
        TriggerRadiusStuds = 60,
        SanityImpact = 10,
        CooldownSeconds = 60,
        VisualCueDescription = "Lámpara de vapor de mercurio de la terminal chisporroteando con luz violácea.",
        AudioCueDescription = "Zumbido eléctrico de 50Hz y estallido sordo de filamento.",
    },
} :: { ParanormalAnchor }

-- 11. PROCEDURAL CONSTRUCTION GUIDELINES (FOR MAP GENERATORS)
EpecuenMapSpecification.ProceduralDensities = {
    UrbanCenter = {
        DebrisPilesPer100StudsSq = 4.5,
        DeadCalamiteTreesPer100StudsSq = 3.0,
        CorrugatedMetalSheetsPer100StudsSq = 2.5,
        SaltEncrustedMoundsPer100StudsSq = 5.0,
        SubmergedFurniturePer100StudsSq = 1.8,
    },
    WaterfrontShoreline = {
        DebrisPilesPer100StudsSq = 6.0,
        DeadCalamiteTreesPer100StudsSq = 8.5,
        CorrugatedMetalSheetsPer100StudsSq = 3.5,
        SaltEncrustedMoundsPer100StudsSq = 12.0,
        SubmergedFurniturePer100StudsSq = 4.0,
    },
    RadialParks = {
        DebrisPilesPer100StudsSq = 1.5,
        DeadCalamiteTreesPer100StudsSq = 14.0, -- Thick bleached forest
        CorrugatedMetalSheetsPer100StudsSq = 0.5,
        SaltEncrustedMoundsPer100StudsSq = 8.0,
        SubmergedFurniturePer100StudsSq = 0.2,
    },
    Cemetery = {
        DebrisPilesPer100StudsSq = 7.0,
        DeadCalamiteTreesPer100StudsSq = 9.0,
        CorrugatedMetalSheetsPer100StudsSq = 1.0,
        SaltEncrustedMoundsPer100StudsSq = 15.0,
        SubmergedFurniturePer100StudsSq = 6.0, -- Coffins / gravestones
    },
    Slaughterhouse = {
        DebrisPilesPer100StudsSq = 3.0,
        DeadCalamiteTreesPer100StudsSq = 2.0,
        CorrugatedMetalSheetsPer100StudsSq = 5.0,
        SaltEncrustedMoundsPer100StudsSq = 4.0,
        SubmergedFurniturePer100StudsSq = 3.5, -- Industrial iron hooks / chains
    },
} :: { [string]: ProceduralPropDensity }

return EpecuenMapSpecification
