-- client.lua
local activeTrial         = nil
local currentCheckpoint   = 0
local startTime           = 0
local topTimes            = {}   
local requestedTimes      = {}   
local personalBest        = nil
local serverBest          = nil
local currentCheckpointHandle = nil
local activeVehicle       = nil
local lastEscalationStage = 0
local lbVisible           = false   
local promptVisible       = false   

-- Anti-Cheat: Forbidden vehicle models
local forbiddenModels = {
    "rhino","khanjali","kuruma2","insurgent","insurgent2",
    "nightshark","apc","chernobog","scarab","scarab2","scarab3"
}

-- ── HELPERS ──────────────────────────────────────────────────────────────────

-- FIX: Added missing Notify function
local function Notify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

local function NuiSend(data)
    SendNUIMessage(data)
end

-- ── BLIPS ────────────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    for id, trial in pairs(Config.Trials) do
        if trial.enabled then
            local blip = AddBlipForCoord(trial.start.x, trial.start.y, trial.start.z)
            SetBlipSprite(blip, trial.blipSprite or 315)
            SetBlipColour(blip, trial.blipColor or 5)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(trial.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

local function CheckVehicleBlacklist(veh)
    if veh == 0 then return false end
    local model = GetEntityModel(veh)
    if GetVehicleClass(veh) == 19 then return true end
    for _, name in ipairs(forbiddenModels) do
        if model == GetHashKey(name) then return true end
    end
    return false
end

local function UpdateTrialGPS(trialId, cpIndex)
    SetWaypointOff()
    local trial = Config.Trials[trialId]
    if trial and trial.checkpoints and trial.checkpoints[cpIndex] then
        SetNewWaypoint(trial.checkpoints[cpIndex].x, trial.checkpoints[cpIndex].y)
    end
end

local function SetRaceCheckpoint(coords, nextCoords, radius, isFinish)
    if currentCheckpointHandle then DeleteCheckpoint(currentCheckpointHandle) end
    local cpType = isFinish and 4 or 0
    local nx, ny, nz = 0, 0, 0
    if nextCoords then nx, ny, nz = nextCoords.x, nextCoords.y, nextCoords.z end
    currentCheckpointHandle = CreateCheckpoint(cpType, coords.x, coords.y, coords.z, nx, ny, nz, radius, 255, 165, 0, 150, 0)
    SetCheckpointCylinderHeight(currentCheckpointHandle, 5.0, 5.0, radius)
end

local function CleanupTrial()
    activeTrial           = nil
    lastEscalationStage   = 0
    activeVehicle         = nil
    personalBest          = nil
    serverBest            = nil
    if currentCheckpointHandle then DeleteCheckpoint(currentCheckpointHandle) end
    SetWaypointOff()
    NuiSend({ type = "hud:hide" })
    NuiSend({ type = "prompt:hide" })
    NuiSend({ type = "cancel:hide" })
    promptVisible = false
    lbVisible     = false -- Reset LB tracking
    LocalPlayer.state:set("trialActive", false, false)
end

local function ShowFinishScreen(trialName, timeSec, vehName, isSurvival, isPb, success)
    if success then
        PlaySoundFrontend(-1, isSurvival and "ERROR" or "RACE_PLACED_FIRST", "HUD_AWARDS", 1)
    else
        PlaySoundFrontend(-1, "Bed", "WastedSounds", 1)
    end
    
    NuiSend({
        type       = "finish:show",
        trialName  = trialName,
        time       = timeSec,
        vehicle    = vehName,
        isSurvival = isSurvival,
        isPb       = isPb or false,
        success    = success,
    })
end

-- ── ESCALATION (Survival) ─────────────────────────────────────────────────────
local function SpawnHostilePed(modelName, x, y, z, weaponName)
    local model = GetHashKey(modelName)
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(0) end
    if not HasModelLoaded(model) then return end
    local ped = CreatePed(4, model, x, y, z, 0.0, true, false)
    SetPedRelationshipGroupHash(ped, GetHashKey("COP"))
    SetPedAsCop(ped, true)
    SetPedAccuracy(ped, 80)
    SetPedArmour(ped, 200)
    GiveWeaponToPed(ped, GetHashKey(weaponName), 999, false, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    SetModelAsNoLongerNeeded(model)
    return ped
end

local function SpawnPursuitHeli(playerPed)
    local pos = GetEntityCoords(playerPed)
    local heliModel = GetHashKey("buzzard2")
    RequestModel(heliModel)
    local t = GetGameTimer()
    while not HasModelLoaded(heliModel) and GetGameTimer() - t < 3000 do Wait(0) end
    if not HasModelLoaded(heliModel) then return end
    local heli = CreateVehicle(heliModel, pos.x + 30.0, pos.y + 30.0, pos.z + 60.0, 0.0, true, false)
    local pilot = CreatePedInsideVehicle(heli, 4, GetHashKey("s_m_y_cop_01"), -1, true, false)
    local gunner = CreatePedInsideVehicle(heli, 4, GetHashKey("s_m_y_swat_01"), 0, true, false)
    SetPedAsCop(pilot, true)
    SetPedAsCop(gunner, true)
    SetPedAccuracy(gunner, 70)
    SetPedArmour(gunner, 200)
    GiveWeaponToPed(gunner, GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    TaskCombatPed(gunner, playerPed, 0, 16)
    TaskHeliChase(pilot, playerPed, 0.0, 0.0, 0.0)
    SetModelAsNoLongerNeeded(heliModel)
end

local function SpawnNooseVan(playerPed)
    local pos = GetEntityCoords(playerPed)
    local vanModel = GetHashKey("fbi2")
    RequestModel(vanModel)
    local t = GetGameTimer()
    while not HasModelLoaded(vanModel) and GetGameTimer() - t < 3000 do Wait(0) end
    if not HasModelLoaded(vanModel) then return end
    local angle = math.rad(math.random(0, 360))
    local spawnX = pos.x + math.cos(angle) * 60.0
    local spawnY = pos.y + math.sin(angle) * 60.0
    local van = CreateVehicle(vanModel, spawnX, spawnY, pos.z, 0.0, true, false)
    for i = 1, 4 do
        local seat = i == 1 and -1 or (i - 2)
        local p = CreatePedInsideVehicle(van, 4, GetHashKey("s_m_y_swat_01"), seat, true, false)
        SetPedAsCop(p, true)
        SetPedAccuracy(p, 85)
        SetPedArmour(p, 200)
        GiveWeaponToPed(p, GetHashKey("WEAPON_SPECIALCARBINE"), 999, false, true)
        if seat ~= -1 then
            TaskCombatPed(p, playerPed, 0, 16)
        end
    end
    SetModelAsNoLongerNeeded(vanModel)
end

local function CheckEscalation(seconds, ped)
    if seconds >= 60 and lastEscalationStage < 1 then
        lastEscalationStage = 1
        SetPlayerWantedLevel(PlayerId(), 4, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        Notify("~o~ESCALATION: ~w~4-Star Pursuit!")

    elseif seconds >= 120 and lastEscalationStage < 2 then
        lastEscalationStage = 2
        SetPlayerWantedLevel(PlayerId(), 5, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        AnimpostfxPlay("CamPushInNeutral", 1000, false)
        Notify("~r~ESCALATION: ~w~5-Star — You're a marked target!")

    elseif seconds >= 180 and lastEscalationStage < 3 then
        lastEscalationStage = 3
        SpawnPursuitHeli(ped)
        Notify("~r~ESCALATION: ~w~NOOSE Helicopter inbound!")

    elseif seconds >= 240 and lastEscalationStage < 4 then
        lastEscalationStage = 4
        SpawnNooseVan(ped)
        Notify("~r~ESCALATION: ~w~NOOSE Rapid Response Team!")

    elseif seconds >= 300 and lastEscalationStage < 5 then
        lastEscalationStage = 5
        SpawnPursuitHeli(ped)
        SpawnNooseVan(ped)
        Notify("~r~ESCALATION: ~w~Full Lockdown — Everything is hunting you!")
    end
end

-- ── HUD TICK THREAD ──────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(50)
        if activeTrial then
            local trialData   = Config.Trials[activeTrial]
            local currentTime = (GetGameTimer() - startTime) / 1000
            NuiSend({
                type = "hud:tick",
                time = currentTime,
                pb   = (not trialData.isSurvival) and personalBest or nil,
                wr   = (not trialData.isSurvival) and serverBest  or nil,
            })
        end
    end
end)

-- ── MAIN LOOP ─────────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerId  = PlayerId()
        local ped       = PlayerPedId()
        local coords    = GetEntityCoords(ped)
        local nearAny   = false
        local promptNow = false

        for id, trial in pairs(Config.Trials) do
            local dist = #(coords - trial.start)

            if dist < 30.0 and not activeTrial then
                nearAny = true
                if not requestedTimes[id] then
                    requestedTimes[id] = true
                    TriggerServerEvent('timetrials:requestTop', id)
                end
                if topTimes[id] and lbVisible ~= id then
                    NuiSend({
                        type       = "lb:show",
                        title      = trial.name,
                        isSurvival = trial.isSurvival or false,
                        entries    = topTimes[id],
                    })
                    lbVisible = id
                end
                DrawMarker(22, trial.start.x, trial.start.y, trial.start.z + 0.8, 0,0,0, 0,0,0, 1.0,1.0,1.0, 255,255,255,180, true,true,2,false)
            end

            if dist < 5.0 and not activeTrial then
                promptNow = true
                local label = trial.isSurvival and "SURVIVAL" or "RACE"
                if not promptVisible then
                    NuiSend({ type = "prompt:show", label = label })
                    promptVisible = true
                end

                if IsControlJustPressed(0, 38) then -- E
                    NuiSend({ type = "prompt:hide" })
                    NuiSend({ type = "lb:hide" })
                    promptVisible = false
                    lbVisible     = false

                    local currentVeh = GetVehiclePedIsIn(ped, false)
                    if currentVeh ~= 0 and CheckVehicleBlacklist(currentVeh) then
                        DeleteVehicle(currentVeh)
                    else
                        activeTrial = id
                        NuiSend({ type = "cancel:show" })
                        LocalPlayer.state:set("trialActive", true, false)
                        TriggerServerEvent('timetrials:getPB', id)

                        if trial.isSurvival then
                            SetPlayerWantedLevel(playerId, 3, false)
                            SetPlayerWantedLevelNow(playerId, false)
                            startTime = GetGameTimer()
                            PlaySoundFrontend(-1, "On_Call_Player_Ready", "DLC_VW_Casino_Lucky_Wheel_Sounds", 1)
                        else
                            if currentVeh ~= 0 then
                                activeVehicle     = currentVeh
                                currentCheckpoint = 1
                                FreezeEntityPosition(activeVehicle, true)
                                for i = 3, 1, -1 do
                                    PlaySoundFrontend(-1, "Count_Down", "DLC_VW_Casino_Lucky_Wheel_Sounds", 1)
                                    NuiSend({ type = "countdown:show", num = i })
                                    local t = GetGameTimer()
                                    while GetGameTimer() - t < 1000 do
                                        Wait(0)
                                        DisableControlAction(0, 71, true)
                                    end
                                end
                                NuiSend({ type = "countdown:hide" })
                                FreezeEntityPosition(activeVehicle, false)
                                startTime = GetGameTimer()
                                UpdateTrialGPS(id, 1)
                                SetRaceCheckpoint(trial.checkpoints[1], trial.checkpoints[2], trial.radius, (#trial.checkpoints == 1))
                            else
                                activeTrial = nil
                                PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", 1)
                            end
                        end
                    end
                end
            end

            if activeTrial == id then
                local trialData   = Config.Trials[activeTrial]
                local currentTime = (GetGameTimer() - startTime) / 1000

                -- FIX: Cancel with X
                if IsControlJustPressed(0, 73) then
                    ClearPlayerWantedLevel(playerId)
                    CleanupTrial()
                    Notify("~y~Trial Cancelled.")
                end

                -- FIX: Exit vehicle fail
                if not trialData.isSurvival and activeVehicle then
                    if not IsPedInVehicle(ped, activeVehicle, false) then
                        ClearPlayerWantedLevel(playerId)
                        ShowFinishScreen(trialData.name, currentTime, "Walk of Shame", false, false, false)
                        CleanupTrial()
                    end
                end

                if activeTrial == id then -- Safety check
                    if trialData.isSurvival then
                        CheckEscalation(currentTime, ped)
                        if IsEntityDead(ped) then
                            TriggerServerEvent('timetrials:saveTime', id, currentTime, "Infantry")
                            ShowFinishScreen(trialData.name, currentTime, "On Foot", true, false, true)
                            ClearPlayerWantedLevel(playerId)
                            CleanupTrial()
                        end
                    else
                        local cp = trialData.checkpoints[currentCheckpoint]
                        if cp and #(GetEntityCoords(ped) - cp) < trialData.radius then
                            if currentCheckpoint == #trialData.checkpoints then
                                local vehicleModel = GetEntityModel(activeVehicle)
                                local vehicleName  = GetLabelText(GetDisplayNameFromVehicleModel(vehicleModel))
                                if vehicleName == "NULL" then vehicleName = GetDisplayNameFromVehicleModel(vehicleModel) end
                                TriggerServerEvent('timetrials:saveTime', id, currentTime, vehicleName)
                                ShowFinishScreen(trialData.name, currentTime, vehicleName, false, (personalBest == nil or currentTime < personalBest), true)
                                CleanupTrial()
                            else
                                PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
                                currentCheckpoint = currentCheckpoint + 1
                                UpdateTrialGPS(id, currentCheckpoint)
                                SetRaceCheckpoint(trialData.checkpoints[currentCheckpoint], trialData.checkpoints[currentCheckpoint + 1], trialData.radius, (currentCheckpoint == #trialData.checkpoints))
                            end
                        end
                    end
                end
            end
        end

        if not promptNow and promptVisible then
            NuiSend({ type = "prompt:hide" })
            promptVisible = false
        end
        if not nearAny and lbVisible then
            NuiSend({ type = "lb:hide" })
            lbVisible = false
        end
    end
end)

-- ── NET EVENTS ────────────────────────────────────────────────────────────────
RegisterNetEvent('timetrials:receivePB')
AddEventHandler('timetrials:receivePB', function(pb)
    personalBest = pb
end)

RegisterNetEvent('timetrials:receiveTop')
AddEventHandler('timetrials:receiveTop', function(trialId, data)
    topTimes[trialId] = data or {}
    if data and data[1] then serverBest = data[1].time end
    if lbVisible == trialId then
        local trial = Config.Trials[trialId]
        if trial then
            NuiSend({
                type       = "lb:show",
                title      = trial.name,
                isSurvival = trial.isSurvival or false,
                entries    = topTimes[trialId],
            })
        end
    end
end)