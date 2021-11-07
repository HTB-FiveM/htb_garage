function RunStartupStuffQbCore(msg)

end

function GetAllPlayerNamesQbCore()
    local players = QBCore.Functions.GetQBPlayers();
    local playerNames = {}
    for _, playerIdStr in pairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if players[playerId] ~= nil then
            local charInfo = players[playerId].PlayerData.charinfo
            playerNames[playerId] = charInfo.firstname + ' ' + charInfo.lasstname
        end
    end

    return playerNames
end

function IdentifierFromServerIdQbCore(source)
    local player = QBCore.Functions.GetPlayer(source)
    return player.PlayerData.citizenid
end

function RegisterDatabaseQueriesQbCore()
    local db = {}
    db.SqlGetAllVehicles = -1
    db.SqlGetVehicle = -1
    db.SqlSetVehicleStored = -1
    db.SqlSaveAndStoreVehicle = -1
    db.SqlSetVehicleName = -1
    db.SqlTransferOwnership = -1
    db.SqlImpoundVehicle = -1
    
    ------------------------------
    MySQL.Async.store([[
SELECT 
    CAST(hash AS INTEGER) model, body, engine, fuel, state stored, 
    depotprice <> 0 pound,
    vehiclename, plate, drivingdistance
FROM player_vehicles
WHERE citizenid = @identifier AND type = @type
    ]], function(storeId)
        db.SqlGetAllVehicles = storeId
    end)
    db.GetAllVehicles = function(identifier, type)
        local results = MySQL.Sync.fetchAll(db.SqlGetAllVehicles, {
            ['@identifier'] = identifier,
            ['@type'] = type
        })

        return results
    end

    ------------------------------
    MySQL.Async.store([[
SELECT mods vehicle, state stored, depotprice <> 0 pound, vehiclename, plate, type
FROM player_vehicles
WHERE citizenid = @identifier AND plate = @plate
        ]], function(storeId)
            db.SqlGetVehicle = storeId
    end)
    db.GetVehicle = function(identifier, plate)
        local results = MySQL.Sync.fetchAll(db.SqlGetVehicle, {
            ['@identifier'] = identifier,
            ['@plate'] = plate
        })
        return results
    end

    
    ------------------------------
    MySQL.Async.store([[
UPDATE player_vehicles
SET state = @stored
WHERE citizenid = @identifier AND plate = @plate
        ]], function(storeId)
            db.SqlSetVehicleStored = storeId
    end)
    db.SetVehicleStored = function(stored, identifier, plate)
        MySQL.Sync.execute(db.SqlSetVehicleStored, {
            ['@stored'] = stored,
            ['@identifier'] = identifier,
            ['@plate'] = plate
        })
    end

    ------------------------------
    MySQL.Async.store([[
UPDATE player_vehicles
SET mods = @vehicle, state = @state, body = @body, engine = @engine, fuel = @fuel
WHERE plate = @plate
        ]], function(storeId)
            db.SqlSaveAndStoreVehicle = storeId
    end)
    db.SaveAndStoreVehicle = function(veh, state, plate)
        local vehprop = json.encode(veh)

        MySQL.Sync.execute(db.SqlSaveAndStoreVehicle, {
            ['@vehicle'] = vehprop,
            ['@state'] = state,
            ['@plate'] = plate,
            ['@body'] = veh.bodyHealth,
            ['@engine'] = veh.engineHealth,
            ['@fuel'] = veh.fuelLevel
        })
    end

    ------------------------------
    MySQL.Async.store([[
UPDATE player_vehicles
SET vehiclename = @newName
WHERE citizenid = @identifier AND plate = @plate
        ]], function(storeId)
            db.SqlSetVehicleName = storeId
    end)
    db.SetVehicleName = function(newName, identifier, plate)
        MySQL.Sync.execute(db.SqlSetVehicleName, {
            ['@newName'] = newName,
            ['@identifier'] = identifier,
            ['@plate'] = plate
        })
    end

    ------------------------------
    MySQL.Async.store([[
UPDATE player_vehicles
SET owner = @newOwner
WHERE owner = @currentOwner AND plate = @plate
        ]], function(storeId)
            db.SqlTransferOwnership = storeId
    end)
    db.TransferOwnership = function(newOwner, currentOwnerIdentifier, plate)
        local result = MySQL.Sync.execute(db.SqlTransferOwnership, {
            ['@newOwner'] = newOwner.identifier,
            ['@currentOwner'] = currentOwnerIdentifier,
            ['@plate'] = plate
        })
    end

    ------------------------------
--     MySQL.Async.store([[
-- UPDATE player_vehicles
-- SET pound = @pound
--         ]], function(storeId)
--             db.SqlImpoundVehicle = storeId
--     end)

    return db
end
