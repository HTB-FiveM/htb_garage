-- ESX's own notifications (whatever style your ESX version uses)
RegisterAdapter("notify", "esx", {
	send = function(message, kind)
		ESX.ShowNotification(message, kind or "info")
	end,
})
