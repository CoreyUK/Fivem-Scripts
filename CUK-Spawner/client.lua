-- ============================================================
--  CUK-Spawner  |  client.lua
-- ============================================================

-- ── State ──────────────────────────────────────────────────
local hasSpawned   = false
local lastLocation = nil
local menuOpen     = false

-- ── Helpers ───────────────────────────────────────────────
local function freezePlayer(state)
    local ped = PlayerPedId()
    SetPlayerControl(PlayerId(), not state, 0)
    SetEntityVisible(ped, not state, false)
    SetEntityCollision(ped, not state, true)
    FreezeEntityPosition(ped, state)
    SetPlayerInvincible(PlayerId(), state)
end

local function doSpawn(spawnData)
    freezePlayer(true)
    DoScreenFadeOut(300)

    while not IsScreenFadedOut() do
        Citizen.Wait(0)
    end

    local ped = PlayerPedId()

    RequestCollisionAtCoord(spawnData.x, spawnData.y, spawnData.z)
    SetEntityCoordsNoOffset(ped, spawnData.x, spawnData.y, spawnData.z, false, false, false, true)
    NetworkResurrectLocalPlayer(spawnData.x, spawnData.y, spawnData.z, spawnData.heading, true, true, false)
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped)
    ClearPlayerWantedLevel(PlayerId())

    local deadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        Citizen.Wait(0)
    end

    ShutdownLoadingScreen()
    DoScreenFadeIn(500)

    while not IsScreenFadedIn() do
        Citizen.Wait(0)
    end

    freezePlayer(false)

    hasSpawned = true
    menuOpen   = false

    TriggerEvent('playerSpawned', spawnData)
    SetNuiFocus(false, false)

    StartSaveLoop()
end

-- ── NUI callbacks ──────────────────────────────────────────
RegisterNUICallback('spawnAtPreset', function(data, cb)
    local idx = tonumber(data.index)
    if Config.PresetSpawns[idx] then
        doSpawn(Config.PresetSpawns[idx])
    end
    cb('ok')
end)

RegisterNUICallback('spawnAtLast', function(data, cb)
    if lastLocation then
        doSpawn(lastLocation)
    end
    cb('ok')
end)

-- ── Show the spawn-selection menu ─────────────────────────
local function openSpawnMenu(withLastLocation)
    menuOpen = true
    SetNuiFocus(true, true)

    local presets = {}
    for i, sp in ipairs(Config.PresetSpawns) do
        presets[i] = { index = i, label = sp.label }
    end

    SendNUIMessage({
        action          = 'openMenu',
        hasLastLocation = withLastLocation,
        presets         = presets,
    })
end

-- ── Entry point ────────────────────────────────────────────
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if hasSpawned then return end
    Citizen.SetTimeout(1000, function()
        TriggerServerEvent('customspawner:getLastLocation')
    end)
end)

-- ── Receive last location from server ─────────────────────
RegisterNetEvent('customspawner:receiveLastLocation', function(row)
    if row then
        lastLocation = {
            x       = row.x,
            y       = row.y,
            z       = row.z,
            heading = row.heading,
            label   = "Last Location",
        }
        openSpawnMenu(true)
    else
        openSpawnMenu(false)
    end
end)

-- ── Periodic location save ─────────────────────────────────
local saveLoopRunning = false

local function saveCurrentLocation()
    local ped = PlayerPedId()
    if not IsEntityDead(ped) then
        local pos = GetEntityCoords(ped)
        local hdg = GetEntityHeading(ped)
        TriggerServerEvent('customspawner:saveLocation', pos.x, pos.y, pos.z, hdg)
    end
end

function StartSaveLoop()
    if saveLoopRunning then return end
    saveLoopRunning = true

    Citizen.CreateThread(function()
        while hasSpawned do
            Citizen.Wait(Config.SaveInterval)
            saveCurrentLocation()
        end
        saveLoopRunning = false
    end)
end

-- ── Save on disconnect / resource stop ────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if not hasSpawned then return end
    saveCurrentLocation()
end)

-- Server requests a final save when the player disconnects
RegisterNetEvent('customspawner:requestFinalSave', function()
    if not hasSpawned then return end
    saveCurrentLocation()
end)

-- ── Respawn on death ──────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if hasSpawned and IsEntityDead(PlayerPedId()) then
            hasSpawned = false
            saveLoopRunning = false

            -- Wait for the wasted screen to appear then trigger respawn menu
            Citizen.Wait(3000)

            -- Force resurrect before showing menu, otherwise coords are stuck
            local ped = PlayerPedId()
            NetworkResurrectLocalPlayer(
                GetEntityCoords(ped).x,
                GetEntityCoords(ped).y,
                GetEntityCoords(ped).z,
                GetEntityHeading(ped), true, true, false
            )
            ClearPedTasksImmediately(ped)

            Citizen.Wait(500)
            TriggerServerEvent('customspawner:getLastLocation')
        end
    end
end)