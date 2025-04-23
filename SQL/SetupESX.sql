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
  PRIMARY KEY (plate)
);

--
-- Create foreign key
--
ALTER TABLE owned_vehicles
ADD CONSTRAINT FK_ownedvehicles_users FOREIGN KEY (owner)
REFERENCES users (identifier) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Create the impound table which lists all impound depots around the map 
--
CREATE TABLE impound_htb (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(30),
  displayName VARCHAR(100),
  locationX DECIMAL(9, 6) NOT NULL,
  locationY DECIMAL(9, 6) NOT NULL,

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

INSERT INTO impound_htb(name, displayName, locationX, locationY) VALUES
('Snoog', 'Snoogans', 10.123, 50.321);

