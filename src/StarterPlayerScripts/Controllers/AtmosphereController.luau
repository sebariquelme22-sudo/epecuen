--!strict
--[[
    AtmosphereController.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/EpecuenClient/Controllers/AtmosphereController (ModuleScript)
    Description: Manages post-processing, bleak desaturated Argentine pampas color grade,
                 salt-encrusted vignette, and perpetual howling lakeside wind.
]]

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local AtmosphereController = {}

local colorCorrection: ColorCorrectionEffect?
local bloom: BloomEffect?
local depthOfField: DepthOfFieldEffect?
local windSound: Sound?

function AtmosphereController.Init()
    -- Color correction: Cold, bleak pampas atmosphere with crisp visibility of obstacles and ruins
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "EpecuenGrade"
    colorCorrection.Brightness = 0.04 -- Gentle lift preventing shadow crush while preserving night
    colorCorrection.Contrast = 0.12 -- Softened contrast so shadows are readable rather than impenetrable
    colorCorrection.Saturation = -0.35 -- Desaturated ghost-town feel without losing all color depth
    colorCorrection.TintColor = Color3.fromRGB(225, 235, 245) -- Pale cold salt-white hue
    colorCorrection.Parent = Lighting

    bloom = Instance.new("BloomEffect")
    bloom.Name = "SaltGlare"
    bloom.Intensity = 0.35
    bloom.Size = 24
    bloom.Threshold = 1.8
    bloom.Parent = Lighting

    depthOfField = Instance.new("DepthOfFieldEffect")
    depthOfField.Name = "MistFocus"
    depthOfField.FarIntensity = 0.6
    depthOfField.FocusDistance = 25
    depthOfField.InFocusRadius = 15
    depthOfField.NearIntensity = 0
    depthOfField.Parent = Lighting

    -- Persistent ambient wind sound
    windSound = Instance.new("Sound")
    windSound.Name = "LakesideWind"
    windSound.SoundId = "rbxassetid://9114227097" -- Low howling wind
    windSound.Looped = true
    windSound.Volume = 0.4
    windSound.Parent = SoundService
    windSound:Play()

    print("[AtmosphereController] Bleak atmospheric effects applied.")
end

function AtmosphereController.SetWaterImmersion(inWater: boolean)
    if colorCorrection then
        if inWater then
            colorCorrection.TintColor = Color3.fromRGB(150, 190, 200)
            colorCorrection.Brightness = -0.10
        else
            colorCorrection.TintColor = Color3.fromRGB(225, 235, 245)
            colorCorrection.Brightness = 0.04
        end
    end
end

return AtmosphereController
