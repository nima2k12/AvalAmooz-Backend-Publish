-- Apply after deploying both AvalAmooz 1.2.2 packages.
SET XACT_ABORT ON;
IF DB_NAME() <> N'AvalAmuz_DB'
    THROW 51000, 'Only the independent AvalAmuz_DB is allowed.', 1;

BEGIN TRANSACTION;
IF (SELECT COUNT(*) FROM nima2k14.Settings WHERE IsDelete = 0) <> 1
    THROW 51001, 'Exactly one active site settings record is required.', 1;

UPDATE nima2k14.Settings
SET SiteVersion = N'1.2.2'
WHERE IsDelete = 0;

COMMIT TRANSACTION;
