-- Zones: the garage, dock, hangar and impound points (blip, ground marker, prompt
-- and key press). Replaces ft_libs' AddArea; the defaults look and behave the
-- same as ft_libs did. How they're shown is set in Config.Zones.
--
--   Zones.Add(id, {
--       kind     = "car" | "boat" | "plane" | "impound",  -- picks per-kind settings
--       coords   = vector3 or { x, y, z },
--       radius   = 1.5,             -- how close counts as "on" the point
--       marker   = { type, size, height, r, g, b, a },    -- nil for no marker
--       blip     = { text, sprite, color, scale },       -- nil for no blip
--       label    = "Name above the point" (optional, shown when Config.Zones.ShowLabels),
--       prompt   = "Press ~INPUT_PICKUP~ to ...",
--       onPress  = function(zone) end,  -- the player pressed the key while on it
--       onEnter  = function(zone) end,  -- optional
--       onExit   = function(zone) end,  -- optional
--   })
--   Zones.Remove(id)
--   Zones.SetEnabled(id, enabled)

Zones = {}

local DEFAULTS = {
	Display = "marker",
	Prompt = "help",
	ShowLabels = false,
	ShowBlips = true,
	DrawDistance = 20.0,
	TriggerHeight = 2.0,
	MarkerZOffset = -1.0,
	MarkerAlpha = 255,
	BobUpAndDown = false,
	RotateMarker = false,
	FaceCamera = false,
	Key = 38,
}

local settings = setmetatable(Config.Zones or {}, { __index = DEFAULTS })

-- A setting can be one value for everything, or a table per kind:
--   Display = { car = "marker", impound = "none", default = "marker" }
local function setting(name, kind)
	local value = settings[name]
	if type(value) == "table" then
		local picked = value[kind]
		if picked == nil then
			picked = value.default
		end
		if picked == nil then
			picked = DEFAULTS[name]
		end
		return picked
	end
	return value
end

local zones = {} -- id -> zone
local nearby = {} -- zones within draw distance, refreshed twice a second
local promptZone = nil -- zone whose prompt is showing (for prompts that stay up)

local function toVector3(coords)
	if type(coords) == "vector3" or type(coords) == "vector4" then
		return vector3(coords.x, coords.y, coords.z)
	end
	return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

----------------------------------------------------------------------------------------------------
-- Drawing

local function drawMarker(zone)
	local m = zone.marker
	DrawMarker(
		m.type,
		zone.coords.x,
		zone.coords.y,
		zone.coords.z + settings.MarkerZOffset,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		m.size * 2.0,
		m.size * 2.0,
		m.height,
		m.r,
		m.g,
		m.b,
		m.a,
		settings.BobUpAndDown,
		settings.FaceCamera,
		2,
		settings.RotateMarker,
		nil,
		nil,
		false
	)
end

local function draw3DText(coords, text)
	SetDrawOrigin(coords.x, coords.y, coords.z, 0)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(true)
	SetTextColour(255, 255, 255, 215)
	SetTextOutline()
	SetTextCentre(true)
	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end

-- "~INPUT_PICKUP~" only works in GTA's help box; elsewhere show the key's name.
local function plainPrompt(text)
	local key = GetControlInstructionalButton(0, settings.Key, true) or ""
	key = key:gsub("^t_", "")
	if key == "" or key:find("^b_") then
		key = "E"
	end
	return (text:gsub("~INPUT_[%w_]+~", "[" .. key .. "]"):gsub("~[^~]*~", ""))
end

local function oxLibRunning()
	return GetResourceState("ox_lib") == "started"
end

local function promptStyle(zone)
	local style = setting("Prompt", zone.kind)
	if style == "ox_lib" and not oxLibRunning() then
		return "help"
	end
	return style
end

local function hidePrompt()
	if promptZone and promptZone.shownStyle == "ox_lib" then
		exports.ox_lib:hideTextUI()
	end
	promptZone = nil
end

-- Called every frame for the zone the player is standing on.
local function showPrompt(zone)
	if not zone.prompt then
		return
	end
	local style = promptStyle(zone)

	if promptZone ~= zone or zone.shownStyle ~= style then
		hidePrompt()
		promptZone = zone
		zone.shownStyle = style
		if style == "ox_lib" then
			exports.ox_lib:showTextUI(plainPrompt(zone.prompt))
		end
	end

	if style == "help" then
		BeginTextCommandDisplayHelp("STRING")
		AddTextComponentSubstringPlayerName(zone.prompt)
		EndTextCommandDisplayHelp(0, false, false, -1)
	elseif style == "text3d" then
		draw3DText(zone.coords + vector3(0.0, 0.0, 0.3), plainPrompt(zone.prompt))
	end
end

-- /garagezones toggles a trace of what happens on a point, printed in the F8 console
local trace = false
local function log(...)
	if trace then
		print("[htb_garage zones]", ...)
	end
end
RegisterCommand("garagezones", function()
	trace = not trace
	print("[htb_garage zones] trace " .. (trace and "on" or "off"))
end, false)
Zones.Log = log

