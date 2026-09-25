--!strict
-- ============================================================================
-- CarPartObjectiveSystem.luau
-- Location: roblox/src/ServerScriptService/CarPartObjectiveSystem.luau
--
-- EPECUÉN: NO ESCAPE - Fiat Cronos Vehicle-Part Exploration Objective System
--
-- Foundation for the five canonical vehicle-part exploration objectives:
--   1. Battery      - Hotel Monte Real (Generator Shed)
--   2. Alternator   - Matadero Salamone (Machinery Vault)
--   3. SparkPlugs   - Dársena Central (Pier Crate Stack)
--   4. FuelCanister - Terminal de Ómnibus (Luggage Cabinet)
--   5. RadiatorHose - Corralón Municipal (Repair Bench)
--
-- CRITICAL RESOURCE SEPARATION:
-- The vehicle battery ("Battery" / "CronosBattery") is strictly an automotive
-- component needed to start the Fiat Cronos. It is completely isolated from any
-- handheld camera flashlight / battery system and is never consumed or recharged
-- by camera mechanics.
--
-- ARCHITECTURE:
-- - Pure server-side typed objective and state management module.
-- - Resolves physical hideout models and HidePoint markers from:
--     Workspace.EpecuenWorld.CarPartHideouts
-- - Does NOT automatically spawn physical parts, models, or gameplay instances.
-- - No interaction prompts, GUI, or collection mechanics are introduced here.
-- ============================================================================

local Workspace = game:GetService("Workspace")

local CarPartObjectiveSystem = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type ObjectiveId = "Battery" | "Alternator" | "SparkPlugs" | "FuelCanister" | "RadiatorHose"

export type ObjectiveDefinition = {
    Id: ObjectiveId,
    DisplayName: string,
    ItemName: string,
    CanonicalPosition: Vector3,
    AssociatedHideoutName: string,
    RequiredRepairPartName: string,
    ZoneId: string,
    LandmarkAnchor: string,
    SearchRadiusStuds: number,
    InstallationStep: number,
    WeightKg: number,
    EnvironmentalHazard: string,
    PuzzleOrThreat: string,
    LoreHint: string,
}

export type ObjectiveState = {
    IsCollected: boolean,
    IsFound: boolean,
    IsHidden: boolean,
}

export type ObjectiveData = {
    Id: ObjectiveId,
    DisplayName: string,
    ItemName: string,
    CanonicalPosition: Vector3,
    AssociatedHideoutName: string,
    RequiredRepairPartName: string,
    ZoneId: string,
    LandmarkAnchor: string,
    SearchRadiusStuds: number,
    InstallationStep: number,
    WeightKg: number,
    EnvironmentalHazard: string,
    PuzzleOrThreat: string,
    LoreHint: string,
    IsCollected: boolean,
    IsFound: boolean,
    IsHidden: boolean,
}

export type ObjectiveProgress = {
    Total: number,
    Collected: number,
    Found: number,
    Remaining: number,
    IsComplete: boolean,
    Percentage: number,
}

-- ----------------------------------------------------------------------------
-- CANONICAL DEFINITIONS
-- Coordinates and metadata match EpecuenMapSpecification.CarPartSearchZones exactly.
-- ----------------------------------------------------------------------------

local OBJECTIVE_ORDER: { ObjectiveId } = {
    "Battery",
    "Alternator",
    "SparkPlugs",
    "FuelCanister",
    "RadiatorHose",
}

