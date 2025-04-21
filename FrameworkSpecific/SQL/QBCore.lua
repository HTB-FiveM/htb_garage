
SQL['qbcore'] = {
  SqlGetAllVehicles = 
  [[
    SELECT 
      CAST(json_value(mods, '$.model') AS SIGNED) model,
      CAST(json_value(mods, '$.bodyHealth') AS SIGNED) body,
      CAST(json_value(mods, '$.engineHealth') AS SIGNED) engine,
      CAST(json_value(mods, '$.fuelLevel') AS SIGNED) fuel
      , `stored`, pound_htb AS pound, vehiclename, plate FROM player_vehicles
    WHERE license = @identifier AND type = @type AND job IS NULL
  ]],

  SqlGetVehicle =
  [[
    SELECT mods AS vehicle, `stored`, pound_htb AS pound, vehiclename, plate, type
    FROM player_vehicles
    WHERE license = @identifier AND plate = @plate
  ]],

  SqlSetVehicleStored =
  [[
    UPDATE player_vehicles
    SET `stored` = @stored
    WHERE license = @identifier AND plate = @plate
  ]],

  SqlSaveAndStoreVehicle =
  [[
    UPDATE player_vehicles
    SET mods = @vehicle, `stored` = @stored
    WHERE plate = @plate
  ]],

  SqlSetVehicleName =
  [[
    UPDATE player_vehicles
    SET vehiclename = @newName
    WHERE license = @identifier AND plate = @plate
  ]],

  SqlTransferOwnership =
  [[
    UPDATE player_vehicles
    SET license = @newOwner,
    citizenid = (
      SELECT citizenid
      FROM players
      WHERE license = @newOwner
      ORDER BY last_updated
      DESC LIMIT 1
    )
    WHERE license = @currentOwner AND plate = @plate
  ]],

  SqlImpoundVehicle =
  [[
    UPDATE player_vehicles
    SET pound_htb = @pound
  ]]

}
