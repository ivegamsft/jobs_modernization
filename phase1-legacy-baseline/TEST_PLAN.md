# Phase 1: Legacy Baseline — Test Plan

**Document Purpose:** Comprehensive test strategy for validating that appV1.5-buildable can build, deploy, and run successfully.

**Baseline Truth:** The legacy application has **never been tested for buildability** in this repository. This test plan establishes a baseline to measure against.

---

## 1. Build Verification Tests

### 1.1 Solution Compilation
**Objective:** Verify that the .NET Framework 4.8 Web Forms solution compiles without errors.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| BLD-001 | Clean build in Debug configuration | Run `dotnet build` or `msbuild` on the solution | Build succeeds, no errors or warnings | CI Pipeline (MSBuild) |
| BLD-002 | Clean build in Release configuration | Run `msbuild JobsSiteWeb.csproj /p:Configuration=Release` | Build succeeds | CI Pipeline |
| BLD-003 | NuGet package restore | Run `nuget restore` before build | All packages restored (currently only CodeDom Providers 2.0.1) | CI Pipeline |
| BLD-004 | Check for missing dependencies | Verify all referenced assemblies are available | No "missing assembly" errors | CI Pipeline |
| BLD-005 | Code-behind compilation | Verify all .aspx.cs and .master.cs files compile | No compilation errors in code-behind | CI Pipeline |

**Dependencies:**
- .NET Framework 4.8 SDK installed
- Visual Studio 2019+ or MSBuild 16.0+

**Test Infrastructure:**
- Use MSBuild directly (cross-platform compatible)
- Log output to analyze warnings

---

## 2. Database Tests

### 2.1 DACPAC Build & Deployment
**Objective:** Verify that the SQL Server database project builds and deploys correctly.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| DB-001 | DACPAC generation | Build JobsDB.sqlproj | .dacpac file generated without errors | CI Pipeline (MSBuild) |
| DB-002 | Deploy DACPAC to LocalDB | Deploy to `(localdb)\mssqllocaldb` with fresh instance | Schema created, zero errors | CI Pipeline or Manual |
| DB-003 | Deploy DACPAC to SQL Server | Deploy to SQL Server 2019+ instance | Schema created, zero errors | Manual (CI optional) |
| DB-004 | Verify schema tables created | Run `SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='dbo'` | Exactly 22 tables present | Integration Test Script |
| DB-005 | Verify stored procedures | Count stored procedures in database | ~150+ stored procedures present | Integration Test Script |
| DB-006 | Table structure validation | Check each table for correct columns and data types | All tables match .sql definition files | Database Schema Validation Script |

**Dependencies:**
- SQL Server 2019+ or LocalDB
- SqlPackage CLI tool (for DACPAC deployment)

**Test Infrastructure:**
- Use `SqlPackage.exe` or Azure Data Studio for deployment
- PowerShell scripts to validate schema
- Connection string environment variables

### 2.2 Seed Data Loading
**Objective:** Verify that reference data loads correctly and does not cause conflicts.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| DB-007 | Load seed data script | Execute `RunAll_SeedData.sql` | All rows inserted without errors | Integration Test Script |
| DB-008 | Countries populated | SELECT from Countries table | At least 100 countries present | Integration Test Script |
| DB-009 | States populated | SELECT from States table for each country | States correctly linked to countries | Integration Test Script |
| DB-010 | Education levels populated | SELECT from EducationLevels | 4-6 education levels (High School, Bachelor, Master, etc.) | Integration Test Script |
| DB-011 | Job types populated | SELECT from JobTypes | 3-5 job types present | Integration Test Script |
| DB-012 | No duplicate seed data | Check for duplicate entries in reference tables | Zero duplicates on unique fields | Integration Test Script |

**Notes:**
- See `SEED_DATA_CONFLICT_ANALYSIS.md` for known conflicts
- Some seed scripts may need ordering adjustments

**Test Infrastructure:**
- Seed data scripts in `database/JobsDB/Scripts/`
- PowerShell seed data validation script

