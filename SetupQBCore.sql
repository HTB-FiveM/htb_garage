
ALTER TABLE player_vehicles
ADD COLUMN vehiclename VARCHAR(50);

ALTER TABLE player_vehicles
ADD COLUMN `type` VARCHAR(10) DEFAULT 'car';

