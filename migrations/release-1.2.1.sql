-- Run on the AvalAmooz database as part of the 1.2.1 rollout.
SET XACT_ABORT ON;
IF DB_NAME() <> N'AvalAmuz_DB'
    THROW 51000, 'Only the independent AvalAmuz_DB is allowed.', 1;
IF OBJECT_ID(N'[nima2k14].[AspNetUsers]', N'U') IS NULL
    OR OBJECT_ID(N'[nima2k14].[Settings]', N'U') IS NULL
    THROW 51001, 'AvalAmooz tables are required.', 1;

-- dbo tracks AvalAmooz migrations. nima2k14 also contains the history copied with the original schema.
IF OBJECT_ID(N'[dbo].[__EFMigrationsHistory]', N'U') IS NULL
    OR NOT EXISTS (SELECT 1 FROM [dbo].[__EFMigrationsHistory]
                   WHERE [MigrationId] = N'20261110213000_DiscussionNotificationReads')
    THROW 51003, 'The active AvalAmooz EF migration history is required.', 1;

BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM [dbo].[__EFMigrationsHistory] WHERE [MigrationId] = N'20261117000000_ConsolePolicy')
BEGIN
    IF COL_LENGTH(N'nima2k14.AspNetUsers', N'DevToolsAllowed') IS NULL
        ALTER TABLE [nima2k14].[AspNetUsers] ADD [DevToolsAllowed] bit NOT NULL DEFAULT CAST(0 AS bit);
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117000000_ConsolePolicy', N'3.1.6');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[__EFMigrationsHistory] WHERE [MigrationId] = N'20261117000100_MinimumClientVersions')
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
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117000100_MinimumClientVersions', N'3.1.6');
END;

COMMIT TRANSACTION;
