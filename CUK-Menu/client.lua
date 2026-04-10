-- client.lua
local menuOpen = false
local selectedCategory, selectedVehicle = 1, 1
local inSubMenu, inClassMenu, inCustomMenu, inBodyMenu, inNeonMenu, inStanceMenu = false, false, false, false, false, false
local inBuildsMenu = false
local selectedCustom, selectedBodyPart, selectedNeon, selectedClass, selectedStance = 1, 1, 1, 1, 1
local selectedBuild = 1
local driftModeEnabled, maxPerfEnabled = false, false
local godModeEnabled, passiveModeEnabled = false, false
local speedoEnabled = true
local trialActive = false
    LocalPlayer.state:set("trialActive", false, false)  -- set by cuk_trials:started/ended events

local playerPlate = GetResourceKvpString("cuk_custom_plate") or "CUK"
local MasterList = {}
local MAX_BUILDS = 20

-- ─── BUILDS STORAGE ──────────────────────────────────────────────────────────
local function LoadBuilds()
    local raw = GetResourceKvpString("cuk_builds")
    if raw then return json.decode(raw) else return {} end
end

local function SaveBuilds(list)
    SetResourceKvp("cuk_builds", json.encode(list))
end

local function UpsertBuild(model, name, mods)
    local list = LoadBuilds()
    for i, entry in ipairs(list) do
        if entry.model == model then
            list[i].name = name
            list[i].mods = mods
            SaveBuilds(list)
            return
        end
    end
    if #list >= MAX_BUILDS then table.remove(list, #list) end
    table.insert(list, { model = model, name = name, mods = mods })
    SaveBuilds(list)
end

-- ─── UTILITIES ───────────────────────────────────────────────────────────────
local function Notify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

RegisterNetEvent('cuk_character:applySkin', function(appearance)
    exports['fivem-appearance']:setPlayerAppearance(appearance)
end)

RegisterNetEvent('cuk_character:openMenu', function()
    local config = {
        ped = true, headBlend = true, faceFeatures = true,
        headOverlays = true, components = true, props = true,
    }
    exports['fivem-appearance']:startPlayerCustomization(function(appearance)
        if appearance then TriggerServerEvent('cuk_character:saveSkin', appearance) end
    end, config)
end)

local function TeleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local coords = GetBlipInfoIdCoord(waypoint)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local entity = (veh ~= 0) and veh or ped
        local ground, groundZ = false, 0.0
        for z = 0, 1000, 50 do
            SetEntityCoordsNoOffset(entity, coords.x, coords.y, z + 0.0, false, false, false)
            Wait(0)
            ground, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, z + 0.0)
            if ground then groundZ = groundZ + 1.0 break end
        end
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, groundZ or 100.0, false, false, false)
        Notify("~g~Teleported to Waypoint!")
        menuOpen = false
    else
        Notify("~r~No Waypoint Set!")
    end
end

-- ─── GODMODE & PASSIVE ───────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        SetPlayerInvincible(PlayerId(), godModeEnabled)
        if passiveModeEnabled then
            SetEntityAlpha(ped, 150, false)
            SetEntityInvincible(ped, true)
            DisablePlayerFiring(PlayerId(), true)
        else
            ResetEntityAlpha(ped)
            if not godModeEnabled then SetEntityInvincible(ped, false) end
        end
        Wait(godModeEnabled or passiveModeEnabled and 0 or 500)
    end
end)

-- ─── VEHICLE MOD HELPERS ─────────────────────────────────────────────────────
local function GetVehicleMods(veh)
    if not DoesEntityExist(veh) then return nil end
    local r, g, b = GetVehicleNeonLightsColour(veh)
    local mods = {
        primary = {GetVehicleColours(veh)}, wheelType = GetVehicleWheelType(veh),
        drift = driftModeEnabled, perf = maxPerfEnabled, xenon = IsToggleModOn(veh, 22),
        neons = {
            enabled = {
                IsVehicleNeonLightEnabled(veh, 0), IsVehicleNeonLightEnabled(veh, 1),
                IsVehicleNeonLightEnabled(veh, 2), IsVehicleNeonLightEnabled(veh, 3)
            },
            color = {r, g, b}
        },
        mods = {}
    }
    for i = 0, 48 do mods.mods[i] = GetVehicleMod(veh, i) end
    return mods
