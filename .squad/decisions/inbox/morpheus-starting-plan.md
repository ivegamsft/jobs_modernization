# Infrastructure Review & Prioritized Starting Plan
**Decision ID:** infra-review-2026-02-27  
**Author:** Morpheus (Lead)  
**Status:** Proposed — Ready for team validation  
**Impact:** High (architecture, Phase 1-2 blocking)

---

## Executive Summary

The repository infrastructure is **well-structured but incomplete**. Core networking is deployed and working (✅), but the deployment pipeline lacks critical end-to-end visibility. Phase 1 (legacy app) can run on-premise or IaaS, but we need to validate what's actually deployable and buildable right now.

**Key Finding:** Infrastructure exists, but **validation and sequencing are gaps**. The team has invested heavily in Bicep templates (core ✅, PaaS partial 🟨, IaaS incomplete ❌) and Azure Pipelines (defined but untested 🟨).

**This plan prioritizes:**
1. **Audit:** Understand what's been deployed, what works, what's half-done
2. **Validation:** Test Phase 1 (legacy app) buildability and basic hosting scenarios
3. **Gap closure:** Fill critical infrastructure holes before heavy Phase 2/3 work
4. **Documentation:** Map what's been learned to reduce onboarding friction

---

## Current Infrastructure State

### ✅ **Deployed & Working**

**Core Infrastructure (jobsite-core-dev-rg)**
- VNet: `10.50.0.0/21` (2,048 IPs, well-sized)
- Subnets: 7 subnets (fe, data, gh-runners, pe, gateway, aks, container-apps) — all properly sized
- Key Vault: `kv-ubzfsgu4-dev` — storing secrets
- Log Analytics Workspace: `jobsite-dev-law` — monitoring ready
- NAT Gateway: Active
- Private DNS Zone: Configured
- ACR: (implicitly available, referenced in documentation)

**Bicep Templates (core/)**
- `main.bicep` → `core-resources.bicep` — subscription-scoped deployment, solid pattern
- Resource group auto-creation with tags
- All outputs properly exposed (VNet IDs, KV name, LAW ID)
- **Status:** Production-ready, well-documented

**Azure Pipelines**
- `deploy-core.yml` — Defined, references correct paths (`iac/bicep/core/`)
- **Issue:** Pipeline references old paths (`iac/` not `infrastructure/`) — **BLOCKER**

---

### 🟨 **Partially Implemented**

**PaaS Infrastructure (bicep/paas/)**
- `main.bicep` exists, subscription-scoped entry point
- `paas-resources.bicep` — Templates exist
- **Missing:** 
  - Actual deployment script (`deploy-paas.ps1` exists but may not be complete)
  - Parameter files for dev/staging/prod
  - SQL Database connection string management
  - App Service configuration injection

**IaaS Infrastructure (bicep/iaas/)**
- Templates exist (`main.bicep`, `iaas-resources.bicep`)
- **Critical gaps:**
  - VMSS (Web tier) template incomplete
  - SQL VM deployment template unclear
  - Application Gateway configuration missing (script exists but not Bicep)
  - Load balancer setup not visible

**Azure Pipelines**
- 9 pipeline files exist (deploy-core, deploy-paas, deploy-iaas, deploy-database-dac-*, etc.)
- **Issue:** All reference `iac/` paths (old naming) instead of `infrastructure/` (current naming)
- **Issue:** No validation or lint step before deployment
- **Issue:** No integration tests or smoke tests after deployment

---

### ❌ **Missing or Incomplete**

**Phase 1 (Legacy App)**
- No build definition (no `.csproj` project file visible at root of phase1-legacy-baseline/appV1.5-buildable/)
- **Question:** Can appV1.5 actually build? Need to test with `dotnet build`
- No local hosting guide (IIS Express, Docker, etc.)
- No connection string documentation for local vs. Azure scenarios

**Database**
- SQL Server project exists (`database/JobsDB/`)
- **Missing:** DACPAC build definition in pipelines
- **Missing:** Local database setup instructions
- SEED_DATA_CONFLICT_ANALYSIS.md exists but resolution not clear

