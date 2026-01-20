-- =============================================
-- Seed Data for JobsDb_ExperienceLevels
-- =============================================

SET IDENTITY_INSERT [dbo].[JobsDb_ExperienceLevels] ON;
GO

INSERT INTO [dbo].[JobsDb_ExperienceLevels] (ExperienceLevelID, ExperienceLevelName) VALUES
(1, 'Entry Level'),
(2, 'Junior'),
(3, 'Intermediate'),
(4, 'Senior'),
(5, 'Lead'),
(6, 'Manager'),
(7, 'Director'),
(8, 'Executive');

SET IDENTITY_INSERT [dbo].[JobsDb_ExperienceLevels] OFF;
GO

PRINT 'Experience Levels seed data inserted successfully!';
GO