local CANONICAL_DEFINITIONS: { [ObjectiveId]: ObjectiveDefinition } = {
    Battery = {
        Id = "Battery",
        DisplayName = "Batería 12V Fiat Cronos",
        ItemName = "Batería de Plomo 12V 75Ah",
        CanonicalPosition = Vector3.new(410, 11, -190),
        AssociatedHideoutName = "Hideout_Battery_HotelMonteReal_GeneratorShed",
        RequiredRepairPartName = "Battery",
        ZoneId = "ZONE_HOTEL_MONTE_REAL",
        LandmarkAnchor = "LMK_HOTEL_MONTE_REAL",
        SearchRadiusStuds = 60,
        InstallationStep = 4,
        WeightKg = 18.5,
        EnvironmentalHazard = "Pisos superiores inestables y derrumbes de mampostería.",
        PuzzleOrThreat = "Ubicada en el cuarto de generadores traseros del hotel. Requiere llave de conserjería o palanca.",
        LoreHint = "El viejo conserje del Monte Real guardaba baterías de repuesto para el generador de emergencia durante las tormentas de 1985.",
    },

    Alternator = {
        Id = "Alternator",
        DisplayName = "Alternador de Carga 14V",
        ItemName = "Alternador de Carga 14V",
        CanonicalPosition = Vector3.new(665, 16, 495),
        AssociatedHideoutName = "Hideout_Alternator_Matadero_MachineryVault",
        RequiredRepairPartName = "Alternator",
        ZoneId = "ZONE_MATADERO",
        LandmarkAnchor = "LMK_MATADERO",
        SearchRadiusStuds = 80,
        InstallationStep = 2,
        WeightKg = 6.2,
        EnvironmentalHazard = "Viento aullante y eco distante de cadenas oxidadas. Refugio de El Vigilante.",
        PuzzleOrThreat = "Montado en el motor diésel de la sala de enfriamiento del Matadero Salamone.",
        LoreHint = "En el Matadero aún quedan maquinarias industriales con alternadores intactos en la sala de faena.",
    },

    SparkPlugs = {
        Id = "SparkPlugs",
        DisplayName = "Juego de Bujías de Encendido",
        ItemName = "Juego de Bujías de Encendido",
        CanonicalPosition = Vector3.new(-160, -1, 700),
        AssociatedHideoutName = "Hideout_SparkPlugs_Darsena_PierCrateStack",
        RequiredRepairPartName = "SparkPlugs",
        ZoneId = "ZONE_SHORELINE",
        LandmarkAnchor = "LMK_DARSENA_CENTRAL",
        SearchRadiusStuds = 50,
        InstallationStep = 1,
        WeightKg = 0.8,
        EnvironmentalHazard = "Agua hipersalina cáustica y niebla espesa; reduce velocidad de movimiento un 45%.",
        PuzzleOrThreat = "Dentro de una caja de herramientas estanca abandonada en la punta del espigón en U.",
        LoreHint = "Un mecánico del balneario intentó reparar una lancha de rescate en el muelle antes de que el agua tapara la rambla.",
    },

    FuelCanister = {
        Id = "FuelCanister",
        DisplayName = "Bidón de Nafta 20L",
        ItemName = "Bidón de Nafta 20L",
        CanonicalPosition = Vector3.new(-120, 18, -670),
        AssociatedHideoutName = "Hideout_FuelCanister_Terminal_LuggageCabinet",
        RequiredRepairPartName = "FuelCanister",
        ZoneId = "ZONE_NORTH_ENTRANCE",
        LandmarkAnchor = "LMK_TERMINAL_OMNIBUS",
        SearchRadiusStuds = 70,
        InstallationStep = 5,
        WeightKg = 16.0,
        EnvironmentalHazard = "Humo tóxico de tanques fermentados y cristales rotos que delatan pasos.",
        PuzzleOrThreat = "Sifonar combustible del tanque de un micro de larga distancia varado en la dársena.",
        LoreHint = "Los últimos micros de evacuación quedaron estacionados en la terminal con tanques llenos.",
    },

    RadiatorHose = {
        Id = "RadiatorHose",
        DisplayName = "Manguera Reforzada de Refrigerante",
        ItemName = "Manguera Reforzada de Refrigerante",
        CanonicalPosition = Vector3.new(-275, 17, -690),
        AssociatedHideoutName = "Hideout_RadiatorHose_Corralon_RepairBench",
        RequiredRepairPartName = "RadiatorHose",
        ZoneId = "ZONE_NORTH_ENTRANCE",
        LandmarkAnchor = "LMK_CORRALON_MUNICIPAL",
        SearchRadiusStuds = 55,
        InstallationStep = 3,
        WeightKg = 1.2,
        EnvironmentalHazard = "Portones de chapa batientes que hacen ruido metálico con el viento.",
        PuzzleOrThreat = "Extraer manguera de alta presión de una bomba centrífuga de desagote municipal.",
        LoreHint = "Las bombas de achique abandonadas en el corralón municipal tienen mangueras de goma sintética intactas.",
    },
}

-- ----------------------------------------------------------------------------
-- RUNTIME STATE
-- ----------------------------------------------------------------------------

local runtimeState: { [ObjectiveId]: ObjectiveState } = {
    Battery = { IsCollected = false, IsFound = false, IsHidden = true },
    Alternator = { IsCollected = false, IsFound = false, IsHidden = true },
    SparkPlugs = { IsCollected = false, IsFound = false, IsHidden = true },
    FuelCanister = { IsCollected = false, IsFound = false, IsHidden = true },
    RadiatorHose = { IsCollected = false, IsFound = false, IsHidden = true },
}

-- ----------------------------------------------------------------------------
-- INTERNAL HELPERS
-- ----------------------------------------------------------------------------

