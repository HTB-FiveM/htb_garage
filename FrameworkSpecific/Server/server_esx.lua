function RunStartupStuffEsx(msg)
    -- NOTE: If not using legacy then comment out the '@es_extended/imports.lua' line in fxmanifest.lua
    --       Legacy provides a definition for ESX object so this should overwrite the global, but
    --       better to not let it load if not required
    if Config.UsingEsxLegacy == false then
        ESX = nil 
    
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end

    RegisterDatabaseQueries()
end


function GetAllPlayerNamesEsx()
    -- If you don't have this function in your es_extended, add it. I won't accomodate for
    -- not having this as without it there's MAJOR potential for server killing. Find it in ESX Legacy
    local xPlayers = ESX.GetExtendedPlayers()
    local playerNames = {}
    for _, playerIdStr in pairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if xPlayers[playerId] ~= nil then
            playerNames[playerId] = xPlayers[playerId].name
        end
    end

    return playerNames
end

function IdentifierFromServerIdEsx(source)
    return PlayerIdentifiers(source)
end

function RegisterDatabaseQueries()
    MySQL.ready(function()
        MySQL.Async.store([[
    SELECT 
        CAST(json_value(vehicle, '$.model') AS INTEGER) model,
        CAST(json_value(vehicle, '$.bodyHealth') AS INTEGER) body,
        CAST(json_value(vehicle, '$.engineHealth') AS INTEGER) engine,
        CAST(json_value(vehicle, '$.fuelLevel') AS INTEGER) fuel
        , stored, pound, vehiclename, plate FROM owned_vehicles
    WHERE owner = @identifier AND type = @type AND job IS NULL
        ]], function(storeId)
                SqlGetAllVehicles = storeId
        end)

        MySQL.Async.store([[
    SELECT vehicle, stored, pound, vehiclename, plate, type
    FROM owned_vehicles
    WHERE owner = @identifier AND plate = @plate
            ]], function(storeId)
                SqlGetVehicle = storeId
        end)
        
        MySQL.Async.store([[
    UPDATE owned_vehicles
    SET stored = @stored
    WHERE owner = @identifier AND plate = @plate
            ]], function(storeId)
                SqlSetVehicleStored = storeId
        end)

        MySQL.Async.store([[
    UPDATE owned_vehicles
    SET vehicle = @vehicle, stored = @stored
    WHERE plate = @plate
            ]], function(storeId)
            SqlSaveAndStoreVehicle = storeId
        end)

        MySQL.Async.store([[
    UPDATE owned_vehicles
    SET vehiclename = @newName
    WHERE owner = @identifier AND plate = @plate
            ]], function(storeId)
                SqlSetVehicleName = storeId
        end)

        MySQL.Async.store([[
    UPDATE owned_vehicles
    SET owner = @newOwner
    WHERE owner = @currentOwner AND plate = @plate
            ]], function(storeId)
                SqlTransferOwnership = storeId
        end)
        
        MySQL.Async.store([[
    UPDATE owned_vehicles
    SET pound = @pound
            ]], function(storeId)
                SqlImpoundVehicle = storeId
        end)

    end)

end

