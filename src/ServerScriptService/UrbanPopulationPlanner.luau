--!strict
-- ============================================================================
-- Villa Epecuén - Urban Population Planner
-- File: roblox/src/ServerScriptService/UrbanPopulationPlanner.luau
-- 
-- PURPOSE:
--   Deterministic planning engine that computes precise spatial placement,
--   archetype assignment, orientation, and zone metadata for urban building
--   ruins across Villa Epecuén.
--
-- ARCHITECTURE CONSTRAINTS:
--   - PURE DATA & PLANNING MODULE ONLY.
--   - ZERO Roblox Instance creation (No Parts, No Models, No Workspace calls).
--   - Does NOT spawn anything into the world.
--   - Does NOT instantiate UrbanBuildingModelBuilder or any other builder.
--   - Requiring this module produces ZERO Workspace changes.
--   - Completely deterministic given the same Seed and Options via Random.new(seed).
--
-- GEOGRAPHIC SPECIFICATION ALIGNMENT:
--   - Classifies the 32 urban blocks from EpecuenMapSpecification into 7 categories:
--       * Residential
--       * Commercial
--       * Hotel/Residential
--       * Ruin/LowDensity
--       * OpenSpace
--       * LandmarkBuffer
--       * Excluded
--   - Protects large clearance envelopes around all canonical landmarks:
--       * Player Spawn (SPAWN_NORTH_ROAD)
--       * Fiat Cronos 1.3 Drive
--       * Plaza Central (Plaza General San Martín / LMK_PLAZA_MONUMENT)
--       * Hotel Monte Real (LMK_HOTEL_MONTE_REAL)
--       * Iglesia de Epecuén (LMK_IGLESIA)
--       * El Matadero (LMK_MATADERO)
--       * Ex-Estación de Ferrocarril / Hotel Colonia Ferroviaria
--       * Cementerio Inundado (LMK_CEMENTERIO)
--       * Laguna de Epecuén / Submerged southern shoreline
--       * Espigón y Dársena Central (LMK_DARSENA_CENTRAL)
--   - Guarantees 100% road clearance across all 16 canonical streets and avenues.
--   - Avoids overlapping existing visual test buildings along Avenida de Mayo.
--   - Maintains pedestrian alleys and interior courtyard setbacks.
-- ============================================================================

local UrbanPopulationPlanner = {}

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type BuildingArchetype =
    | "HouseSmall"
    | "HouseMedium"
    | "ShopRuins"
    | "SmallHotel"
    | "FacadeRuins"
    | "WallRuins"

export type ZoneCategory =
    | "Residential"
    | "Commercial"
    | "Hotel/Residential"
    | "Ruin/LowDensity"
    | "OpenSpace"
    | "LandmarkBuffer"
    | "Excluded"

export type PlannedBuilding = {
    BuildingType: string,
    Position: Vector3,
    RotationY: number,
    Seed: number,
    BlockId: string,
    ZoneCategory: string,
    FootprintWidth: number,
    FootprintDepth: number,
    ElevationY: number,
}

export type PlanOptions = {
    Seed: number?,
    Density: number?,
    MaxBuildings: number?,
    ExistingBuildingPositions: { Vector3 }?,
}

export type PlanResult = {
    Buildings: { PlannedBuilding },
    TotalCount: number,
    Seed: number,
    Density: number,
    MaxBuildings: number,
    BlockCounts: { [string]: number },
    CategoryCounts: { [string]: number },
    ArchetypeCounts: { [string]: number },
    PlannedCapacity: number,
    Summary: string,
}

export type BlockDefinition = {
    Id: string,
    RowIndex: number,
    ColumnIndex: number,
    Name: string,
    Category: ZoneCategory,
    MinX: number,
    MaxX: number,
    MinZ: number,
    MaxZ: number,
    ElevationY: number,
    SaltLevel: number,
    BaseCapacity: number,
}

export type ArchetypeSpec = {
    Type: BuildingArchetype,
    Width: number,
    Depth: number,
    Height: number,
    Description: string,
}

export type ProtectedZone = {
    Name: string,
    MinX: number,
    MaxX: number,
    MinZ: number,
    MaxZ: number,
    BufferStuds: number,
}

export type StreetCorridor = {
    Name: string,
    MinX: number,
    MaxX: number,
    MinZ: number,
    MaxZ: number,
}

export type PlannerMetrics = {
    TotalBlocks: number,
    BuildableBlocks: number,
    CategoryBreakdown: { [string]: number },
    TheoreticalCapacity: number,
    Archetypes: { [string]: { Width: number, Depth: number, Height: number, Description: string } },
    ProtectedZonesCount: number,
    TargetCapacityRange: string,
    Version: string,
}

-- ============================================================================
-- CANONICAL ARCHETYPE DIMENSIONS (From UrbanBuildingModelBuilder)
-- ============================================================================

