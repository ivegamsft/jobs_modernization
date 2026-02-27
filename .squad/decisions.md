# Decisions

> Shared decision log. All agents read this before starting work.
> Scribe merges new decisions from `.squad/decisions/inbox/`.

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
