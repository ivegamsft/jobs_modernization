# Repository Reorganization Proposal

**Author:** Morpheus (Lead)  
**Date:** 2026-02-27  
**Status:** Awaiting Approval  
**Impact:** High (structural changes to entire repo)

---

## Executive Summary

This repository tells a learning story about .NET modernization but currently has 15+ loose markdown files at root and ambiguous folder names. I'm proposing a **three-phase folder structure** that clearly maps to the modernization journey: Phase 1 (legacy), Phase 2 (PaaS migration), Phase 3 (React + API modernization).

**Key Principle:** This is a learning repo — structure must tell the story, not just organize files.

---

## Current State Assessment

### Root-Level Chaos (15+ Markdown Files)

| File | Purpose | Problem |
|------|---------|---------|
| `4LAYER_RG_QUICK_REFERENCE.md` | Azure RG organization guide | Belongs in infrastructure docs |
| `CODE_ANALYSIS_REPORT.md` | Legacy code analysis | Belongs with Phase 1 docs |
| `CONVERSION_WORKFLOW_PROMPT.md` | AI conversion prompts | Belongs in Phase 3 docs |
| `CREDENTIALS_AND_NEXT_STEPS.md` | Deployment credentials | Belongs in IaC docs |
| `DEPLOYMENT_COMPLETE.md` | IaaS deployment summary | Belongs in IaC docs |
| `DEPLOYMENT_SUMMARY.md` | Infrastructure status | Belongs in IaC docs |
| `DOCUMENTATION_PACKAGE_README.md` | Index of infra docs | Belongs in IaC docs |
| `IMPLEMENTATION_CHECKLIST.md` | Infrastructure tasks | Belongs in IaC docs |
| `INDEX.md` | Navigation guide for infra reorg | Redundant with README |
| `REACT_CONVERSION_PLAN.md` | Phase 3 React planning | Belongs in Phase 3 docs |
| `RESOURCE_GROUP_ORGANIZATION_FIX.md` | Azure RG fix details | Belongs in IaC docs |
| `REVERSE_ENGINEERING_PROCESS.md` | Spec generation process | Belongs in specs/ or docs/ |
| `SPECS.md` | Spec kit overview | Belongs in specs/ |
| `THE_ISSUE_AND_FIX.md` | Azure CLI deployment issue | Belongs in IaC docs |
| `VISUAL_SUMMARY.md` | Infrastructure visual guide | Belongs in IaC docs |

### Ambiguous Folder Names

- `appV1` — What is V1? Original? Buildable?
- `appV1.5-JobsSiteWeb` — Why 1.5? What changed?
- `appV2` — Modern .NET but purpose unclear
- `appV3` — Python version but why V3?

These names don't tell the **learning story**.

---

## Proposed Structure

