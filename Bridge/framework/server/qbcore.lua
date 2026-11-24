-- QBCore, server side
local QBCore

RegisterAdapter("framework", "qbcore", {
	detect = function()
		return GetResourceState("qb-core") == "started"
	end,

	init = function()
		QBCore = exports["qb-core"]:GetCoreObject()
	end,

	-- Vehicles are owned by the player's license in player_vehicles
	getIdentifier = function(playerId)
		local player = QBCore.Functions.GetPlayer(playerId)
		return player and player.PlayerData.license
	end,

	getPlayerNames = function()
		local names = {}
		for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
			local data = player.PlayerData
			names[data.source] = ("%s %s"):format(data.charinfo.firstname, data.charinfo.lastname)
		end
		return names
	end,

	getJob = function(playerId)
		local player = QBCore.Functions.GetPlayer(playerId)
		if not player then
			return nil
		end
		local job = player.PlayerData.job
		return { name = job.name, grade = job.grade.level }
	end,

	getBalance = function(playerId, account)
		local player = QBCore.Functions.GetPlayer(playerId)
		return player and player.PlayerData.money[account] or 0
	end,

	removeMoney = function(playerId, account, amount)
		local player = QBCore.Functions.GetPlayer(playerId)
		return player ~= nil and player.Functions.RemoveMoney(account, amount) ~= false
	end,
})