### 2.3 Stored Procedure Validation
**Objective:** Verify that all stored procedures execute without errors.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| DB-013 | All stored procedures callable | Execute INFORMATION_SCHEMA query for procedures | ~150+ procedures reported | Integration Test Script |
| DB-014 | ASP.NET Membership procs execute | Call aspnet_Membership_GetUserByName with test user | No errors, valid data returned | Integration Test Script |
| DB-015 | Jobs-specific procs execute | Call JobsDb_JobPostings_SelectAll | No errors, DataSet returned | Integration Test Script |
| DB-016 | Procedure parameter binding | Test proc with parameters (e.g., JobsDb_JobPostings_SelectOne @ID=1) | Parameters bound correctly, expected result | Integration Test Script |
| DB-017 | No syntax errors in procedures | Parse all .sql files in Stored Procedures folder | All syntax valid | Static Analysis (SQL Parser) |

**Test Infrastructure:**
- T-SQL test harness in PowerShell or SQL Agent job
- Parameterized queries for security validation

---

## 3. Smoke Tests (Manual + Automation Candidates)

### 3.1 Application Startup & Home Page
**Objective:** Verify the application launches and renders the home page.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| SMK-001 | Application starts | Launch app (IIS Express or full IIS), navigate to https://localhost:44344/ | HTTP 200, page renders without 500 errors | Manual or Selenium |
| SMK-002 | Master page loads | Check for header, navigation, footer elements | Master page structure present | Selenium / UI Test |
| SMK-003 | No unhandled exceptions | Check browser console and Application Insights logs | Zero error log entries | Log Monitoring |
| SMK-004 | Database connection on startup | Verify app connects to database on page load | No "Connection Failed" errors | Manual Inspection |
| SMK-005 | CSS/JS loaded | Verify theme (YellowShades) applies correctly | Page renders with styling, no 404s on assets | Selenium / Browser Dev Tools |

**Dependencies:**
- IIS Express or local IIS configured
- SQL Server or LocalDB running with JobsDB
- Connection string in Web.config pointing to database

**Test Infrastructure:**
- Manual smoke test by developer
- Optional: Selenium tests for UI rendering
- Log file inspection for errors

### 3.2 Job Listing & Search
**Objective:** Verify users can browse and search for jobs.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| SMK-006 | View job listings | Navigate to `/jobseeker/jobsearch.aspx` | Page loads, displays job list from database | Manual + Selenium |
| SMK-007 | Search by keyword | Enter search term (e.g., "software"), submit | Results filtered by keyword match | Selenium |
| SMK-008 | Filter by location | Select country/state filter | Results filtered by location | Selenium |
| SMK-009 | Pagination works | Click "Next" on result list | Next page loads with different jobs | Selenium |
| SMK-010 | View job details | Click on a job listing | Job detail page loads with full description | Selenium |

**Notes:**
- Assumes seed data has been loaded with sample jobs
- Requires at least 1 job posting in database

