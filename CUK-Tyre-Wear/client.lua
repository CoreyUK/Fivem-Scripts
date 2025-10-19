-- Tyre Wear Client: Simulates tire degradation and manages UI for a vehicle in FiveM

local currentVehicle = 0
local tyreDurability = {}
local burstState = {} -- Tracks burst tires to prevent redundant popping
local burstAttempts = {} -- Limits burst attempts for rear wheels
local tyreDisplayActive = false
local wheelNames = { "FL", "FR", "RL", "RR", "M1L", "M1R", "M2L", "M2R" }
local isRepairing = false -- Prevents degradation during repair
local MAX_BURST_ATTEMPTS = 3 -- Max burst attempts for rear wheels

-- Get number of vehicle wheels (capped at 4)
local function GetVehicleWheelCount(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    local rawCount = GetVehicleNumberOfWheels(vehicle)
    return rawCount > 4 and 4 or rawCount
end

-- Determine vehicle drivetrain type (FWD, RWD, AWD) based on fDriveBiasFront
local function GetDrivetrainType(vehicle)
    if not DoesEntityExist(vehicle) then return "AWD" end -- Fallback

    -- Attempt to get the drive bias value (0.0 to 1.0) using FiveM's handling native
    local driveBias = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront')

    if driveBias == nil or driveBias < 0.0 or driveBias > 1.0 then
        -- Fallback to the original logic if handling data is unavailable or invalid
        local drivetrainType = GetVehicleDriveTrainType and GetVehicleDriveTrainType(vehicle) or 1
        if drivetrainType == 1 then return "FWD"
        elseif drivetrainType == 0 then return "RWD"
        else return "AWD" end
    end

    -- Apply the custom bias logic:
    -- Bias: 0.0 is pure RWD, 1.0 is pure FWD.
    if driveBias < 0.5 then
        -- 0.0 to 0.499...: RWD (Bias favors the rear)
        return "RWD"
    elseif driveBias == 0.5 then
        -- Exactly 0.5: AWD (Perfect 50/50 split)
        return "AWD"
    else -- driveBias > 0.5
        -- 0.500...1 to 1.0: FWD (Bias favors the front)
        return "FWD"
    end
end

-- Calculate wear multiplier based on drivetrain
local function GetWheelWearMultiplier(vehicle, wheelIndex)
    if not TyreWearConfig.ENABLE_DIFFERENTIAL_WEAR then return 1.0 end
    local drivetrain = GetDrivetrainType(vehicle)
    local isFrontWheel = wheelIndex < 2 -- Wheels 0,1 are front; 2,3 are rear
    
    if drivetrain == "FWD" then
        return isFrontWheel and 1.5 or 1.0 -- Front wheels wear more
    elseif drivetrain == "RWD" then
        return isFrontWheel and 1.0 or 1.5 -- Rear wheels wear more
    else
        return 1.0 -- AWD: equal wear
    end
end

-- Check if vehicle is on off-road surface
local offroadSurfaceHashes = {
    [GetHashKey("dirt")] = true,
    [GetHashKey("mud")] = true,
    [GetHashKey("grass")] = true,
    [GetHashKey("sand")] = true,
    [GetHashKey("gravel")] = true,
}

local function IsVehicleOffRoad(vehicle)
    local x, y, z = table.unpack(GetEntityCoords(vehicle))
    local surfaceHash = GetVehicleWheelSurfaceMaterial(vehicle, 0)
    if offroadSurfaceHashes[surfaceHash] then
        return true
    end
    local materialId = GetZoneAtCoords(x, y, z)
    return materialId ~= GetHashKey("asphalt") and materialId ~= GetHashKey("road") and materialId ~= GetHashKey("concrete")
end

-- Send NUI message to update UI
local function SendNUIEventToUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- Update UI with tire durability
local function updateUI()
    if currentVehicle == 0 or not tyreDisplayActive then return end

    local numWheels = GetVehicleWheelCount(currentVehicle)
    local durabilityData = {}
    local maxHealth = TyreWearConfig.MAX_TYRE_HEALTH or 100.0

    for i = 0, numWheels - 1 do
        local health = tyreDurability[i] or maxHealth
        local scaledHealth = health <= 0 and 0 or math.round((health / maxHealth) * 100.0)
        durabilityData[i] = scaledHealth > 100 and 100 or scaledHealth
    end

    SendNUIEventToUI('updateTyres', {
        durability = durabilityData,
        wheelCount = numWheels,
        vehicleType = numWheels == 2 and "bike" or "car"
    })
end

-- Main simulation loop: Degrade tires and handle bursts
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if currentVehicle ~= 0 and not isRepairing then
            local playerPed = PlayerPedId()
            if GetPedInVehicleSeat(currentVehicle, -1) == playerPed and IsVehicleOnAllWheels(currentVehicle) then
                local numWheels = GetVehicleWheelCount(currentVehicle)
                local currentSpeed = GetEntitySpeed(currentVehicle) * 3.6
                
                -- UPDATED: Degradation rate for ~30 hours of driving at 100kph
                local degradationRate = TyreWearConfig.DEGRADATION_RATE or 0.000009
                
                local maxHealth = TyreWearConfig.MAX_TYRE_HEALTH or 100.0
                local offroadMultiplier = TyreWearConfig.ENABLE_OFFROAD_WEAR and IsVehicleOffRoad(currentVehicle) and (TyreWearConfig.OFFROAD_WEAR_MULTIPLIER or 2.5) or 1.0
                local baseDegradation = currentSpeed * degradationRate

                for i = 0, numWheels - 1 do
                    if tyreDurability[i] == nil then
                        tyreDurability[i] = maxHealth
                        burstState[i] = false
                        burstAttempts[i] = 0
                    end
                    local wearMultiplier = GetWheelWearMultiplier(currentVehicle, i)
                    local degradationAmount = baseDegradation * wearMultiplier * offroadMultiplier
                    tyreDurability[i] = math.max(0, tyreDurability[i] - degradationAmount)

                    if tyreDurability[i] <= 0 and not burstState[i] and (burstAttempts[i] or 0) < MAX_BURST_ATTEMPTS then
                        local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
                        if not isBurst then
                            SetVehicleTyreBurst(currentVehicle, i, true, 1000.0)
                            if i == 2 or i == 3 then
                                local altIndices = { i == 2 and 4 or 5, 45, 46, 47, 48 }
                                for _, altIndex in ipairs(altIndices) do
                                    SetVehicleTyreBurst(currentVehicle, altIndex, true, 1000.0)
                                    Citizen.Wait(50)
                                end
                            end
                            isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
                            burstAttempts[i] = (burstAttempts[i] or 0) + 1
                            if isBurst then
                                burstState[i] = true
                            end
                        else
                            burstState[i] = true
                        end
                    end
                end
                updateUI()
            end
        end
    end
end)

