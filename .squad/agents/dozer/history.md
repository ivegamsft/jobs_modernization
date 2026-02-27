# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Repository Reorganization Complete — Infrastructure Consolidated, Phase Structure Ready

**Context:** Team orchestration complete. Repository reorganization from Morpheus (proposed) + Dozer (executed) is finalized and documented.

**What Changed:**
- Repository now organized into three-phase learning journey
- 440+ files moved with Git history preserved
- Root cleaned from 15+ markdown files to 3 core files
- 9 infrastructure markdown docs consolidated to `infrastructure/docs/`
- Utility files organized: RDP connection files, cleanup scripts → infrastructure/
- 8 new README files created for phase guidance

**Key Infrastructure Changes:**
- `iac/` → `infrastructure/` (all Bicep, Terraform, scripts consolidated)
- All deployment documentation (9 files) moved to `infrastructure/docs/`
- Added `infrastructure/README.md` explaining IaC structure
- Cleanup scripts organized to `infrastructure/scripts/`
- RDP connection files moved to `infrastructure/`

**Windows Git Technique Learnings:**
- `git mv` is primary choice (preserves history)
- Move-Item + git add for directory renames (shows "R" in status, not "D+A")
- Temp directory technique needed for case-only renames on Windows (Database → database)
- Verification: Always check `git status` after each operation to confirm "R" not "D+A"

**Team Synchronization:**
- Morpheus documented architectural analysis and decision-making
- Scribe wrote orchestration logs, merged decision inbox, updated agent histories
- All team members now aware of reorganization via `.squad/decisions.md`
- Future work ready to proceed with clear phase structure

**Status:** ✅ Reorganization complete, committed, all agents synchronized

### 2026-02-27: Repository Reorganization Execution

**Task:** Executed Morpheus's approved repository reorganization to transform the repo into a three-phase learning journey.

**What Was Moved:**

1. **App Version Folders:**
   - `appV1` → `phase1-legacy-baseline/appV1-original/`
   - `appV1.5-JobsSiteWeb` → `phase1-legacy-baseline/appV1.5-buildable/`
   - `appV2` → `phase3-modernization/api-dotnet/`
   - `appV3` → `phase3-modernization/api-python/`

2. **Root Markdown Files (15 files):**
   - 9 infrastructure docs → `infrastructure/docs/`
   - 1 legacy doc → `phase1-legacy-baseline/docs/`
   - 2 modernization docs → `phase3-modernization/docs/`
   - 2 spec docs → `specs/`
   - 1 navigation doc → `docs/`

3. **Infrastructure Rename:**
   - `iac/` → `infrastructure/` (all contents moved via Move-Item + git add)

4. **Database Rename:**
   - `Database/` → `database/` (lowercase, via temp directory to handle Windows case-insensitive rename)

5. **Utility Files:**
   - `vm-rdc-conns.rdg` → `infrastructure/`
   - `cleanup_secrets.py`, `CLEANUP_SECRETS.ps1` → `infrastructure/scripts/`

**New Structure Created:**
- `phase1-legacy-baseline/` — Legacy baseline story
- `phase2-azure-migration/` — PaaS migration story  
- `phase3-modernization/` — Modern API + React story
- `infrastructure/` — All IaC consolidated
- `database/` — Database assets (lowercase)
- `docs/` — General learning docs

**READMEs Created:**
- Phase 1, 2, 3 README files explaining each learning phase
- `phase3-modernization/ui-react/README.md` — React UI placeholder
- `infrastructure/README.md` — Infrastructure overview
- `database/README.md` — Database documentation
- `docs/LEARNING_PATH.md` — Complete learning journey guide
- Updated root `README.md` — New learning journey map

**Git Operations:**
- Used `git mv` for all file/folder moves (preserves history)
- Used `Move-Item` + `git add` for `iac/` → `infrastructure/` (directory rename)
- Used temp directory technique for `Database/` → `database/` (case-only rename on Windows)
- 401 renamed, 8 added, 1 modified, 12 deleted = 440 total changes

**Key Decisions:**
1. **Preserve Git History:** Always used `git mv` to maintain file lineage
2. **Windows Path Handling:** Used backslashes, temp directories for case-only renames
3. **Comprehensive READMEs:** Each phase tells its story clearly for learners
4. **Clean Root:** Reduced root to 3 files (.gitignore, .gitattributes, README.md)

**Outcome:**
Repository now clearly communicates the three-phase modernization journey. Folder names are self-documenting. All 15 loose markdown files organized into logical homes. Infrastructure consolidated. Ready for learners to follow the path from legacy → Azure PaaS → modern architecture.
