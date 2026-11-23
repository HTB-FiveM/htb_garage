EsxStrategy = {
    RunStartupStuff = Strategy:new(function(msg)
        -- NOTE: If not using legacy then comment out the '@es_extended/imports.lua' line in fxmanifest.lua
        --       Legacy provides a definition for ESX object so this should overwrite the global, but
        --       better to not let it load if not required
        if Config.UsingEsxLegacy == false then
            ESX = nil 
        
            TriggerEvent('esx:getSharedObject', function(obj)
                ESX = obj
            end)
        end
    end),

    GetAllPlayerNames = Strategy:new(function()
        -- If you don't have this function in your es_extended, add it. I won't accomodate for
        -- not having this as without it there's MAJOR potential for server killing. Find it in ESX Legacy
        local xPlayers = ESX.GetExtendedPlayers()
        local playerNames = {}
        for _, playerIdStr in pairs(GetPlayers()) do
            local playerId = tonumber(playerIdStr)
            if xPlayers[playerId] ~= nil then
                playerNames[playerId] = xPlayers[playerId].name
            end
        end

        return playerNames
    end),

    GetPlayerIdentifierFromId = Strategy:new(function(source)
        return ESX.GetPlayerFromId(source).identifier
    end),

    MakePayment = Strategy:new(function(source, account, amount)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeAccountMoney(account, amount)
    end),

    GiveVehicleKeys = Strategy:new(function(args)
        -- Is vehicles_keys script by jaksam installed then this should work, otherwise adjust to suit your own system
        if GetResourceState('vehicles_keys') == 'started' then
            exports['vehicles_keys']:giveVehicleKeysToPlayerId(args.playerServerId, args.carplate, args.lifetime)
        end
    end),

    GetPlayerJob = Strategy:new(function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        return {
            jobName = xPlayer.job.name,
            jobGrade = xPlayer.job.grade_name
        }        
    end),

    -- Attempts to deduct `amount` from a player's cash or bank.
    -- @param source       number    The player’s server ID
    -- @param amount       number    How much to deduct (must be > 0)
    -- @param accountName  string?   Optional: “bank”, “black_money”, etc. If nil, tries cash then bank.
    -- @return boolean               True if money was removed, false if insufficient funds
    TryDeductPlayerMoney = Strategy:new(function(source, amount, accountName)
        if amount <= 0 then
            return false
        end
        
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            return false
        end

        -- Helper to test-and-remove from a given account
        local function attemptAccount(accName, current)
            if (current - amount) >= 0 then
                if accName == 'cash' then
                    xPlayer.removeMoney(amount)
                else
                    xPlayer.removeAccountMoney(accName, amount)
                end
                return true
            end
            return false
        end

        if accountName then
            -- Specified account: fetch its balance and try it
            local acc = xPlayer.getAccount(accountName)
            if acc and attemptAccount(accountName, acc.money) then
                return true
            end
            return false
        else
            -- No account specified: try cash first…
            local cash   = xPlayer.getMoney()
            if attemptAccount('cash', cash) then
                return true
            end
            -- then fall back to bank
            local bankAcc = xPlayer.getAccount('bank')
            if bankAcc and attemptAccount('bank', bankAcc.money) then
                return true
            end
            return false
        end
    end),

}
