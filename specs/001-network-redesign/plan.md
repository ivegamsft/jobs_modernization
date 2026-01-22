# Network Redesign - Implementation Plan

**Status**: Ready for Task Breakdown  
**Tech Stack**: Bicep IaC, Azure CLI, PowerShell  
**Target Region**: Sweden Central  
**Environment**: dev (initial), expandable to staging/prod

---

## Architecture Decisions

### 1. VNet Sizing: /21 vs Alternatives

**Decision**: Use 10.50.0.0/21 (2,048 IPs)

**Rationale**:

- Current /24 leaves 0% room for growth (blocker)
- /22 (1,024 IPs) considered too conservative, wastes space
- /21 (2,048 IPs) provides 3-5x growth headroom
- No additional cost regardless of VNet size
- Aligns with Microsoft standard practice (most enterprises use /21 or larger)

**Alternatives Considered**:

- /20 (4,096 IPs): Over-provisioning for dev environment
- /22 (1,024 IPs): Too tight, increases likelihood of future redesign
- Stay with /24: Confirmed blocker - cannot scale

---

### 2. Subnet Sizing Strategy

**Decision**: Size each subnet based on Azure service requirements + 50% buffer

**Rationale**:

```
Usable IPs = Subnet Size - 5 (Azure reserved) - Service Reserved
Buffer = Usable IPs * 0.5
Max Instances = Usable IPs - Buffer
```

**Examples**:

**Frontend (snet-fe): /24**

- Total IPs: 256
- Azure Reserved: 5
- App Gateway Instances: 125
- Available: 251 - 125 = 126 buffer ✓

**GitHub Runners (snet-gh-runners): /26**

- Total IPs: 64
- Azure Reserved: 5
- VMSS Instances Max: 50
- Available: 59 - 50 = 9 buffer ✓

**AKS (snet-aks): /23**

- Total IPs: 512
- Azure Reserved: 5
- Container App reserved: 12 (per subnet)
- Overlay network nodes: 250+
- Available: 507 - 250 = 257 buffer ✓

---

### 3. Deployment Strategy: Blue-Green vs Fresh Start

**Decision**: Fresh Start (Option 3) for dev environment

**Rationale**:

- Dev environment, not production
- No customer impact
- Faster implementation (2-4 hours vs 15-30 min migration)
- Cleaner testing of new architecture
- All resources deployed fresh with best practices

**Execution Plan**:

1. **Document Current State** (30 min)
   - Export current resource configs to Bicep
   - List all dependencies and data

2. **Prepare New Infrastructure** (60 min)
   - Update core-resources.bicep with new subnets
   - Validate Bicep templates
   - Prepare deployment scripts

3. **Tear Down (Optional)** (30 min)
   - Delete old resource group (can skip if parallel deploying)
   - Verify cleanup

4. **Deploy New Infrastructure** (60 min)
   - Deploy Core layer (VNet, subnets, services)
   - Deploy IaaS layer (VMSS, SQL VM, App Gateway)
   - Deploy PaaS layer (App Service, SQL DB, App Insights)

5. **Validation & Testing** (60 min)
   - Test connectivity between tiers
   - Verify monitoring/diagnostics
   - Confirm scaling works properly

---

### 4. IaC Framework: Bicep Module Structure + Resource Group Organization

**Decision**: 4-layer architecture with proper resource group separation

**Rationale**:

- **Core (jobsite-core-dev-rg)**: Shared infrastructure (VNet, subnets, Key Vault, Log Analytics, ACR)
- **IaaS (jobsite-iaas-dev-rg)**: Long-lived application VMs (Web VMSS, SQL VM, App Gateway WFE)
- **PaaS (jobsite-paas-dev-rg)**: Managed services (Container Apps, App Service, SQL Database, App Insights)
- **Agents (jobsite-agents-dev-rg)**: Ephemeral build infrastructure (GitHub Runners VMSS)

**Benefits**:

- Clear separation of concerns
- Independent scaling policies per tier
- Cost tracking by layer
- Correct lifecycle management (ephemeral vs long-lived)
- Can deploy IaaS, PaaS, Agents in parallel
- Easy to enable/disable features
- Reusable across environments

**Resource Group Organization**:

```
jobsite-core-dev-rg (Shared Networking)
├── Virtual Network (10.50.0.0/21)
├── 7 Subnets
├── Private DNS Zone
├── NAT Gateway + Public IP
├── Key Vault
├── Log Analytics Workspace
└── Container Registry

jobsite-iaas-dev-rg (Application Tier VMs)
├── Application Gateway v2 (WFE)
├── Public IP (App Gateway)
├── Web VMSS (D2ds_v6)
├── SQL Server VM (D4ds_v6)
└── Network Interfaces & Disks

jobsite-paas-dev-rg (Managed Services)
├── Container Apps Environment
├── App Service Plan
├── App Service
├── SQL Database
├── Application Insights
└── Private Endpoints

jobsite-agents-dev-rg (Build Infrastructure)
├── Build Agent VMSS (GitHub Runners)
├── Network Interfaces
└── Disks
```

**File Structure**:

```
iac/
├── bicep/
│   ├── core/
│   │   ├── main.bicep (entry point, subscription scope)
│   │   └── core-resources.bicep (VNet, subnets, KV, ACR, etc.)
│   ├── iaas/
│   │   ├── main.bicep (entry point, resource group scope)
│   │   └── iaas-resources.bicep (App Gateway, Web VMSS, SQL VM)
│   ├── paas/
│   │   ├── main.bicep (entry point, resource group scope)
│   │   └── paas-resources.bicep (Container Apps, App Service, SQL DB)
│   ├── agents/
│   │   ├── main.bicep (entry point, resource group scope)
│   │   └── agents-resources.bicep (Build Agent VMSS)
│   └── scripts/
│       ├── deploy-core.ps1
│       ├── deploy-iaas.ps1
│       ├── deploy-paas.ps1
│       └── deploy-agents.ps1
```

**Deployment Order**:

1. Core layer (creates VNet, subnets, shared services)
2. IaaS, PaaS, Agents in parallel (all depend only on Core outputs)

---

### 5. Resource Naming & Tagging Strategy

**Decision**: Consistent naming convention for all resources

**Naming Pattern**:

- Core: `{applicationName}-{environment}-{resource-type}`
- Example: `jobsite-dev-vnet`, `jobsite-dev-rg-core`

**Tags Applied**:

```bicep
tags: {
  Application: 'JobSite'
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Layer: 'Core/IaaS/PaaS'
  CreatedDate: '2026-01-21'
}
```

**Benefits**:

- Easy to find all resources for an app/environment
- Cost allocation by business unit
- Automated backup/cleanup policies possible

---

### 6. Web Front End (WFE): Application Gateway v2 Architecture

**Decision**: Application Gateway v2 with WAF for HTTP/HTTPS ingress

**Rationale**:

- Single entry point for all web traffic
- Load balancing across VMSS instances
- WAF protection against OWASP Top 10
- SSL/TLS termination
- Path-based routing capabilities
- Production-grade reliability (99.99% SLA)

**Architecture**:

```
Internet (Users)
    ↓
Public IP (jobsite-dev-pip-agw)
    ↓
Application Gateway v2 (jobsite-dev-agw)
├── SKU: WAF_v2
├── Capacity: 2-10 (auto-scale)
├── Front-end Port: 80, 443
└── Backend Pool: Web VMSS instances (snet-fe)
    ↓
Web VMSS (snet-fe)
├── D2ds_v6 instances
├── IIS + ASP.NET Core
└── Ports 80/443
    ↓
App Tier
├── Business logic
└── Database connections
    ↓
Data Tier (SQL Server)
```

**WAF Configuration**:

- **Mode**: Detection (dev), Prevention (prod)
- **Rule Set**: OWASP 3.1
- **Protections**:
  - SQL Injection
  - Cross-Site Scripting (XSS)
  - Local File Inclusion (LFI)
  - Remote File Inclusion (RFI)
  - Session Fixation
  - Protocol Attacks

