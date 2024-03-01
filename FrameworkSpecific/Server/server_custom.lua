CustomStrategy = {
    RunStartupStuff = Strategy:new(function(msg)
        -- Call your custom notification function here
        
    end),

    GetAllPlayerNames = Strategy:new(function()
        -- Call your custom player name fetching code here

    end),

    GetPlayerIdentifierFromId = Strategy:new(function(source)
        
    end),

    MakePayment = Strategy:new(function(source, account, amount)

    end),

    GiveVehicleKeys = Strategy:new(function(serverId, plate)

    end)
}
