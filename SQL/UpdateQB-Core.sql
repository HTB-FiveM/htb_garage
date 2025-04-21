ALTER TABLE player_vehicles
  ADD COLUMN garage_name varchar(50) NOT NULL DEFAULT 'Garage_Centre',
  ADD COLUMN pound_htb tinyint(4) NOT NULL DEFAULT 0,
  ADD COLUMN vehiclename varchar(50) DEFAULT NULL,
  ADD COLUMN `stored` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'State of the vehicle',
  ADD COLUMN `type` varchar(10) NOT NULL DEFAULT 'car',
  ADD COLUMN job varchar(50) DEFAULT NULL
;
