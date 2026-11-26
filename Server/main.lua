local vehicleInstances = {}
local spawnTickets = {} -- [normalised plate] = { playerId, identifier, plate, model, expires }
local pendingImpounds = {} -- [playerId] = { plate, networkId, expires }

local garageDebug = false

-- The framework's queries (Bridge/queries), registered with the database once it's ready
local qu = Queries
MySQL.ready(function()
	for _, entry in pairs(qu) do
		MySQL.Async.store(entry.query, function(id)
			entry.handle = id
		end)
	end
end)

local sec = Config.Security

-------------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------------

-- Mapping from vehicle type to the associated garage config key
local GarageTypeMapping = {
	car = "Garages",
	boat = "Docks",
	plane = "Hangars",
}

local function getGarage(vehicleType, garageName)
	local key = GarageTypeMapping[vehicleType]
	local garages = key and Config[key]
	return garages and garages[garageName] or nil
end

-- oxmysql may return TINYINT(1) columns as booleans, so accept either form
local function isSet(value)
	return value == true or value == 1
end

local function notify(playerId, message)
	TriggerClientEvent("htb_garage:ShowClientNotification", playerId, message)
end

local function decodeProps(json_text)
	if type(json_text) ~= "string" then
		return nil
	end
	local ok, props = pcall(json.decode, json_text)
	return ok and type(props) == "table" and props or nil
end

local function modelHash(model)
	if type(model) == "string" and tonumber(model) == nil then
		model = GetHashKey(model)
	end
	return Security.NormaliseHash(model)
end

local function getPlayerJobName(playerId)
	local job = Framework.getJob(playerId)
	return job and job.name or nil
end

-- Charge a player from cash first, then bank, unless a specific account is given.
-- Returns false, and charges nothing, if no single account can cover the amount.
local function chargePlayer(playerId, amount, account)
	if amount <= 0 then
		return false
	end
	for _, acc in ipairs(account and { account } or { "cash", "bank" }) do
		if (Framework.getBalance(playerId, acc) or 0) >= amount then
			return Framework.removeMoney(playerId, acc, amount)
		end
	end
	return false
end

local function isImpoundStaff(playerId)
	local jobName = getPlayerJobName(playerId)
	return jobName ~= nil and Config.AllowedImpoundJobs[jobName] == true
end

-- Jobs that may release held vehicles with /ImpoundRelease
local function isImpoundReleaseStaff(playerId)
	local jobName = getPlayerJobName(playerId)
	return jobName ~= nil and (Config.AllowedImpoundReleaseJobs or {})[jobName] == true
end

-- "char2:abc", "license:abc" and "abc" all come down to "abc": the person, not the character
local function personId(identifier)
	if type(identifier) ~= "string" then
		return nil
	end
	local id = identifier:gsub("^char%d+:", ""):gsub("^%w+:", "")
	return id ~= "" and id:lower() or nil
end

-- Corruption prevention: is the vehicle owned by this player, on any of their characters?
-- ESX multicharacter stores "char1:<license>", "char2:<license>" ... so compare the person
-- behind the identifier, and also against every identifier the connection has.
local function ownsOnAnyCharacter(playerId, ownerIdentifier)
	local owner = personId(ownerIdentifier)
	if not owner then
		return false
	end
	if personId(Framework.getIdentifier(playerId)) == owner then
		return true
	end
	for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
		if personId(identifier) == owner then
			return true
		end
	end
	return false
end


-------------------------------------------------------------------------------------------
-- Vehicle tracking (which owned vehicles are currently out in the world)
-------------------------------------------------------------------------------------------
local function broadcastInstances()
	TriggerClientEvent("htb_garage:UpdateLocalVehicleInstances", -1, vehicleInstances)
	if garageDebug then
		Citizen.Trace(json.encode(vehicleInstances) .. "\n")
	end
end

local function setTracked(plate, networkId)
	vehicleInstances[trim(plate)] = { networkId = networkId }
	broadcastInstances()
end

local function clearTracked(plate)
	local key = trim(plate)
	if vehicleInstances[key] then
		vehicleInstances[key] = nil
		broadcastInstances()
	end
end

-------------------------------------------------------------------------------------------
-- Spawn tickets: the server hands one out when it allows a vehicle to be spawned. The
-- client must present it to have the vehicle tracked. If the vehicle never appears the
-- ticket expires and the vehicle is put back in the garage, so nothing is lost.
-------------------------------------------------------------------------------------------
local function issueSpawnTicket(playerId, identifier, plate, vehicleJson)
	local props = decodeProps(vehicleJson)
	spawnTickets[Security.NormalisePlate(plate)] = {
		playerId = playerId,
		identifier = identifier,
		plate = plate,
		model = props and modelHash(props.model) or nil,
		expires = os.time() + (sec.SpawnTicketSeconds or 60),
	}
end