local ARCHETYPE_SPECS: { [string]: ArchetypeSpec } = {
    HouseSmall = {
        Type = "HouseSmall",
        Width = 23.0,
        Depth = 19.0,
        Height = 11.0,
        Description = "Single-story vernacular brick/stucco residence with entrance and rubble scree",
    },
    HouseMedium = {
        Type = "HouseMedium",
        Width = 34.0,
        Depth = 26.0,
        Height = 13.0,
        Description = "Two-room summer villa with veranda porch and boundary garden wall",
    },
    ShopRuins = {
        Type = "ShopRuins",
        Width = 28.0,
        Depth = 24.0,
        Height = 13.0,
        Description = "Commercial almacén with 45-degree corner ochava and display windows",
    },
    SmallHotel = {
        Type = "SmallHotel",
        Width = 44.0,
        Depth = 32.0,
        Height = 20.0,
        Description = "Two-story resort accommodation with central hallway and grand portico",
    },
    FacadeRuins = {
        Type = "FacadeRuins",
        Width = 26.0,
        Depth = 8.0,
        Height = 12.0,
        Description = "Standalone front facade wall with ornate architrave and dentil cornice",
    },
    WallRuins = {
        Type = "WallRuins",
        Width = 28.0,
        Depth = 5.0,
        Height = 8.0,
        Description = "Boundary perimeter masonry wall with breach opening and decorative pillars",
    },
}

-- ============================================================================
-- CANONICAL 32 URBAN BLOCKS & CLASSIFICATIONS
-- ============================================================================