**Containerization (Phase 3 prep)**
- No Dockerfile in phase1-legacy-baseline/ (expected for legacy)
- `bicep/iaas/` has Container Apps references but no Container Registry Bicep template (should be in core)
- No ACR build task definitions

**Infrastructure Documentation Gaps**
- 4LAYER_RG_QUICK_REFERENCE.md exists (good!) but may be outdated
- DEPLOYMENT_STATUS.md says "Core: ✅, IaaS: ⏸️, PaaS: ⏹️" — **no current date, unclear when last updated**
- No "How to Deploy Phase 1 Legacy App" guide
- No "Troubleshooting infrastructure issues" guide

---

## Infrastructure Topology & Phase Mapping

### **Phase 1: Legacy Baseline** → Simple Hosting Options

**What needs to run:** `phase1-legacy-baseline/appV1.5-buildable/` (ASP.NET Framework Web Forms app)

**Option A: On-Premise / Local**
- IIS Express or IIS on Windows dev machine
- Local SQL Server or SQL Server Express
- Connection string: `Server=localhost;Database=JobsDB;Integrated Security=true;`
- **Status:** Not documented; unclear if tested

**Option B: Azure IaaS (VMSS + SQL VM)**
- Web tier: VMSS running Windows Server 2022 with IIS
- Data tier: SQL Server 2022 VM
- Front-end: Application Gateway v2 with WAF
- **Status:** Bicep templates exist but not fully validated; Azure Pipeline defined but broken (path issues)

**Option C: Azure App Service (PaaS)**
- App Service (B2 SKU, configurable)
- Azure SQL Database (Standard S1, configurable)
- **Status:** Bicep exists; no actual deployment tested; scripts partially complete

**Recommendation for Phase 1:** Start with **Option A (on-premise)** to validate the build, then move to **Option B (IaaS)** for Azure learning.

---

### **Phase 2: Azure Migration** → PaaS Hosting

**Infrastructure needed:**
- App Service + App Service Plan
- Azure SQL Server + Database
- Connection string management in App Configuration or Key Vault
- Deployment slot for staging

**Current state:**
- Bicep templates drafted
- Scripts partially written
- No deployment tested
- Database migration plan missing (DACPAC? SQL scripts? EF migrations?)

**Blocker:** Phase 1 must be buildable first; can't deploy what won't build.

---

### **Phase 3: Modernization** → API + React on Containers

**Infrastructure needed:**
- Container Registry (ACR)
- Container Apps or AKS
- API Gateway / Ingress
- Managed Redis (optional caching)

**Current state:**
- Bicep templates reference Container Apps in `bicep/paas/`
- Subnets allocated for AKS (`snet-aks /23`)
- No Dockerfile or container build pipelines yet
- No API deployment scripts

---

## Identified Gaps & Issues

### **Critical (Block Phase 1 deployment)**

| Issue | Location | Impact | Priority |
|-------|----------|--------|----------|
| **Pipeline path mismatch** | `.azure-pipelines/*.yml` | All pipelines reference `iac/` not `infrastructure/` | P0 |
| **Phase 1 app buildability unknown** | `phase1-legacy-baseline/appV1.5-buildable/` | Can't proceed if app won't compile | P0 |
| **No local setup guide** | Missing docs | Developers can't get started | P0 |
| **Database migration strategy unclear** | `database/` + `phase2-azure-migration/` | How do we migrate schema + data? | P0 |

### **High (Block Phase 2 deployment)**

| Issue | Location | Impact | Priority |
|-------|----------|--------|----------|
| **PaaS Bicep incomplete** | `bicep/paas/*.bicep` | Missing App Service details, App Insights, etc. | P1 |
| **IaaS VMSS/SQL VM unclear** | `bicep/iaas/` | Web tier and database tier templates partial | P1 |
| **No deployment validation** | Pipelines | No lint, syntax check, or post-deploy smoke tests | P1 |
| **App Gateway Bicep missing** | `bicep/iaas/` | Exists as PowerShell script, not IaC | P1 |
| **No parameter files** | `infrastructure/` | `dev.bicepparam`, `prod.bicepparam` missing | P1 |

### **Medium (Improve quality)**

