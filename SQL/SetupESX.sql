-- Use this script if you do NOT have the owned_vehicles table already.

--
-- Create table `owned_vehicles`
--
CREATE TABLE owned_vehicles (
  vehicle longtext NOT NULL,
  owner varchar(100) NOT NULL,
  `stored` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'State of the vehicle',
  garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  pound tinyint(1) NOT NULL DEFAULT 0,
  vehiclename varchar(50) DEFAULT NULL,
  plate varchar(50) NOT NULL,
  type varchar(10) NOT NULL DEFAULT 'car',
  job varchar(50) DEFAULT NULL,

  PRIMARY KEY (plate),
  CONSTRAINT FK_ownedvehicles_users FOREIGN KEY (owner) REFERENCES users (identifier) ON DELETE CASCADE ON UPDATE CASCADE;
);

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
