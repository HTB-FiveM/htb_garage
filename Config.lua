Config = {}
Config.Debug = false

Config.MinSpawns = 2
Config.Blips = {
    car = { sprite = 524, color = 30 },
    boat = { sprite = 410, color = 30 },
    plane = { sprite = 524, color = 188 }
}

Config.GarageMarkerType = 1 --27
Config.BoatDockMarkerType = 1
Config.HangarMarkerType = 1

Config.DocksEnabled = true
Config.HangarsEnabled = false

Config.ImpoundPrice	= 2500 -- pound price to get vehicle back
Config.Locale = 'en'

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
    mechanic = true
}


-- Set the identifier type as a string here, for example:
--		steam
--		ip
--		discord
--		license
--		license2
--		xbl
--		live
Config.PlayerIdentifierType = 'license' -- Very easy to switch your identifier for your platform

Config.MaxPlayersInTransferList = 5

-- Set the RP framework, supported values are:
--      none
--      esx
--      custom
Config.RolePlayFramework = 'esx'

Config.UsingEsxLegacy = true
