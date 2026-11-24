-- The game's own notification feed (above the minimap). Works without any framework.
RegisterAdapter("notify", "gta", {
	send = function(message)
		BeginTextCommandThefeedPost("STRING")
		AddTextComponentSubstringPlayerName(message)
		EndTextCommandThefeedPostTicker(false, true)
	end,
})
