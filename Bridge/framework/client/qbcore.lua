-- QBCore, client side
RegisterAdapter("framework", "qbcore", {
	detect = function()
		return GetResourceState("qb-core") == "started"
	end,

	onPlayerLoaded = function(callback)
		RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
		AddEventHandler("QBCore:Client:OnPlayerLoaded", callback)
	end,
})