local function normalizeId(rawId: string): ObjectiveId?
    if not rawId then
        return nil
    end

    local clean = string.gsub(rawId, "%s+", "")
    if clean == "Battery" or clean == "CronosBattery" or clean == "battery" then
        return "Battery"
    elseif clean == "Alternator" or clean == "alternator" then
        return "Alternator"
    elseif clean == "SparkPlugs" or clean == "sparkplugs" or clean == "Spark_Plugs" then
        return "SparkPlugs"
    elseif clean == "FuelCanister" or clean == "fuelcanister" or clean == "Fuel_Canister" then
        return "FuelCanister"
    elseif clean == "RadiatorHose" or clean == "radiatorhose" or clean == "Radiator_Hose" then
        return "RadiatorHose"
    end

    return nil
end

local function getCarPartHideoutsFolder(): Folder?
    local epecuenWorld = Workspace:FindFirstChild("EpecuenWorld")
    if not epecuenWorld then
        return nil
    end
    local hideoutsFolder = epecuenWorld:FindFirstChild("CarPartHideouts")
    if hideoutsFolder and hideoutsFolder:IsA("Folder") then
        return hideoutsFolder
    end
    return nil
end

local function assembleObjectiveData(id: ObjectiveId): ObjectiveData
    local def = CANONICAL_DEFINITIONS[id]
    local state = runtimeState[id]
    return {
        Id = def.Id,
        DisplayName = def.DisplayName,
        ItemName = def.ItemName,
        CanonicalPosition = def.CanonicalPosition,
        AssociatedHideoutName = def.AssociatedHideoutName,
        RequiredRepairPartName = def.RequiredRepairPartName,
        ZoneId = def.ZoneId,
        LandmarkAnchor = def.LandmarkAnchor,
        SearchRadiusStuds = def.SearchRadiusStuds,
        InstallationStep = def.InstallationStep,
        WeightKg = def.WeightKg,
        EnvironmentalHazard = def.EnvironmentalHazard,
        PuzzleOrThreat = def.PuzzleOrThreat,
        LoreHint = def.LoreHint,
        IsCollected = state.IsCollected,
        IsFound = state.IsFound,
        IsHidden = state.IsHidden,
    }
end

-- ----------------------------------------------------------------------------
-- PUBLIC API: OBJECTIVE DEFINITION & STATE ACCESS
-- ----------------------------------------------------------------------------

--- Retrieves complete objective data and current state for a given objective ID.
function CarPartObjectiveSystem.GetObjective(objectiveId: string): ObjectiveData?
    local id = normalizeId(objectiveId)
    if not id then
        return nil
    end
    return assembleObjectiveData(id)
end

--- Retrieves all five vehicle-part objectives indexed by their stable ObjectiveId.
function CarPartObjectiveSystem.GetAllObjectives(): { [ObjectiveId]: ObjectiveData }
    local result: { [ObjectiveId]: ObjectiveData } = {}
    for _, id in ipairs(OBJECTIVE_ORDER) do
        result[id] = assembleObjectiveData(id)
    end
    return result
end

--- Retrieves an ordered array of all five vehicle-part objectives.
function CarPartObjectiveSystem.GetObjectiveList(): { ObjectiveData }
    local list: { ObjectiveData } = {}
    for _, id in ipairs(OBJECTIVE_ORDER) do
        table.insert(list, assembleObjectiveData(id))
    end
    return list
end

--- Retrieves the static canonical definition for a given objective ID.
function CarPartObjectiveSystem.GetDefinition(objectiveId: string): ObjectiveDefinition?
    local id = normalizeId(objectiveId)
    if not id then
        return nil
    end
    return CANONICAL_DEFINITIONS[id]
end

--- Returns an array of the 5 canonical objective IDs in standard repair order.
function CarPartObjectiveSystem.GetObjectiveOrder(): { ObjectiveId }
    return table.clone(OBJECTIVE_ORDER)
end

-- ----------------------------------------------------------------------------
-- PUBLIC API: HIDEOUT & HIDEPOINT RESOLUTION
-- Resolves environmental models and markers in Workspace.EpecuenWorld.CarPartHideouts
-- ----------------------------------------------------------------------------

--- Resolves the physical hideout Model from Workspace.EpecuenWorld.CarPartHideouts.
--- Returns nil if the map or hideout has not yet been generated.
function CarPartObjectiveSystem.GetHideout(objectiveId: string): Model?
    local id = normalizeId(objectiveId)
    if not id then
        return nil
    end

    local def = CANONICAL_DEFINITIONS[id]
    local hideoutsFolder = getCarPartHideoutsFolder()
    if not hideoutsFolder then
        return nil
    end

    local hideoutInstance = hideoutsFolder:FindFirstChild(def.AssociatedHideoutName)
    if hideoutInstance and hideoutInstance:IsA("Model") then
        return hideoutInstance
    end

    return nil
end

