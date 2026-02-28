# Decisions

> Shared decision log. All agents read this before starting work.
> Scribe merges new decisions from `.squad/decisions/inbox/`.

---

## 2026-02-28: Deployment Blocker Fixes — 6 Issues Resolved

**Decision ID:** deployment-blocker-fixes-2026-02-28  
**Author:** Dozer (DevOps)  
**Date:** 2026-02-28  
**Status:** Executed  
**Impact:** High (unblocks all Bicep deployments and CI/CD pipelines)

### Context

Infrastructure audit identified 6 deployment blockers preventing Bicep compilation and pipeline execution. All blockers are now resolved.

### Fixes Applied

**Bicep Templates (3 files):**

1. **agents/main.bicep** — Removed duplicate `githubRunnersSubnet` resource declaration (compilation error). Added `coreVnetName` parameter replacing hardcoded VNet name.

2. **iaas/main.bicep** — Added `coreVnetName` parameter replacing hardcoded VNet name `jobsite-dev-vnet-ubzfsgu4p5eli` (deployment-specific value that would cause failures).

3. **core/core-resources.bicep** — Two security improvements:
   - Key Vault `networkAcls.defaultAction` changed from `Allow` to `Deny` (defense-in-depth, matches Terraform security posture)
   - Container Apps subnet `snet-ca` now has `Microsoft.App/environments` delegation (required for Container Apps Environment deployment)

**CI/CD Pipelines (10 files):**
- All deployment pipelines updated from `iac/` to `infrastructure/` path references
- 5 GitHub Actions workflows: deploy-agents, deploy-core, deploy-iaas, deploy-paas, deploy-vpn
- 5 Azure Pipelines definitions: deploy-agents, deploy-core, deploy-iaas, deploy-paas, deploy-vpn

### Key Design Decisions

1. **VNet Parameterization:** Layers that reference core VNet (iaas, agents) now receive `coreVnetName` as parameter from core module deployment output. Not hardcoded.

2. **Key Vault Security:** All Key Vault instances default to deny-by-default. Access only via private endpoints or Azure services bypass. Deployment scripts accessing KV over public internet will need adjustment.

3. **Pipeline Paths:** All triggers and workflow paths now correctly reference `infrastructure/bicep/` structure.

4. **Sensitive Parameters:** .bicepparam files are gitignored (passwords never committed). Must pass sensitive values via CLI `--parameters` flag or Key Vault reference at deployment time.

### Team Impact

- Bicep templates are now compilable
- Pipeline triggers fire correctly on infrastructure changes
- Teams deploying iaas/agents layers must pass `coreVnetName` parameter
- Key Vault is now production-secure (deny-by-default)

### Related

- Orchestration log: `.squad/orchestration-log/2026-02-28T06-45-dozer.md`

---

## 2026-02-28: appV1.5 Build Now Works — Web Site → WAP Migration Completed

**Decision ID:** appv15-build-fixed-2026-02-28  
**Author:** Tank (Backend Dev)  
**Date:** 2026-02-28  
**Status:** Implemented & Verified  
**Impact:** High (unblocks Phase 1 testing, deployment, and all downstream work)

### Context

appV1.5-buildable was supposed to be the "minimal changes to make buildable" version of the legacy .NET Web Forms app. However, the Web Site → Web Application Project (WAP) migration was incomplete. The project had a .csproj file but was missing 4 critical categories of files, causing 232+ compile errors.

### Root Causes & Fixes

| Category | Problem | Solution | Files Changed |
|----------|---------|----------|----------------|
| **App_Code** | 12 BOL/DAL files marked as `<Content>` instead of `<Compile>` | Changed .csproj build action to `<Compile>` | 1 (.csproj) |
| **Designers** | 28 ASPX/ASCX/Master pages missing .designer.cs files | Generated .designer.cs files with server control field declarations | 28 new files |
| **Profile** | No typed `ProfileCommon` class for Web.config `<profile>` definition | Created ProfileCommon.cs + BasePage.cs; updated 6 pages to inherit BasePage | 2 new + 6 modified |
| **Collision** | Both employer and jobseeker had `MyFavorites_aspx` class (conflicts in single assembly) | Renamed employer's class to `employer_MyFavorites_aspx` | 2 files |
| **Namespace** | Invalid `using ASP;` (runtime-only namespace) in viewresume.aspx.cs | Removed the using statement | 1 file |

