-- Use this script if you already have an ESX server setup that has the owned_vehicles table already
ALTER TABLE owned_vehicles
  ADD COLUMN garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  ADD COLUMN pound tinyint(4) NOT NULL DEFAULT 0,
  ADD COLUMN vehiclename varchar(50) DEFAULT NULL
;
