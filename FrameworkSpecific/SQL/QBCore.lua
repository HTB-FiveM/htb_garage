-- define each QBCore SQL statement as { query = <SQL>, handle = nil }
SQL['qbcore'] = {
  SqlGetAllVehicles = {
    query = [[
      SELECT 
        CAST(json_value(mods,        '$.model')      AS SIGNED) model,
        CAST(json_value(mods,        '$.bodyHealth') AS SIGNED) body,
        CAST(json_value(mods,        '$.engineHealth') AS SIGNED) engine,
        CAST(json_value(mods,        '$.fuelLevel')  AS SIGNED) fuel,
        `stored`,
        pound_htb      AS pound,
        vehiclename,
        plate
      FROM player_vehicles
      WHERE license = @identifier
        AND type    = @type
        AND job     IS NULL
    ]],
    handle = nil,
  },

  SqlGetVehicle = {
    query = [[
      SELECT
        mods      AS vehicle,
        `stored`,
        pound_htb AS pound,
        vehiclename,
        plate,
        type
      FROM player_vehicles
      WHERE license = @identifier
        AND plate   = @plate
    ]],
    handle = nil,
  },

  SqlSetVehicleStored = {
    query = [[
      UPDATE player_vehicles
      SET `stored` = @stored
      WHERE license = @identifier
        AND plate   = @plate
    ]],
    handle = nil,
  },

  SqlSaveAndStoreVehicle = {
    query = [[
      UPDATE player_vehicles
      SET mods     = @vehicle,
          `stored` = @stored
      WHERE plate   = @plate
    ]],
    handle = nil,
  },

  SqlSetVehicleName = {
    query = [[
      UPDATE player_vehicles
      SET vehiclename = @newName
      WHERE license = @identifier
        AND plate   = @plate
    ]],
    handle = nil,
  },

  SqlTransferOwnership = {
    query = [[
      UPDATE player_vehicles
      SET license   = @newOwner,
          citizenid = (
            SELECT citizenid
            FROM players
            WHERE license = @newOwner
            ORDER BY last_updated DESC
            LIMIT 1
          )
      WHERE license = @currentOwner
        AND plate   = @plate
    ]],
    handle = nil,
  },

  SqlImpoundVehicle = {
    query = [[
      UPDATE player_vehicles
      SET pound_htb = @pound
      WHERE plate = @vehiclePlate
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
        allowPersonalUnimpound,
        impoundedByUser
      ) VALUES (
        @vehiclePlate,
        @id,
        @reasonForImpound,
        @releaseDateTime,
        @allowPersonalUnimpound,
        @impoundedByUser
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
        id          AS impoundId,
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

-- The same MySQL.ready loop you already have will automatically store all of these:
-- MySQL.ready(function()
--   for _, entry in pairs(SQL[Config.RolePlayFramework]) do
--     MySQL.Async.store(entry.query, function(id) entry.handle = id end)
--   end
-- end)