### Build Result

```
Configuration: Debug
Result: ✅ 0 errors, 9 warnings (pre-existing legacy code)

Configuration: Release
Result: ✅ 0 errors

Output: bin\JobsSiteWeb.dll (53KB)
```

### Build Command (for CI/CD)

```powershell
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
# One-time: nuget restore JobsSiteWeb.csproj -PackagesDirectory ..\packages
& $msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /t:Build /p:Configuration=Debug
```

### Remaining Work (Out of Scope)

1. **No .sln file** — Build works on .csproj directly; .sln would improve VS IDE integration
2. **CodeFile vs CodeBehind** — ASPX directives use `CodeFile=` (Web Site pattern), not `CodeBehind=` (WAP pattern); affects runtime execution, not build
3. **Connection strings** — Hardcoded to `C:\GIT\APPMIGRATIONWORKSHOP\...` path; need updating for local development
4. **Runtime testing** — Build success ≠ runtime success. Need IIS Express + database configuration to verify runtime behavior

### Key Files Created

- `App_Code/ProfileCommon.cs` — Typed profile class matching Web.config `<profile>` definition (JobSeeker + Employer properties)
- `App_Code/BasePage.cs` — Base page class providing strongly-typed `Profile` property for inherited pages
- 28 `.designer.cs` files — Server control field declarations for all ASPX pages, ASCX user controls, and master pages

### Key Files Modified

- `JobsSiteWeb.csproj` — App_Code items: Content → Compile, added references to all designer files
- `Web.config` — Added `inherits="ProfileCommon"` to `<profile>` element
- 6 code-behind files — Changed `: Page` to `: BasePage` where typed Profile is accessed
- `employer/MyFavorites.aspx[.cs]` — Class collision fixed with namespace rename

### Team Impact

- **Mouse (Tester):** Build Verification tests (5 tests in `phase1-legacy-baseline/TEST_PLAN.md`) can now be executed
- **Morpheus (Lead):** "Building appV1.5" section of `phase1-legacy-baseline/DEPLOYMENT_PLAN.md` is now fully executable
- **Dozer (DevOps):** Build command is CI/CD pipeline-ready; can integrate into GitHub Actions / Azure Pipelines

### Related

- Orchestration log: `.squad/orchestration-log/2026-02-28T06-45-tank.md`

---

## 2026-02-27: Phase 1 Deployment Plan Established

**Decision ID:** phase1-deployment-plan-2026-02-27  
**Author:** Morpheus (Lead)  
**Status:** Decision Document  
**Impact:** Medium (enables Phase 1 execution)  
**Related:** Legacy baseline deployment, database setup, Azure PaaS preview

### Context

Phase 1 requires a comprehensive deployment guide covering local development setup, building appV1.5, database setup, and app verification.

### Decision

**Created comprehensive Phase 1 Deployment Plan** at `phase1-legacy-baseline/DEPLOYMENT_PLAN.md` with:
- Local development prerequisites (.NET Framework 4.8, VS 2022, SQL Server LocalDB)
- Building appV1.5-buildable (NuGet restore, MSBuild)
- Database setup (DACPAC deployment, seed data ordering)
- Local execution (IIS Express, full IIS, smoke tests)
- Troubleshooting matrix (build, database, runtime)
- Azure Phase 2 preview (PaaS architecture, Bicep templates, migration)
- 9-point success criteria with verification script

### Key Decisions

