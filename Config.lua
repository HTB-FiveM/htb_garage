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

Config.GarageMarkerType = 1 --27
Config.BoatDockMarkerType = 1
Config.HangarMarkerType = 1

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

-- Set the RP framework, supported values are:
--      none
--      esx
--      qbcore
--      custom
Config.RolePlayFramework = "esx"

Config.UsingEsxLegacy = true