**Test Infrastructure:**
- Selenium WebDriver tests (C# or Python)
- Test data: Pre-load 10+ sample jobs in test database

### 3.3 User Registration & Login (ASP.NET Membership)
**Objective:** Verify the membership system works for user authentication.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| SMK-011 | User registration | Navigate to `/register.aspx`, fill form, submit | User created in aspnet_Users table | Manual + Selenium |
| SMK-012 | Password validation | Attempt registration with weak password | Validation error shown | Selenium |
| SMK-013 | Duplicate user check | Attempt to register with existing email | "User already exists" error | Selenium |
| SMK-014 | User login | Navigate to `/login.aspx`, enter username/password | Authentication succeeds, user logged in (session/cookie set) | Selenium |
| SMK-015 | Invalid credentials | Login with wrong password | "Invalid credentials" error | Selenium |
| SMK-016 | Change password | Navigate to `/changepassword.aspx`, change password | Password updated in database, can login with new password | Manual |
| SMK-017 | Role assignment | Register as JobSeeker, verify role created | User in aspnet_UsersInRoles with JobSeeker role | Manual SQL check |
| SMK-018 | Employer role | Register as Employer, verify employer folder accessible | Can access `/employer/` pages | Manual |

**Dependencies:**
- ASPNET Membership provider configured in Web.config
- Membership tables deployed

**Test Infrastructure:**
- Selenium for UI tests
- SQL Server query to validate user creation
- Test cleanup: Delete test users after each run

### 3.4 Admin Pages & Access Control
**Objective:** Verify admin functionality and role-based access control.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| SMK-019 | Admin login | Register/login as admin, navigate to `/Admin/` | Admin pages load | Manual |
| SMK-020 | Education levels management | As admin, view/edit education levels | Management page loads, CRUD operations work | Manual + Selenium |
| SMK-021 | Experience level management | As admin, manage experience levels | Management page loads, CRUD operations work | Manual + Selenium |
| SMK-022 | Non-admin access denied | As non-admin user, attempt to access `/Admin/` | HTTP 403 Forbidden or redirect to login | Selenium |
| SMK-023 | JobSeeker cannot access Employer pages | As JobSeeker, attempt `/employer/` | Access denied or redirect | Selenium |
| SMK-024 | Employer cannot access Admin pages | As Employer, attempt `/Admin/` | Access denied or redirect | Selenium |

**Dependencies:**
- Roles configured (JobSeeker, Employer, Admin)
- Authorization rules in Web.config

**Test Infrastructure:**
- Role-based access control validation tests
- Test accounts for each role

---

## 4. Integration Tests

### 4.1 Application → Database Connectivity
**Objective:** Verify the app correctly connects to and reads/writes data.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| INT-001 | Connection string loaded | App starts, reads connectionstring from Web.config | Connection successful, no timeout | Integration Test |
| INT-002 | Query execution | Load companies list (via JobsDb_Companies_SelectAll) | DataSet returned with data | Integration Test (MSTest/xUnit) |
| INT-003 | Parameter binding | Search jobs by criteria (multiple parameters) | Query executes with correct parameters bound | Integration Test |
| INT-004 | Transaction rollback | Attempt invalid insert, check rollback | Database remains unchanged on error | Integration Test |
| INT-005 | Connection pooling | Make 10 rapid requests to database | All requests succeed, no "max pool size" errors | Load Test (optional) |
| INT-006 | Null handling | Retrieve optional fields (e.g., company description) | Nulls handled gracefully (not displayed as "null") | Manual inspection |

**Test Infrastructure:**
- MSTest or xUnit test projects
- Connection string from Web.config or test configuration
- SQL Server test instance (LocalDB or Docker)

### 4.2 Stored Procedure Round-Trips
**Objective:** Verify specific business workflows using stored procedures.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| INT-007 | Add job posting | Call JobsDb_JobPostings_Insert with test data | Posting created, ID returned, can be retrieved | Integration Test |
| INT-008 | Get latest jobs | Call JobsDb_JobPostings_GetLatest | Returns most recent N postings in order | Integration Test |
| INT-009 | Match skills | Call JobsDb_JobPostings_SelecForMatchingSkills with resume skills | Returns jobs with matching skills | Integration Test |
| INT-010 | Save favorites | Call JobsDb_MyJobs_Insert for user | User's favorite job saved, retrievable | Integration Test |
| INT-011 | List user postings | Call JobsDb_JobPostings_SelectByUser for employer | Returns only that user's postings | Integration Test |
| INT-012 | Update posting | Call JobsDb_JobPostings_Update | Posting updated, select returns new values | Integration Test |
| INT-013 | Delete posting | Call JobsDb_JobPostings_Delete | Posting deleted, select returns empty | Integration Test |

**Notes:**
- Each test uses a fresh test database
- Data cleaned up after each test

**Test Infrastructure:**
- xUnit or MSTest with test databases
- Setup/teardown for test isolation
- Factory methods for test data creation

### 4.3 Membership Provider Integration
**Objective:** Verify ASP.NET Membership provider functions.

**Test Cases:**

| Test ID | Scenario | Steps | Expected Result | Automation |
|---------|----------|-------|-----------------|-----------|
| INT-014 | Create user via provider | Use Membership.CreateUser() | User record in aspnet_Users, aspnet_Membership | Unit Test |
| INT-015 | Verify password | Use Membership.ValidateUser() | Password hash verified, bool returned | Unit Test |
| INT-016 | Get user by email | Use Membership.FindUsersByEmail() | User found and returned | Unit Test |
| INT-017 | Get user by username | Use Membership.FindUsersByName() | User found and returned | Unit Test |
| INT-018 | Reset password | Use Membership.GeneratePassword() + ResetPassword() | Password reset, old password no longer valid | Unit Test |
| INT-019 | Lock/unlock user | Attempt N failed logins | User locked after threshold, Admin can unlock | Unit Test |
| INT-020 | Roles assignment | Use Roles.AddUserToRole() | User in aspnet_UsersInRoles | Unit Test |

**Test Infrastructure:**
- Unit test framework (MSTest)
- Mock or real Membership provider
- Test database cleanup between tests

---

## 5. Regression Baseline — Current Behavior Documentation

**Purpose:** Document the current behavior of Phase 1 so that Phase 2 migration can verify nothing changed.

### 5.1 Home Page (`default.aspx`)

| Element | Expected Behavior | Current Status | Verification |
|---------|------------------|-----------------|-------------|
| Page title | "Job Site Starter Kit (Ver.1.0)" | TBD | Browser title/app settings |
| Logo display | Site logo visible (logo.gif/png) | TBD | Visual inspection |
| Navigation menu | JobSeeker, Employer, Admin links | TBD | Master page navigation tree |
| Latest jobs widget | Shows N most recent postings | TBD | LatestJobs.ascx control |
| User display mode | "Welcome, [Username]" or "Login" | TBD | DisplayModeController.ascx |
| Themes | YellowShades theme applied | TBD | CSS/layout inspection |

### 5.2 Job Seeker Pages

| Page | URL | Key Features | Expected Behavior |
|------|-----|--------------|-------------------|
| Job Search | `/jobseeker/jobsearch.aspx` | Keyword search, location filter, pagination | Displays paginated job listings, filters work |
| View Job | `/jobseeker/viewjobposting.aspx` | Full job detail, company profile link | Shows complete job description |
| Post Resume | `/jobseeker/postresume.aspx` | Resume form, file upload | Resume saved, retrievable |
| My Favorites | `/jobseeker/MyFavorites.aspx` | List saved jobs | Shows jobs marked as favorite |
| View Company | `/jobseeker/viewcompanyprofile.aspx` | Company info from company profile | Shows company details |

### 5.3 Employer Pages

| Page | URL | Key Features | Expected Behavior |
|------|-----|--------------|-------------------|
| Job Postings | `/employer/jobpostings.aspx` | List, create, edit, delete | CRUD operations on postings |
| Add/Edit Posting | `/employer/AddEditPosting.aspx` | Job form | Form saves to database |
| Resume Search | `/employer/resumesearch.aspx` | Search resumes by skills | Filters resumes by criteria |
| View Resume | `/employer/viewresume.aspx` | Candidate resume display | Shows full resume |
| Company Profile | `/employer/companyprofile.aspx` | Edit company info | Saves company data |
| My Favorites | `/employer/MyFavorites.aspx` | Saved resumes | Shows bookmarked resumes |

### 5.4 Admin Pages

| Page | URL | Key Features | Expected Behavior |
|------|-----|--------------|-------------------|
| Education Levels | `/Admin/EducationLevelsManager.aspx` | CRUD on lookup data | Add/edit/delete education levels |
| Experience Levels | `/Admin/ExperienceLevelManager.aspx` | CRUD on lookup data | Add/edit/delete experience levels |

### 5.5 Authentication Pages

| Page | URL | Expected Behavior |
|------|-----|-------------------|
| Login | `/login.aspx` | User authentication, role-based redirect |
| Register | `/register.aspx` | New user registration, default role assignment |
| Change Password | `/changepassword.aspx` | Password change for authenticated users |
| Custom Error | `/customerrorpage.aspx` | Error display for handled exceptions |
| Not Authorized | `/CustomErrorPages/NotAuthorized.aspx` | 403 Forbidden display |

### 5.6 Database Behavior

| Component | Expected Behavior | Baseline Status |
|-----------|------------------|-----------------|
| Connection string | Reads from Web.config key "connectionstring" | TBD |
| Membership tables | ASP.NET Membership tables auto-created | TBD |
| Stored procedures | All 150+ procedures callable without errors | TBD |
| Seed data | Countries, states, education levels populated | TBD |
| Transaction support | Long-running queries don't timeout | TBD |
| Error handling | Database errors logged, user sees friendly message | TBD |

### 5.7 Performance Baseline (Reference)

| Metric | Target | Baseline | Notes |
|--------|--------|----------|-------|
| Home page load | < 2 sec | TBD | Measured on local machine |
| Job search (1000 results) | < 5 sec | TBD | Including pagination |
| User registration | < 1 sec | TBD | Create user + role |
| Login | < 1 sec | TBD | Authentication check |

---

## 6. Test Infrastructure

### 6.1 Test Framework Selection

**Recommended:**
- **Build Tests:** MSBuild / CI Pipeline (GitHub Actions or Azure Pipelines)
- **Database Tests:** T-SQL scripts + PowerShell validation
- **Unit Tests:** MSTest (built into Visual Studio)
- **Integration Tests:** xUnit with Testcontainers for SQL Server
- **Smoke/UI Tests:** Selenium WebDriver (C#) or Cypress (optional)

**Alternative:**
- NUnit instead of xUnit
- Playwright instead of Selenium
- Docker SQL Server instead of LocalDB

### 6.2 Test Database Strategy

**Option A: LocalDB (Development)**
```
Server=(localdb)\mssqllocaldb
Database=JobsDB_Test
```
- Lightweight, no SQL Server licensing
- Suitable for local development
- Limited to Windows

**Option B: Docker SQL Server (CI/CD)**
```
Server=tcp:localhost,1433
Database=JobsDB_Test
```
- Reproducible across all machines
- Works on Windows/Linux/Mac
- Better for CI/CD pipelines
- See `infrastructure/` for Docker setup

**Option C: SQL Server Express (Full Testing)**
```
Server=.
Database=JobsDB_Test
```
- Full SQL Server features
- Suitable for comprehensive testing
- Requires licensing

**Selected:** Docker SQL Server for CI/CD, LocalDB for developer machines.

### 6.3 Test Data Management

**Seed Data:**
- Use `database/JobsDB/Scripts/RunAll_SeedData.sql` for baseline
- Reference data (countries, states, education levels) always present

**Test-Specific Data:**
- Create isolated test users with prefix `test_`
- Use transaction rollback for cleanup (if possible)
- Or: Fresh database per test run

**Cleanup Strategy:**
```
-- Delete test-created data
DELETE FROM aspnet_Users WHERE UserName LIKE 'test_%'
DELETE FROM JobsDb_JobPostings WHERE CreatedBy LIKE 'test_%'
-- Reseed identity columns if needed
DBCC CHECKIDENT (table_name, RESEED, seed_value)
```

### 6.4 CI/CD Integration

**GitHub Actions Workflow (Example):**

```yaml
name: Phase 1 Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      
      # 1. Build verification
      - name: Build solution
        run: msbuild phase1-legacy-baseline/appV1.5-buildable/JobsSiteWeb.csproj
      
      # 2. Build DACPAC
      - name: Build database
        run: msbuild phase1-legacy-baseline/../database/JobsDB/JobsDB.sqlproj
      
      # 3. Start SQL Server Docker
      - name: Start SQL Server
        run: docker run -d -p 1433:1433 -e SA_PASSWORD=YourPassword mcr.microsoft.com/mssql/server:latest
      
      # 4. Deploy DACPAC
      - name: Deploy database
        run: |
          sqlpackage /Action:Publish /SourceFile:database/JobsDB/bin/Debug/JobsDB.dacpac /TargetServerName:localhost /TargetDatabaseName:JobsDB_CI
      
      # 5. Run integration tests
      - name: Integration tests
        run: dotnet test tests/Integration.Tests.csproj
```

### 6.5 Test Environment Configuration

**Web.config for testing:**
```xml
<connectionStrings>
  <add name="connectionstring" 
       connectionString="Server=localhost;Database=JobsDB_Test;User ID=sa;Password=YourPassword;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**appsettings.json (if migrating to Core):**
```json
{
  "ConnectionStrings": {
    "JobsDb": "Server=localhost;Database=JobsDB_Test;..."
  }
}
```

### 6.6 Logging & Diagnostics

**For debugging test failures:**
- Enable SQL Profiler to trace executed queries
- Capture IIS Express logs: `%USERPROFILE%\Documents\IISExpress\TraceLogFiles\`
- Use Application Insights for production diagnostics
- Web.config `<customErrors>` set to `Off` in test environments

---

## 7. Execution Plan

### Phase 1a: Manual Baseline (Week 1)
1. **Developer:** Build solution locally, verify compilation
2. **QA:** Smoke test the app (startup, browse jobs, login)
3. **DBA:** Deploy DACPAC, verify schema, load seed data
4. **Team:** Document current behavior in Section 5 above

### Phase 1b: Automated Tests (Week 2-3)
1. **CI/CD:** Set up MSBuild in GitHub Actions
2. **QA:** Create Selenium smoke tests (home page, job search, login)
3. **Dev:** Create MSTest integration tests (database connectivity, stored procedures)
4. **QA:** Document test execution results

### Phase 1c: Baseline Lock (Week 4)
1. **Team:** Review and approve baseline behavior document
2. **QA:** Generate test coverage report
3. **Scribe:** Update Phase 1 README with test status
4. **Team:** Approve Phase 1 complete, ready for Phase 2

---

## 8. Success Criteria

### Build & Deployment
- ✅ Solution compiles without errors in Debug and Release
- ✅ DACPAC builds successfully
- ✅ DACPAC deploys to LocalDB and SQL Server
- ✅ All 22 tables created with correct schema
- ✅ All ~150 stored procedures present and callable
- ✅ Seed data loads without conflicts

### Functional
- ✅ App starts without unhandled exceptions
- ✅ Home page renders with theme applied
- ✅ Job search works and returns results
- ✅ User registration and login work
- ✅ Membership roles enforced (JobSeeker, Employer, Admin)
- ✅ Admin pages restrict access to non-admins

### Data Integrity
- ✅ Database connections do not timeout
- ✅ Query results match expected data types
- ✅ Null values handled gracefully
- ✅ No orphaned records or referential integrity violations

### Non-Functional
- ✅ Home page loads in < 2 seconds
- ✅ Job search on 1000 results completes in < 5 seconds
- ✅ No memory leaks during extended testing
- ✅ Error messages logged but not exposed to users

---

## 9. Known Limitations & Future Work

### Current Phase 1 Limitations
- No automated UI tests yet (manual smoke tests only)
- Database tests require T-SQL expertise
- Connection strings hard-coded in Web.config (address in Phase 2)
- No load testing (out of scope)
- No security testing (e.g., SQL injection, XSS) — Phase 3 concern

### Future Enhancements (Phase 2+)
- Add Selenium tests for all user workflows
- Containerize SQL Server for consistent test environments
- Add performance benchmarks (baseline for Phase 2 migration)
- Add security testing (OWASP Top 10)
- Add accessibility testing (WCAG 2.1)
- Migrate to modern test framework (Playwright, xUnit)

---

## 10. Test Artifacts & Reporting

### Artifacts to Maintain
- `phase1-legacy-baseline/tests/` — Test code (MSTest, integration tests)
- `phase1-legacy-baseline/test-results/` — JUnit XML reports
- `phase1-legacy-baseline/test-data/` — SQL scripts for test setup
- `.github/workflows/phase1-tests.yml` — CI/CD configuration

### Test Reports
- **Build Report:** Compilation time, warnings, errors
- **Database Report:** Schema validation, stored procedure count, seed data load time
- **Test Coverage:** Line/branch coverage for C# code (target: > 60% for Phase 1)
- **Regression Report:** Baseline vs. current behavior (for Phase 2 comparison)

---

## 11. Appendix: Connection Strings

### Development (Local)
```
Data Source=(localdb)\mssqllocaldb;Initial Catalog=JobsDB;Integrated Security=True;
```

### Testing (Docker)
```
Server=tcp:localhost,1433;Database=JobsDB_Test;User ID=sa;Password=YourPassword;
```

### Production (Phase 2 - Azure)
```
Server=tcp:{server}.database.windows.net;Database=JobsDB;User ID={user};Password={password};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;
```

---

## 12. References

- **Project Repository:** `phase1-legacy-baseline/`
- **Database Project:** `database/JobsDB/`
- **Infrastructure:** `infrastructure/` (Docker, IaC)
- **Related Plans:** `phase2-azure-migration/`, `phase3-modernization/`
- **MSTest Documentation:** https://docs.microsoft.com/en-us/visualstudio/test/unit-test-your-code
- **xUnit.net:** https://xunit.net/
- **Selenium WebDriver:** https://www.selenium.dev/
- **SQL Server Stored Procedures:** https://docs.microsoft.com/en-us/sql/relational-databases/stored-procedures/stored-procedures-database-engine

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-27  
**Owner:** Mouse (Tester)  
**Status:** Draft — Awaiting team approval for Phase 1a execution
