Config.Hangars = {
	AirplaneHangar_Centre = {
		Type = "plane",
		-- Impound = {
		-- 	Pos = vector3(-1280.1153564453, -3378.1647949219, 13.940155029297),
		-- 	Marker = { w= 1.5, h= 1.0,r = 204, g = 204, b = 0},
		-- 	HelpPrompt = _U('open_plane_hangar')
		-- },
		GarageMenuLocation = {
			Name = _U("plane_hangar_name"),
			Pos = vector3(-1622.4475, -3151.1323, 13.9922),
			Heading = 328.0,
			Marker = { w = 1.5, h = 1.0, r = 0, g = 255, b = 0 },
			HelpPrompt = _U("spawn_plane"),
		},
		-- Where the aircraft appears: somewhere open, away from the menu (no marker)
		SpawnPoint = {
			Pos = vector3(-1628.44, -3104.7, 13.94),
			Heading = 330.0,
			Clearance = 10.0, -- Refuse to spawn if anything is within this many metres
		},
		DeletePoint = {
			Pos = vector3(-1593.4073, -3111.5364, 13.9449),
			Marker = { w = 8, h = 1.0, r = 255, g = 0, b = 0 },
			HelpPrompt = _U("store_plane"),
		},
	},
}
