local function GetVehicleInFront(distance)
	local ped = PlayerPedId()
	local src = GetEntityCoords(ped)
	local aim = src + GetEntityForwardVector(ped) * (distance or 6.0)

	-- flag = 2 → vehicles only (no peds)
	local rayHandle = StartShapeTestRay(
		src.x,
		src.y,
		src.z,
		aim.x,
		aim.y,
		aim.z,
		eTraceFlags.IntersectVehicles,
		ped, -- ignore yourself
		eTraceOptionFlags.None
	)

	local _, hit, _, _, ent = GetShapeTestResult(rayHandle)
	if hit == 1 and DoesEntityExist(ent) and IsEntityAVehicle(ent) then
		return ent
	end

	return nil
end

local function GetVehicleInFrontCone(maxDist, fovDegrees)
	local ped = PlayerPedId()
	local pCoords = GetEntityCoords(ped)
	local forward = GetEntityForwardVector(ped)
	local cosThresh = math.cos(math.rad(fovDegrees * 0.5))
	local bestVeh, bestDist = nil, maxDist + 1

	-- grab *all* vehicles currently spawned
	for _, veh in ipairs(GetGamePool("CVehicle")) do
		-- don’t hit the one you’re in:
		if veh ~= GetVehiclePedIsIn(ped, false) then
			local vCoords = GetEntityCoords(veh)
			local offset = vCoords - pCoords
			local dist = #offset
			if dist <= maxDist then
				-- normalize and dot
				local dir = offset / dist
				if (forward.x * dir.x + forward.y * dir.y + forward.z * dir.z) >= cosThresh then
					-- vehicle is within your cone
					if dist < bestDist then
						bestDist = dist
						bestVeh = veh
					end
				end
			end
		end
	end

	return bestVeh
end

function OpenImpoundUI(plate, impounds)
	local messageData = {
		type = "setupImpoundStoreVehicle",
		vehiclePlate = plate,
		availableImpounds = impounds,
		timePeriods = Config.ImpoundTimePeriods,
		retrievePrice = Config.ImpoundDefaultRetrievePrice,
	}
	SendNUIMessage(messageData)

	ToggleGUI(true, "enableImpound", "/impound")
end

RegisterCommand("impound", function()
	local veh = GetVehicleInFrontCone(5.0, 90)

	if veh == nil or not NetworkGetEntityIsNetworked(veh) then
		Notify.send(_U("no_vehicles_nearby"))
		return
	end

	-- Send the network id so the server can check the real vehicle (plate, distance)
	TriggerServerEvent("htb_garage:server:SetupForImpoundVehicle", NetworkGetNetworkIdFromEntity(veh))
end, false)

RegisterNetEvent("htb_garage:client:SetupForImpoundVehicleResults")
AddEventHandler("htb_garage:client:SetupForImpoundVehicleResults", function(data)
	local impounds = {}

	for _, imp in ipairs(data.impounds) do -- keep the server's order (by name)
		table.insert(impounds, {
			id = imp.impoundId,
			displayName = imp.displayName,
		})
	end

	local plate = data.data
	OpenImpoundUI(plate, impounds)
end)

RegisterNUICallback("impoundStore", function(impoundData, cb)
	TriggerServerEvent("htb_garage:ImpoundVehicle", impoundData)

	cb("ok")
end)

RegisterNetEvent("htb_garage:ImpoundResult")
AddEventHandler("htb_garage:ImpoundResult", function(data)
	-- The server has already removed the vehicle from the world
	ToggleGUI(false)

	Notify.send(data.message)
end)

function FetchImpoundedPlayerVehicles(impoundName)
	TriggerServerEvent("htb_garage:server:FetchImpoundedPlayerVehicles", impoundName)
end

function OpenImpoundRetrieveUI(impoundedPlayerVehicles, route)
	-- {
	-- 	type: string;
	-- 	plate: string;
	-- 	displayName: string;
	-- 	modelName: string;
	-- 	spawnName: string;
	-- 	import: boolean;
	-- 	price: number;
	-- 	timeLeft: number;
	-- 	impoundId: number;
	--   }
	local messageData = {
		type = "setupImpoundRetrieveVehicle",
		vehicles = impoundedPlayerVehicles,
	}
	SendNUIMessage(messageData)

	ToggleGUI(true, "enableImpound", route)
end

RegisterNetEvent("htb_garage:client:ReturnImpoundedPlayerVehicles")
AddEventHandler("htb_garage:client:ReturnImpoundedPlayerVehicles", function(impoundedPlayerVehicles)
	Zones.Log("server sent impounded vehicles")
	if not impoundedPlayerVehicles or #impoundedPlayerVehicles < 1 then
		Notify.send(_U("no_vehicles_impounded"))
		return
	end

	for k, veh in pairs(impoundedPlayerVehicles) do
		veh.spawnName = GetDisplayNameFromVehicleModel(veh.model)
	end

	OpenImpoundRetrieveUI(impoundedPlayerVehicles, "/retrieve")
end)

