Config = {}
Config.Debug = false
Config.ShowSpawnPointMarkersDebug = false

Config.MinSpawns = 2
Config.Blips = {
	car = { sprite = 524, color = 30 },
	boat = { sprite = 410, color = 30 },
	plane = { sprite = 423, color = 188 },
	impound = { sprite = 317, color = 33 }, -- TODO Find a blip for here
}

-- Marker shapes (https://docs.fivem.net/docs/game-references/markers/). Sizes and colours are
-- per point in Configs/*.lua: Marker = { w = 1.5, h = 1.0, r = 0, g = 255, b = 0 }, where you
-- can also add a = (transparency 0-255) and type = (shape) to override these for one point.
Config.GarageMarkerType = 1 --27
Config.BoatDockMarkerType = 1
Config.HangarMarkerType = 1
Config.ImpoundMarkerType = 1

-- How garage, dock, hangar and impound points are shown. The defaults are the classic look.
-- Any setting can be one value for everything, or set per kind of point, for example:
--      Display = { car = "marker", boat = "marker", plane = "marker", impound = "none" }
--      Prompt  = { default = "help", impound = "text3d" }
Config.Zones = {
	-- What is drawn on the ground:
	--      marker      a coloured marker (the shapes above)
	--      none        nothing; standing on the spot still shows the prompt
	Display = "marker",

	-- How "Press E to ..." is shown while standing on a point:
	--      help        GTA's help box, top left
	--      text3d      floating text above the point
	--      ox_lib      ox_lib's text UI (uses help if ox_lib isn't running)
	--      none        no prompt (the key still works)
	Prompt = "help",

	ShowLabels = false, -- Float the garage / impound name above its point
	ShowBlips = true, -- Map blips (sprites and colours are in Config.Blips)
	DrawDistance = 20.0, -- Markers are drawn within this many metres (plus the marker's size)
	MarkerAlpha = 255, -- Marker transparency, 0 (invisible) to 255 (solid)
	BobUpAndDown = false,
	RotateMarker = false,
	FaceCamera = false,

	-- Control pressed on a point (38 = E). If you change it, change ~INPUT_PICKUP~ in the
	-- locale prompts to match (https://docs.fivem.net/docs/game-references/controls/).
	Key = 38,
}

Config.DocksEnabled = true
Config.HangarsEnabled = false

Config.RetrieveVehiclePrice = 2500 -- pound price to get vehicle back TOO: Remove this
Config.Locale = "en"

Config.TeleportToVehicleOnSpawn = true
Config.AnimateExitOnStore = true

-- Show or hide vehicle stats in garage menu
Config.DisplayFuel = true
Config.DisplayEngine = true
Config.DisplayBody = true

-- Impound
Config.ImpoundEnabled = true

Config.AllowedImpoundJobs = {
	police = true,
	mechanic = true,
}

Config.ImpoundTimePeriods =
	{ 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48 }

Config.ImpoundDefaultRetrievePrice = 1000

-- when false: 1 hour = 3,600 real seconds
-- when  true: 1 in-game hour = 2 real minutes = 120 real seconds
Config.UseInGameClock = true
Config.InGameHourSeconds = 2 * 60

-- Set the identifier type as a string here, for example:
--		steam
--		ip
--		discord
--		license (Rockstar License)
--		license2 (Stray Rockstar License which I've seen appear, not sure why but allowing it here if it means anything to anyone)
--		xbl
--		live
Config.PlayerIdentifierType = "license" -- Very easy to switch your identifier type for your platform

-- By default ESX only uses the value of the identifer (after the : symbol) in the users table.
-- FiveM required
Config.ExcludeIdentifierPrefix = false

Config.MaxPlayersInTransferList = 5

-- Server side protection against modified clients. Requires OneSync (on by default
-- with txAdmin and required by ESX Legacy) so the server can check real positions/entities.
Config.Security = {
	DefaultCooldownMs = 250, -- Minimum time between calls to the same event by one player
	KickOnSuspicious = false, -- Kick players whose requests could only come from a modified client
	KickMessage = "Kicked by htb_garage: suspicious activity",

	InteractionDistance = 10.0, -- Max distance from a garage / impound marker when using it
	VehicleDistance = 10.0, -- Max distance from a vehicle being impounded
	TransferDistance = 15.0, -- Max distance between buyer and seller when transferring
	NearbyPlayersRadius = 15.0, -- Radius used to list buyers for a transfer

	MaxImpoundPrice = 1000000,
	MaxImpoundReasonLength = 300,
	MaxVehicleNameLength = 50,
	MaxVehiclePropsBytes = 65536, -- Size limit for a vehicle's saved properties
	SpawnTicketSeconds = 60, -- How long a client has to report a vehicle it was allowed to spawn
}

-- The RP framework:
--      esx             ESX Legacy
--      qbcore          QBCore
--      auto            whichever of the above is running
-- To support another framework, add files to Bridge/framework/client, Bridge/framework/server
-- and Bridge/queries (copy the esx ones). Bridge/registry.lua lists what each must provide.
Config.RolePlayFramework = "esx"

-- Who shows notifications:
--      framework       ESX's or QBCore's own (the game's feed when running without one)
--      ox_lib          ox_lib notifications
--      gta             the game's notification feed above the minimap
-- To use something else, add a file to Bridge/notify (copy one of the existing ones).
Config.Notify = "framework"

-- Which resource handles vehicle keys:
--      auto            whichever of the supported ones below is running, otherwise none
--      vehicles_keys   jaksam's vehicles_keys
--      qb-vehiclekeys  QBCore's qb-vehiclekeys
--      none            no keys needed
-- To use something else, add a file to Bridge/keys (copy one of the existing ones).
Config.VehicleKeys = "auto"
