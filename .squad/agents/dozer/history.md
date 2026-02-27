# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-27: Deep Infrastructure Audit — Critical Findings

**Context:** Comprehensive audit of all IaC (Bicep + Terraform), CI/CD pipelines, deployment scripts, and documentation.

**Key Infrastructure Patterns:**
- **Bicep structure**: `infrastructure/bicep/{core,iaas,paas,agents}/` — each has `main.bicep` (subscription-scoped entry point) + `*-resources.bicep` (resource-group-scoped module) + parameter files
- **Terraform structure**: `infrastructure/terraform/{core,iaas,paas,agents}/` — modular with `main.tf`/`variables.tf`/`outputs.tf` per module, root orchestrates with conditional `count` deployment
- **Deployment scripts**: `infrastructure/scripts/Deploy-Bicep.ps1` (main orchestrator), `infrastructure/deploy-core.ps1`, `infrastructure/deploy-iaas-clean.ps1`, `infrastructure/deploy-paas-simple.ps1` (layer-specific)
- **CI/CD**: Both `.github/workflows/` and `.azure-pipelines/` exist with 11 pipelines each (deploy-core, deploy-iaas, deploy-paas, deploy-agents, deploy-vpn, deploy-app-iaas, deploy-app-paas, deploy-database-dac-iaas, deploy-database-dac-paas, build-jobsiteweb, build-database-dacpac)

**Critical Findings:**
1. **ALL 22 CI/CD pipelines broken** — reference old `iac/` path (now `infrastructure/`)
2. **Bicep agents/main.bicep has compile error** — duplicate resource declaration
3. **Bicep iaas/main.bicep and agents/main.bicep** — hardcoded VNet name from specific dev deployment
4. **5+ parameter files have hardcoded passwords** committed to git
5. **Bicep Key Vault defaults to Allow all networks** — Terraform correctly uses Deny
6. **Container Apps subnet missing delegation** in Bicep (Terraform has it)
7. **No subnet-level NSGs** in core network layer

**Terraform vs Bicep Verdict:** Terraform is more production-ready. Has conditional deployment, variable validation, proper state management, and better security defaults.

**Key File Paths:**
- Bicep entry points: `infrastructure/bicep/{core,iaas,paas,agents}/main.bicep`
- Terraform entry: `infrastructure/terraform/main.tf`
- Main deploy script: `infrastructure/scripts/Deploy-Bicep.ps1`
- Network config: Subnets defined in `infrastructure/bicep/core/core-resources.bicep` (lines 26-55) and `infrastructure/terraform/core/main.tf` (locals block)
- VNet: 10.50.0.0/21 (2,048 IPs), 7 subnets, 44% reserved

**Audit Report:** `.squad/decisions/inbox/dozer-infra-audit.md` — 23 prioritized fix items

**Status:** ✅ Audit complete, report delivered

### 2026-02-27: Repository Reorganization Complete— Infrastructure Consolidated, Phase Structure Ready

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

### 2026-02-27: Infrastructure Documentation Cleanup — 13 Deleted, 18 Fixed, Merged to Decisions

**Context:** Post-reorganization audit of all markdown files under `infrastructure/`. After the `iac/` → `infrastructure/` rename, most docs had stale paths, some contained exposed credentials, and many were redundant duplicates.

**Files Deleted (13):**
1. `infrastructure/DEPLOYMENT_STATUS.md` — Contained hardcoded passwords in plaintext + all `iac/` paths
2. `infrastructure/docs/CREDENTIALS_AND_NEXT_STEPS.md` — Contained actual passwords (security risk)
3. `infrastructure/bicep/INDEX.md` — Referenced old flat `iac/` structure with nonexistent files
4. `infrastructure/bicep/QUICK_START.md` — Referenced old flat structure (main.bicep at root)
5. `infrastructure/bicep/DEPLOYMENT_VALIDATION.md` — Same flat structure assumptions
6. `infrastructure/bicep/NETWORK_SECURITY_COMPLETE.md` — Duplicate status doc (same NSG tables repeated)
7. `infrastructure/bicep/NETWORK_SECURITY_FILES_INDEX.md` — 414-line duplicate index
8. `infrastructure/bicep/NETWORK_SECURITY_INDEX.md` — Another duplicate navigation doc
9. `infrastructure/bicep/NETWORK_SECURITY_QUICKSTART.md` — Overlapped with existing summaries
10. `infrastructure/bicep/README_NETWORK_SECURITY_CHANGES.md` — Duplicate changelog
11. `infrastructure/bicep/paas/FILE_INDEX.md` — Directory listing (no value over `ls`)
12. `infrastructure/bicep/paas/INTEGRATION_SUMMARY.md` — Changelog duplicate
13. `infrastructure/bicep/paas/COMPLETION_REPORT.md` — Status doc, not useful for learners

