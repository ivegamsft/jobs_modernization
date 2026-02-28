-- =============================================
-- Seed Data for JobsDb_EducationLevels
-- =============================================

SET IDENTITY_INSERT [dbo].[JobsDb_EducationLevels] ON;
GO

INSERT INTO [dbo].[JobsDb_EducationLevels] (EducationLevelID, EducationLevelName) VALUES
(1, 'High School'),
(2, 'Associate''s'),
(3, 'Bachelor''s'),
(4, 'Master''s'),
(5, 'Doctorate'),
(6, 'Professional'),
(7, 'Other');

SET IDENTITY_INSERT [dbo].[JobsDb_EducationLevels] OFF;
GO

PRINT 'Education Levels seed data inserted successfully!';
GO