local URBAN_BLOCKS: { BlockDefinition } = {
    -- ------------------------------------------------------------------------
    -- ROW 1: North grid (Z: -670 to -470, Y: 12-16)
    -- ------------------------------------------------------------------------
    {
        Id = "BLK_R1_C1",
        RowIndex = 1,
        ColumnIndex = 1,
        Name = "Manzana Terminal y Garajes",
        Category = "LandmarkBuffer", -- Buffer for Terminal de Ómnibus, Spawn & Fiat Cronos
        MinX = -300.0,
        MaxX = -180.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 16.0,
        SaltLevel = 18.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R1_C2",
        RowIndex = 1,
        ColumnIndex = 2,
        Name = "Manzana Escuela e Institucional",
        Category = "Residential",
        MinX = -140.0,
        MaxX = -20.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 16.0,
        SaltLevel = 18.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R1_C3",
        RowIndex = 1,
        ColumnIndex = 3,
        Name = "Manzana Ferroviaria Central",
        Category = "LandmarkBuffer", -- Buffer for Ex-Estación de Ferrocarril
        MinX = 20.0,
        MaxX = 130.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 15.0,
        SaltLevel = 22.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R1_C4",
        RowIndex = 1,
        ColumnIndex = 4,
        Name = "Manzana Chalets del Norte",
        Category = "Residential",
        MinX = 170.0,
        MaxX = 280.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 15.0,
        SaltLevel = 20.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R1_C5",
        RowIndex = 1,
        ColumnIndex = 5,
        Name = "Manzana Residencial Este 1",
        Category = "Residential",
        MinX = 320.0,
        MaxX = 430.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 14.0,
        SaltLevel = 24.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R1_C6",
        RowIndex = 1,
        ColumnIndex = 6,
        Name = "Manzana Residencial Este 2",
        Category = "Residential",
        MinX = 470.0,
        MaxX = 580.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 13.0,
        SaltLevel = 25.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R1_C7",
        RowIndex = 1,
        ColumnIndex = 7,
        Name = "Manzana Límite Este",
        Category = "Residential",
        MinX = 620.0,
        MaxX = 730.0,
        MinZ = -670.0,
        MaxZ = -470.0,
        ElevationY = 12.0,
        SaltLevel = 30.0,
        BaseCapacity = 5,
    },

    -- ------------------------------------------------------------------------
    -- ROW 2: North-Central grid (Z: -430 to -270, Y: 10-14)
    -- ------------------------------------------------------------------------
    {
        Id = "BLK_R2_C1",
        RowIndex = 2,
        ColumnIndex = 1,
        Name = "Manzana Hoteles del Oeste",
        Category = "Hotel/Residential",
        MinX = -300.0,
        MaxX = -180.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 14.0,
        SaltLevel = 25.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R2_C2",
        RowIndex = 2,
        ColumnIndex = 2,
        Name = "Manzana Comercial Av. de Mayo Norte",
        Category = "Commercial",
        MinX = -140.0,
        MaxX = -20.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 14.0,
        SaltLevel = 25.0,
        BaseCapacity = 7,
    },
    {
        Id = "BLK_R2_C3",
        RowIndex = 2,
        ColumnIndex = 3,
        Name = "Manzana Hotel Bristol y Termas",
        Category = "Hotel/Residential",
        MinX = 20.0,
        MaxX = 130.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 13.0,
        SaltLevel = 28.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R2_C4",
        RowIndex = 2,
        ColumnIndex = 4,
        Name = "Manzana Hotelería Familiar",
        Category = "Hotel/Residential",
        MinX = 170.0,
        MaxX = 280.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 13.0,
        SaltLevel = 26.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R2_C5",
        RowIndex = 2,
        ColumnIndex = 5,
        Name = "Manzana Residencial Monte Real (Norte)",
        Category = "Hotel/Residential",
        MinX = 320.0,
        MaxX = 430.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 12.0,
        SaltLevel = 30.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R2_C6",
        RowIndex = 2,
        ColumnIndex = 6,
        Name = "Manzana Chalets del Este 2",
        Category = "Residential",
        MinX = 470.0,
        MaxX = 580.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 11.0,
        SaltLevel = 32.0,
        BaseCapacity = 5,
    },
    {
        Id = "BLK_R2_C7",
        RowIndex = 2,
        ColumnIndex = 7,
        Name = "Manzana Salitral Este 2",
        Category = "Ruin/LowDensity",
        MinX = 620.0,
        MaxX = 730.0,
        MinZ = -430.0,
        MaxZ = -270.0,
        ElevationY = 10.0,
        SaltLevel = 40.0,
        BaseCapacity = 3,
    },

    -- ------------------------------------------------------------------------
    -- ROW 3: Central grid (Z: -230 to -20, Y: 8-12)
    -- ------------------------------------------------------------------------
    {
        Id = "BLK_R3_C1",
        RowIndex = 3,
        ColumnIndex = 1,
        Name = "Manzana Teatro Bowling y Comercio Oeste",
        Category = "Commercial",
        MinX = -300.0,
        MaxX = -180.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 12.0,
        SaltLevel = 30.0,
        BaseCapacity = 7,
    },
    {
        Id = "BLK_R3_C2",
        RowIndex = 3,
        ColumnIndex = 2,
        Name = "Manzana Oeste de Plaza Central",
        Category = "Commercial",
        MinX = -140.0,
        MaxX = -20.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 12.0,
        SaltLevel = 32.0,
        BaseCapacity = 7,
    },
    {
        Id = "BLK_R3_C3",
        RowIndex = 3,
        ColumnIndex = 3,
        Name = "PLAZA CENTRAL (Plaza General San Martín)",
        Category = "OpenSpace", -- Strict public open space (Plaza monument only)
        MinX = 20.0,
        MaxX = 130.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 11.0,
        SaltLevel = 35.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R3_C4",
        RowIndex = 3,
        ColumnIndex = 4,
        Name = "Manzana Termas y Balneario Integral",
        Category = "Hotel/Residential",
        MinX = 170.0,
        MaxX = 280.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 11.0,
        SaltLevel = 35.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R3_C5",
        RowIndex = 3,
        ColumnIndex = 5,
        Name = "MANZANA HOTEL MONTE REAL (Epicentro)",
        Category = "LandmarkBuffer", -- Buffer for Hotel Monte Real
        MinX = 320.0,
        MaxX = 440.0,
        MinZ = -240.0,
        MaxZ = -160.0,
        ElevationY = 10.0,
        SaltLevel = 35.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R3_C6",
        RowIndex = 3,
        ColumnIndex = 6,
        Name = "Manzana Hotel Venecia",
        Category = "Hotel/Residential",
        MinX = 470.0,
        MaxX = 580.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 9.0,
        SaltLevel = 40.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R3_C7",
        RowIndex = 3,
        ColumnIndex = 7,
        Name = "Manzana Salitral Este 3",
        Category = "Ruin/LowDensity",
        MinX = 620.0,
        MaxX = 730.0,
        MinZ = -230.0,
        MaxZ = -20.0,
        ElevationY = 8.0,
        SaltLevel = 50.0,
        BaseCapacity = 3,
    },

    -- ------------------------------------------------------------------------
    -- ROW 4: South-Central grid (Z: 20 to 180, Y: 3-9)
    -- ------------------------------------------------------------------------
    {
        Id = "BLK_R4_C1",
        RowIndex = 4,
        ColumnIndex = 1,
        Name = "Manzana Cervecería y Rambla Oeste",
        Category = "Commercial",
        MinX = -300.0,
        MaxX = -180.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 9.0,
        SaltLevel = 42.0,
        BaseCapacity = 6,
    },
    {
        Id = "BLK_R4_C2",
        RowIndex = 4,
        ColumnIndex = 2,
        Name = "Manzana Parroquia e Iglesia de Epecuén",
        Category = "LandmarkBuffer", -- Buffer for Iglesia de Epecuén
        MinX = -140.0,
        MaxX = -20.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 8.0,
        SaltLevel = 45.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R4_C3",
        RowIndex = 4,
        ColumnIndex = 3,
        Name = "Manzana Hotel Las Palmeras",
        Category = "Hotel/Residential",
        MinX = 20.0,
        MaxX = 130.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 7.0,
        SaltLevel = 48.0,
        BaseCapacity = 5,
    },
    {
        Id = "BLK_R4_C4",
        RowIndex = 4,
        ColumnIndex = 4,
        Name = "Manzana Balneario Este 1",
        Category = "Residential",
        MinX = 170.0,
        MaxX = 280.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 6.0,
        SaltLevel = 55.0,
        BaseCapacity = 5,
    },
    {
        Id = "BLK_R4_C5",
        RowIndex = 4,
        ColumnIndex = 5,
        Name = "Manzana Balneario Este 2",
        Category = "Residential",
        MinX = 320.0,
        MaxX = 430.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 5.0,
        SaltLevel = 60.0,
        BaseCapacity = 5,
    },
    {
        Id = "BLK_R4_C6",
        RowIndex = 4,
        ColumnIndex = 6,
        Name = "Manzana Salitral Costero Este 1",
        Category = "Ruin/LowDensity",
        MinX = 470.0,
        MaxX = 580.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 4.0,
        SaltLevel = 65.0,
        BaseCapacity = 3,
    },
    {
        Id = "BLK_R4_C7",
        RowIndex = 4,
        ColumnIndex = 7,
        Name = "Manzana Salitral Costero Este 2",
        Category = "Ruin/LowDensity",
        MinX = 620.0,
        MaxX = 730.0,
        MinZ = 20.0,
        MaxZ = 180.0,
        ElevationY = 3.0,
        SaltLevel = 75.0,
        BaseCapacity = 3,
    },

    -- ------------------------------------------------------------------------
    -- ROW 5: Coastal / Submerged Waterfront (Z: 220 to 470, Y: 0-2) -> EXCLUDED
    -- ------------------------------------------------------------------------
    {
        Id = "BLK_R5_COSTANERA_WEST",
        RowIndex = 5,
        ColumnIndex = 1,
        Name = "Manzana Costanera Balnearia Oeste",
        Category = "Excluded", -- Submerged lakeshore (Salt: 85)
        MinX = -300.0,
        MaxX = -180.0,
        MinZ = 220.0,
        MaxZ = 470.0,
        ElevationY = 2.0,
        SaltLevel = 85.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R5_DARSENA_PROMENADE",
        RowIndex = 5,
        ColumnIndex = 2,
        Name = "Manzana Espigón y Dársena Central",
        Category = "Excluded", -- Dársena Central submerged pier (Salt: 90)
        MinX = -140.0,
        MaxX = -20.0,
        MinZ = 220.0,
        MaxZ = 470.0,
        ElevationY = 1.0,
        SaltLevel = 90.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R5_COSTANERA_CENTRAL",
        RowIndex = 5,
        ColumnIndex = 3,
        Name = "Manzana Piletas Saladas Costanera",
        Category = "Excluded", -- Submerged public pools (Salt: 95)
        MinX = 20.0,
        MaxX = 130.0,
        MinZ = 220.0,
        MaxZ = 470.0,
        ElevationY = 1.0,
        SaltLevel = 95.0,
        BaseCapacity = 0,
    },
    {
        Id = "BLK_R5_SOUTHEAST_RUINS",
        RowIndex = 5,
        ColumnIndex = 4,
        Name = "Manzana Sureste Inundada",
        Category = "Excluded", -- Fully submerged ruins (Salt: 100)
        MinX = 170.0,
        MaxX = 450.0,
        MinZ = 220.0,
        MaxZ = 470.0,
        ElevationY = 0.0,
        SaltLevel = 100.0,
        BaseCapacity = 0,
    },
}

