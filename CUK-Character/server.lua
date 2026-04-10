-- Save skin to DB
RegisterNetEvent('cuk_character:saveSkin', function(appearance)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not appearance then return end

    MySQL.Async.execute('INSERT INTO player_skins (identifier, skin_data) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin_data = ?', 
    {license, json.encode(appearance), json.encode(appearance)}, function(rowsChanged)
        print("^2[CUK Character] Skin saved for " .. GetPlayerName(src) .. "^7")
    end)
end)

-- Fetch skin from DB
RegisterNetEvent('cuk_character:loadSkin', function()
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    MySQL.Async.fetchAll('SELECT skin_data FROM player_skins WHERE identifier = ?', {license}, function(result)
        if result and result[1] then
            TriggerClientEvent('cuk_character:applySkin', src, json.decode(result[1].skin_data))
        else
            -- If no skin found, open the menu for them to create one
            TriggerClientEvent('cuk_character:openMenu', src)
        end
    end)
end)