-- ESX's own notifications (whatever style your ESX version uses)
RegisterAdapter("notify", "esx", {
	send = function(message, kind)
		ESX.ShowNotification(message .. " ====> New Strategy", kind or "info")
	end,
})