-- ============================================================================
-- PROTECTED CLEARANCE ZONES (Landmarks, Spawns, Vehicles, Lagoon, Cemetery)
-- ============================================================================

local PROTECTED_ZONES: { ProtectedZone } = {
    {
        Name = "Player Spawn & Fiat Cronos",
        MinX = -220.0,
        MaxX = -100.0,
        MinZ = -790.0,
        MaxZ = -670.0,
        BufferStuds = 20.0,
    },
    {
        Name = "Plaza Central (Plaza General San Martín)",
        MinX = 0.0,
        MaxX = 150.0,
        MinZ = -250.0,
        MaxZ = 0.0,
        BufferStuds = 15.0,
    },
    {
        Name = "Hotel Monte Real Epicentro",
        MinX = 310.0,
        MaxX = 490.0,
        MinZ = -270.0,
        MaxZ = -130.0,
        BufferStuds = 20.0,
    },
    {
        Name = "Iglesia de Epecuén",
        MinX = -145.0,
        MaxX = 5.0,
        MinZ = 30.0,
        MaxZ = 190.0,
        BufferStuds = 20.0,
    },
    {
        Name = "El Matadero (Francisco Salamone)",
        MinX = 520.0,
        MaxX = 780.0,
        MinZ = 380.0,
        MaxZ = 580.0,
        BufferStuds = 25.0,
    },
    {
        Name = "Ex-Estación de Ferrocarril / Colonia Ferroviaria",
        MinX = 0.0,
        MaxX = 150.0,
        MinZ = -700.0,
        MaxZ = -570.0,
        BufferStuds = 20.0,
    },
    {
        Name = "Cementerio Inundado",
        MinX = -650.0,
        MaxX = -250.0,
        MinZ = 480.0,
        MaxZ = 850.0,
        BufferStuds = 30.0,
    },
    {
        Name = "Espigón y Dársena Central",
        MinX = -170.0,
        MaxX = 30.0,
        MinZ = 180.0,
        MaxZ = 520.0,
        BufferStuds = 20.0,
    },
    {
        Name = "Laguna de Epecuén / Southern Submerged Brine",
        MinX = -850.0,
        MaxX = 850.0,
        MinZ = 460.0,
        MaxZ = 900.0,
        BufferStuds = 10.0,
    },
    {
        Name = "Terminal de Ómnibus",
        MinX = -260.0,
        MaxX = -110.0,
        MinZ = -710.0,
        MaxZ = -590.0,
        BufferStuds = 15.0,
    },
    {
        Name = "Corralón Municipal",
        MinX = -270.0,
        MaxX = -170.0,
        MinZ = -380.0,
        MaxZ = -300.0,
        BufferStuds = 15.0,
    },
    {
        Name = "Complejo de Termas Centrales",
        MinX = 120.0,
        MaxX = 220.0,
        MinZ = -120.0,
        MaxZ = -40.0,
        BufferStuds = 15.0,
    },
}

