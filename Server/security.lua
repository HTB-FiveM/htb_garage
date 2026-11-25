-------------------------------------------------------------------------------------------
-- Server side guards for every network event this resource exposes.
--
-- Clients can never be trusted: cheat menus run inside the resource's own client Lua
-- and can call TriggerServerEvent with any arguments. A shared secret sent by the client
-- doesn't help, because anything the client knows a cheater can read. So every event is:
--   * registered through Security.RegisterNetEvent, which rejects non-player sources,
--     rate limits each player and type checks the arguments, and
--   * validated inside its handler against server owned state (database, config, and
--     the real entities via OneSync).
--
-- Anything that looks like tampering is reported through Security.Flag, which fires the
-- server-only event "htb_garage:server:suspiciousActivity" so server owners can connect
-- their own anticheat, ban system or Discord logging:
--
--   AddEventHandler("htb_garage:server:suspiciousActivity", function(playerId, eventName, reason)
--       -- ban / log / notify staff
--   end)
--
-- Never RegisterNetEvent that event name, or clients will be able to fake reports.
-------------------------------------------------------------------------------------------

Security = {}

local settings = Config.Security or {}
local lastCallTimes = {} -- [playerId][eventName] = GetGameTimer()

local function isValidPlayer(playerId)
	playerId = tonumber(playerId)
	return playerId ~= nil and playerId > 0 and GetPlayerName(playerId) ~= nil
end

Security.IsValidPlayer = isValidPlayer

--- Report a request that could only come from a modified client.
function Security.Flag(playerId, eventName, reason)
	local name = GetPlayerName(playerId) or "unknown"
	print(
		("^3[htb_garage] Suspicious call to '%s' from %s (id %s): %s^0"):format(
			eventName,
			name,
			tostring(playerId),
			reason
		)
	)

	TriggerEvent("htb_garage:server:suspiciousActivity", playerId, eventName, reason)

	if settings.KickOnSuspicious and isValidPlayer(playerId) then
		DropPlayer(playerId, settings.KickMessage or "Kicked for suspicious activity")
	end
end

--- Type check a value against a spec such as "string", "number", "table" or "string?" (optional).
local function matchesType(value, spec)
	local optional = spec:sub(-1) == "?"
	local expected = optional and spec:sub(1, -2) or spec

	if value == nil then
		return optional
	end

	return type(value) == expected
end

--- Register a network event that only real players can call.
-- @param eventName string
-- @param opts table|nil  { args = { "string", "number?" }, cooldownMs = 500 }
-- @param handler function(playerId, ...)  receives the validated caller as its first argument
function Security.RegisterNetEvent(eventName, opts, handler)
	opts = opts or {}
	local argSpecs = opts.args or {}
	local cooldownMs = opts.cooldownMs or settings.DefaultCooldownMs or 250

	RegisterNetEvent(eventName, function(...)
		-- Capture source straight away: it is reset after the handler yields
		local playerId = tonumber(source)

		-- Net events must come from a connected player. Anything else (e.g. source 0
		-- from a server TriggerEvent) is refused: server code should use the exports.
		if not isValidPlayer(playerId) then
			return
		end

		-- Rate limit per player, per event, before anything else so spam (valid or not)
		-- is dropped cheaply. Legitimate clients never call this fast.
		local now = GetGameTimer()
		local calls = lastCallTimes[playerId]
		if not calls then
			calls = {}
			lastCallTimes[playerId] = calls
		end
		if calls[eventName] and (now - calls[eventName]) < cooldownMs then
			return
		end
		calls[eventName] = now

		local args = table.pack(...)
		for i, spec in ipairs(argSpecs) do
			if not matchesType(args[i], spec) then
				Security.Flag(
					playerId,
					eventName,
					("argument %d should be %s but was %s"):format(i, spec, type(args[i]))
				)
				return
			end
		end

		handler(playerId, table.unpack(args, 1, args.n))
	end)
end

AddEventHandler("playerDropped", function()
	lastCallTimes[tonumber(source)] = nil
end)

-------------------------------------------------------------------------------------------
-- Validation helpers
-------------------------------------------------------------------------------------------

--- Trim and length limit a string. Returns nil if it isn't a string.
function Security.CleanString(value, maxLength)
	if type(value) ~= "string" then
		return nil
	end
	value = trim(value)
	if maxLength and #value > maxLength then
		value = value:sub(1, maxLength)
	end
	return value
