-- =============================================
-- RunAll Seed Data
-- Execute all seed data scripts in order.
-- Usage: sqlcmd -S (localdb)\JobsLocalDb -d JobsDB -i RunAll_SeedData.sql
-- =============================================

:r 01_SeedCountries.sql
:r 02_SeedStates.sql
:r 03_SeedEducationLevels.sql
:r 04_SeedJobTypes.sql
:r Scripts\SeedData\05_SeedExperienceLevels.sql

PRINT '';
PRINT 'All seed data scripts executed successfully!';
GO