-- ============================================================================
-- CANONICAL STREET CORRIDORS (Vehicular & Thoroughfare Clearances)
-- ============================================================================

local STREET_CORRIDORS: { StreetCorridor } = {
    -- North-South Avenues and Streets
    { Name = "ST_TALCAHUANO", MinX = -338.0, MaxX = -302.0, MinZ = -670.0, MaxZ = 520.0 },
    { Name = "AV_DE_MAYO",    MinX = -186.0, MaxX = -134.0, MinZ = -730.0, MaxZ = 740.0 },
    { Name = "ST_CERRITO",    MinX = -17.0,  MaxX = 17.0,   MinZ = -670.0, MaxZ = 520.0 },
    { Name = "ST_PELLEGRINI", MinX = 130.0,  MaxX = 170.0,  MinZ = -670.0, MaxZ = 520.0 },
    { Name = "ST_SUIPACHA",   MinX = 284.0,  MaxX = 316.0,  MinZ = -670.0, MaxZ = 470.0 },
    { Name = "ST_ESMERALDA",  MinX = 434.0,  MaxX = 466.0,  MinZ = -670.0, MaxZ = 370.0 },
    { Name = "ST_MAIPU",      MinX = 584.0,  MaxX = 616.0,  MinZ = -670.0, MaxZ = 270.0 },
    { Name = "ST_FLORIDA",    MinX = 734.0,  MaxX = 766.0,  MinZ = -670.0, MaxZ = 170.0 },

    -- East-West Streets
    { Name = "RD_NORTH_ACCESS", MinX = -750.0, MaxX = 850.0, MinZ = -770.0, MaxZ = -730.0 },
    { Name = "ST_SARMIENTO",    MinX = -750.0, MaxX = 750.0, MinZ = -467.0, MaxZ = -433.0 },
    { Name = "ST_CANGALLO",     MinX = -750.0, MaxX = 750.0, MinZ = -266.0, MaxZ = -234.0 },
    { Name = "ST_MITRE",        MinX = -750.0, MaxX = 750.0, MinZ = -22.0,  MaxZ = 22.0 },
    { Name = "ST_RIVADAVIA",    MinX = -750.0, MaxX = 650.0, MinZ = 183.0,  MaxZ = 217.0 },
    { Name = "ST_VICTORIA",     MinX = -550.0, MaxX = 500.0, MinZ = 364.0,  MaxZ = 396.0 },
}

-- ============================================================================
-- DEFAULT EXISTING TEST BUILDINGS (Visual test set in EpecuenMapGenerator)
-- ============================================================================

local DEFAULT_EXISTING_POSITIONS: { Vector3 } = {
    -- West Flank of Avenida de Mayo (Row 3, Col 1)
    Vector3.new(-202.0, 11.0, -213.75),
    Vector3.new(-199.0, 11.0, -182.50),
    Vector3.new(-209.0, 11.0, -148.50),
    Vector3.new(-210.0, 11.0, -103.50),
    Vector3.new(-192.0, 11.0, -62.50),
    Vector3.new(-199.0, 11.0, -34.50),

    -- East Flank of Avenida de Mayo (Row 3, Col 2)
    Vector3.new(-111.0, 11.0, -211.00),
    Vector3.new(-118.0, 11.0, -174.75),
    Vector3.new(-121.0, 11.0, -144.00),
    Vector3.new(-129.0, 11.0, -113.50),
    Vector3.new(-111.0, 11.0, -82.00),
    Vector3.new(-121.0, 11.0, -47.00),
}

-- ============================================================================
-- ARCHETYPE SELECTION WEIGHTS PER ZONE CATEGORY
-- ============================================================================

type WeightedArchetype = {
    Type: BuildingArchetype,
    Weight: number,
}

