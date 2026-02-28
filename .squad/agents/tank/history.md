# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-28: Phase 1 Runtime Complete — Tank Finalizes Buildability & Runtime

**Cross-Agent Context: Tank's Session Outcome**

Tank (Backend Dev) completed Phase 1 runtime prep. Environment validated (MSBuild v17.14, LocalDB, IIS Express), .sln created, connection strings fixed, code refactored for WAP migration (App_Code→Code, ProfileCommon→JobSiteProfileBase), database deployed (22 tables, 157 sprocs), IIS Express running with HTTP 200 on 5 pages.

**Critical Gap:** All seed data files are 0 bytes. Blocks functional testing.

**For other agents:**
- Mouse: Database infrastructure live, smoke tests ready
- Dozer: Build command finalized, CI/CD ready
- Morpheus: Phase 1 partially met (builds+runs), seed data blocks progress

**Related:** `.squad/decisions.md` — "2026-02-28: Phase 1 Runtime Success"

---

### 2026-02-28: Seed Data Populated — All 4 Empty Files + RunAll Script

**What Was Done:**
- Wrote seed data SQL for all 4 empty files following the pattern from `05_SeedExperienceLevels.sql`
- Countries: 15 rows (US=ID 1, plus Canada, UK, Australia, Germany, France, India, Japan, Brazil, Mexico, Netherlands, Singapore, Ireland, Israel, South Korea)
- States: 51 rows (all 50 US states + DC, all mapped to CountryID=1)
- EducationLevels: 7 rows (High School, Associate's, Bachelor's, Master's, Doctorate, Professional, Other)
- JobTypes: 7 rows (Full-time, Part-time, Contract, Temporary, Internship, Freelance, Remote)
- RunAll_SeedData.sql: Uses `:r` sqlcmd syntax to run all 5 scripts in order

**Deployment Verified:**
- Deployed to `(localdb)\JobsLocalDb` via classic sqlcmd (NOT go-based — go-based doesn't work with LocalDB named pipes)
- Row counts confirmed: 15 countries, 51 states, 7 education levels, 7 job types, 8 experience levels
- IIS Express: HTTP 200 on homepage, login, register (no errors)
- Auth-protected pages (jobsearch, postjob, AddEditPosting) properly redirect to login (302→200)

**Table naming convention:** All tables use `JobsDb_` prefix (e.g., `JobsDb_Countries`, `JobsDb_States`)

**Critical gap resolved:** Seed data was the last blocker for functional user flow testing.

**For other agents:**
- Mouse: All dropdown data now populated — registration/job posting flows should work with real data
- Morpheus: Phase 1 seed data gap closed

**Commit:** 44510b1

---

### 2026-02-28: Deployment Blockers Fixed — Dozer Completes Infrastructure Validation

Dozer completed all 6 deployment blockers. 10 CI/CD pipelines updated from `iac/` → `infrastructure/`, Bicep templates compile without errors, VNet parameterized, Key Vault deny-by-default, Container Apps subnet delegation added. Infrastructure unblocked for Tank's testing.

**Related:** `.squad/decisions.md` — "2026-02-28: Deployment Blocker Fixes"

---

## Core Context

**Phase 1 Build & Runtime (2026-02-28):** Fixed 232 build errors (App_Code Content→Compile, 28 missing .designer.cs, ProfileCommon class, collision). Created .sln, fixed connection strings, refactored code, deployed database 22 tables + 157 sprocs. App runs IIS Express HTTP 200. Seed data gap critical. Build command: `msbuild phase1-legacy-baseline\appV1.5-buildable\JobsSiteWeb.csproj /t:Build /p:Configuration=Debug`. Tools: MSBuild v17.14, .NET 4.8 targeting pack, classic sqlcmd (ODBC, not Go v1.9 which fails for LocalDB).

**Phase 1 Planning (2026-02-27):** Created Deployment Plan with prerequisites, build, database setup, local execution, troubleshooting, Azure Phase 2 preview. LocalDB `(localdb)\JobsLocalDb`, DACPAC deployment, dual connection strings. Phase 1 risks: buildability untested (resolved), migration (BACPAC), infrastructure (Bicep structured). Connection strings: Phase 1 LocalDB+Integrated; Phase 2 Azure SQL+Key Vault.

**Documentation Audit (2026-02-27):** Verified 21 documents trustworthy, no stale paths. Deleted 1 orphaned INDEX.md. Reorganization surgical, complete.

**Infrastructure & Phase 0 (2026-02-27):** Identified blockers (old pipeline paths), validated buildability as critical blocker. Phase 0: test appV1.5, fix pipelines, create CURRENT_STATE.md. Sequencing: Phase 0 (validate) → Phase 1 (local) → Phase 2 (Azure) → Phase 3 (modernize).

**Repository Reorganization (2026-02-27):** Three-phase structure (phase1-legacy-baseline, phase2-azure-migration, phase3-modernization). Moved 440+ files preserving history. Root: 15+ files → 3. Renamed appV1→appV1-original, appV2→api-dotnet, appV3→api-python. Result: self-documenting repository for learners.
