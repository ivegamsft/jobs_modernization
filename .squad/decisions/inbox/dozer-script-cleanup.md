# Infrastructure Script Cleanup

**Decision ID:** script-cleanup-2026-02-27
**Author:** Dozer (DevOps)
**Status:** Executed
**Impact:** Medium (developer experience, security hygiene)

## Context

The `infrastructure/` directory had 20 PowerShell scripts scattered across 4 locations (root, scripts/, bicep/core/, bicep/iaas/scripts/). Many had hardcoded absolute paths to `c:\git\jobs_modernization\iac\`, weak password generation, or were one-time tools no longer needed.

## Decision

Audited every script. Applied three rules:
1. **DELETE** if superseded, hardcoded paths with no unique value, one-time cleanup tool, or security liability
2. **FIX** if worth keeping but had wrong paths or weak patterns
3. **CONSOLIDATE** all deployment scripts into `infrastructure/scripts/`

## What Changed

### Deleted (5 scripts, -492 lines)
- `deploy-app-layers.ps1` — Superseded, hardcoded `iac/` paths, weak passwords
- `deploy-iaas-v2.ps1` — Superseded by deploy-iaas-clean.ps1, hardcoded paths
- `redeploy-iaas-wfe.ps1` — One-time troubleshooting script
- `CLEANUP_SECRETS.ps1` — One-time git history cleanup with password patterns
- `cleanup_secrets.py` — Python duplicate of above

### Fixed (7 scripts)
All hardcoded `c:\git\jobs_modernization\iac\` paths replaced with `$PSScriptRoot\..` references. One script's weak password generation (12 chars + "Aa1") replaced with shared `New-SecurePassword.ps1` (20 chars, proper complexity).

### Consolidated
All scripts now live in `infrastructure/scripts/`. The only exception is `bicep/iaas/scripts/iis-install.ps1` which is a VM extension script that must stay adjacent to its Bicep template.

## Final Script Inventory (15 scripts)

| Script | Purpose |
|--------|---------|
| `Deploy-Bicep.ps1` | Full-stack orchestrator (core + iaas + paas) |
| `deploy-core.ps1` | Core layer (VNet, Key Vault, Log Analytics) |
| `deploy-iaas-clean.ps1` | IaaS layer (VMs, Load Balancer) |
| `deploy-paas-simple.ps1` | PaaS layer (App Service, SQL Database) |
| `deploy-agents.ps1` | CI/CD agents (VMSS) |
| `deploy-vpn.ps1` | VPN Gateway |
| `update-core-add-containers.ps1` | Add ACR + Container Apps to core |
| `bootstrap-terraform-backend.ps1` | Terraform state storage setup |
| `New-SecurePassword.ps1` | Shared password generation utility |
| `create-nat-inbound-rules.ps1` | NAT Gateway port mappings |
| `check-status.ps1` | Deployment status checker |
| `diagnose.ps1` | Azure CLI diagnostics |
| `get-credentials.ps1` | Key Vault credential retrieval |
| `iis-install.ps1` | VM extension (in bicep/iaas/scripts/) |

## Implications for Team

1. **All deployment scripts are now in ONE place:** `infrastructure/scripts/`
2. **Scripts work from any CWD** — all paths are `$PSScriptRoot`-based
3. **No hardcoded absolute paths remain** in any script
4. **Docs may have stale script path references** — flag for next doc audit
