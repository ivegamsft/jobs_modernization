# Infrastructure Audit Report

**Author:** Dozer (DevOps)
**Date:** 2026-02-27
**Scope:** Full infrastructure audit — Bicep, Terraform, CI/CD, scripts, docs, networking
**Verdict:** ⚠️ Significant issues found. Not deployable as-is in most configurations.

---

## Executive Summary

I read every infrastructure file in this repository. The *design* is solid — layered architecture (core/iaas/paas/agents), proper separation of concerns, good subnet planning. But the *implementation* has critical gaps: hardcoded environment-specific values, parameter mismatches between templates and their param files, broken CI/CD paths after the repo reorganization, and multiple hardcoded passwords committed to source. **Terraform is more production-ready than Bicep.** Neither is deployable without fixes.

---

## 1. Bicep Templates (`infrastructure/bicep/`)

### ✅ What's Good

- **Layered architecture**: Core → IaaS → PaaS → Agents follows Azure best practices
- **Subscription-scoped deployments**: Resource groups created by templates (idempotent)
- **Security patterns**: Key Vault with RBAC, managed identities on all VMs, Entra ID authentication
- **VM extensions chain**: Proper dependency ordering (init → AAD → antimalware → monitoring)
- **Private endpoints**: ACR in core, SQL in PaaS both use private endpoints
- **NAT Gateway**: Proper outbound control for all backend subnets
- **Tagging**: Consistent Application/Environment/ManagedBy tags across all resources

### ❌ Broken — Deployment Blockers

**B1. `agents/main.bicep` — Duplicate resource declaration (lines 50-58)**
```bicep
resource githubRunnersSubnet '...' existing = { name: 'snet-github-runners' ... }
resource githubRunnersSubnet '...' existing = { name: 'snet-github-runners' ... }
```
Exact same resource declared twice. **Bicep will refuse to compile.**

**B2. `agents/main.bicep` — Wrong subnet name (line 51)**
References `'snet-github-runners'` but the subnet is defined as `'snet-gh-runners'` in `core/core-resources.bicep` (line 36). Even after fixing B1, this will fail with "subnet not found."

**B3. `iaas/main.bicep` — Hardcoded VNet name (line 45)**
```bicep
resource vnet '...' existing = { name: 'jobsite-dev-vnet-ubzfsgu4p5eli' }
```
This is a `uniqueString()`-derived name from a specific dev deployment. **Will fail in any other environment or subscription.** Same issue in `agents/main.bicep` (line 45).

**B4. `core/deploy-vpn.bicep` — Passes undefined parameter (line 46)**
```bicep
module vpnGateway './vpn-gateway.bicep' = {
  params: { vnetName: vnetLookup.outputs.vnetName ... }
}
```
But `vpn-gateway.bicep` has no `vnetName` parameter. **Deployment will fail.**

**B5. `core/nat-inbound-rules.bicep` — Invalid resource type**
Uses `Microsoft.Network/natGateways/inboundNatRules` — this resource type **does not exist**. NAT Gateways only handle outbound traffic. Inbound NAT rules belong on Load Balancers.

**B6. `iaas/parameters.bicepparam` — Complete parameter mismatch**
References params that don't exist in `iaas/main.bicep`: `vnetId`, `frontendSubnetId`, `dataSubnetId`, `logAnalyticsWorkspaceId`, `vmssInstanceCount`, `vmssVmSize`, `sqlAdminUsername`, `sqlAdminPassword`, `vmAdminUsername`, `vmAdminPassword`, `appGatewayCertData`, `appGatewayCertPassword`. **None of these match.** This `.bicepparam` file was written for a different version of the template.

**B7. `paas/parameters.bicepparam` — Parameter mismatch**
References `sqlAdminUsername`, `sqlAdminPassword`, `vnetId`, `keyVaultId`, `keyVaultName`, `privateDnsZoneId`, `privateDnsZoneName`. The actual `paas/main.bicep` requires `sqlAadAdminObjectId`, `sqlAadAdminName`, `containerAppsSubnetId`, `coreResourceGroupName` — none of which are in the param file.

**B8. `core/parameters.bicepparam` — Missing required secure params**
Doesn't supply `sqlAdminPassword` or `wfeAdminPassword`. Both are `@secure()` with no defaults. Deployment will prompt interactively (breaks automation).

**B9. `agents/agents-resources.bicep` — Invalid conditional in array (line 189)**
```bicep
if (!empty(keyVaultCertificateUrls)) {
  name: 'KeyVaultForWindows'
```
This `if` syntax inside an extension array literal is not valid Bicep for VMSS extension profiles.