local function keyPressed()
	-- Also accept the key when another resource has disabled the control this frame.
	local released = IsControlJustReleased(0, settings.Key) or IsDisabledControlJustReleased(0, settings.Key)
	if not released then
		return false
	end
	-- keyboard only, as before (stops controller players opening menus by accident)
	local keyboard = IsUsingKeyboard(0)
	log("key released, keyboard:", keyboard)
	return keyboard
end

----------------------------------------------------------------------------------------------------
-- Enter / exit

local function setInside(zone, inside)
	if zone.inside == inside then
		return
	end
	zone.inside = inside
	log(inside and "entered" or "left", zone.id)
	if inside then
		if zone.onEnter then
			zone.onEnter(zone)
		end
	else
		if promptZone == zone then
			hidePrompt()
		end
		if zone.onExit then
			zone.onExit(zone)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Blips

local function createBlip(zone)
	local b = zone.blip
	if not b or not settings.ShowBlips or zone.blipHandle then
		return
	end
	local handle = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
	SetBlipSprite(handle, b.sprite or 1)
	SetBlipColour(handle, b.color or 0)
	SetBlipScale(handle, b.scale or 1.0)
	SetBlipAsShortRange(handle, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(b.text or "")
	EndTextCommandSetBlipName(handle)
	zone.blipHandle = handle
end

local function removeBlip(zone)
	if zone.blipHandle then
		RemoveBlip(zone.blipHandle)
		zone.blipHandle = nil
	end
end

----------------------------------------------------------------------------------------------------
-- API

function Zones.Add(id, def)
	if zones[id] then
		Zones.Remove(id)
	end

	local kind = def.kind or "default"
	local zone = {
		id = id,
		kind = kind,
		coords = toVector3(def.coords),
		radius = (def.radius or 1.5) + 0.0,
		height = (def.height or settings.TriggerHeight) + 0.0,
		blip = def.blip,
		label = def.label,
		prompt = def.prompt,
		onPress = def.onPress,
		onEnter = def.onEnter,
		onExit = def.onExit,
		enabled = def.enabled ~= false,
		inside = false,
	}

	if def.marker and setting("Display", kind) == "marker" then
		local m = def.marker
		zone.marker = {
			type = m.type or 1,
			size = (m.size or zone.radius) + 0.0,
			height = (m.height or 1.0) + 0.0,
			r = m.r or 255,
			g = m.g or 255,
			b = m.b or 255,
			a = m.a or settings.MarkerAlpha,
		}
	end

	zone.drawDistance = zone.radius + settings.DrawDistance
	zones[id] = zone
	if zone.enabled then
		createBlip(zone)
	end
	return zone
end

function Zones.Remove(id)
	local zone = zones[id]
	if not zone then
		return
	end
	setInside(zone, false)
	removeBlip(zone)
	zone.enabled = false
	zones[id] = nil
end

function Zones.SetEnabled(id, enabled)
	local zone = zones[id]
	if not zone then
		return
	end
	zone.enabled = enabled
	if enabled then
		createBlip(zone)
	else
		setInside(zone, false)
		removeBlip(zone)
	end
end

function Zones.Get(id)
	return zones[id]
end

----------------------------------------------------------------------------------------------------
-- Threads

-- Which zones are close enough to draw (cheap, twice a second).
CreateThread(function()
	while true do
		local pos = GetEntityCoords(PlayerPedId())
		local found = {}
		for _, zone in pairs(zones) do
			if zone.enabled and #(pos - zone.coords) <= zone.drawDistance then
				found[#found + 1] = zone
			elseif zone.inside then
				setInside(zone, false)
			end
		end
		nearby = found
		Wait(500)
	end
end)

-- Draw the nearby zones and handle the one the player is standing on (every frame, only when near one).
CreateThread(function()
	while true do
		if #nearby == 0 then
			Wait(500)
		else
			local pos = GetEntityCoords(PlayerPedId())
			local current, currentDistance = nil, nil

			for _, zone in ipairs(nearby) do
				if zone.enabled then
					if zone.marker then
						drawMarker(zone)
					end
					if zone.label and setting("ShowLabels", zone.kind) then
						draw3DText(zone.coords + vector3(0.0, 0.0, 1.0), zone.label)
					end

					local distance = #(pos - zone.coords)
					local inside = distance < zone.radius and math.abs(pos.z - zone.coords.z) <= zone.height
					setInside(zone, inside)
					if inside and (not current or distance < currentDistance) then
						current, currentDistance = zone, distance
					end
				end
			end

			if current then
				if promptStyle(current) ~= "none" then
					showPrompt(current)
				end
				if current.onPress and keyPressed() then
					log("onPress", current.id, "at", GetEntityCoords(PlayerPedId()))
					-- an error in an action must not stop the zones from drawing
					local ok, err = pcall(current.onPress, current)
					if not ok then
						print(("^1[htb_garage] error handling %s: %s^7"):format(current.id, tostring(err)))
					end
				end
			elseif promptZone then
				hidePrompt()
			end

			Wait(0)
		end
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	hidePrompt()
	for _, zone in pairs(zones) do
		removeBlip(zone)
	end
end)
