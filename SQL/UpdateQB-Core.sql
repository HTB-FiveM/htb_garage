ALTER TABLE player_vehicles
  ADD COLUMN garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  ADD COLUMN pound_htb tinyint(4) NOT NULL DEFAULT 0,
  ADD COLUMN vehiclename varchar(50) DEFAULT NULL,
  ADD COLUMN `stored` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'State of the vehicle',
  ADD COLUMN `type` varchar(10) NOT NULL DEFAULT 'car',
  ADD COLUMN job varchar(50) DEFAULT NULL
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
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	vehiclePlate VARCHAR(12),
	impoundId INT UNSIGNED NOT NULL, -- FK
	reasonForImpound VARCHAR(300),
	releaseDateTime varchar(50),
	allowPersonalUnimpound TINYINT(1),
  
  PRIMARY KEY (id),
  FOREIGN KEY (impoundId) REFERENCES impound_htb(id),
  FOREIGN KEY (vehiclePlate) REFERENCES owned_vehicles(plate)
);

INSERT INTO impound_htb(NAME, displayName, locationX, locationY, locationZ) VALUES
('hayesautos', 'Haye''s Autos', 490.021973, -1315.938477, 29.246094);