-- Put a vehicle back in the garage if it never made it into the world.
--
-- Runs under the vehicle's lock so it can't land in the middle of a take-out, paid
-- retrieve or store (a paid retrieve deletes the old copy before the new one appears, so
-- for a moment the vehicle really isn't in the world). It only acts while `ticket` is
-- still the current ticket for the plate: if a newer spawn has been handed out, or the
-- ticket was claimed, there's nothing to undo. The ticket is only removed here, so when
-- the vehicle is busy (lock held) the ticket stays and the expiry check tries again.
local function restoreIfNotSpawned(ticket)
	local key = Security.NormalisePlate(ticket.plate)

	Security.WithLock("vehicle:" .. key, function()
		if spawnTickets[key] ~= ticket then
			return
		end
		spawnTickets[key] = nil

		local tracked = vehicleInstances[trim(ticket.plate)]
		if tracked and Security.GetVehicleFromNetId(tracked.networkId) then
			return
		end
		if Security.FindVehicleByPlate(ticket.plate) then
			return
		end

		MySQL.update.await(qu.SqlSetVehicleStored.handle, {
			["@stored"] = 1,
			["@identifier"] = ticket.identifier,
			["@plate"] = ticket.plate,
		})
		if garageDebug then
			print(("[htb_garage] Spawn of %s never appeared; returned it to the garage"):format(ticket.plate))
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(30000)
		local now = os.time()

		-- Collect first: restoring removes tickets from the table
		local expired = {}
		for _, ticket in pairs(spawnTickets) do
			if ticket.expires < now then
				expired[#expired + 1] = ticket
			end
		end
		for _, ticket in ipairs(expired) do
			restoreIfNotSpawned(ticket)
		end

		for playerId, pending in pairs(pendingImpounds) do
			if pending.expires < now then
				pendingImpounds[playerId] = nil
			end
		end
	end
end)

AddEventHandler("playerDropped", function()
	local playerId = tonumber(source)
	pendingImpounds[playerId] = nil
	for _, ticket in pairs(spawnTickets) do
		if ticket.playerId == playerId then
			Citizen.CreateThread(function()
				restoreIfNotSpawned(ticket)
			end)
		end
	end
end)

-------------------------------------------------------------------------------------------
-- Garage events
-------------------------------------------------------------------------------------------

-- When players login we need to send them a copy of the vehicleInstances
Security.RegisterNetEvent("htb_garage:playerLoaded", { cooldownMs = 5000 }, function(playerId)
	TriggerClientEvent("htb_garage:UpdateLocalVehicleInstances", playerId, vehicleInstances)
end)

Security.RegisterNetEvent(
	"htb_garage:SetVehicleName",
	{ args = { "string", "string?" }, cooldownMs = 1000 },
	function(playerId, plate, newName)
		newName = Security.CleanString(newName, sec.MaxVehicleNameLength)

		-- The query only updates vehicles owned by this player
		MySQL.update.await(qu.SqlSetVehicleName.handle, {
			["@newName"] = newName,
			["@identifier"] = Framework.getIdentifier(playerId),
			["@plate"] = plate,
		})
	end
)

-- Whether the caller owns the vehicle with this plate, so the client only shows store
-- points for the player's own vehicles. Answers only for the caller's own identifier and
-- reveals nothing about other owners.
Security.RegisterNetEvent(
	"htb_garage:CheckVehicleOwnership",
	{ args = { "string" }, cooldownMs = 500 },
	function(playerId, plate)
		local clean = Security.CleanString(plate, 16)
		if not clean or clean == "" then
			return
		end

		local record = MySQL.single.await(qu.SqlGetVehicleByPlate.handle, { ["@plate"] = clean })
		local identifier = Framework.getIdentifier(playerId)
		local owned = record ~= nil and identifier ~= nil and record.owner == identifier

		TriggerClientEvent("htb_garage:VehicleOwnershipResult", playerId, plate, owned, owned and record.type or nil)
	end
)

Security.RegisterNetEvent(
	"htb_garage:GetPlayerVehicles",
	{ args = { "string", "string" }, cooldownMs = 1000 },
	function(playerId, vehicleType, garageName)
		local garage = getGarage(vehicleType, garageName)
		if not garage or not garage.GarageMenuLocation then
			Security.Flag(playerId, "htb_garage:GetPlayerVehicles", "unknown garage " .. garageName)
			return
		end
		if not Security.IsPlayerNear(playerId, garage.GarageMenuLocation.Pos, sec.InteractionDistance) then
			Security.Flag(playerId, "htb_garage:GetPlayerVehicles", "opened garage " .. garageName .. " from a distance")
			return
		end

		local results = MySQL.query.await(qu.SqlGetAllVehicles.handle, {
			["@identifier"] = Framework.getIdentifier(playerId),
			["@type"] = vehicleType,
		})

		TriggerClientEvent("htb_garage:GetPlayerVehiclesResults", playerId, results or {}, garageName)
	end
)

Security.RegisterNetEvent(
	"htb_garage:GetVehicleForSpawn",
	{ args = { "string", "string", "boolean?" }, cooldownMs = 1000 },
	function(playerId, plate, garageName, payForRetrieve)
		local eventName = "htb_garage:GetVehicleForSpawn"
		local identifier = Framework.getIdentifier(playerId)

		local vehicle = MySQL.single.await(qu.SqlGetVehicle.handle, {
			["@identifier"] = identifier,
			["@plate"] = plate,
		})
		if not vehicle then
			return -- not this player's vehicle (or it was just sold while the menu was open)
		end

		local garage = getGarage(vehicle.type, garageName)
		if not garage or not garage.GarageMenuLocation then
			Security.Flag(playerId, eventName, "unknown garage " .. garageName)
			return
		end
		if not Security.IsPlayerNear(playerId, garage.GarageMenuLocation.Pos, sec.InteractionDistance) then
			Security.Flag(playerId, eventName, "took a vehicle out away from garage " .. garageName)
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(vehicle.plate), function()
			if isSet(vehicle.pound) then
				notify(playerId, _U("vehicle_in_pound"))
				return
			end

			-- A spawn already handed out for this vehicle hasn't appeared yet. Refuse, or
			-- repeated (paid) requests could produce several copies before the first appears.
			-- An expired, unclaimed ticket is simply replaced by the one issued below; because
			-- this runs under the vehicle's lock, the expiry check can't restore it mid-way.
			local ticket = spawnTickets[Security.NormalisePlate(vehicle.plate)]
			if ticket and ticket.expires >= os.time() then
				notify(playerId, _U("cannot_take_out"))
				return
			end

			-- Duplicate protection: check the real world, not what the client says
			local existing = Security.FindVehicleByPlate(vehicle.plate)
			local needsRetrieve = existing ~= nil or not isSet(vehicle.stored)

			if needsRetrieve then
				if not payForRetrieve then
					notify(playerId, existing and _U("cannot_take_out") or _U("vehicle_already_out"))
					return
				end

				if not chargePlayer(playerId, Config.RetrieveVehiclePrice) then
					notify(playerId, _U("retrieve_not_enough"))
					return
				end
				notify(playerId, _U("retrieval_fee_paid"))

				if existing then
					DeleteEntity(existing)
				end
				clearTracked(vehicle.plate)
			end

			MySQL.update.await(qu.SqlSetVehicleStored.handle, {
				["@stored"] = 0,
				["@identifier"] = identifier,
				["@plate"] = vehicle.plate,
			})
			issueSpawnTicket(playerId, identifier, vehicle.plate, vehicle.vehicle)

			TriggerClientEvent("htb_garage:ResultsForVehicleSpawn", playerId, vehicle, garageName)
		end)
	end
)

-- The client couldn't find a free spot to spawn the vehicle it was given
Security.RegisterNetEvent("htb_garage:SpawnCancelled", { args = { "string" } }, function(playerId, plate)
	local key = Security.NormalisePlate(plate)
	local ticket = spawnTickets[key]
	if ticket and ticket.playerId == playerId then
		restoreIfNotSpawned(ticket)
	end
end)

Security.RegisterNetEvent(
	"htb_garage:StartTrackingEntity",
	{ args = { "string", "number" } },
	function(playerId, plate, networkId)
		local key = Security.NormalisePlate(plate)
		local ticket = spawnTickets[key]

		-- Only vehicles the server just handed to this player can be registered from a
		-- client. Other resources should use the StartTrackingVehicle export instead.
		if not ticket or ticket.playerId ~= playerId then
			if garageDebug then
				print(("[htb_garage] StartTrackingEntity for %s from player %d ignored: no spawn ticket"):format(plate, playerId))
			end
			return
		end

		-- The client sends this as soon as it has spawned the vehicle; give the server time
		-- to learn about the new network entity
		local entity = Security.GetVehicleFromNetId(networkId, 10000)
		if not entity then
			-- The ticket stays, so the expiry check puts the vehicle back if it's really missing
			print(
				("^3[htb_garage] Couldn't confirm the spawn of %s for player %d (network id %s not found)^0"):format(
					plate,
					playerId,
					tostring(networkId)
				)
			)
			return
		end

		-- The ticket may have been replaced or restored while we waited
		if spawnTickets[key] ~= ticket then
			return
		end

		if ticket.model and Security.NormaliseHash(GetEntityModel(entity)) ~= ticket.model then
			Security.Flag(playerId, "htb_garage:StartTrackingEntity", "spawned a different model for plate " .. plate)
			DeleteEntity(entity)
			restoreIfNotSpawned(ticket)
			return
		end

		spawnTickets[key] = nil
		setTracked(ticket.plate, networkId)

		-- The spawn is confirmed, so the player who took the vehicle out gets its keys
		Keys.give(playerId, plate, "permanent")
	end
)

Security.RegisterNetEvent("htb_garage:StopTrackingEntity", { args = { "string" } }, function(playerId, plate)
	local tracked = vehicleInstances[trim(plate)]
	if not tracked then
		return
	end

	-- Only forget a vehicle that really is gone
	if Security.GetVehicleFromNetId(tracked.networkId) then
		return
	end

	clearTracked(plate)
end)

Security.RegisterNetEvent(
	"htb_garage:SaveAndStoreVehicle",
	{ args = { "table", "number", "string", "string" }, cooldownMs = 2000 },
	function(playerId, vehicleProps, networkId, vehicleType, garageName)
		local eventName = "htb_garage:SaveAndStoreVehicle"

		local garage = getGarage(vehicleType, garageName)
		if not garage or not garage.DeletePoint then
			Security.Flag(playerId, eventName, "unknown garage " .. garageName)
			return
		end
		if not Security.IsPlayerNear(playerId, garage.DeletePoint.Pos, sec.InteractionDistance) then
			Security.Flag(playerId, eventName, "stored a vehicle away from garage " .. garageName)
			return
		end

		local entity = Security.GetVehicleFromNetId(networkId)
		if not entity then
			notify(playerId, _U("vehicle_error"))
			return
		end

		if GetPedInVehicleSeat(entity, -1) ~= GetPlayerPed(playerId) then
			Security.Flag(playerId, eventName, "stored a vehicle they aren't driving")
			return
		end

		local plate = vehicleProps.plate
		if
			type(plate) ~= "string"
			or Security.NormalisePlate(plate) ~= Security.NormalisePlate(GetVehicleNumberPlateText(entity))
		then
			Security.Flag(playerId, eventName, "vehicle properties don't match the vehicle's plate")
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(plate), function()
			-- Anyone may return an owned vehicle (saves the owner a retrieval fee), but it must
			-- be a real owned vehicle and must still be the same model that was saved
			local record = MySQL.single.await(qu.SqlGetVehicleByPlate.handle, { ["@plate"] = plate })
			if not record then
				notify(playerId, _U("cannot_store_vehicle"))
				return
			end
			if isSet(record.pound) or record.type ~= vehicleType then
				notify(playerId, _U("cannot_store_vehicle"))
				return
			end

			local entityModel = Security.NormaliseHash(GetEntityModel(entity))
			local savedProps = decodeProps(record.vehicle)
			local savedModel = savedProps and modelHash(savedProps.model)

			if (savedModel and savedModel ~= entityModel) or modelHash(vehicleProps.model) ~= entityModel then
				Security.Flag(playerId, eventName, "model of vehicle " .. plate .. " doesn't match the saved vehicle")
				return
			end

			-- Keep the identity of the vehicle from the database, never from the client
			vehicleProps.plate = record.plate
			vehicleProps.model = savedProps and savedProps.model or vehicleProps.model

			local encoded = json.encode(vehicleProps)
			if #encoded > (sec.MaxVehiclePropsBytes or 65536) then
				Security.Flag(playerId, eventName, ("vehicle properties too large (%d bytes)"):format(#encoded))
				return
			end

			MySQL.update.await(qu.SqlSaveAndStoreVehicle.handle, {
				["@vehicle"] = encoded,
				["@stored"] = 1,
				["@plate"] = record.plate,
			})

			TriggerClientEvent("htb_garage:VehicleSaveAndStored", playerId, networkId, vehicleType)

			-- The server removes the vehicle itself, after giving the driver time to climb out
			Citizen.CreateThread(function()
				if vehicleType ~= "boat" and Config.AnimateExitOnStore then
					local waited = 0
					while
						DoesEntityExist(entity)
						and GetPedInVehicleSeat(entity, -1) ~= 0
						and waited < 5000
					do
						Citizen.Wait(100)
						waited = waited + 100
					end
					Citizen.Wait(1000)
				end

				-- Boats: put everyone aboard on dry land rather than dropping them in the water
				local dryPoint = garage.DeletePoint.DryPoint
				if vehicleType == "boat" and dryPoint and DoesEntityExist(entity) then
					for _, occupantId in ipairs(Security.GetPlayersInVehicle(entity)) do
						TriggerClientEvent("htb_garage:HandleWarpToDock", occupantId, dryPoint)
					end
					Citizen.Wait(500)
				end

				if DoesEntityExist(entity) then
					DeleteEntity(entity)
				end
				clearTracked(record.plate)
			end)
		end)
	end
)

Security.RegisterNetEvent("htb_garage:fetchNearbyPlayers", { cooldownMs = 1000 }, function(playerId)
	local myCoords = GetEntityCoords(GetPlayerPed(playerId))
	local radius = sec.NearbyPlayersRadius or 15.0
	local maxPlayers = Config.MaxPlayersInTransferList

	local tree = nil
	local players = {}
	local allPlayerNames = Framework.getPlayerNames()

	for _, playerIdStr in pairs(GetPlayers()) do
		local otherId = tonumber(playerIdStr)
		if otherId ~= playerId then -- Ignore the player selling the vehicle
			local distance = #(GetEntityCoords(GetPlayerPed(otherId)) - myCoords)
			if distance <= radius then
				-- Only the name and server id go to the client, never identifiers
				local playerNode = { name = allPlayerNames[otherId], serverId = otherId }
				if tree == nil then
					tree = NewBinaryTree({ key = distance, player = playerNode })
				else
					tree:insert({ key = distance, player = playerNode })
				end
			end
		end
	end

	-- Retrieve btree items in order (closest first) and build standard ordered lua table
	if tree ~= nil then
		for currPlayer in tree:values() do
			if #players >= maxPlayers then
				break
			end
			table.insert(players, currPlayer.player)
		end
	end

	TriggerClientEvent("htb_garage:nearbyPlayersList", playerId, players)
end)

Security.RegisterNetEvent(
	"htb_garage:transferOwnership",
	{ args = { "string", "table" }, cooldownMs = 2000 },
	function(playerId, plate, newOwner)
		local buyerId = tonumber(newOwner.serverId)
		if not buyerId or buyerId == playerId or not Security.IsValidPlayer(buyerId) then
			Security.Flag(playerId, "htb_garage:transferOwnership", "invalid buyer " .. tostring(newOwner.serverId))
			return
		end

		local buyerCoords = GetEntityCoords(GetPlayerPed(buyerId))
		if not Security.IsPlayerNear(playerId, buyerCoords, sec.TransferDistance) then
			notify(playerId, _U("transfer_too_far"))
			return
		end

		-- Both identifiers come from the server, never from the client
		local affected = MySQL.update.await(qu.SqlTransferOwnership.handle, {
			["@newOwner"] = Framework.getIdentifier(buyerId),
			["@currentOwner"] = Framework.getIdentifier(playerId),
			["@plate"] = plate,
		})

		if affected and affected > 0 then
			TriggerClientEvent("htb_garage:TransferOwnershipResult", playerId, "Sold vehicle " .. plate, true, plate)
			TriggerClientEvent("htb_garage:TransferOwnershipResult", buyerId, "Purchased vehicle " .. plate, false)

			-- The keys go with the vehicle: the seller loses theirs, and if the vehicle is
			-- out the buyer gets a set
			Keys.remove(playerId, plate)
			if vehicleInstances[trim(plate)] then
				Keys.give(buyerId, plate, "permanent")
			end
		else
			TriggerClientEvent(
				"htb_garage:TransferOwnershipResult",
				playerId,
				"Failed to sell vehicle " .. plate,
				true
			)
		end
	end
)

-------------------------------------------------------------------------------------------
-- Impound events
-------------------------------------------------------------------------------------------

Security.RegisterNetEvent(
	"htb_garage:server:SetupForImpoundVehicle",
	{ args = { "number" }, cooldownMs = 1000 },
	function(playerId, networkId)
		if not isImpoundStaff(playerId) then
			notify(playerId, _U("impound_not_auth"))
			return
		end

		local entity = Security.GetVehicleFromNetId(networkId)
		if not entity or not Security.IsPlayerNear(playerId, GetEntityCoords(entity), sec.VehicleDistance) then
			notify(playerId, _U("no_vehicles_nearby"))
			return
		end
		if #Security.GetPlayersInVehicle(entity) > 0 then
			notify(playerId, _U("impound_vehicle_occupied"))
			return
		end

		-- Read the plate from the real vehicle rather than trusting the client
		local record = MySQL.single.await(qu.SqlGetVehicleByPlate.handle, {
			["@plate"] = trim(GetVehicleNumberPlateText(entity)),
		})
		if not record then
			notify(playerId, _U("citizen_vehicle_only_impound"))
			return
		end
		if isSet(record.pound) then
			notify(playerId, _U("already_impounded"))
			return
		end

		pendingImpounds[playerId] = {
			plate = record.plate,
			networkId = networkId,
			expires = os.time() + 300,
		}

		local impounds = {}
		for impoundKey, v in pairs(Config.Impounds) do
			table.insert(impounds, {
				impoundId = impoundKey,
				displayName = v.RetrievePoint.Name,
			})
		end
		-- Config.Impounds has no order of its own, so list them by name
		table.sort(impounds, function(a, b)
			return tostring(a.displayName):lower() < tostring(b.displayName):lower()
		end)

		TriggerClientEvent("htb_garage:client:SetupForImpoundVehicleResults", playerId, {
			impounds = impounds,
			data = record.plate,
		})
	end
)

local function isAllowedTimePeriod(hours)
	for _, period in ipairs(Config.ImpoundTimePeriods) do
		if period == hours then
			return true
		end
	end
	return false
end

Security.RegisterNetEvent(
	"htb_garage:ImpoundVehicle",
	{ args = { "table" }, cooldownMs = 1000 },
	function(playerId, impoundData)
		local eventName = "htb_garage:ImpoundVehicle"

		if not isImpoundStaff(playerId) then
			notify(playerId, _U("impound_not_auth"))
			return
		end

		-- The vehicle must be the one the server checked in SetupForImpoundVehicle
		local pending = pendingImpounds[playerId]
		if not pending or pending.expires < os.time() then
			notify(playerId, _U("impound_vehicle_gone"))
			return
		end
		if Security.NormalisePlate(impoundData.vehiclePlate) ~= Security.NormalisePlate(pending.plate) then
			Security.Flag(playerId, eventName, "tried to impound a different vehicle to the one inspected")
			return
		end

		-- Validate every field against the config
		local expiryHours = tonumber(impoundData.expiryHours)
		local price = tonumber(impoundData.retrievePrice)
		local reason = Security.CleanString(impoundData.reasonForImpound or "", sec.MaxImpoundReasonLength)

		if
			type(impoundData.impoundId) ~= "string"
			or not Config.Impounds[impoundData.impoundId]
			or not expiryHours
			or not isAllowedTimePeriod(expiryHours)
			or not price
			or price < 0
			or price > sec.MaxImpoundPrice
			or price ~= math.floor(price)
			or reason == nil
		then
			notify(playerId, _U("impound_invalid_details"))
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(pending.plate), function()
			local entity = Security.GetVehicleFromNetId(pending.networkId)
			if
				not entity
				or Security.NormalisePlate(GetVehicleNumberPlateText(entity)) ~= Security.NormalisePlate(pending.plate)
				or not Security.IsPlayerNear(playerId, GetEntityCoords(entity), sec.VehicleDistance)
			then
				notify(playerId, _U("impound_vehicle_gone"))
				return
			end

			-- Someone may have got in while the impound form was open
			if #Security.GetPlayersInVehicle(entity) > 0 then
				notify(playerId, _U("impound_vehicle_occupied"))
				return
			end

			if MySQL.single.await(qu.SqlGetActiveImpoundByPlate.handle, { ["@plate"] = pending.plate }) then
				notify(playerId, _U("already_impounded"))
				return
			end

			MySQL.insert.await(qu.SqlAddImpoundEntry.handle, {
				["@vehiclePlate"] = pending.plate,
				["@impoundName"] = impoundData.impoundId,
				["@reasonForImpound"] = reason,
				["@releaseDateTime"] = os.date("%Y-%m-%d %H:%M:%S", GetTimePlusHours(expiryHours)),
				["@allowPersonalUnimpound"] = impoundData.allowPersonalUnimpound == true,
				["@priceToRelease"] = price,
				["@impoundedByUser"] = Framework.getIdentifier(playerId),
			})
			MySQL.update.await(qu.SqlImpoundVehicle.handle, {
				["@pound"] = 1,
				["@plate"] = pending.plate,
			})

			pendingImpounds[playerId] = nil
			DeleteEntity(entity)
			clearTracked(pending.plate)

			TriggerClientEvent("htb_garage:ImpoundResult", playerId, {
				message = "Vehicle '" .. pending.plate .. "' has been impounded",
				plate = pending.plate,
			})
		end)
	end
)

-- Match a spawn point the client chose against the lot's configured spawn points
local function matchImpoundSpawnPoint(lot, spawnPoint)
	if type(spawnPoint) ~= "table" or type(spawnPoint.Pos) ~= "table" then
		return nil
	end
	local x, y, z = tonumber(spawnPoint.Pos.x), tonumber(spawnPoint.Pos.y), tonumber(spawnPoint.Pos.z)
	if not x or not y or not z then
		return nil
	end

	for _, candidate in ipairs(lot.SpawnPoints) do
		local p = candidate.Point
		if #(vector3(p.x, p.y, p.z) - vector3(x, y, z)) < 1.0 then
			-- Return the configured values, not the client's
			return { Pos = { x = p.x, y = p.y, z = p.z }, Heading = p.w }
		end
	end
	return nil
end

Security.RegisterNetEvent(
	"htb_garage:server:ImpoundRetrieveVehicle",
	{ args = { "table", "table" }, cooldownMs = 2000 },
	function(playerId, vehicle, spawnPoint)
		local eventName = "htb_garage:server:ImpoundRetrieveVehicle"
		if type(vehicle.plate) ~= "string" then
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(vehicle.plate), function()
			-- Never trust the client's copy of the impound record: look it up and confirm
			-- the requesting player owns the vehicle and it is actually impounded.
			local identifier = Framework.getIdentifier(playerId)
			local impound = MySQL.single.await(qu.SqlGetActiveImpoundByPlate.handle, {
				["@plate"] = vehicle.plate,
			})
			if not impound or impound.owner ~= identifier then
				notify(playerId, _U("no_vehicles_impounded"))
				return
			end

			-- The UI hides the button in these cases; enforce them here too
			if not isSet(impound.allowPersonalUnimpound) then
				Security.Flag(playerId, eventName, "collected a vehicle the owner isn't allowed to collect")
				notify(playerId, _U("impound_collect_denied"))
				return
			end
			local h, m, s = GetTimeRemaining(ParseDateTime(impound.releaseDateTime))
			if h > 0 or m > 0 or s > 0 then
				Security.Flag(playerId, eventName, "collected a vehicle before its release time")
				notify(playerId, _U("impound_collect_too_early", h, m))
				return
			end

			-- Vehicles can only be collected from the lot they are held at
			local lot = Config.Impounds[impound.impoundName]
			if not lot then
				return
			end
			if not Security.IsPlayerNear(playerId, lot.RetrievePoint.Pos, sec.InteractionDistance) then
				Security.Flag(playerId, eventName, "retrieved a vehicle away from impound " .. impound.impoundName)
				return
			end

			local spawn = matchImpoundSpawnPoint(lot, spawnPoint)
			if not spawn then
				Security.Flag(playerId, eventName, "sent a spawn point that isn't part of impound " .. impound.impoundName)
				return
			end

			local price = tonumber(impound.priceToRelease) or 0
			if price > 0 and not chargePlayer(playerId, price) then
				notify(playerId, _U("impound_fee_not_enough"))
				return
			end

			-- An impounded vehicle shouldn't exist in the world; remove any stray copy
			local stray = Security.FindVehicleByPlate(vehicle.plate)
			if stray then
				DeleteEntity(stray)
			end

			MySQL.update.await(qu.SqlReleaseImpoundVehicle.handle, {
				["@plate"] = vehicle.plate,
			})

			local fullVehicle = MySQL.single.await(qu.SqlGetVehicle.handle, {
				["@identifier"] = identifier,
				["@plate"] = vehicle.plate,
			})
			issueSpawnTicket(playerId, identifier, fullVehicle.plate, fullVehicle.vehicle)

			TriggerClientEvent("htb_garage:client:VehicleImpoundRetrieved", playerId, fullVehicle, spawn)
		end)
	end
)

