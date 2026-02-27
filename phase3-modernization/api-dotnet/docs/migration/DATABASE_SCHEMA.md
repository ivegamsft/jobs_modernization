# Database Schema Migration Plan

## Overview

This document outlines the strategy for migrating the legacy SQL Server database schema to the modernized ASP.NET Core application.

## Current Legacy Schema Analysis

### Tables to Migrate

- `aspnet_Users` → AppUser (Identity)
- `aspnet_Roles` → AppRole (Identity)
- `aspnet_UsersInRoles` → UserRoles (Identity)
- `Companies` → Company entity
- `JobPostings` → JobPosting entity
- `Resumes` → Resume entity
- `JobSearch` → JobSearch entity
- `MyJobs` → UserJobPosting entity
- `MyResumes` → UserResume entity
- Reference tables: Countries, States, EducationLevels, JobTypes

## Migration Strategy

### Phase 1: Identity System Migration

1. Map `aspnet_Users` to `AppUser`
   - Preserve usernames and emails
   - Hash passwords (already hashed in legacy)
   - Map profile data (FirstName, LastName)

2. Map `aspnet_Roles` to `AppRole`
   - Migrate existing roles (JobSeeker, Employer, Admin)

3. Map `aspnet_UsersInRoles` to `UserRoles`

### Phase 2: Core Entity Migration

1. Migrate Companies table
2. Migrate JobPostings table
3. Migrate Resumes table
4. Migrate reference/lookup tables

### Phase 3: Relationship Migration

1. Establish foreign key relationships
2. Validate data integrity
3. Handle orphaned records

## Data Type Mappings

| Legacy SQL Type | EF Core Type          | Notes              |
| --------------- | --------------------- | ------------------ |
| int             | int                   | Direct mapping     |
| bigint          | long                  | For large integers |
| varchar(max)    | string                | Long text fields   |
| varchar(50)     | string with MaxLength | Short strings      |
| decimal(10,2)   | decimal               | Salary fields      |
| datetime        | DateTime              | Timestamps         |
| bit             | bool                  | Boolean flags      |

## Testing Approach

1. Validate record counts match
2. Spot-check data samples
3. Verify relationships
4. Test foreign key constraints
5. Performance testing on large datasets
