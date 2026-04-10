# CUK-Spawner

A streamlined, user-friendly vehicle spawning system for the **<span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span>** server. This script allows players to quickly access their favorite vehicles through a simple command or a categorized menu.

## 🌟 Features
* **Command-Based Spawning:** Quickly spawn any vehicle by model name using `/v [modelname]`.
* **Integrated Menu:** Works in tandem with the `CUK-Menu` system to provide a categorized list of vehicles (Super, Sports, Off-Road, etc.).
* **Smart Placement:** Automatically places the player inside the vehicle upon spawning.
* **Auto-Cleanup:** Deletes the player's previous spawned vehicle to prevent server clutter and maintain performance.
* **Warp-to-Driver:** Ensures the player is instantly seated in the driver's seat with the engine running.

## 📋 Requirements
* None (Standalone)
* Works on any framework (ESX, QBCore, or Vanilla)
* **Optional:** Designed to integrate with `CUK-Menu` for a GUI experience.

## 🛠️ Installation
1. Download the `CUK-Spawner` folder.
2. Place it into your FiveM `resources` directory.
3. Add the following to your `server.cfg`:
   ```cfg
   ensure CUK-Spawner
⌨️ Commands
/v [model]: Spawns the specified vehicle model (e.g., /v t20).

/dv: Deletes the vehicle the player is currently in or nearest to.

⚙️ Configuration
Open config.lua to manage:

Vehicle Categories: Define which vehicles appear in the menu lists.

Spawn Locations: (If enabled) Set specific coordinates where vehicles are allowed to be created.

Permissions: Adjust who can use the spawning commands (Default: Everyone).

Developed for the <span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span> server project. Free to use and modify.