Security.RegisterNetEvent(
	"htb_garage:server:ReturnVehicleToOwner",
	{ args = { "table" }, cooldownMs = 2000 },
	function(playerId, vehicle)
		local eventName = "htb_garage:server:ReturnVehicleToOwner"
		if type(vehicle.plate) ~= "string" then
			return
		end

		-- Only impound staff may release a vehicle without payment
		if not isImpoundStaff(playerId) then
			notify(playerId, _U("return_not_auth"))
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(vehicle.plate), function()
			local impound = MySQL.single.await(qu.SqlGetActiveImpoundByPlate.handle, {
				["@plate"] = vehicle.plate,
			})
			if not impound then
				return
			end

			-- Corruption prevention: staff can't waive the fee on their own vehicles (any character)
			if ownsOnAnyCharacter(playerId, impound.owner) then
				notify(playerId, _U("return_not_auth"))
				return
			end

			local lot = Config.Impounds[impound.impoundName]
			if not lot or not Security.IsPlayerNear(playerId, lot.RetrievePoint.Pos, sec.InteractionDistance) then
				Security.Flag(playerId, eventName, "released a vehicle away from its impound")
				return
			end

			MySQL.update.await(qu.SqlReleaseImpoundVehicle.handle, {
				["@plate"] = vehicle.plate,
			})

			local message = ("Vehicle %s has been returned to the owner"):format(vehicle.plate)
			TriggerClientEvent("htb_garage:client:VehicleReturnedToOwner", playerId, message)
		end)
	end
)

