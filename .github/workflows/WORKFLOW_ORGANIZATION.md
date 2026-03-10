# Workflow Organization by Migration Phase

## Phase-Specific Workflows

### Phase 1: Legacy .NET 4.8 Baseline
These workflows are specific to Phase 1 (legacy application) and will **not** be reused in later phases:

- **`build-phase1-legacy-web.yml`** - Builds legacy .NET 4.8 JobsSiteWeb from `phase1-legacy-baseline/appV1.5-buildable/`
- **`deploy-phase1-app-iaas.yml`** - Deploys Phase 1 app to IaaS VMs running IIS
- **`deploy-phase1-app-paas.yml`** - Deploys Phase 1 app to Azure App Service

### Phase 2: Azure Migration (Future)
Phase 2 will require **new** workflows:
- `build-phase2-azure-web.yml` - Build modernized Azure-ready app
- `deploy-phase2-app-paas.yml` - Deploy Phase 2 app to PaaS

### Phase 3: Full Modernization (Future)
Phase 3 will require **new** workflows:
- `build-phase3-modern-web.yml` - Build fully modernized app (containers, microservices, etc.)
- `deploy-phase3-app-*.yml` - Deploy Phase 3 architecture

---

## Cross-Phase Workflows

These workflows are **shared across all migration phases** and should be maintained for the entire project lifecycle:

### Build Workflows
- **`build-database-dacpac.yml`** ✓  
  Builds database DACPAC from `database/JobsDB/`  
  Used by: All phases (shared database schema)

- **`build-iac-verify.yml`** ✓  
  Validates Bicep and Terraform in `infrastructure/`  
  Used by: All phases (shared infrastructure definitions)

### Infrastructure Deploy Workflows
- **`deploy-core.yml`** ✓  
  Deploys core infrastructure: networking, ACR, Key Vault  
  Used by: All phases (foundational resources)

- **`deploy-iaas.yml`** ✓  
  Deploys IaaS infrastructure: VMs, SQL Server VMs  
  Used by: Phase 1 and testing/comparison scenarios

- **`deploy-paas.yml`** ✓  
  Deploys PaaS infrastructure: App Service, Azure SQL Database  
  Used by: Phase 1 (alternative), Phase 2+

- **`deploy-agents.yml`** ✓  
  Deploys GitHub Copilot agent infrastructure (containers)  
  Used by: All phases (development tooling)

- **`deploy-vpn.yml`** ✓  
  Deploys VPN gateway for secure Azure access  
  Used by: All phases (operational access)

### Database Deploy Workflows
- **`deploy-database-dac-iaas.yml`** ✓  
  Deploys database DACPAC to IaaS SQL Server VMs  
  Used by: Phase 1 IaaS deployments

- **`deploy-database-dac-paas.yml`** ✓  
  Deploys database DACPAC to Azure SQL Database  
  Used by: Phase 1 PaaS, Phase 2+

---

## Squad Workflows (Repository Automation)

These are **not migration-related** — they manage repository automation:

- `squad-ci.yml`, `squad-docs.yml`, `squad-heartbeat.yml`
- `squad-insider-release.yml`, `squad-issue-assign.yml`, `squad-label-enforce.yml`
- `squad-main-guard.yml`, `squad-preview.yml`, `squad-promote.yml`
- `squad-release.yml`, `squad-triage.yml`, `sync-squad-labels.yml`

---

## Workflow Dependencies

```
Phase 1 App Deployment Flow:
  build-phase1-legacy-web.yml
    └─> deploy-phase1-app-iaas.yml
    └─> deploy-phase1-app-paas.yml

Database Deployment Flow:
  build-database-dacpac.yml
    └─> deploy-database-dac-iaas.yml
    └─> deploy-database-dac-paas.yml

Infrastructure Deployment Flow:
  build-iac-verify.yml (validation only)
  deploy-core.yml (run first)
    └─> deploy-iaas.yml (for IaaS path)
    └─> deploy-paas.yml (for PaaS path)
    └─> deploy-agents.yml (optional)
    └─> deploy-vpn.yml (optional)

Dependency Export Contract:
  deploy-core.yml
    └─> exports core-deployment-outputs-{environment} (core-outputs.json + core-dependencies.json)
  deploy-iaas.yml
    └─> exports iaas-deployment-outputs-{environment} (iaas-outputs.json + iaas-dependencies.json)
  deploy-paas.yml
    └─> exports paas-deployment-outputs-{environment} (paas-outputs.json + paas-dependencies.json)
  deploy-phase1-app-paas.yml
    └─> exports phase1-app-paas-dependencies-{environment}
  deploy-phase1-app-iaas.yml
    └─> exports phase1-app-iaas-dependencies-{environment}
  deploy-database-dac-paas.yml
    └─> exports database-paas-dependencies-{environment}
  deploy-database-dac-iaas.yml
    └─> exports database-iaas-dependencies-{environment}
  deploy-agents.yml
    └─> exports agents-deployment-outputs-{environment} (agents-outputs.json + agents-dependencies.json)
  deploy-vpn.yml
    └─> exports vpn-deployment-outputs-{environment} (vpn-outputs.json + vpn-dependencies.json)

---

## Required Secrets and App Settings

### Required Repository Secrets

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `SQL_AAD_ADMIN_OBJECT_ID`
- `SQL_AAD_ADMIN_NAME`
- `SQL_ADMIN_LOGIN`
- `SQL_ADMIN_PASSWORD`
- `VM_ADMIN_USERNAME`
- `VM_ADMIN_PASSWORD`

### App Service Settings Managed by Workflow

`deploy-phase1-app-paas.yml` configures these app settings from IaC outputs and workflow input:

- `ASPNETCORE_ENVIRONMENT`
- `APPINSIGHTS_INSTRUMENTATIONKEY`
- `APPLICATIONINSIGHTS_CONNECTION_STRING`
- `JOBSITE_SQL_SERVER`
- `JOBSITE_SQL_DATABASE`
- `WEBSITE_RUN_FROM_PACKAGE`

### Manual Deploy Artifact Requirement

For manual app/database deployment workflows (`workflow_dispatch`), provide `build_run_id` so `actions/download-artifact@v4` can fetch artifacts from the source build run.
```

---

## Migration Notes

1. **Phase 1 → Phase 2 transition:**  
   - Archive Phase 1 workflows (move to `.github/workflows/archived/phase1/`)
   - Create new Phase 2 workflows inheriting from Phase 1 patterns
   - Database and infrastructure workflows remain unchanged

2. **Adding new phases:**
   - Always prefix app-specific workflows with `*-phase{N}-*`
   - Reuse all cross-phase infrastructure workflows
   - Update this document when adding phase-specific workflows

3. **Workflow naming convention:**
   - Phase-specific: `{action}-phase{N}-{component}.yml`
   - Cross-phase: `{action}-{component}.yml` (no phase number)