1. **LocalDB Instance:** `(localdb)\JobsLocalDb` (clear, descriptive, consistent)
2. **Database Deployment:** Prioritize DACPAC (native to SQL Server, SSDT standard)
3. **Connection Strings:** Document dual strings (app data + ASP.NET membership) — legacy constraint
4. **Dev Environment:** IIS Express default (zero setup), full IIS as alternative
5. **Migration:** BACPAC export/import (LocalDB → Azure SQL, industry standard)
6. **Smoke Tests:** 9-point checklist (HTTP 200 + DB connectivity + master page)

### Impact

- Removes ambiguity for Phase 1 execution
- Enables teams to verify appV1.5 buildability (critical blocker)
- Sets pattern for Phase 2 Azure migration
- Learning value — rationale explained for each decision

---

## 2026-02-27: Phase 1 Testing Strategy — Test Framework & Infrastructure

**Decision ID:** phase1-testing-strategy-2026-02-27  
**Author:** Mouse (Tester)  
**Date:** 2026-02-27  
**Status:** Proposed for team review  
**Impact:** Medium (defines test approach for Phase 1 → Phase 2 baseline)

### Context

Phase 1 goal is buildability and runnability. No existing tests in legacy codebase — need comprehensive baseline for Phase 2 comparison.

### Decision

**Created TEST_PLAN.md** at `phase1-legacy-baseline/TEST_PLAN.md` with 6 test categories (40+ test cases):
- Build verification (5 tests)
- Database (17 tests) — DACPAC, schema, seed data, stored procedures
- Smoke tests (24 tests) — App startup, job search, registration, login, admin
- Integration (20 tests) — App↔DB connectivity, stored procedures
- Regression baseline (document current behavior pre-Phase 2)
- Test infrastructure (framework, database strategy, CI/CD)

