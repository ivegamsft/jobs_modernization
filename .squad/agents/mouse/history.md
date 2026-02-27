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