-- Detect vehicle enter/exit and sync durability
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 and vehicle ~= currentVehicle then
            if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                currentVehicle = vehicle
                tyreDisplayActive = true
                burstState = {}
                burstAttempts = {}

                local numWheels = GetVehicleWheelCount(currentVehicle)
                local maxHealth = TyreWearConfig.MAX_TYRE_HEALTH or 100.0
                for i = 0, numWheels - 1 do
                    local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
                    tyreDurability[i] = isBurst and 0 or maxHealth
                    burstState[i] = isBurst
                    burstAttempts[i] = isBurst and MAX_BURST_ATTEMPTS or 0
                end

                local netId = VehToNet(currentVehicle)
                if netId ~= 0 then
                    TriggerServerEvent('tyrewear:requestDurability', netId)
                end

                SendNUIEventToUI('setVisibility', true)
                updateUI()
            end
        elseif vehicle == 0 and currentVehicle ~= 0 then
            local netId = VehToNet(currentVehicle)
            if netId ~= 0 and next(tyreDurability) ~= nil then
                TriggerServerEvent('tyrewear:saveDurability', netId, tyreDurability)
            end
            currentVehicle = 0
            tyreDurability = {}
            burstState = {}
            burstAttempts = {}
            tyreDisplayActive = false
            SendNUIEventToUI('setVisibility', false)
        end
    end
end)

-- Handle server durability sync
RegisterNetEvent('tyrewear:receiveDurability')
AddEventHandler('tyrewear:receiveDurability', function(netId, durabilityTable)
    if netId == 0 or not durabilityTable then return end

    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) and vehicle == currentVehicle then
        local maxHealth = TyreWearConfig.MAX_TYRE_HEALTH or 100.0
        local numWheels = GetVehicleWheelCount(currentVehicle)

        for i = 0, numWheels - 1 do
            local savedHealth = durabilityTable[i]
            if savedHealth ~= nil then
                tyreDurability[i] = math.max(0, tonumber(savedHealth))
                local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
                if tyreDurability[i] <= 0 and not burstState[i] and (burstAttempts[i] or 0) < MAX_BURST_ATTEMPTS then
                    SetVehicleTyreBurst(currentVehicle, i, true, 1000.0)
                    if i == 2 or i == 3 then
                        local altIndices = { i == 2 and 4 or 5, 45, 46, 47, 48 }
                        for _, altIndex in ipairs(altIndices) do
                            SetVehicleTyreBurst(currentVehicle, altIndex, true, 1000.0)
                            Citizen.Wait(50)
                        end
                    end
                    isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
                    burstAttempts[i] = (burstAttempts[i] or 0) + 1
                    if isBurst then
                        burstState[i] = true
                    end
                else
                    burstState[i] = isBurst
                end
            else
                tyreDurability[i] = maxHealth
                burstState[i] = false
                burstAttempts[i] = 0
            end
        end
        updateUI()
    end
