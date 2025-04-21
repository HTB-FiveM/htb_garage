SQL['esx'] = {
  SqlGetAllVehicles = 
  [[
    SELECT 
      CAST(json_value(vehicle, '$.model') AS SIGNED) model,
      CAST(json_value(vehicle, '$.bodyHealth') AS SIGNED) body,
      CAST(json_value(vehicle, '$.engineHealth') AS SIGNED) engine,
      CAST(json_value(vehicle, '$.fuelLevel') AS SIGNED) fuel
      , `stored`, pound_htb AS pound, vehiclename, plate FROM owned_vehicles
    WHERE owner = @identifier AND type = @type AND job IS NULL
  ]],

  SqlGetVehicle =
  [[
    SELECT vehicle, `stored`, pound_htb AS pound, vehiclename, plate, type
    FROM owned_vehicles
    WHERE owner = @identifier AND plate = @plate
  ]],

  SqlSetVehicleStored =
  [[
    UPDATE owned_vehicles
    SET `stored` = @stored
    WHERE owner = @identifier AND plate = @plate
  ]],

  SqlSaveAndStoreVehicle =
  [[
    UPDATE owned_vehicles
    SET vehicle = @vehicle, `stored` = @stored
    WHERE plate = @plate
  ]],

  SqlSetVehicleName =
  [[
    UPDATE owned_vehicles
    SET vehiclename = @newName
    WHERE owner = @identifier AND plate = @plate
  ]],

  SqlTransferOwnership =
  [[
    UPDATE owned_vehicles
    SET owner = @newOwner
    WHERE owner = @currentOwner AND plate = @plate
  ]],

  SqlImpoundVehicle =
  [[
    UPDATE owned_vehicles
    SET pound_htb = @pound
  ]]

}