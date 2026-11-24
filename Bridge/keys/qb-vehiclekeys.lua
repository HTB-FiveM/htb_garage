-- qb-vehiclekeys (QBCore's keys resource)
RegisterAdapter("keys", "qb-vehiclekeys", {
	detect = function()
		return GetResourceState("qb-vehiclekeys") == "started"
	end,

	give = function(playerId, plate)
		TriggerClientEvent("qb-vehiclekeys:client:AddKeys", playerId, plate)
	end,

	remove = function(playerId, plate)
		TriggerClientEvent("qb-vehiclekeys:client:RemoveKeys", playerId, plate)
	end,
})
