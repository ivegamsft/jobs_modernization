-- =============================================
-- Seed Data for JobsDb_Countries
-- =============================================

SET IDENTITY_INSERT [dbo].[JobsDb_Countries] ON;
GO

INSERT INTO [dbo].[JobsDb_Countries] (CountryID, CountryName) VALUES
(1, 'United States'),
(2, 'Canada'),
(3, 'United Kingdom'),
(4, 'Australia'),
(5, 'Germany'),
(6, 'France'),
(7, 'India'),
(8, 'Japan'),
(9, 'Brazil'),
(10, 'Mexico'),
(11, 'Netherlands'),
(12, 'Singapore'),
(13, 'Ireland'),
(14, 'Israel'),
(15, 'South Korea');

SET IDENTITY_INSERT [dbo].[JobsDb_Countries] OFF;
GO

PRINT 'Countries seed data inserted successfully!';
GO