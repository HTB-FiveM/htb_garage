local vehicleInstances = {}

local garageDebug = false


-- Store all the SQL Queries
MySQL.ready(function()
	local cfg = SQL[Config.RolePlayFramework]
	for name, entry in pairs(cfg) do
		MySQL.Async.store(entry.query, function(id)
			entry.handle = id
		end)
	end
end)

-- Assign a shortcut to the SQL query list
local qu = SQL[Config.RolePlayFramework]
-------------------------------------------------------------------------------------------

FrameworkCtx:RunStartupStuff()

-------------------------------------------------------------------------------------------
RegisterNetEvent("htb_garage:SetVehicleName")
AddEventHandler("htb_garage:SetVehicleName", function(plate, newName)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	MySQL.Sync.execute(qu.SqlSetVehicleName.handle, {
		["@newName"] = newName,
		["@identifier"] = identifier,
		["@plate"] = plate,
	})
end)

RegisterNetEvent("htb_garage:GetPlayerVehicles")
AddEventHandler("htb_garage:GetPlayerVehicles", function(type, garageName)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	local results = MySQL.Sync.fetchAll(qu.SqlGetAllVehicles.handle, {
		["@identifier"] = identifier,
		["@type"] = type,
	}) 

	TriggerClientEvent("htb_garage:GetPlayerVehiclesResults", _source, results, garageName)
end)

RegisterNetEvent("htb_garage:GetVehicleForSpawn")
AddEventHandler("htb_garage:GetVehicleForSpawn", function(plate, garage)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	local results = MySQL.Sync.fetchAll(qu.SqlGetVehicle.handle, {
		["@identifier"] = identifier,
		["@plate"] = plate,
	})
	TriggerClientEvent("htb_garage:ResultsForVehicleSpawn", _source, results[1], garage)
end)

RegisterNetEvent("htb_garage:SetVehicleStored")
AddEventHandler("htb_garage:SetVehicleStored", function(plate, stored)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	MySQL.Sync.execute(qu.SqlSetVehicleStored.handle, {
		["@stored"] = stored,
		["@identifier"] = identifier,
		["@plate"] = plate,
	})
end)

-- When players login we need to send them a copy of the vehicleInstances
RegisterNetEvent("htb_garage:playerLoaded")
AddEventHandler("htb_garage:playerLoaded", function()
	TriggerClientEvent("htb_garage:UpdateLocalVehicleInstances", source, vehicleInstances)
end)

RegisterNetEvent("htb_garage:StartTrackingEntity")
AddEventHandler("htb_garage:StartTrackingEntity", function(plate, networkId)
	if networkId then
		vehicleInstances[trim(plate)] = {
			networkId = networkId,
		}
		TriggerClientEvent("htb_garage:UpdateLocalVehicleInstances", -1, vehicleInstances)

		if garageDebug then
			Citizen.Trace(json.encode(vehicleInstances))
		end
	else
		Citizen.Trace("No networkId provided for plate: " .. plate)
	end
end)

RegisterNetEvent("htb_garage:StopTrackingEntity")
AddEventHandler("htb_garage:StopTrackingEntity", function(plate)
	vehicleInstances[trim(plate)] = nil

	if garageDebug then
		Citizen.Trace(json.encode(vehicleInstances))
	end

	TriggerClientEvent("htb_garage:UpdateLocalVehicleInstances", -1, vehicleInstances)
end)

RegisterNetEvent("htb_garage:SaveAndStoreVehicle")
AddEventHandler("htb_garage:SaveAndStoreVehicle", function(vehicleProps, networkId, vehicleType, deleteZone)
	local _source = source

	-- No need to track the owner of the vehicle. This way anyone can return vehicles and
	-- prevent the owner from having to pay a retrieval fee
	local vehprop = json.encode(vehicleProps)

	MySQL.Sync.execute(qu.SqlSaveAndStoreVehicle.handle, {
		["@vehicle"] = vehprop,
		["@stored"] = 1,
		["@plate"] = vehicleProps.plate,
	})

	TriggerClientEvent(
		"htb_garage:VehicleSaveAndStored",
		_source,
		networkId,
		vehicleProps.plate,
		vehicleType,
		deleteZone
	)
end)

