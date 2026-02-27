# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Repository Reorganization Complete — Three-Phase Learning Journey

**Context:** Team orchestration completed. Repository structure now maps the modernization learning journey.

**Key Changes:**
- **Repository restructured** into three-phase folders: phase1-legacy-baseline, phase2-azure-migration, phase3-modernization
- **440+ files moved** with Git history preserved across all operations
- **Root cleaned** from 15+ markdown files to ~3 core files
- **App versions renamed:** appV1 → appV1-original, appV1.5-JobsSiteWeb → appV1.5-buildable, appV2 → api-dotnet, appV3 → api-python
- **Infrastructure consolidated:** 9 infrastructure markdown docs moved to infrastructure/docs/
- **New folders:** infrastructure/ (renamed from iac/), docs/ (general learning materials)
- **Case normalization:** Database/ → database/ (consistency)

**What This Means for Future Work:**
- Phase 1 focus: Get appV1.5 (buildable baseline) running — study appV1 to understand legacy issues
- Phase 2 focus: Host Phase 1 app on Azure App Service + SQL PaaS (migration, minimal code changes)
- Phase 3 focus: Build modern API (appV2/appV3) + React UI alongside legacy app (strangler fig pattern)
- **Migrate-Then-Modernize:** Strict principle — Phase 2 is migration, Phase 3 is modernization. No code changes to legacy app.

**Organizational Impact:**
- All future team members will find the repository structure self-documenting
- Phase READMEs provide clear entry points for learners
- Supporting documentation consolidated and organized
- Team decisions recorded in `.squad/decisions.md` (merged from inbox)

**Related:**
- Orchestration logs: `.squad/orchestration-log/2026-02-27T01-36-morpheus.md`, `.squad/orchestration-log/2026-02-27T01-36-dozer.md`
- Decision log: `.squad/decisions.md`
- Session log: `.squad/log/2026-02-27T01-36-repo-reorg.md`

**Status:** ✅ Complete — Repository ready for Phase 1 work

### 2026-02-27: Repository Structure Analysis & Reorganization Proposal

**Context:** First architectural review of repository organization.

**Key Findings:**
- **15+ loose markdown files at root level** — Infrastructure docs (9), code analysis, conversion plans, deployment summaries
- **Ambiguous folder names** — appV1, appV1.5-JobsSiteWeb, appV2, appV3 don't tell the learning story
- **Three-phase learning story** — Phase 1 (legacy baseline), Phase 2 (Azure migration), Phase 3 (modernization with API + React)
- **Key constraint:** This is a LEARNING repository — structure must tell the story, not just organize files

**Repository State:**
- `appV1/` — Original .NET 2.0 Web Forms (can't build, web project format)
- `appV1.5-JobsSiteWeb/` — Minimal changes to make buildable (.sln, master pages, SDK-style project)
- `appV2/` — ASP.NET Core 6+ clean architecture (modern .NET API)
- `appV3/` — Python Flask alternative (experimental)
- `iac/` — Bicep + Terraform infrastructure
- `Database/` — SQL Server database project
- `specs/` — Spec-kit specifications (network redesign, infra reorg)
- `.squad/` — Squad system (agents, decisions, ceremonies)

**Architecture Decisions:**
1. **Folder structure should map to learning phases** — phase1-legacy-baseline, phase2-azure-migration, phase3-modernization
2. **Infrastructure docs consolidated** — Move 9 infrastructure markdown files from root to infrastructure/docs/
3. **Clear naming** — Rename appV1 → appV1-original, appV2 → api-dotnet, appV3 → api-python
4. **Phase READMEs** — Each phase folder needs README explaining its purpose in the learning journey
5. **Root README rewrite** — Make it a learning journey map, not just project description

**Proposal:** Created comprehensive reorganization proposal at `.squad/decisions/inbox/morpheus-repo-reorg.md`

**User Preferences:**
- **Clarity over convention** — If folder name doesn't tell the story, rename it
- **Minimal code changes** — Phase 2 is migration, Phase 3 is modernization (separate concerns)
- **Learning-first** — Structure optimized for learners, not just maintainability

**Key Paths:**
- Infrastructure docs: 9 files at root need to move to infrastructure/docs/
- Spec-related: SPECS.md, REVERSE_ENGINEERING_PROCESS.md → specs/
- Legacy analysis: CODE_ANALYSIS_REPORT.md → phase1-legacy-baseline/docs/
- Modernization planning: REACT_CONVERSION_PLAN.md, CONVERSION_WORKFLOW_PROMPT.md → phase3-modernization/docs/
