-- The queries htb_garage runs against the ESX database tables.
-- Each entry is { query = <SQL> }; the server registers them with the database on start.
RegisterAdapter("queries", "esx", {
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

	-- Vehicle by plate regardless of owner (used to validate stores and impounds server side)
	SqlGetVehicleByPlate = {
		query = [[
      SELECT
        owner,
        vehicle,
        `stored`,
        pound_htb AS pound,
        plate,
        type
      FROM owned_vehicles
      WHERE plate = @plate
      LIMIT 1
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

	SqlIsCitizenVehicle = {
		query = [[
      SELECT plate
      FROM owned_vehicles
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
  CAST(json_value(ov.vehicle, '$.model') AS SIGNED) model,
  iv.priceToRelease,
  iv.impoundName AS impoundId,
  iv.id AS impoundVehicleId,
  iv.releaseDateTime,
  iv.allowPersonalUnimpound,
  CASE
      WHEN iv.impoundName = @impoundName THEN 1
      ELSE 0
  END AS canRetrieveHere
                                     

FROM owned_vehicles ov
  INNER JOIN impound_vehicle_htb iv
    ON ov.plate = iv.vehiclePlate

WHERE ov.pound_htb = 1
  AND ov.owner = @license
  AND iv.active = 1
    ]],
		handle = nil,
	},

	-- Authoritative impound details for a plate. Used server side so the price/owner
	-- is never taken from what the client sends.
	SqlGetActiveImpoundByPlate = {
		query = [[
SELECT
  ov.owner,
  iv.priceToRelease,
  iv.impoundName
FROM owned_vehicles ov
  INNER JOIN impound_vehicle_htb iv
    ON ov.plate = iv.vehiclePlate
WHERE ov.plate = @plate
  AND ov.pound_htb = 1
  AND iv.active = 1
ORDER BY iv.id DESC
LIMIT 1
    ]],
		handle = nil,
	},

	SqlReleaseImpoundVehicle = {
		query = [[
UPDATE impound_vehicle_htb iv
JOIN owned_vehicles ov ON iv.vehiclePlate = ov.plate
SET iv.active = 0,
    ov.pound_htb = 0,
    ov.`stored` = 0
WHERE ov.plate = @plate;
    ]],
		handle = nil,
	},
})