| Issue | Location | Impact | Priority |
|-------|----------|--------|----------|
| **Infrastructure documentation outdated** | `infrastructure/docs/` | DEPLOYMENT_STATUS.md undated; unclear current state | P2 |
| **Network redesign (VNet size)** | `NETWORK_REDESIGN.md` | Current `/24` was too small; now `/21` — need validation that existing VNet matches | P2 |
| **No ACR Bicep template** | `bicep/core/` | ACR mentioned but not in templates | P2 |
| **Container image build missing** | `.azure-pipelines/` | No pipeline for building Docker images | P2 |
| **Connection string management** | `phase1-legacy-baseline/appV1.5-buildable/` | Web.config manual editing vs. Key Vault integration | P2 |

---

## Prioritized Starting Plan

### **Phase 0: Immediate Validation (This Week)**

#### **0.1 Audit: What's Actually Deployed?** [4 hours]
- **Owner:** DevOps / Infrastructure
- **What to do:**
  - Run `az group list` → List all resource groups, confirm count matches expectations
  - Run `az resource list --resource-group jobsite-core-dev-rg` → Audit what's actually in core RG
  - Check DEPLOYMENT_STATUS.md date — is it current?
  - Confirm `kv-ubzfsgu4-dev` exists and contains expected secrets
  - List all deployed Bicep versions (check deployment history in Azure Portal)
- **Output:** Infrastructure audit document with current resource inventory
- **Blocker removal:** Confirms deployment actually happened or identifies failures

#### **0.2 Test Phase 1 Build** [2-3 hours]
- **Owner:** .NET Developer / Build Engineer
- **What to do:**
  - Clone repo locally or in a build agent
  - Run `cd phase1-legacy-baseline/appV1.5-buildable/` 
  - Check for `.sln` file (mentioned in repo reorganization history, should exist)
  - Try `dotnet build` or `msbuild` 
  - Document success/failures, missing dependencies
  - Create BUILD_STATUS.md in phase1-legacy-baseline/
- **Output:** BUILD_STATUS.md saying "✅ Builds" or "❌ Fails: [specific errors]"
- **Blocker removal:** Phase 1 buildability is a hard prerequisite

#### **0.3 Fix Azure Pipeline Paths** [1 hour]
- **Owner:** CI/CD Lead
- **What to do:**
  - All `.azure-pipelines/*.yml` files reference `iac/` paths
  - Update all paths to `infrastructure/` (repository reorganization changed folder names)
  - Search for: `iac/bicep`, `iac/scripts`, `iac/terraform` 
  - Replace with: `infrastructure/bicep`, `infrastructure/scripts`, `infrastructure/terraform`
  - Verify: Run pipeline validation (dry-run in Azure DevOps)
- **Output:** Fixed pipeline files, pipeline validation passes
- **Blocker removal:** Pipelines can't run with wrong paths

#### **0.4 Document Current Architecture** [3 hours]
- **Owner:** Morpheus (Lead) / Technical Writer
- **What to do:**
  - Create `infrastructure/CURRENT_STATE.md` with:
    - Deployed resources by RG (core, iaas, paas, agents)
    - VNet topology (subnets, NSGs, routing)
    - Completed Bicep templates vs. TODO templates
    - Known issues and workarounds
  - Include deployment timestamps and versions
  - Link to DEPLOYMENT_STATUS.md but clearly mark as "verified on [date]"
- **Output:** CURRENT_STATE.md (living document, updated after each phase)
- **Blocker removal:** Team has shared understanding of what exists

---

### **Phase 1: Build Phase 1 Support (Week 2)**

#### **1.1 Complete Phase 1 Local Setup Guide** [3 hours]
- **Owner:** .NET Developer
- **What to do:**
  - Document how to build appV1.5-buildable locally
  - Document how to run locally (IIS Express, Docker, etc.)
  - Document how to connect to local SQL Server
  - Create `phase1-legacy-baseline/LOCAL_SETUP.md`
  - Include troubleshooting section
- **Output:** LOCAL_SETUP.md with step-by-step instructions
- **Blocker removal:** New developers can get Phase 1 running

