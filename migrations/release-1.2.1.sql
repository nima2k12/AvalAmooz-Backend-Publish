-- Run on the AvalAmooz database as part of the 1.2.1 rollout.
SET XACT_ABORT ON;
IF DB_NAME() <> N'AvalAmuz_DB'
    THROW 51000, 'Only the independent AvalAmuz_DB is allowed.', 1;
IF OBJECT_ID(N'[nima2k14].[AspNetUsers]', N'U') IS NULL
    OR OBJECT_ID(N'[nima2k14].[Settings]', N'U') IS NULL
    THROW 51001, 'AvalAmooz tables are required.', 1;

DECLARE @history nvarchar(261);
IF (SELECT COUNT(*) FROM sys.tables WHERE [name] = N'__EFMigrationsHistory') <> 1
    THROW 51003, 'Exactly one EF migration history table is required.', 1;
SELECT @history = QUOTENAME(SCHEMA_NAME([schema_id])) + N'.[__EFMigrationsHistory]'
FROM sys.tables WHERE [name] = N'__EFMigrationsHistory';
DECLARE @hasConsole bit, @hasMinimum bit;
DECLARE @check nvarchar(max) = N'
    SELECT @console = CASE WHEN EXISTS (SELECT 1 FROM ' + @history + N' WHERE [MigrationId] = N''20261117000000_ConsolePolicy'') THEN 1 ELSE 0 END,
           @minimum = CASE WHEN EXISTS (SELECT 1 FROM ' + @history + N' WHERE [MigrationId] = N''20261117000100_MinimumClientVersions'') THEN 1 ELSE 0 END;';
DECLARE @record nvarchar(max) = N'INSERT INTO ' + @history + N' ([MigrationId], [ProductVersion]) VALUES (@id, N''3.1.6'');';

BEGIN TRANSACTION;
EXEC sys.sp_executesql @check, N'@console bit OUTPUT, @minimum bit OUTPUT', @hasConsole OUTPUT, @hasMinimum OUTPUT;

IF @hasConsole = 0
BEGIN
    IF COL_LENGTH(N'nima2k14.AspNetUsers', N'DevToolsAllowed') IS NULL
        ALTER TABLE [nima2k14].[AspNetUsers] ADD [DevToolsAllowed] bit NOT NULL DEFAULT CAST(0 AS bit);
    EXEC sys.sp_executesql @record, N'@id nvarchar(150)', N'20261117000000_ConsolePolicy';
END;

IF @hasMinimum = 0
BEGIN
    IF COL_LENGTH(N'nima2k14.Settings', N'MinimumWebVersion') IS NULL
        ALTER TABLE [nima2k14].[Settings] ADD [MinimumWebVersion] nvarchar(32) NULL;
    IF COL_LENGTH(N'nima2k14.Settings', N'MinimumAndroidVersion') IS NULL
        ALTER TABLE [nima2k14].[Settings] ADD [MinimumAndroidVersion] nvarchar(32) NULL;
    EXEC sys.sp_executesql N'
        UPDATE [nima2k14].[Settings]
        SET [SiteVersion] = N''1.2.1'', [MinimumWebVersion] = N''1.2.1'', [MinimumAndroidVersion] = N''1.2.1'',
            [AndroidApp] = N''https://avalamuz.ir/assets/file/AvalAmooz.apk''
        WHERE [Id] = 1 AND [IsDelete] = 0;
        IF @@ROWCOUNT <> 1 THROW 51002, ''Active AvalAmooz settings record 1 is required.'', 1;';
    EXEC sys.sp_executesql @record, N'@id nvarchar(150)', N'20261117000100_MinimumClientVersions';
END;

COMMIT TRANSACTION;