Security.RegisterNetEvent(
	"htb_garage:server:FetchImpoundedPlayerVehicles",
	{ args = { "string" }, cooldownMs = 1000 },
	function(playerId, impoundName)
		local lot = Config.Impounds[impoundName]
		if not lot then
			Security.Flag(playerId, "htb_garage:server:FetchImpoundedPlayerVehicles", "unknown impound " .. impoundName)
			return
		end
		if not Security.IsPlayerNear(playerId, lot.RetrievePoint.Pos, sec.InteractionDistance) then
			Security.Flag(
				playerId,
				"htb_garage:server:FetchImpoundedPlayerVehicles",
				"opened impound " .. impoundName .. " from a distance"
			)
			return
		end

		local vehicles = MySQL.query.await(qu.SqlGetImpoundedPlayerVehicles.handle, {
			["@license"] = Framework.getIdentifier(playerId),
			["@impoundName"] = impoundName,
		}) or {}

		for _, veh in pairs(vehicles) do
			local releaseTs = ParseDateTime(veh.releaseDateTime)
			local h, m, s = GetTimeRemaining(releaseTs)

			if h == 0 and m == 0 and s == 0 then
				veh.timeLeft = nil
				veh.expired = true
			else
				veh.timeLeft = ("%dh %dm %ds"):format(h, m, s)
				veh.expired = false
			end

			local vehLot = Config.Impounds[veh.impoundId]
			veh.impoundName = vehLot and vehLot.RetrievePoint.Name or veh.impoundId

			-- "Return to owner" is a staff action, but this list only ever contains the player's
			-- own vehicles and staff can't waive fees on their own vehicles. Hidden until there's
			-- a staff view of other players' impounded vehicles (see TODO.md).
			veh.allowReturn = false
		end

		TriggerClientEvent("htb_garage:client:ReturnImpoundedPlayerVehicles", playerId, vehicles)
	end
)