```
F:\Git\jobs_modernization\
│
├── README.md                           # New: Learning journey map
│
├── phase1-legacy-baseline/             # RENAME: appV1 + appV1.5
│   ├── README.md                       # Phase 1 story: Get legacy running
│   ├── appV1-original/                 # RENAME: appV1 (original, can't build)
│   │   └── README.md                   # What this is, why it won't build
│   ├── appV1.5-buildable/              # RENAME: appV1.5-JobsSiteWeb
│   │   └── README.md                   # Minimal changes to make it build
│   └── docs/
│       ├── CODE_ANALYSIS_REPORT.md     # MOVE: from root
│       └── legacy-architecture.md      # New: Explain .NET 2.0 architecture
│
├── phase2-azure-migration/             # NEW: PaaS migration story
│   ├── README.md                       # Phase 2 story: Host on Azure with minimal code changes
│   ├── deployment-guide.md             # How to deploy legacy app to Azure
│   └── lessons-learned.md              # What worked, what didn't
│
├── phase3-modernization/               # NEW: Modernization story
│   ├── README.md                       # Phase 3 story: Add modern API + React UI
│   ├── api-dotnet/                     # RENAME: appV2
│   │   ├── README.md                   # Clean architecture, .NET 6+
│   │   ├── src/
│   │   ├── tests/
│   │   └── docs/
│   ├── api-python/                     # RENAME: appV3
│   │   ├── README.md                   # Python Flask alternative
│   │   ├── app/
│   │   └── tests/
│   ├── ui-react/                       # NEW: Future React UI
│   │   └── README.md                   # Placeholder for Phase 3 UI work
│   └── docs/
│       ├── REACT_CONVERSION_PLAN.md    # MOVE: from root
│       ├── CONVERSION_WORKFLOW_PROMPT.md # MOVE: from root
│       └── modernization-strategy.md   # New: Why this approach
│
├── infrastructure/                     # RENAME: iac/
│   ├── README.md                       # Infrastructure overview
│   ├── bicep/                          # Keep as-is
│   ├── terraform/                      # Keep as-is (if exists)
│   ├── scripts/                        # Keep as-is
│   └── docs/
│       ├── 4LAYER_RG_QUICK_REFERENCE.md        # MOVE: from root
│       ├── CREDENTIALS_AND_NEXT_STEPS.md       # MOVE: from root
│       ├── DEPLOYMENT_COMPLETE.md              # MOVE: from root
│       ├── DEPLOYMENT_SUMMARY.md               # MOVE: from root
│       ├── DOCUMENTATION_PACKAGE_README.md     # MOVE: from root
│       ├── IMPLEMENTATION_CHECKLIST.md         # MOVE: from root
│       ├── RESOURCE_GROUP_ORGANIZATION_FIX.md  # MOVE: from root
│       ├── THE_ISSUE_AND_FIX.md                # MOVE: from root
│       └── VISUAL_SUMMARY.md                   # MOVE: from root
│
├── database/                           # RENAME: Database/ (lowercase)
│   ├── README.md                       # Database schema overview
│   ├── JobsDB/                         # Keep as-is
│   └── SEED_DATA_CONFLICT_ANALYSIS.md  # Keep as-is
│
├── specs/                              # Keep as-is (spec-kit specs)
│   ├── README.md                       # Already exists
│   ├── QUICKSTART.md                   # Keep
│   ├── REVERSE_ENGINEERING_PROCESS.md  # MOVE: from root
│   ├── SPECS.md                        # MOVE: from root (rename INDEX.md if needed)
│   ├── 001-network-redesign/
│   └── 002-infra-reorg/
│
├── .squad/                             # Keep as-is
├── .github/                            # Keep as-is
├── .azure-pipelines/                   # Keep as-is
│
└── docs/                               # NEW: General documentation
    ├── INDEX.md                        # MOVE: from root (main nav)
    ├── LEARNING_PATH.md                # New: How to use this repo for learning
    └── CONTRIBUTING.md                 # New: How to contribute

# Files to DELETE (if appropriate after review):
# - INDEX.md (root) — Redundant with README if we create proper phase structure
```

---

## Rationale by Phase

### Phase 1: Legacy Baseline

**Folder:** `phase1-legacy-baseline/`

**Story:** "We have a legacy .NET 2.0 Web Forms app that won't build. First, we get it running."

**Contents:**
- `appV1-original/` — Original code, can't build (reference only)
- `appV1.5-buildable/` — Minimal changes to make it buildable (.sln, master pages)
- `docs/CODE_ANALYSIS_REPORT.md` — Analysis of legacy code issues

**Why:** Clearly labels this as "the starting point" for learners.

---

### Phase 2: Azure Migration

**Folder:** `phase2-azure-migration/`

**Story:** "We migrated the legacy app to Azure App Service + Azure SQL with minimal code changes."

**Contents:**
- Deployment guides for hosting legacy app on Azure PaaS
- Lessons learned from lift-and-shift
- Infrastructure as Code for PaaS deployment

**Why:** Shows the **migration** step before modernization. Critical teaching moment: you can migrate *before* rewriting.

**Note:** This phase may currently be represented by infrastructure docs. We consolidate deployment stories here.

---

### Phase 3: Modernization

**Folder:** `phase3-modernization/`

**Story:** "We built a modern API + React UI that runs alongside the legacy app."

