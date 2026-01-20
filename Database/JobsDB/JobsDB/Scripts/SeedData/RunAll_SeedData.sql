-- =============================================
-- Master Seed Data Script
-- Run all seed data scripts in order
-- =============================================

PRINT 'Starting seed data insertion...';
PRINT '==================================';
GO

-- 01 - Countries
:r .\01_SeedCountries.sql

-- 02 - States (depends on Countries)
:r .\02_SeedStates.sql

-- 03 - Education Levels
:r .\03_SeedEducationLevels.sql

-- 04 - Job Types
:r .\04_SeedJobTypes.sql

-- 05 - Experience Levels
:r .\05_SeedExperienceLevels.sql

PRINT '==================================';
PRINT 'All seed data inserted successfully!';
GO