-------------------------------------------------------------------------------------------
-- Impound release (/ImpoundRelease): staff in Config.AllowedImpoundReleaseJobs can release
-- any held vehicle, including ones the owner isn't allowed to collect themselves. The
-- vehicle is parked, locked, in a free spot at the impound it's held at.
-------------------------------------------------------------------------------------------

-- What CreateVehicleServerSetter needs; the releasing client works it out from the model
local SERVER_VEHICLE_TYPES = {
	automobile = true,
	bike = true,
	boat = true,
	heli = true,
	plane = true,
	submarine = true,
	trailer = true,
	train = true,
}

local function findOnlinePlayer(identifier)
	for _, id in ipairs(GetPlayers()) do
		local playerId = tonumber(id)
		if Framework.getIdentifier(playerId) == identifier then
			return playerId
		end
	end
	return nil
end

-- First of the lot's parking spots with no vehicle on it
local function freeImpoundParkingSpot(lot)
	local vehicles = GetAllVehicles()
	for _, spot in ipairs(lot.SpawnPoints or {}) do
		local p = spot.Point
		local pos = vector3(p.x, p.y, p.z)
		local taken = false
		for _, vehicle in ipairs(vehicles) do
			if #(GetEntityCoords(vehicle) - pos) < 3.0 then
				taken = true
				break
			end
		end
		if not taken then
			return p
		end
	end
	return nil
