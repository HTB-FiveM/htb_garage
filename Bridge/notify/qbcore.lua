-- QBCore's own notifications
local qbTypes = { info = "primary", success = "success", error = "error" }

RegisterAdapter("notify", "qbcore", {
	send = function(message, kind)
		local QBCore = exports["qb-core"]:GetCoreObject()
		QBCore.Functions.Notify(message, qbTypes[kind] or "primary", 5000)
	end,
})
