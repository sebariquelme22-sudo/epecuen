--!strict
--[[
    EpecuenMapSpecification.luau
    Master Geographic & Spatial Specification for "EPECUÉN: NO ESCAPE"
    
    Source Reference: Historical Municipal Tourist Plan ("Plano - Villa Turística Lago Epecuén")
    Municipalidad de Adolfo Alsina - Dirección de Turismo (lago-epecuen.jpg)
    
    Coordinate System (Roblox Studs, 1 stud ≈ 0.28m):
      Origin (0, 0, 0): Central Plaza ("Ud. Está Aquí") at Calle Cerrito & Calle Mitre
      +X: East (toward Calle Florida, Eastern Littoral Basin, and El Matadero)
      -X: West (toward Western Radial Plazas and Talcahuano)
      +Z: South (toward Calle Alsina, Shoreline Pier, and Laguna Epecuén)
      -Z: North (toward Terminal de Ómnibus, School, and Carhué Access Road)
      +Y: Elevation (Pampas high ground +20 studs -> Lakebed brine -8 studs)
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
    IsPaved: boolean, -- Matches green "Pavimento" marking on master map
    WidthStuds: number,
    StartPos: Vector3D,
    EndPos: Vector3D,
    Description: string,
}

export type Intersection = {
    Id: string,
    StreetA: string,
    StreetB: string,
    Position: Vector3D,
    IsPavedCrossroad: boolean,
    TacticalNote: string,
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
    SalinityHazardLevel: number, -- 0 (dry) to 100 (caustic hypersaline flood)
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
    IndexOnMap: number?, -- Number identifier on the municipal tourist map
    Name: string,
    HistoricalCategory: string,
    Position: Vector3D,
    FootprintStuds: Vector2D,
    VerticalHeightStuds: number,
    VisualSilhouette: string,
    GameplayRole: string,
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

export type VehicleSpawnPoint = {
    Name: string,
    Position: Vector3D,
    RotationY: number,
    Status: "Disabled" | "Repairable",
    MissingParts: { CarPartType },
    Description: string,
}

export type PlayerSpawnPoint = {
    Id: string,
    Name: string,
    Position: Vector3D,
    FacingAngleY: number,
    ProximityToVehicleStuds: number,
    InitialNarrative: string,
}

export type PointOfInterest = {
    Id: string,
    Name: string,
    Position: Vector3D,
    Type: "SafeHaven" | "LootCache" | "ObservationPerch" | "AcousticTrap" | "DeadEnd",
    RiskRewardRatio: string,
    Details: string,
}

-- ============================================================================
-- MASTER SPECIFICATION TABLE
-- ============================================================================

local EpecuenMapSpecification = {}

-- 1. WORLD BOUNDS (Playable Realm Dimensions in Roblox Studs)
EpecuenMapSpecification.WorldBounds = {
    Min = { X = -1400, Y = -20, Z = -950 } :: Vector3D,
    Max = { X = 1300, Y = 100, Z = 1100 } :: Vector3D,
    Center = { X = 0, Y = 5, Z = 0 } :: Vector3D,
    TotalWidthStuds = 2700,
    TotalLengthStuds = 2050,
    MetricApproximation = "approx. 750m East-West by 575m North-South (1 stud ≈ 0.28m)",
}

-- 2. MAIN STREETS AND AVENUES
EpecuenMapSpecification.Streets = {
    -- North-South Avenues (West to East)
    {
        Id = "ST_TALCAHUANO",
        Name = "Calle Talcahuano",
        HistoricalName = "Talcahuano",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 32,
        StartPos = { X = -320, Y = 15, Z = -650 },
        EndPos = { X = -320, Y = 3, Z = 500 },
        Description = "Western boundary of the central grid; divides orthogonal streets from the radial geometric parks.",
    },
    {
        Id = "AV_DE_MAYO",
        Name = "Avenida de Mayo",
        HistoricalName = "Av. de Mayo",
        Orientation = "NorthSouth",
        IsPaved = true, -- Marked as Pavimento on map
        WidthStuds = 48,
        StartPos = { X = -160, Y = 16, Z = -700 },
        EndPos = { X = -160, Y = -2, Z = 720 },
        Description = "Grand paved central boulevard; cuts through town directly into the U-shaped lake pier.",
    },
    {
        Id = "ST_CERRITO",
        Name = "Calle Cerrito",
        HistoricalName = "Cerrito",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 30,
        StartPos = { X = 0, Y = 14, Z = -650 },
        EndPos = { X = 0, Y = 2, Z = 500 },
        Description = "Flanks the western edge of the Central Plaza and major thermal hotels.",
    },
    {
        Id = "ST_PELLEGRINI",
        Name = "Calle Pellegrini",
        HistoricalName = "Pellegrini",
        Orientation = "NorthSouth",
        IsPaved = true, -- Marked as Pavimento on map
        WidthStuds = 36,
        StartPos = { X = 150, Y = 14, Z = -650 },
        EndPos = { X = 150, Y = 2, Z = 500 },
        Description = "Paved eastern boundary of the Central Plaza; major transit corridor for tourist buses.",
    },
    {
        Id = "ST_SUIPACHA",
        Name = "Calle Suipacha",
        HistoricalName = "Suipacha",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 300, Y = 12, Z = -650 },
        EndPos = { X = 300, Y = 3, Z = 450 },
        Description = "Intermediate corridor passing through the primary resort hotel and thermal spa clusters.",
    },
    {
        Id = "ST_ESMERALDA",
        Name = "Calle Esmeralda",
        HistoricalName = "Esmeralda",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 450, Y = 11, Z = -650 },
        EndPos = { X = 450, Y = 4, Z = 350 },
        Description = "Eastern hotel street running alongside Residencial Monte Real and residential pensions.",
    },
    {
        Id = "ST_MAIPU",
        Name = "Calle Maipú",
        HistoricalName = "Maipú",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 600, Y = 10, Z = -650 },
        EndPos = { X = 600, Y = 4, Z = 250 },
        Description = "Outer eastern residential avenue terminating near the curving shoreline of the lagoon.",
    },
    {
        Id = "ST_FLORIDA",
        Name = "Calle Florida",
        HistoricalName = "Florida",
        Orientation = "NorthSouth",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = 750, Y = 10, Z = -650 },
        EndPos = { X = 750, Y = 3, Z = 150 },
        Description = "Easternmost street on the municipal plan, bordering open salterns and eastern flood plains.",
    },

    -- East-West Streets (North to South)
    {
        Id = "RD_NORTH_ACCESS",
        Name = "Ruta Norte / Acceso Carhué",
        HistoricalName = "Camino a Carhué / Acceso Norte",
        Orientation = "EastWest",
        IsPaved = true,
        WidthStuds = 36,
        StartPos = { X = -750, Y = 20, Z = -750 },
        EndPos = { X = 850, Y = 18, Z = -750 },
        Description = "High-elevation northern thoroughfare connecting Terminal de Ómnibus, Corralón, and the road to Carhué.",
    },
    {
        Id = "ST_SARMIENTO",
        Name = "Calle Sarmiento",
        HistoricalName = "Sarmiento",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 30,
        StartPos = { X = -750, Y = 16, Z = -450 },
        EndPos = { X = 750, Y = 14, Z = -450 },
        Description = "Traverses northern circular radial park on the west and the central town school block.",
    },
    {
        Id = "ST_CANGALLO",
        Name = "Calle Cangallo",
        HistoricalName = "Cangallo",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -750, Y = 14, Z = -250 },
        EndPos = { X = 750, Y = 12, Z = -250 },
        Description = "Intermediate street between northern public amenities and central commercial square.",
    },
    {
        Id = "ST_MITRE",
        Name = "Calle Mitre",
        HistoricalName = "Mitre",
        Orientation = "EastWest",
        IsPaved = true, -- Marked as Pavimento on map
        WidthStuds = 40,
        StartPos = { X = -750, Y = 11, Z = 0 },
        EndPos = { X = 750, Y = 8, Z = 0 },
        Description = "Paved east-west central backbone; intersects Av. de Mayo and passes South of the Central Plaza.",
    },
    {
        Id = "ST_RIVADAVIA",
        Name = "Calle Rivadavia",
        HistoricalName = "Rivadavia",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 30,
        StartPos = { X = -750, Y = 8, Z = 200 },
        EndPos = { X = 650, Y = 6, Z = 200 },
        Description = "Resort boulevard housing the town Iglesia, thermal baths, and nightlife confiterías.",
    },
    {
        Id = "ST_VICTORIA",
        Name = "Calle Victoria",
        HistoricalName = "Victoria",
        Orientation = "EastWest",
        IsPaved = false,
        WidthStuds = 28,
        StartPos = { X = -550, Y = 4, Z = 380 },
        EndPos = { X = 500, Y = 3, Z = 380 },
        Description = "Low-lying southern residential street running directly parallel to the coastal embankment.",
    },
    {
        Id = "ST_ALSINA",
        Name = "Calle Alsina (Costanera)",
        HistoricalName = "Alsina",
        Orientation = "CurvedCoast",
        IsPaved = true,
        WidthStuds = 34,
        StartPos = { X = -650, Y = 2, Z = 490 },
        EndPos = { X = 750, Y = 1, Z = 490 },
        Description = "Waterfront promenade along Laguna Epecuén; functions as the Costanera at Z=490, connecting to the central U-shaped pier and eastern salterns.",
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
        Description = "Deteriorated gravel and cracked asphalt track connecting the southeastern edge of Villa Epecuén (Calle Victoria) to the peripheral slaughterhouse.",
    },
    {
        Id = "RD_HUELLA_CEMENTERIO",
        Name = "Huella al Cementerio Inundado",
        HistoricalName = "Camino del Bajo al Cementerio",
        Orientation = "Diagonal",
        IsPaved = false,
        WidthStuds = 22,
        StartPos = { X = -320, Y = 4, Z = 380 },
        EndPos = { X = -600, Y = 0, Z = 600 },
        Description = "Submerged dirt track wading through petrified trees and briny mud toward the half-drowned municipal necropolis.",
    },
} :: { Street }

