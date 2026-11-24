-- =====================================================================================
-- htb_garage: upgrade an existing ESX database in place to 2.1.0
--
-- * BACK UP YOUR DATABASE FIRST (HeidiSQL: Tools > Export database as SQL).
-- * Safe to run more than once: every step checks the current state first.
-- * Works from any earlier htb_garage version, including the in-development impound
--   table shapes (impoundId + impound_htb lookup table, missing price/active columns).
-- * Works on MySQL 8.0.21+ and MariaDB 10.6+ (the versions oxmysql's JSON_VALUE needs).
-- * Run it with HeidiSQL or the mysql/mariadb command line client, not through oxmysql,
--   because it uses temporary stored procedures (DELIMITER). They're removed at the end.
-- * A new impound table is created exactly as UpdateESX.sql creates it, foreign keys
--   included. An existing impound table keeps whatever foreign keys it already has.
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- Temporary helpers
-- -------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS htb_garage_add_column;
DROP PROCEDURE IF EXISTS htb_garage_create_impound_table;
DROP PROCEDURE IF EXISTS htb_garage_upgrade_210;

DELIMITER $$

-- Adds a column only if the table doesn't have it yet
CREATE PROCEDURE htb_garage_add_column(IN tbl varchar(64), IN col varchar(64), IN def text)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND COLUMN_NAME = col
  ) THEN
    SET @htb_sql = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', def);
    PREPARE htb_stmt FROM @htb_sql;
    EXECUTE htb_stmt;
    DEALLOCATE PREPARE htb_stmt;
  END IF;
END$$

-- Creates the impound table, if it doesn't exist yet, the same way UpdateESX.sql does.
-- It uses the character set of owned_vehicles, because a foreign key can't join columns
-- with different character sets.
CREATE PROCEDURE htb_garage_create_impound_table()
BEGIN
  DECLARE tblCollation varchar(64) DEFAULT NULL;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'impound_vehicle_htb'
  ) THEN
    SELECT TABLE_COLLATION INTO tblCollation
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'owned_vehicles';

    SET @htb_sql = CONCAT(
      'CREATE TABLE impound_vehicle_htb (
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
      )',
      IF(tblCollation IS NULL, '',
        CONCAT(' DEFAULT CHARSET=', SUBSTRING_INDEX(tblCollation, '_', 1), ' COLLATE=', tblCollation)));
    PREPARE htb_stmt FROM @htb_sql;
    EXECUTE htb_stmt;
    DEALLOCATE PREPARE htb_stmt;
  END IF;
END$$

-- Early versions stored the impound lot as `impoundId`, a foreign key to an `impound_htb`
-- table. Lots now live in Configs/Impounds.lua and are referenced by name. This copies the
-- old lot name across (where possible), then removes the old column and its foreign key,
-- otherwise new impounds would fail because `impoundId` is NOT NULL.
CREATE PROCEDURE htb_garage_upgrade_210()
BEGIN
  DECLARE fkName varchar(64) DEFAULT NULL;

  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'impound_vehicle_htb'
      AND COLUMN_NAME = 'impoundId'
  ) THEN
    -- Copy the old lot name across
    IF EXISTS (
      SELECT 1 FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'impound_htb'
    ) THEN
      SET @htb_sql =
        'UPDATE impound_vehicle_htb iv
           JOIN impound_htb i ON i.id = iv.impoundId
         SET iv.impoundName = i.name
         WHERE iv.impoundName = ''''';
      PREPARE htb_stmt FROM @htb_sql;
      EXECUTE htb_stmt;
      DEALLOCATE PREPARE htb_stmt;
    END IF;

    -- Drop whatever foreign key(s) use impoundId (the name was auto generated in early versions)
    dropLoop: LOOP
      SET fkName = NULL;
      SELECT CONSTRAINT_NAME INTO fkName
      FROM information_schema.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'impound_vehicle_htb'
        AND COLUMN_NAME = 'impoundId'
        AND REFERENCED_TABLE_NAME IS NOT NULL
      LIMIT 1;

      IF fkName IS NULL THEN
        LEAVE dropLoop;
      END IF;

      SET @htb_sql = CONCAT('ALTER TABLE impound_vehicle_htb DROP FOREIGN KEY `', fkName, '`');
      PREPARE htb_stmt FROM @htb_sql;
      EXECUTE htb_stmt;
      DEALLOCATE PREPARE htb_stmt;
    END LOOP;

    ALTER TABLE impound_vehicle_htb DROP COLUMN impoundId;
  END IF;
END$$

DELIMITER ;


-- -------------------------------------------------------------------------------------
-- 1. Columns htb_garage needs on owned_vehicles
--    (stock ESX Legacy already has `stored`, `type` and `job`; they're skipped if present)
-- -------------------------------------------------------------------------------------
CALL htb_garage_add_column('owned_vehicles', 'garage_name', 'varchar(50) NOT NULL DEFAULT ''Garage_Centre''');
CALL htb_garage_add_column('owned_vehicles', 'pound_htb',   'tinyint(4) NOT NULL DEFAULT 0');
CALL htb_garage_add_column('owned_vehicles', 'vehiclename', 'varchar(50) DEFAULT NULL');
CALL htb_garage_add_column('owned_vehicles', 'stored',      'tinyint(1) NOT NULL DEFAULT 0');
CALL htb_garage_add_column('owned_vehicles', 'type',        'varchar(10) NOT NULL DEFAULT ''car''');
CALL htb_garage_add_column('owned_vehicles', 'job',         'varchar(50) DEFAULT NULL');


