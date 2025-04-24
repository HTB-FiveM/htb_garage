if Config.Debug then
	debugPostList = {}
end
local isVisible = false
local vehicleInstances = {}

-------------------------------------------------------------------------------------------

FrameworkCtx:RunStartupStuff()

-------------------------------------------------------------------------------------------
function ToggleGUI(explicit_status, type, route)

	if explicit_status ~= nil then
		isVisible = explicit_status
	else
		isVisible = not isVisible
	end
	SetNuiFocus(isVisible, isVisible)

	local messageData = {
		type = type or "toggleVisibility",
		route = route,
		isVisible = isVisible
	}
	-- print(json.encode(messageData))
	SendNUIMessage(messageData)

end

function HandleVehicleSpecifics(vehicleEntity, vehicleType, deleteZone)
	if vehicleType == "boat" and deleteZone.DryPoint then
		local pos = deleteZone.DryPoint

		-- Get all peds so we can spawn them all on dry land
		local numberOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicleEntity))
		local playerServerIds = {}
		local driverSeat = -1
		local lastSeat = driverSeat + numberOfSeats - 1

		for seat = driverSeat, lastSeat, 1 do
			local playerPed = GetPedInVehicleSeat(vehicleEntity, seat)
			local svrId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(playerPed))
			if svrId > 0 then
				table.insert(playerServerIds, svrId)
			end

			local netIds = NetworkGetNetworkIdFromEntity(playerPed)
		end

		TriggerServerEvent("htb_garage:TeleportAllInVehicleToDock", playerServerIds, {
			x = deleteZone.DryPoint.x,
			y = deleteZone.DryPoint.y,
			z = deleteZone.DryPoint.z,
			h = deleteZone.DryPoint.h,
		})
	end
end

RegisterNetEvent("htb_garage:UpdateLocalVehicleInstances")
AddEventHandler("htb_garage:UpdateLocalVehicleInstances", function(vehicles)
	vehicleInstances = vehicles
	--print(json.encode(vehicleInstances))
end)

RegisterNetEvent("htb_garage:HandleWarpToDock")
AddEventHandler("htb_garage:HandleWarpToDock", function(pos)
	local ped = PlayerPedId()
	SetEntityCoords(
		ped, --[[ Entity ]]
		pos.x, --[[ number ]]
		pos.y, --[[ number ]]
		pos.z, --[[ number ]]
		nil, --[[ boolean (unused) ]]
		false, --[[ boolean ]]
		false, --[[ boolean ]]
		false --[[ boolean ]]
	)

	SetEntityHeading(
		ped, --[[ Entity ]]
		pos.h --[[ number ]]
	)
end)

function StoreVehicle(vehicleType, deleteZone)
	local playerPed = PlayerPedId()
	if IsPedInAnyVehicle(playerPed, false) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		if GetPedInVehicleSeat(vehicle, -1) == playerPed then
			local GotTrailer, TrailerHandle = GetVehicleTrailerVehicle(vehicle)
			if GotTrailer then
				local trailerProps = GetVehicleProperties(TrailerHandle)
				if trailerProps ~= nil then
					-- TODO:
					-- eden_garage:stockv isn't anywere in the Server code. Work out what to do here
					-- -- -- ESX.TriggerServerCallback("eden_garage:stockv", function(valid)
					-- -- -- 	if valid then
					-- -- -- 		--local networkId = NetworkGetNetworkIdFromEntity(TrailerHandle)
					-- -- -- 		DeleteEntity(TrailerHandle)
					-- -- -- 		TriggerServerEvent("htb_garage:SetVehicleStored", trailerProps.plate, 1)

					-- -- -- 		ShowNotification(_U("trailer_in_garage"))
					-- -- -- 	else
					-- -- -- 		ShowNotification(_U("cannot_store_vehicle"))
					-- -- -- 	end
					-- -- -- end, trailerProps, KindOfVehicle, garage_name, vehicle_type)
				else
					FrameworkCtx:ShowNotification(_U("vehicle_error"))
				end
			else
				local networkId = NetworkGetNetworkIdFromEntity(vehicle)
				local vehicleProps = GetVehicleProperties(vehicle)
				if vehicleProps ~= nil then
					TriggerServerEvent(
						"htb_garage:SaveAndStoreVehicle",
						vehicleProps,
						networkId,
						vehicleType,
						deleteZone
					)
				else
					FrameworkCtx:ShowNotification(_U("vehicle_error"))
				end
			end
		else
			FrameworkCtx:ShowNotification(_U("not_driver"))
		end
	else
		FrameworkCtx:ShowNotification(_U("no_vehicle_to_enter"))
	end