-- 3. KEY STREET INTERSECTIONS
EpecuenMapSpecification.Intersections = {
    {
        Id = "INT_MAYO_MITRE",
        StreetA = "AV_DE_MAYO",
        StreetB = "ST_MITRE",
        Position = { X = -160, Y = 11, Z = 0 },
        IsPavedCrossroad = true,
        TacticalNote = "Crucial central crossroads with long 4-way sightlines. Vulnerable to monster ambushes.",
    },
    {
        Id = "INT_CERRITO_MITRE",
        StreetA = "ST_CERRITO",
        StreetB = "ST_MITRE",
        Position = { X = 0, Y = 10, Z = 0 },
        IsPavedCrossroad = true,
        TacticalNote = "Southwest corner of the Central Plaza. Site of fallen streetlamps and rusted kiosks.",
    },
    {
        Id = "INT_PELLEGRINI_MITRE",
        StreetA = "ST_PELLEGRINI",
        StreetB = "ST_MITRE",
        Position = { X = 150, Y = 9, Z = 0 },
        IsPavedCrossroad = true,
        TacticalNote = "Southeast corner of the Central Plaza; gateway to the eastern hotel district.",
    },
    {
        Id = "INT_MAYO_ALSINA",
        StreetA = "AV_DE_MAYO",
        StreetB = "ST_ALSINA",
        Position = { X = -160, Y = 1, Z = 490 },
        IsPavedCrossroad = true,
        TacticalNote = "Root base of the U-shaped concrete promenade pier extending into Laguna Epecuén.",
    },
    {
        Id = "INT_MAYO_NORTH",
        StreetA = "AV_DE_MAYO",
        StreetB = "RD_NORTH_ACCESS",
        Position = { X = -160, Y = 18, Z = -720 },
        IsPavedCrossroad = true,
        TacticalNote = "Entrance to Terminal de Ómnibus and northern escape route heading toward Carhué.",
    },
    {
        Id = "INT_TALCAHUANO_MITRE",
        StreetA = "ST_TALCAHUANO",
        StreetB = "ST_MITRE",
        Position = { X = -320, Y = 11, Z = 0 },
        IsPavedCrossroad = false,
        TacticalNote = "Boundary crossing from orthogonal urban grid into the overgrown Western Radial Plazas.",
    },
    {
        Id = "INT_VICTORIA_MATADERO",
        StreetA = "ST_VICTORIA",
        StreetB = "RD_CAMINO_MATADERO",
        Position = { X = 500, Y = 3, Z = 380 },
        IsPavedCrossroad = false,
        TacticalNote = "Fork at the southeastern edge of town where Calle Victoria dissolves into the deteriorated path leading toward the peripheral Matadero.",
    },
    {
        Id = "INT_TALCAHUANO_CEM",
        StreetA = "ST_TALCAHUANO",
        StreetB = "RD_HUELLA_CEMENTERIO",
        Position = { X = -320, Y = 4, Z = 380 },
        IsPavedCrossroad = false,
        TacticalNote = "Southwest water gate branching out toward the submerged cemetery and the dead caldén groves.",
    },
} :: { Intersection }