end

Security.RegisterNetEvent("htb_garage:server:OpenImpoundRelease", { cooldownMs = 1000 }, function(playerId)
	if not isImpoundReleaseStaff(playerId) then
		notify(playerId, _U("impound_release_not_auth"))
		return
	end

	local vehicles = MySQL.query.await(qu.SqlGetAllActiveImpounds.handle, {}) or {}
	for _, veh in ipairs(vehicles) do
		local h, m, s = GetTimeRemaining(ParseDateTime(veh.releaseDateTime))
		veh.expired = h == 0 and m == 0 and s == 0
		veh.timeLeft = not veh.expired and ("%dh %dm %ds"):format(h, m, s) or nil

		local lot = Config.Impounds[veh.impoundId]
		veh.impoundName = lot and lot.RetrievePoint.Name or veh.impoundId
		veh.allowPersonalUnimpound = isSet(veh.allowPersonalUnimpound)
		if veh.ownerName == "" then
			veh.ownerName = nil
		end
		-- The form shows "another officer must release this" instead of the button
		veh.ownedByOfficer = ownsOnAnyCharacter(playerId, veh.owner)
		veh.owner = nil -- the identifier isn't needed by the client
	end

	TriggerClientEvent("htb_garage:client:ImpoundReleaseList", playerId, vehicles)
end)

