-- Use this script if you already have an ESX server setup that has the owned_vehicles table already
ALTER TABLE owned_vehicles
  ADD COLUMN garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  ADD COLUMN pound_htb tinyint(4) NOT NULL DEFAULT 0,
  ADD COLUMN vehiclename varchar(50) DEFAULT NULL
;

--
-- Create the impound table which lists all impound depots around the map 
--
CREATE TABLE impound_htb (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(30),
  displayName VARCHAR(100),
  locationX DECIMAL(12, 6) NOT NULL,
  locationY DECIMAL(12, 6) NOT NULL,
  locationZ DECIMAL(12, 6) NOT NULL,

  PRIMARY KEY (id)
);

--
-- Create the impound_vehicle where a record of vehicle imponds are recorded 
--
CREATE TABLE impound_vehicle_htb (
  id int UNSIGNED NOT NULL AUTO_INCREMENT,
  vehiclePlate varchar(12) DEFAULT NULL,
  impoundId int UNSIGNED NOT NULL,
  reasonForImpound varchar(300) DEFAULT NULL,
  releaseDateTime varchar(50) DEFAULT NULL,
  allowPersonalUnimpound tinyint(1) DEFAULT NULL,
  impoundedByUser varchar(60) NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT FK_impoundvehicle_impound FOREIGN KEY (impoundId) REFERENCES impound_htb (id),
  CONSTRAINT FK_impoundvehicle_ownedvehicle FOREIGN KEY (vehiclePlate) REFERENCES owned_vehicles (plate),
  CONSTRAINT FK_impoundvehicle_users FOREIGN KEY (impoundedByUser) REFERENCES users (identifier)
);

INSERT INTO impound_htb(NAME, displayName, locationX, locationY, locationZ) VALUES
('hayesautos', 'Haye''s Autos', 490.021973, -1315.938477, 29.246094);

