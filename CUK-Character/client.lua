-- Apply skin from DB
RegisterNetEvent('cuk_character:applySkin', function(appearance)
    exports['fivem-appearance']:setPlayerAppearance(appearance)
end)

-- Open the menu
RegisterNetEvent('cuk_character:openMenu', function()
    local config = {
        ped = true, headBlend = true, faceFeatures = true,
        headOverlays = true, components = true, props = true,
    }
    
    exports['fivem-appearance']:startPlayerCustomization(function (appearance)
        if (appearance) then
            TriggerServerEvent('cuk_character:saveSkin', appearance)
        end
    end, config)
end)

-- Command to manually edit character
RegisterCommand('customise', function()
    TriggerEvent('cuk_character:openMenu')
end)

-- Auto-load on spawn
AddEventHandler('playerSpawned', function()
    Wait(250) -- Give the game a second to settle
    TriggerServerEvent('cuk_character:loadSkin')
end)