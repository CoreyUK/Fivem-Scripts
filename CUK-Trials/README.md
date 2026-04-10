# CUK-Trials

An advanced time-trial and survival racing system designed for the **<span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span>** server. This resource challenges players to beat the clock in traditional races or outlast the heat in survival-style trials.

## 🌟 Features
* **Dual Game Modes:**
    * **Racing:** Classic checkpoint-to-checkpoint time trials where the fastest lap wins.
    * **Survival:** Unique survival logic where players must stay alive or in a zone as long as possible (Leaderboards rank the *longest* time).
* **Dynamic Leaderboards:** Real-time top-5 leaderboards for every trial, stored permanently in your database.
* **Personal Best Tracking:** Displays your individual PB and compares it to the server best during the run.
* **Modern NUI Overlay:** Custom-built interface featuring a countdown timer, finish screen, and leaderboard UI.
* **Anti-Cheat Measures:** Built-in restricted vehicle list (e.g., Rhino, Khanjali) to ensure fair competition.
* **GPS Integration:** Automatically sets and updates GPS waypoints to the next checkpoint.

## 📋 Requirements
* **[oxmysql](https://github.com/overextended/oxmysql)** (For leaderboard and PB storage)

## 🛠️ Installation
1. Download the `CUK-Trials` folder and place it in your `resources` directory.
2. The script will automatically create the `time_trials` table in your database on the first start.
3. Add the following to your `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure CUK-Trials
⌨️ How to Play
Look for the Time Trial blips on your map.

Approach the start location and press [E] to open the leaderboard and prepare.

Once the countdown hits GO, follow the checkpoints.

If you need to quit early, press [F] to cancel the active trial.

⚙️ Configuration
Open config.lua to easily:

Add new trials by defining vector3 coordinates for the start and checkpoints.

Toggle isSurvival = true to switch a trial from racing logic to survival logic.

Customize blip sprites, colors, and checkpoint radii.

Developed for the <span style="color: #FF0000;">Corey</span><span style="color: #FF69B4;">UK</span> server project. Free to use and modify.
