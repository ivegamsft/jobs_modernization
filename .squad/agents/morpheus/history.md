# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-28: Phase 1 Focus Shift — Seed Data Gap Identified

Phase 1 runtime success has shifted focus to seed data gap. All Countries, States, EducationLevels, JobTypes SQL files are 0 bytes (empty). This blocks user registration/login/search functional testing. Critical for Phase 1 → Phase 2 transition. Team now prioritizes filling seed data with appropriate INSERT statements.

**Current Status:**
- ✅ Build (appV1.5 compiles 0 errors)
- ✅ Runtime (app runs IIS Express HTTP 200)
- ✅ Database schema (22 tables, 157 sprocs deployed)
- ✅ Build automation (5 tests automated, all passing)
- ✅ Infrastructure blockers (Bicep, CI/CD paths fixed)
- ⏳ Seed data (CRITICAL — all files empty)
- ⏳ Functional testing (blocked on seed data)

**Next Priority:** Create & deploy seed data for Countries, States, EducationLevels, JobTypes.

---

## Core Context

**Phase 1 Planning (2026-02-27):** Created Deployment Plan covering prerequisites (.NET 4.8, VS 2022, LocalDB), build (NuGet restore, MSBuild), database setup (DACPAC to `(localdb)\JobsLocalDb`), local execution (IIS Express/full IIS), troubleshooting, and Azure Phase 2 preview. Database: SSDT DACPAC format, separate seed data scripts, dual connection strings (app + membership). Infrastructure: PaaS Bicep complete with App Service S1, Azure SQL for .NET 4.8, TLS 1.2 minimum. Key risks identified: appV1.5 buildability untested (resolved 2026-02-28), database migration (BACPAC standard), infrastructure deployment (Bicep well-structured).

**Documentation Audit (2026-02-27):** Verified 21 documents have learning value and no stale paths. Deleted 1 orphaned INDEX.md navigation file for non-existent infrastructure docs. Conclusion: reorganization was surgical and well-executed, all documentation trustworthy.

**Infrastructure & Phase 0 Validation (2026-02-27):** Identified deployment blockers (Azure pipelines reference old `iac/` paths), validated appV1.5 buildability as critical blocker for Phase 1. Proposed Phase 0 validation strategy: test appV1.5 buildability, fix pipeline paths, create living CURRENT_STATE.md. Team sequencing: Phase 0 (validate) → Phase 1 (legacy local) → Phase 2 (Azure) → Phase 3 (modernize).

**Repository Reorganization (2026-02-27):** Restructured repository from loose files and ambiguous app versions into three-phase learning journey: phase1-legacy-baseline (get legacy .NET 2.0 running), phase2-azure-migration (host on Azure PaaS), phase3-modernization (modern API + React UI). Moved 440+ files preserving Git history. Root cleaned from 15+ markdown files to 3 core files. Renamed apps: appV1→appV1-original, appV2→api-dotnet, appV3→api-python. Consolidated infrastructure docs. Impact: repository is self-documenting, tells clear learning story.