local CATEGORY_WEIGHTS: { [string]: { WeightedArchetype } } = {
    Commercial = {
        { Type = "ShopRuins",   Weight = 0.42 },
        { Type = "HouseMedium", Weight = 0.24 },
        { Type = "FacadeRuins", Weight = 0.15 },
        { Type = "HouseSmall",  Weight = 0.10 },
        { Type = "SmallHotel",  Weight = 0.05 },
        { Type = "WallRuins",   Weight = 0.04 },
    },
    ["Hotel/Residential"] = {
        { Type = "HouseMedium", Weight = 0.34 },
        { Type = "HouseSmall",  Weight = 0.26 },
        { Type = "ShopRuins",   Weight = 0.15 },
        { Type = "SmallHotel",  Weight = 0.11 }, -- SmallHotel used sparingly
        { Type = "FacadeRuins", Weight = 0.08 },
        { Type = "WallRuins",   Weight = 0.06 },
    },
    Residential = {
        { Type = "HouseSmall",  Weight = 0.46 },
        { Type = "HouseMedium", Weight = 0.30 },
        { Type = "WallRuins",   Weight = 0.12 },
        { Type = "FacadeRuins", Weight = 0.08 },
        { Type = "ShopRuins",   Weight = 0.04 },
        { Type = "SmallHotel",  Weight = 0.00 },
    },
    ["Ruin/LowDensity"] = {
        { Type = "FacadeRuins", Weight = 0.38 }, -- Heavily damaged sectors prefer Facades and Walls
        { Type = "WallRuins",   Weight = 0.36 },
        { Type = "HouseSmall",  Weight = 0.18 },
        { Type = "HouseMedium", Weight = 0.05 },
        { Type = "ShopRuins",   Weight = 0.03 },
        { Type = "SmallHotel",  Weight = 0.00 },
    },
}

-- ============================================================================
-- HELPER FUNCTIONS (Pure Logic)
-- ============================================================================

local function pickWeightedArchetype(category: string, rng: Random): BuildingArchetype
    local weights = CATEGORY_WEIGHTS[category]
    if not weights then
        return "HouseSmall"
    end

    local r = rng:NextNumber()
    local cumulative = 0.0
    for _, entry in ipairs(weights) do
        cumulative += entry.Weight
        if r <= cumulative then
            return entry.Type
        end
    end
    return weights[1].Type
end

local function isPointInsideBox(px: number, pz: number, minX: number, maxX: number, minZ: number, maxZ: number): boolean
    return px >= minX and px <= maxX and pz >= minZ and pz <= maxZ
end

local function isAABBOverlapping(
    minX1: number, maxX1: number, minZ1: number, maxZ1: number,
    minX2: number, maxX2: number, minZ2: number, maxZ2: number
): boolean
    return not (maxX1 < minX2 or minX1 > maxX2 or maxZ1 < minZ2 or minZ1 > maxZ2)
end

-- ============================================================================
-- PUBLIC METRICS API
-- ============================================================================

function UrbanPopulationPlanner.GetMetrics(): PlannerMetrics
    local catBreakdown: { [string]: number } = {
        Residential = 0,
        Commercial = 0,
        ["Hotel/Residential"] = 0,
        ["Ruin/LowDensity"] = 0,
        OpenSpace = 0,
        LandmarkBuffer = 0,
        Excluded = 0,
    }

    local buildableCount = 0
    local theoreticalCapacity = 0

    for _, b in ipairs(URBAN_BLOCKS) do
        catBreakdown[b.Category] = (catBreakdown[b.Category] or 0) + 1
        if b.BaseCapacity > 0 then
            buildableCount += 1
            theoreticalCapacity += b.BaseCapacity
        end
    end

    local archMetrics: { [string]: { Width: number, Depth: number, Height: number, Description: string } } = {}
    for name, spec in pairs(ARCHETYPE_SPECS) do
        archMetrics[name] = {
            Width = spec.Width,
            Depth = spec.Depth,
            Height = spec.Height,
            Description = spec.Description,
        }
    end

    return {
        TotalBlocks = #URBAN_BLOCKS,
        BuildableBlocks = buildableCount,
        CategoryBreakdown = catBreakdown,
        TheoreticalCapacity = theoreticalCapacity,
        Archetypes = archMetrics,
        ProtectedZonesCount = #PROTECTED_ZONES,
        TargetCapacityRange = "100–160 buildings",
        Version = "1.0.0-VillaEpecuen",
    }
end

function UrbanPopulationPlanner.GetBlockClassification(blockId: string): string?
    for _, b in ipairs(URBAN_BLOCKS) do
        if b.Id == blockId then
            return b.Category
        end
    end
    return nil
end

function UrbanPopulationPlanner.GetAllBlockClassifications(): { [string]: string }
    local res: { [string]: string } = {}
    for _, b in ipairs(URBAN_BLOCKS) do
        res[b.Id] = b.Category
    end
    return res
end

function UrbanPopulationPlanner.GetProtectedZones(): { ProtectedZone }
    return PROTECTED_ZONES
end

function UrbanPopulationPlanner.GetArchetypeFootprint(archetype: string): { Width: number, Depth: number, Height: number }?
    local spec = ARCHETYPE_SPECS[archetype]
    if spec then
        return {
            Width = spec.Width,
            Depth = spec.Depth,
            Height = spec.Height,
        }
    end
    return nil
