# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Phase 1 Deployment Plan — Comprehensive Local & Azure Deployment Guide

**Context:** User directive to create Phase 1 Deployment Plan document. Goal is step-by-step guide for getting legacy app running, covering local development, database setup, and Azure PaaS preview.

**Methodology:**
- Examined appV1.5-buildable project structure (.csproj, Web.config, NuGet dependencies)
- Analyzed database project (JobsDB/) and DACPAC deployment approach
- Reviewed infrastructure Bicep templates for PaaS layer
- Structured plan into logical phases: prerequisites, build, database, local run, troubleshooting, Azure preview

**Key Findings:**

1. **App Build Profile:**
   - .NET Framework 4.8 (legacy Web Forms)
   - Uses packages.config (pre-PackageReference era)
   - MSBuild project format (SDK-style, not old web project format)
   - IIS Express compatible (UseIISExpress=true in .csproj)
   - App Service Plan S1 sizing in Bicep template appropriate

2. **Database Architecture:**
   - SSDT-format database project (JobsDB.sqlproj)
   - DACPAC deployment pattern for schema/procedures
   - Separate seed data scripts (ordered, runnable independently)
   - Dual connection strings: application data + ASP.NET membership provider
   - Hard-coded LocalDB path in appV1.5-buildable Web.config (requires update before running)

3. **Infrastructure Foundation:**
   - PaaS Bicep templates complete and functional
   - App Service Plan + Azure SQL Server already defined
   - App Service configured for .NET Framework 4.8 (important constraint)
   - TLS 1.2 minimum, HTTPS enforced (Phase 2 pattern)
   - System-assigned managed identity on App Service (good security practice)

4. **Connection String Management:**
   - Phase 1: LocalDB with hardcoded server name + Integrated Security
   - Phase 2: Azure SQL with TCP endpoint + username/password from Key Vault
   - Dual strings pattern (one for app, one for membership) preserved throughout

5. **Deployment Risk Assessment:**
   - **High risk:** appV1.5 buildability untested at start of Phase 1 (critical blocker)
   - **Medium risk:** Database migration from LocalDB → Azure SQL (BACPAC export/import approach standard)
   - **Low risk:** Infrastructure deployment (Bicep templates well-structured)

**Architecture Decisions Documented:**

1. **Local Development Pattern:** IIS Express + LocalDB (lowest friction for Windows dev)
2. **Database Deployment:** DACPAC (SSDT standard, preserves schema consistency)
3. **Connection String Updates:** In-place Web.config modification (minimal change principle)
4. **Smoke Testing Approach:** HTTP 200 + master page rendering + database query success
5. **Phase 2 Preview:** Included BACPAC migration path and Key Vault integration pattern

**Plan Contents:**

- Part 1: Prerequisites (tools, versions, verification)
- Part 2: Building appV1.5 (NuGet restore, MSBuild, troubleshooting)
- Part 3: Database setup (LocalDB instance, DACPAC deploy, seed data, connection strings)
- Part 4: Local execution (IIS Express vs full IIS)
- Part 5: Troubleshooting matrix (build, database, runtime issues)
- Part 6: Azure Phase 2 preview (architecture, templates, deployment steps)
- Success criteria with verification commands
- Known blockers and risk assessment
- Quick reference command guide

**Key Paths Documented:**

- Source: `phase1-legacy-baseline/appV1.5-buildable/`
- Database: `database/JobsDB/` (DACPAC deployment)
- Infrastructure: `infrastructure/bicep/paas/` (main.bicep + paas-resources.bicep)
- Database LocalDB location: `(localdb)\JobsLocalDb` (instance name as per standard)
- Connection string format: `Server=(localdb)\JobsLocalDb;Database=JobsDB;Integrated Security=true;`

**What This Means for Future Work:**

1. **Phase 1 Execution:** Teams can now follow detailed step-by-step guide without guessing
2. **Phase 2 Planning:** Azure resource mapping already defined; CI/CD pipeline next
3. **Learning Repository:** Document serves dual purpose: deployment guide + teaching artifact
4. **Troubleshooting Reference:** Common issues + solutions prevent rework
5. **Risk Transparency:** Known blockers listed upfront; success criteria clear

**User Preferences Captured:**

- Clear, tabular format for prerequisites and troubleshooting
- Command examples for every major step
- Rationale for each decision (why LocalDB, why DACPAC, why dual connection strings)
- Cross-references to related documentation
- Quick reference section for power users

**Team Awareness:**

- Plan addresses "appV1.5 buildability untested" blocker explicitly
- Provides verification steps for each phase
- Includes rollback/remediation guidance
- Connects Phase 1 → Phase 2 transition clearly

**Related:**
- Artifact: `phase1-legacy-baseline/DEPLOYMENT_PLAN.md`
- Status: ✅ Complete and ready for team execution

### 2026-02-27: Documentation Audit — Post-Reorganization Cleanup, Merged to Decisions

**Context:** User directive to audit all documentation after three-phase repo reorganization and ensure all docs make sense. Remove stale references and noise.

**Methodology:**
- Reviewed every markdown file in root, docs/, phases/, specs/, and database/
- Checked for: stale paths (appV1, appV1.5-JobsSiteWeb, iac/, Database/), accuracy, and learning value
- Evaluated each against three-phase learning journey narrative

**Audit Results:**

