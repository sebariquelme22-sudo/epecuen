--!strict
--[[
    MainClient.client.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterPlayer/StarterPlayerScripts/EpecuenClient/MainClient (LocalScript)
    Description: Primary client bootstrap. Initializes controllers for psychological sanity,
                 flashlight mechanics, footstep sound detection, and atmosphere post-processing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer

print("==================================================")
print(`  EPECUÉN: NO ESCAPE — Client Starting ({LocalPlayer.Name})`)
print("==================================================")

-- Ensure shared packages exist
local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared", 15)
if not EpecuenShared then
    error("[MainClient] EpecuenShared folder missing from ReplicatedStorage!")
end

local ControllersFolder = script.Parent:WaitForChild("Controllers")
local SanityController = require(ControllersFolder:WaitForChild("SanityController") :: ModuleScript)
local FlashlightController = require(ControllersFolder:WaitForChild("FlashlightController") :: ModuleScript)
local FootstepSaltController = require(ControllersFolder:WaitForChild("FootstepSaltController") :: ModuleScript)
local AtmosphereController = require(ControllersFolder:WaitForChild("AtmosphereController") :: ModuleScript)
local ParanormalEncounterController = require(ControllersFolder:WaitForChild("ParanormalEncounterController") :: ModuleScript)

-- Initialize all client subsystems
AtmosphereController.Init()
SanityController.Init()
FlashlightController.Init()
FootstepSaltController.Init()
ParanormalEncounterController.Init()

print("[MainClient] EPECUÉN: NO ESCAPE client controllers successfully loaded.")
