# Bicep Implementation Validation Report

**Date**: 2026-01-22  
**Source**: Review of existing Bicep templates in `iac/bicep/` against `tasks.md`  
**Status**: ⚠️ PARTIAL IMPLEMENTATION - Critical gaps identified

---

## Executive Summary

The existing Bicep infrastructure has a **solid foundation** with all 4 layers properly structured (Core, IaaS, PaaS, Agents), but **several critical components from the specification are missing or incomplete**:

| Component              | Status         | Note                                    |
| ---------------------- | -------------- | --------------------------------------- |
| ✅ VNet & 7 Subnets    | Implemented    | Correct CIDR ranges                     |
| ✅ Log Analytics       | Implemented    | Connected to monitoring                 |
| ✅ NAT Gateway         | Implemented    | For outbound traffic                    |
| ✅ Key Vault           | Implemented    | Referenced in outputs                   |
| ✅ Container Registry  | Implemented    | For image storage                       |
| ⚠️ App Gateway v2      | **MISSING**    | Critical for WFE layer                  |
| ⚠️ VMSS Infrastructure | **INCOMPLETE** | Only agents have VMSS template          |
| ⚠️ NSGs                | **PARTIAL**    | IaaS has basic rules, others missing    |
| ⚠️ Private Endpoints   | **PARTIAL**    | SQL has PE, others needed               |
| ⚠️ Container Apps Env  | **MOVED**      | Currently in Core RG, should be in PaaS |

---

## Detailed Analysis by Layer

### ✅ Layer 1: Core (Networking) - 85% Complete

**Status**: Mostly implemented, needs validation and output updates

#### Implemented ✅

- [x] VNet (10.50.0.0/21) with correct address space
- [x] 7 subnets with correct CIDR ranges:
  - snet-fe (10.50.0.0/24)
  - snet-data (10.50.1.0/26)
  - snet-gh-runners (10.50.1.64/26)
  - snet-pe (10.50.1.128/27)
  - GatewaySubnet (10.50.1.160/27)
  - snet-aks (10.50.2.0/23)
  - snet-ca (10.50.4.0/26)
- [x] NAT Gateway with public IP
- [x] Log Analytics Workspace
- [x] Key Vault (kv-{env}-{region}-{unique})
- [x] Azure Container Registry
- [x] Container App Environment (⚠️ should move to PaaS RG)
- [x] Private DNS Zone
- [x] Outputs include: vnetId, subnet IDs, KV name, LAW ID

#### Missing/Incomplete ❌

- [ ] **VNet diagnostics to Log Analytics** - No diagnostic settings configured
- [ ] **NSG for core subnets** - NSGs only in IaaS layer
- [ ] **Detailed outputs** - Missing some subnet IDs in outputs (aks, ca)
- [ ] **Resource tagging validation** - Tags applied but not validated
- [ ] **SKU validation** - No comments on why PerGB2018 chosen for LAW

**Expected from Tasks**:

- T007: Create VNet ✅
- T008: Create 7 subnets ✅
- T009: Configure NSGs ❌ (only IaaS has NSGs)
- T010: Deploy NAT Gateway ✅
- T011: Create Log Analytics ✅
- T012: Create Private DNS Zones ✅
- T013: Configure VNet diagnostics ❌ (not implemented)
- T014: Validate subnet outputs ⚠️ (partial)
- T015: Update core outputs ⚠️ (incomplete - missing AKS/CA subnet IDs)

---

### ⚠️ Layer 2: IaaS (Web Front End + VMs) - 30% Complete

**Status**: Severely incomplete - **Application Gateway v2 is completely missing**

#### Implemented ✅

- [x] NSG for Frontend subnet with HTTP/HTTPS/RDP/WinRM rules
- [x] NSG for Data subnet with SQL/RDP rules
- [x] Network Interface configuration
- [x] Variables for naming
- [x] Parameters for VM sizes (D2ds_v6, D4ds_v6)

#### **CRITICALLY MISSING** ❌

- [ ] **Application Gateway v2 (WAF_v2)** - Core requirement for WFE
  - No public IP for App Gateway
  - No WAF rules (OWASP 3.1)
  - No backend pool
  - No health probes
  - No listener configuration
- [ ] **Web VMSS** - Scale set for web tier
  - Currently templates refer to WFE VM, not VMSS
  - No auto-scale policy
  - No health probe integration
- [ ] **SQL Server VM** - Database tier VM
  - Template mentions it but incomplete implementation
  - No managed disks
  - No backup configuration