end

-- ============================================================================
-- MAIN PLAN GENERATOR
-- ============================================================================

function UrbanPopulationPlanner.GeneratePlan(options: PlanOptions?): PlanResult
    local opts = options or {}
    local seed = opts.Seed or 5151
    local density = math.clamp(opts.Density or 1.0, 0.1, 2.0)
    local maxBuildings = opts.MaxBuildings or 135

    local rng = Random.new(seed)

    -- Merge existing buildings
    local existingPoints: { Vector3 } = {}
    for _, pos in ipairs(DEFAULT_EXISTING_POSITIONS) do
        table.insert(existingPoints, pos)
    end
    if opts.ExistingBuildingPositions then
        for _, pos in ipairs(opts.ExistingBuildingPositions) do
            table.insert(existingPoints, pos)
        end
    end

    local planned: { PlannedBuilding } = {}
    local blockCounts: { [string]: number } = {}
    local categoryCounts: { [string]: number } = {
        Residential = 0,
        Commercial = 0,
        ["Hotel/Residential"] = 0,
        ["Ruin/LowDensity"] = 0,
        OpenSpace = 0,
        LandmarkBuffer = 0,
        Excluded = 0,
    }
    local archetypeCounts: { [string]: number } = {
        HouseSmall = 0,
        HouseMedium = 0,
        ShopRuins = 0,
        SmallHotel = 0,
        FacadeRuins = 0,
        WallRuins = 0,
    }

    -- Target count scaling by category
    local categoryMultipliers: { [string]: number } = {
        Commercial = 1.15,          -- Higher density in central commercial corridors
        ["Hotel/Residential"] = 1.05, -- Medium-high density in resort hotel sector
        Residential = 1.00,         -- Standard residential density
        ["Ruin/LowDensity"] = 0.60, -- Lower density near flooded and salt flats
    }

    -- Process each block
    for _, block in ipairs(URBAN_BLOCKS) do
        -- Skip non-buildable categories (Plaza Central, Landmark Buffers, Submerged Costanera)
        if block.Category == "OpenSpace"
            or block.Category == "LandmarkBuffer"
            or block.Category == "Excluded" then
            continue
        end

        local catMultiplier = categoryMultipliers[block.Category] or 1.0
        local targetInBlock = math.round(block.BaseCapacity * density * catMultiplier)
        targetInBlock = math.clamp(targetInBlock, 1, 8)

        local placedInBlock = 0
        blockCounts[block.Id] = 0

        local zLength = block.MaxZ - block.MinZ
        local zPadding = 14.0
        local zUsable = zLength - (zPadding * 2.0)
        local numLotBands = math.clamp(math.floor(zUsable / 22.0), 4, 8)
        local bandStep = zUsable / numLotBands

        -- Generate candidate lot positions along West, East, North, and South frontages
        type CandidateSlot = {
            Flank: "West" | "East" | "North" | "South",
            BaseX: number,
            BaseZ: number,
            RotationY: number,
        }

        local slots: { CandidateSlot } = {}
        for i = 0, numLotBands - 1 do
            local zCenter = block.MinZ + zPadding + (i + 0.5) * bandStep
            -- West frontage: lots sit near MinX, facing West towards avenue (RotationY = -90)
            table.insert(slots, {
                Flank = "West",
                BaseX = block.MinX + 16.0,
                BaseZ = zCenter,
                RotationY = -90,
            })
            -- East frontage: lots sit near MaxX, facing East towards avenue (RotationY = 90)
            table.insert(slots, {
                Flank = "East",
                BaseX = block.MaxX - 16.0,
                BaseZ = zCenter,
                RotationY = 90,
            })
        end

        -- Mid-block North and South street frontage lots
        local midX = (block.MinX + block.MaxX) * 0.5
        table.insert(slots, {
            Flank = "North",
            BaseX = midX,
            BaseZ = block.MinZ + 16.0,
            RotationY = 0,
        })
        table.insert(slots, {
            Flank = "South",
            BaseX = midX,
            BaseZ = block.MaxZ - 16.0,
            RotationY = 180,
        })

        -- Deterministic shuffle of slot candidates within the block
        for i = #slots, 2, -1 do
            local j = rng:NextInteger(1, i)
            slots[i], slots[j] = slots[j], slots[i]
        end

        -- Evaluate candidate slots
        for _, slot in ipairs(slots) do
            if #planned >= maxBuildings then
                break
            end
            if placedInBlock >= targetInBlock then
                break
            end

            local chosenType = pickWeightedArchetype(block.Category, rng)
            local spec = ARCHETYPE_SPECS[chosenType]
            local width = spec.Width
            local depth = spec.Depth

            -- Calculate half-extents based on orientation
            local halfX: number
            local halfZ: number
            if slot.RotationY == 90 or slot.RotationY == -90 then
                -- When rotated 90 deg, building width spans Z and building depth spans X
                halfX = depth * 0.5
                halfZ = width * 0.5
            else
                halfX = width * 0.5
                halfZ = depth * 0.5
            end

            -- Lot setback: align facade near sidewalk while keeping building body inside block
            local posX: number
            local posZ: number

            if slot.Flank == "West" then
                posX = block.MinX + 3.0 + halfX
                posZ = slot.BaseZ + (rng:NextNumber() - 0.5) * 4.0
            elseif slot.Flank == "East" then
                posX = block.MaxX - 3.0 - halfX
                posZ = slot.BaseZ + (rng:NextNumber() - 0.5) * 4.0
            elseif slot.Flank == "North" then
                posX = slot.BaseX + (rng:NextNumber() - 0.5) * 6.0
                posZ = block.MinZ + 3.0 + halfZ
            else -- South
                posX = slot.BaseX + (rng:NextNumber() - 0.5) * 6.0
                posZ = block.MaxZ - 3.0 - halfZ
            end

            -- Boundary containment check: must be strictly inside block lot
            local minCandX = posX - halfX
            local maxCandX = posX + halfX
            local minCandZ = posZ - halfZ
            local maxCandZ = posZ + halfZ

            if minCandX < block.MinX + 1.0 or maxCandX > block.MaxX - 1.0 then
                continue
            end
            if minCandZ < block.MinZ + 1.0 or maxCandZ > block.MaxZ - 1.0 then
                continue
            end

            -- 1. Street clearance check (must never overlap or touch any street)
            local collidesStreet = false
            for _, street in ipairs(STREET_CORRIDORS) do
                if isAABBOverlapping(
                    minCandX, maxCandX, minCandZ, maxCandZ,
                    street.MinX, street.MaxX, street.MinZ, street.MaxZ
                ) then
                    collidesStreet = true
                    break
                end
            end
            if collidesStreet then
                continue
            end

            -- 2. Protected landmark clearance check
            local collidesProtected = false
            for _, prot in ipairs(PROTECTED_ZONES) do
                if isAABBOverlapping(
                    minCandX, maxCandX, minCandZ, maxCandZ,
                    prot.MinX - prot.BufferStuds,
                    prot.MaxX + prot.BufferStuds,
                    prot.MinZ - prot.BufferStuds,
                    prot.MaxZ + prot.BufferStuds
                ) then
                    collidesProtected = true
                    break
                end
            end
            if collidesProtected then
                continue
            end

            -- 3. Collision check with existing visual test buildings (min 14 studs buffer)
            local collidesExisting = false
            for _, exPos in ipairs(existingPoints) do
                local dx = math.abs(posX - exPos.X)
                local dz = math.abs(posZ - exPos.Z)
                if dx < (halfX + 14.0) and dz < (halfZ + 14.0) then
                    collidesExisting = true
                    break
                end
            end
            if collidesExisting then
                continue
            end

            -- 4. Collision check with previously planned buildings (min 4 studs pedestrian alley)
            local collidesPlanned = false
            for _, pb in ipairs(planned) do
                local pbHalfX = (pb.RotationY == 90 or pb.RotationY == -90) and (pb.FootprintDepth * 0.5) or (pb.FootprintWidth * 0.5)
                local pbHalfZ = (pb.RotationY == 90 or pb.RotationY == -90) and (pb.FootprintWidth * 0.5) or (pb.FootprintDepth * 0.5)

                local dx = math.abs(posX - pb.Position.X)
                local dz = math.abs(posZ - pb.Position.Z)
                if dx < (halfX + pbHalfX + 4.0) and dz < (halfZ + pbHalfZ + 4.0) then
                    collidesPlanned = true
                    break
                end
            end
            if collidesPlanned then
                continue
            end

            -- Candidate is valid! Register planned building
            local buildingSeed = rng:NextInteger(1000, 999999)
            local buildingElevation = block.ElevationY

            local newBuilding: PlannedBuilding = {
                BuildingType = chosenType,
                Position = Vector3.new(posX, buildingElevation, posZ),
                RotationY = slot.RotationY,
                Seed = buildingSeed,
                BlockId = block.Id,
                ZoneCategory = block.Category,
                FootprintWidth = width,
                FootprintDepth = depth,
                ElevationY = buildingElevation,
            }

            table.insert(planned, newBuilding)
            placedInBlock += 1
            blockCounts[block.Id] = (blockCounts[block.Id] or 0) + 1
            categoryCounts[block.Category] = (categoryCounts[block.Category] or 0) + 1
            archetypeCounts[chosenType] = (archetypeCounts[chosenType] or 0) + 1
        end
    end

    local total = #planned
    local summaryStr = string.format(
        "Urban population plan generated with %d buildings across Villa Epecuén (Seed: %d, Density: %.2f)",
        total, seed, density
    )

    return {
        Buildings = planned,
        TotalCount = total,
        Seed = seed,
        Density = density,
        MaxBuildings = maxBuildings,
        BlockCounts = blockCounts,
        CategoryCounts = categoryCounts,
        ArchetypeCounts = archetypeCounts,
        PlannedCapacity = total,
        Summary = summaryStr,
    }
end

return UrbanPopulationPlanner
