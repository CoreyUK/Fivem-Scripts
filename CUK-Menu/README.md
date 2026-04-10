# CUK-Menu

A clean, responsive interaction menu designed for the **<span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span>** server. This resource provides a centralized UI for player actions, vehicle management, and server-specific utilities.

## 🌟 Features
* **Modern NUI Interface:** A sleek, web-based menu built with HTML/CSS that overlays seamlessly onto the gameplay.
* **Vehicle Management:** Quick access to vehicle repairs, cleaning, and performance tuning.
* **Player Actions:** Quick-access buttons for character customization and player-related tasks.
* **Teleportation Suite:** Integrated teleport options to key locations like the Airport, Custom Shop, and Spawn.
* **Dynamic Content:** Easily expandable categories and buttons via the NUI interface.
* **Smooth Transitions:** Faded UI animations for opening and closing the menu.

## 📋 Requirements
* None (Standalone)
* Works on any framework (ESX, QBCore, or Vanilla)

## 🛠️ Installation
1. Download the `CUK-Menu` folder.
2. Place it into your FiveM `resources` directory.
3. Add the following to your `server.cfg`:
   ```cfg
   ensure CUK-Menu
   ```

## ⌨️ Controls
Open Menu: Press [F1] (Default) to toggle the menu interface.

Navigation: Use your Arrow keys to interact with the buttons.

Exit: Click the "Close" button or press [ESC] to return to the game.

⚙️ Configuration
The menu buttons and actions are primarily managed through client.lua and index.html. You can customize the destination coordinates for teleports or add new functionality by adding event listeners to the NUI callbacks.

Developed for the <span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span> server project. Free to use and modify.
