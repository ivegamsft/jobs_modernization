-- SQL Server Database Initialization Script for JobSite
-- Run this script to create the database and tables

-- Create database if not exists
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'JobsDB')
BEGIN
    CREATE DATABASE JobsDB;
END
GO

USE JobsDB;
GO

-- Countries table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'countries')
BEGIN
    CREATE TABLE countries (
        id INT IDENTITY(1,1) PRIMARY KEY,
        country_name NVARCHAR(100) NOT NULL
    );
END
GO

-- States table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'states')
BEGIN
    CREATE TABLE states (
        id INT IDENTITY(1,1) PRIMARY KEY,
        country_id INT NOT NULL,
        state_name NVARCHAR(100) NOT NULL,
        FOREIGN KEY (country_id) REFERENCES countries(id)
    );
END
GO

-- Education Levels table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'education_levels')
BEGIN
    CREATE TABLE education_levels (
        id INT IDENTITY(1,1) PRIMARY KEY,
        education_level_name NVARCHAR(100) NOT NULL,
        description NVARCHAR(255)
    );
END
GO

-- Experience Levels table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'experience_levels')
BEGIN
    CREATE TABLE experience_levels (
        id INT IDENTITY(1,1) PRIMARY KEY,
        experience_level_name NVARCHAR(100) NOT NULL,
        min_years INT,
        max_years INT
    );
END
GO

-- Job Types table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'job_types')
BEGIN
    CREATE TABLE job_types (
        id INT IDENTITY(1,1) PRIMARY KEY,
        job_type_name NVARCHAR(50) NOT NULL
    );
END
GO

-- Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        email NVARCHAR(255) NOT NULL UNIQUE,
        password_hash NVARCHAR(255) NOT NULL,
        user_type NVARCHAR(20) NOT NULL DEFAULT 'jobseeker',
        first_name NVARCHAR(100),
        last_name NVARCHAR(100),
        phone NVARCHAR(50),
        is_active BIT DEFAULT 1,
        is_admin BIT DEFAULT 0,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE(),
        last_login DATETIME
    );
    CREATE INDEX idx_users_username ON users(username);
    CREATE INDEX idx_users_email ON users(email);
END
GO

-- Companies table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'companies')
BEGIN
    CREATE TABLE companies (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        company_name NVARCHAR(255) NOT NULL,
        company_profile NVARCHAR(MAX),
        address1 NVARCHAR(255),
        address2 NVARCHAR(255),
        city NVARCHAR(50),
        state_id INT,
        country_id INT,
        postal_code NVARCHAR(50),
        phone NVARCHAR(50),
        fax NVARCHAR(50),
        email NVARCHAR(255),
        website_url NVARCHAR(255),
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (state_id) REFERENCES states(id),
        FOREIGN KEY (country_id) REFERENCES countries(id)
    );
    CREATE INDEX idx_companies_user_id ON companies(user_id);
END
GO

-- Job Postings table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'job_postings')
BEGIN
    CREATE TABLE job_postings (
        id INT IDENTITY(1,1) PRIMARY KEY,
        company_id INT NOT NULL,
        title NVARCHAR(255) NOT NULL,
        description NVARCHAR(MAX) NOT NULL,
        department NVARCHAR(50),
        job_code NVARCHAR(50),
        contact_person NVARCHAR(255),
        city NVARCHAR(50),
        state_id INT,
        country_id INT,
        education_level_id INT,
        job_type_id INT,
        category_id INT,
        min_salary DECIMAL(12,2),
        max_salary DECIMAL(12,2),
        posted_date DATETIME DEFAULT GETDATE(),
        posted_by NVARCHAR(50),
        is_active BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (company_id) REFERENCES companies(id),
        FOREIGN KEY (state_id) REFERENCES states(id),
        FOREIGN KEY (country_id) REFERENCES countries(id),
        FOREIGN KEY (education_level_id) REFERENCES education_levels(id),
        FOREIGN KEY (job_type_id) REFERENCES job_types(id)
    );
    CREATE INDEX idx_job_postings_company_id ON job_postings(company_id);
    CREATE INDEX idx_job_postings_is_active ON job_postings(is_active);
END
GO

