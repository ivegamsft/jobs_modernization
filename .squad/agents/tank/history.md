# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-28: Deployment Blockers Fixed — Dozer Completes Infrastructure Validation

**Cross-Agent Context Update**

Dozer (DevOps) has completed all 6 deployment blockers. Tank should be aware of these infrastructure changes for CI/CD integration:

**Infrastructure Changes:**
- All 10 CI/CD pipelines updated from `iac/` → `infrastructure/` paths
- Bicep templates now compile without errors (agents/main.bicep duplicate removed)
- VNet references parameterized (iaas/agents layers receive `coreVnetName` parameter)
- Key Vault defaults to deny-by-default (security improvement)
- Container Apps subnet delegation added (required for deployment)

**For Tank's Runtime Testing:**
- CI/CD pipelines are now pipeline-ready with correct paths
- Build command output goes to `bin\JobsSiteWeb.dll` — ready for deployment scripts
- Deployment infrastructure is unblocked; can proceed with IIS Express testing

**Related:** `.squad/decisions.md` — "2026-02-28: Deployment Blocker Fixes"



**Context:** Morpheus (Lead) and Mouse (Tester) completed Phase 1 planning in parallel. These artifacts define the execution path for appV1.5 buildability validation.

**Deployment Plan (Morpheus):** `phase1-legacy-baseline/DEPLOYMENT_PLAN.md` (22KB)
- **Prerequisites:** .NET Framework 4.8, VS 2022, SQL Server LocalDB
- **Build path:** NuGet restore → MSBuild command-line (packages.config era)
- **Database:** DACPAC deployment to `(localdb)\JobsLocalDb` instance
- **Local run:** IIS Express (dev) or full IIS (production-like)
- **Smoke tests:** 9-point checklist (HTTP 200 + DB + master page)
- **Blockers addressed:** Build failures (NuGet), DB deployment (DACPAC), connection strings
- **Key path:** `phase1-legacy-baseline/appV1.5-buildable/`
- **DB path:** `database/JobsDB/` (DACPAC project)

**Test Plan (Mouse):** `phase1-legacy-baseline/TEST_PLAN.md` (27KB)
- **6 test categories:** Build (5), Database (17), Smoke (24), Integration (20), Regression baseline, Infrastructure
- **CI/CD:** GitHub Actions + MSBuild + PowerShell + xUnit
- **Database strategy:** Docker SQL Server (CI), LocalDB (dev)
- **Phase 1 success criteria:** Compiles, 22 tables created, ~150 sprocs callable, app runs, user flows work, baseline documented
- **Timeline:** Week 1 (manual testing), Week 2-3 (automation), Week 4 (approval)

**Impact on This Agent:**
- Tank's appV1.5 build validation aligns with Morpheus's deployment plan
- Test execution follows Mouse's test framework (MSTest + xUnit)
- Both plans assume **appV1.5 buildability is currently untested** (critical blocker)
- Build output should feed into Test Plan's "Build Verification" section (5 tests)

**Key Decisions Reflected in Plans:**
1. **LocalDB instance naming:** `(localdb)\JobsLocalDb` (standard across team)
2. **DACPAC deployment:** SSDT format (native to SQL Server)
3. **Dual connection strings:** App data + ASP.NET Membership (legacy constraint)
4. **IIS Express default:** Zero setup, good for learning
5. **BACPAC for Phase 2:** LocalDB → Azure SQL migration strategy

**What This Means for Tank's Work:**
- Build validation output should match deployment plan prerequisites
- Any blockers found should be added to plan's troubleshooting matrix
- Success = proof that appV1.5 builds, runs locally, queries database
- Failures = learning opportunity, document in decision inbox

**Related Artifacts:**
- Phase 1 Deployment Plan: `phase1-legacy-baseline/DEPLOYMENT_PLAN.md`
- Phase 1 Test Plan: `phase1-legacy-baseline/TEST_PLAN.md`
- Decisions merged: `.squad/decisions.md` (search for "deployment-plan" and "testing-strategy")

**Status:** ✅ Deployment & test plans complete; awaiting Tank's build validation results

### 2026-02-27: Repository Reorganized — Three-Phase Learning Journey