-- 4. GEOGRAPHIC ZONES
EpecuenMapSpecification.Zones = {
    -- 1. Northern Entrance & Municipal Works
    {
        Id = "ZONE_NORTH_ENTRANCE",
        Name = "Acceso Norte y Obras Municipales",
        Category = "TransitDepot",
        Bounds = {
            Min = { X = -450, Y = 10, Z = -850 },
            Max = { X = 350, Y = 40, Z = -550 },
        },
        Center = { X = -100, Y = 18, Z = -680 },
        ElevationRange = { Min = 14, Max = 25 },
        SalinityHazardLevel = 5,
        ThreatLevel = "Medium",
        AcousticProfile = "OpenWind",
        Description = "High dry ground. Houses Terminal de Ómnibus, municipal vehicle impound (Corralón), and primary school.",
        NorthOf = "ZONE_CENTRAL_TOWN",
        SouthOf = "Open rural pampas plains toward Carhué",
        EastOf = "ZONE_RESIDENTIAL_EAST",
        WestOf = "ZONE_RADIAL_PARKS and western access road",
    },

    -- 2. Central Town Grid
    {
        Id = "ZONE_CENTRAL_TOWN",
        Name = "Casco Urbano Central",
        Category = "UrbanGrid",
        Bounds = {
            Min = { X = -320, Y = 5, Z = -450 },
            Max = { X = 350, Y = 30, Z = 200 },
        },
        Center = { X = 0, Y = 10, Z = -100 },
        ElevationRange = { Min = 7, Max = 15 },
        SalinityHazardLevel = 25,
        ThreatLevel = "High",
        AcousticProfile = "EchoingConcrete",
        Description = "Dense orthogonal grid of storefronts, cafes, dispensaries, and thermal spas. Narrow alleys and shattered glass.",
        NorthOf = "ZONE_SHORELINE",
        SouthOf = "ZONE_NORTH_ENTRANCE",
        EastOf = "ZONE_HOTEL_MONTE_REAL",
        WestOf = "ZONE_RADIAL_PARKS",
    },

    -- 3. Avenida de Mayo Central Spine
    {
        Id = "ZONE_AV_DE_MAYO",
        Name = "Corredor Avenida de Mayo",
        Category = "CivicCenter",
        Bounds = {
            Min = { X = -200, Y = 0, Z = -720 },
            Max = { X = -120, Y = 25, Z = 520 },
        },
        Center = { X = -160, Y = 10, Z = -100 },
        ElevationRange = { Min = 0, Max = 18 },
        SalinityHazardLevel = 30,
        ThreatLevel = "Deadly",
        AcousticProfile = "EchoingConcrete",
        Description = "Wide paved avenue cutting directly down the center of the ruins. Zero cover from distant watcher entity.",
        NorthOf = "Terminates at U-shaped pier in Laguna Epecuén",
        SouthOf = "Northern Access Route & Bus Terminal",
        EastOf = "ZONE_CENTRAL_PLAZA",
        WestOf = "ZONE_RADIAL_PARKS",
    },

    -- 4. Central Plaza ("Ud. Está Aquí")
    {
        Id = "ZONE_CENTRAL_PLAZA",
        Name = "Plaza Central (Ud. Está Aquí)",
        Category = "CivicCenter",
        Bounds = {
            Min = { X = -30, Y = 6, Z = -280 },
            Max = { X = 160, Y = 20, Z = 0 },
        },
        Center = { X = 65, Y = 11, Z = -140 },
        ElevationRange = { Min = 9, Max = 14 },
        SalinityHazardLevel = 15,
        ThreatLevel = "High",
        AcousticProfile = "MuffledFog",
        Description = "The landmark town square marked with the famous yellow 'Ud. Está Aquí' tourist orientation monument.",
        NorthOf = "Calle Mitre and Church sector",
        SouthOf = "Calle Sarmiento & upper residential blocks",
        EastOf = "Calle Pellegrini and Hotel District",
        WestOf = "Calle Cerrito and Avenida de Mayo",
    },

    -- 5. Eastern Town & Residential Quarter
    {
        Id = "ZONE_RESIDENTIAL_EAST",
        Name = "Barrio Residencial y Pensiones del Este",
        Category = "HospitalityResort",
        Bounds = {
            Min = { X = 350, Y = 2, Z = -650 },
            Max = { X = 850, Y = 25, Z = 300 },
        },
        Center = { X = 600, Y = 8, Z = -180 },
        ElevationRange = { Min = 3, Max = 12 },
        SalinityHazardLevel = 40,
        ThreatLevel = "Medium",
        AcousticProfile = "MuffledFog",
        Description = "Summer pensions, single-story villas, and boarding houses along Calle Maipú and Florida. Heavy white salt crusted walls.",
        NorthOf = "Curved littoral shoreline of Laguna Epecuén",
        SouthOf = "Northeast open salterns",
        EastOf = "Laguna Epecuén Eastern Basin",
        WestOf = "ZONE_HOTEL_MONTE_REAL",
    },

    -- 6. Laguna Epecuén Shoreline & Pier
    {
        Id = "ZONE_SHORELINE",
        Name = "Costanera y Dársena Lago Epecuén",
        Category = "ShorelineWaterfront",
        Bounds = {
            Min = { X = -700, Y = -15, Z = 450 },
            Max = { X = 900, Y = 10, Z = 1050 },
        },
        Center = { X = 0, Y = -2, Z = 650 },
        ElevationRange = { Min = -10, Max = 3 },
        SalinityHazardLevel = 90,
        ThreatLevel = "Deadly",
        AcousticProfile = "WaterSloshing",
        Description = "Submerged asphalt, calcified dead eucalyptus trees, and the prominent U-shaped concrete promenade pier jutting into deep brine.",
        NorthOf = "Open hypersaline waters of Laguna Epecuén",
        SouthOf = "Calle Alsina & Southern Hotel Strip",
        EastOf = "Eastern Littoral Bay",
        WestOf = "Southwest Mudflats",
    },

    -- 7. Hotel Monte Real Resort Quarter
    {
        Id = "ZONE_HOTEL_MONTE_REAL",
        Name = "Sector Residencial Monte Real",
        Category = "HospitalityResort",
        Bounds = {
            Min = { X = 300, Y = 5, Z = -350 },
            Max = { X = 500, Y = 45, Z = -50 },
        },
        Center = { X = 400, Y = 10, Z = -200 },
        ElevationRange = { Min = 8, Max = 13 },
        SalinityHazardLevel = 20,
        ThreatLevel = "High",
        AcousticProfile = "EchoingConcrete",
        Description = "Multi-story grand hotel ruins between Calle Suipacha and Esmeralda. Collapsed floors and flooded basement thermal baths.",
        NorthOf = "Thermal Spas & Calle Mitre",
        SouthOf = "Calle Cangallo upper pensions",
        EastOf = "ZONE_RESIDENTIAL_EAST",
        WestOf = "ZONE_CENTRAL_PLAZA",
    },

    -- 8. Church & Religious Sanctuary
    {
        Id = "ZONE_CHURCH",
        Name = "Santuario Parroquial de Epecuén",
        Category = "CivicCenter",
        Bounds = {
            Min = { X = -50, Y = 6, Z = 50 },
            Max = { X = 180, Y = 60, Z = 250 },
        },
        Center = { X = 60, Y = 8, Z = 150 },
        ElevationRange = { Min = 7, Max = 10 },
        SalinityHazardLevel = 15,
        ThreatLevel = "Medium",
        AcousticProfile = "EchoingConcrete",
        Description = "Parish church with half-collapsed bell tower between Mitre and Rivadavia. Offers temporary acoustic sanctuary.",
        NorthOf = "Calle Rivadavia & Teatro Bowling",
        SouthOf = "Calle Mitre & Central Plaza",
        EastOf = "Termas & Hotel Venecia",
        WestOf = "Avenida de Mayo",
    },

    -- 9. El Matadero (Salamone Slaughterhouse)
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
        Description = "Monumental Art Deco/Brutalist slaughterhouse with towering clocktower, adapted as an accessible southeastern peripheral sector. Connected to town via the deteriorated Camino al Matadero.",
        NorthOf = "Open salterns and eastern lagoon littoral plain",
        SouthOf = "Rural pampas perimeter and ancient cattle enclosures",
        EastOf = "Laguna Epecuén southeastern basin",
        WestOf = "Calle Alsina costanera and southeastern villa ruins",
    },

    -- 10. Western Radial Plazas (Beaux-Arts Geometric Parks)
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
        Description = "Geometric circular plazas and 45-degree diagonal radiant avenues filled with bleached, salt-petrified dead trees.",
        NorthOf = "Southwest shoreline of Laguna Epecuén",
        SouthOf = "Western littoral mudflats and salt pans",
        EastOf = "Calle Talcahuano & Central Town Grid",
        WestOf = "Outer western marshlands",
    },

    -- 11. Flooded Cemetery (Municipal Necropolis)
    {
        Id = "ZONE_FLOODED_CEMETERY",
        Name = "Cementerio Inundado de Epecuén",
        Category = "FloodedCemetery",
        Bounds = {
            Min = { X = -720, Y = -10, Z = 500 },
            Max = { X = -480, Y = 15, Z = 740 },
        },
        Center = { X = -600, Y = 0, Z = 620 },
        ElevationRange = { Min = -4, Max = 6 },
        SalinityHazardLevel = 85,
        ThreatLevel = "Deadly",
        AcousticProfile = "CryptEmanations",
        Description = "Half-submerged necropolis with exposed crypts, floating headstones, and iron crosses standing above the calcified brine.",
        NorthOf = "Calle Victoria and Southwest Radial Parks",
        SouthOf = "Deep hypersaline waters of Laguna Epecuén",
        EastOf = "U-shaped Promenade Pier and Costanera",
        WestOf = "Western littoral mudflats and salterns",
    },
} :: { GeographicZone }

