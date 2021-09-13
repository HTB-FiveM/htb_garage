Config.Hangars = {
	AirplaneHangar_Centre = {
		Type = 'plane',
		-- Impound = {
		-- 	Pos = { x = -1280.1153564453, y = -3378.1647949219,z = 13.940155029297 },
		-- 	Marker = { w= 1.5, h= 1.0,r = 204, g = 204, b = 0},
		-- 	HelpPrompt = _U('open_plane_hangar')
		-- },
		SpawnPoint = {
			Name = _U('plane_hangar_name'),
			Pos = { x = -1285.1153564453,y = -3382.1647949219,z = 13.940155029297 },
			Heading = 160.0,
			Marker = { w=1.5, h=1.0, r=0, g=255, b=0 },
			HelpPrompt = _U('spawn_plane')
		},
		DeletePoint = {
			Pos = { x = -1287.5788574219,y = -3390.4025878906,z = 13.940155029297 },
			Marker = { w=1.5, h=1.0, r=255, g=0, b=0 },
			HelpPrompt = _U('store_plane')
		}, 	
	},
}

