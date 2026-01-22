# Resource Group Organization Fix

**Issue**: Current deployment has resources in wrong resource groups  
**Status**: Identified and ready for correction  
**Date**: 2026-01-21

---

## Current Problems Identified

### 1. Container Infrastructure in Wrong RG

**Current State**:

- Container Apps Environment → jobsite-core-dev-rg ❌
- Log Analytics Workspace → jobsite-core-dev-rg ❌

**Should Be**:

- Container Apps Environment → jobsite-paas-dev-rg ✅
- Log Analytics Workspace → jobsite-core-dev-rg (shared, acceptable)

**Why This Matters**:

- Container Apps is a PaaS service, should live in PaaS RG
- Clean separation of concerns
- Cost tracking by layer
- Easier to manage PaaS resources together

---

### 2. Build Agents (VMSS) in Wrong RG

**Current State**:

- VMSS (GitHub Runners) → jobsite-iaas-dev-rg ❌
- SQL VMs, Web VMs → jobsite-iaas-dev-rg ✓

**Should Be**:

- VMSS (GitHub Runners) → jobsite-agents-dev-rg (new) ✅
- SQL VMs, Web VMs → jobsite-iaas-dev-rg ✓

**Why This Matters**:

- Build agents are ephemeral and managed differently
- Separate RG enables independent scaling policies
- Cost tracking for build infrastructure
- Different compliance/security requirements
- Lifecycle (create/destroy frequently)

**Network Connection**:

- Still uses snet-gh-runners (stays connected)
- Can reach other subnets through VNet
- No network changes needed

---

### 3. Web Front End (WFE) Missing

**Current State**:

- No Application Gateway deployed ❌
- No public IP for web traffic ❌
- No WAF protection ❌

**Should Be**:

- Application Gateway v2 → jobsite-iaas-dev-rg ✅
- Public IP address → jobsite-iaas-dev-rg ✅
- WAF rules configured → Application Gateway ✅

**Why This Matters**:

- HTTP/HTTPS entry point for applications
- Load balancing across VMSS
- WAF (Web Application Firewall) protection
- SSL/TLS termination
- URL-based routing

---

## Correct Resource Group Organization

### jobsite-core-dev-rg (Networking & Shared Services)

**Contains**:

```
✅ Virtual Network (10.50.0.0/21)
✅ Subnets (7 total)
✅ Private DNS Zone
✅ NAT Gateway
✅ Public IP (NAT)
✅ Key Vault
✅ Log Analytics Workspace
✅ Container Registry (ACR)
```

**Purpose**: Shared infrastructure used by IaaS and PaaS layers

---

### jobsite-iaas-dev-rg (Application Tier - Virtual Machines)

**Contains**:

```
✅ Application Gateway v2
✅ Public IP (App Gateway)
✅ Network Interfaces (for VMSS)
✅ VMSS (Web/App tier) - D2ds_v6
✅ SQL Server VM - D4ds_v6
✅ Disk resources
```

**Purpose**: Long-lived application VMs and load balancer

---

### jobsite-agents-dev-rg (Build Infrastructure - NEW)

**Contains** (Move from IAAS):

```
🆕 VMSS (GitHub Runners/Build Agents)
🆕 Network Interfaces (for build VMSS)
🆕 Disk resources (for build agents)
```

**Purpose**: Ephemeral build/CI-CD agents

**Network Access**:

- Connected to snet-gh-runners (via VNet)
- Can reach all subnets
- NAT outbound through NAT Gateway (core RG)

---

### jobsite-paas-dev-rg (Managed Services)

**Contains** (Move from CORE):

```
✅ Container Apps Environment (move from core)
✅ App Service Plan
✅ App Service
✅ SQL Database
✅ Application Insights
✅ Private Endpoints (for data access)
```

**Purpose**: PaaS services that scale automatically

---

### jobsite-data-dev-rg (Optional - Data Layer)

**Future Use**:

```
- Cosmos DB
- Azure SQL Database (if moved from paas)
- Redis Cache
- Storage Accounts (application data)
```