end

local function SetVehicleMods(veh, data)
    if not DoesEntityExist(veh) or not data then return end
    SetVehicleModKit(veh, 0)
    SetVehicleColours(veh, data.primary[1], data.primary[2])
    SetVehicleWheelType(veh, data.wheelType)
    ToggleVehicleMod(veh, 22, data.xenon or false)
    if data.neons then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, data.neons.enabled[i+1]) end
        SetVehicleNeonLightsColour(veh, data.neons.color[1], data.neons.color[2], data.neons.color[3])
    end
    for k, v in pairs(data.mods) do SetVehicleMod(veh, tonumber(k), v, false) end
    driftModeEnabled, maxPerfEnabled = data.drift or false, data.perf or false
    SetDriftTyresEnabled(veh, driftModeEnabled)
end

local function SpawnVehicle(model, mods)
    local ped = PlayerPedId()
    local curVeh = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(curVeh) then DeleteEntity(curVeh) end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local v = CreateVehicle(model, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, v, -1)
    SetVehicleNumberPlateText(v, playerPlate)
    if mods then SetVehicleMods(v, mods) end
    return v
end

-- ─── VEHICLE PREVIEW ─────────────────────────────────────────────────────────
local previewVeh    = nil
local previewRotating = false

-- Large vehicle classes that need more distance so they don't clip the player
local FAR_CLASSES = {
    [10] = true, -- INDUSTRIAL
    [11] = true, -- UTILITY
    [12] = true, -- VANS
    [14] = true, -- BOATS
    [15] = true, -- HELICOPTERS
    [16] = true, -- PLANES
    [19] = true, -- MILITARY
    [20] = true, -- COMMERCIAL
}

local function GetPreviewDistance(modelHash)
    local class = GetVehicleClassFromName(modelHash)
    if FAR_CLASSES[class] then return 14.0 end
    -- Use model dimensions to fine-tune distance
    local min, max = GetModelDimensions(modelHash)
    local length = math.abs(max.y - min.y)
    if length > 8.0 then return 14.0
    elseif length > 5.0 then return 10.0
    else return 7.0 end
end

local function ClearPreview()
    if DoesEntityExist(previewVeh) then
        DeleteEntity(previewVeh)
    end
    previewVeh = nil
    previewRotating = false
end

local function SpawnPreview(modelHash)
    ClearPreview()
    RequestModel(modelHash)
    local t = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(0)
        if GetGameTimer() - t > 5000 then return end -- timeout after 5s
    end

    local ped     = PlayerPedId()
    local pos     = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local dist    = GetPreviewDistance(modelHash)

    -- Place vehicle directly in front of the player
    local rad = math.rad(heading)
    local spawnX = pos.x + (-math.sin(rad) * dist)
    local spawnY = pos.y + ( math.cos(rad) * dist)

    local v = CreateVehicle(modelHash, spawnX, spawnY, pos.z, heading + 180.0, false, false)
    SetEntityAlpha(v, 180, false)
    SetEntityInvincible(v, true)
    SetVehicleEngineOn(v, false, true, true)
    FreezeEntityPosition(v, true)
    SetEntityCollision(v, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    previewVeh      = v
    previewRotating = true
end

-- Rotation thread — runs continuously, only does work when a preview exists
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if previewRotating and DoesEntityExist(previewVeh) then
            local current = GetEntityHeading(previewVeh)
            SetEntityHeading(previewVeh, (current + 0.8) % 360.0)
        else
            Wait(100) -- sleep when no preview active
        end
    end
end)

-- ─── AUTO-SCANNER ────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    local allModels = GetAllVehicleModels()
    local tempMap = {}
    for _, modelHash in ipairs(allModels) do
        if IsModelInCdimage(modelHash) then
            local class = GetVehicleClassFromName(modelHash)
            local className = Config.VehicleClasses[class]
            if className then
                local label = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
                if label == "NULL" then label = GetDisplayNameFromVehicleModel(modelHash) end
                if not tempMap[className] then tempMap[className] = {} end
                table.insert(tempMap[className], { label = label, model = modelHash })
            end
        end
    end
    for catName, vehList in pairs(tempMap) do
        table.sort(vehList, function(a, b) return a.label < b.label end)
        table.insert(MasterList, { category = catName, list = vehList })
    end
    table.sort(MasterList, function(a, b) return a.category < b.category end)