--- Resolves the internal "HidePoint" marker part within the physical hideout model.
--- Returns nil if the hideout or marker part does not exist in Workspace.
function CarPartObjectiveSystem.GetHidePoint(objectiveId: string): BasePart?
    local hideoutModel = CarPartObjectiveSystem.GetHideout(objectiveId)
    if not hideoutModel then
        return nil
    end

    local hidePointInstance = hideoutModel:FindFirstChild("HidePoint", true)
    if hidePointInstance and hidePointInstance:IsA("BasePart") then
        return hidePointInstance
    end

    return nil
end

-- ----------------------------------------------------------------------------
-- PUBLIC API: STATE MUTATION & QUERY
-- ----------------------------------------------------------------------------

--- Checks whether an objective part has been collected by the player.
function CarPartObjectiveSystem.IsCollected(objectiveId: string): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end
    return runtimeState[id].IsCollected
end

--- Sets the collected state for an objective.
--- Marking as collected automatically updates IsFound to true and IsHidden to false.
function CarPartObjectiveSystem.SetCollected(objectiveId: string, collected: boolean?): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end

    local isCol = if collected ~= nil then collected else true
    runtimeState[id].IsCollected = isCol

    if isCol then
        runtimeState[id].IsFound = true
        runtimeState[id].IsHidden = false
    end

    return true
end

--- Checks whether an objective part has been discovered/spotted in its hideout.
function CarPartObjectiveSystem.IsFound(objectiveId: string): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end
    return runtimeState[id].IsFound
end

--- Sets whether an objective part has been discovered.
function CarPartObjectiveSystem.SetFound(objectiveId: string, found: boolean?): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end

    local isFnd = if found ~= nil then found else true
    runtimeState[id].IsFound = isFnd
    if isFnd then
        runtimeState[id].IsHidden = false
    end

    return true
end

--- Checks whether an objective part is still concealed in its hideout.
function CarPartObjectiveSystem.IsHidden(objectiveId: string): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end
    return runtimeState[id].IsHidden
end

--- Sets whether an objective part is concealed in its hideout.
function CarPartObjectiveSystem.SetHidden(objectiveId: string, hidden: boolean?): boolean
    local id = normalizeId(objectiveId)
    if not id then
        return false
    end

    local isHid = if hidden ~= nil then hidden else true
    runtimeState[id].IsHidden = isHid
    if isHid then
        runtimeState[id].IsCollected = false
    end

    return true
end

--- Returns quantitative progress across all 5 vehicle exploration objectives.
function CarPartObjectiveSystem.GetProgress(): ObjectiveProgress
    local total = #OBJECTIVE_ORDER
    local collectedCount = 0
    local foundCount = 0

    for _, id in ipairs(OBJECTIVE_ORDER) do
        local state = runtimeState[id]
        if state.IsCollected then
            collectedCount += 1
        end
        if state.IsFound then
            foundCount += 1
        end
    end

    local remaining = total - collectedCount
    local isComplete = (collectedCount == total)
    local percentage = math.floor((collectedCount / total) * 100)

    return {
        Total = total,
        Collected = collectedCount,
        Found = foundCount,
        Remaining = remaining,
        IsComplete = isComplete,
        Percentage = percentage,
    }
end

--- Resets all objective states to default (Uncollected, Unfound, Hidden).
function CarPartObjectiveSystem.ResetAll(): ()
    for _, id in ipairs(OBJECTIVE_ORDER) do
        runtimeState[id] = {
            IsCollected = false,
            IsFound = false,
            IsHidden = true,
        }
    end
end

-- ----------------------------------------------------------------------------
-- COMPATIBILITY INTERFACE (Preserves API ergonomics)
-- ----------------------------------------------------------------------------

--- Alias for IsCollected
function CarPartObjectiveSystem.IsPartCollected(objectiveId: string): boolean
    return CarPartObjectiveSystem.IsCollected(objectiveId)
end

--- Returns true if all five vehicle parts have been collected.
function CarPartObjectiveSystem.IsAllCollected(): boolean
    return CarPartObjectiveSystem.GetProgress().IsComplete
end

--- Validates that all five canonical definitions exist with valid coordinates and hideouts.
function CarPartObjectiveSystem.ValidateDefinitions(): (boolean, { string })
    local errors: { string } = {}

    for _, id in ipairs(OBJECTIVE_ORDER) do
        local def = CANONICAL_DEFINITIONS[id]
        if not def then
            table.insert(errors, "Missing definition for " .. tostring(id))
        else
            if def.CanonicalPosition.Magnitude == 0 then
                table.insert(errors, "Zero coordinate for " .. tostring(id))
            end
            if not def.AssociatedHideoutName or def.AssociatedHideoutName == "" then
                table.insert(errors, "Missing hideout name for " .. tostring(id))
            end
        end
    end

    return (#errors == 0), errors
end

return CarPartObjectiveSystem