-- -------------------------------------------------------------------------------------
-- 2. Impound records table (created only if it doesn't exist yet, as UpdateESX.sql does)
-- -------------------------------------------------------------------------------------
CALL htb_garage_create_impound_table();


-- -------------------------------------------------------------------------------------
-- 3. Bring an older impound table up to the current shape
-- -------------------------------------------------------------------------------------
CALL htb_garage_add_column('impound_vehicle_htb', 'impoundName',            'varchar(50) NOT NULL DEFAULT '''' AFTER vehiclePlate');
CALL htb_garage_add_column('impound_vehicle_htb', 'reasonForImpound',       'varchar(300) DEFAULT NULL');
CALL htb_garage_add_column('impound_vehicle_htb', 'releaseDateTime',        'varchar(50) DEFAULT NULL');
CALL htb_garage_add_column('impound_vehicle_htb', 'allowPersonalUnimpound', 'tinyint(1) DEFAULT NULL');
CALL htb_garage_add_column('impound_vehicle_htb', 'priceToRelease',         'int UNSIGNED NOT NULL DEFAULT 0');
CALL htb_garage_add_column('impound_vehicle_htb', 'impoundedByUser',        'varchar(60) NOT NULL DEFAULT ''''');
CALL htb_garage_add_column('impound_vehicle_htb', 'active',                 'tinyint(1) NOT NULL DEFAULT 1');

-- priceToRelease used to be nullable
UPDATE impound_vehicle_htb SET priceToRelease = 0 WHERE priceToRelease IS NULL;
ALTER TABLE impound_vehicle_htb MODIFY COLUMN priceToRelease int UNSIGNED NOT NULL DEFAULT 0;

-- impoundId -> impoundName (see the procedure above)
CALL htb_garage_upgrade_210();


-- Remove the temporary helpers
DROP PROCEDURE IF EXISTS htb_garage_add_column;
DROP PROCEDURE IF EXISTS htb_garage_create_impound_table;
DROP PROCEDURE IF EXISTS htb_garage_upgrade_210;


-- -------------------------------------------------------------------------------------
-- 4. Data consistency
-- -------------------------------------------------------------------------------------

-- Older versions saved the plate exactly as the game shows it, padded with spaces
-- ('ABC 123 '). Make each impound record use the vehicle's plate exactly as stored, so the
-- two still match on databases whose collation doesn't ignore trailing spaces (MySQL 8+).
UPDATE impound_vehicle_htb iv
  JOIN owned_vehicles ov ON TRIM(ov.plate) = TRIM(iv.vehiclePlate)
SET iv.vehiclePlate = ov.plate
WHERE CAST(iv.vehiclePlate AS BINARY) <> CAST(ov.plate AS BINARY);

-- An impound record is only "active" while its vehicle is actually impounded
UPDATE impound_vehicle_htb iv
  JOIN owned_vehicles ov ON ov.plate = iv.vehiclePlate
SET iv.active = 0
WHERE iv.active = 1
  AND ov.pound_htb = 0;


-- -------------------------------------------------------------------------------------
-- 5. Review (read only). Check these results before starting the server.
-- -------------------------------------------------------------------------------------

-- a) Active impounds. impoundName must match a key in Configs/Impounds.lua
--    (e.g. LosSantos, PaletoBay). Rows with any other name can't be retrieved in game;
--    fix them with: UPDATE impound_vehicle_htb SET impoundName = 'LosSantos' WHERE id = <id>;
SELECT id, vehiclePlate, impoundName, priceToRelease, releaseDateTime, active
FROM impound_vehicle_htb
WHERE active = 1;

-- b) Vehicles flagged as impounded with no active impound record. Nobody can retrieve
--    these in game. To release them back to their owners' garages run:
--    UPDATE owned_vehicles SET pound_htb = 0, `stored` = 1 WHERE plate IN (...);
SELECT ov.plate, ov.owner
FROM owned_vehicles ov
WHERE ov.pound_htb = 1
  AND NOT EXISTS (
    SELECT 1 FROM impound_vehicle_htb iv
    WHERE iv.vehiclePlate = ov.plate AND iv.active = 1
  );

-- The old `impound_htb` lookup table (if you have it) is no longer used. It's left in
-- place; once you're happy everything works you can remove it with:
-- DROP TABLE IF EXISTS impound_htb;
