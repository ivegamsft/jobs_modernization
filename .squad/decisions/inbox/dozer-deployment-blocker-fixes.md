# Deployment Blocker Fixes — 6 Issues Resolved

**Author:** Dozer (DevOps)  
**Date:** 2026-02-27  
**Status:** Executed  
**Impact:** High (unblocks all Bicep deployments and CI/CD pipelines)

## What Changed

### Bicep Templates (3 files)

1. **agents/main.bicep** — Removed duplicate `githubRunnersSubnet` resource (compile error). Added `coreVnetName` parameter replacing hardcoded VNet name.

2. **iaas/main.bicep** — Added `coreVnetName` parameter replacing hardcoded VNet name `jobsite-dev-vnet-ubzfsgu4p5eli`.

3. **core/core-resources.bicep** — Two security fixes:
   - Key Vault `networkAcls.defaultAction` changed from `Allow` to `Deny`
   - Container Apps subnet (`snet-ca`) now has `Microsoft.App/environments` delegation

### CI/CD Pipelines (10 files)

All deployment pipelines updated from `iac/` to `infrastructure/` path references:
- 5 GitHub Actions: deploy-agents, deploy-core, deploy-iaas, deploy-paas, deploy-vpn
- 5 Azure Pipelines: deploy-agents, deploy-core, deploy-iaas, deploy-paas, deploy-vpn

## Implications for Team

1. **Anyone deploying iaas or agents layers** must now pass `coreVnetName` parameter (get from core module output: `az deployment sub show --name jobsite-core-dev --query properties.outputs.vnetName.value`)

2. **Key Vault is now deny-by-default** — access only via private endpoints or Azure services bypass. Deployment scripts that access Key Vault over public internet will need adjustment.

3. **Pipeline triggers now fire correctly** on `infrastructure/bicep/` changes.

4. **.bicepparam files are gitignored** — passwords were never in the repo. Locally, empty password params removed; must be passed via CLI `--parameters` flag.
