-- ============================================================
--  CUK-Loadout  |  client.lua
-- ============================================================

local loadoutGiven    = false
local statLoopStarted = false

-- ── Give full weapon loadout ───────────────────────────────
local function giveLoadout()
    local ped = PlayerPedId()

    for _, weapon in ipairs(Config.Weapons) do
        GiveWeaponToPed(ped, GetHashKey(weapon), Config.AmmoCount, false, false)
    end

    -- Max out ammo for all weapons
    SetPedAmmo(ped, GetHashKey('WEAPON_PISTOL'), Config.AmmoCount)
end

-- ── Infinite stamina & oxygen loop ────────────────────────
local function startStatLoop()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.RefillInterval)

            local ped = PlayerPedId()

            -- Infinite stamina
            ResetPlayerStamina(PlayerId())

            -- Keep weapon ammo topped up
            if loadoutGiven then
                for _, weapon in ipairs(Config.Weapons) do
                    local hash = GetHashKey(weapon)
                    if HasPedGotWeapon(ped, hash, false) then
                        if GetAmmoInPedWeapon(ped, hash) < 100 then
                            AddAmmoToPed(ped, hash, Config.AmmoCount)
                        end
                    end
                end
            end
        end
    end)
end

-- ── Death watcher — resets loadout flag so respawn re-arms ─
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if loadoutGiven and IsEntityDead(PlayerPedId()) then
            loadoutGiven = false
        end
    end
end)

-- ── Trigger on spawn / respawn ────────────────────────────
AddEventHandler('playerSpawned', function()
    Citizen.SetTimeout(500, function()
        giveLoadout()
        loadoutGiven = true

        if not statLoopStarted then
            statLoopStarted = true
            startStatLoop()
        end
    end)
end)

-- ── Also apply on resource start if already spawned ───────
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    Citizen.SetTimeout(1000, function()
        if NetworkIsPlayerActive(PlayerId()) then
            giveLoadout()
            loadoutGiven = true

            if not statLoopStarted then
                statLoopStarted = true
                startStatLoop()
            end
        end
    end)
end)
