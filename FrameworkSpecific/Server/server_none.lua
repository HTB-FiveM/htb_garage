NoneStrategy = {
  RunStartupStuff = Strategy:new(function()
    
  end),

  GetAllPlayerNames = Strategy:new(function()
     return nil
  end),

  GetPlayerIdentifierFromId = Strategy:new(function(source)
      return nil
  end),

  MakePayment = Strategy:new(function(source, account, amount)
      
  end),

  GiveVehicleKeys = Strategy:new(function(serverId, plate)

  end)
}
