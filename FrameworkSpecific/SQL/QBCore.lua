-- define each QBCore SQL statement as { query = <SQL>, handle = nil }
SQL["qbcore"] = {
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

	-- Vehicle by plate regardless of owner (used to validate stores and impounds server side)
	SqlGetVehicleByPlate = {
		query = [[
      SELECT
        license   AS owner,
        mods      AS vehicle,
        `stored`,
        pound_htb AS pound,
        plate,
        type
      FROM player_vehicles
      WHERE plate = @plate
      LIMIT 1
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
      WHERE plate = @plate
    ]],
		handle = nil,
	},

	SqlAddImpoundEntry = {
		query = [[
      INSERT INTO impound_vehicle_htb (
        vehiclePlate,
        impoundName,
        reasonForImpound,
        releaseDateTime,
        allowPersonalUnimpound,
        priceToRelease,
        impoundedByUser
      ) VALUES (
        @vehiclePlate,
        @impoundName,
        @reasonForImpound,
        @releaseDateTime,
        @allowPersonalUnimpound,
        @priceToRelease,
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
      INNER JOIN player_vehicles AS o
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
      INNER JOIN player_vehicles AS o
        ON i.vehiclePlate = o.plate
      WHERE o.pound_htb = 1
    ]],
		handle = nil,
	},

	SqlIsCitizenVehicle = {
		query = [[
      SELECT plate
      FROM player_vehicles
      WHERE plate = @plate
      LIMIT 1
    ]],
		handle = nil,
	},

	SqlGetImpoundedPlayerVehicles = {
		query = [[
SELECT 
  ov.type,
  ov.plate,
  ov.vehiclename AS displayName,
  CAST(json_value(ov.mods, '$.model') AS SIGNED) model,
  iv.priceToRelease,
  iv.impoundName AS impoundId,
  iv.id AS impoundVehicleId,
  iv.releaseDateTime,
  iv.allowPersonalUnimpound,
  CASE
      WHEN iv.impoundName = @impoundName THEN 1
      ELSE 0
  END AS canRetrieveHere
                                     

FROM player_vehicles ov
  INNER JOIN impound_vehicle_htb iv
    ON ov.plate = iv.vehiclePlate

WHERE ov.pound_htb = 1
  AND ov.license = @license
  AND iv.active = 1
    ]],
		handle = nil,
	},

	-- Authoritative impound details for a plate. Used server side so the price/owner
	-- is never taken from what the client sends.
	SqlGetActiveImpoundByPlate = {
		query = [[
SELECT
  pv.license AS owner,
  iv.priceToRelease,
  iv.impoundName
FROM player_vehicles pv
  INNER JOIN impound_vehicle_htb iv
    ON pv.plate = iv.vehiclePlate
WHERE pv.plate = @plate
  AND pv.pound_htb = 1
  AND iv.active = 1
ORDER BY iv.id DESC
LIMIT 1
    ]],
		handle = nil,
	},

	SqlReleaseImpoundVehicle = {
		query = [[
UPDATE impound_vehicle_htb iv
JOIN player_vehicles ov ON iv.vehiclePlate = ov.plate
SET iv.active = 0,
    ov.pound_htb = 0,
    ov.`stored` = 0
WHERE ov.plate = @plate;
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
