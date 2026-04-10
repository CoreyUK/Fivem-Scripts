-- server.lua
local function formatTime(seconds)
    return string.format("%d:%06.3f", math.floor(seconds/60), seconds % 60)
end

-- List of IDs that use Survival Logic (Ranking HIGHEST time first)
-- Add any new Survival trial IDs to this list
local survivalIds = { 
    [7] = true, -- Mission Row Survival
    [8] = true, -- Sandy Shores Survival
    [9] = true  -- Military Base Survival
}

-- Auto-Create Table (Ghost data column removed for optimization)
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `time_trials` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `trial_id` INT NOT NULL,
                `player_name` VARCHAR(50) NOT NULL,
                `car_name` VARCHAR(50) NOT NULL,
                `time` FLOAT NOT NULL,
                `date` DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY `unique_run` (`trial_id`, `player_name`, `car_name`)
            )
        ]])
        print("^2[TimeTrials] Database ready for CUKServers!^7")
    end
end)

-- Fetch Personal Best for the HUD Delta Timer
RegisterNetEvent('timetrials:getPB')
AddEventHandler('timetrials:getPB', function(trialId)
    local src = source
    local playerName = GetPlayerName(src)
    local isSurvival = survivalIds[trialId]

    -- For Survival, PB is the MAX time. For Racing, PB is the MIN time.
    local query = isSurvival and 'SELECT MAX(time) FROM time_trials WHERE trial_id = ? AND player_name = ?' 
                              or 'SELECT MIN(time) FROM time_trials WHERE trial_id = ? AND player_name = ?'

    MySQL.Async.fetchScalar(query, { trialId, playerName }, function(bestTime)
        TriggerClientEvent('timetrials:receivePB', src, bestTime)
    end)
end)

-- Save time (Handles both Race and Survival records)
RegisterNetEvent('timetrials:saveTime')
AddEventHandler('timetrials:saveTime', function(trialId, time, carName)
    local src = source
    local playerName = GetPlayerName(src)
    local isSurvival = survivalIds[trialId]

    -- Survival Logic: New time must be GREATER than old time to update.
    -- Racing Logic: New time must be LOWER than old time to update.
    local updateCondition = isSurvival and "VALUES(time) > time" or "VALUES(time) < time"

    MySQL.Async.execute([[
        INSERT INTO time_trials (trial_id, player_name, car_name, time) 
        VALUES (?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE 
        time = IF(]] .. updateCondition .. [[, VALUES(time), time),
        date = IF(]] .. updateCondition .. [[, CURRENT_TIMESTAMP, date)
    ]], {trialId, playerName, carName, time}, function(rowsChanged)
        local modeName = isSurvival and "Survived" or "Finished"
        print(string.format("^3[TimeTrials] %s %s Trial #%s with %s.^7", playerName, modeName, trialId, formatTime(time)))
    end)
end)

-- Request top 5 Leaderboard
RegisterNetEvent('timetrials:requestTop')
AddEventHandler('timetrials:requestTop', function(trialId)
    local src = source
    
    -- Survival shows longest survivors (DESC), Races show fastest laps (ASC)
    local order = survivalIds[trialId] and "DESC" or "ASC"
    
    MySQL.Async.fetchAll('SELECT player_name, car_name, time FROM time_trials WHERE trial_id = ? ORDER BY time ' .. order .. ' LIMIT 5', {
        trialId
    }, function(result)
        TriggerClientEvent('timetrials:receiveTop', src, trialId, result)
    end)
end)