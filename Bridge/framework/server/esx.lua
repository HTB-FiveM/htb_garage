-- ESX Legacy, server side
RegisterAdapter("framework", "esx", {
	detect = function()
		return GetResourceState("es_extended") == "started"
	end,

	init = function()
		-- '@es_extended/imports.lua' in the manifest normally provides ESX already
		ESX = ESX or exports["es_extended"]:getSharedObject()
	end,

	getIdentifier = function(playerId)
		local xPlayer = ESX.GetPlayerFromId(playerId)
		return xPlayer and xPlayer.identifier
	end,

	getPlayerNames = function()
		local names = {}
		for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
			names[xPlayer.source] = xPlayer.getName and xPlayer.getName() or xPlayer.name
		end
		return names
	end,

	getJob = function(playerId)
		local xPlayer = ESX.GetPlayerFromId(playerId)
		return xPlayer and { name = xPlayer.job.name, grade = xPlayer.job.grade_name }
	end,

	-- ESX calls cash "money"; this adapter translates, so the rest of the code says "cash"
	getBalance = function(playerId, account)
		local xPlayer = ESX.GetPlayerFromId(playerId)
		if not xPlayer then
			return 0
		end
		if account == "cash" then
			return xPlayer.getMoney()
		end
		local acc = xPlayer.getAccount(account)
		return acc and acc.money or 0
	end,

	removeMoney = function(playerId, account, amount)
		local xPlayer = ESX.GetPlayerFromId(playerId)
		if not xPlayer then
			return false
		end
		if account == "cash" then
			xPlayer.removeMoney(amount)
		else
			xPlayer.removeAccountMoney(account, amount)
		end
		return true
	end,
})