end

function DrawMarkers(garages, markerType, vehicleType)
	for k, garage in pairs(garages) do
		for zoneName, zone in pairs(garage) do
			if zoneName ~= "Type" then
				local blip = nil
				if zone.Name ~= nil then
					blip = {
						text = zone.Name,
						colorId = Config.Blips[garage.Type].color,
						imageId = Config.Blips[garage.Type].sprite,
					}
				end

				exports.ft_libs:AddArea(("htb_garage_%s_%s_cars"):format(k, zoneName), {
					marker = {
						weight = zone.Marker.w,
						height = zone.Marker.h,
						red = zone.Marker.r,
						green = zone.Marker.g,
						blue = zone.Marker.b,
						type = markerType,
					},
					trigger = {
						weight = zone.Marker.w,
						active = {
							callback = function()
								exports.ft_libs:HelpPromt(zone.HelpPrompt)
								if IsControlJustReleased(0, 38) and IsInputDisabled(0) and GetLastInputMethod(2) then
									if not IsPedInAnyVehicle(PlayerPedId()) then
										if zoneName == "SpawnPoint" then
											TriggerServerEvent("htb_garage:GetPlayerVehicles", vehicleType, k)
										end
									else
										if zoneName == "DeletePoint" then
											StoreVehicle(vehicleType, zone)
										end
										--if zoneName == "Impound" then OpenImpound(zone, k, "car") end
									end
								end
							end,
						},
						exit = {
							callback = exitmarker,
						},
					},
					blip = blip,
					locations = {
						zone.Pos,
					},
				})
			end
		end
	end
end

RegisterNetEvent("ft_libs:OnClientReady")
AddEventHandler("ft_libs:OnClientReady", function()
	DrawMarkers(Config.Garages, Config.GarageMarkerType, "car")

	if Config.DocksEnabled then
		DrawMarkers(Config.Docks, Config.BoatDockMarkerType, "boat")
	end

	if Config.HangarsEnabled then
		DrawMarkers(Config.Hangars, Config.HangarMarkerType, "plane")
	end
end)

function DoesVehicleExist(plate)
	local doesVehicleExist = false

	plate = trim(plate)
	local instance = vehicleInstances[plate]
	if instance then
		local vehicleEntity = NetworkGetEntityFromNetworkId(instance.networkId)
		if DoesEntityExist(vehicleEntity) then
			doesVehicleExist = true
		else
			TriggerServerEvent("htb_garage:StopTrackingEntity", plate)
			doesVehicleExist = false
		end
	end

	return doesVehicleExist
end

function IsPlayerDrivingVehicle(plate)
	local isVehicleTaken = false
	local players = GetActivePlayers()
	local thisPlayer = PlayerPedId()
	for i = 1, #players, 1 do
		local target = GetPlayerPed(players[i])
		if target ~= thisPlayer then
			local plate1 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, true))
			local plate2 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, false))
			if plate == plate1 or plate == plate2 then
				isVehicleTaken = true
				break
			end
		end
	end
	return isVehicleTaken
end