-- 5. IMPORTANT LANDMARKS & FACILITIES (Cross-referenced with map index)
EpecuenMapSpecification.Landmarks = {
    {
        Id = "LMK_MATADERO",
        IndexOnMap = nil, -- Regional landmark adapted to accessible southeastern periphery
        Name = "El Matadero (Francisco Salamone)",
        HistoricalCategory = "Matadero Municipal / Obra de Francisco Salamone (1938)",
        Position = { X = 650, Y = 15, Z = 480 },
        FootprintStuds = { X = 140, Z = 90 },
        VerticalHeightStuds = 70,
        VisualSilhouette = "Towering 70-stud concrete blade clocktower with curved Art Deco slaughter hall; landmark beacon visible through fog.",
        GameplayRole = "Major visual landmark and expedition destination. Contains high-tier mechanical salvage and alternator.",
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
        HistoricalNotes = "Central place of worship for the permanent residents and seasonal workers of the town.",
    },
    {
        Id = "LMK_PLAZA_MONUMENT",
        IndexOnMap = 7, -- Center Plaza
        Name = "Cartel 'Ud. Está Aquí' / Plaza Central",
        HistoricalCategory = "Monumento Cívico / Plaza Pública",
        Position = { X = 65, Y = 11, Z = -140 },
        FootprintStuds = { X = 30, Z = 30 },
        VerticalHeightStuds = 14,
        VisualSilhouette = "Concrete tourism signboard plinth surrounded by dried decorative fountains.",
        GameplayRole = "Town orientation marker; map discovery point updating player's handheld compass.",
        HistoricalNotes = "The exact tourist signboard photographed in 2010 standing alone in the ruins.",
    },
    {
        Id = "LMK_TERMINAL_OMNIBUS",
        IndexOnMap = 2,
        Name = "Terminal de Ómnibus",
        HistoricalCategory = "Transporte de Pasajeros",
        Position = { X = -140, Y = 18, Z = -680 },
        FootprintStuds = { X = 120, Z = 60 },
        VerticalHeightStuds = 22,
        VisualSilhouette = "Open concrete canopy with rusted bus bays and ticketing counter.",
        GameplayRole = "Abandoned Mercedes-Benz long-distance buses; source of siphonable fuel.",
        HistoricalNotes = "Connected Villa Epecuén to Buenos Aires, Rosario, and Bahía Blanca during peak seasons.",
    },
    {
        Id = "LMK_CORRALON_MUNICIPAL",
        IndexOnMap = 1,
        Name = "Corralón Municipal",
        HistoricalCategory = "Obras Públicas / Taller",
        Position = { X = -280, Y = 17, Z = -680 },
        FootprintStuds = { X = 90, Z = 80 },
        VerticalHeightStuds = 20,
        VisualSilhouette = "Perimeter chainlink enclosure with rusted dump trucks and tool sheds.",
        GameplayRole = "Heavy tools, crowbars, hydraulic jacks, and repair parts.",
        HistoricalNotes = "Maintained municipal pumps, floodwalls, and street paving machinery before the levee broke.",
    },
    {
        Id = "LMK_HOTEL_COLONIA_FERROV",
        IndexOnMap = 4,
        Name = "Hotel Colonia Ferroviaria",
        HistoricalCategory = "Alojamiento Sindical",
        Position = { X = 50, Y = 16, Z = -660 },
        FootprintStuds = { X = 130, Z = 70 },
        VerticalHeightStuds = 26,
        VisualSilhouette = "Long utilitarian dormitory complex with iron railings.",
        GameplayRole = "Dormitory locker loot, medkits, blankets, and flashlights.",
        HistoricalNotes = "Railway worker union retreat holiday facility.",
    },
    {
        Id = "LMK_TERMAS_CENTRALES",
        IndexOnMap = 5,
        Name = "Complejo de Termas y Piletas",
        HistoricalCategory = "Baños Termales e Hidroterapia",
        Position = { X = 160, Y = 10, Z = -80 },
        FootprintStuds = { X = 100, Z = 100 },
        VerticalHeightStuds = 16,
        VisualSilhouette = "Large tiled indoor pools filled with dried white salt crust and rusted pipe networks.",
        GameplayRole = "Water valve puzzle to drain brine and access subterranean utility tunnel.",
        HistoricalNotes = "Famed for highly concentrated hyper-mineralized saline waters matching the Dead Sea.",
    },
    {
        Id = "LMK_TEATRO_BOWLING",
        IndexOnMap = 19,
        Name = "Teatro y Bowling",
        HistoricalCategory = "Centro de Recreación / Ocio Nocturno",
        Position = { X = 80, Y = 7, Z = 280 },
        FootprintStuds = { X = 90, Z = 60 },
        VerticalHeightStuds = 24,
        VisualSilhouette = "Art Deco facade with cracked marquee lettering and bowling lane pins.",
        GameplayRole = "Acoustic hazard zone: stepping on warped floorboards makes pins crash.",
        HistoricalNotes = "Entertained thousands of tourists during January and February summer seasons.",
    },
    {
        Id = "LMK_DARSENA_CENTRAL",
        IndexOnMap = nil, -- Clearly visible on lake shore
        Name = "Espigón Central y Dársena en U",
        HistoricalCategory = "Balneario / Paseo Costanero Subacuático",
        Position = { X = -160, Y = -2, Z = 650 },
        FootprintStuds = { X = 80, Z = 240 },
        VerticalHeightStuds = 6,
        VisualSilhouette = "U-shaped concrete promenade jetty extending out into the black saline lake.",
        GameplayRole = "Dead-end high stakes exploration: crate of spark plugs at pier tip; no side escape if trapped.",
        HistoricalNotes = "The iconic pier from which thousands floated in the buoyant waters of Epecuén.",
    },
    {
        Id = "LMK_EL_CASTILLO",
        IndexOnMap = 30,
        Name = "El Castillo",
        HistoricalCategory = "Mansión / Atractivo Turístico",
        Position = { X = 550, Y = 4, Z = 400 },
        FootprintStuds = { X = 70, Z = 70 },
        VerticalHeightStuds = 35,
        VisualSilhouette = "Medieval revival turret and crenellated tower rising from the shoreline ruins.",
        GameplayRole = "Sniper/observation perch; safe from ground patrols but narrow spiral exit.",
        HistoricalNotes = "Built by French settler Ernest L'Avene in the 1920s.",
    },
    {
        Id = "LMK_CEMENTERIO",
        IndexOnMap = nil,
        Name = "Cementerio Inundado y Criptas",
        HistoricalCategory = "Necrópolis Municipal / Patrimonio Histórico",
        Position = { X = -600, Y = 0, Z = 620 },
        FootprintStuds = { X = 180, Z = 180 },
        VerticalHeightStuds = 20,
        VisualSilhouette = "Shattered marble mausoleums and rusting wrought-iron crosses emerging from gray-white salt flats.",
        GameplayRole = "High-risk exploration zone; hidden crypt caches, occult lore relics, and acoustic anomaly.",
        HistoricalNotes = "The town cemetery was submerged under meters of salt water in 1985; coffins and vaults were calcified by the hypermineralized lake.",
    },
} :: { Landmark }

