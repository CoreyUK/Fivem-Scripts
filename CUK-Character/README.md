# CUK-Character

A lightweight character saving and loading bridge for FiveM, designed to work seamlessly with `fivem-appearance` and `oxmysql`.

## 🌟 Features
* **Auto-Load on Spawn:** Automatically retrieves and applies the player's saved appearance when they join the server.
* **Database Integration:** Uses `oxmysql` to store appearance data as JSON strings linked to player licenses.
* **New Player Detection:** If no saved skin is found, the customization menu opens automatically for the player.
* **Manual Customization:** Players can use a command to re-open the menu at any time.

## 📋 Requirements
This resource requires the following dependencies to function:
* **oxmysql** (For database management)
* **fivem-appearance** (For the customization UI and skin logic)

## 🛠️ Installation
1. Ensure the `player_skins` table exists in your database (see **SQL Schema** below).
2. Download the `CUK-Character` folder and place it in your `resources` directory.
3. Add the following to your `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure fivem-appearance
   ensure CUK-Character
💾 SQL Schema
Run this query in your database to create the required table:

SQL
CREATE TABLE IF NOT EXISTS `player_skins` (
  `identifier` varchar(100) NOT NULL,
  `skin_data` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`)
);
⌨️ Commands
/customise: Opens the appearance menu to edit your character's look.

Developed for the <span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span> server project.
