RegisterNetEvent("htb_garage:ShowClientNotification")
AddEventHandler("htb_garage:ShowClientNotification", function(message)
	FrameworkCtx:ShowNotification(message)
end)

--- Returns a table with the future game time after adding n hours.
-- @param n number of hours to add (can be fractional)
-- @return { hours=int, minutes=int, seconds=int, dayOverflow=int }
function GetGameTimePlus(hours)
	-- fetch current in‑game time
	local h = GetClockHours()
	local m = GetClockMinutes()
	local s = GetClockSeconds()

	-- total seconds since midnight
	local currentSec = h * 3600 + m * 60 + s
	local addSec = math.floor(hours * 3600)
	local totalSec = currentSec + addSec

	-- compute overflow days and wrap‑around seconds
	local dayOverflow = math.floor(totalSec / (24 * 3600))
	local wrapSec = totalSec % (24 * 3600)

	-- convert back to h:m:s
	local newH = math.floor(wrapSec / 3600)
	local newM = math.floor((wrapSec % 3600) / 60)
	local newS = wrapSec % 60

	return {
		hours = newH,
		minutes = newM,
		seconds = newS,
		dayOverflow = dayOverflow, -- how many days you rolled past
	}
end

--- Find the first vehicle whose plate matches `plateText`
--- @param plateText string
--- @return number|nil vehicleEntity
function GetVehicleByPlate(plateText)
	-- get all vehicles currently streamed in for this client
	for _, veh in ipairs(GetGamePool("CVehicle")) do
		if DoesEntityExist(veh) then
			-- strip spaces/case if you like
			if GetVehicleNumberPlateText(veh) == plateText then
				return veh
			end
		end
	end
	return nil
end

Citizen.CreateThread(function()
	if not Config.ShowSpawnPointMarkersDebug then
		return
	end
	while true do
		Citizen.Wait(0) -- draw every frame
		for _, pt in ipairs(Config.Impounds.PaletoBay.SpawnPoints) do
			-- markerType = 1 is the classic vertical cylinder
			-- offset Z slightly down so it sits on the ground
			DrawMarker(
				1, -- markerType
				pt.Point.x,
				pt.Point.y,
				pt.Point.z - 1.0, -- position
				0.0,
				0.0,
				0.0, -- dir
				0.0,
				0.0,
				0.0, -- rot
				3.0,
				3.0,
				5.0, -- scale (x,y,z)
				0,
				255,
				0,
				100, -- color (r,g,b,alpha)
				false,
				true,
				2, -- bobUpAndDown, faceCamera, p19
				false,
				nil,
				nil,
				false -- unk flags
			)
			DrawFloatingText(pt.Point.x, pt.Point.y, pt.Point.z + 1.5, pt.Name)
		end
	end
end)

local function IsVehicleInRange(x, y, z, radius)
	-- set up a vertical capsule around the point
	local startZ = z + radius
	local endZ = z - radius

	-- 4 = VEHICLES only; 0 = ignore no entities; 7 = default collider mask
	local handle = StartShapeTestCapsule(
		x,
		y,
		startZ,
		x,
		y,
		endZ,
		radius,
		eTraceFlags.IntersectVehicles | eTraceFlags.IntersectPeds,
		0, -- ignoreEntity
		7 -- p9: collider types mask
	)

	-- poll until the test is no longer 'pending'
	local status, hit, endCoords, surfaceNormal, entityHit
	repeat
		status, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)
		Citizen.Wait(0)
	until status ~= 1

	-- when status == 2, hit is valid
	if status == 2 and hit and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then
		return true
	end
	return false
end

--- Attempts to find an unoccupied impound retrieval spawn location.
-- @param spawnPoints table  Array of vector4 spawn locations ({ x, y, z, w })
-- @return table|nil         `{ Pos = { x, y, z }, Heading = number }` or `nil` if all are occupied
function DetermineImpoundRetrieveSpawnLocation(spawnPoints)
	local candidates = {}
	for i, v in ipairs(spawnPoints) do
		candidates[i] = v
	end

	local spawnArea = 1.5

	while #candidates > 0 do
		local idx = math.random(#candidates)
		local spawn = table.remove(candidates, idx)
		local x, y, z, w = spawn.Point.x, spawn.Point.y, spawn.Point.z, spawn.Point.w

		local occupied = IsVehicleInRange(x, y, z, spawnArea)
		if not occupied then
			return {
				Pos = { x = x, y = y, z = z },
				Heading = w,
			}
		end
	end

	return nil
end

function DrawFloatingText(x, y, z, text)
	SetTextScale(0.8, 0.8)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextDropshadow(1, 1, 1, 1, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	SetDrawOrigin(x, y, z, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

RegisterCommand("coords_htb", function()
	local ped = PlayerPedId()
	-- Get current position
	local x, y, z = table.unpack(GetEntityCoords(ped))
	-- Get current heading
	local heading = GetEntityHeading(ped)

	-- Format as vector3
	local posVec = vector3(x, y, z)

	-- Print to the client console
	print(("[coords] %s, heading: %.2f"):format(posVec, heading))

	-- Optional: show in chat as well
	TriggerEvent("chat:addMessage", {
		color = { 255, 240, 0 },
		args = { "Coords", ("%s | heading: %.2f"):format(posVec, heading) },
	})
end, false)

-- Optional: bind to a key (e.g. F5)
RegisterKeyMapping("coords_htb", "Dump current coords & heading", "keyboard", "F5")
