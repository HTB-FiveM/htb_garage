-- ox_lib notifications (https://overextended.dev/ox_lib/Modules/Interface/Client/notify)
local oxTypes = { info = "inform", success = "success", error = "error" }

RegisterAdapter("notify", "ox_lib", {
	detect = function()
		return GetResourceState("ox_lib") == "started"
	end,

	send = function(message, kind)
		-- ox_lib listens for this event on the client, so no '@ox_lib/init.lua' import is needed
		TriggerEvent("ox_lib:notify", { description = message, type = oxTypes[kind] or "inform" })
	end,
})
