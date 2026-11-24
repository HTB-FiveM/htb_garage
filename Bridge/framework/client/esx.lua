-- ESX Legacy, client side
RegisterAdapter("framework", "esx", {
	detect = function()
		return GetResourceState("es_extended") == "started"
	end,

	init = function()
		-- '@es_extended/imports.lua' in the manifest normally provides ESX already
		ESX = ESX or exports["es_extended"]:getSharedObject()
	end,

	onPlayerLoaded = function(callback)
		RegisterNetEvent("esx:playerLoaded")
		AddEventHandler("esx:playerLoaded", callback)
	end,
})