RegisterNetEvent("htb_garage:MakePayment")
AddEventHandler("htb_garage:MakePayment", function(account, amount)
	local _source = source
	FrameworkCtx:MakePayment(_source, account, amount)
	
end)

RegisterNetEvent("htb_garage:fetchNearbyPlayers")
AddEventHandler("htb_garage:fetchNearbyPlayers", function(maxPlayers)
	if maxPlayers == nil then
		maxPlayers = Config.MaxPlayersInTransferList
	end

	local _source = source
	local me = GetPlayerPed(_source)
	local myCoords = GetEntityCoords(me)

	local tree = nil
	local players = {}

	local allPlayerNames = FrameworkCtx:GetAllPlayerNames()

	for _, playerIdStr in pairs(GetPlayers()) do
		local playerId = tonumber(playerIdStr)
		if playerId ~= _source then -- Ignore the player selling the vehicle
			local player = GetPlayerPed(playerIdStr)
			local playerCoords = GetEntityCoords(player)
			local distance = #(playerCoords - myCoords)
			local name = allPlayerNames[playerId]
			local identifier = PlayerIdentifiers(playerId)

			-- Insert into sorted list / btree here with distance as sort key
			local playerNode = { name = name, serverId = playerId, identifier = identifier }
			if tree == nil then
				tree = NewBinaryTree({ key = distance, player = playerNode })
			else
				tree:insert({ key = distance, player = playerNode })
			end
		end
	end

	-- Retrieve btree items in order and build standard ordered lua table
	if tree ~= nil then
		for currPlayer in tree:values() do
			table.insert(players, currPlayer.player)
		end
	end

	TriggerClientEvent("htb_garage:nearbyPlayersList", _source, players)
end)

RegisterNetEvent("htb_garage:transferOwnership")
AddEventHandler("htb_garage:transferOwnership", function(plate, newOwner)
	local oldOwnerServerId = source
	local currentOwnerIdentifier = PlayerIdentifiers(oldOwnerServerId)

	local result = MySQL.Sync.execute(qu.SqlTransferOwnership.handle, {
		["@newOwner"] = newOwner.identifier,
		["@currentOwner"] = currentOwnerIdentifier,
		["@plate"] = plate,
	})
	--print('TransferOwnership Result: ' .. json.encode(result))

	if result then
		TriggerClientEvent("htb_garage:TransferOwnershipResult", oldOwnerServerId, "Sold vehicle " .. plate, true, plate)
		TriggerClientEvent(
			"htb_garage:TransferOwnershipResult",
			newOwner.serverId,
			"Purchased vehicle " .. plate,
			false
		)

		-- if the vehicle is out then give the keys to the buyer
			local theVeh = vehicleInstances[trim(plate)]
			if theVeh then
				TriggerClientEvent('qb-vehiclekeys:client:AddKeys', newOwner.serverId, plate)
			end
	else
		TriggerClientEvent(
			"htb_garage:TransferOwnershipResult",
			oldOwnerServerId,
			"Failed to sell vehicle " .. plate,
			true
		)
		TriggerClientEvent(
			"htb_garage:TransferOwnershipResult",
			newOwner.serverId,
			"Failed to purchase vehicle " .. plate,
			false
		)
	end
end)

RegisterNetEvent("htb_garage:TeleportAllInVehicleToDock")
AddEventHandler("htb_garage:TeleportAllInVehicleToDock", function(serverIds, pos)
	for _, serverId in pairs(serverIds) do
		TriggerClientEvent("htb_garage:HandleWarpToDock", serverId, pos)
	end
end)


RegisterNetEvent("htb_garage:SetupForImpoundVehicle")
AddEventHandler("htb_garage:SetupForImpoundVehicle", function(plate)
	local _source = source

	local playerJob = FrameworkCtx:GetPlayerJob(_source)
print('PlayJob: ' .. json.encode(playerJob.jobName))
	if Config.AllowedImpoundJobs[playerJob.jobName] then
		local isCitizen = MySQL.scalar.await(qu.SqlIsCitizenVehicle.handle, {
			["@plate"] = plate
		})
		if not isCitizen then
			TriggerClientEvent("htb_garage:ShowClientNotification", _source, _U("citizen_vehicle_only_impound"))
			return
		end
		
		local results = MySQL.Sync.fetchAll(qu.SqlGetImpoundList.handle, {})

		local ret = {
			impounds = results,
			data = plate
		}

		TriggerClientEvent("htb_garage:SetupForImpoundVehicleResults", _source, ret)
	
	else
		TriggerClientEvent("htb_garage:ShowClientNotification", _source, "You are not authorised to impound vehicles")
	end
end)

