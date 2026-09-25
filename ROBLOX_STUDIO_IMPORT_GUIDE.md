# EPECUÉN: NO ESCAPE — Roblox Studio Import Guide

This guide explains how to install and run the Luau scripts for **EPECUÉN: NO ESCAPE** in Roblox Studio.

---

## Method 1: Using Rojo (Recommended)

Rojo syncs files directly from this repository into your active Roblox Studio session automatically.

1. **Install Rojo**:
   - Download the Rojo CLI and the Roblox Studio Plugin from [rojo.space](https://rojo.space/).
2. **Start Rojo Server**:
   - Open a terminal in the project root:
     ```bash
     rojo serve roblox/default.project.json
     ```
3. **Connect in Roblox Studio**:
   - In Roblox Studio, click the **Rojo** plugin button in the Plugins toolbar.
   - Click **Connect** (default port `34872`).
   - All files in `ReplicatedStorage`, `ServerScriptService`, `StarterPlayerScripts`, and `StarterGui` will sync immediately.

---

## Method 2: Manual Copy & Paste (No Rojo required)

If you prefer to copy scripts directly into Roblox Studio's Explorer panel:

### 1. `ReplicatedStorage`
- Create a **Folder** named `EpecuenShared`.
- Inside `EpecuenShared`, create three **ModuleScripts**:
  1. `SanityTypes` ➡️ paste from `roblox/src/ReplicatedStorage/SanityTypes.luau`
  2. `GameConfig` ➡️ paste from `roblox/src/ReplicatedStorage/GameConfig.luau`
  3. `NetworkBridge` ➡️ paste from `roblox/src/ReplicatedStorage/NetworkBridge.luau`

### 2. `ServerScriptService`
- Create a **Folder** named `EpecuenServer`.
- Inside `EpecuenServer`, create a **Folder** named `Services`.
- Inside `Services`, create four **ModuleScripts**:
  1. `SanityService` ➡️ paste from `roblox/src/ServerScriptService/Services/SanityService.luau`
  2. `WaterHazardService` ➡️ paste from `roblox/src/ServerScriptService/Services/WaterHazardService.luau`
  3. `MonsterAIService` ➡️ paste from `roblox/src/ServerScriptService/Services/MonsterAIService.luau`
  4. `InteractionService` ➡️ paste from `roblox/src/ServerScriptService/Services/InteractionService.luau`
- Inside `EpecuenServer` (root level), create a regular **Script**:
  1. `MainServer` ➡️ paste from `roblox/src/ServerScriptService/MainServer.server.luau`

### 3. `StarterPlayer` ➡️ `StarterPlayerScripts`
- Create a **Folder** named `EpecuenClient`.
- Inside `EpecuenClient`, create a **Folder** named `Controllers`.
- Inside `Controllers`, create four **ModuleScripts**:
  1. `SanityController` ➡️ paste from `roblox/src/StarterPlayerScripts/Controllers/SanityController.luau`
  2. `FlashlightController` ➡️ paste from `roblox/src/StarterPlayerScripts/Controllers/FlashlightController.luau`
  3. `FootstepSaltController` ➡️ paste from `roblox/src/StarterPlayerScripts/Controllers/FootstepSaltController.luau`
  4. `AtmosphereController` ➡️ paste from `roblox/src/StarterPlayerScripts/Controllers/AtmosphereController.luau`
- Inside `EpecuenClient` (root level), create a **LocalScript**:
  1. `MainClient` ➡️ paste from `roblox/src/StarterPlayerScripts/MainClient.client.luau`

### 4. `StarterGui`
- Create a **Folder** named `EpecuenGui`.
- Inside `EpecuenGui`, create a **LocalScript**:
  1. `HUDController` ➡️ paste from `roblox/src/StarterGui/HUDController.client.luau`

---

## Setting Up the Map in Workspace

To activate all environmental mechanics:
1. **Water Plane**:
   - Create a Part named `LagunaEpecuenWater`.
   - Set transparency to `0.4`, color to murky dark teal/gray, and size it across the flooded ruins area.
   - `WaterHazardService` will automatically detect players stepping into this plane.
2. **Interactive Items**:
   - Add the tag `EpecuenBattery` using Roblox Studio's **Tag Editor** to small battery props.
   - Add the tag `EpecuenNote` to paper/diary models.
   - Add the tag `EpecuenDoor` to doors. Give the door an attribute named `RequiredKey` if you want it locked.
3. **The Monster ("El Vigilante de la Sal")**:
   - Place an R15 or R6 rigged character inside a folder in Workspace named `Monsters`.
   - Give it a `Humanoid` and `HumanoidRootPart`. `MonsterAIService` will register it automatically!