RegisterNUICallback("impoundRetrieve", function(vehicle, cb)
	local spawnPoint = DetermineImpoundRetrieveSpawnLocation(Config.Impounds[vehicle.impoundId].SpawnPoints)

	if spawnPoint == nil then
		Notify.send(_U("spawn_point_occupied"))
		return
	end

	TriggerServerEvent("htb_garage:server:ImpoundRetrieveVehicle", vehicle, spawnPoint)

	cb("ok")
end)

RegisterNetEvent("htb_garage:client:VehicleImpoundRetrieved")
AddEventHandler("htb_garage:client:VehicleImpoundRetrieved", function(vehicle, spawnPoint)
	-- May want to call through to server here depending on how things go with OneSync Infinity and vehicle duplication
	DoTheSpawn(vehicle.vehicle, spawnPoint, false)

	local message = (_U("impound_vehicle_released")):format()
	Notify.send(message)
	ToggleGUI(false)
end)

RegisterNUICallback("returnToOwner", function(data, cb)
	if data.userIsImpoundManager == nil or data.userIsImpoundManager == false then
		Notify.send(_U("return_not_auth"))
		return
	end
	if data ~= nil and data.vehicle ~= nil then
		TriggerServerEvent("htb_garage:server:ReturnVehicleToOwner", data.vehicle)
	end

	cb("ok")
end)

RegisterNetEvent("htb_garage:client:VehicleReturnedToOwner")
AddEventHandler("htb_garage:client:VehicleReturnedToOwner", function(message)
	Notify.send(message)
	ToggleGUI(false)
end)

----------------------------------------------------------------------------------------------------
-- /ImpoundRelease: staff (Config.AllowedImpoundReleaseJobs) search every held vehicle and
-- release it to a parking spot at the impound it's held at. The server checks the job.

RegisterCommand("ImpoundRelease", function()
	TriggerServerEvent("htb_garage:server:OpenImpoundRelease")
end, false)

RegisterNetEvent("htb_garage:client:ImpoundReleaseList")
AddEventHandler("htb_garage:client:ImpoundReleaseList", function(vehicles)
	if not vehicles or #vehicles < 1 then
		Notify.send(_U("impound_release_none"))
		return
	end

	for _, veh in ipairs(vehicles) do
		veh.spawnName = GetDisplayNameFromVehicleModel(veh.model)
		veh.modelName = GetLabelText(veh.spawnName)
	end

	SendNUIMessage({
		type = "setupImpoundReleaseVehicle",
		vehicles = vehicles,
	})
	ToggleGUI(true, "enableImpound", "/impoundRelease")
end)

-- The kind of entity the server must create for a model
local function serverVehicleType(model)
	if IsThisModelABoat(model) or IsThisModelAJetski(model) then
		return "boat"
	elseif IsThisModelAHeli(model) then
		return "heli"
	elseif IsThisModelAPlane(model) then
		return "plane"
	elseif IsThisModelABike(model) or IsThisModelABicycle(model) then
		return "bike"
	elseif IsThisModelATrain(model) then
		return "train"
	elseif GetVehicleClassFromName(model) == 14 then
		return "boat" -- submersibles are class 14 too, close enough for spawning
	end
	return "automobile"
end

RegisterNUICallback("impoundRelease", function(vehicle, cb)
	if type(vehicle) == "table" and type(vehicle.plate) == "string" and vehicle.model then
		TriggerServerEvent("htb_garage:server:ImpoundReleaseVehicle", vehicle.plate, serverVehicleType(vehicle.model))
	end
	cb("ok")
end)

RegisterNetEvent("htb_garage:client:ImpoundReleaseComplete")
AddEventHandler("htb_garage:client:ImpoundReleaseComplete", function(plate)
	-- The list stays open so several vehicles can be released; drop this one from it
	SendNUIMessage({ type = "impoundReleaseComplete", plate = plate })
end)

-- A released vehicle is created by the server, which can't apply mods, colours or damage.
-- Whichever client owns it does that once, then clears the state.
AddStateBagChangeHandler("htb_garage:props", nil, function(bagName, _, props)
	if type(props) ~= "table" then
		return
	end
	local entity = GetEntityFromStateBagName(bagName)
	local waited = 0
	while entity == 0 and waited < 5000 do
		Wait(100)
		waited = waited + 100
		entity = GetEntityFromStateBagName(bagName)
	end
	-- The server hands it to a nearby player straight after it appears
	waited = 0
	while entity ~= 0 and not NetworkHasControlOfEntity(entity) and waited < 5000 do
		Wait(100)
		waited = waited + 100
	end
	if entity == 0 or not DoesEntityExist(entity) or not NetworkHasControlOfEntity(entity) then
		return -- not ours; the owner applies them
	end

	SetVehicleProperties(entity, props)
	SetVehicleDoorsLocked(entity, 2)
	Entity(entity).state:set("htb_garage:props", nil, true)
end)