### ⚠️ Needs Review

**B10. Duplicate ACR**: Core creates a Premium ACR (`core-resources.bicep` line 274) and PaaS creates a Basic ACR (`paas-resources.bicep` line 150). This duplicates cost and creates confusion about which registry to use.

**B11. Container Apps subnet missing delegation**: In `core-resources.bicep`, the `snet-ca` subnet has no `delegation` for `Microsoft.App/environments`. Container Apps Environment deployment in PaaS will fail because Azure requires the delegation. Terraform correctly has this (line 213-222 of `core/main.tf`).

**B12. `iaas/main.bicep` line 15**: `@secure() param adminPassword string = newGuid()` — GUIDs are not cryptographically random passwords. This "works" but is a security concern and generates new credentials on every redeployment.

**B13. No NSGs on core subnets**: VNet subnets are created without Network Security Groups. NSGs only exist in the IaaS module for frontend/data NICs. AKS, Container Apps, Private Endpoint, and GitHub Runners subnets have **zero network protection** at the subnet level.

**B14. `agents/agents-resources.bicep` — Orphaned NIC**: Lines 29-46 create a standalone Network Interface that is never attached to the VMSS (VMSS has its own networkProfile). This NIC will be created and immediately orphaned.

### 🔒 Security Issues

**B15. Hardcoded passwords in source control:**
| File | Line | Value |
|------|------|-------|
| `iaas/parameters.dev.json` | 24 | `VmAdmin@2024!Secure` |
| `paas/parameters.bicepparam` | 16 | `ChangeMe@123456` |
| `paas/main.dev.bicepparam` | 10 | `ChangeMe@12345678!` |
| `paas/main.staging.bicepparam` | 10 | `ChangeMe@87654321!` |
| `paas/main.prod.bicepparam` | 10 | `ChangeMe@ProdPassword!` |

Even if these are "example" values, they're in tracked files and will appear in git history. The `parameters.dev.json` password looks like it was actually used.

**B16. `iaas/parameters.dev.json`** contains hardcoded subscription ID (`844eabcc-dc96-453b-8d45-bef3d566f3f8`) and full resource IDs.

**B17. Key Vault network ACL set to `Allow`**: In `core-resources.bicep` line 234, Key Vault `defaultAction: 'Allow'` exposes it to all networks. Terraform version correctly uses `Deny` with subnet allowlisting.

### Phase Mapping

| Layer | Phase | Status |
|-------|-------|--------|
| `core/` | All phases (shared) | ⚠️ Deployable with fixes to params |
| `iaas/` | Phase 1 (IaaS baseline) | ❌ Blocked by hardcoded VNet name |
| `paas/` | Phase 2 (Azure migration) | ❌ Blocked by param mismatches |
| `agents/` | All phases (CI/CD) | ❌ Blocked by compile error |

---

## 2. Terraform (`infrastructure/terraform/`)

### ✅ What's Good

- **Conditional module deployment**: `deploy_iaas`, `deploy_paas`, `deploy_agents` booleans — excellent for phased approach
- **State management**: Azure Storage backend with environment-specific keys
- **Variable validation**: Environment must be dev/staging/prod, password >= 20 chars, VMSS count 1-100
- **Provider configuration**: Key Vault soft-delete protection, proper VM deletion behavior
- **Modular structure**: Clean separation (core/iaas/paas/agents) with proper inter-module references
- **Key Vault security**: `default_action = "Deny"` with subnet-scoped access
- **Container Apps subnet delegation**: Correctly configured (`Microsoft.App/environments`)
- **Availability zones**: NAT Gateway and public IPs use zones 1,2,3

### ⚠️ Needs Review

**T1. `staging.tfvars` and `prod.tfvars` — Missing `subscription_id`**
This is a required variable with no default. `terraform plan -var-file=staging.tfvars` will fail prompting for subscription_id.

**T2. `staging.tfvars` — Undefined variables (lines 26-27)**
References `sql_database_edition` and `sql_service_objective` but the actual variable is `sql_database_sku`. These will be silently ignored by default or cause errors with `--strict`.

**T3. `dev.tfvars` — Subscription ID committed (line 8)**
`subscription_id = "844eabcc-dc96-453b-8d45-bef3d566f3f8"` — should come from environment variable or Key Vault reference.

**T4. STATUS.md is outdated**: Says IaaS, PaaS, and Agents modules are "⏳ remaining" but all three modules exist and are fully implemented.

