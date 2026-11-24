-- jaksam's vehicles_keys (https://jaksam1074.tebex.io)
RegisterAdapter("keys", "vehicles_keys", {
	detect = function()
		return GetResourceState("vehicles_keys") == "started"
	end,

	give = function(playerId, plate, lifetime)
		exports["vehicles_keys"]:giveVehicleKeysToPlayerId(playerId, plate, lifetime)
	end,

	-- Keys aren't taken back from the seller on a transfer (same as before). Add the
	-- vehicles_keys removal export here if your version has one.
	remove = function(playerId, plate) end,
})
