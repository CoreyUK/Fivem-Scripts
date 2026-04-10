# CUK-Loadout

A standalone utility for the **<span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span>** server that ensures players are always battle-ready with a full arsenal and peak physical stats.

## 🌟 Features
* **Automatic Arsenal:** Automatically grants a comprehensive list of weapons upon player spawn or resource restart.
* **Infinite Vitality:** Provides unlimited stamina, ensuring players never get tired while sprinting.
* **Auto-Refill Ammo:** A background loop constantly checks and tops up ammunition so you never run dry in a fight.
* **Death Management:** Smartly detects player death to re-apply the full loadout and stats immediately upon respawn.
* **Fully Configurable:** Easily add or remove weapons and adjust refill intervals via the config file.

## 📋 Requirements
* None (Standalone)
* Works on any framework (ESX, QBCore, or Vanilla)

## 🛠️ Installation
1.  Download the `CUK-Loadout` folder.
2.  Place it into your FiveM `resources` directory.
3.  Add the following to your `server.cfg`:
    ```cfg
    ensure CUK-Loadout
    ```

## ⚙️ Configuration
Open `config.lua` to customize the following:
* **Config.AmmoCount:** Set the amount of ammo given (default is 9999).
* **Config.RefillInterval:** How often the script checks to refill stamina and ammo (in milliseconds).
* **Config.Weapons:** A massive list containing all GTA V weapons from Melee to Heavy launchers. Simply comment out a line to remove a weapon from the spawn loadout.

---
*Developed for the <span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span> server project. Free to use and modify.*