function GetVehicleProperties(vehicle)
	if DoesEntityExist(vehicle) then
		local vehicleProps = EsxGetVehicleProperties(vehicle)

		vehicleProps["tyres"] = {}
		vehicleProps["windows"] = {}
		vehicleProps["doors"] = {}

		for id = 1, 7 do
			local tyreId = IsVehicleTyreBurst(vehicle, id, false)

			if tyreId then
				vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = tyreId

				if tyreId == false then
					tyreId = IsVehicleTyreBurst(vehicle, id, true)
					vehicleProps["tyres"][#vehicleProps["tyres"]] = tyreId
				end
			else
				vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = false
			end
		end

		for id = 1, 9 do
			local windowId = IsVehicleWindowIntact(vehicle, id)

			if windowId ~= nil then
				vehicleProps["windows"][#vehicleProps["windows"] + 1] = windowId
			else
				vehicleProps["windows"][#vehicleProps["windows"] + 1] = true
			end
		end

		for id = 0, 5 do
			local doorId = IsVehicleDoorDamaged(vehicle, id)

			if doorId then
				vehicleProps["doors"][#vehicleProps["doors"] + 1] = doorId
			else
				vehicleProps["doors"][#vehicleProps["doors"] + 1] = false
			end
		end
		vehicleProps["vehicleHeadLight"] = GetVehicleHeadlightsColour(vehicle)

		return vehicleProps
	else
		return nil
	end
end

function SetVehicleProperties(vehicle, vehicleProps)
	SetBaseVehicleProperties(vehicle, vehicleProps)

	if vehicleProps["windows"] then
		for windowId = 1, 9, 1 do
			if vehicleProps["windows"][windowId] == false then
				SmashVehicleWindow(vehicle, windowId)
			end
		end
	end

	if vehicleProps["tyres"] then
		for tyreId = 1, 7, 1 do
			if vehicleProps["tyres"][tyreId] ~= false then
				SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
			end
		end
	end

	if vehicleProps["doors"] then
		for doorId = 0, 5, 1 do
			if vehicleProps["doors"][doorId] ~= false then
				SetVehicleDoorBroken(vehicle, doorId - 1, true)
			end
		end
	end
	if vehicleProps.vehicleHeadLight then
		SetVehicleHeadlightsColour(vehicle, vehicleProps.vehicleHeadLight)
	end

	if(vehicleProps["lightsState"]) then
		SetLightsHealth(vehicle, vehicleProps.lightsState)
	end
end

---------------------
RegisterNUICallback("close", function(data, cb)
	ToggleGUI(false)

	cb("ok")
end)

function PayForRetrieve(vehicle)
	local playerData = FrameworkCtx:GetPlayerData()
	
	-- TODO: Should move this to a factory generated class
	local accountName = ""
  if Config.RolePlayFramework == "esx" then
		accountName = "money"
	elseif Config.RolePlayFramework == "qbcore" then
			accountName = "cash"
	end    

	for _, account in pairs(playerData.accounts) do
		if account.name == "money" then
			if account.money >= Config.ImpoundPrice then
				-- Pay the fee and notify the player
				TriggerServerEvent("htb_garage:MakePayment", accountName, Config.ImpoundPrice)
				FrameworkCtx:ShowNotification(_U("retrieval_fee_paid"))

				local plate = trim(vehicle.plate)
				local instance = vehicleInstances[plate]
				if instance then
					local vehicleEntity = NetworkGetEntityFromNetworkId(instance.networkId)
					if DoesEntityExist(vehicleEntity) then
						DeleteEntity(vehicleEntity)
						TriggerServerEvent("htb_garage:StopTrackingEntity", plate)
					end
				end
				return true
			else
				FrameworkCtx:ShowNotification(_U("retrieve_not_enough"))
				return false
			end
		end
	end

	Citizen.Trace(
		"function PayForRetrieve: Unable to find account '" .. accountName .. "' for player " .. playerData.identifier .. "\n"
	)
	return false
end

RegisterNUICallback("takeOut", function(data, cb)
	local vehicle = data.vehicle
	local payForRetrieve = data.payForRetrieve

	local getTheVehicle = true
	local overrideStored = false
	if payForRetrieve then
		getTheVehicle = PayForRetrieve(vehicle)
		if getTheVehicle then
			overrideStored = true
		end
	end

	if getTheVehicle then
		if DoesVehicleExist(vehicle.plate) or IsPlayerDrivingVehicle(vehicle.plate) then
			FrameworkCtx:ShowNotification(_U("cannot_take_out"))
		elseif vehicle.pound == 1 then
			FrameworkCtx:ShowNotification(_U("vehicle_in_pound"))
		elseif vehicle.stored == 1 or overrideStored then
			TriggerServerEvent("htb_garage:GetVehicleForSpawn", vehicle.plate, vehicle.garage)
			ToggleGUI(false)
		else
			FrameworkCtx:ShowNotification(_U("vehicle_already_out"))
		end
	end

	cb("ok")
end)

RegisterNUICallback("setGpsMarker", function(data, cb)
	local vehicle = data.vehicle
	local instance = vehicleInstances[trim(vehicle.plate)]
	local vehicleEntity = NetworkGetEntityFromNetworkId(instance.networkId)
	local coords = GetEntityCoords(vehicleEntity)

	SetNewWaypoint(coords.x, coords.y)

	cb("ok")
end)

RegisterNUICallback("setVehicleName", function(data, cb)
	TriggerServerEvent("htb_garage:SetVehicleName", data.plate, data.newName)

	cb("ok")
end)

RegisterNUICallback("transferOwnership", function(data, cb)
	TriggerServerEvent("htb_garage:transferOwnership", data.plate, data.newOwner)

	cb("ok")
end)

RegisterNUICallback("fetchNearbyPlayers", function(data, cb)
	TriggerServerEvent("htb_garage:fetchNearbyPlayers")

	cb("ok")
end)



--------------------------
-- Impound related stuff
--------------------------



RegisterNetEvent("htb_garage:DeleteVehicleAfterImpound")
AddEventHandler("htb_garage:DeleteVehicleAfterImpound", function(vehiclePlate)

end)


RegisterNetEvent("htb_garage:GetPlayerVehiclesResults")
AddEventHandler("htb_garage:GetPlayerVehiclesResults", function(vehicles, garageName)
	local data = {}

	SendNUIMessage({
		type = "initVehicleStats",
		showFuel = Config.DisplayFuel,
		showEngine = Config.DisplayEngine,
		showBody = Config.DisplayBody,
	})

	for a, veh in pairs(vehicles) do
		table.insert(data, {
			garage = garageName,
			spawnName = GetDisplayNameFromVehicleModel(veh.model),
			model = veh.model,
			modelName = GetLabelText(GetDisplayNameFromVehicleModel(veh.model)),
			body = veh.body,
			engine = veh.engine,
			fuel = veh.fuel,
			stored = veh.stored,
			pound = veh.pound,
			displayName = veh.vehiclename,
			plate = veh.plate,
			htmlId = string.gsub(veh.plate, "%s+", ""),
			href = "#" .. string.gsub(veh.plate, "%s+", ""),
			tempNickName = "",
			selectedNewOwner = "",
			transferOwnership = false,
			showSetName = false,
			collapsed = nil,
		})
	end

	SendNUIMessage({
		type = "setVehicles",
		vehicles = json.encode(data),
	})

	ToggleGUI(true, "enableGarage", "/vehicleMenu")
end)

function DetermineSpawnPosition(vehicleType, spawnPoint, heading, numSpawns)
	if vehicleType == "boat" then
		return {
			Pos = {
				x = spawnPoint.SpawnPos.x,
				y = spawnPoint.SpawnPos.y,
				z = spawnPoint.SpawnPos.z,
			},
			Heading = heading,
		}
	end

	local spawnPos = spawnPoint.Pos
	local totalSpawns = numSpawns
	if totalSpawns == nil then
		totalSpawns = Config.MinSpawns
	end

	-- Get unit vector for the garage heading
	-- 0/360 is to the right of entities so need to adjust by rotating 90°
	vectHeading = heading + 90

	local hVect = vector2(Cos(vectHeading), Sin(vectHeading))
	local firstSpawnOffset = 4.0
	local spawnArea = 1.5
	local offset = 0.0
	for currentTry = 0, totalSpawns - 1, 1 do
		offset = 6.0 * currentTry

		local pos = vector2(spawnPos.x, spawnPos.y) - (hVect * firstSpawnOffset) - (hVect * offset)

		if Config.Debug then
			table.insert(debugPostList, { x = pos.x, y = pos.y, z = spawnPos.z - 0.98 })
		end

		if
			not IsPositionOccupied(
				pos.x,
				pos.y,
				spawnPos.z,
				spawnArea,
				false, --[[ boolean Unknown ]]
				true, --[[ boolean Check for any vehicles ]]
				true, --[[ boolean Check for any peds ]]
				false, --[[ Unknown ]]
				false, --[[ Unknown ]]
				0,
				false --[[ Unknown ]]
			)
		then
			return {
				Pos = {
					x = pos.x,
					y = pos.y,
					z = spawnPos.z,
				},
				Heading = heading,
			}
		end
	end

	-- All positions are occupied
	return nil
end

function DoTheSpawn(vehicle, spawnPoint)
	local vehicleProps = json.decode(vehicle)

	SpawnVehicle(
		vehicleProps.model,
		{
			x = spawnPoint.Pos.x,
			y = spawnPoint.Pos.y,
			z = spawnPoint.Pos.z + 1,
		},
		spawnPoint.Heading,
		function(callback_vehicle, networkId)
			if GetResourceState('VehicleDeformation') == 'started' and vehicleProps.deformation ~= nil then
				exports['VehicleDeformation']:SetVehicleDeformation(callback_vehicle, vehicleProps.deformation)
			end
			SetVehicleProperties(callback_vehicle, vehicleProps)			

			if Config.TeleportToVehicleOnSpawn then
				TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
			end

			local carplate = GetVehicleNumberPlateText(callback_vehicle)

			TriggerServerEvent("htb_garage:SetVehicleStored", carplate, 0)
			TriggerServerEvent("htb_garage:StartTrackingEntity", carplate, networkId)
			
			local playerId = PlayerId()
			local playerServerId = GetPlayerServerId(playerId)
			FrameworkCtx:GiveVehicleKeys({ playerServerId = playerServerId, carplate = carplate, lifetime = 'permanent'})
		end,
		true
	)
end

-- Mapping from vehicle type to the associated garage config key
GarageTypeMapping = {
	["car"] = "Garages",
	["boat"] = "Docks",
	["plane"] = "Hangars",
}

RegisterNetEvent("htb_garage:ResultsForVehicleSpawn")
AddEventHandler("htb_garage:ResultsForVehicleSpawn", function(vehicle, garageName)
	local GarageKey = GarageTypeMapping[vehicle.type]
	local garage = Config[GarageKey][garageName]

	local spawnPoint = DetermineSpawnPosition(
		vehicle.type,
		garage.SpawnPoint,
		garage.SpawnPoint.Heading,
		garage.SpawnPoint.NumSpawns
	)
	if spawnPoint == nil then
		FrameworkCtx:ShowNotification(_U("spawn_point_occupied"))
	else
		-- May want to call through to server here depending on how things go with OneSync Infinity and vehicle duplication
		DoTheSpawn(vehicle.vehicle, spawnPoint)
		TriggerEvent('qb-vehiclekeys:client:AddKeys', vehicle.plate)
	end
end)

RegisterNetEvent("htb_garage:VehicleSaveAndStored")
AddEventHandler("htb_garage:VehicleSaveAndStored", function(networkId, plate, vehicleType, deleteZone)
	local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)

	local playerPed = PlayerPedId()
	if vehicleType ~= "boat" and Config.AnimateExitOnStore then
		TaskLeaveVehicle(playerPed, vehicleEntity, 0)
		while IsPedInVehicle(playerPed, vehicleEntity, true) do
			Citizen.Wait(0)
		end

		Citizen.Wait(1000)
	end

	HandleVehicleSpecifics(vehicleEntity, vehicleType, deleteZone)
	DeleteEntity(vehicleEntity)

	TriggerServerEvent("htb_garage:StopTrackingEntity", plate)

	FrameworkCtx:ShowNotification(_U("vehicle_in_garage"))
end)

RegisterNetEvent("htb_garage:nearbyPlayersList")
AddEventHandler("htb_garage:nearbyPlayersList", function(players)
	SendNUIMessage({
		type = "setNearbyPlayersList",
		nearbyPlayers = json.encode(players),
	})
end)

RegisterNetEvent("htb_garage:TransferOwnershipResult")
AddEventHandler("htb_garage:TransferOwnershipResult", function(outcome, amITheSeller, plate, receiverServerId)
	FrameworkCtx:ShowNotification(outcome)

	if amITheSeller then
		TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plate)
		SendNUIMessage({
			type = "transferComplete",
			plate = plate
		})
	end
end)

-------------------------------------------
--- Used only if debugging
--- Displays blue circles in each spawn
--- point  that has been tested for space
---
if Config.Debug then
	Citizen.CreateThread(function()
		while true do
			if #debugPostList > 0 then
				for _, zone in pairs(debugPostList) do
					DrawMarker(
						27,
						zone.x,
						zone.y,
						zone.z, -- x, y, z
						0,
						0,
						0, -- Direction vector x, y, z
						0,
						0,
						0, -- Rotation x, y, z
						5.0,
						5.0,
						5.0, -- Scale
						10,
						10,
						255,
						255, -- Red, Green, Blue, Alph
						false, -- Slowly bob up and down?
						false, -- Constantly face camera?
						2, -- P19. Other values don't seem to do anything
						false, -- Rotate
						nil, -- textureDict [[ string ]]
						nil, -- textureName [[ string ]]
						false -- Draw on intesecting entities?
					)
				end
			end

			Citizen.Wait(0)
		end
	end)
end


-- RegisterNetEvent('htb_garage:FinialiseSpawnVehicle')
-- AddEventHandler('htb_garage:FinialiseSpawnVehicle', function(vehicle, id, model, vector)
--     SetNetworkIdCanMigrate(id, true)
--     SetEntityAsMissionEntity(vehicle, true, false)

--     SetVehicleHasBeenOwnedByPlayer(vehicle, true)
--     SetVehicleNeedsToBeHotwired(vehicle, false)
--     SetModelAsNoLongerNeeded(model)
--     SetVehRadioStation(vehicle, 'OFF')

--     RequestCollisionAtCoord(vector.xyz)
--     while not HasCollisionLoadedAroundEntity(vehicle) do
--         Citizen.Wait(0)
--     end

-- end)

-- RegisterCommand('aaaaa', function(source, args, raw)
--     print(json.encode(vehicleInstances))
-- end, false)


local lightBones = {
	headlight_l      = "headlight_l",
	headlight_r      = "headlight_r",
	taillight_l      = "taillight_l",
	taillight_r      = "taillight_r",
	indicator_lf     = "indicator_lf",
	indicator_rf     = "indicator_rf",
	indicator_lr     = "indicator_lr",
	indicator_rr     = "indicator_rr",
	brakelight_l     = "brakelight_l",
	brakelight_r     = "brakelight_r",
	reversinglight_l = "reversinglight_l",
	reversinglight_r = "reversinglight_r",
  }
  
  -- Returns a table of booleans keyed by the bone‑name keys above
  function GetLightsHealth(vehicle)
	local out = {}
	for key, boneName in pairs(lightBones) do
	  local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
	  if boneIndex ~= -1 then
		-- world pos of the lamp bone
		local wx, wy, wz = GetWorldPositionOfEntityBone(vehicle, boneIndex)
		-- convert it into local vehicle offsets
		local ox, oy, oz = GetOffsetFromEntityGivenWorldCoords(vehicle, wx, wy, wz)
		-- sample mesh deformation at that offset
		local dx, dy, dz = GetVehicleDeformationAtPos(vehicle, ox, oy, oz)  -- :contentReference[oaicite:0]{index=0}
		out[key] = (dx ~= 0 or dy ~= 0 or dz ~= 0)
	  else
		out[key] = false
	  end
	end
	
	return out
  end
  
  -- Re‑break exactly those lights by inflicting a tiny damage sphere
  function SetLightsHealth(vehicle, lightsState)
	-- allow lenses to shatter
	SetVehicleHasUnbreakableLights(vehicle, false)
	for key, shouldBeBroken in pairs(lightsState) do
	  if shouldBeBroken then
		local boneName = lightBones[key]
		local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
		if boneIndex ~= -1 then
		  local wx, wy, wz = GetWorldPositionOfEntityBone(vehicle, boneIndex)
		  local ox, oy, oz = GetOffsetFromEntityGivenWorldCoords(vehicle, wx, wy, wz)
		  -- a small radius (0.1) focuses damage on that lamp; strength 10 is plenty to shatter
		  SetVehicleDamage(vehicle, ox, oy, oz, 0.1, 10.0, true)  -- :contentReference[oaicite:1]{index=1}
		end
	  end
	end
  end
