-- ===================================================================
-- SERVER SIDE LOGIC: Data Persistence and Synchronization
-- ===================================================================

-- Dictionary to store durability data for vehicles in the world
-- Key: Net ID of the vehicle
-- Value: Table containing { [wheelIndex] = durabilityValue }
local VehicleDurabilityData = {}

if Config.DEBUG_MODE then
    print("[TyreWear Server Debug] Server Configuration loaded. Debug Mode is active.")
    print("[TyreWear Server Debug] Config: " .. json.encode(Config))
end

-- ===================================================================
-- UTILITY: Get Vehicle Wheel Count
-- ===================================================================
local function GetVehicleWheelCount(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    local rawCount = GetVehicleNumberOfWheels(vehicle)
    if rawCount > 4 then rawCount = 4 end -- Cap at 4 for cars
    return rawCount
end

-- ===================================================================
-- EVENT HANDLERS
-- ===================================================================

-- Event triggered by client when entering a vehicle to get initial data
RegisterNetEvent('tyrewear:requestDurability')
AddEventHandler('tyrewear:requestDurability', function(netId)
    local source = source
    if not netId or netId == 0 then
        if Config.DEBUG_MODE then
            print(string.format("[TyreWear Server Debug] Player %d sent invalid netId: %s", source, tostring(netId)))
        end
        TriggerClientEvent('tyrewear:receiveDurability', source, netId, nil)
        return
    end

    local vehicle = NetToVeh(netId)
    local numWheels = vehicle and DoesEntityExist(vehicle) and GetVehicleWheelCount(vehicle) or 4
    local dataToSend = VehicleDurabilityData[netId]

    -- Initialize default durability if no data exists
    if not dataToSend then
        dataToSend = {}
        for i = 0, numWheels - 1 do
            dataToSend[i] = Config.MAX_TYRE_HEALTH
        end
        VehicleDurabilityData[netId] = dataToSend
        if Config.DEBUG_MODE then
            print(string.format("[TyreWear Server Debug] Initialized durability for Net ID %d: %s", netId, json.encode(dataToSend)))
        end
    end

    if Config.DEBUG_MODE then
        print(string.format("[TyreWear Server Debug] Player %d requested durability for Net ID %d: %s", source, netId, json.encode(dataToSend)))
    end

    -- Send the data back to the requesting client
    TriggerClientEvent('tyrewear:receiveDurability', source, netId, dataToSend)
end)

-- Event triggered by client when exiting a vehicle to save current data
RegisterNetEvent('tyrewear:saveDurability')
AddEventHandler('tyrewear:saveDurability', function(netId, durabilityTable)
    if not netId or not durabilityTable or next(durabilityTable) == nil then
        if Config.DEBUG_MODE then
            print("[TyreWear Server Debug] Invalid save data for Net ID " .. tostring(netId) .. ": " .. json.encode(durabilityTable))
        end
        return
    end

    -- Cap durabilityTable to 4 wheels to match client
    local numWheels = 4 -- Assume car unless vehicle exists
    local vehicle = NetToVeh(netId)
    if vehicle and DoesEntityExist(vehicle) then
        numWheels = GetVehicleWheelCount(vehicle)
    end
    local sanitizedTable = {}
    for i = 0, numWheels - 1 do
        sanitizedTable[i] = tonumber(durabilityTable[i]) or Config.MAX_TYRE_HEALTH
        sanitizedTable[i] = math.max(0, math.min(sanitizedTable[i], Config.MAX_TYRE_HEALTH))
    end

    VehicleDurabilityData[netId] = sanitizedTable
    if Config.DEBUG_MODE then
        print(string.format("[TyreWear Server Debug] Saved durability for Net ID %d: %s", netId, json.encode(sanitizedTable)))
    end
end)

-- Event triggered by client when the vehicle is repaired via command
RegisterNetEvent('tyrewear:forceRepair')
AddEventHandler('tyrewear:forceRepair', function(netId, maxHealth)
    if not netId or netId == 0 then
        if Config.DEBUG_MODE then
            print("[TyreWear Server Debug] Invalid netId for repair: " .. tostring(netId))
        end
        return
    end

    local source = source
    local vehicle = NetToVeh(netId)
    local numWheels = vehicle and DoesEntityExist(vehicle) and GetVehicleWheelCount(vehicle) or 4
    maxHealth = maxHealth or Config.MAX_TYRE_HEALTH

    -- Initialize repaired durability data
    local repairedData = {}
    for i = 0, numWheels - 1 do
        repairedData[i] = maxHealth
    end
    VehicleDurabilityData[netId] = repairedData

    if Config.DEBUG_MODE then
        print(string.format("[TyreWear Server Debug] Forced repair for Net ID %d: %s", netId, json.encode(repairedData)))
    end

    -- Sync repaired data to the client
    TriggerClientEvent('tyrewear:receiveDurability', source, netId, repairedData)
end)

-- ===================================================================
-- GARBAGE COLLECTION (Cleanup data when vehicle is deleted)
-- ===================================================================
AddEventHandler('entityRemoved', function(entity)
    if DoesEntityExist(entity) and IsEntityAVehicle(entity) then
        local netId = VehToNet(entity)
        if VehicleDurabilityData[netId] then
            VehicleDurabilityData[netId] = nil
            if Config.DEBUG_MODE then
                print(string.format("[TyreWear Server Debug] Cleaned up durability data for removed vehicle Net ID %d.", netId))
            end
        end
    end

end)