#### **1.2 Complete Database Setup** [4 hours]
- **Owner:** Database Engineer / DevOps
- **What to do:**
  - Document SQL Server schema creation (JobsDB project)
  - Create `database/SETUP.md` with:
    - Local database setup (SQL Express or SQL Server)
    - DACPAC build process (if using .sqlproj)
    - Seed data loading
    - Connection string examples
  - Test locally: `sqlcmd -S localhost -d JobsDB -Q "SELECT @@VERSION"`
  - Document for Azure SQL (connection string format, firewall rules, etc.)
- **Output:** SETUP.md + verified local database working
- **Blocker removal:** Database can be created and seeded

#### **1.3 Complete IaaS Infrastructure (Bicep)** [8 hours]
- **Owner:** Cloud Architect / DevOps
- **What to do:**
  - Review `bicep/iaas/main.bicep` and dependent modules
  - Complete VMSS template for web tier:
    - Windows Server 2022 image
    - IIS + .NET Framework 4.x installation
    - Custom script extension for app deployment
  - Complete SQL VM template:
    - SQL Server 2022 image
    - Storage configuration (P10+ disks)
  - Complete Application Gateway configuration in Bicep (currently in PowerShell script)
  - Add outputs (gateway IP, VMSS IDs, etc.)
- **Output:** Complete `bicep/iaas/main.bicep` with all child modules
- **Blocker removal:** IaaS infrastructure is deployable code

#### **1.4 Create Parameter Files** [2 hours]
- **Owner:** DevOps
- **What to do:**
  - Create `infrastructure/bicep/parameters/dev.bicepparam`
  - Create `infrastructure/bicep/parameters/prod.bicepparam`
  - Create `infrastructure/bicep/parameters/staging.bicepparam` (optional)
  - Include all parameters (location, SKU, password placeholders)
  - Document how to use them in pipelines
- **Output:** Parameter files for each environment
- **Blocker removal:** Pipelines can reference environment-specific parameters

---

### **Phase 2: Validate Phase 1 on Azure IaaS (Week 3)**

