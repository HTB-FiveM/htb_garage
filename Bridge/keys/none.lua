-- No keys resource: vehicles can be driven without keys
RegisterAdapter("keys", "none", {
	give = function(playerId, plate, lifetime) end,
	remove = function(playerId, plate) end,
})
