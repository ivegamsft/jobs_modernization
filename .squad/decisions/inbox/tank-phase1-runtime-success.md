# Phase 1 Runtime Success — appV1.5 Runs Locally

**Decision ID:** phase1-runtime-success-2026-02-28  
**Author:** Tank (Backend Dev)  
**Date:** 2026-02-28  
**Status:** Implemented & Verified  
**Impact:** High (unblocks Phase 1 testing, Phase 2 migration planning)

## Context

Following the successful build fix, this session completed the full runtime preparation: environment validation, solution file creation, connection string fix, database deployment to LocalDB, and IIS Express launch with HTTP smoke testing.

## What Was Done

### Files Created
- `phase1-legacy-baseline/appV1.5-buildable/JobsSiteWeb.sln` — VS solution file referencing JobsSiteWeb.csproj

### Files Modified
- **Web.config** — Connection strings updated from hardcoded workshop paths to `(localdb)\JobsLocalDb;Initial Catalog=JobsDB`. Profile `inherits` changed to `JobSiteProfileBase`.
- **Code/ProfileCommon.cs** (was App_Code) — Class renamed from `ProfileCommon` to `JobSiteProfileBase` to avoid collision with ASP.NET auto-generated class
- **Code/BasePage.cs** — Updated to reference `JobSiteProfileBase`
- **employer/viewresume.aspx.cs** — Updated `ProfileCommon` reference to `JobSiteProfileBase`
- **JobsSiteWeb.csproj** — All `App_Code\` paths changed to `Code\`
- **App_Code folder renamed to Code** — Critical WAP migration step; `App_Code` gets double-compiled at runtime

### Database Deployed
- LocalDB instance: `(localdb)\JobsLocalDb`
- 22 tables, 9 views, 157 stored procedures — all deployed successfully
- Seed data files are empty (0 bytes) — needs attention

### Runtime Verified
- HTTP 200 on homepage, login, register, default, and welcome pages
- Master page renders, job content present, search/login/register links visible

## Key Technical Decisions

1. **App_Code → Code rename** — In WAP projects, the `App_Code` folder is dynamically compiled by ASP.NET at runtime IN ADDITION to being compiled into the assembly at build time. This causes duplicate class errors. Renaming to `Code` (or any non-reserved name) prevents the runtime dynamic compilation.

2. **ProfileCommon → JobSiteProfileBase** — ASP.NET reserves the name `ProfileCommon` for the auto-generated profile proxy class. When `<profile inherits="X">` is set, ASP.NET generates `class ProfileCommon : X`. If our class is also named `ProfileCommon`, it creates a circular base class dependency (CS0146).

3. **Classic sqlcmd over Go-based sqlcmd** — The Go-based sqlcmd v1.9 (in PATH) cannot connect to LocalDB via named pipes. Must use the classic ODBC-based sqlcmd at `C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe`.

4. **Raw SQL deployment over DACPAC** — The .sqlproj DACPAC build fails silently (`SqlBuildTask returned false but did not log an error`). Deployed all objects via individual SQL scripts successfully.

## Team Impact

- **Mouse (Tester):** Smoke tests (Section 5 of TEST_PLAN.md) can now be executed — app responds HTTP 200. Database tests can verify 22 tables + 157 sprocs.
- **Morpheus (Lead):** Phase 1 success criteria partially met — app compiles AND runs. Seed data gap needs resolution.
- **Dozer (DevOps):** Build command updated — csproj paths changed from `App_Code\` to `Code\`. CI/CD pipelines should reference new paths.

## Outstanding Items

1. **Seed data** — All 5 seed SQL files are 0 bytes. Registration/login flows will fail without Countries, States, EducationLevels, JobTypes data.
2. **DACPAC build** — SqlBuildTask fails; may need SSDT targets investigation.
3. **Functional testing** — HTTP 200 ≠ working forms. Registration requires ASP.NET Membership, which requires DB + seed data.
4. **CodeFile directives** — ASPX pages still use `CodeFile=` (Web Site) not `CodeBehind=` (WAP). Works at runtime but is technically incorrect.
