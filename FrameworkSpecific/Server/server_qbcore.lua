function RunStartupStuffQbCore(msg)
    QBCore = exports['qb-core']:GetCoreObject()
end


function GetAllPlayerNamesQbCore()
    local qbPlayers = QBCore.Functions.GetPlayers()
    local playerNames = {}
    for _, playerIdStr in pairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if qbPlayers[playerId] ~= nil then
            playerNames[playerId] = qbPlayers[playerId].name
        end
    end

    return playerNames
end

function GetPlayerIdentifierFromIdQbCore(source)
    local player = QBCore.Functions.GetPlayer(source).PlayerData
    return player.license
end

function MakePaymentQbCore(source, account, amount)
	local player = QBCore.Functions.GetPlayer(source)
    if player then
        player.Functions.RemoveMoney(account, amount)
    end
end