-- Resumes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'resumes')
BEGIN
    CREATE TABLE resumes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        title NVARCHAR(255) NOT NULL,
        summary NVARCHAR(MAX),
        first_name NVARCHAR(100),
        last_name NVARCHAR(100),
        email NVARCHAR(255),
        phone NVARCHAR(50),
        address NVARCHAR(255),
        city NVARCHAR(50),
        state_id INT,
        country_id INT,
        postal_code NVARCHAR(50),
        education_level_id INT,
        experience_level_id INT,
        desired_job_type_id INT,
        desired_salary DECIMAL(12,2),
        skills NVARCHAR(MAX),
        experience NVARCHAR(MAX),
        education NVARCHAR(MAX),
        is_active BIT DEFAULT 1,
        is_public BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (state_id) REFERENCES states(id),
        FOREIGN KEY (country_id) REFERENCES countries(id),
        FOREIGN KEY (education_level_id) REFERENCES education_levels(id),
        FOREIGN KEY (experience_level_id) REFERENCES experience_levels(id),
        FOREIGN KEY (desired_job_type_id) REFERENCES job_types(id)
    );
    CREATE INDEX idx_resumes_user_id ON resumes(user_id);
END
GO

-- My Jobs (Favorites) table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'my_jobs')
BEGIN
    CREATE TABLE my_jobs (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        job_posting_id INT NOT NULL,
        notes NVARCHAR(MAX),
        created_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (job_posting_id) REFERENCES job_postings(id),
        UNIQUE(user_id, job_posting_id)
    );
END
GO

-- My Resumes (Favorites) table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'my_resumes')
BEGIN
    CREATE TABLE my_resumes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        resume_id INT NOT NULL,
        notes NVARCHAR(MAX),
        created_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (resume_id) REFERENCES resumes(id),
        UNIQUE(user_id, resume_id)
    );
END
GO

-- My Searches table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'my_searches')
BEGIN
    CREATE TABLE my_searches (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        search_name NVARCHAR(100) NOT NULL,
        search_criteria NVARCHAR(MAX),
        search_type NVARCHAR(20) DEFAULT 'job',
        created_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- Insert seed data
-- Countries
IF NOT EXISTS (SELECT * FROM countries WHERE country_name = 'United States')
BEGIN
    INSERT INTO countries (country_name) VALUES ('United States');
    INSERT INTO countries (country_name) VALUES ('Canada');
    INSERT INTO countries (country_name) VALUES ('United Kingdom');
    INSERT INTO countries (country_name) VALUES ('Australia');
    INSERT INTO countries (country_name) VALUES ('Germany');
END
GO

-- States (US)
IF NOT EXISTS (SELECT * FROM states WHERE state_name = 'California')
BEGIN
    DECLARE @usa_id INT = (SELECT id FROM countries WHERE country_name = 'United States');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'California');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'New York');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Texas');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Florida');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Washington');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Massachusetts');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Illinois');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Colorado');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'Georgia');
    INSERT INTO states (country_id, state_name) VALUES (@usa_id, 'North Carolina');
END
GO

-- Education Levels
IF NOT EXISTS (SELECT * FROM education_levels WHERE education_level_name = 'High School')
BEGIN
    INSERT INTO education_levels (education_level_name, description) VALUES ('High School', 'High School Diploma or GED');
    INSERT INTO education_levels (education_level_name, description) VALUES ('Associate', 'Associate Degree');
    INSERT INTO education_levels (education_level_name, description) VALUES ('Bachelor', 'Bachelor''s Degree');
    INSERT INTO education_levels (education_level_name, description) VALUES ('Master', 'Master''s Degree');
    INSERT INTO education_levels (education_level_name, description) VALUES ('Doctorate', 'Ph.D. or Doctorate');
    INSERT INTO education_levels (education_level_name, description) VALUES ('Professional', 'Professional Degree (MD, JD, etc.)');
END
GO

-- Experience Levels
IF NOT EXISTS (SELECT * FROM experience_levels WHERE experience_level_name = 'Entry Level')
BEGIN
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Entry Level', 0, 1);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Junior', 1, 3);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Mid-Level', 3, 5);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Senior', 5, 10);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Lead', 7, 15);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Principal', 10, NULL);
    INSERT INTO experience_levels (experience_level_name, min_years, max_years) VALUES ('Executive', 15, NULL);
END
GO

-- Job Types
IF NOT EXISTS (SELECT * FROM job_types WHERE job_type_name = 'Full-Time')
BEGIN
    INSERT INTO job_types (job_type_name) VALUES ('Full-Time');
    INSERT INTO job_types (job_type_name) VALUES ('Part-Time');
    INSERT INTO job_types (job_type_name) VALUES ('Contract');
    INSERT INTO job_types (job_type_name) VALUES ('Temporary');
    INSERT INTO job_types (job_type_name) VALUES ('Internship');
    INSERT INTO job_types (job_type_name) VALUES ('Remote');
    INSERT INTO job_types (job_type_name) VALUES ('Freelance');
END
GO

PRINT 'Database initialization completed successfully!';
GO