end)

-- ─── SPEEDO THREAD ───────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    local wasInVeh = false
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inVeh = DoesEntityExist(veh) and veh ~= 0
        if inVeh then
            Wait(50)
            SendNUIMessage({
                type          = "setSpeedo",
                inVehicle     = true,
                speedoEnabled = speedoEnabled,
                data = {
                    speed  = GetEntitySpeed(veh),
                    gear   = GetVehicleCurrentGear(veh),
                    rpm    = GetVehicleCurrentRpm(veh),
                    health = GetVehicleEngineHealth(veh),
                }
            })
            wasInVeh = true
        else
            if wasInVeh then
                -- only send once when leaving vehicle
                SendNUIMessage({ type = "setSpeedo", inVehicle = false, speedoEnabled = speedoEnabled })
                wasInVeh = false
            end
            Wait(500)
        end
    end
end)

-- ─── NUI HELPERS ─────────────────────────────────────────────────────────────
local function NuiSetVisible(visible)
    SendNUIMessage({ type = "setVisible", visible = visible })
end

local function NuiSendMenu(selectedIdx)
    local items = {}
    local title, bc = "", ""

    if inSubMenu then
        title = MasterList[selectedClass].category
        bc    = "VEHICLES › " .. title
        for _, v in ipairs(MasterList[selectedClass].list) do
            table.insert(items, { label = v.label })
        end

    elseif inClassMenu then
        title = "VEHICLES"
        bc    = "MAIN › VEHICLES"
        for _, v in ipairs(MasterList) do
            table.insert(items, { label = v.category, hasArrow = true })
        end

    elseif inBodyMenu then
        title = "BODY SHOP"
        bc    = "MAIN › CUSTOMIZATION › BODY SHOP"
        for _, p in ipairs({"Spoiler","Front Bumper","Rear Bumper","Skirts","Exhaust","Grille","Hood","Roof"}) do
            table.insert(items, { label = p })
        end

    elseif inStanceMenu then
        title = "STANCE"
        bc    = "MAIN › CUSTOMIZATION › STANCE"
        table.insert(items, { label = "Lower Suspension" })
        table.insert(items, { label = "Stock Suspension" })

    elseif inNeonMenu then
        title = "LIGHTS"
        bc    = "MAIN › CUSTOMIZATION › LIGHTS"
        for _, l in ipairs({"Toggle Underglow","Toggle Xenon","Red","Blue","Green","White","Pink","Yellow"}) do
            table.insert(items, { label = l })
        end

    elseif inCustomMenu then
        title = "CUSTOMS"
        bc    = "MAIN › CUSTOMIZATION"
        table.insert(items, { label = "Body Shop",   hasArrow = true })
        table.insert(items, { label = "Stance",      hasArrow = true })
        table.insert(items, { label = "Lighting",    hasArrow = true })
        table.insert(items, { label = "Drift",       badge = true, badgeOn = driftModeEnabled })
        table.insert(items, { label = "Max Perf",    badge = true, badgeOn = maxPerfEnabled })
        table.insert(items, { label = "Random Paint" })
        table.insert(items, { label = "Next Livery" })
        table.insert(items, { label = "Repair" })
        table.insert(items, { label = "Save Car" })

    elseif inBuildsMenu then
        title = "BUILDS"
        bc    = "MAIN › BUILDS"
        local list = LoadBuilds()
        if #list == 0 then
            table.insert(items, { label = "No saved builds", disabled = true })
        else
            for _, entry in ipairs(list) do
                table.insert(items, { label = entry.name })
            end
        end

    else
        title = Config.MenuTitle or "CUK MENU"
        bc    = ""
        table.insert(items, { label = "Vehicles",        hasArrow = true })
        table.insert(items, { label = "Customization",   hasArrow = true })
        table.insert(items, { label = "Builds",          hasArrow = true })
        table.insert(items, { label = "Warp to Waypoint" })
        table.insert(items, { label = "Edit Character" })
        table.insert(items, { label = "Speedo",          badge = true, badgeOn = speedoEnabled })
        table.insert(items, { label = "Passive",         badge = true, badgeOn = passiveModeEnabled })
        table.insert(items, { label = "God Mode",        badge = true, badgeOn = godModeEnabled })
        table.insert(items, { label = "Delete Vehicle",  danger = true })
    end

    SendNUIMessage({
        type       = "setMenu",
        title      = title,
        breadcrumb = bc,
        items      = items,
        selected   = selectedIdx or 1,
    })