---

## Migration Steps

### Phase 1: Prepare (No Downtime)

```powershell
# 1. Document current Container Apps config
az containerapp show -g jobsite-core-dev-rg -n jobsite-dev-cae-ubzfsgu4p5eli | ConvertTo-Json

# 2. Document current VMSS config
az vmss show -g jobsite-iaas-dev-rg -n vmss-qahxan3ogcgdi | ConvertTo-Json

# 3. Create new resource groups
az group create -n jobsite-agents-dev-rg -l swedencentral
az group create -n jobsite-paas-dev-rg -l swedencentral (if not exists)
```

### Phase 2: Redeploy Resources

**Option A: Move via Redeploy (Recommended)**

```powershell
# 1. Update Bicep templates with correct RG references
# 2. Deploy PaaS layer to jobsite-paas-dev-rg
# 3. Deploy agents to jobsite-agents-dev-rg
# 4. Delete old resources from wrong RGs
# 5. Verify connectivity
```

**Option B: Move via Azure Portal**

```
❌ Not recommended - too complex and error-prone for multiple resources
```

### Phase 3: Verify Connectivity (10 min)

```powershell
# Build agents can reach web tier
$agentVm = Get-AzVm -ResourceGroupName jobsite-agents-dev-rg -Name "agent-vm-1"
$webVm = Get-AzVm -ResourceGroupName jobsite-iaas-dev-rg -Name "web-vm-1"

# Test network path
Test-NetConnection -ComputerName $webVm.PrivateIps[0] -Port 80

# Verify DNS resolution
Resolve-DnsName jobsite.internal  # Should resolve
```

---

## Updated Bicep Structure

### core/main.bicep

```bicep
metadata description = 'Shared networking and services'
param location string = 'swedencentral'
param environment string = 'dev'

// Creates: VNet, subnets, KV, LAW, ACR, NAT, DNS
```

### paas/main.bicep

```bicep
metadata description = 'PaaS services'
param location string = 'swedencentral'
param vnetResourceGroupName string = 'jobsite-core-dev-rg'
param containerAppEnvironmentId string // from core outputs

// Creates: Container Apps Env, App Service, SQL DB, App Insights, Private Endpoints
// Uses: subnets from core
```

### iaas/main.bicep

```bicep
metadata description = 'Application VMs and load balancer'
param location string = 'swedencentral'
param vnetResourceGroupName string = 'jobsite-core-dev-rg'

// Creates: App Gateway, VMSS (web), SQL VM, NICs, Disks
// Uses: snet-fe, snet-data subnets
```

### agents/main.bicep (NEW)

```bicep
metadata description = 'Build agents and CI/CD infrastructure'
param location string = 'swedencentral'
param vnetResourceGroupName string = 'jobsite-core-dev-rg'

// Creates: VMSS (build agents), NICs, Disks
// Uses: snet-gh-runners subnet
// Outputs: Build agent pool IDs, private IPs
```

---

## Web Front End (WFE) Implementation

### What's Missing

The Web Front End component is currently absent from the deployment. This includes:

- Application Gateway v2 (load balancer)
- Public IP for web traffic
- SSL/TLS certificates
- WAF (Web Application Firewall)
- URL routing rules

### Why It's Needed

1. **Entry Point**: HTTP/HTTPS ingress for all traffic
2. **Load Balancing**: Distribute traffic across VMSS instances
3. **WAF**: Protect against common attacks
4. **SSL/TLS**: Encrypt in-transit
5. **Routing**: Route based on URL path or hostname

### Architecture

```
Internet
    ↓
Public IP (App Gateway)
    ↓
Application Gateway v2 (WAF_v2)
    ↓
Backend Pool (VMSS instances in snet-fe)
    ↓
Web Tier (port 80, 443)
    ↓
App Tier (port 8080)
    ↓
Data Tier (port 1433 - SQL)
```

### Deployment Details