Security.RegisterNetEvent(
	"htb_garage:server:ImpoundReleaseVehicle",
	{ args = { "string", "string" }, cooldownMs = 2000 },
	function(playerId, plate, vehicleType)
		local eventName = "htb_garage:server:ImpoundReleaseVehicle"
		if not isImpoundReleaseStaff(playerId) then
			notify(playerId, _U("impound_release_not_auth"))
			return
		end
		if not SERVER_VEHICLE_TYPES[vehicleType] then
			Security.Flag(playerId, eventName, "sent an unknown vehicle type " .. tostring(vehicleType))
			return
		end

		Security.WithLock("vehicle:" .. Security.NormalisePlate(plate), function()
			local impound = MySQL.single.await(qu.SqlGetActiveImpoundByPlate.handle, { ["@plate"] = plate })
			if not impound then
				notify(playerId, _U("impound_release_not_held"))
				return
			end

			-- Corruption prevention: staff can't release their own vehicles (any character)
			if ownsOnAnyCharacter(playerId, impound.owner) then
				notify(playerId, _U("impound_release_own_vehicle"))
				return
			end

			local lot = Config.Impounds[impound.impoundName]
			local record = MySQL.single.await(qu.SqlGetVehicleByPlate.handle, { ["@plate"] = plate })
			local props = record and decodeProps(record.vehicle)
			local model = props and modelHash(props.model)
			if not lot or not model then
				notify(playerId, _U("vehicle_error"))
				return
			end

			local spot = freeImpoundParkingSpot(lot)
			if not spot then
				notify(playerId, _U("spawn_point_occupied"))
				return
			end

			-- An impounded vehicle shouldn't exist in the world; remove any stray copy
			local stray = Security.FindVehicleByPlate(record.plate)
			if stray then
				DeleteEntity(stray)
			end

			local entity = CreateVehicleServerSetter(model, vehicleType, spot.x, spot.y, spot.z, spot.w + 0.0)
			local waited = 0
			while not DoesEntityExist(entity) and waited < 3000 do
				Citizen.Wait(50)
				waited = waited + 50
			end
			if not DoesEntityExist(entity) then
				notify(playerId, _U("vehicle_error"))
				return
			end

			SetVehicleNumberPlateText(entity, record.plate)
			SetVehicleDoorsLocked(entity, 2)
			if SetEntityOrphanMode then
				SetEntityOrphanMode(entity, 2) -- keep it when the player near it leaves
			end
			-- Mods, colours, damage etc. are applied by whichever client owns it (Client/impound.lua)
			Entity(entity).state:set("htb_garage:props", props, true)

			MySQL.update.await(qu.SqlReleaseImpoundVehicle.handle, { ["@plate"] = record.plate })
			setTracked(record.plate, NetworkGetNetworkIdFromEntity(entity))

			local ownerId = findOnlinePlayer(impound.owner)
			if ownerId then
				Keys.give(ownerId, record.plate, "permanent")
				notify(ownerId, _U("impound_release_owner", record.plate, lot.RetrievePoint.Name))
			end

			notify(playerId, _U("impound_release_done", record.plate, lot.RetrievePoint.Name))
			TriggerClientEvent("htb_garage:client:ImpoundReleaseComplete", playerId, record.plate)
		end)
	end
)

