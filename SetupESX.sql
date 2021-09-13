
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
)

--
-- Create index `vehsowned` on table `owned_vehicles`
--
ALTER TABLE owned_vehicles
ADD INDEX vehsowned (owner);

--
-- Create foreign key
--
ALTER TABLE owned_vehicles
ADD CONSTRAINT FK_ownedvehiclesowner_users FOREIGN KEY (owner)
REFERENCES users (identifier) ON DELETE CASCADE ON UPDATE CASCADE;
