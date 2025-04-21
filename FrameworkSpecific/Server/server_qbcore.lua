QBCoreStrategy = {
    RunStartupStuff = Strategy:new(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end),


    GetAllPlayerNames = Strategy:new(function()
        local qbPlayers = QBCore.Functions.GetQBPlayers()
        local playerNames = {}
        for _, player in pairs(qbPlayers) do
            if player ~= nil then
                playerNames[player.PlayerData.source] = string.format("%s %s", player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
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
    end),

    GiveVehicleKeys = Strategy:new(function(args)
        -- Is vehicles_keys script by jaksam installed then this should work, otherwise adjust to suit your own system
        -- if GetResourceState('vehicles_keys') == 'started' then
        --     exports['vehicles_keys']:giveVehicleKeysToPlayerId(args.playerServerId, args.carplate, args.lifetime)
        -- end
    end)
}
