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

	TriggerServerEvent("htb_garage:SetupForImpoundVehicle", plate)
end, false)

RegisterNetEvent("htb_garage:SetupForImpoundVehicleResults")
AddEventHandler("htb_garage:SetupForImpoundVehicleResults", function(data)
	local impounds = {}
	for a, imp in pairs(data.impounds) do
		table.insert(impounds, {
			id = imp.impoundId,
			displayName = imp.displayName,
			locationX = imp.locationX,
			locationY = imp.locationY,
			locationZ = imp.locationZ,
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

RegisterNetEvent("htb_garage:Released")
AddEventHandler("htb_garage:Released", function(message, carplate)
	FrameworkCtx:ShowNotification(message)

	-- Charge the player

	-- Spawn the vehicle
end)