end

local function NuiSetSelected(idx)
    SendNUIMessage({ type = "setSelected", selected = idx })
end

local function GetSel()
    if inSubMenu        then return selectedVehicle
    elseif inClassMenu  then return selectedClass
    elseif inBodyMenu   then return selectedBodyPart
    elseif inStanceMenu then return selectedStance
    elseif inNeonMenu   then return selectedNeon
    elseif inCustomMenu then return selectedCustom
    elseif inBuildsMenu then return selectedBuild
    else return selectedCategory end
end

-- ─── MENU TOGGLE (key mapping — works with NUI present) ──────────────────────
local function ToggleMenu()
    if LocalPlayer.state.trialActive then return end  -- M key disabled during trials
    menuOpen = not menuOpen
    if menuOpen then
        NuiSetVisible(true)
        NuiSendMenu(GetSel())
    else
        NuiSetVisible(false)
        ClearPreview()
        inSubMenu, inClassMenu, inCustomMenu = false, false, false
        inBodyMenu, inNeonMenu, inStanceMenu = false, false, false
        inBuildsMenu = false
        selectedCategory = 1
    end
end

RegisterCommand('cuk_togglemenu', ToggleMenu, false)
RegisterKeyMapping('cuk_togglemenu', 'Toggle CUK Menu', 'keyboard', 'M')

