# Phase 1 Deployment Plan: Legacy Baseline

**Status:** Phase 1 Learning Module  
**Target:** Get legacy .NET 4.8 Web Forms app (`appV1.5-buildable`) running locally and verified  
**Scope:** Local development setup and Azure PaaS preview  
**Learning Value:** Understanding legacy architecture constraints and deployment patterns  

---

## Part 1: Local Development Setup

### Prerequisites

Before you can build and run the application locally, install these tools:

#### Required Tools
| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **.NET Framework** | 4.8 | Runtime for Web Forms app | Windows Update or [Direct Download](https://dotnet.microsoft.com/download/dotnet-framework) |
| **Visual Studio** | 2022 (or 2019) | IDE for building .NET Framework projects | [Community Edition](https://visualstudio.microsoft.com/vs/community/) |
| **SQL Server LocalDB** | 2019+ | Local database engine | VS Installer: `Desktop development with C++` → SQL Server tools |
| **SQL Server Management Studio** | Latest | Database administration | [Free Download](https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) |

#### Recommended
- **Git** — Version control (if not already installed)
- **PowerShell 7+** — For deployment scripts
- **Azure CLI** — For Phase 2 Azure deployment (optional for Phase 1)

### Verify Installation

```powershell
# Check .NET Framework (Windows)
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release

# Check SQL Server LocalDB instances
sqllocaldb info

# Create LocalDB instance if needed
sqllocaldb create JobsLocalDb
sqllocaldb start JobsLocalDb
```

---

## Part 2: Building appV1.5-buildable

### Step 1: Restore NuGet Packages

The project uses a legacy `packages.config` file (not modern PackageReference format).

```powershell
# Navigate to the app directory
cd phase1-legacy-baseline\appV1.5-buildable

# Option A: Using Visual Studio (recommended for .NET Framework)
# Open in Visual Studio 2022 → Build → Clean Solution → Build Solution

# Option B: Using NuGet CLI
nuget restore

# Option C: Using MSBuild with integrated NuGet restore
msbuild JobsSiteWeb.csproj /t:Restore
```

**Expected:** All packages restore without errors. Check `packages/` folder is populated.

### Step 2: Build with MSBuild

```powershell
# MSBuild (requires VS Build Tools or Visual Studio)
msbuild JobsSiteWeb.csproj /p:Configuration=Debug /p:Platform=AnyCPU

# Or via Visual Studio Command Prompt
# (VS provides "Developer Command Prompt" with MSBuild in PATH)
```

**Expected Output:**
```
Build succeeded.
0 Error(s), 0 Warning(s)
Time Elapsed 00:00:XX
```

**Troubleshooting:**
- **"Microsoft.CodeDom.Providers.DotNetCompilerPlatform not found"** → Run `nuget restore` first
- **"Project file format not recognized"** → Ensure you're using Visual Studio 2015+ (SDK-style projects)
- **"Assembly version conflicts"** → Check `packages.config` for duplicate entries

### Step 3: Verify Build Artifacts

```powershell
# Check build output
dir bin\Debug\

# Expected files:
# - JobsSiteWeb.dll
# - JobsSiteWeb.pdb
# - *.dll (all dependencies from packages/)
```

---

## Part 3: Database Setup

### Step 1: Create LocalDB Instance

```powershell
# List existing instances
sqllocaldb info

# Create named instance (if not exists)
sqllocaldb create JobsLocalDb
sqllocaldb start JobsLocalDb

# Verify it's running
sqllocaldb info JobsLocalDb
```

### Step 2: Deploy Database Schema

The database project (`database/JobsDB/`) uses SQL Server Data Tools (SSDT) format (`.sqlproj`).

#### Option A: Visual Studio SSDT Deployment (Recommended)

```powershell
# Open Visual Studio
# Navigate to database/JobsDB/JobsDB.sqlproj
# Right-click project → Publish...
# Configure settings:
#   - Database name: JobsDB
#   - Server: (localdb)\JobsLocalDb
#   - Always create/update schema
# Click Publish
```

**Result:** Database schema created in LocalDB instance.

#### Option B: Command-Line DACPAC Deployment

SSDT projects export to `.dacpac` files (Data-tier Application packages).

```powershell
# Build the database project to generate DACPAC
msbuild database/JobsDB/JobsDB.sqlproj /p:Configuration=Debug

# Publish DACPAC using SqlPackage.exe
# (Installed with SSMS or VS)
SqlPackage.exe /Action:Publish `
  /SourceFile:database/JobsDB/bin/Debug/JobsDB.dacpac `
  /TargetConnectionString:"Server=(localdb)\JobsLocalDb;Database=JobsDB;Integrated Security=true;" `
  /p:CreateNewDatabase=true

# Verify
sqlcmd -S "(localdb)\JobsLocalDb" -Q "SELECT name FROM sys.databases WHERE name='JobsDB'"
```

### Step 3: Load Seed Data

The database includes seed data scripts:

```powershell
# Connect to JobsDB
sqlcmd -S "(localdb)\JobsLocalDb" -d "JobsDB"

# Run seed scripts (in order)
:r database/JobsDB/01_SeedCountries.sql
:r database/JobsDB/02_SeedStates.sql
:r database/JobsDB/03_SeedEducationLevels.sql
:r database/JobsDB/04_SeedJobTypes.sql

# Or run the combined script:
:r database/JobsDB/RunAll_SeedData.sql

# Verify
SELECT COUNT(*) as TableCount FROM information_schema.tables WHERE table_type='BASE TABLE'
GO
```

### Step 4: Update Connection Strings

The app's `Web.config` contains hardcoded paths. Update to point to LocalDB:

**File:** `phase1-legacy-baseline/appV1.5-buildable/Web.config`

**Current (hardcoded):**
```xml
<add name="connectionstring" connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=C:\GIT\APPMIGRATIONWORKSHOP\SHARED\SOURCEAPPS\APPS\JOBS\APP_DATA\JSSKDB.MDF;..." />
```

**Update to:**
```xml
<add name="connectionstring" connectionString="Data Source=(localdb)\JobsLocalDb;Initial Catalog=JobsDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;TrustServerCertificate=False;" />
<add name="MyProviderConnectionString" connectionString="Data Source=(localdb)\JobsLocalDb;Initial Catalog=JobsDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;TrustServerCertificate=False;" />
```

**Why Two Strings?** The app uses ASP.NET Membership provider (second connection string).

---

## Part 4: Running Locally

### Option A: IIS Express (Recommended for Web Forms)

```powershell
# Open in Visual Studio
# Press F5 (Debug) or Ctrl+F5 (Release without debugging)

# Or launch via command line:
cd phase1-legacy-baseline\appV1.5-buildable
"C:\Program Files\IIS Express\iisexpress.exe" /path:. /port:8080
```

**Expected:**
- IIS Express starts
- Browser opens to `http://localhost:8080`
- Login page displays (or default.aspx)

### Option B: Full IIS (Windows Server / Production-like)

1. **Install IIS Feature** (Windows)
   ```powershell
   Enable-WindowsOptionalFeature -FeatureName IIS-WebServer -Online
   ```

2. **Create Application Pool**
   ```powershell
   # Open IIS Manager (inetmgr)
   # Create app pool:
   #   Name: JobsiteAppPool
   #   .NET CLR version: 4.0
   #   Managed pipeline mode: Integrated
   ```

3. **Create Site**
   ```
   Site Name: JobSite
   Physical path: F:\Git\jobs_modernization\phase1-legacy-baseline\appV1.5-buildable
   Binding: http | localhost | 80
   ```

4. **Test**
   ```
   http://localhost/
   ```

### Smoke Test Checklist

Once the app is running, verify core functionality:

- [ ] **Home Page Loads** — No 500 errors
- [ ] **Database Connected** — App can query database (check app logs)
- [ ] **Login Page Works** — `/login.aspx` loads without error
- [ ] **CSS/Images Load** — No 404s in browser console
- [ ] **Master Page Renders** — Navigation and footer visible
- [ ] **Default Theme Applied** — "YellowShades" theme CSS loads

**Check Logs:**
```powershell
# Event Viewer (Windows)
eventvwr.msc

# IIS Express logs
dir %LOCALAPPDATA%\IIS Express\Logs\

# Application logs (if configured)
dir phase1-legacy-baseline\appV1.5-buildable\App_Data\logs\
```

---

## Part 5: Troubleshooting Common Issues

### Build Failures

| Error | Cause | Solution |
|-------|-------|----------|
| "Missing assembly `Microsoft.CodeDom.Providers...`" | NuGet restore incomplete | Run `nuget restore` from app directory |
| "TargetFrameworkVersion '4.8' not found" | .NET Framework 4.8 not installed | Install via Windows Update or [Direct Download](https://dotnet.microsoft.com/download/dotnet-framework) |
| "ASPX file not recognized" | Wrong Visual Studio version | Use VS 2015+ (SDK-style project support) |

### Database Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Login failed for user" (SQL Server) | Connection string wrong | Verify LocalDB instance name and database name |
| "Cannot attach database file (`.mdf`)" | Old connection string points to hardcoded path | Update `Web.config` connection strings |
| "Database does not exist" | DACPAC publish failed | Verify SQL Server LocalDB is running: `sqllocaldb start JobsLocalDb` |

### Runtime Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Assembly binding failure" | NuGet packages not restored | Clean and rebuild solution |
| "HTTP Error 500" on page load | Missing master page or code-behind error | Check IIS logs and Event Viewer |
| "Session state database error" | ASP.NET session table not created | DACPAC deploy includes session schema—verify publish completed |

---

## Part 6: Azure Deployment Preview (Phase 2)

This section outlines what happens in Phase 2 when moving to Azure. **No action needed for Phase 1.**

### Target Architecture

```
┌─────────────────────────────────────────┐
│         Azure Subscription              │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    App Service (PaaS)            │  │
│  │  - Hosting Plan: S1 or B1        │  │
│  │  - .NET Framework 4.8            │  │
│  │  - System Assigned Identity      │  │
│  └──────────────────────────────────┘  │
│            ↓ (connects to)              │
│  ┌──────────────────────────────────┐  │
│  │    Azure SQL Database            │  │
│  │  - Edition: Standard/Basic       │  │
│  │  - Firewall rules to App Service │  │
│  │  - Point-in-time restore enabled │  │
│  └──────────────────────────────────┘  │
│                                         │
│  Supporting Services:                   │
│  - Key Vault (secrets)                  │
│  - Application Insights (monitoring)    │
│  - Log Analytics (logs)                 │
│                                         │
└─────────────────────────────────────────┘
```

### Bicep Templates Used

**Location:** `infrastructure/bicep/paas/`

| Template | Purpose |
|----------|---------|
| `main.bicep` | Subscription-scoped entry point; creates resource group |
| `paas-resources.bicep` | Deploys App Service, App Service Plan, SQL Server, SQL Database, App Insights |

**Key Parameters:**
```bicep
param environment string = 'dev'                    // dev/staging/prod
param applicationName string = 'jobsite'            // Resource name prefix
param location string = 'swedencentral'             // Azure region
param appServiceSku string = 'S1'                   // Pricing tier (B1 for dev, S1+ for prod)
param sqlDatabaseEdition string = 'Standard'        // SQL tier
param sqlServiceObjective string = 'S1'             // SQL performance
param sqlAadAdminObjectId string                    // Azure AD admin (for RBAC)
```

### Deployment Steps (Phase 2)

```powershell
# 1. Deploy Core Infrastructure (networking, Key Vault)
az deployment sub create `
  --template-file infrastructure/bicep/core/main.bicep `
  --parameters environment=dev location=swedencentral `
  --name core-infrastructure-deploy

# 2. Deploy PaaS Infrastructure
az deployment sub create `
  --template-file infrastructure/bicep/paas/main.bicep `
  --parameters `
    environment=dev `
    applicationName=jobsite `
    location=swedencentral `
    appServiceSku=S1 `
    sqlAadAdminObjectId={YOUR_AAD_OBJECT_ID} `
    sqlAadAdminName={YOUR_AAD_USER_EMAIL} `
  --name paas-infrastructure-deploy

# 3. Get App Service deployment credentials
az webapp deployment user set --user-name {USERNAME} --password {PASSWORD}

# 4. Deploy the app (Web Deploy or Git)
# TODO: Detailed CI/CD pipeline instructions in Phase 2 plan
```

### Database Migration: Local → Azure SQL

```powershell
# Export LocalDB database as BACPAC
SqlPackage.exe /Action:Export `
  /SourceConnectionString:"Server=(localdb)\JobsLocalDb;Database=JobsDB;Integrated Security=true;" `
  /TargetFile:JobsDB.bacpac

# Import to Azure SQL (using Azure Portal or Azure CLI)
az sql db import `
  --resource-group jobsite-paas-dev-rg `
  --server {SQL_SERVER_NAME} `
  --name JobsDB `
  --admin-user {SQL_ADMIN} `
  --admin-password {SQL_PASSWORD} `
  --file-key {STORAGE_ACCOUNT_KEY} `
  --file-path "https://{storage}.blob.core.windows.net/{container}/JobsDB.bacpac"
```

### Connection String Management (Phase 2)

**In Azure App Service Configuration:**

```json
{
  "connectionstring": "Server=tcp:jobsite-sql-dev-xyz.database.windows.net;Database=JobsDB;User ID={SQL_USER};Password={SQL_PASSWORD};Encrypt=true;",
  "MyProviderConnectionString": "Server=tcp:jobsite-sql-dev-xyz.database.windows.net;Database=JobsDB;User ID={SQL_USER};Password={SQL_PASSWORD};Encrypt=true;"
}
```

**Security:** Store passwords in Azure Key Vault, not in app settings (reference via `@Microsoft.KeyVault(SecretUri=...)`).

---

## Success Criteria: How to Know Phase 1 is Complete

| Criterion | Verification |
|-----------|--------------|
| **App Builds Without Error** | `msbuild JobsSiteWeb.csproj` succeeds with 0 errors |
| **Database Deploys** | `JobsDB` exists in LocalDB with all tables and stored procedures |
| **App Runs Locally** | IIS Express or IIS serves the app on localhost |
| **Homepage Loads** | `http://localhost:8080/` or `http://localhost/` displays without 500 error |
| **Master Page Works** | Navigation, header, footer render correctly (YellowShades theme visible) |
| **Database Connected** | App can query database (pages that fetch job listings, company profiles work) |
| **Login Flow Accessible** | `/login.aspx` page loads; form renders |
| **CSS/Images Render** | No 404 errors in browser dev tools console |

### Running the Full Verification Suite

```powershell
# Build
msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /p:Configuration=Debug

# Verify artifacts
if ((Test-Path "phase1-legacy-baseline\appV1.5-buildable\bin\Debug\JobsSiteWeb.dll")) {
    Write-Host "✓ Build artifact exists"
} else {
    Write-Host "✗ Build failed"
    exit 1
}

# Verify database
sqlcmd -S "(localdb)\JobsLocalDb" -d "JobsDB" -Q "SELECT COUNT(*) as TableCount FROM information_schema.tables WHERE table_type='BASE TABLE'"
# Expected: TableCount should be > 10 (tables created by DACPAC)

# Start IIS Express and hit homepage
# http://localhost:8080/default.aspx
# Verify HTTP 200, master page renders, no 500 errors in logs
```

---

## Known Blockers & Risks

### Critical Blockers (Must Fix Before Phase 1 Complete)

1. **App Won't Build**
   - **Root Cause:** Missing NuGet packages or .NET Framework 4.8 not installed
   - **Impact:** Can't proceed to runtime testing
   - **Mitigation:** Follow NuGet restore and prerequisite verification steps above

2. **Database Won't Deploy**
   - **Root Cause:** SQL Server LocalDB not installed or DACPAC publish fails
   - **Impact:** App can't connect to database; 500 errors on data-driven pages
   - **Mitigation:** Verify LocalDB instance, check DACPAC publish logs, rebuild database project

3. **Connection String Mismatch**
   - **Root Cause:** `Web.config` still hardcoded to old path (e.g., `C:\GIT\APPMIGRATIONWORKSHOP\...`)
   - **Impact:** Database connection fails at runtime
   - **Mitigation:** Update both `connectionstring` and `MyProviderConnectionString` in `Web.config`

### Medium-Risk Issues (Plan Workarounds)

| Issue | Likelihood | Impact | Workaround |
|-------|------------|--------|-----------|
| IIS Express port 8080 already in use | Medium | Can't start app | Use `iisexpress /port:9090` |
| ASP.NET session database not created | Low | Session state fails | Included in DACPAC publish; verify if you see "Session expired" errors |
| .mdf file lock on older projects | Low | Can't rebuild database | Use SQL Server Management Studio to detach before rebuild |

### Lessons from appV1-original

The original app (`appV1-original/`) demonstrates issues that appV1.5 fixes:

| Issue | appV1 (Original) | appV1.5 (Fixed) | Learning |
|-------|-----------------|-----------------|----------|
| Solution File | Missing | Included | Essential for modern builds |
| Master Page | Ad-hoc includes | Proper master pages | Web Forms best practice |
| Connection Strings | Hardcoded in code | In Web.config | Configuration management |
| Project Format | Old web project format | SDK-style .csproj | Modern tooling support |
| NuGet Restore | Manual | Automated via build | Dependency management |

---

## Deployment Artifacts & Documentation

### Files Created During This Phase

```
phase1-legacy-baseline/
├── DEPLOYMENT_PLAN.md (this file)
├── appV1.5-buildable/
│   ├── bin/Debug/
│   │   ├── JobsSiteWeb.dll (build artifact)
│   │   └── JobsSiteWeb.pdb (debug symbols)
│   └── Web.config (updated with LocalDB connection string)
└── docs/
    └── CODE_ANALYSIS_REPORT.md (already exists; technical debt analysis)

database/
├── JobsDB/
│   └── bin/Debug/
│       └── JobsDB.dacpac (deployment artifact)
└── README.md

infrastructure/
└── bicep/paas/
    ├── main.bicep (Phase 2 PaaS template)
    └── paas-resources.bicep (resource definitions)
```

### Key Paths for Reference

| Item | Path | Purpose |
|------|------|---------|
| **Source App** | `phase1-legacy-baseline/appV1.5-buildable/` | Deploy-ready code |
| **Reference App** | `phase1-legacy-baseline/appV1-original/` | Study original architecture |
| **Database Project** | `database/JobsDB/` | Schema and seed data |
| **PaaS Templates** | `infrastructure/bicep/paas/` | Phase 2 Azure deployment |
| **Architecture Docs** | `infrastructure/README.md` | Infrastructure overview |
| **Phase 1 README** | `phase1-legacy-baseline/README.md` | Phase context |

---

## Phase 1 → Phase 2 Transition Checklist

When Phase 1 is complete and verified, you're ready for Phase 2 (Azure Migration):

- [ ] App builds successfully locally
- [ ] Database deploys to LocalDB without errors
- [ ] App runs on IIS Express/IIS with all pages loading
- [ ] Database queries work (no connection errors)
- [ ] All smoke tests pass (see "Success Criteria" above)
- [ ] Connection string updated to point to LocalDB
- [ ] No hardcoded paths in configuration files
- [ ] Documentation matches actual deployment (this file is accurate)

**Next:** Phase 2 involves deploying the same app to Azure App Service + Azure SQL Database with minimal code changes. The Bicep templates in `infrastructure/bicep/paas/` provide the infrastructure; a separate CI/CD guide will detail the automated deployment pipeline.

---

## Related Documentation

- **[Phase 1 README](./README.md)** — Phase context and learning journey
- **[Code Analysis Report](./docs/CODE_ANALYSIS_REPORT.md)** — Technical debt and architecture notes
- **[appV1-original Reference](./appV1-original/)** — Original code for comparison
- **[Database README](../database/README.md)** — Database schema and usage
- **[Infrastructure README](../infrastructure/README.md)** — Infrastructure overview and 4-layer strategy
- **[Phase 2 Plan](../phase2-azure-migration/)** — Azure migration guide (coming next)

---

## Quick Reference: Essential Commands

```powershell
# ========== BUILD ==========
# Restore NuGet packages
nuget restore phase1-legacy-baseline\appV1.5-buildable\

# Build with MSBuild
msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /p:Configuration=Debug

# ========== DATABASE ==========
# Start LocalDB instance
sqllocaldb start JobsLocalDb

# Deploy database (via DACPAC)
SqlPackage.exe /Action:Publish `
  /SourceFile:database\JobsDB\bin\Debug\JobsDB.dacpac `
  /TargetConnectionString:"Server=(localdb)\JobsLocalDb;Database=JobsDB;Integrated Security=true;" `
  /p:CreateNewDatabase=true

# ========== RUN LOCALLY ==========
# Via IIS Express (from app directory)
"C:\Program Files\IIS Express\iisexpress.exe" /path:. /port:8080

# ========== VERIFY ==========
# Check LocalDB databases
sqlcmd -S "(localdb)\JobsLocalDb" -Q "SELECT name FROM sys.databases"

# Check job site database tables
sqlcmd -S "(localdb)\JobsLocalDb" -d "JobsDB" -Q "SELECT COUNT(*) FROM information_schema.tables"
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-27  
**Author:** Morpheus (Lead)  
**Status:** Phase 1 Deployment Plan — Ready for Implementation