RegisterNetEvent("htb_garage:ImpoundVehicle")
AddEventHandler("htb_garage:ImpoundVehicle", function(impoundData)
	local _source = source

	local playerLicense = PlayerIdentifiers(_source)
	local playerJob = FrameworkCtx:GetPlayerJob(_source)

	if Config.AllowedImpoundJobs[playerJob.jobName] then
		local isCitizen = MySQL.Sync.fetchScalar(qu.SqlIsCitizenVehicle.handle, {
			["@plate"] = impoundData.vehiclePlate
		})

		if not isCitizen then
			TriggerClientEvent("htb_garage:ShowClientNotification", _source, _U("citizen_vehicle_only_impound"))
			return
		end

		local id = MySQL.Sync.insert(qu.SqlAddImpoundEntry.handle, {		
			["@vehiclePlate"] = impoundData.vehiclePlate,
			["@id"] = impoundData.impoundId,
			["@reasonForImpound"] = impoundData.reasonForImpound,
			["@releaseDateTime"] = impoundData.releaseDateTime,
			["@allowPersonalUnimpound"] = impoundData.allowPersonalUnimpound,
			["@impoundedByUser"] = playerLicense
		})
		local updated = MySQL.Sync.execute(qu.SqlImpoundVehicle.handle, {
			["@pound"] = 1,
			["@plate"] = impoundData.vehiclePlate
		})

		local data = {
			message = "Vehicle '" .. impoundData.vehiclePlate .. "' has been impounded",
			plate = impoundData.vehiclePlate
		}

		TriggerClientEvent("htb_garage:ImpoundResult", _source, data)
	else
		TriggerClientEvent("htb_garage:ShowClientNotification", _source, "You are not authorised to impound vehicles")
	end

end)


RegisterNetEvent("htb_garage:ReleaseVehicle")
AddEventHandler("htb_garage:ReleaseVehicle", function(plate)
	MySQL.Sync.execute(qu.SqlImpoundVehicle.handle, {
		["@pound"] = 0,
		["@plate"] = plate
	})
	TriggerClientEvent("htb_garage:Released", source, "Vehicle '" .. plate .. "' has been released", plate)
end)



/*
{
  type: string;
  plate: string;
  displayName: string;
  modelName: string;
  spawnName: string;
  import: boolean;
  price: number;
  timeLeft: number;
}
*/



RegisterNetEvent("htb_garage:server:ImpoundRetrieveVehicle")
AddEventHandler("htb_garage:server:ImpoundRetrieveVehicle", function(vehicle)
	local _source = source

	MySQL.Sync.execute(qu.SqlImpoundVehicle.handle, {
		["@pound"] = 0,
		["@plate"] = vehicle.plate

	})

	

	TriggerClientEvent("htb_garage:client:VehicleImpoundRetrieved", _source,
	{
		plate = vehicle.plate,
		spawnLocation = vector3()
	})
end)

RegisterNetEvent("htb_garage:server:ReturnVehicleToOwner")
AddEventHandler("htb_garage:server:ReturnVehicleToOwner", function(vehicle)
	local _source = source

	MySQL.Sync.execute(qu.SqlImpoundVehicle.handle, {
		["@pound"] = 0,
		["@plate"] = vehicle.plate

	})
	local message = ("Vehicle %s has been returned to the owner"):format(vehicle.plate)
	TriggerClientEvent("htb_garage:client:VehicleReturnedToOwner", _source, message)
end)









RegisterCommand("garageToggleDebug", function(source, args, raw)
	garageDebug = not garageDebug
end, false)

RegisterCommand("dumpVehicleInstances", function(source, args, raw)
	if garageDebug then
		Citizen.Trace(json.encode(vehicleInstances))
	end
end, false)

-- Lifetime is either 'temporary' for a one off key or 'permanent'
RegisterNetEvent('htb_garage:giveKeys', function(playerServerId, carplate, lifetime)
	FrameworkCtx:GiveVehicleKeys({ playerServerId = playerServerId, carplate = carplate, lifetime = lifetime})
end)

