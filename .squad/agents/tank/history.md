# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Phase 1 Deployment & Test Plans — Team Context for Build Validation

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
