QBCoreStrategy = {
    RunStartupStuff = Strategy:new(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end),


    GetAllPlayerNames = Strategy:new(function()
        local qbPlayers = QBCore.Functions.GetPlayers()
        local playerNames = {}
        for _, playerIdStr in pairs(GetPlayers()) do
            local playerId = tonumber(playerIdStr)
            if qbPlayers[playerId] ~= nil then
                playerNames[playerId] = qbPlayers[playerId].name
            end
        end

        return playerNames
    end),

    GetPlayerIdentifierFromId = Strategy:new(function(source)
        local player = QBCore.Functions.GetPlayer(source).PlayerData
        return player.license
    end),

    MakePayment = Strategy:new(function(source, account, amount)
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            player.Functions.RemoveMoney(account, amount)
        end
    end)
}
