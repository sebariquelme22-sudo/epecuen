--!strict
-- ============================================================================
-- RepairToolWorldPlacement.luau
-- Location: roblox/src/ServerScriptService/RepairToolWorldPlacement.luau
--
-- EPECUÉN: NO ESCAPE - World Placement for Abandoned Automotive Toolbox
--
-- PURPOSE:
-- Provides the canonical world-placement definition and builder invoker for the
-- physical mechanic's toolbox (RepairToolBuilder) inside the Corralón Municipal.
--
-- CANONICAL CORRALÓN MUNICIPAL SPECIFICATION (EpecuenMapSpecification.luau):
--   - Landmark Id:       "LMK_CORRALON_MUNICIPAL"
--   - Zone Id:           "ZONE_NORTH_ENTRANCE"
--   - Canonical Anchor:  Vector3.new(-280, 17, -670)
--   - Footprint (Studs): 80 (X: -320 to -240) x 90 (Z: -715 to -625)
--   - Historical Role:   Municipal equipment depot, mechanical workshops, dyke machinery
--
-- EXACT TOOLBOX PLACEMENT:
--   - Model Name:        "RepairTool_Corralon_AbandonedToolbox"
--   - Position:          Vector3.new(-260, 17, -650)
--   - RotationY:         25 degrees (naturally resting against the interior workshop corner)
--   - DamageLevel:       0.75 (weathered and oxidized industrial steel)
--   - SaltLevel:         0.65 (mineral calcite crust from hyper-saline flooding)
--   - Target Folder:     "EnvironmentDetails" (Workspace.EpecuenWorld.EnvironmentDetails)
--
-- SAFETY & CLEARANCE VERIFICATION:
--   - Inside Corralón Bounds:
--       X = -260 is within [-320, -240] (20 studs inside eastern workshop perimeter)
--       Z = -650 is within [-715, -625] (25 studs inside southern workshop perimeter)
--       Y = 17.0 rests flush on the canonical ground level of the municipal depot
--   - Away from Roads:
--       > 42 studs east of ST_TALCAHUANO (X: -338 to -302)
--       > 80 studs south of RD_NORTH_ACCESS (Z: -770 to -730)
--   - Away from Entrances/Exits:
--       Located in the sheltered southeast workshop yard, away from vehicular gates
--   - Away from RadiatorHose Hideout & Part:
--       RadiatorHose hideout ("Hideout_RadiatorHose_Corralon_RepairBench") is at (-275, 17, -690)
--       Distance: sqrt((15)^2 + (40)^2) = sqrt(225 + 1600) = sqrt(1825) ≈ 42.72 studs
--       Separated by over 42 studs across opposite quadrants of the Corralón
--   - Away from Important Player Paths:
--       Tucked into an interior workshop recess rather than main thoroughfares
--
-- NARRATIVE CONSTRAINTS:
--   - This toolbox is NOT an objective.
--   - ZERO quest markers, objective IDs, HUD binds, or progress tracking.
--   - ZERO ProximityPrompts, ClickDetectors, or Touched listeners.
--   - ZERO collection, inventory, repair, UI, audio, or networking logic.
--   - Players simply encounter it as authentic abandoned environment dressing.
--   - ZERO automatic execution of Build() on module require.
-- ============================================================================

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local RepairToolWorldPlacement = {}

-- ----------------------------------------------------------------------------
-- TYPES
-- ----------------------------------------------------------------------------

export type RepairToolPlacementDefinition = {
    ModelName: string,
    Position: Vector3,
    RotationY: number,
    DamageLevel: number,
    SaltLevel: number,
    LandmarkId: string,
    ZoneId: string,
    TargetFolderName: string,
    Description: string,
}

-- ----------------------------------------------------------------------------
-- CANONICAL PLACEMENT DEFINITION
-- ----------------------------------------------------------------------------

local PLACEMENT_DEFINITION: RepairToolPlacementDefinition = {
    ModelName = "RepairTool_Corralon_AbandonedToolbox",
    Position = Vector3.new(-260, 17, -650),
    RotationY = 25,
    DamageLevel = 0.75,
    SaltLevel = 0.65,
    LandmarkId = "LMK_CORRALON_MUNICIPAL",
    ZoneId = "ZONE_NORTH_ENTRANCE",
    TargetFolderName = "EnvironmentDetails",
    Description = "Abandoned heavy mechanic's toolbox tucked into the sheltered southeastern workshop yard of Corralón Municipal.",
}

-- Internal tracking to guarantee single-instance placement idempotency
local activeModel: Model? = nil

-- ----------------------------------------------------------------------------
-- DEPENDENCY RESOLUTION: RepairToolBuilder
-- ----------------------------------------------------------------------------