**T5. Key Vault secret creation may fail**: With `default_action = "Deny"`, the deploying identity needs both RBAC permission AND network access. If deploying from a non-allowlisted IP (like a CI/CD runner not in the VNet), secret creation will be blocked.

**T6. Hardcoded subnet CIDRs**: Both Bicep and Terraform hardcode `10.50.x.x` subnet prefixes regardless of the `vnet_address_prefix` variable. Changing the VNet prefix without updating all subnet configs will create conflicts.

### ❌ Missing

**T7. No Terraform CI/CD pipelines**: Neither GitHub Actions nor Azure Pipelines include Terraform workflows. STATUS.md notes this as a next step.

**T8. No `staging.hcl` or `prod.hcl`**: Only `backend-dev.hcl` exists for state backend config.

### Terraform vs Bicep Comparison

| Aspect | Bicep | Terraform |
|--------|-------|-----------|
| Deployable | ❌ Multiple blockers | ⚠️ Close, needs tfvars fixes |
| State management | N/A (ARM handles) | ✅ Azure Storage backend |
| Conditional deploy | ❌ No toggle mechanism | ✅ `deploy_*` booleans |
| Variable validation | ❌ None | ✅ Type + constraint checks |
| Key Vault security | ⚠️ Allow all | ✅ Deny + subnet allowlist |
| Subnet delegation | ❌ Missing for CA | ✅ Correct |
| Password handling | ❌ Hardcoded in files | ✅ Env vars (TF_VAR_*) |
| Multi-environment | ⚠️ Separate param files | ✅ tfvars per environment |

**Verdict: Terraform is the more production-ready IaC tool for this project.**

---

## 3. Deployment Scripts (`infrastructure/scripts/` and `infrastructure/*.ps1`)

### ✅ What's Good

- **`Deploy-Bicep.ps1`**: Comprehensive orchestration — auto-generates passwords, creates certs, chains core → iaas → paas
- **`New-SecurePassword.ps1`**: Good password generation — excludes ambiguous chars, guarantees character class diversity
- **`deploy-core.ps1`**: Uses `New-SecurePassword`, proper error handling, clean output
- **`deploy-paas-simple.ps1`**: Auto-retrieves core outputs, auto-detects current user for SQL AAD admin
- **All scripts**: Have `$ErrorActionPreference = 'Stop'` and check `$LASTEXITCODE`

### ❌ Issues

**S1. `Deploy-Bicep.ps1` — Password parameter mismatch**
- Line 189: Passes `vpnRootCertificate` to core template, but `core/main.bicep` has no such parameter
- Lines 241-248: Passes `vnetId`, `logAnalyticsWorkspaceId`, `appGatewayCertData`, `appGatewayCertPassword` to IaaS template — none exist in `iaas/main.bicep`
- Missing: `wfeAdminPassword` for core, `adminPassword` for IaaS

**S2. `Deploy-Bicep.ps1` — Passwords printed to console (lines 106-108, 337-340)**
```powershell
Write-Host "   Password: $SqlAdminPassword" -ForegroundColor Yellow
```
In a CI/CD environment, this would be logged. Should use `Write-Warning` or write to Key Vault only.

**S3. `Deploy-Bicep.ps1` — Weak password generation (line 100)**
Internal `New-SecurePassword` generates only 16 characters. Terraform validation requires 20+. The standalone `New-SecurePassword.ps1` script defaults to 20 chars, but the embedded function is weaker.

**S4. `deploy-iaas-clean.ps1` — Weak password generation (lines 26-30)**
```powershell
$adminPassword = -join ((1..12) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
$adminPassword += $special[(Get-Random -Maximum $special.Length)]
$adminPassword += "Aa1"
```
12 random chars + "Aa1" suffix = predictable pattern, only 16 chars total.

**S5. `deploy-paas-simple.ps1` — Old hardcoded path (line 41)**
```powershell
--template-file "c:\git\jobs_modernization\iac\bicep\paas\main.bicep"
```
Should be `infrastructure/bicep/paas/main.bicep` and use relative paths.

**S6. `CLEANUP_SECRETS.ps1` — Contains redacted password patterns (line 17)**
While these are redacted, the replacement mapping reveals password length and structure. Also hardcodes a specific GitHub repo URL.

---

## 4. CI/CD Pipelines

### ❌ ALL PIPELINES ARE BROKEN

**C1. Every pipeline references old `iac/` path structure.**