**Contents:**
- `api-dotnet/` — ASP.NET Core 6+ clean architecture (currently appV2)
- `api-python/` — Python Flask alternative (currently appV3)
- `ui-react/` — Future React UI
- `docs/` — Modernization planning, conversion workflows

**Why:** Clearly signals this is the "modern" layer. Avoids confusion about "what is V2 vs V3?"

---

### Infrastructure

**Folder:** `infrastructure/` (renamed from `iac/`)

**Why rename?**
- More accessible to learners ("Infrastructure" is clearer than "IaC")
- All 9 infrastructure markdown docs move to `infrastructure/docs/`
- Keeps Bicep/Terraform organized

**Contents:**
- `bicep/` — Bicep templates
- `terraform/` — Terraform (if used)
- `scripts/` — Deployment scripts
- `docs/` — All infrastructure documentation (9 files from root)

---

### Database

**Folder:** `database/` (lowercase from `Database/`)

**Why:** Consistency — all top-level folders lowercase.

---

### Specs

**Folder:** `specs/` (keep as-is, add 2 files from root)

**Why:** Spec-kit structure already good. Just consolidate spec-related docs here.

**Changes:**
- Move `REVERSE_ENGINEERING_PROCESS.md` here
- Move `SPECS.md` here

---

### Docs

**Folder:** `docs/` (NEW)

**Why:** General learning documentation that doesn't fit in phase folders.

**Contents:**
- Learning paths (how to navigate this repo)
- Contributing guide
- Main index (moved from root)

---

## Files to Move

### From Root → phase1-legacy-baseline/docs/
- `CODE_ANALYSIS_REPORT.md`

### From Root → phase3-modernization/docs/
- `REACT_CONVERSION_PLAN.md`
- `CONVERSION_WORKFLOW_PROMPT.md`

### From Root → infrastructure/docs/
- `4LAYER_RG_QUICK_REFERENCE.md`
- `CREDENTIALS_AND_NEXT_STEPS.md`
- `DEPLOYMENT_COMPLETE.md`
- `DEPLOYMENT_SUMMARY.md`
- `DOCUMENTATION_PACKAGE_README.md`
- `IMPLEMENTATION_CHECKLIST.md`
- `RESOURCE_GROUP_ORGANIZATION_FIX.md`
- `THE_ISSUE_AND_FIX.md`
- `VISUAL_SUMMARY.md`

### From Root → specs/
- `REVERSE_ENGINEERING_PROCESS.md`
- `SPECS.md`

### From Root → docs/
- `INDEX.md` (evaluate if needed after new README)

---

## New README.md (Root)

