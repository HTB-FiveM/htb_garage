
HtbGarageUtil = {}
function HtbGarageUtil.RequestModel(modelHash, cb)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
		RequestModel(modelHash)
		while not HasModelLoaded(modelHash) do
			Citizen.Wait(4)
		end
	end

	if cb ~= nil then
		cb()
	end
end


function SpawnVehicle(veh, coords, heading, cb, networked)
	local model = (type(veh) == 'number' and veh or GetHashKey(veh))
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

	networked = networked and networked ~= false -- Ensure networked will never be nil
	Citizen.CreateThread(function()
		frameworkFunctionMappings[Config.RolePlayFramework]['requestModel'](model)

		local vehicle = CreateVehicle(model, vector.x, vector.y, vector.z, heading, networked, false)

		local networkId = nil
		if networked == true then
			networkId = NetworkGetNetworkIdFromEntity(vehicle)
			SetNetworkIdCanMigrate(networkId, true) -- Allow player interaction
			SetEntityAsMissionEntity(vehicle, true, false) -- Ensure no automatic despawn
		end
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
		SetVehRadioStation(vehicle, 'OFF')

		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(vehicle) do
			Citizen.Wait(0)
		end

		if cb then
			cb(vehicle, networkId)
		end
	end)
end


