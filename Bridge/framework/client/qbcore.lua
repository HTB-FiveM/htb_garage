-- QBCore, client side
RegisterAdapter("framework", "qbcore", {
	detect = function()
		return GetResourceState("qb-core") == "started"
	end,

	onPlayerLoaded = function(callback)
		RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
		AddEventHandler("QBCore:Client:OnPlayerLoaded", callback)
	end,

	-- qb-core's draw text box
	showPrompt = function(text)
		exports["qb-core"]:DrawText(text, "left")
		return true
	end,

	hidePrompt = function()
		exports["qb-core"]:HideText()
	end,
})