**Context:** Team orchestration complete. Repository structure now maps the modernization learning journey. All agents synchronized.

**What Changed:**
- Repository restructured from loose files + ambiguous app versions into clear three-phase structure
- **phase1-legacy-baseline/** — Get legacy .NET 2.0 app running (appV1-original reference, appV1.5-buildable working version)
- **phase2-azure-migration/** — Host on Azure PaaS with minimal code changes
- **phase3-modernization/** — Modern API (api-dotnet, api-python) + React UI alongside legacy
- **infrastructure/** — All IaC consolidated (Bicep, Terraform, scripts, 9 docs)
- **database/** — Schema, seed data (lowercase)
- **specs/** — Spec-kit specifications

**For This Agent:**
- All folder references in work should use new structure
- Infrastructure code/docs now in `infrastructure/` (not `iac/`)
- Database assets in `database/` (not `Database/`)
- See `.squad/decisions.md` for complete decision log

**Status:** ✅ Repository ready for Phase 1 work

### 2026-02-28: appV1.5 Build Fixed — Web Site → WAP Migration Completed

**Context:** The critical Phase 1 blocker — nobody had verified appV1.5 actually builds. Investigated and found the Web Site → Web Application Project migration was incomplete (232 compile errors).

**Root Causes Found & Fixed:**
1. **App_Code files as Content, not Compile** — 12 BOL/DAL files in .csproj were `<Content>` instead of `<Compile>`. The `JobSiteStarterKit` namespace classes weren't being compiled into the assembly.
2. **Missing .designer.cs files** — 28 pages/controls had no designer files. WAP needs these to declare server control fields. Generated them by parsing ASPX markup.
3. **Missing ProfileCommon class** — Web Site projects auto-generate typed profile class from Web.config. Created `ProfileCommon.cs` + `BasePage.cs` to provide typed Profile access.
4. **Duplicate class name** — employer and jobseeker both had `MyFavorites_aspx`. Renamed employer's to `employer_MyFavorites_aspx`.
5. **Invalid `using ASP;`** — Runtime-only namespace reference in viewresume.aspx.cs.

**Build Command:**
```powershell
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
# One-time: nuget restore JobsSiteWeb.csproj -PackagesDirectory ..\packages
& $msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /t:Build /p:Configuration=Debug
```

**Build Tools Available on This Machine:**
- MSBuild: `C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe`
- dotnet SDK: 10.0.103
- nuget.exe: NOT pre-installed (had to download from nuget.org)
- .NET Framework 4.8 targeting pack: ✅ Present
- WebApplication.targets: ✅ Present at VS 2022 v17.0 path

**Key Files Created:**
- `App_Code/ProfileCommon.cs` — Typed profile matching Web.config `<profile>` definition
- `App_Code/BasePage.cs` — Base page class with typed `Profile` property
- 28 `.designer.cs` files — Server control field declarations for all pages/controls

**Key Files Modified:**
- `JobsSiteWeb.csproj` — App_Code Content→Compile, added designer file references
- `Web.config` — Added `inherits="ProfileCommon"` to profile element
- 6 code-behind files — Changed `: Page` to `: BasePage` for typed Profile access
- `employer/MyFavorites.aspx[.cs]` — Class renamed to fix collision

**Result:** 0 errors, 9 warnings (pre-existing legacy). Both Debug and Release succeed. Output: `bin\JobsSiteWeb.dll` (53KB).

**Remaining Issues (not build-related):**
1. No .sln file exists — build works on .csproj directly
2. ASPX directives use `CodeFile=` (Web Site) not `CodeBehind=` (WAP) — runtime concern
3. Connection strings hardcoded to `C:\GIT\APPMIGRATIONWORKSHOP\...` — need updating
4. Runtime testing needs IIS Express + database setup

**Status:** ✅ appV1.5 builds successfully — Phase 1 blocker removed

### 2026-02-28: Phase 1 Runtime Achieved — appV1.5 Runs on IIS Express + LocalDB

**Context:** Followed up on successful build by doing full runtime preparation — environment check, .sln creation, connection string fix, database deployment, and IIS Express launch.

**Environment Inventory (this machine):**
- MSBuild: `C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe` (v17.14)
- dotnet SDK: 9.0.311, 10.0.103
- LocalDB: ✅ Available (SQL Server 17.0.925.4)
- IIS Express: ✅ Available (both x64 and x86)
- sqlpackage: ✅ `C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\SqlPackage.exe`
- Classic sqlcmd: `C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe`
- Go-based sqlcmd v1.9 (in PATH) — does NOT work with LocalDB pipes; must use classic sqlcmd
- NuGet: ❌ Not in PATH (download manually from nuget.org/downloads)

**What Was Created/Fixed:**

1. **JobsSiteWeb.sln** — Created at `phase1-legacy-baseline/appV1.5-buildable/JobsSiteWeb.sln`
2. **Connection strings** — Changed from hardcoded `(localdb)\MSSQLLocalDB;Initial Catalog=C:\GIT\APPMIGRATIONWORKSHOP\...` to `(localdb)\JobsLocalDb;Initial Catalog=JobsDB`
3. **App_Code → Code rename** — WAP requires this; `App_Code` folder gets double-compiled (build-time DLL + ASP.NET runtime dynamic compilation). Standard WAP migration step.
4. **ProfileCommon → JobSiteProfileBase rename** — ASP.NET auto-generates `class ProfileCommon` from `<profile inherits="...">`. If our class is also named `ProfileCommon`, it creates a circular base class dependency. Renamed to `JobSiteProfileBase` so ASP.NET generates `class ProfileCommon : JobSiteProfileBase`.
5. **Web.config profile properties restored** — The `<properties>` section stays in Web.config alongside `inherits="JobSiteProfileBase"` because ASP.NET needs it to define the profile schema for the SqlProfileProvider.

**Database Deployment:**
- LocalDB instance: `(localdb)\JobsLocalDb` (SQL Server 17.0.925.4)
- Database: `JobsDB` created
- 22 tables deployed (3 required retry due to FK ordering: aspnet_Membership, aspnet_PersonalizationPerUser, aspnet_Profile depend on aspnet_Users)
- 9 views deployed (0 errors)
- 157 stored procedures deployed (0 errors)
- 9 security roles deployed (17 scripts failed — expected for LocalDB limited security model)
- Seed data: ❌ All 5 seed SQL files are EMPTY (0 bytes) — placeholder files with no data
- DACPAC build: ❌ SqlBuildTask fails silently (SSDT MSBuild issue) — deployed via raw SQL scripts instead

**Runtime Test Results:**
- Homepage (`/`): HTTP 200 ✅ — 14,504 chars, job content + search + login/register links
- Login (`/login.aspx`): HTTP 200 ✅ — 18,056 chars
- Register (`/register.aspx`): HTTP 200 ✅ — 17,667 chars
- Default (`/default.aspx`): HTTP 200 ✅ — 14,516 chars
- Welcome (`/Welcome.htm`): HTTP 200 ✅ — 11,839 chars

**IIS Express Launch Command:**
```powershell
& "C:\Program Files\IIS Express\iisexpress.exe" /path:"F:\Git\jobs_modernization\phase1-legacy-baseline\appV1.5-buildable" /port:8088 /clr:v4.0 /systray:false
```

**Remaining Issues:**
1. **Empty seed data** — Countries, States, EducationLevels, JobTypes tables are empty. Dropdowns will show no options. Need actual INSERT statements.
2. **CodeFile vs CodeBehind** — ASPX directives still use `CodeFile=` (Web Site pattern). Pages render but this is technically incorrect for WAP.
3. **No functional testing** — HTTP 200 doesn't mean forms work. Registration/login require database + ASP.NET Membership infrastructure.
4. **DACPAC build broken** — `SqlBuildTask` fails silently. May need SSDT version alignment or manual fix.

**Key Insight:** The Web Site → WAP migration has TWO runtime-critical steps beyond just getting it to compile:
- Rename `App_Code` to anything else (prevents double compilation)
- Avoid naming custom profile class `ProfileCommon` (ASP.NET reserves that name for auto-generation)

**Status:** ✅ appV1.5 runs locally — HTTP 200 on all tested pages
