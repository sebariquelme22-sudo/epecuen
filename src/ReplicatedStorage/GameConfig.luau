--!strict
--[[
    GameConfig.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ReplicatedStorage/EpecuenShared/GameConfig (ModuleScript)
    Description: Master configuration constants balancing survival-horror tuning:
                 Hypersaline lake toxicity, sanity decay, sound detection, flashlight drain.
]]

local GameConfig = {
    -- Game Metadata
    VERSION = "1.0.0-PROTOTYPE",
    GAME_TITLE = "Epecuén: No Escape",
    SETTING = "Villa Epecuén, Buenos Aires, Argentina (Ruins of the 1985 Inundation)",

    -- Flashlight Systems
    FLASHLIGHT = {
        MAX_BATTERY = 100,
        DRAIN_PER_SECOND = 0.45,       -- ~3.7 minutes on a single full battery
        FLICKER_CHANCE_LOW_BATTERY = 0.08,
        FLICKER_CHANCE_NEAR_ENTITY = 0.35,
        LIGHT_RANGE = 42,
        LIGHT_BRIGHTNESS = 2.8,
        LIGHT_ANGLE = 65,
        TINT = Color3.fromRGB(242, 235, 210), -- Slightly warm incandescent beam
    },

    -- Sanity & Psychological Horror
    SANITY = {
        MAX_SANITY = 100,
        DARKNESS_DECAY_PER_SEC = 0.30,   -- Losing sanity when in total pitch black
        SALT_WATER_DECAY_PER_SEC = 0.60, -- Standing in toxic brine water
        MONSTER_PROXIMITY_DECAY = 2.2,   -- Staring or close to El Vigilante
        RECOVERY_RATE_LIGHT = 0.15,      -- Slow recovery near lit lamps or campfire
        HALLUCINATION_INTERVAL_MIN = 8,  -- Seconds between checks when sanity is low
        HALLUCINATION_INTERVAL_MAX = 22,
    },

    -- Hypersaline Water Hazard (Laguna Epecuén - 10x ocean salinity)
    SALT_WATER = {
        MAX_EXPOSURE = 100,
        EXPOSURE_DAMAGE_TICK = 1.5,      -- Seconds per damage tick
        CORROSION_DAMAGE = 4,            -- Damage when exposure > 70%
        SLOW_DOWN_FACTOR = 0.65,         -- WalkSpeed multiplier in deep salt mud
        BUOYANCY_FACTOR = 1.35,          -- Flotation pull due to extreme salinity
        FREEZING_RATE_PER_SEC = 0.25,    -- Cold water hypothermia
    },

    -- Acoustic Stealth & Noise Detection
    NOISE = {
        CROUCH_WALK = 8,                 -- Range in studs
        NORMAL_WALK = 22,
        SPRINT = 55,
        SALT_CRUNCH_BOOST = 1.3,         -- Running on dry salt crust creates extra acoustic crackle
        WATER_SPLASH_BOOST = 1.7,        -- Sloshing through brine
        FLASHLIGHT_CLICK_RANGE = 18,
    },

    -- Monster: "El Vigilante de la Sal" (The Salinized Stalker)
    MONSTER = {
        DEFAULT_WALK_SPEED = 12,
        CHASE_WALK_SPEED = 24,
        HEARING_RADIUS = 75,
        FIELD_OF_VIEW_DEG = 80,
        SIGHT_RANGE = 60,
        KILL_DISTANCE = 4.2,
        SUBMERGE_SPEED = 18,
    }
}

return table.freeze(GameConfig)
