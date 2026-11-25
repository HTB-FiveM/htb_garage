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

	-- ESX's text UI (esx_textui). Without it the zones use GTA's help box instead.
	showPrompt = function(text)
		if GetResourceState("esx_textui") ~= "started" then
			return false
		end
		ESX.TextUI(text, "info")
		return true
	end,

	hidePrompt = function()
		if GetResourceState("esx_textui") == "started" then
			ESX.HideUI()
		end
	end,
})