After the repo reorganization (`iac/` → `infrastructure/`), all 22 pipeline files (11 GitHub Actions + 11 Azure Pipelines) reference the old paths:

| Issue | Files Affected | Old Path | Correct Path |
|-------|---------------|----------|-------------|
| Trigger paths | All 22 | `iac/bicep/**` | `infrastructure/bicep/**` |
| Template file | All deploy-* | `./iac/bicep/*/main.bicep` | `./infrastructure/bicep/*/main.bicep` |
| Azure Pipelines paths | All 11 | `azure-pipelines/` | `.azure-pipelines/` |

**C2. Missing required parameters in all deployment pipelines.**
None of the deploy workflows pass secure parameters (`sqlAdminPassword`, `wfeAdminPassword`, `adminPassword`). Deployments will fail or prompt interactively (which fails in CI).

**C3. GitHub Actions — Wrong shell syntax (multiple files)**
```yaml
echo "IAAS_DEPLOYED=true" >> $env:GITHUB_OUTPUT
```
`$env:GITHUB_OUTPUT` is PowerShell syntax. Pipeline runs on `ubuntu-latest` with bash shell. Should be `$GITHUB_OUTPUT`.

**C4. No environment protection**: No `environment` declarations with required reviewers or approval gates. A push to `main` could trigger production deployment without approval.

**C5. No what-if / plan step**: Pipelines deploy directly without a `--what-if` preview or `terraform plan` step. Risky for production environments.

### ⚠️ What's Partially Right

- OIDC authentication (`id-token: write` + `azure/login@v2`) — correct pattern
- Artifact upload of deployment outputs — good for cross-pipeline dependency
- Path-based triggers — good for selective deployment (once paths are fixed)

---

## 5. Infrastructure Docs

### ⚠️ Documentation-Reality Gaps

**D1. `bicep/INDEX.md` — All file paths reference `iac/` (old structure)**
Every path reference throughout the 430-line file points to `iac/main.bicep`, `iac/main.dev.bicepparam`, etc. These no longer exist.

**D2. `bicep/INDEX.md` — References nonexistent files**
- `deploy-bicep.sh` (Linux bash script — never created)
- `PACKAGE_SUMMARY.md` — not found in current structure
- `main.dev.bicepparam`, `main.staging.bicepparam`, `main.prod.bicepparam` at `iac/` root — these are actually in `paas/` subdirectory

**D3. `bicep/README.md` — Stale cross-references (lines 343-344)**
References `../../appV2/README.md` and `../../appV3/README.md`. After reorganization, these are at `../../phase3-modernization/api-dotnet/` and `../../phase3-modernization/api-python/`.

**D4. `terraform/STATUS.md` — Says modules are incomplete but they exist**
Marks IaaS, PaaS, and Agents as "⏳ remaining" even though all three modules are fully written.

**D5. Architecture docs describe correct design**: `NETWORK_REDESIGN.md`, subnet table in `README.md` — these accurately reflect the Bicep/Terraform subnet layout. The network design docs are trustworthy.

---

## 6. Network Architecture

### ✅ Well-Designed

| Subnet | CIDR | IPs | Phase | Verdict |
|--------|------|-----|-------|---------|
| snet-fe | 10.50.0.0/24 | 251 | 1 (IaaS) | ✅ App Gateway needs /24+ |
| snet-data | 10.50.1.0/26 | 59 | 1 (IaaS) | ✅ Sufficient for SQL VMs |
| snet-gh-runners | 10.50.1.64/26 | 59 | All | ✅ CI/CD agents |
| snet-pe | 10.50.1.128/27 | 27 | 2 (PaaS) | ✅ Private endpoints |
| GatewaySubnet | 10.50.1.160/27 | 27 | All | ✅ Azure minimum for VPN GW |
| snet-aks | 10.50.2.0/23 | 507 | 3 (K8s) | ✅ 250+ pods |
| snet-ca | 10.50.4.0/26 | 59 | 3 (Containers) | ✅ Container Apps |
| Reserved | 10.50.4.64+ | 896 | Future | ✅ 44% for growth |

- CIDR ranges don't overlap
- 2,048 total IPs in /21 is appropriate
- Growth room is generous
- Proper VPN client address pool separation (172.16.0.0/24 or 10.70.0.0/24 depending on config)

### ⚠️ Issues

**N1. No subnet-level NSGs in core**: All 7 subnets are created without NSGs. Only IaaS module creates NSGs, and only for NIC-level association. The AKS, Container Apps, Private Endpoint, and GitHub Runners subnets are wide open at the network layer.