```markdown
# Jobs Modernization — A Learning Journey

This repository demonstrates modernizing a legacy .NET Web Forms application to modern Azure cloud architecture through three phases.

## The Three-Phase Story

### 📦 Phase 1: Legacy Baseline
**Goal:** Get the legacy .NET 2.0 app running as-is.

- **Folder:** `phase1-legacy-baseline/`
- **App Versions:**
  - `appV1-original/` — Original code (can't build, reference only)
  - `appV1.5-buildable/` — Minimal changes to make it buildable
- **Learn:** Legacy architecture, code quality issues, .NET 2.0 → .NET Framework migration

➡️ [Start Phase 1](./phase1-legacy-baseline/README.md)

---

### ☁️ Phase 2: Azure Migration
**Goal:** Host on Azure App Service + Azure SQL with minimal code changes.

- **Folder:** `phase2-azure-migration/`
- **Key Concepts:** Lift-and-shift, PaaS hosting, connection string management
- **Learn:** Azure deployment, infrastructure as code, migration strategies

➡️ [Start Phase 2](./phase2-azure-migration/README.md)

---

### 🚀 Phase 3: Modernization
**Goal:** Add modern API + React UI alongside legacy app.

- **Folder:** `phase3-modernization/`
- **Modern Implementations:**
  - `api-dotnet/` — ASP.NET Core 6+ (clean architecture)
  - `api-python/` — Python Flask alternative
  - `ui-react/` — React SPA frontend (in progress)
- **Learn:** Clean architecture, API design, React integration, strangler fig pattern

➡️ [Start Phase 3](./phase3-modernization/README.md)

---

## Supporting Folders

### 🏗️ Infrastructure
**Folder:** `infrastructure/`

Bicep and Terraform templates for Azure deployment. All infrastructure documentation consolidated here.

➡️ [Infrastructure Guide](./infrastructure/README.md)

---

### 🗄️ Database
**Folder:** `database/`

SQL Server database project, schema, and seed data.

➡️ [Database Guide](./database/README.md)

---

### 📋 Specifications
**Folder:** `specs/`

Feature specifications using GitHub Spec Kit framework (spec → plan → tasks → implementation).

➡️ [Specs Index](./specs/README.md)

---

## Quick Start

**For Learners:**
1. Read [Learning Path](./docs/LEARNING_PATH.md)
2. Start with [Phase 1](./phase1-legacy-baseline/README.md)

**For Infrastructure Engineers:**
1. Review [Infrastructure Guide](./infrastructure/README.md)
2. Check [Deployment Docs](./infrastructure/docs/)

**For Developers:**
1. Explore [Phase 3 Modernization](./phase3-modernization/README.md)
2. Review [Clean Architecture API](./phase3-modernization/api-dotnet/README.md)

---

## Technologies

| Layer | Phase 1 | Phase 2 | Phase 3 |
|-------|---------|---------|---------|
| **UI** | Web Forms | Web Forms (hosted) | React SPA |
| **Backend** | .NET 2.0 | .NET Framework 4.x | .NET 6+ / Python |
| **Database** | SQL Server | Azure SQL | Azure SQL |
| **Hosting** | IIS on-prem | Azure App Service | Container Apps / AKS |
| **Architecture** | Monolith | Monolith (PaaS) | Clean Architecture + API |

---

## Contributing

See [CONTRIBUTING.md](./docs/CONTRIBUTING.md)

---

**Learning Repository** — Built to teach .NET modernization strategies.
```

---

## Execution Plan

**DO NOT EXECUTE YET — This is a proposal.**

Once approved:

1. **Create new folders** (phase1, phase2, phase3, infrastructure, database, docs)
2. **Move files** as documented above
3. **Rename folders** (appV1 → appV1-original, appV2 → api-dotnet, etc.)
4. **Create README.md files** for each phase folder
5. **Update root README.md** with learning journey map
6. **Update all internal links** in moved documents
7. **Test navigation** — ensure learners can follow the path
8. **Commit with message:** "Reorganize repo to tell three-phase modernization story"

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Broken links** | High | Script to update all relative links after move |
| **CI/CD paths** | Medium | Update `.azure-pipelines/` and `.github/workflows/` paths |
| **Developer confusion** | Medium | Clear communication, update team documentation |
| **Git history** | Low | Git preserves history across renames with `git log --follow` |

---

## Success Criteria

- [ ] Root directory has ≤5 files (README, .gitignore, license, etc.)
- [ ] Folder names tell the story without reading docs
- [ ] Each phase has a clear README explaining its purpose
- [ ] All infrastructure docs consolidated in `infrastructure/docs/`
- [ ] All internal links work
- [ ] CI/CD pipelines still work
- [ ] New contributors can navigate without asking questions

---

## Open Questions

1. **INDEX.md at root** — Keep or delete after creating new README?
   - **Recommendation:** Review after new README created. If redundant, delete.

2. **Phase 2 content** — Currently empty. Should we create deployment guides now or later?
   - **Recommendation:** Create placeholder README, populate later as needed.

3. **vm-rdc-conns.rdg** — Remote Desktop connection file. Keep at root or move to infrastructure/?
   - **Recommendation:** Move to `infrastructure/docs/` or `infrastructure/rdp/`

4. **cleanup_secrets.py / CLEANUP_SECRETS.ps1** — Move to infrastructure/scripts/?
   - **Recommendation:** Yes, move to `infrastructure/scripts/`

---

## Decision Required

**Approve this proposal?**

- ✅ Yes, proceed with reorganization
- ❌ No, needs revision (provide feedback)
- ⏸️ Hold, needs discussion

**Reviewer:** ivegamsft  
**Awaiting:** Approval before execution
