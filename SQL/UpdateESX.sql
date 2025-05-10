-- Use this script if you already have an ESX server setup that has the owned_vehicles table already
ALTER TABLE owned_vehicles
  ADD COLUMN garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  ADD COLUMN pound_htb tinyint(4) NOT NULL DEFAULT 0,
  ADD COLUMN vehiclename varchar(50) DEFAULT NULL
;

--
-- Create the impound_vehicle where a record of vehicle imponds are recorded 
--
CREATE TABLE impound_vehicle_htb (
  id int UNSIGNED NOT NULL AUTO_INCREMENT,
  vehiclePlate varchar(12) DEFAULT NULL,
  impoundName varchar(50) NOT NULL,
  reasonForImpound varchar(300) DEFAULT NULL,
  releaseDateTime varchar(50) DEFAULT NULL,
  allowPersonalUnimpound tinyint(1) DEFAULT NULL,
  priceToRelease int UNSIGNED NOT NULL DEFAULT 0,
  impoundedByUser varchar(60) NOT NULL,
  active tinyint(1) NOT NULL DEFAULT 1,

  PRIMARY KEY (id),
  CONSTRAINT FK_impoundvehicle_ownedvehicle FOREIGN KEY (vehiclePlate) REFERENCES owned_vehicles (plate),
  CONSTRAINT FK_impoundvehicle_users FOREIGN KEY (impoundedByUser) REFERENCES users (identifier) ON UPDATE CASCADE
);
