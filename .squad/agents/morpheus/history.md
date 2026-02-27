# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

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