**N2. Container Apps subnet needs delegation (Bicep only)**: Missing `Microsoft.App/environments` delegation. Terraform has this correct.

**N3. Hardcoded subnet CIDRs**: Subnet ranges are hardcoded in both Bicep and Terraform variables/locals. Changing `vnetAddressPrefix` from `10.50.0.0/21` would not update any subnet — they'd fall outside the VNet range.

**N4. NAT Gateway not on data subnet in Bicep**: The data subnet (`snet-data`) gets NAT Gateway in `core-resources.bicep` line 137, but the SQL VM should ideally have controlled outbound via NAT Gateway — this is actually correct. ✅

---

## 📋 Prioritized Fix List

### Priority 1: Deployment Blockers (fix these first)

| # | Component | Issue | Effort |
|---|-----------|-------|--------|
| 1 | `agents/main.bicep` | Remove duplicate `githubRunnersSubnet` declaration | 5 min |
| 2 | `agents/main.bicep` | Fix subnet name: `snet-github-runners` → `snet-gh-runners` | 5 min |
| 3 | `iaas/main.bicep` + `agents/main.bicep` | Replace hardcoded VNet name with dynamic lookup (use core deployment outputs) | 30 min |
| 4 | `core/deploy-vpn.bicep` | Remove `vnetName` from params passed to vpn-gateway module | 5 min |
| 5 | All `.bicepparam` files | Align parameter names with actual template parameters | 1 hr |
| 6 | `core/nat-inbound-rules.bicep` | Delete or rewrite — NAT Gateways don't have inbound rules | 15 min |

### Priority 2: Security (fix before any deployment)

| # | Component | Issue | Effort |
|---|-----------|-------|--------|
| 7 | `iaas/parameters.dev.json` | Remove hardcoded password and subscription ID | 10 min |
| 8 | `paas/*.bicepparam` (all 4 files) | Remove hardcoded passwords, use `readEnvironmentVariable()` or Key Vault | 30 min |
| 9 | `core/core-resources.bicep` | Change Key Vault `defaultAction` from `Allow` to `Deny` | 10 min |
| 10 | `Deploy-Bicep.ps1` | Stop printing passwords to console | 10 min |

### Priority 3: CI/CD (fix to enable automation)

| # | Component | Issue | Effort |
|---|-----------|-------|--------|
| 11 | All 22 pipeline files | Update `iac/` → `infrastructure/` in paths | 1 hr |
| 12 | All GitHub Actions deploy-* | Fix `$env:GITHUB_OUTPUT` → `$GITHUB_OUTPUT` | 15 min |
| 13 | All deploy pipelines | Add required parameter passing (secrets from Key Vault or GitHub Secrets) | 2 hr |
| 14 | Add what-if step | Add `--what-if` before actual deployment in all pipelines | 1 hr |

### Priority 4: Architecture Improvements

| # | Component | Issue | Effort |
|---|-----------|-------|--------|
| 15 | `core/core-resources.bicep` | Add NSGs to all subnets at creation time | 1 hr |
| 16 | `core/core-resources.bicep` | Add `Microsoft.App/environments` delegation to snet-ca | 10 min |
| 17 | Remove duplicate ACR | Either remove from core or PaaS — one ACR is sufficient | 15 min |
| 18 | `agents/agents-resources.bicep` | Remove orphaned NIC resource (lines 29-46) | 5 min |
| 19 | `staging.tfvars` + `prod.tfvars` | Add `subscription_id`, fix variable names | 15 min |
| 20 | `terraform/STATUS.md` | Update to reflect actual completed state | 10 min |

### Priority 5: Documentation

| # | Component | Issue | Effort |
|---|-----------|-------|--------|
| 21 | `bicep/INDEX.md` | Update all `iac/` references to `infrastructure/` | 30 min |
| 22 | `bicep/README.md` | Fix cross-references to phase3 app paths | 10 min |
| 23 | `deploy-paas-simple.ps1` | Fix hardcoded absolute path | 5 min |

---

## Decision

**Recommendation**: Adopt Terraform as the primary IaC tool. Bicep templates serve as reference/learning material, but Terraform's conditional deployment, variable validation, state management, and overall code quality make it the production choice. Fix Bicep blockers for learning purposes but invest new infrastructure work in Terraform.

**Immediate action**: Items 1-10 (blockers + security) should be fixed before any deployment attempt. The CI/CD path issue (#11) affects all automation.

**Status:** Pending team review

---

*Dozer — DevOps | Infrastructure Audit Complete*
