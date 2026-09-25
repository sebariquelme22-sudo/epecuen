--!strict
--[[
    InteractionService.luau
    Project: EPECUÉN: NO ESCAPE
    Location: ServerScriptService/EpecuenServer/Services/InteractionService (ModuleScript)
    Description: Manages puzzle locks, rusted keys, battery pickups, generator switches,
                 and historical diary notes found in the ruins of Villa Epecuén.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EpecuenShared = ReplicatedStorage:WaitForChild("EpecuenShared")
local NetworkBridge = require(EpecuenShared:WaitForChild("NetworkBridge") :: ModuleScript)

local monsterAIService: any = nil
local function getMonsterAIService()
    if not monsterAIService then
        local servicesFolder = script.Parent
        if servicesFolder and servicesFolder:FindFirstChild("MonsterAIService") then
            monsterAIService = require(servicesFolder:FindFirstChild("MonsterAIService") :: ModuleScript)
        end
    end
    return monsterAIService
end

local InteractionService = {}

type PlayerInventory = {
    Batteries: number,
    HasGeneratorFuse: boolean,
    Keys: { [string]: boolean },
    NotesFound: { [string]: boolean },
}

local inventories: { [Player]: PlayerInventory } = {}

function InteractionService.Init()
    Players.PlayerAdded:Connect(function(player)
        inventories[player] = {
            Batteries = 2,
            HasGeneratorFuse = false,
            Keys = {},
            NotesFound = {},
        }
    end)

    Players.PlayerRemoving:Connect(function(player)
        inventories[player] = nil
    end)

    -- Setup auto-discovery of tagged interactive props
    InteractionService.SetupTaggedItems("EpecuenBattery", InteractionService.HandleBatteryPickup)
    InteractionService.SetupTaggedItems("EpecuenNote", InteractionService.HandleNotePickup)
    InteractionService.SetupTaggedItems("EpecuenDoor", InteractionService.HandleDoorInteraction)
    InteractionService.SetupTaggedItems("EpecuenGenerator", InteractionService.HandleGenerator)

    print("[InteractionService] Survival horror interactions ready.")
end

function InteractionService.SetupTaggedItems(tag: string, callback: (player: Player, item: Instance) -> ())
    for _, instance in ipairs(CollectionService:GetTagged(tag)) do
        local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Interact"
            prompt.ObjectText = instance.Name
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 8
            prompt.Parent = instance
        end

        prompt.Triggered:Connect(function(player)
            callback(player, instance)
        end)
    end

    CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
        local prompt = instance:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt")
        prompt.MaxActivationDistance = 8
        prompt.Parent = instance
        prompt.Triggered:Connect(function(player)
            callback(player, instance)
        end)
    end)
end

function InteractionService.HandleBatteryPickup(player: Player, item: Instance)
    local inv = inventories[player]
    if inv then
        inv.Batteries += 1
        item:Destroy()

        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, true, `Found 1x Flashlight Battery (Total: {inv.Batteries})`)
    end
end

function InteractionService.HandleNotePickup(player: Player, item: Instance)
    local inv = inventories[player]
    if inv then
        inv.NotesFound[item.Name] = true
        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, true, `Diary Log: "{item.Name}" added to notebook.`)
    end
end

function InteractionService.HandleDoorInteraction(player: Player, item: Instance)
    local inv = inventories[player]
    local doorKey = item:GetAttribute("RequiredKey") :: string?

    if not doorKey or (inv and inv.Keys[doorKey]) then
        -- Open rusted door
        item:SetAttribute("IsOpen", not item:GetAttribute("IsOpen"))
        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, true, "Rusted hinge groans open...")

        -- Emit noise to attract entities safely on server
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            local monsterAI = getMonsterAIService()
            if monsterAI and monsterAI.OnSoundHeard then
                monsterAI.OnSoundHeard(player, hrp.Position, 30, "DoorCreak")
            end
        end
    else
        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, false, `Padlock is rusted shut. Needs {doorKey or "a key"}.`)
    end
end

function InteractionService.HandleGenerator(player: Player, item: Instance)
    local inv = inventories[player]
    if inv and inv.HasGeneratorFuse then
        item:SetAttribute("Running", true)
        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, true, "Generator rumbles to life! Emergency lights active.")
    else
        local completedEv = NetworkBridge.GetEvent("InteractCompleted")
        completedEv:FireClient(player, item, false, "The thermal spa generator needs an industrial fuse.")
    end
end

function InteractionService.GetInventory(player: Player): PlayerInventory?
    return inventories[player]
end

return InteractionService
