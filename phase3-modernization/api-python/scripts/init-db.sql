-- PostgreSQL Initialization Script for JobSite
-- This script runs when the PostgreSQL container is first created

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create indexes for better performance (tables are created by Flask-Migrate)
-- These will be created after the application runs migrations

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE jobsite_db TO jobsite;

-- Create a function for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';
