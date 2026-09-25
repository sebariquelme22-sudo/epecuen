--!strict
--[[
    CarPartProgressHUDBootstrap.client.luau
    Project: EPECUÉN: NO ESCAPE
    Location: StarterGui/CarPartProgressHUDBootstrap.client.luau (LocalScript)
    Description: Client bootstrap LocalScript that locates and executes the
                 diegetic Fiat Cronos CarPartProgressHUD module at client startup.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

--- Locates the existing CarPartProgressHUD ModuleScript safely across client contexts.
local function resolveHUDModule(): ModuleScript?
    -- 1. Check under script.Parent (replicated directly in PlayerGui)
    local direct = script.Parent:FindFirstChild("CarPartProgressHUD")
    if direct and direct:IsA("ModuleScript") then
        return direct
    end

    -- 2. Search PlayerGui if parent is still assembling
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
        or localPlayer:WaitForChild("PlayerGui", 5) :: PlayerGui?
    if playerGui then
        local inPlayerGui = playerGui:FindFirstChild("CarPartProgressHUD", true)
        if inPlayerGui and inPlayerGui:IsA("ModuleScript") then
            return inPlayerGui
        end
    end

    -- 3. Fallback: StarterGui template
    local inStarterGui = StarterGui:FindFirstChild("CarPartProgressHUD", true)
    if inStarterGui and inStarterGui:IsA("ModuleScript") then
        return inStarterGui
    end

    -- 4. WaitForChild fallback with bounded timeout
    local waited = script.Parent:WaitForChild("CarPartProgressHUD", 5)
    if waited and waited:IsA("ModuleScript") then
        return waited :: ModuleScript
    end

    return nil
end

--- Initializes the client HUD module safely without duplicating GUI or connections.
local function bootstrapHUD(): ()
    local hudModuleScript = resolveHUDModule()
    if not hudModuleScript then
        warn("[CarPartProgressHUDBootstrap] Could not locate CarPartProgressHUD ModuleScript.")
        return
    end

    -- Safely require the module
    local success, CarPartProgressHUD = pcall(function()
        return require(hudModuleScript)
    end)

    if not success or typeof(CarPartProgressHUD) ~= "table" then
        warn(string.format("[CarPartProgressHUDBootstrap] Failed to require CarPartProgressHUD: %s", tostring(CarPartProgressHUD)))
        return
    end

    -- Check if already initialized by the module's internal client trigger
    local isAlreadyInitialized = false
    if typeof(CarPartProgressHUD.IsInitialized) == "function" then
        isAlreadyInitialized = CarPartProgressHUD.IsInitialized()
    end

    -- If not yet initialized, invoke the explicit public Init() entry point exactly once
    if not isAlreadyInitialized then
        if typeof(CarPartProgressHUD.Init) == "function" then
            CarPartProgressHUD.Init()
        end
    end
end

-- Defer execution slightly to ensure PlayerGui hierarchy is ready
task.defer(bootstrapHUD)