### Framework Choices

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Build | MSBuild + GitHub Actions | .NET native, cross-platform |
| Database | T-SQL + PowerShell | Native to SQL Server |
| Unit Tests | MSTest | Built into Visual Studio |
| Integration | xUnit + Testcontainers | Modern, database isolation |
| UI/Smoke | Selenium WebDriver (C#) | All platforms, scriptable |
| DB Instance | Docker SQL Server (CI) + LocalDB (dev) | Reproducible, lightweight |

### Phase 1 Success Criteria

- Solution compiles (Debug & Release)
- 22 database tables created
- ~150 stored procedures callable
- App starts without unhandled exceptions
- User can register, login, browse jobs, search
- Admin access control enforced
- All baseline behavior documented

### Implementation Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1a | Week 1 | Manual baseline testing, Section 5 docs |
| 1b | Week 2-3 | Automated tests (build, DB, smoke) |
| 1c | Week 4 | Coverage report, Phase 1 approval |

### Open Questions for Team

1. **Database instance:** Docker for everyone or LocalDB? → **Rec:** Docker in CI/CD, LocalDB optional
2. **UI test coverage:** Smoke only or full? → **Rec:** Smoke in 1b, expand phase 2
3. **Stored proc tests:** All 150 or top 20? → **Rec:** Top 20 critical flows
4. **Performance baseline:** Worth measuring? → **Rec:** Measure, no strict SLAs yet

### Impact

Establishes Phase 1 works. Creates regression baseline for Phase 2 comparison. Sets test pattern for Phases 2 & 3.

---

## 2026-02-27: Infrastructure Script Cleanup

**Decision ID:** script-cleanup-2026-02-27  
**Author:** Dozer (DevOps)  
**Status:** Executed  
**Impact:** Medium (developer experience, security hygiene)

### Context

20 PowerShell scripts scattered across 4 locations with hardcoded paths, weak passwords, or one-time tools.

### Decision

Audited every script. Applied three rules:
1. **DELETE** if superseded, hardcoded paths, one-time tool, or security liability
2. **FIX** if worth keeping but had wrong paths or weak patterns
3. **CONSOLIDATE** all deployment scripts into `infrastructure/scripts/`

### What Changed

**Deleted (5 scripts, -492 lines):**
- deploy-app-layers.ps1 (superseded, hardcoded paths)
- deploy-iaas-v2.ps1 (superseded by deploy-iaas-clean.ps1)
- redeploy-iaas-wfe.ps1 (one-time troubleshooting)
- CLEANUP_SECRETS.ps1 (one-time git cleanup)
- cleanup_secrets.py (Python duplicate)

**Fixed (7 scripts):**
- All hardcoded `c:\git\jobs_modernization\iac\` → `$PSScriptRoot\..`
- Weak password generation replaced with `New-SecurePassword.ps1`

**Consolidated:**
All scripts now in `infrastructure/scripts/` (except `bicep/iaas/scripts/iis-install.ps1` which must stay adjacent to Bicep template)

### Final Script Inventory (15 scripts)

Deploy-Bicep.ps1, deploy-core.ps1, deploy-iaas-clean.ps1, deploy-paas-simple.ps1, deploy-agents.ps1, deploy-vpn.ps1, update-core-add-containers.ps1, bootstrap-terraform-backend.ps1, New-SecurePassword.ps1, create-nat-inbound-rules.ps1, check-status.ps1, diagnose.ps1, get-credentials.ps1, iis-install.ps1 (bicep/iaas/scripts/)

### Implications

1. All deployment scripts in ONE place (`infrastructure/scripts/`)
2. Scripts work from any CWD (all `$PSScriptRoot`-based)
3. No hardcoded absolute paths remain
4. Docs may have stale script path references — flag for next audit

---

## 2026-02-27: Three-Phase Learning Journey — Repository Reorganization

**Decision ID:** repo-reorg-2026-02-27  
**Author:** Morpheus (proposal), Dozer (execution)  
**Status:** Approved & Implemented  
**Impact:** High (structural — affects all future work)

### Context

Repository had 15+ loose markdown files at root, 4 ambiguous app versions (appV1/V1.5/V2/V3), and unclear folder organization. This was a learning repository but structure didn't tell the story.

### Decision

Reorganize repository into **three-phase structure** that maps the modernization journey:

1. **Phase 1: Legacy Baseline** (`phase1-legacy-baseline/`)
   - Goal: Get legacy .NET 2.0 Web Forms app running as-is
   - Contents: appV1-original (original, doesn't build), appV1.5-buildable (minimal changes)
   
2. **Phase 2: Azure Migration** (`phase2-azure-migration/`)
   - Goal: Host on Azure App Service + SQL PaaS with minimal code changes
   - Contents: Deployment guides, IaC for PaaS, lessons learned

3. **Phase 3: Modernization** (`phase3-modernization/`)
   - Goal: Add modern API + React UI alongside legacy app (strangler fig pattern)
   - Contents: api-dotnet (ASP.NET Core 6+), api-python (Flask), ui-react (React SPA)

### Supporting Structure

- **infrastructure/** — Consolidated all 9 infrastructure docs, Bicep/Terraform templates
- **database/** — SQL Server schema, seed data (renamed to lowercase)
- **specs/** — Spec-kit specifications (SPECS.md, REVERSE_ENGINEERING_PROCESS.md moved here)
- **docs/** — Learning paths, contributing guide, general documentation

### Root Cleanup

Root directory reduced from **15+ markdown files → 3 files** (README, .gitignore, core project config).

### Implementation

- **Files moved:** 440+
- **Directories renamed:** 4 (appV* → phase folders, iac → infrastructure, Database → database)
- **READMEs created:** 8 (one per phase + supporting folders)
- **Git history:** Preserved across all moves using `git mv` with Windows fallback techniques

### Verification

✅ Root cleaned  
✅ Git history preserved  
✅ Phase structure tells story  
✅ All infrastructure docs consolidated  
✅ All README files created and populated  

### Related Artifacts

- **Proposal:** `.squad/decisions/inbox/morpheus-repo-reorg.md` (comprehensive design)
- **Execution:** `.squad/decisions/inbox/dozer-windows-git-operations.md` (implementation techniques)
- **Commit:** "refactor: reorganize repo into three-phase learning journey"

---

## 2026-02-27: Infrastructure Documentation Cleanup

**Decision ID:** infra-doc-cleanup-2026-02-27  
**Author:** Dozer (DevOps)  
**Status:** Executed  
**Impact:** Medium (documentation quality, security)

### Context

After the `iac/` → `infrastructure/` reorganization, all infrastructure documentation had stale paths. Two files contained plaintext passwords committed to git. The `infrastructure/bicep/` directory had 10 network security docs that were 80% duplicate content.

### Decision

1. **Delete 13 files** that were broken, contained credentials, or were pure duplicates
2. **Fix paths in 18 files** — all `iac/` references → `infrastructure/`, all `appV2/appV3` → `phase3-modernization/`
3. **Fix incorrect data** — core/README.md had wrong VNet CIDR, terraform/STATUS.md marked complete modules as pending

### Security Note

Two files contained plaintext passwords that were committed to git history:
- `infrastructure/DEPLOYMENT_STATUS.md` — VM admin password + certificate password
- `infrastructure/docs/CREDENTIALS_AND_NEXT_STEPS.md` — Same credentials

These passwords should be rotated if they were ever used in a real deployment. The files are removed from HEAD but remain in git history.

### Files Deleted (13)

1. infrastructure/DEPLOYMENT_STATUS.md
2. infrastructure/docs/CREDENTIALS_AND_NEXT_STEPS.md
3. infrastructure/bicep/INDEX.md
4. infrastructure/bicep/QUICK_START.md
5. infrastructure/bicep/DEPLOYMENT_VALIDATION.md
6. infrastructure/bicep/NETWORK_SECURITY_COMPLETE.md
7. infrastructure/bicep/NETWORK_SECURITY_FILES_INDEX.md
8. infrastructure/bicep/NETWORK_SECURITY_INDEX.md
9. infrastructure/bicep/NETWORK_SECURITY_QUICKSTART.md
10. infrastructure/bicep/README_NETWORK_SECURITY_CHANGES.md
11. infrastructure/bicep/paas/FILE_INDEX.md
12. infrastructure/bicep/paas/INTEGRATION_SUMMARY.md
13. infrastructure/bicep/paas/COMPLETION_REPORT.md

### Files Fixed (18)

- infrastructure/bicep/README.md
- infrastructure/bicep/core/README.md
- infrastructure/terraform/STATUS.md
- infrastructure/docs/4LAYER_RG_QUICK_REFERENCE.md
- infrastructure/README.md
- 13 other files with stale path references

### Related

- Orchestration log: `.squad/orchestration-log/2026-02-27T02-07-dozer.md`

---

## 2026-02-27: Post-Reorganization Documentation Audit

**Decision ID:** doc-audit-2026-02-27  
**Author:** Morpheus (Lead)  
**Status:** Completed  
**Impact:** Low (hygiene — removes noise)

### Context

User directive: "ensure the current documents make sense. if not, delete them."

After repository reorganization from loose app folders (appV1/V2/V3) to three-phase structure (phase1/phase2/phase3), documentation needed audit. The restructuring was comprehensive (440+ files moved), and documentation might contain stale paths or outdated info.

### Decision

Audited EVERY document in the repository post-reorganization. Verified 21 documents for accuracy and learning value. Deleted 1 orphaned file.

### Documents

**Kept (21 docs):** README.md (root), LEARNING_PATH.md, all phase READMEs, CODE_ANALYSIS_REPORT.md, REACT_CONVERSION_PLAN.md, CONVERSION_WORKFLOW_PROMPT.md, all spec kit docs, all database docs

**Deleted (1 doc):**
- `docs/INDEX.md` (408 lines) — Orphaned navigation index for infrastructure documents that don't exist in current structure

### Key Finding

The reorganization was surgical and well-executed. Documentation already accounts for new structure. No stale path traps or broken references found except one abandoned artifact.

### Implications

1. **Documentation is trustworthy** — New contributors can navigate with confidence
2. **No broken links** — All references point to actual files
3. **Clean slate for Phase 1 work** — Can proceed without doc-related distractions
4. **Learning journey intact** — Three-phase story preserved across all docs

### Related

- Orchestration log: `.squad/orchestration-log/2026-02-27T02-07-morpheus.md`

---

## 2026-02-27: Migrate-Then-Modernize Strategy

**Decision ID:** migrate-then-modernize  
**Author:** ivegamsft (user directive)  
**Status:** Guiding principle  
**Impact:** High (strategy — shapes Phase 2 & 3 work)

### Context

Clear directive: Do not change the existing legacy application until Phase 3. Phases 1 and 2 are about getting it running and hosting it, not rewriting it.

### Decision

Three-phase approach with **strict separation of concerns:**

1. **Phase 1:** Get the legacy .NET 2.0 app running as-is (no code changes)
2. **Phase 2:** Host on Azure App Service + SQL PaaS (infrastructure change, no app changes)
3. **Phase 3:** Modernize by adding modern API + React UI alongside legacy app (strangler fig pattern, no modifications to legacy app)

**Key Principle:** MINIMAL CHANGES. Each phase is independent. Never modify the legacy app directly — extend it or replace it, but don't alter it.

### Why

This approach:
- ✅ Preserves legacy app integrity for reference/learning
- ✅ Demonstrates migration (Phase 2) as separate from modernization (Phase 3)
- ✅ Teaches strangler fig pattern in Phase 3
- ✅ Allows learners to understand each concern independently

### Related

- Foundational to Phase 2 and Phase 3 design
- Repository reorganization supports this strategy (separate folders)

---

## 2026-02-27: Legacy App Baseline Definition

**Decision ID:** legacy-baseline-definition  
**Author:** ivegamsft (user clarification)  
**Status:** Reference  
**Impact:** Medium (defines Phase 1 scope)

### Context

Clarification of app versions and their roles in learning journey.

### Decision

- **appV1** = Original legacy .NET Web Forms app (web project format, doesn't build) → `phase1-legacy-baseline/appV1-original/` (reference only)
- **appV1.5** = Minimal changes to make buildable (.sln, master pages, SDK-style project) → `phase1-legacy-baseline/appV1.5-buildable/` (working baseline for learning)
- **appV2** = Phase 3 modernization material (ASP.NET Core 6+ clean architecture) → `phase3-modernization/api-dotnet/`
- **appV3** = Experimental (Python Flask alternative) → `phase3-modernization/api-python/` (keep or redo)

**Phase 1 Goal:** Get appV1.5 (the buildable baseline) running successfully. Study appV1 to understand original architecture and issues.

### Why

Clarity about app versions and their purposes in learning flow.

---

## 2026-02-27: Windows Git Operations for Large-Scale Reorganization

**Decision ID:** windows-git-ops  
**Author:** Dozer (DevOps)  
**Status:** Technique reference  
**Impact:** Low (operational — for future reorganizations)

### Context

Moving 440+ files across Windows filesystem (case-insensitive) requires careful technique selection.

### Decision

Use **`git mv` as primary technique** with fallback strategies for Windows edge cases:

**Standard Moves (works every time):**
```powershell
git mv old-file.md new-location/old-file.md
git mv appV1 phase1-legacy-baseline/appV1-original
```

**Directory Content Moves (when git mv fails):**
```powershell
Move-Item -Path "iac\*" -Destination "infrastructure\" -Force
Remove-Item -Path "iac" -Force
git add infrastructure\*
```

**Case-Only Renames (Windows special case):**
```powershell
Move-Item -Path "Database" -Destination "Database_temp" -Force
Move-Item -Path "Database_temp" -Destination "database" -Force
git add database\*
```

### Why

- `git mv` preserves history (shows "R" not "D+A")
- Move-Item + git add handles large directory moves
- Temp directory handles Windows case-insensitive filesystem
- All approaches maintain Git history with `git log --follow`

### Lessons for Future Work

1. Always prefer `git mv` (safest for history)
2. Use temp directory for case-only renames on Windows
3. Verify with `git status` (check for "R")
4. Test incrementally, don't batch all 440 operations

### Related

- Executed in repository reorganization (440+ files)
- Reference for future large-scale file reorganizations
