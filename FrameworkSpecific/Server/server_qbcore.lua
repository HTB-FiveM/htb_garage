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
    end),

    GetPlayerJob = Strategy:new(function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end
       
        return {
            jobName = job.name,
            jobGrade = job.grade.level
        }        
    end),

    --- Attempts to deduct `amount` from a player's cash or bank.
    -- @param source       number    The player’s server ID
    -- @param amount       number    How much to deduct (must be > 0)
    -- @param accountName  string?   Optional: “bank”, “black_money”, etc. If nil or empty, tries cash then bank.
    -- @return boolean               True if money was removed, false if insufficient funds
    TryDeductPlayerMoney = Strategy:new(function(source, amount, accountName)
        if amount <= 0 then
            return false
        end
    
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            return false
        end
    
        local function attemptAccount(accName, currentBalance)
            if (currentBalance - amount) >= 0 then
                Player.Functions.RemoveMoney(accName, amount)
                return true
            end
            return false
        end
    
        if accountName and accountName ~= "" then
            local balance = Player.PlayerData.money[accountName]
            if balance and attemptAccount(accountName, balance) then
                return true
            end
            return false
        else
            -- Try cash first
            local cashBalance = Player.PlayerData.money["cash"]
            if cashBalance and attemptAccount("cash", cashBalance) then
                return true
            end
            
            -- Then try bank
            local bankBalance = Player.PlayerData.money["bank"]
            if bankBalance and attemptAccount("bank", bankBalance) then
                return true
            end
            return false
        end
    end),

}