-------------------------------------------------------------------------------------------
-- Server exports for other resources. Clients can't call exports, so these are the safe
-- way for other server scripts (e.g. a vehicle shop) to integrate.
-------------------------------------------------------------------------------------------

--- Track a vehicle that another resource spawned, so it can't be duplicated from a garage.
exports("StartTrackingVehicle", function(plate, networkId)
	if type(plate) ~= "string" or not tonumber(networkId) then
		return false
	end
	setTracked(plate, tonumber(networkId))
	return true
end)

--- Stop tracking a vehicle, e.g. when another resource deletes or impounds it.
exports("StopTrackingVehicle", function(plate)
	if type(plate) ~= "string" then
		return false
	end
	clearTracked(plate)
	return true
end)

--- Give a player keys using the configured key system.
exports("GiveVehicleKeys", function(playerId, plate, lifetime)
	Keys.give(playerId, plate, lifetime == "temporary" and "temporary" or "permanent")
end)

-------------------------------------------------------------------------------------------
-- Admin / debug commands (restricted: grant with `add_ace group.admin command.<name> allow`)
-------------------------------------------------------------------------------------------
RegisterCommand("garageToggleDebug", function(source, args, raw)
	garageDebug = not garageDebug
end, true)

RegisterCommand("dumpVehicleInstances", function(source, args, raw)
	if garageDebug then
		Citizen.Trace(json.encode(vehicleInstances) .. "\n")
	end
end, true)

RegisterCommand("settime", function(source, args, raw)
	if source ~= 0 then
		print("This command must be run from the server console or RCON.")
		return
	end

	local hour = tonumber(args[1]) or 12
	local minute = tonumber(args[2]) or 0
	local second = tonumber(args[3]) or 0

	print(("→ Setting time to %02d:%02d:%02d"):format(hour, minute, second))
	-- -1 sends to all clients
	TriggerClientEvent("timeSync:updateTime", -1, hour, minute, second)
end, false)
