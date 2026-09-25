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
    -- Color correction: Cold, desaturated, high contrast
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "EpecuenGrade"
    colorCorrection.Brightness = -0.05
    colorCorrection.Contrast = 0.22
    colorCorrection.Saturation = -0.45 -- Desaturated bleak ghost-town feel
    colorCorrection.TintColor = Color3.fromRGB(225, 235, 245) -- Pale salt-white hue
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
            colorCorrection.Brightness = -0.2
        else
            colorCorrection.TintColor = Color3.fromRGB(225, 235, 245)
            colorCorrection.Brightness = -0.05
        end
    end
end

return AtmosphereController
