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
	}
	SendNUIMessage(messageData)

	ToggleGUI(true, "enableImpound", "/impound")
end

RegisterCommand("impound", function()
	local veh = GetVehicleInFrontCone(5.0, 90)

	if veh == nil then
		FrameworkCtx:ShowNotification(_U("no_vehicles_nearby"))
		return
	end

	local plate = GetVehicleNumberPlateText(veh)

	TriggerServerEvent("htb_garage:server:SetupForImpoundVehicle", plate)
end, false)

RegisterNetEvent("htb_garage:client:SetupForImpoundVehicleResults")
AddEventHandler("htb_garage:client:SetupForImpoundVehicleResults", function(data)
	local impounds = {}

	for a, imp in pairs(data.impounds) do
		table.insert(impounds, {
			id = imp.impoundId,
			displayName = imp.displayName,
		})
	end

	local plate = data.data
	OpenImpoundUI(plate, impounds)
end)

RegisterNUICallback("impoundStore", function(impoundData, cb)
	local expiryTime = GetGameTimePlus(impoundData.expiryHours)
	impoundData.releaseDateTime = ("%02d:%02d:%02d"):format(expiryTime.hours, expiryTime.minutes, expiryTime.seconds)

	TriggerServerEvent("htb_garage:ImpoundVehicle", impoundData)

	cb("ok")
end)

RegisterNetEvent("htb_garage:ImpoundResult")
AddEventHandler("htb_garage:ImpoundResult", function(data)
	local vehicleEntity = GetVehicleByPlate(data.plate)
	--HandleVehicleSpecifics(vehicleEntity, vehicleType, deleteZone)
	DeleteEntity(vehicleEntity)
	ToggleGUI(false)

	FrameworkCtx:ShowNotification(data.message)
end)






function FetchImpoundedPlayerVehicles(impoundName)
	TriggerServerEvent("htb_garage:server:FetchImpoundedPlayerVehicles", impoundName)
end



function OpenImpoundRetrieveUI(impoundedPlayerVehicles, userIsImpoundManager)
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
		userIsImpoundManager = userIsImpoundManager,
		vehicles = impoundedPlayerVehicles
	}
	SendNUIMessage(messageData)

	ToggleGUI(true, "enableImpound", "/impound")
end

RegisterNetEvent("htb_garage:client:ReturnImpoundedPlayerVehicles")
AddEventHandler("htb_garage:client:ReturnImpoundedPlayerVehicles", function(impoundedPlayerVehicles, userIsImpoundManager)
	
	for k, veh in pairs(impoundedPlayerVehicles) do
		veh.spawnName = GetDisplayNameFromVehicleModel(veh.model)

	end

	OpenImpoundRetrieveUI(impoundedPlayerVehicles, userIsImpoundManager)
end)


RegisterNUICallback("impoundRetrieve", function(vehicle, cb)

	TriggerServerEvent("htb_garage:server:ImpoundRetrieveVehicle", vehicle)

	cb("ok")
end)

RegisterNetEvent("htb_garage:client:VehicleImpoundRetrieved")
AddEventHandler("htb_garage:client:VehicleImpoundRetrieved", function(vehicle, impoundId)
	local spawnPoint = DetermineImpoundRetrieveSpawnLocation(Config.Impounds[impoundId].SpawnPoints)

	if spawnPoint == nil then
		FrameworkCtx:ShowNotification(_U("spawn_point_occupied"))
		return
	end

	-- May want to call through to server here depending on how things go with OneSync Infinity and vehicle duplication
	DoTheSpawn(vehicle.vehicle, spawnPoint)
	TriggerEvent('qb-vehiclekeys:client:AddKeys', vehicle.plate)


	local message = (""):format()
	FrameworkCtx:ShowNotification(message)
	ToggleGUI(false)
end)



RegisterNUICallback("returnToOwner", function(data, cb)
	if data.userIsImpoundManager == nil or data.userIsImpoundManager == false then
		FrameworkCtx:ShowNotification(_U('return_not_auth'))
		return
	end
	if data ~= nil and data.vehicle ~= nil then
		TriggerServerEvent("htb_garage:server:ReturnVehicleToOwner", data.vehicle)
	end

	cb("ok")
end)

RegisterNetEvent("htb_garage:client:VehicleReturnedToOwner")
AddEventHandler("htb_garage:client:VehicleReturnedToOwner", function(message)
	FrameworkCtx:ShowNotification(message)
	ToggleGUI(false)
end)


RegisterNetEvent("htb_garage:Released")
AddEventHandler("htb_garage:Released", function(message, carplate)
	FrameworkCtx:ShowNotification(message)

	-- Charge the player

	-- Spawn the vehicle
end)
