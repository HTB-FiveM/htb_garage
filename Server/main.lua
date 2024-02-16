local vehicleInstances = {}

local SqlGetAllVehicles = -1
local SqlGetVehicle = -1
local SqlSetVehicleStored = -1
local SqlSaveAndStoreVehicle = -1
local SqlSetVehicleName = -1
local SqlTransferOwnership = -1
local SqlImpoundVehicle = -1

local garageDebug = false

MySQL.ready(function()
	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlGetAllVehicles,
		function(storeId)
			SqlGetAllVehicles = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlGetVehicle,
		function(storeId)
			SqlGetVehicle = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlSetVehicleStored,
		function(storeId)
			SqlSetVehicleStored = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlSaveAndStoreVehicle,
		function(storeId)
			SqlSaveAndStoreVehicle = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlSetVehicleName,
		function(storeId)
			SqlSetVehicleName = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlTransferOwnership,
		function(storeId)
			SqlTransferOwnership = storeId
		end
	)

	MySQL.Async.store(
		SQL[Config.RolePlayFramework].SqlImpoundVehicle,
		function(storeId)
			SqlImpoundVehicle = storeId
		end
	)
end)

-------------------------------------------------------------------------------------------

FrameworkCtx:RunStartupStuff()

-------------------------------------------------------------------------------------------
RegisterNetEvent("htb_garage:SetVehicleName")
AddEventHandler("htb_garage:SetVehicleName", function(plate, newName)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	MySQL.Sync.execute(SqlSetVehicleName, {
		["@newName"] = newName,
		["@identifier"] = identifier,
		["@plate"] = plate,
	})
end)

RegisterNetEvent("htb_garage:GetPlayerVehicles")
AddEventHandler("htb_garage:GetPlayerVehicles", function(type, garageName)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	local results = MySQL.Sync.fetchAll(SqlGetAllVehicles, {
		["@identifier"] = identifier,
		["@type"] = type,
	}) 
	
	TriggerClientEvent("htb_garage:GetPlayerVehiclesResults", _source, results, garageName)
end)

RegisterNetEvent("htb_garage:GetVehicleForSpawn")
AddEventHandler("htb_garage:GetVehicleForSpawn", function(plate, garage)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	local results = MySQL.Sync.fetchAll(SqlGetVehicle, {
		["@identifier"] = identifier,
		["@plate"] = plate,
	})
	TriggerClientEvent("htb_garage:ResultsForVehicleSpawn", _source, results[1], garage)
end)

RegisterNetEvent("htb_garage:SetVehicleStored")
AddEventHandler("htb_garage:SetVehicleStored", function(plate, stored)
	local _source = source
	local identifier = FrameworkCtx:GetPlayerIdentifierFromId(_source)

	MySQL.Sync.execute(SqlSetVehicleStored, {
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

	MySQL.Sync.execute(SqlSaveAndStoreVehicle, {
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
			local player = GetPlayerPed(playerId)
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
			table.insert(players, currPlayer)
		end
	end

	TriggerClientEvent("htb_garage:nearbyPlayersList", _source, players)
end)

RegisterNetEvent("htb_garage:transferOwnership")
AddEventHandler("htb_garage:transferOwnership", function(plate, newOwner)
	local oldOwnerServerId = source
	local currentOwnerIdentifier = PlayerIdentifiers(oldOwnerServerId)

	local result = MySQL.Sync.execute(SqlTransferOwnership, {
		["@newOwner"] = newOwner.identifier,
		["@currentOwner"] = currentOwnerIdentifier,
		["@plate"] = plate,
	})
	--print('TransferOwnership Result: ' .. json.encode(result))

	if result then
		TriggerClientEvent("htb_garage:TransferOwnershipResult", oldOwnerServerId, "Sold vehicle " .. plate, true)
		TriggerClientEvent(
			"htb_garage:TransferOwnershipResult",
			newOwner.serverId,
			"Purchased vehicle " .. plate,
			false
		)
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

RegisterNetEvent("htb_garage:ImpoundVehicle")
AddEventHandler("htb_garage:ImpoundVehicle", function(plate, actionByJob)
	if Config.AllowedImpoundJobs[actionByJob] then
		MySQL.Sync.execute(SqlImpoundVehicle, {
			["@pound"] = 1,
		})
		TriggerClientEvent("htb_garage:Impounded", source, "Vehicle '" .. plate .. "' has been impounded")
	else
		TriggerClientEvent("htb_garage:Impounded", source, "You are not authorised to impound vehicles")
	end
end)

RegisterNetEvent("htb_garage:ReleaseVehicle")
AddEventHandler("htb_garage:ReleaseVehicle", function(plate)
	MySQL.Sync.execute(SqlImpoundVehicle, {
		["@pound"] = 0,
	})
	TriggerClientEvent("htb_garage:Released", source, "Vehicle '" .. plate .. "' has been released", plate)
end)

RegisterCommand("garageToggleDebug", function(source, args, raw)
	garageDebug = not garageDebug
end, false)

RegisterCommand("dumpVehicleInstances", function(source, args, raw)
	if garageDebug then
		Citizen.Trace(json.encode(vehicleInstances))
	end
end, false)