local function getRepairToolBuilder(): any
    local parent = script.Parent
    if parent and parent:FindFirstChild("RepairToolBuilder") then
        return require(parent:FindFirstChild("RepairToolBuilder") :: ModuleScript)
    end
    local serverFolder = ServerScriptService:FindFirstChild("EpecuenServer")
    if serverFolder and serverFolder:FindFirstChild("RepairToolBuilder") then
        return require(serverFolder:FindFirstChild("RepairToolBuilder") :: ModuleScript)
    end
    local found = ServerScriptService:FindFirstChild("RepairToolBuilder", true)
    if found and found:IsA("ModuleScript") then
        return require(found)
    end
    return require(ServerScriptService:WaitForChild("RepairToolBuilder") :: ModuleScript)
end

-- ----------------------------------------------------------------------------
-- TARGET PARENT RESOLUTION
-- ----------------------------------------------------------------------------

local function resolveTargetParent(customParent: Instance?): Instance
    if customParent then
        return customParent
    end

    local world = Workspace:FindFirstChild("EpecuenWorld")
    if world then
        local envFolder = world:FindFirstChild(PLACEMENT_DEFINITION.TargetFolderName)
        if envFolder then
            return envFolder
        end
        return world
    end

    return Workspace
end

-- ----------------------------------------------------------------------------
-- PUBLIC API
-- ----------------------------------------------------------------------------

--- Returns a copy of the canonical placement definition for the Corralón toolbox.
function RepairToolWorldPlacement.GetPlacement(): RepairToolPlacementDefinition
    return {
        ModelName = PLACEMENT_DEFINITION.ModelName,
        Position = PLACEMENT_DEFINITION.Position,
        RotationY = PLACEMENT_DEFINITION.RotationY,
        DamageLevel = PLACEMENT_DEFINITION.DamageLevel,
        SaltLevel = PLACEMENT_DEFINITION.SaltLevel,
        LandmarkId = PLACEMENT_DEFINITION.LandmarkId,
        ZoneId = PLACEMENT_DEFINITION.ZoneId,
        TargetFolderName = PLACEMENT_DEFINITION.TargetFolderName,
        Description = PLACEMENT_DEFINITION.Description,
    }
end

--- Retrieves the currently built Model instance if one exists in the world.
function RepairToolWorldPlacement.GetModel(): Model?
    if activeModel and activeModel.Parent then
        return activeModel
    end

    local found = Workspace:FindFirstChild(PLACEMENT_DEFINITION.ModelName, true)
    if found and found:IsA("Model") then
        activeModel = found
        return found
    end

    return nil
end

--- Checks if the toolbox model is currently placed in the world.
function RepairToolWorldPlacement.IsPlaced(): boolean
    return RepairToolWorldPlacement.GetModel() ~= nil
end

--- Removes any existing placed toolbox model from the world.
function RepairToolWorldPlacement.Clear(): ()
    local current = RepairToolWorldPlacement.GetModel()
    if current then
        current:Destroy()
    end
    activeModel = nil
end

--- Builds exactly one physical toolbox model using the canonical placement definition.
--- Prevents duplicate instances if called multiple times.
---
--- @param parent Optional custom parent instance. Defaults to Workspace.EpecuenWorld.EnvironmentDetails.
--- @return The generated Model.
function RepairToolWorldPlacement.Build(parent: Instance?): Model
    -- 1. Check if an active instance already exists in memory and hierarchy
    if activeModel and activeModel.Parent then
        return activeModel
    end

    local targetParent = resolveTargetParent(parent)

    -- 2. Check if a model with the canonical name is already present in targetParent
    local existingInParent = targetParent:FindFirstChild(PLACEMENT_DEFINITION.ModelName)
    if existingInParent and existingInParent:IsA("Model") then
        activeModel = existingInParent
        return existingInParent
    end

    -- 3. Check if an instance exists anywhere in Workspace to guarantee single-instance placement
    local existingInWorld = Workspace:FindFirstChild(PLACEMENT_DEFINITION.ModelName, true)
    if existingInWorld and existingInWorld:IsA("Model") then
        activeModel = existingInWorld
        return existingInWorld
    end

    -- 4. Invoke RepairToolBuilder with the canonical placement specification
    local RepairToolBuilder = getRepairToolBuilder()
    local builtModel = RepairToolBuilder.Build({
        Position = PLACEMENT_DEFINITION.Position,
        RotationY = PLACEMENT_DEFINITION.RotationY,
        DamageLevel = PLACEMENT_DEFINITION.DamageLevel,
        SaltLevel = PLACEMENT_DEFINITION.SaltLevel,
        Name = PLACEMENT_DEFINITION.ModelName,
        Parent = targetParent,
    })

    activeModel = builtModel
    return builtModel
end

return RepairToolWorldPlacement