-- 6. PLAYER SPAWN POINT
EpecuenMapSpecification.PlayerSpawn = {
    Id = "SPAWN_NORTH_ROAD",
    Name = "Acceso Ruta Provincial Norte (Llegada en Niebla)",
    Position = { X = -180, Y = 20, Z = -780 } :: Vector3D,
    FacingAngleY = 180, -- Facing South toward the dead town
    ProximityToVehicleStuds = 25,
    InitialNarrative = "Tu vehículo se ha descompuesto al atravesar la densa niebla salina de Villa Epecuén. El motor humea y la batería está muerta. Debes adentrarte en el pueblo abandonado y recuperar repuestos antes de que caiga la noche.",
} :: PlayerSpawnPoint

-- 7. FIAT CRONOS VEHICLE OBJECTIVE
EpecuenMapSpecification.FiatCronos = {
    Name = "Fiat Cronos 1.3 Drive (Gris Silverstone)",
    Position = { X = -160, Y = 19, Z = -755 } :: Vector3D,
    RotationY = 175,
    Status = "Disabled",
    MissingParts = {
        "Battery",
        "Alternator",
        "SparkPlugs",
        "FuelCanister",
        "RadiatorHose",
    },
    Description = "El único medio de escape. Varado al costado del acceso asfaltado. El capó está abierto y el radiador reventado por el vapor corrosivo.",
} :: VehicleSpawnPoint