#### **2.1 Fix & Test deploy-core Pipeline** [3 hours]
- **Owner:** CI/CD Lead
- **What to do:**
  - Validate `.azure-pipelines/deploy-core.yml` against current paths
  - Dry-run in Azure DevOps (don't deploy, just validate)
  - Document any manual prerequisites (service connections, key vaults, etc.)
  - Update documentation if needed
- **Output:** Pipeline validated, prerequisites documented

#### **2.2 Deploy & Test IaaS Infrastructure** [6 hours]
- **Owner:** DevOps Lead + Infrastructure Engineer
- **What to do:**
  - Manual or pipeline deploy of core infrastructure (should already be done ✅)
  - Deploy IaaS infrastructure using `deploy-iaas.ps1` or pipeline
  - Verify resources created: VMSS, SQL VM, App Gateway
  - Test connectivity: RDP to VMSS, SQL connectivity to SQL VM
  - Create post-deployment validation script
- **Output:** IaaS infrastructure deployed and healthy; validation script created
- **Blocker removal:** Can run Phase 1 app on Azure VMs

#### **2.3 Deploy Phase 1 App to IaaS** [4 hours]
- **Owner:** DevOps + .NET Developer
- **What to do:**
  - Create deployment script/pipeline for app package to VMSS
  - Handle Web.config transformation for Azure environment
  - Deploy database schema to SQL VM (DACPAC or script)
  - Smoke test: HTTP call to app through Application Gateway
  - Document deployment process
- **Output:** Deployment pipeline or runbook; Phase 1 app running on Azure
- **Blocker removal:** Can actually run legacy app in cloud

#### **2.4 Create Troubleshooting Guide** [2 hours]
- **Owner:** DevOps + whoever debugged issues
- **What to do:**
  - Document common IaaS deployment issues
  - Include Azure CLI diagnostic commands
  - App Gateway health probe failures → how to debug
  - Network connectivity issues → how to troubleshoot
  - Create `infrastructure/docs/TROUBLESHOOTING_IAAS.md`
- **Output:** TROUBLESHOOTING_IAAS.md

---

### **Phase 3: Prepare Phase 2 PaaS (Week 4)**

#### **3.1 Complete PaaS Bicep Templates** [6 hours]
- **Owner:** Cloud Architect / DevOps
- **What to do:**
  - Review `bicep/paas/main.bicep` and child modules
  - Complete App Service + App Service Plan template
  - Complete Azure SQL Server + Database template
  - Add Application Insights + Log Analytics integration
  - Add Private Endpoint for SQL Database
  - Add Key Vault integration for secrets
  - Verify all outputs (connection strings, app URLs, etc.)
- **Output:** Complete PaaS templates, ready to deploy

#### **3.2 Create Database Migration Strategy** [4 hours]
- **Owner:** Database Engineer
- **What to do:**
  - Document schema migration (SQL Server → Azure SQL):
    - Use DACPAC for schema
    - Use SQL Data Sync or native Azure tools for data
  - Document breaking changes (if any) for Azure SQL
  - Create `database/MIGRATION_STRATEGY.md`
  - Create migration test plan
- **Output:** MIGRATION_STRATEGY.md + test plan

#### **3.3 Complete & Test deploy-paas Pipeline** [4 hours]
- **Owner:** CI/CD Lead
- **What to do:**
  - Complete `.azure-pipelines/deploy-paas.yml` (currently incomplete)
  - Add database migration step
  - Add smoke tests after deployment
  - Dry-run and validate
- **Output:** deploy-paas.yml complete and tested

#### **3.4 Connection String & Secrets Management** [3 hours]
- **Owner:** DevOps + Security
- **What to do:**
  - Document how connection strings are managed:
    - Azure Key Vault for storage
    - App Service config for injection
    - No hardcoding
  - Create script to populate Key Vault with secrets
  - Document for appV1.5 in Phase 2 (Web.config → App Settings)
- **Output:** Connection string management documented and automated

---

## Infrastructure Dependencies & Sequencing

```
Phase 0 (This week)
├── 0.1: Audit deployed resources ───────┐
├── 0.2: Test Phase 1 builds             │
├── 0.3: Fix pipeline paths ─────────────┼→ Ready for Phase 1 infrastructure
├── 0.4: Document current state ─────────┘
           ↓
Phase 1 (Week 2-3)
├── 1.1: Phase 1 local setup
├── 1.2: Database setup ──────────────────┐
├── 1.3: Complete IaaS Bicep              ├→ Phase 1 running on Azure
├── 1.4: Create parameter files ──────────┤
├── 2.1: Validate core pipeline           │
├── 2.2: Deploy IaaS ─────────────────────┘
├── 2.3: Deploy Phase 1 app to IaaS
└── 2.4: Troubleshooting guide
           ↓
Phase 2 (Week 4+)
├── 3.1: Complete PaaS Bicep
├── 3.2: Database migration strategy ────┐
├── 3.3: Complete deploy-paas pipeline   ├→ Phase 1 running on App Service
├── 3.4: Connection strings management ──┘
           ↓
Phase 3 (Beyond)
├── Containerization (Dockerfile, ACR)
├── API deployment (ASP.NET Core / Python)
└── React UI deployment
```

---

## Success Criteria

### **Phase 0 (Validation)**
- ✅ Infrastructure audit completed; current state documented
- ✅ Phase 1 app builds successfully
- ✅ Azure pipeline path issues fixed
- ✅ Current architecture diagram exists and accurate

### **Phase 1 (Phase 1 Running on IaaS)**
- ✅ Local development guide works end-to-end
- ✅ Database schema can be created locally and in Azure
- ✅ IaaS infrastructure fully coded in Bicep
- ✅ Phase 1 app running on VMSS, accessible via App Gateway
- ✅ Troubleshooting guide documented

### **Phase 2 (Phase 1 Running on App Service)**
- ✅ PaaS infrastructure fully coded in Bicep
- ✅ Database migration strategy documented and tested
- ✅ Pipelines automated (deploy-core, deploy-iaas, deploy-paas)
- ✅ Phase 1 app running on App Service + Azure SQL
- ✅ Connection strings managed via Key Vault / App Settings

### **Phase 3 (Modernization Ready)**
- ✅ Container infrastructure (ACR, Container Apps or AKS) defined
- ✅ API deployment pipelines created
- ✅ React UI hosting infrastructure prepared

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **Phase 1 app won't build** | Medium | Blocks everything | Test immediately (Phase 0.2) |
| **Bicep templates have syntax errors** | Medium | Pipelines fail | Validate templates before PR (bicep build + lint) |
| **Network connectivity issues in IaaS** | Medium | Can't access app | Pre-deploy NSG validation; troubleshooting guide |
| **Database migration breaks data** | Low | Data loss | Test migration with backup; rollback plan |
| **Pipeline secrets exposed** | Low | Security incident | Key Vault only; no hardcoding; audit secrets script |
| **Outdated documentation causes confusion** | High | Rework / delays | Living docs (CURRENT_STATE.md); dates on everything |

---

## Key Artifacts to Create/Update

| Artifact | Owner | Phase | Note |
|----------|-------|-------|------|
| `infrastructure/CURRENT_STATE.md` | Morpheus | Phase 0 | Living document |
| `phase1-legacy-baseline/BUILD_STATUS.md` | .NET Dev | Phase 0 | Buildability report |
| `phase1-legacy-baseline/LOCAL_SETUP.md` | .NET Dev | Phase 1 | Developer onboarding |
| `database/SETUP.md` | DB Eng | Phase 1 | Database setup guide |
| `bicep/iaas/` (complete) | Cloud Arch | Phase 1 | Full IaaS infrastructure |
| `infrastructure/TROUBLESHOOTING_IAAS.md` | DevOps | Phase 2 | Debugging guide |
| `database/MIGRATION_STRATEGY.md` | DB Eng | Phase 3 | Migration plan |

---

## Questions for Team Validation

1. **Phase 1 Buildability:** Can appV1.5-buildable actually build today? Dependencies? Target Framework?
2. **Current Deployment:** Was core infrastructure actually deployed to Azure, or is this a template-only repo?
3. **Password Security:** How should we handle VM/SQL admin passwords? Key Vault? Environment variables?
4. **Network Design:** The NETWORK_REDESIGN.md mentions changing from /24 to /21 — has this been done or is it a proposal?
5. **Database:** Is JobsDB SQL project buildable? Does it generate DACPAC?
6. **App Service Auth:** For Phase 2 PaaS, what auth will we use? SQL auth? Managed Identity?

---

## Ownership & Timeline

| Phase | Owner(s) | Duration | Start | End |
|-------|----------|----------|-------|-----|
| **Phase 0** | Morpheus, DevOps, .NET Dev | 1.5 weeks | Week 1 | Week 2 |
| **Phase 1** | Cloud Arch, DevOps, DB Eng, .NET Dev | 2 weeks | Week 2 | Week 4 |
| **Phase 2** | DevOps, Cloud Arch, CI/CD Lead | 1 week | Week 4 | Week 5 |
| **Phase 3** | DevOps, Cloud Arch | 2+ weeks | Week 5+ | TBD |

---

## Related Documents

- [Repository Structure](../.squad/decisions.md) — Three-phase learning journey decision
- [Infrastructure README](../infrastructure/README.md) — Current infrastructure overview
- [Deployment Status](../infrastructure/DEPLOYMENT_STATUS.md) — Last known deployment state
- [4-Layer RG Quick Reference](../infrastructure/docs/4LAYER_RG_QUICK_REFERENCE.md) — Resource group organization
- [Network Redesign](../infrastructure/NETWORK_REDESIGN.md) — VNet sizing discussion
- [Implementation Checklist](../infrastructure/docs/IMPLEMENTATION_CHECKLIST.md) — Detailed resource reorganization steps

---

## Next Steps

1. **Morpheus:** Present this plan to the team
2. **Team:** Answer the validation questions above
3. **Phase 0 Owner (DevOps):** Start with 0.1 (Audit) and 0.2 (Build test)
4. **Update this plan** based on Phase 0 findings
5. **Proceed to Phase 1** once Phase 0 is complete

---

**Plan Version:** 1.0  
**Date:** 2026-02-27  
**Status:** Proposed (awaiting team review)