- [ ] **Network Interface assignments** - NSGs created but not linked
- [ ] **Auto-scale rules** - CPU-based scaling for web tier
- [ ] **Managed Identity** - For Azure service access
- [ ] **Custom Script Extensions** - For app/SQL installation
- [ ] **VNet integration** - VMSS → VNet peering

**Expected from Tasks**:

- T016: Deploy App Gateway v2 ❌ (NOT FOUND)
- T017: Deploy Web VMSS ❌ (partially defined, not deployed)
- T018: Deploy SQL VM ❌ (referenced but incomplete)
- T019: Configure NSG rules ✅ (partially done)
- T020: Assign Network Interfaces ⚠️ (incomplete)
- T021: Enable diagnostics ❌ (not configured)
- T022: Validate App Gateway health ❌ (cannot validate missing resource)
- T023: Test connectivity ❌ (blocked by missing App Gateway)

---

### ⚠️ Layer 3: PaaS (Managed Services) - 70% Complete

**Status**: Mostly implemented, but Container Apps Env is in wrong RG

#### Implemented ✅

- [x] App Service Plan (with configurable SKU)
- [x] App Service (ASP.NET Core configured)
  - System Managed Identity enabled
  - HTTPS only
  - TLS 1.2 minimum
  - .NET Framework 4.8
- [x] Application Insights (connected to Log Analytics)
- [x] SQL Server (AAD authentication, public network access disabled)
- [x] SQL Database (with proper collation and max size)
- [x] SQL Role Assignment (App Service → SQL Database access)
- [x] Private Endpoint for SQL Server
- [x] Azure Container Registry (from core, referenced in outputs)
- [x] Parameter validation for SQL admin

#### Incomplete/Misplaced ⚠️

- [ ] **Container Apps Environment location** - Currently in Core RG
  - Should be deployed in jobsite-paas-dev-rg per spec
  - Currently inherits from core layer
- [ ] **Container App instances** - No app deployment definitions
- [ ] **Private Endpoints for other services**:
  - [ ] KV private endpoint in snet-pe
  - [ ] ACR private endpoint in snet-pe
- [ ] **VNet integration for App Service**:
  - [ ] App Service should have VNet integration subnet reference
  - [ ] No outbound access via NAT Gateway configured
- [ ] **Diagnostics configuration**:
  - [ ] App Service diagnostics → LAW
  - [ ] SQL Server diagnostics → LAW
  - [ ] App Insights diagnostics → LAW
- [ ] **NSG for PaaS tier** - No NSG rules for snet-ca or PaaS connectivity

**Expected from Tasks**:

- T024: Deploy Container Apps Environment ⚠️ (in Core, not PaaS)
- T025: Deploy Container App instances ❌ (not found)
- T026: Deploy App Service Plan ✅
- T027: Deploy App Service ✅
- T028: Deploy SQL Database ✅
- T029: Create Application Insights ✅
- T030: Create Private Endpoints ⚠️ (SQL only, missing KV/ACR)
- T031: Configure PaaS NSGs ❌ (not implemented)
- T032: Configure App Service VNet integration ❌ (not implemented)
- T033: Setup Key Vault secrets ⚠️ (referenced but not populated)
- T034: Validate PaaS connectivity ⚠️ (incomplete)
- T035: Enable PaaS diagnostics ⚠️ (partial)

---

### ✅ Layer 4: Agents (Build Infrastructure) - 60% Complete

**Status**: Basic structure exists, needs scaling and GitHub integration

#### Implemented ✅

- [x] VMSS resource definition (GitHub Runners)
- [x] Network Interface configuration
- [x] Windows Server 2022 image (Azure Edition)
- [x] SSH/RDP access paths defined
- [x] Storage configuration with Premium LRS
- [x] networkApiVersion set correctly (2023-05-01)
- [x] Flexible orchestration mode
- [x] Outputs include VMSS ID and name

#### Incomplete ❌

- [ ] **Auto-scaling policy** - Only has static instance count
  - No queue-based scaling defined
  - No CPU-based scaling fallback
  - No scale-in cooldown
- [ ] **Custom Script Extension** - No GitHub runner registration
  - Missing script to install runner software
  - Missing GitHub token/registration
  - No build tools installation (Docker, .NET, Node, etc.)
- [ ] **Managed Identity** - No system/user assigned identity
  - Cannot access ACR or Key Vault
- [ ] **Network Security Group** - No NSG rules for agents subnet
  - No egress to GitHub Actions defined
  - No ingress lockdown
- [ ] **Outbound NAT** - NAT Gateway configured in core, not linked to agents subnet
  - agents subnet not listed in NAT Gateway association
- [ ] **Monitoring** - No diagnostics or Log Analytics agent
- [ ] **Health probes** - None configured

**Expected from Tasks**:

- T036: Deploy VMSS ✅ (partial)
- T037: Configure outbound NAT ❌ (NAT exists but not linked)
- T038: Configure agents NSGs ❌ (not implemented)
- T039: Setup VMSS health probes ❌ (not implemented)
- T040: Create managed identity ❌ (not implemented)
- T041: Assign RBAC roles ❌ (identity missing)
- T042: Configure Custom Script Extension ❌ (not implemented)
- T043: Enable diagnostics ❌ (not implemented)
- T044: Validate agents connectivity ❌ (blocked by missing config)

---

## Critical Gaps Summary

### 🔴 BLOCKING ISSUES (Must fix before deployment)

1. **Application Gateway v2 Missing**
   - No WFE layer at all
   - Web traffic cannot enter the system
   - WAF protection missing
   - **Impact**: System cannot be accessed from internet

2. **Web VMSS Incomplete**
   - No proper scale set configuration
   - No health probes
   - No backend pool registration
   - **Impact**: Cannot route traffic to web tier

3. **Container Apps in Wrong RG**
   - Currently in jobsite-core-dev-rg
   - Should be in jobsite-paas-dev-rg
   - **Impact**: Architecture violates 4-layer separation

### ⚠️ IMPORTANT ISSUES (Should fix before production)

4. **Missing NSGs for PaaS and Core tiers**
   - Only IaaS has comprehensive NSGs
   - Core and PaaS subnets unprotected
   - **Impact**: Security gaps

5. **No VNet Diagnostics**
   - NSG flow logs not configured
   - VNet diagnostics not flowing to Log Analytics
   - **Impact**: Cannot troubleshoot network issues

6. **Agents VMSS Not Linked to NAT Gateway**
   - NAT Gateway exists in Core
   - Agents subnet not listed as NAT client
   - **Impact**: Agents cannot reach internet

7. **Missing Auto-scaling**
   - Agents VMSS has fixed capacity
   - Web VMSS (if implemented) needs auto-scale rules
   - **Impact**: Cannot respond to load changes

8. **No Private Endpoints**
   - Only SQL has PE
   - KV and ACR missing private endpoints
   - **Impact**: Services accessible over internet (security risk)

---

## Mapping: Existing Code vs. Tasks.md

### What's Working (Move Forward)

```
✅ T007  - Core VNet creation (complete)
✅ T008  - 7 subnets (complete)
✅ T010  - NAT Gateway (complete)
✅ T011  - Log Analytics (complete)
✅ T012  - Private DNS Zone (complete)
⚠️  T014  - Subnet validation (partial outputs)
✅ T026  - App Service Plan (complete)
✅ T027  - App Service (complete)
✅ T028  - SQL Database (complete)
✅ T029  - App Insights (complete)
⚠️  T036  - Agents VMSS (basic structure only)
```

### What's Missing (Must Implement)

```
❌ T016  - App Gateway v2 (entire component)
❌ T017  - Web VMSS (incomplete, not integrated)
❌ T018  - SQL VM (incomplete)
❌ T019  - IaaS NSG rules (partially done, incomplete)
❌ T020  - NIC assignments (incomplete)
❌ T021  - IaaS diagnostics (not configured)
❌ T024  - Move CAE to PaaS RG (currently in Core)
❌ T025  - Container App instances (not defined)
❌ T030  - KV/ACR Private Endpoints (SQL only)
❌ T031  - PaaS NSGs (not implemented)
❌ T032  - App Service VNet integration (not configured)
❌ T037  - Link agents to NAT Gateway (NAT exists but not linked)
❌ T038  - Agents NSGs (not implemented)
❌ T039  - VMSS health probes (not implemented)
❌ T040  - Managed identity for agents (not implemented)
❌ T041  - RBAC roles for agents (no identity to assign)
❌ T042  - Custom Script Extension (not implemented)
```

### What Needs Validation (Partially Done)

```
⚠️  T009  - NSG configuration (IaaS only, need Core/PaaS)
⚠️  T013  - VNet diagnostics (not configured)
⚠️  T014  - Subnet outputs (missing AKS/CA IDs)
⚠️  T015  - Update outputs (incomplete)
⚠️  T022  - App Gateway health (can't validate - missing App GW)
⚠️  T023  - Connectivity tests (can't test - missing components)
```

---

## Recommendations

### Phase 1: Fix Critical Blocking Issues (ASAP)

**Priority 1 - Deploy Application Gateway v2**:

- [ ] Add App Gateway v2 resource to iaas-resources.bicep
- [ ] Create public IP for App Gateway
- [ ] Configure WAF rules (OWASP 3.1) in Detection mode
- [ ] Setup backend pool for Web tier
- [ ] Create health probes (HTTP 200 on /health endpoint)
- [ ] Update iaas/main.bicep outputs