-- 8. FIVE CAR-PART SEARCH ZONES (Faithfully anchored to authentic landmarks)
EpecuenMapSpecification.CarPartSearchZones = {
    -- 1. Heavy Duty Battery
    {
        PartType = "Battery",
        ItemName = "Batería de 12V / 65Ah",
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
        EnvironmentalHazard = "Agua hipersalina cáustica y niebla espesa; reduce velocidad de movimiento un 40%.",
        PuzzleOrThreat = "Dentro de una caja de herramientas estanca abandonada en la punta del espigón en U.",
        LoreHint = "Un mecánico del balneario intentó reparar una lancha de rescate en el muelle antes de que el agua tapara la rambla.",
    },

    -- 4. Fuel Canister (Gasolina)
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
        PuzzleOrThreat = "Colgada en el panel de repuestos del taller municipal de obras viales.",
        LoreHint = "En el corralón de Adolfo Alsina reparaban los tractores que intentaron reforzar el terraplén.",
    },
} :: { CarPartSearchZone }

-- 9. HORROR & EXPLORATION ZONES (Atmospheric & Gameplay Tuning)
EpecuenMapSpecification.HorrorZones = {
    {
        Id = "HZ_SALINE_MUDFLATS",
        Name = "Lodazales de Salmuera y Esqueletos de Eucaliptos",
        ZoneRef = "ZONE_SHORELINE",
        AmbientColor = Color3.fromRGB(25, 30, 40),
        FogDistance = 90, -- Very tight fog
        SanityDrainPerSec = 0.8,
        MonsterSpawnWeight = 1.4,
        SpecialEffect = "BrineFootstepsAndHallucinations",
    },
    {
        Id = "HZ_MATADERO_TOWER",
        Name = "La Torre de la Matanza (Salamone)",
        ZoneRef = "ZONE_MATADERO",
        AmbientColor = Color3.fromRGB(35, 20, 20),
        FogDistance = 180,
        SanityDrainPerSec = 1.2,
        MonsterSpawnWeight = 2.0,
        SpecialEffect = "IndustrialClockTickingAndHeartbeat",
    },
    {
        Id = "HZ_MONTE_REAL_INTERIOR",
        Name = "Pasillos Muertos del Monte Real",
        ZoneRef = "ZONE_HOTEL_MONTE_REAL",
        AmbientColor = Color3.fromRGB(15, 15, 20),
        FogDistance = 60,
        SanityDrainPerSec = 1.0,
        MonsterSpawnWeight = 1.6,
        SpecialEffect = "DoorCreaksAndWhisperingGuests",
    },
    {
        Id = "HZ_BELL_TOWER",
        Name = "Campanario de la Iglesia en Ruinas",
        ZoneRef = "ZONE_CHURCH",
        AmbientColor = Color3.fromRGB(30, 30, 25),
        FogDistance = 140,
        SanityDrainPerSec = 0.2, -- Relatively calm sanctuary
        MonsterSpawnWeight = 0.5,
        SpecialEffect = "DistantBellEchoAndWindChimes",
    },
}

