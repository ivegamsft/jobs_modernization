# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-28: appV1.5 Now Runs on IIS Express — Tank Enables Phase 1 Functional Testing

**Cross-Agent Context: Tank's Runtime Success**

Tank (Backend Dev) has successfully deployed appV1.5 to LocalDB and IIS Express. App responds HTTP 200 on 5 pages. This unblocks Phase 1 functional testing (pending seed data).

**What Tank Accomplished:**
- LocalDB instance created: `(localdb)\JobsLocalDb`
- Database deployed: 22 tables, 9 views, 157 stored procedures
- Connection strings fixed: `(localdb)\JobsLocalDb;Initial Catalog=JobsDB`
- Code refactored for WAP migration: App_Code → Code, ProfileCommon → JobSiteProfileBase
- IIS Express running, HTTP 200 on homepage + login/register/welcome/default pages
- Master page renders, job search links visible

**Critical Gap for Your Attention:**
- All seed data SQL files are 0 bytes (empty): Countries.sql, States.sql, EducationLevels.sql, JobTypes.sql
- Registration/login flows will fail without this data
- This blocks Phase 1 functional testing (Sec. 5 of TEST_PLAN.md)
- Priority: HIGH for Phase 1 → Phase 2 transition

**Infrastructure Implications for Your CI/CD Work:**
- Build command now targets: `msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj`
- Code folder structure changed: `App_Code/` → `Code/` (update build paths in pipelines)
- Database deployment now via raw SQL (DACPAC build fails silently, workaround uses scripts)
- Connection string pattern: `(localdb)\JobsLocalDb;Initial Catalog=JobsDB`

**For Your Deployment Scripts:**
- Build produces `bin\JobsSiteWeb.dll` (52.5 KB)
- LocalDB instance must exist before database deployment
- Raw SQL scripts deploy successfully where DACPAC fails
- sqlcmd must be classic ODBC version (`C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe`), not Go-based v1.9

**Related:** `.squad/decisions.md` — "2026-02-28: Phase 1 Runtime Success", `.squad/orchestration-log/2026-02-28T18-30-tank.md`

### 2026-02-28: appV1.5 Build Status — Tank Completes Buildability Validation

**Cross-Agent Context Update**

Tank (Backend Dev) has successfully resolved the Phase 1 critical blocker: **appV1.5 now builds**.

**Build Status:**
- ✅ Debug build: 0 errors, 9 warnings (pre-existing legacy)
- ✅ Release build: 0 errors
- Output: `bin\JobsSiteWeb.dll` (53KB)

**What Was Fixed (4 categories, 232 compile errors resolved):**
1. App_Code files marked as Compile (not Content) in .csproj
2. 28 missing .designer.cs files generated for ASPX/ASCX/Master pages
3. ProfileCommon.cs + BasePage.cs created for typed Profile access
4. Class name collision fixed (employer/jobseeker MyFavorites)

**For Dozer's CI/CD Integration:**
- Build command ready: `msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /t:Build /p:Configuration=Debug`
- Requires .NET Framework 4.8 targeting pack (present on CI/CD agents)
- NuGet restore needed once: `nuget restore JobsSiteWeb.csproj -PackagesDirectory ..\packages`

**Remaining (Not Build-Blocking):**
- No .sln file (build works on .csproj)
- CodeFile vs CodeBehind (runtime concern)
- Connection strings need updating (hardcoded paths)
- Runtime testing pending (IIS Express + database)

**Related:** `.squad/decisions.md` — "2026-02-28: appV1.5 Build Now Works"

## Core Context

Historical learnings from 2026-02-27 infrastructure work. Summarized for readability; full details in `.squad/decisions.md`.

### Repository Structure & Infrastructure Patterns

**Phase Structure:** Repository reorganized into three-phase learning journey:
- **Phase 1:** `phase1-legacy-baseline/` (appV1-original, appV1.5-buildable)
- **Phase 2:** `phase2-azure-migration/`
- **Phase 3:** `phase3-modernization/` (api-dotnet, api-python, ui-react)
- **Supporting:** `infrastructure/` (Bicep, Terraform, scripts), `database/`, `specs/`, `docs/`

**Infrastructure IaC Structure:**
- **Bicep:** `infrastructure/bicep/{core,iaas,paas,agents}/` — Each layer has `main.bicep` (subscription-scoped), `*-resources.bicep` (resource-group-scoped), parameter files
- **Terraform:** `infrastructure/terraform/{core,iaas,paas,agents}/` — Modular with `main.tf`, `variables.tf`, `outputs.tf` per module, conditional `count` deployment
- **Deployment Scripts:** `infrastructure/scripts/Deploy-Bicep.ps1` (main orchestrator), layer-specific scripts (deploy-core, deploy-iaas-clean, deploy-paas-simple)
- **CI/CD:** `.github/workflows/` and `.azure-pipelines/` with 10 deployment pipelines each

**Windows Git Operations for Large Moves:**
- Use `git mv` as primary (preserves history)
- Use `Move-Item` + `git add` for directory renames
- Use temp directory for case-only renames (Windows case-insensitive filesystem)
- Always verify with `git status` (check for "R" not "D+A")

### Infrastructure Cleanup & Blocker Fixes (2026-02-27 to 02-28)

**Documentation Cleanup:** 13 files deleted (broken/credential-containing/duplicate), 18 files fixed (stale paths corrected)

**Script Cleanup:** 5 deleted (hardcoded paths, weak patterns, one-time tools), 7 fixed (path corrections, weak password gen → secure), 12 consolidated to `infrastructure/scripts/`
- All scripts now use `$PSScriptRoot`-based paths (work from any CWD, no absolute paths)

**Deployment Blocker Fixes:**
- Bicep agents/main.bicep: Removed duplicate `githubRunnersSubnet` resource (compilation error)
- Bicep iaas/agents: Parameterized hardcoded VNet name `jobsite-dev-vnet-ubzfsgu4p5eli`
- Bicep core: Key Vault deny-by-default, Container Apps subnet delegation added
- CI/CD: All 10 pipelines updated from `iac/` → `infrastructure/` paths

**Status:** ✅ All 2026-02-27 infrastructure work complete, documented in decisions.md
