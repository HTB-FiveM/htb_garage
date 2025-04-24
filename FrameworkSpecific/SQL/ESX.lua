-- define each SQL statement as { query = <SQL>, handle = nil }
SQL['esx'] = {
  SqlGetAllVehicles = {
    query = [[
      SELECT 
        CAST(json_value(vehicle, '$.model')      AS SIGNED) model,
        CAST(json_value(vehicle, '$.bodyHealth') AS SIGNED) body,
        CAST(json_value(vehicle, '$.engineHealth') AS SIGNED) engine,
        CAST(json_value(vehicle, '$.fuelLevel')  AS SIGNED) fuel,
        `stored`,
        pound_htb       AS pound,
        vehiclename,
        plate
      FROM owned_vehicles
      WHERE owner = @identifier
        AND type   = @type
        AND job    IS NULL
    ]],
    handle = nil,
  },

  SqlGetVehicle = {
    query = [[
      SELECT
        vehicle,
        `stored`,
        pound_htb   AS pound,
        vehiclename,
        plate,
        type
      FROM owned_vehicles
      WHERE owner = @identifier
        AND plate = @plate
    ]],
    handle = nil,
  },

  SqlSetVehicleStored = {
    query = [[
      UPDATE owned_vehicles
      SET `stored` = @stored
      WHERE owner = @identifier
        AND plate = @plate
    ]],
    handle = nil,
  },

  SqlSaveAndStoreVehicle = {
    query = [[
      UPDATE owned_vehicles
      SET vehicle = @vehicle,
          `stored` = @stored
      WHERE plate = @plate
    ]],
    handle = nil,
  },

  SqlSetVehicleName = {
    query = [[
      UPDATE owned_vehicles
      SET vehiclename = @newName
      WHERE owner = @identifier
        AND plate = @plate
    ]],
    handle = nil,
  },

  SqlTransferOwnership = {
    query = [[
      UPDATE owned_vehicles
      SET owner = @newOwner
      WHERE owner = @currentOwner
        AND plate = @plate
    ]],
    handle = nil,
  },

  SqlImpoundVehicle = {
    query = [[
      UPDATE owned_vehicles
      SET pound_htb = @pound
      WHERE plate = @plate
    ]],
    handle = nil,
  },

  SqlAddImpoundEntry = {
    query = [[
      INSERT INTO impound_vehicle_htb (
        vehiclePlate,
        impoundId,
        reasonForImpound,
        releaseDateTime,
        allowPersonalUnimpound
      ) VALUES (
        @vehiclePlate,
        @id,
        @reasonForImpound,
        @releaseDateTime,
        @allowPersonalUnimpound
      )
    ]],
    handle = nil,
  },

  SqlGetImpoundedVehicleByPlate = {
    query = [[
      SELECT
        i.vehiclePlate,
        i.reasonForImpound,
        i.releaseDateTime,
        i.allowPersonalUnimpound,
        o.pound_htb AS isImpounded
      FROM impound_vehicle_htb AS i
      INNER JOIN owned_vehicles AS o
        ON i.vehiclePlate = o.plate
      WHERE i.vehiclePlate = @vehiclePlate
        AND o.pound_htb    = 1
    ]],
    handle = nil,
  },

  SqlGetAllImpoundedVehicles = {
    query = [[
      SELECT
        i.vehiclePlate,
        i.reasonForImpound,
        i.releaseDateTime,
        i.allowPersonalUnimpound,
        o.pound_htb AS isImpounded
      FROM impound_vehicle_htb AS i
      INNER JOIN owned_vehicles AS o
        ON i.vehiclePlate = o.plate
      WHERE o.pound_htb = 1
    ]],
    handle = nil,
  },

  SqlGetImpoundList = {
    query = [[
      SELECT
        id AS impoundId,
        displayName,
        locationX,
        locationY,
        locationZ
      FROM impound_htb
    ]],
    handle = nil,
  },

  SqlIsCitizenVehicle = {
    query = [[
      SELECT plate
      FROM owned_vehicles
      WHERE plate = @plate
      LIMIT 1
    ]],
    handle = nil,
  },
}

-- Then, in your client.lua (or shared init), store them all in one loop:
MySQL.ready(function()
  local cfg = SQL[Config.RolePlayFramework]  -- e.g. SQL['esx'] or SQL['qbcore']
  for _, entry in pairs(cfg) do
    MySQL.Async.store(entry.query, function(storeId)
      entry.handle = storeId
    end)
  end
end)

-- Usage example:
-- MySQL.Async.fetchAll(
--   SQL[Config.RolePlayFramework].SqlGetAllVehicles.handle,
--   { identifier = someIdentifier, type = 'car' },
--   function(results) … end
-- )