**Resource**: Application Gateway v2

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
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${vnetId}/subnets/snet-fe'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: { id: '${appGateway.id}/frontendIPConfigurations/appGatewayFrontendIP' }
          frontendPort: { id: '${appGateway.id}/frontendPorts/port_80' }
          protocol: 'Http'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [] // Populated by VMSS
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: { id: '${appGateway.id}/httpListeners/appGatewayHttpListener' }
          backendAddressPool: { id: '${appGateway.id}/backendAddressPools/appGatewayBackendPool' }
          backendHttpSettings: { id: '${appGateway.id}/backendHttpSettingsCollection/appGatewayBackendHttpSettings' }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection' // Use 'Prevention' for production
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.1'
    }
  }
}
```

---

## Corrected Resource Mapping

| Resource           | Current RG          | Correct RG            | Status  |
| ------------------ | ------------------- | --------------------- | ------- |
| VNet               | jobsite-core-dev-rg | jobsite-core-dev-rg   | ✓       |
| Subnets            | jobsite-core-dev-rg | jobsite-core-dev-rg   | ✓       |
| Key Vault          | jobsite-core-dev-rg | jobsite-core-dev-rg   | ✓       |
| Log Analytics      | jobsite-core-dev-rg | jobsite-core-dev-rg   | ✓       |
| Container Registry | jobsite-core-dev-rg | jobsite-core-dev-rg   | ✓       |
| Container Apps Env | jobsite-core-dev-rg | jobsite-paas-dev-rg   | 🔴 MOVE |
| App Gateway        | Missing             | jobsite-iaas-dev-rg   | 🔴 ADD  |
| Public IP (WFE)    | Missing             | jobsite-iaas-dev-rg   | 🔴 ADD  |
| Web VMSS           | jobsite-iaas-dev-rg | jobsite-iaas-dev-rg   | ✓       |
| SQL VM             | jobsite-iaas-dev-rg | jobsite-iaas-dev-rg   | ✓       |
| Build VMSS         | jobsite-iaas-dev-rg | jobsite-agents-dev-rg | 🔴 MOVE |
| App Service        | jobsite-paas-dev-rg | jobsite-paas-dev-rg   | ✓       |
| SQL Database       | jobsite-paas-dev-rg | jobsite-paas-dev-rg   | ✓       |
| App Insights       | jobsite-paas-dev-rg | jobsite-paas-dev-rg   | ✓       |

---

## Implementation Timeline

**Immediate (Today)**:

- ✅ Identify resources in wrong RGs (done)
- ✅ Create this fix specification (done)

**Short-term (This Week)**:

- [ ] Update Bicep templates for correct RG structure
- [ ] Create jobsite-agents-dev-rg
- [ ] Add Application Gateway to iaas/ layer
- [ ] Test new deployment

**Medium-term (Next Week)**:

- [ ] Execute migration (redeploy to correct RGs)
- [ ] Verify all connectivity works
- [ ] Update documentation
- [ ] Team knowledge transfer

---

## Risk Assessment

| Risk                           | Likelihood | Impact   | Mitigation                        |
| ------------------------------ | ---------- | -------- | --------------------------------- |
| Connectivity broken            | Medium     | High     | Test each move, verify NSG rules  |
| DNS resolution fails           | Low        | Medium   | Test DNS from each tier           |
| Build agents lose connectivity | Medium     | High     | Verify snet-gh-runners routing    |
| Data loss                      | Very Low   | Critical | No data layer being touched       |
| Downtime                       | High       | Medium   | Use blue-green or parallel deploy |

---

## Success Criteria

- ✅ All resources in correct RGs
- ✅ Build agents can reach web tier
- ✅ Web tier can reach data tier
- ✅ Container Apps environment works in PaaS RG
- ✅ Application Gateway receives traffic on port 80/443
- ✅ VMSS instances appear in App Gateway backend pool
- ✅ All connectivity tests pass
- ✅ Documentation updated
- ✅ Team trained on new structure

---

**Next Step**: Update specs/001-network-redesign/plan.md and Bicep templates with correct RG organization