**Priority 2 - Move Container Apps Environment**:

- [ ] Create Container Apps Environment resource in paas-resources.bicep
- [ ] Remove CAE from core-resources.bicep
- [ ] Update core-resources.bicep to output only subnet IDs for CAE
- [ ] Ensure PAAS RG has containerAppsSubnetId parameter

**Priority 3 - Implement Web VMSS**:

- [ ] Add Web VMSS to iaas-resources.bicep (D2ds_v6 sizing)
- [ ] Configure auto-scale policy (2-5 instances, CPU 30-70%)
- [ ] Link to App Gateway backend pool
- [ ] Add custom script extension for IIS/app installation
- [ ] Ensure VMSS uses correct subnet (snet-fe or appropriate frontend subnet)

### Phase 2: Fix Important Security Issues (Before Prod)

**Priority 4 - Add NSGs for PaaS & Core**:

- [ ] Create NSG for snet-ca (Container Apps subnet)
- [ ] Create NSG for snet-pe (Private Endpoints subnet)
- [ ] Link to core-resources.bicep
- [ ] Document rules per specification

**Priority 5 - Configure Diagnostics**:

- [ ] Add VNet diagnostics to Log Analytics
- [ ] Add NSG flow logs
- [ ] Configure App Service diagnostics
- [ ] Configure SQL diagnostics
- [ ] Configure App Insights data source

**Priority 6 - Fix Agents Integration**:

- [ ] Link agents VMSS subnet to NAT Gateway
- [ ] Create NSG for agents subnet (egress to GitHub)
- [ ] Add managed identity to agents VMSS
- [ ] Add Custom Script Extension for runner installation
- [ ] Configure auto-scaling (queue-based preferred)

### Phase 3: Complete Remaining Tasks

**Priority 7 - Private Endpoints**:

- [ ] Add private endpoint for Key Vault
- [ ] Add private endpoint for Container Registry
- [ ] Link to Private DNS Zone

**Priority 8 - App Service Integration**:

- [ ] Configure App Service VNet integration
- [ ] Link to appropriate subnet
- [ ] Configure outbound NAT

---

## Testing Strategy

### Cannot Proceed With Until Fixed:

1. ❌ T022 - App Gateway health tests (need App Gateway first)
2. ❌ T023 - End-to-end connectivity (need App Gateway + Web VMSS)
3. ❌ T044 - Agents connectivity (need agents NSG + auto-scale + Custom Script)

### Can Proceed Now:

- ✅ Core layer validation (VNet, subnets, NAT, LAW)
- ✅ PaaS layer deployment (App Service, SQL, Insights)
- ✅ Resource group creation

---

## File Status Summary

| File                            | Status      | Issues                                              |
| ------------------------------- | ----------- | --------------------------------------------------- |
| `core/main.bicep`               | ✅ Good     | Minor output updates needed                         |
| `core/core-resources.bicep`     | ⚠️ Partial  | No diagnostics, remove CAE                          |
| `iaas/main.bicep`               | ❌ Critical | Missing App Gateway entirely                        |
| `iaas/iaas-resources.bicep`     | ⚠️ Partial  | NSGs OK, missing App GW + Web VMSS + SQL VM         |
| `paas/main.bicep`               | ✅ Good     | Good structure                                      |
| `paas/paas-resources.bicep`     | ⚠️ Partial  | Missing CAE move, missing private endpoints         |
| `agents/main.bicep`             | ✅ Good     | Good structure                                      |
| `agents/agents-resources.bicep` | ⚠️ Partial  | Missing auto-scale, health probes, managed identity |

---

## Next Steps

1. **Create detailed implementation plan** for fixing critical gaps
2. **Start with App Gateway v2** deployment (T016)
3. **Move Container Apps Environment** to PaaS RG (T024)
4. **Implement Web VMSS** with auto-scaling (T017)
5. **Add all missing NSGs** for security (T009, T031, T038)
6. **Configure diagnostics** for observability (T013, T021, T035, T043)

**Estimated Effort to Fix**:

- Critical gaps: 8-12 hours
- Important gaps: 4-6 hours
- Complete validation: 2-4 hours
- **Total**: 14-22 hours

---

## Conclusion

The existing Bicep templates provide a **solid foundation** for the 4-layer infrastructure, but are **not production-ready** without significant additions. The missing Application Gateway v2 is a **show-stopper** that prevents any web traffic from reaching the system.

**Recommendation**: Do not deploy until Application Gateway v2, Web VMSS, and Container Apps RG placement are completed. These are blocking issues for the entire architecture.