**Kept (21 docs):**
- ✅ `README.md` (root) — Accurate, no stale paths
- ✅ `docs/LEARNING_PATH.md` — Clear learning journey, all phases referenced correctly  
- ✅ `phase1-legacy-baseline/README.md` — Accurate, learning value
- ✅ `phase1-legacy-baseline/docs/CODE_ANALYSIS_REPORT.md` — Technical analysis, valuable
- ✅ `phase2-azure-migration/README.md` — Clear migration strategy
- ✅ `phase3-modernization/README.md` — Accurate, documents strangler fig pattern
- ✅ `phase3-modernization/docs/REACT_CONVERSION_PLAN.md` — Future reference value
- ✅ `phase3-modernization/docs/CONVERSION_WORKFLOW_PROMPT.md` — AI workflow guide
- ✅ `phase3-modernization/ui-react/README.md` — Honest placeholder, clear intent
- ✅ `specs/README.md` — Spec kit framework guide, comprehensive
- ✅ `specs/SPECS.md` — Quick reference, accurate
- ✅ `specs/REVERSE_ENGINEERING_PROCESS.md` — Methodology explanation
- ✅ `specs/QUICKSTART.md` — Feature status reference
- ✅ `database/README.md` — Clear schema overview
- ✅ `database/SEED_DATA_CONFLICT_ANALYSIS.md` — Technical analysis

**Deleted (1 doc):**
- ❌ `docs/INDEX.md` — 400+ line outdated navigation index for non-existent infrastructure docs. Predates repo reorganization. Noise.

**Key Finding:** Reorganization was surgical and well-executed. Nearly all documentation already accounts for new structure. Only garbage was one orphaned navigation file.

**What This Means for Future Work:**
- Documentation is clean and current
- All docs serve learning journey or have technical value
- New contributors can navigate with confidence
- No stale path traps or broken references

**Team Awareness:** Merged decision to `.squad/decisions.md`. Dozer's cleanup work documented. All agents understand documentation status.

**Status:** ✅ Complete — Documentation audit passed, decisions merged

### 2026-02-27: Infrastructure Audit & Starting Plan — Phase 0 Validation Required

**Context:** First deep review of infrastructure state after repository reorganization. Objective: understand what's deployable, what's working, what's missing, and sequence the work.

**Key Findings:**

1. **Core Infrastructure (✅ Deployed):**
   - VNet `10.50.0.0/21` with 7 subnets properly sized
   - Key Vault, Log Analytics, NAT Gateway all working
   - Bicep templates for core are production-ready
   - **No issues here** — this foundation is solid

2. **PaaS & IaaS Infrastructure (🟨 Partial):**
   - Bicep templates exist but incomplete (VMSS, SQL VM, App Gateway, full PaaS not finished)
   - Scripts (`deploy-core.ps1`, `deploy-paas-simple.ps1`, etc.) partially complete
   - **Blocker:** All Azure pipelines reference old `iac/` paths, not new `infrastructure/` paths (repo reorganization impact)

3. **Phase 1 Legacy App (❓ Unknown):**
   - AppV1.5-buildable exists but **buildability untested**
   - No local setup guide
   - No proof it compiles with `dotnet build` or `msbuild`
   - **Critical blocker:** Can't progress without knowing if app builds

4. **Database (❓ Partial):**
   - JobsDB SQL project exists
   - **Missing:** Database setup guide, migration strategy for Phase 2 (local → Azure SQL)
   - DACPAC generation untested

5. **Documentation Quality (🟨 Needs update):**
   - DEPLOYMENT_STATUS.md marked "complete" but no date — unclear if current
   - No "How to deploy Phase 1 app" guide
   - IMPLEMENTATION_CHECKLIST.md is detailed but resource-reorganization-specific (Phase 3+ work)
   - No living architecture document (CURRENT_STATE.md)

**Architecture Decisions Made:**

1. **Validation Before Deep Work:** Phase 0 (this week) must focus on:
   - Audit: What's actually deployed? (Azure resource inventory)
   - Test: Does Phase 1 app build?
   - Fix: Correct pipeline paths (iac → infrastructure)
   - Document: Create CURRENT_STATE.md (living doc)

2. **Sequencing Strategy:**
   - Phase 1 (legacy running locally) → Phase 1 (legacy on Azure IaaS) → Phase 2 (legacy on App Service) → Phase 3 (modernize)
   - Each phase must have: infrastructure code (Bicep), deployment automation (Pipeline), and validation steps

3. **Risk Management:**
   - If Phase 1 app doesn't build: stop, fix, document why (learning value even in failure)
   - If IaaS deployment fails: troubleshooting guide and mitigation needed
   - If database migration breaks: test with backups, rollback plan required

**Key Paths & Artifacts Created:**
- `.squad/decisions/inbox/morpheus-starting-plan.md` — Comprehensive 25-section infrastructure plan
- Need to create: `infrastructure/CURRENT_STATE.md`, `phase1-legacy-baseline/BUILD_STATUS.md`, `LOCAL_SETUP.md`

**What This Means for Future Work:**
- Infrastructure work is well-structured but incomplete — gaps are known and sequenced
- Phase 0 (validation) is critical and must happen before Phase 1 infrastructure commit
- Team needs to answer 6 validation questions (buildability, current deployment status, password strategy, etc.)
- Documentation is a key artifact: living CURRENT_STATE.md replaces static DEPLOYMENT_STATUS.md

**User Preferences Learned:**
- Clarity over convention — file/folder names tell the story
- Learning-first — infrastructure docs must explain not just "how to deploy" but "why this architecture"
- Minimal changes — infrastructure, like code, should be migrations-first
- Transparency about unknowns — "❓ Unknown" vs "✅ Done" vs "❌ Broken" is valuable

**Related:**
- Decision document: `.squad/decisions/inbox/morpheus-starting-plan.md`
- Next action: Team review of plan + answer validation questions

**Status:** Plan proposed; awaiting team review and Phase 0 execution

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