**Deployment**:

```bicep
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: 'jobsite-dev-agw'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: environment == 'prod' ? 'Prevention' : 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.1'
    }
    // ... frontend/backend/routing config
  }
}
```

**Monitoring**:

- Application Gateway metrics in Log Analytics
- Request latency
- Failed requests
- Backend health status
- WAF-triggered rules

---

### 7. Build Infrastructure: GitHub Runners in Dedicated RG

**Decision**: VMSS for ephemeral build agents in separate resource group

**Rationale**:

- Build agents are created/destroyed frequently (not long-lived)
- Independent scaling policy from application tier
- Separate cost tracking for CI/CD infrastructure
- Different security/compliance requirements
- Can update agent image without affecting prod VMs

**Architecture**:

```
jobsite-agents-dev-rg (Dedicated Build RG)
└── GitHub Runners VMSS
    ├── Auto-scale: 1-5 instances
    ├── SKU: D2ds_v6
    ├── Image: Ubuntu 22.04 + GitHub Runner
    ├── Connected to: snet-gh-runners (core VNet)
    └── Outbound: Via NAT Gateway (core RG)

Network Connectivity:
├── Inbound: GitHub API webhooks
├── Outbound: NAT Gateway → Internet
├── Internal: Can reach all subnets via VNet
└── Database: Can reach SQL VM in data tier
```

**VMSS Configuration**:

```bicep
resource buildVmss 'Microsoft.Compute/virtualMachineScaleSets@2023-07-01' = {
  name: 'vmss-build-agents'
  location: location
  properties: {
    orchestrationMode: 'Uniform'
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 33
        maxUnhealthyInstancePercent: 33
      }
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: { storageAccountType: 'Standard_LRS' }
        }
      }
      osProfile: {
        computerNamePrefix: 'build-'
        adminUsername: 'azureuser'
        customData: base64('#!/bin/bash\n# GitHub Runner install script')
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: { id: '${vnetId}/subnets/snet-gh-runners' }
                    privateIPAddressVersion: 'IPv4'
                  }
                }
              ]
            }
          }
        ]
      }
    }
    overprovision: false
  }
}
```

**Scaling Policy**:

- **Min Instances**: 1
- **Max Instances**: 5
- **Scale-out Trigger**: Queue depth > 2
- **Scale-in Trigger**: Queue depth < 1

---

### 8. Monitoring & Diagnostics

**Decision**: Centralize logs in Log Analytics, configure diagnostics for all resources

**Implementation**:

- **VNet Diagnostics**: NSG flow logs to storage account
- **App Gateway**: Diagnostic logs to Log Analytics
- **VMSS**: Guest OS diagnostics via Log Analytics agent
- **SQL**: Query Performance Insights, audit logs
- **App Service**: Application logs, trace logs
- **Container Apps**: Runtime logs to Log Analytics

**Queries Provided**:

- IP address allocation by subnet
- Network latency between tiers
- Application Gateway request latency
- Failed connectivity attempts

---

### 9. Security Implementation

**Decision**: Zero hardcoded credentials, all secrets in Key Vault

**Key Vault Secrets**:

- VM Admin Password
- App Gateway Certificate Password
- SQL Server SA Password
- Connection Strings (on demand)

**Managed Identities**:

- VMSS → Read App Gateway config
- App Service → Read Key Vault secrets
- SQL Server → Use Microsoft Entra authentication

**Network Security**:

- NSGs with explicit allow rules per tier
- Private endpoints for Key Vault, SQL, Storage
- Service endpoints for Azure services
- No public internet access to data tier

---

## Implementation Timeline

### Phase 1: Preparation (Day 1)

- [ ] Review this plan with team
- [ ] Answer open questions from spec
- [ ] Prepare rollback plan

### Phase 2: Infrastructure Deployment (Day 1-2)