end

--- Normalise a plate for comparisons (plates are padded with spaces in game).
function Security.NormalisePlate(plate)
	if type(plate) ~= "string" then
		return nil
	end
	return trim(plate):upper()
end

--- Model hashes can come back signed or unsigned depending on where they were read.
function Security.NormaliseHash(hash)
	hash = tonumber(hash)
	if not hash then
		return nil
	end
	return math.floor(hash) % 4294967296
end

local function toVector3(pos)
	if type(pos) == "vector3" or type(pos) == "vector4" then
		return vector3(pos.x, pos.y, pos.z)
	end
	return vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
end

--- Distance from a player's ped to a position (server side, needs OneSync).
function Security.DistanceToPlayer(playerId, pos)
	local ped = GetPlayerPed(playerId)
	if not ped or ped == 0 then
		return math.huge
	end
	return #(GetEntityCoords(ped) - toVector3(pos))
end

function Security.IsPlayerNear(playerId, pos, maxDistance)
	local distance = Security.DistanceToPlayer(playerId, pos)
	if distance <= maxDistance then
		return true
	end

	-- Say why, so a server problem is easy to tell from a cheater
	local ped = GetPlayerPed(playerId)
	if not ped or ped == 0 then
		print(("^3[htb_garage] The server can't see player %s's character. Is OneSync on?^0"):format(playerId))
	else
		local at = GetEntityCoords(ped)
		local target = toVector3(pos)
		print(
			(
				"^3[htb_garage] Player %s is %.1fm from (%.1f, %.1f, %.1f), limit %.1fm. Server sees them at (%.1f, %.1f, %.1f)."
				.. " If they're really there, their position isn't reaching the server (e.g. after noclip): reconnecting fixes it.^0"
			):format(playerId, distance, target.x, target.y, target.z, maxDistance, at.x, at.y, at.z)
		)
	end
	return false
end

--- Resolve a network id sent by a client to a vehicle entity that really exists.
-- Waits briefly because a freshly created entity can arrive just after the event.
function Security.GetVehicleFromNetId(networkId, waitMs)
	networkId = tonumber(networkId)
	if not networkId then
		return nil
	end

	local waited = 0
	local timeout = waitMs or 0
	while true do
		local entity = NetworkGetEntityFromNetworkId(networkId)
		if entity and entity ~= 0 and DoesEntityExist(entity) then
			if GetEntityType(entity) == 2 then
				return entity
			end
			return nil
		end

		if waited >= timeout then
			return nil
		end
		Citizen.Wait(100)
		waited = waited + 100
	end
end

--- Find a vehicle in the world with the given plate (server side scan, needs OneSync).
function Security.FindVehicleByPlate(plate)
	local wanted = Security.NormalisePlate(plate)
	if not wanted then
		return nil
	end

	for _, vehicle in ipairs(GetAllVehicles()) do
		if DoesEntityExist(vehicle) and Security.NormalisePlate(GetVehicleNumberPlateText(vehicle)) == wanted then
			return vehicle
		end
	end
	return nil
end

--- The player id driving a ped, or nil.
function Security.GetPlayerFromPed(ped)
	if not ped or ped == 0 then
		return nil
	end
	for _, id in ipairs(GetPlayers()) do
		if GetPlayerPed(id) == ped then
			return tonumber(id)
		end
	end
	return nil
end

--- All player ids sitting in a vehicle.
function Security.GetPlayersInVehicle(vehicle)
	local players = {}
	for seat = -1, 15 do
		local playerId = Security.GetPlayerFromPed(GetPedInVehicleSeat(vehicle, seat))
		if playerId then
			table.insert(players, playerId)
		end
	end
	return players
end

-------------------------------------------------------------------------------------------
-- Simple per key locks so two requests can't act on the same vehicle at the same time
-------------------------------------------------------------------------------------------
local locks = {}

--- Run fn while holding a lock for key. Returns false if the key is already locked.
function Security.WithLock(key, fn)
	if locks[key] then
		return false
	end
	locks[key] = true
	local ok, err = pcall(fn)
	locks[key] = nil
	if not ok then
		print(("^1[htb_garage] Error while handling %s: %s^0"):format(tostring(key), tostring(err)))
	end
	return true
end
