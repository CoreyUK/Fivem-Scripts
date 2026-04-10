-- ============================================================
--  CUK-Spawner  |  server.lua
-- ============================================================

-- Create table on resource start
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    exports.oxmysql:query([[
        CREATE TABLE IF NOT EXISTS `player_spawns` (
            `license`  VARCHAR(60)  NOT NULL PRIMARY KEY,
            `x`        FLOAT        NOT NULL DEFAULT 0,
            `y`        FLOAT        NOT NULL DEFAULT 0,
            `z`        FLOAT        NOT NULL DEFAULT 0,
            `heading`  FLOAT        NOT NULL DEFAULT 0,
            `updated`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
end)

-- Returns the player's license identifier
local function getLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- ── Fetch last known location ──────────────────────────────
RegisterNetEvent('customspawner:getLastLocation', function()
    local src     = source
    local license = getLicense(src)

    if not license then
        TriggerClientEvent('customspawner:receiveLastLocation', src, nil)
        return
    end

    exports.oxmysql:single(
        'SELECT x, y, z, heading FROM player_spawns WHERE license = ?',
        { license },
        function(row)
            TriggerClientEvent('customspawner:receiveLastLocation', src, row)
        end
    )
end)

-- ── Save current location ──────────────────────────────────
RegisterNetEvent('customspawner:saveLocation', function(x, y, z, heading)
    local src     = source
    local license = getLicense(src)

    if not license then return end

    exports.oxmysql:query(
        [[
            INSERT INTO player_spawns (license, x, y, z, heading)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE x = VALUES(x), y = VALUES(y),
                                    z = VALUES(z), heading = VALUES(heading)
        ]],
        { license, x, y, z, heading }
    )
end)

-- ── Save location on player drop (disconnect) ──────────────
AddEventHandler('playerDropped', function()
    local src     = source
    local license = getLicense(src)

    if not license then return end

    -- Request the client to send their final position before dropping
    TriggerClientEvent('customspawner:requestFinalSave', src)
end)