- [ ] Update Bicep templates
- [ ] Test in isolation (validate syntax)
- [ ] Deploy Core layer
- [ ] Deploy IaaS layer
- [ ] Deploy PaaS layer

### Phase 3: Validation (Day 2)

- [ ] Test all connectivity paths
- [ ] Verify monitoring and logging
- [ ] Validate backup procedures
- [ ] Document any issues

### Phase 4: Documentation (Day 2-3)

- [ ] Update architecture diagrams
- [ ] Create runbook for common tasks
- [ ] Document lessons learned
- [ ] Prepare for team knowledge transfer

---

## Risk Assessment & Mitigation

| Risk                                        | Likelihood | Impact | Mitigation                                                         |
| ------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------ |
| VMSS fails to deploy to new subnet          | Low        | High   | Test VMSS network profile with networkApiVersion                   |
| IP conflict with existing resources         | Low        | High   | Pre-validate all CIDR ranges don't overlap                         |
| NSG rules too restrictive                   | Medium     | Medium | Test connectivity from each tier before going live                 |
| Application Gateway can't find backend VMSS | Medium     | High   | Ensure VMSS in frontend-accessible subnet (done - snet-gh-runners) |
| Cost overruns from overlooked resources     | Low        | Medium | Review pricing calculator for all services                         |
| Long deployment time impacts team           | Low        | Medium | Prepare dry-run ahead of time, parallel deploy IaaS/PaaS           |

---

## Success Criteria for Implementation

✅ **Functional**:

- [ ] All 7 subnets created with correct CIDRs
- [ ] All resources deployed successfully
- [ ] Services can communicate across tiers
- [ ] Monitoring/diagnostics working

✅ **Performance**:

- [ ] VNet creation < 2 minutes
- [ ] Full stack deployment < 15 minutes
- [ ] No observable network latency increase

✅ **Security**:

- [ ] No credentials in git
- [ ] All secrets in Key Vault
- [ ] NSGs properly configured
- [ ] Audit logging enabled

✅ **Documentation**:

- [ ] Architecture diagram updated
- [ ] Deployment guide written
- [ ] Troubleshooting guide created
- [ ] Team trained on new design

---

## Cost Estimates

| Resource             | Type       | Qty | Price/Month | Total   |
| -------------------- | ---------- | --- | ----------- | ------- |
| VNet                 | Networking | 1   | $0          | $0      |
| NAT Gateway          | Egress     | 1   | ~$32        | $32     |
| Public IP            | IP Address | 1   | ~$3         | $3      |
| NSG                  | Security   | 7   | $0          | $0      |
| **Total Networking** | -          | -   | -           | **$35** |

_Note: Most significant cost comes from compute (VMSS, App Service, SQL), not networking._

---

## Dependencies & Prerequisites

### Tools Required

- Azure CLI (latest)
- PowerShell 7+
- Git
- Bicep CLI (comes with Azure CLI)

### Azure Permissions

- Contributor or higher on subscription
- Ability to create resource groups
- Network contributor role

### Knowledge Requirements

- Understanding of TCP/IP networking
- Familiarity with Azure services
- Basic Bicep syntax

---

## Rollback Plan

If issues arise during deployment:

**Option A: Keep Old Network**

- Don't delete old resource group
- Point DNS back to old App Gateway
- Investigate issues offline

**Option B: Redeploy Old Network**

- Have Bicep templates for old /24 design ready
- Can redeploy in ~15 minutes
- All code and scripts version controlled

**Option C: Hybrid Mode**

- Keep old for production
- Use new for dev/testing
- Migrate when confident

---

## Next Steps

1. ✅ Share this plan with team
2. ✅ Answer open questions from spec.md
3. ✅ Get approvals from stakeholders
4. → **RUN `/speckit.tasks`** to create actionable task breakdown
5. → **RUN `/speckit.implement`** to execute all tasks

---

**Plan Prepared By**: Infrastructure Team  
**Review Date**: 2026-01-21  
**Approval Status**: Pending