**Files Fixed (18):**
- All remaining `iac/` path references → `infrastructure/` across 17 files
- `infrastructure/bicep/README.md` — Fixed `appV2/appV3` → `phase3-modernization/` paths
- `infrastructure/bicep/core/README.md` — Fixed wrong VNet CIDR (10.50.0.0/16 → /21), wrong subnet sizes
- `infrastructure/terraform/STATUS.md` — Fixed iaas/paas/agents shown as ⏳ pending → ✅ complete
- `infrastructure/docs/4LAYER_RG_QUICK_REFERENCE.md` — Fixed broken appV2 link
- `infrastructure/README.md` — Removed reference to deleted CREDENTIALS doc

**Decision Criteria:**
- DELETE: Contains credentials, references nonexistent files, pure duplicate of another doc
- FIX: Good content with stale paths only
- KEEP: Accurate, useful for the three-phase learning journey

**Key Learning:** Network security docs had 10 files for one feature — consolidated to 5 essential docs.

**Team Awareness:** Merged decision to `.squad/decisions.md`. All agents now aware docs were cleaned.

**Status:** ✅ Complete, committed, merged to decisions

### 2026-02-27: Infrastructure Script Cleanup — 5 Deleted, 7 Fixed, 12 Consolidated

**Context:** User directive to clean up scattered deployment scripts in `infrastructure/`. Audited all 20 script files across 4 locations.

**Scripts Deleted (5):**
1. `deploy-app-layers.ps1` — Hardcoded `c:\git\jobs_modernization\iac\` paths (lines 101, 151), weak password generation ("Aa1" suffix), superseded by individual deploy-iaas-clean.ps1 and deploy-paas-simple.ps1
2. `deploy-iaas-v2.ps1` — Hardcoded `c:\git\...\iac\` path (line 113), prints passwords to console, superseded by deploy-iaas-clean.ps1
3. `redeploy-iaas-wfe.ps1` — One-time troubleshooting script for group-level redeployment, covered by main deploy script
4. `scripts/CLEANUP_SECRETS.ps1` — One-time git history cleanup tool, contained redacted password patterns, hardcoded path, already been used
5. `scripts/cleanup_secrets.py` — Python duplicate of above, same issues

**Scripts Fixed (7):**
1. `deploy-core.ps1` — Changed `$PSScriptRoot\scripts\` → `$PSScriptRoot\` (now co-located), `./bicep/` → `$PSScriptRoot\..\bicep\`, replaced hardcoded KV name with dynamic lookup
2. `deploy-iaas-clean.ps1` — Replaced weak inline password gen (12 chars + "Aa1") with dot-sourced `New-SecurePassword.ps1` (20 chars, proper complexity), fixed template/params paths to `$PSScriptRoot\..`
3. `deploy-paas-simple.ps1` — `c:\git\jobs_modernization\iac\bicep\paas\` → `$PSScriptRoot\..\bicep\paas\`
4. `deploy-vpn.ps1` — Removed `Set-Location "c:\git\...\iac\bicep\core"`, used `$PSScriptRoot\..\bicep\core\` in params
5. `deploy-agents.ps1` — `./bicep/agents/main.bicep` → `$PSScriptRoot\..\bicep\agents\main.bicep`
6. `diagnose.ps1` — `c:\git\...\iac\bicep\iaas\` → `$PSScriptRoot\..\bicep\iaas\`
7. `update-core-add-containers.ps1` — `c:\git\...\iac\bicep\core\` → `$PSScriptRoot\..\bicep\core\`

**Scripts Consolidated (12 moved):**
- All 10 root-level scripts moved from `infrastructure/` → `infrastructure/scripts/`
- `bicep/core/create-nat-inbound-rules.ps1` → `scripts/create-nat-inbound-rules.ps1`
- All paths updated to use `$PSScriptRoot`-based references so scripts work regardless of CWD

**Scripts Kept In Place (3):**
- `scripts/Deploy-Bicep.ps1` — Main orchestrator, already in scripts/
- `scripts/New-SecurePassword.ps1` — Shared utility, already in scripts/
- `bicep/iaas/scripts/iis-install.ps1` — VM extension script, must stay with Bicep template

**Key Pattern:** All scripts now use `$PSScriptRoot\..` to resolve paths to the infrastructure root. No hardcoded absolute paths remain.

**Status:** ✅ Complete, committed
