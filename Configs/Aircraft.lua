Config.Hangars = {
	AirplaneHangar_Centre = {
		Type = "plane",
		-- Impound = {
		-- 	Pos = vector3(-1280.1153564453, -3378.1647949219, 13.940155029297),
		-- 	Marker = { w= 1.5, h= 1.0,r = 204, g = 204, b = 0},
		-- 	HelpPrompt = _U('open_plane_hangar')
		-- },
		SpawnPoint = {
			Name = _U("plane_hangar_name"),
			Pos = vector3(-1262.9760, -3361.6353, 13.9401),
			Heading = 328.0,
			Marker = { w = 1.5, h = 1.0, r = 0, g = 255, b = 0 },
			HelpPrompt = _U("spawn_plane"),
		},
		DeletePoint = {
			Pos = vector3(-1287.5788574219, -3390.4025878906, 13.940155029297),
			Marker = { w = 1.5, h = 1.0, r = 255, g = 0, b = 0 },
			HelpPrompt = _U("store_plane"),
		},
	},
}