-- 10. STRATEGIC POINTS OF INTEREST
EpecuenMapSpecification.PointsOfInterest = {
    {
        Id = "POI_CHURCH_BELFRY",
        Name = "Campanario del Santuario",
        Position = { X = 60, Y = 35, Z = 150 },
        Type = "ObservationPerch",
        RiskRewardRatio = "High Risk / Strategic Reward",
        Details = "Permite divisar la silueta de El Vigilante en el plano de la ciudad y hacer sonar la campana.",
    },
    {
        Id = "POI_MUNICIPAL_SAFEHOUSE",
        Name = "Refugio del Subsuelo Municipal",
        Position = { X = -260, Y = 12, Z = -670 },
        Type = "SafeHaven",
        RiskRewardRatio = "Safe",
        Details = "Sótano estanco con puerta de hierro trabable; cama improvisada para regenerar cordura.",
    },
    {
        Id = "POI_BOWLING_TRAP",
        Name = "Pista de Bowling Desfondada",
        Position = { X = 80, Y = 7, Z = 280 },
        Type = "AcousticTrap",
        RiskRewardRatio = "High Risk",
        Details = "Tablones carcomidos por la humedad salina. Si el jugador corre, los bolos ruedan y delatan su posición.",
    },
    {
        Id = "POI_PIER_TIP",
        Name = "Extremo de la Dársena",
        Position = { X = -160, Y = -2, Z = 720 },
        Type = "LootCache",
        RiskRewardRatio = "Extreme Risk / Essential Loot",
        Details = "Punta del espigón rodeado de agua negra. Alberga las bujías pero no tiene escapatoria si es acorralado.",
    },
} :: { PointOfInterest }

return EpecuenMapSpecification