-- ─── MAIN LOOP ───────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if menuOpen then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)

            -- ── UP ──
            if IsControlJustPressed(0, 172) then
                if inSubMenu then
                    selectedVehicle = (selectedVehicle > 1) and selectedVehicle - 1 or #MasterList[selectedClass].list
                    SpawnPreview(MasterList[selectedClass].list[selectedVehicle].model)
                elseif inClassMenu then
                    selectedClass = (selectedClass > 1) and selectedClass - 1 or #MasterList
                elseif inBodyMenu then
                    selectedBodyPart = (selectedBodyPart > 1) and selectedBodyPart - 1 or 8
                elseif inStanceMenu then
                    selectedStance = (selectedStance > 1) and selectedStance - 1 or 2
                elseif inNeonMenu then
                    selectedNeon = (selectedNeon > 1) and selectedNeon - 1 or 8
                elseif inCustomMenu then
                    selectedCustom = (selectedCustom > 1) and selectedCustom - 1 or 9
                elseif inBuildsMenu then
                    local cnt = math.max(1, #LoadBuilds())
                    selectedBuild = (selectedBuild > 1) and selectedBuild - 1 or cnt
                else
                    selectedCategory = (selectedCategory > 1) and selectedCategory - 1 or 9
                end
                NuiSetSelected(GetSel())

            -- ── DOWN ──
            elseif IsControlJustPressed(0, 173) then
                if inSubMenu then
                    selectedVehicle = (selectedVehicle < #MasterList[selectedClass].list) and selectedVehicle + 1 or 1
                    SpawnPreview(MasterList[selectedClass].list[selectedVehicle].model)
                elseif inClassMenu then
                    selectedClass = (selectedClass < #MasterList) and selectedClass + 1 or 1
                elseif inBodyMenu then
                    selectedBodyPart = (selectedBodyPart < 8) and selectedBodyPart + 1 or 1
                elseif inStanceMenu then
                    selectedStance = (selectedStance < 2) and selectedStance + 1 or 1
                elseif inNeonMenu then
                    selectedNeon = (selectedNeon < 8) and selectedNeon + 1 or 1
                elseif inCustomMenu then
                    selectedCustom = (selectedCustom < 9) and selectedCustom + 1 or 1
                elseif inBuildsMenu then
                    local cnt = math.max(1, #LoadBuilds())
                    selectedBuild = (selectedBuild < cnt) and selectedBuild + 1 or 1
                else
                    selectedCategory = (selectedCategory < 9) and selectedCategory + 1 or 1
                end
                NuiSetSelected(GetSel())

            -- ── ENTER ──
            elseif IsControlJustPressed(0, 191) then

                if inSubMenu then
                    local entry = MasterList[selectedClass].list[selectedVehicle]
                    ClearPreview()
                    SpawnVehicle(entry.model, nil)
                    menuOpen = false
                    inSubMenu, inClassMenu = false, false
                    NuiSetVisible(false)

                elseif inClassMenu then
                    inSubMenu, selectedVehicle = true, 1
                    NuiSendMenu(1)
                    -- spawn initial preview for first vehicle in this class
                    local entry = MasterList[selectedClass].list[1]
                    SpawnPreview(entry.model)

                elseif inBodyMenu then
                    local mt = {0, 1, 2, 3, 4, 6, 7, 10}
                    SetVehicleModKit(veh, 0)
                    local mid = mt[selectedBodyPart]
                    SetVehicleMod(veh, mid,
                        (GetVehicleMod(veh, mid) + 1 >= GetNumVehicleMods(veh, mid)) and -1
                        or GetVehicleMod(veh, mid) + 1, false)

                elseif inStanceMenu then
                    SetVehicleModKit(veh, 0)
                    SetVehicleMod(veh, 15, (selectedStance == 1) and GetNumVehicleMods(veh, 15)-1 or -1, false)

                elseif inNeonMenu then
                    if selectedNeon == 1 then
                        local s = not IsVehicleNeonLightEnabled(veh, 0)
                        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, s) end
                    elseif selectedNeon == 2 then
                        ToggleVehicleMod(veh, 22, not IsToggleModOn(veh, 22))
                    elseif selectedNeon >= 3 then
                        local colors = {{255,0,0},{0,0,255},{0,255,0},{255,255,255},{255,0,255},{255,255,0}}
                        local c = colors[selectedNeon - 2]
                        SetVehicleNeonLightsColour(veh, c[1], c[2], c[3])
                    end

                elseif inCustomMenu then
                    if selectedCustom == 1 then
                        inBodyMenu = true; NuiSendMenu(1)
                    elseif selectedCustom == 2 then
                        inStanceMenu = true; NuiSendMenu(1)
                    elseif selectedCustom == 3 then
                        inNeonMenu = true; NuiSendMenu(1)
                    elseif selectedCustom == 4 then
                        driftModeEnabled = not driftModeEnabled
                        SetDriftTyresEnabled(veh, driftModeEnabled)
                        NuiSendMenu(selectedCustom)
                    elseif selectedCustom == 5 then
                        maxPerfEnabled = not maxPerfEnabled
                        SetVehicleModKit(veh, 0)
                        local m = maxPerfEnabled and 50 or -1
                        SetVehicleMod(veh, 11, m) SetVehicleMod(veh, 12, m)
                        SetVehicleMod(veh, 13, m) ToggleVehicleMod(veh, 18, maxPerfEnabled)
                        NuiSendMenu(selectedCustom)
                    elseif selectedCustom == 6 then
                        SetVehicleColours(veh, math.random(0, 159), math.random(0, 159))
                    elseif selectedCustom == 7 then
                        SetVehicleLivery(veh, (GetVehicleLivery(veh) + 1) % GetVehicleLiveryCount(veh))
                    elseif selectedCustom == 8 then
                        SetVehicleFixed(veh) SetVehicleDirtLevel(veh, 0.0)
                    elseif selectedCustom == 9 then
                        if DoesEntityExist(veh) then
                            local model = GetEntityModel(veh)
                            local fallback = GetLabelText(GetDisplayNameFromVehicleModel(model))
                            if fallback == "NULL" or fallback == "" then
                                fallback = GetDisplayNameFromVehicleModel(model)
                            end
                            menuOpen = false
                            NuiSetVisible(false)
                            Wait(150)
                            AddTextEntry("CUK_BUILD_INPUT", "Enter build name")
                            DisplayOnscreenKeyboard(1, "CUK_BUILD_INPUT", "", fallback, "", "", "", 30)
                            while UpdateOnscreenKeyboard() == 0 do Wait(0) end
                            local input = GetOnscreenKeyboardResult()
                            local buildName = (input and input ~= "") and input or fallback
                            UpsertBuild(model, buildName, GetVehicleMods(veh))
                            Notify("~g~Build saved: ~w~" .. buildName)
                        else
                            Notify("~r~Not in a vehicle!")
                        end
                    end

                elseif inBuildsMenu then
                    local list = LoadBuilds()
                    if list[selectedBuild] then
                        local entry = list[selectedBuild]
                        SpawnVehicle(entry.model, entry.mods)
                        menuOpen, inBuildsMenu = false, false
                        NuiSetVisible(false)
                    end

                else
                    -- 1=Vehicles 2=Customization 3=Builds 4=Warp 5=Character
                    -- 6=Speedo   7=Passive       8=God    9=Delete
                    if selectedCategory == 1 then
                        inClassMenu = true; NuiSendMenu(1)
                    elseif selectedCategory == 2 then
                        inCustomMenu = true; NuiSendMenu(1)
                    elseif selectedCategory == 3 then
                        inBuildsMenu = true; selectedBuild = 1; NuiSendMenu(1)
                    elseif selectedCategory == 4 then
                        TeleportToWaypoint(); NuiSetVisible(false)
                    elseif selectedCategory == 5 then
                        menuOpen = false; NuiSetVisible(false)
                        Wait(150); TriggerEvent('cuk_character:openMenu')
                    elseif selectedCategory == 6 then
                        speedoEnabled = not speedoEnabled
                        SendNUIMessage({ type = "setSpeedoEnabled", enabled = speedoEnabled })
                        NuiSendMenu(selectedCategory)
                    elseif selectedCategory == 7 then
                        if LocalPlayer.state.trialActive then
                            Notify("~r~Passive disabled during trials!")
                        else
                            passiveModeEnabled = not passiveModeEnabled
                            Notify("Passive: " .. (passiveModeEnabled and "~g~ON" or "~r~OFF"))
                        end
                        NuiSendMenu(selectedCategory)
                    elseif selectedCategory == 8 then
                        if LocalPlayer.state.trialActive then
                            Notify("~r~God Mode disabled during trials!")
                        else
                            godModeEnabled = not godModeEnabled
                            Notify("God Mode: " .. (godModeEnabled and "~g~ON" or "~r~OFF"))
                        end
                        NuiSendMenu(selectedCategory)
                    elseif selectedCategory == 9 then
                        if DoesEntityExist(veh) then DeleteEntity(veh) end
                    end
                end

            -- ── BACK ──
            elseif IsControlJustPressed(0, 177) then
                if inBodyMenu or inStanceMenu or inNeonMenu then
                    inBodyMenu, inStanceMenu, inNeonMenu = false, false, false
                    NuiSendMenu(selectedCustom)
                elseif inSubMenu then
                    inSubMenu = false
                    ClearPreview()
                    NuiSendMenu(selectedClass)
                elseif inClassMenu then
                    inClassMenu = false; NuiSendMenu(selectedCategory)
                elseif inCustomMenu then
                    inCustomMenu = false; NuiSendMenu(selectedCategory)
                elseif inBuildsMenu then
                    inBuildsMenu = false; NuiSendMenu(selectedCategory)
                else
                    menuOpen = false; NuiSetVisible(false)
                end
            end

        end -- if menuOpen
    end
end)

-- ─── SPAWN ───────────────────────────────────────────────────────────────────
AddEventHandler('playerSpawned', function()
    Wait(5000)
    TriggerServerEvent('cuk_character:loadSkin')
    Notify("Press ~y~M~w~ for the Menu.")
end)

-- ─── TRIAL INTEGRATION ───────────────────────────────────────────────────────
-- Uses LocalPlayer.state so it works cross-resource with CUK-Trials

AddStateBagChangeHandler("trialActive", "player:" .. GetPlayerServerId(PlayerId()), function(bagName, key, value)
    if value == true then
        -- Force off god and passive
        if godModeEnabled then
            godModeEnabled = false
            SetPlayerInvincible(PlayerId(), false)
        end
        if passiveModeEnabled then
            passiveModeEnabled = false
            ResetEntityAlpha(PlayerPedId())
            SetEntityInvincible(PlayerPedId(), false)
            DisablePlayerFiring(PlayerId(), false)
        end
        -- Close menu if open
        if menuOpen then
            menuOpen = false
            NuiSetVisible(false)
            ClearPreview()
            inSubMenu, inClassMenu, inCustomMenu = false, false, false
            inBodyMenu, inNeonMenu, inStanceMenu = false, false, false
            inBuildsMenu = false
            selectedCategory = 1
        end
    end
end)

