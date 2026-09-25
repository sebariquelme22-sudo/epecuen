--!strict
--[[
    SanityTypes.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ReplicatedStorage/EpecuenShared/SanityTypes (ModuleScript)
    Author: Coding Assistant for Epecuén Development
    Description: Core data types and enums for psychological survival horror mechanics.
]]

export type SanityLevel = "Calm" | "Uneasy" | "Paranoid" | "Psychotic" | "Catatonic"

export type PlayerSurvivalState = {
    Sanity: number,          -- 0 (Catatonic) to 100 (Sane)
    SaltWaterExposure: number, -- 0 to 100 (Corrosion & Hypothermia)
    BodyTemperature: number,  -- Celsius: 37 normal, <34 hypothermic
    Stamina: number,         -- 0 to 100
    FlashlightBattery: number, -- 0 to 100
    IsFlashlightOn: boolean,
    IsSubmergedInBrine: boolean,
    NoiseLevel: number,      -- 0 to 100 (Auditory signature alerting entities)
}

export type HallucinationType = 
    | "Whispers" 
    | "FakeFootsteps" 
    | "ShadowSpecter" 
    | "SubmergedBell" 
    | "StaticVision" 
    | "DisorientCamera"
    | "MajorJumpscare"
    | "DizzinessSpecter"

export type MonsterState = "Dormant" | "Stalking" | "InvestigatingSound" | "Charging" | "Submerging"

local SanityTypes = {}

SanityTypes.SanityThresholds = {
    Calm = 80,
    Uneasy = 60,
    Paranoid = 35,
    Psychotic = 15,
    Catatonic = 0
}

return SanityTypes
