# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Phase 1 Test Plan Created — Comprehensive Testing Strategy

**Context:** First tester deliverable for Phase 1. Established comprehensive testing baseline for legacy Web Forms app.

**What Was Done:**
- Created `phase1-legacy-baseline/TEST_PLAN.md` (27KB, 12 sections)
- Covered 6 test categories: Build, Database, Smoke, Integration, Regression Baseline, Infrastructure
- 40+ specific test cases with manual + automation paths
- Documented current behavior baseline for Phase 2 comparison

**Key Insights About the Codebase:**
- **No existing tests** — This is the first test effort
- **Build:** .NET Framework 4.8, 1 NuGet dependency (CodeDom Providers), MSBuild compatible
- **Database:** 22 tables, ~150 stored procedures (mix of ASP.NET Membership + custom Jobs procs)
- **Architecture:** Classic Web Forms (code-behind), BOL/DAL layers, stored procedure-driven
- **Membership:** ASP.NET Membership provider with roles (JobSeeker, Employer, Admin)
- **Pages:** 14 user-facing pages + 3 admin pages, Master page pattern, UserControls for reusable UI
- **Concerns:** Hard-coded connection strings (appV1), database-first design, no modern error handling

**Test Strategy Decisions:**
- **CI/CD:** GitHub Actions with MSBuild (compile), PowerShell (database), xUnit (integration)
- **Database:** Docker SQL Server for CI, LocalDB for dev (both Windows + Linux compatible)
- **Frameworks:** MSTest (unit), xUnit (integration), Selenium (UI smoke tests)
- **Isolation:** Fresh test database per run, `test_` prefix for test data, transaction cleanup

**For This Agent (and Future Testers):**
- TEST_PLAN.md is north star for Phase 1 testing
- Section 5 (Regression Baseline) must be filled in with actual behavior during Phase 1a
- Success criteria (Section 8) are the gates for Phase 1 → Phase 2
- Seed data has known conflicts (see `database/SEED_DATA_CONFLICT_ANALYSIS.md`)

**Status:** ✅ Test Plan written, ready for Phase 1a execution

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

### 2026-02-28: Build Verification Tests Implemented — 5/5 Passing

**Context:** First automated test execution for Phase 1. Converted TEST_PLAN.md Section 1 (BLD-001 through BLD-005) into executable PowerShell tests.

**What Was Done:**
- Created `phase1-legacy-baseline/tests/Build-Verification.ps1` (5 tests, self-contained harness)
- Created `phase1-legacy-baseline/tests/README.md` (usage docs)
- All 5 tests pass on current machine (VS 2022 Enterprise MSBuild)

**Test Results (first run):**
- BLD-001: Project file exists — PASS (JobsSiteWeb.csproj found, no .sln yet)
- BLD-002: NuGet restore — PASS (packages already committed to repo)
- BLD-003: Debug build — PASS (0 errors)
- BLD-004: Release build — PASS (0 errors)
- BLD-005: Build output — PASS (bin\JobsSiteWeb.dll, 52.5 KB)

**Key Technical Decisions:**
- **MSBuild discovery:** Uses vswhere first, then well-known VS paths, then PATH fallback
- **NuGet handling:** Tries nuget.exe first; falls back to verifying packages/ already present (they're committed)
- **No .sln required:** Tests work against .csproj directly; will auto-detect .sln when Tank creates it
- **Clean build:** Wipes bin/obj before Debug build for reliability
- **CI/CD ready:** Exit code 0/1, structured PSCustomObject output, no external dependencies

**Key File Paths:**
- Tests: `phase1-legacy-baseline/tests/Build-Verification.ps1`
- Docs: `phase1-legacy-baseline/tests/README.md`
- Project: `phase1-legacy-baseline/appV1.5-buildable/JobsSiteWeb.csproj`
- Output: `phase1-legacy-baseline/appV1.5-buildable/bin/JobsSiteWeb.dll`

**Gotchas Found:**
- PowerShell file encoding matters: em-dash (U+2014) in source causes parse errors on some PowerShell hosts — use ASCII dashes only
- `$PSScriptRoot` can be empty when script is invoked certain ways — need explicit fallback via `$MyInvocation.MyCommand.Path`
- nuget.exe is NOT in PATH on this machine — fallback to checking committed packages/ dir is essential

**Status:** ✅ Build verification automated, all tests green
