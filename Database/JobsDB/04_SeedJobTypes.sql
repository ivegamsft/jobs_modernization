-- =============================================
-- Seed Data for JobsDb_JobTypes
-- =============================================

SET IDENTITY_INSERT [dbo].[JobsDb_JobTypes] ON;
GO

INSERT INTO [dbo].[JobsDb_JobTypes] (JobTypeID, JobTypeName) VALUES
(1, 'Full-time'),
(2, 'Part-time'),
(3, 'Contract'),
(4, 'Temporary'),
(5, 'Internship'),
(6, 'Freelance'),
(7, 'Remote');

SET IDENTITY_INSERT [dbo].[JobsDb_JobTypes] OFF;
GO

PRINT 'Job Types seed data inserted successfully!';
GO