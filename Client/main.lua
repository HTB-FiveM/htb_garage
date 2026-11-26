if Config.Debug then
	debugPostList = {}
end
local isVisible = false
local vehicleInstances = {}

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
		isVisible = isVisible,
	}
	-- print(json.encode(messageData))
	SendNUIMessage(messageData)
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

	SetEntityHeading(ped, --[[ Entity ]] (pos.w or pos.h or 0.0) --[[ number: vector4 heading, or h in older configs ]])
end)

-- garageName is the config key of the garage; the server looks up the zone itself
function StoreVehicle(vehicleType, garageName)
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
					Notify.send(_U("vehicle_error"))
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
						garageName
					)
				else
					Notify.send(_U("vehicle_error"))
				end
			end
		else
			Notify.send(_U("not_driver"))
		end
	else
		Notify.send(_U("no_vehicle_to_enter"))
	end
end

-- Marker settings from Configs/*.lua ({ w, h, r, g, b, a?, type? }) in Zones form
local function zoneMarker(marker, markerType)
	return {
		type = marker.type or markerType,
		size = marker.w,
		height = marker.h,
		r = marker.r,
		g = marker.g,
		b = marker.b,
		a = marker.a,
	}
end

-- Which vehicles the player owns, asked of the server per plate and remembered briefly
-- (ownership can change through transfers): [plate] = { owned, type, at, pending }
local ownership = {}
local OWNERSHIP_TTL_MS = 30000
local OWNERSHIP_TIMEOUT_MS = 5000

RegisterNetEvent("htb_garage:VehicleOwnershipResult")
AddEventHandler("htb_garage:VehicleOwnershipResult", function(plate, owned, vehicleType)
	ownership[plate] = { owned = owned == true, type = vehicleType, at = GetGameTimer() }
	Zones.Log("ownership of", plate, owned, vehicleType)
end)

-- Forget what we knew when ownership may have changed (e.g. after a transfer)
function ForgetVehicleOwnership()
	ownership = {}
end

-- True when the player is in a vehicle they own, of this kind (car, boat or plane)
local function inOwnVehicle(vehicleType)
	local ped = PlayerPedId()
	if not IsPedInAnyVehicle(ped, false) then
		return false
	end
	local plate = trim(GetVehicleNumberPlateText(GetVehiclePedIsIn(ped, false)))
	local now = GetGameTimer()
	local known = ownership[plate]

	local stale = not known or (known.pending and now - known.at > OWNERSHIP_TIMEOUT_MS)
		or (not known.pending and now - known.at > OWNERSHIP_TTL_MS)
	if stale then
		ownership[plate] = { pending = true, at = now, owned = known and known.owned, type = known and known.type }
		TriggerServerEvent("htb_garage:CheckVehicleOwnership", plate)
		known = ownership[plate]
	end

	return known.owned == true and known.type == vehicleType
end

function DrawImpoundMarkers(impounds, markerType)
	for impoundName, details in pairs(impounds) do
		local zone = details.RetrievePoint
		Zones.Add(("htb_garage_impound_%s"):format(impoundName), {
			kind = "impound",
			coords = zone.Pos,
			radius = zone.Marker.w,
			marker = zoneMarker(zone.Marker, markerType),
			blip = {
				text = zone.Name,
				sprite = Config.Blips.impound.sprite,
				color = Config.Blips.impound.color,
			},
			label = zone.Name,
			prompt = zone.HelpPrompt,
			onPress = function()
				if not IsPedInAnyVehicle(PlayerPedId(), true) then
					FetchImpoundedPlayerVehicles(impoundName)
				end
			end,
		})
	end
end

-- The points a player walks or drives onto. (A hangar's SpawnPoint is only where the
-- aircraft appears, so it gets no marker.)
local GARAGE_ZONES = { "GarageMenuLocation", "DeletePoint" }

function DrawMarkers(garages, markerType, vehicleType)
	for k, garage in pairs(garages) do
		for _, zoneName in ipairs(GARAGE_ZONES) do
			local zone = garage[zoneName]
			if zone then
				local blip = nil
				if zone.Name ~= nil then
					blip = {
						text = zone.Name,
						sprite = Config.Blips[garage.Type].sprite,
						color = Config.Blips[garage.Type].color,
					}
				end

				Zones.Add(("htb_garage_%s_%s_cars"):format(k, zoneName), {
					kind = vehicleType,
					coords = zone.Pos,
					radius = zone.Marker.w,
					marker = zoneMarker(zone.Marker, markerType),
					blip = blip,
					label = zone.Name,
					prompt = zone.HelpPrompt,
					-- Store points only show while in a vehicle the player owns
					canShow = zoneName == "DeletePoint" and function()
						return inOwnVehicle(vehicleType)
					end or nil,
					onPress = function()
						if not IsPedInAnyVehicle(PlayerPedId(), true) then
							if zoneName == "GarageMenuLocation" then
								TriggerServerEvent("htb_garage:GetPlayerVehicles", vehicleType, k)
							end
						elseif zoneName == "DeletePoint" then
							StoreVehicle(vehicleType, k)
						end
					end,
				})
			end
		end
	end
end

-- Create the zones once the player is in the session (also straight away after a resource restart)
CreateThread(function()
	while not NetworkIsSessionStarted() do
		Wait(100)
	end

	DrawMarkers(Config.Garages, Config.GarageMarkerType, "car")

	if Config.DocksEnabled then
		DrawMarkers(Config.Docks, Config.BoatDockMarkerType, "boat")
	end

	if Config.HangarsEnabled then
		DrawMarkers(Config.Hangars, Config.HangarMarkerType, "plane")
	end

	if Config.ImpoundEnabled then
		DrawImpoundMarkers(Config.Impounds, Config.ImpoundMarkerType)
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
		-- Saved as a 1-based list: slot 1 = door 0 (driver) ... slot 6 = door 5
		for doorId = 0, 5, 1 do
			if vehicleProps["doors"][doorId + 1] == true then
				SetVehicleDoorBroken(vehicle, doorId, true)
			end
		end
	end
	if vehicleProps.vehicleHeadLight then
		SetVehicleHeadlightsColour(vehicle, vehicleProps.vehicleHeadLight)
	end

	if vehicleProps["lightsState"] then
		SetLightsHealth(vehicle, vehicleProps.lightsState)
	end
end

---------------------
RegisterNUICallback("close", function(data, cb)
	ToggleGUI(false)

	cb("ok")
end)

RegisterNUICallback("takeOut", function(data, cb)
	local vehicle = data.vehicle
	local payForRetrieve = data.payForRetrieve

	-- These checks are for player feedback only; the server re-checks the
	-- stored/impound state and charges any retrieval fee itself.
	if payForRetrieve then
		TriggerServerEvent("htb_garage:GetVehicleForSpawn", vehicle.plate, vehicle.garage, true)
		ToggleGUI(false)
	elseif DoesVehicleExist(vehicle.plate) or IsPlayerDrivingVehicle(vehicle.plate) then
		Notify.send(_U("cannot_take_out"))
	elseif vehicle.pound == 1 or vehicle.pound == true then
		Notify.send(_U("vehicle_in_pound"))
	elseif vehicle.stored == 1 or vehicle.stored == true then -- TINYINT(1) columns arrive as booleans
		TriggerServerEvent("htb_garage:GetVehicleForSpawn", vehicle.plate, vehicle.garage, false)
		ToggleGUI(false)
	else
		Notify.send(_U("vehicle_already_out"))
	end

	cb("ok")
end)

RegisterNUICallback("setGpsMarker", function(data, cb)
	local vehicle = data.vehicle
	local instance = vehicleInstances[trim(vehicle.plate)]
	local vehicleEntity = instance and NetworkGetEntityFromNetworkId(instance.networkId) or 0

	-- Not tracked, or too far away for this client to see it
	if vehicleEntity == 0 or not DoesEntityExist(vehicleEntity) then
		Notify.send(_U("someone_driving"))
		cb("ok")
		return
	end

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
AddEventHandler("htb_garage:DeleteVehicleAfterImpound", function(vehiclePlate) end)

RegisterNetEvent("htb_garage:GetPlayerVehiclesResults")
AddEventHandler("htb_garage:GetPlayerVehiclesResults", function(vehicles, garageName)
	Zones.Log("server sent", #vehicles, "vehicles for", garageName)
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

-- A fixed spot away from the menu (hangars). nil when something is in the way.
local function fixedSpawnPosition(spawnPoint)
	local pos = spawnPoint.Pos
	local clearance = (spawnPoint.Clearance or 10.0) + 0.0
	if IsPositionOccupied(pos.x, pos.y, pos.z, clearance, false, true, true, false, false, 0, false) then
		return nil
	end
	return {
		Pos = { x = pos.x, y = pos.y, z = pos.z },
		Heading = spawnPoint.Heading or 0.0,
	}
end

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

function DoTheSpawn(vehicle, spawnPoint, teleportPlayerToVehicle)
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
			if GetResourceState("VehicleDeformation") == "started" and vehicleProps.deformation ~= nil then
				exports["VehicleDeformation"]:SetVehicleDeformation(callback_vehicle, vehicleProps.deformation)
			end
			SetVehicleProperties(callback_vehicle, vehicleProps)

			if teleportPlayerToVehicle then
				TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
			end

			local carplate = GetVehicleNumberPlateText(callback_vehicle)

			-- The server already marked the vehicle as out; this registers the entity
			-- against the spawn ticket the server issued for it. The server hands out the
			-- keys once it has confirmed the spawn.
			TriggerServerEvent("htb_garage:StartTrackingEntity", carplate, networkId)
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
	-- Any copy left out in the world has already been removed by the server
	local GarageKey = GarageTypeMapping[vehicle.type]
	local garage = Config[GarageKey][garageName]

	local spawnPoint
	if garage.SpawnPoint then
		-- Hangars: the aircraft appears at its own spot, not next to the menu
		spawnPoint = fixedSpawnPosition(garage.SpawnPoint)
	else
		local menu = garage.GarageMenuLocation
		spawnPoint = DetermineSpawnPosition(vehicle.type, menu, menu.Heading, menu.NumSpawns)
	end
	if spawnPoint == nil then
		Notify.send(_U("spawn_point_occupied"))
		-- Let the server put the vehicle back in the garage
		TriggerServerEvent("htb_garage:SpawnCancelled", vehicle.plate)
	else
		-- May want to call through to server here depending on how things go with OneSync Infinity and vehicle duplication
		DoTheSpawn(vehicle.vehicle, spawnPoint, Config.TeleportToVehicleOnSpawn)
	end
end)

RegisterNetEvent("htb_garage:VehicleSaveAndStored")
-- The server has saved the vehicle. It removes the vehicle itself (and moves boat
-- passengers onto the dock) once the driver has climbed out.
AddEventHandler("htb_garage:VehicleSaveAndStored", function(networkId, vehicleType)
	local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)

	if vehicleType ~= "boat" and Config.AnimateExitOnStore and DoesEntityExist(vehicleEntity) then
		TaskLeaveVehicle(PlayerPedId(), vehicleEntity, 0)
	end

	Notify.send(_U("vehicle_in_garage"))
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
	Notify.send(outcome)
	ForgetVehicleOwnership()

	-- The seller's keys are removed by the server
	if amITheSeller then
		SendNUIMessage({
			type = "transferComplete",
			plate = plate,
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
	headlight_l = "headlight_l",
	headlight_r = "headlight_r",
	taillight_l = "taillight_l",
	taillight_r = "taillight_r",
	indicator_lf = "indicator_lf",
	indicator_rf = "indicator_rf",
	indicator_lr = "indicator_lr",
	indicator_rr = "indicator_rr",
	brakelight_l = "brakelight_l",
	brakelight_r = "brakelight_r",
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
			local dx, dy, dz = GetVehicleDeformationAtPos(vehicle, ox, oy, oz) -- :contentReference[oaicite:0]{index=0}
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
				SetVehicleDamage(vehicle, ox, oy, oz, 0.1, 10.0, true) -- :contentReference[oaicite:1]{index=1}
			end
		end
	end
end

RegisterNetEvent("timeSync:updateTime")
AddEventHandler("timeSync:updateTime", function(hour, minute, second)
	-- freeze = false means time will continue advancing from this point
	NetworkOverrideClockTime(hour, minute, second)
	-- if you want to *freeze* the world at exactly that time, uncomment:
	-- PauseClock(true)
end)