end)

-- Repair command: Restore all tires
RegisterCommand('fixmytyres', function()
    if not TyreWearConfig.ENABLE_TYRE_REPAIR then return end
    if currentVehicle ~= 0 then
        isRepairing = true
        local numWheels = GetVehicleWheelCount(currentVehicle)
        local maxHealth = TyreWearConfig.MAX_TYRE_HEALTH or 100.0
        for i = 0, numWheels - 1 do
            tyreDurability[i] = maxHealth
            burstState[i] = false
            burstAttempts[i] = 0
            if IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false) then
                SetVehicleTyreFixed(currentVehicle, i)
                if i == 2 or i == 3 then
                    local altIndices = { i == 2 and 4 or 5, 45, 46, 47, 48 }
                    for _, altIndex in ipairs(altIndices) do
                        SetVehicleTyreFixed(currentVehicle, altIndex)
                    end
                end
            end
        end
        local netId = VehToNet(currentVehicle)
        if netId ~= 0 then
            TriggerServerEvent('tyrewear:forceRepair', netId, maxHealth)
        end
        updateUI()
        TriggerEvent("chat:addMessage", {
            color = { 52, 211, 153 },
            args = {"Tyres Repaired!", "Your tires are now 100% durable."}
        })
        Citizen.Wait(1000)
        isRepairing = false
    end
end, false)

-- Command: Check tire configuration and status
RegisterCommand('checkdeg', function()
    if currentVehicle ~= 0 then
        local numWheels = GetVehicleWheelCount(currentVehicle)
        local drivetrain = GetDrivetrainType(currentVehicle)
        local message = {
            color = { 255, 255, 255 },
            args = {
                "Tyre Status",
                string.format("Drivetrain: %s\nDegradation Rate: %.7f\nMax Health: %.1f\nDifferential Wear: %s\nOffroad Wear: %s\nOffroad Multiplier: %.2f\nRepair: %s",
                    drivetrain,
                    TyreWearConfig.DEGRADATION_RATE or 0.000009,
                    TyreWearConfig.MAX_TYRE_HEALTH or 100.0,
                    TyreWearConfig.ENABLE_DIFFERENTIAL_WEAR and "Enabled" or "Disabled",
                    TyreWearConfig.ENABLE_OFFROAD_WEAR and "Enabled" or "Disabled",
                    TyreWearConfig.OFFROAD_WEAR_MULTIPLIER or 2.5,
                    TyreWearConfig.ENABLE_TYRE_REPAIR and "Enabled" or "Disabled")
            }
        }
        for i = 0, numWheels - 1 do
            local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
            local wearMult = GetWheelWearMultiplier(currentVehicle, i)
            message.args[#message.args + 1] = string.format("Wheel %s: %.2f%% (%.1fx wear), %s",
                wheelNames[i + 1], (tyreDurability[i] or 100.0) / (TyreWearConfig.MAX_TYRE_HEALTH or 100.0) * 100, wearMult, isBurst and "Popped" or "Intact")
        end
        TriggerEvent("chat:addMessage", message)
    end
end, false)

-- Command: Check wheel burst states
RegisterCommand('checkwheels', function()
    if currentVehicle ~= 0 then
        local numWheels = GetVehicleWheelCount(currentVehicle)
        local message = { color = { 255, 255, 255 }, args = {"Wheel States"} }
        for i = 0, numWheels - 1 do
            local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
            message.args[#message.args + 1] = string.format("Wheel %s: %s", wheelNames[i + 1], isBurst and "Popped" or "Intact")
        end
        for _, i in ipairs({4, 5, 45, 46, 47, 48}) do
            local isBurst = IsVehicleTyreBurst(currentVehicle, i, true) or IsVehicleTyreBurst(currentVehicle, i, false)
            message.args[#message.args + 1] = string.format("Alt Wheel %d: %s", i, isBurst and "Popped" or "Intact")
        end
        TriggerEvent("chat:addMessage", message)
    end
end, false)
