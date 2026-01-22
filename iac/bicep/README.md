# Infrastructure as Code (Bicep)

**Purpose**: Automate Azure infrastructure deployment  
**Language**: Bicep (Azure Resource Manager templates)  
**Status**: ✅ Production-ready (Core, IaaS, PaaS layers)

---

## 📖 Quick Navigation

### 🚀 Deploy Now (5 minutes)

→ See [QUICK_START.md](QUICK_START.md)

### 📚 Understand the Design (20 minutes)

→ Read [../NETWORK_REDESIGN.md](../NETWORK_REDESIGN.md)  
→ Then [../../specs/001-network-redesign/plan.md](../../specs/001-network-redesign/plan.md)

### 🔍 Detailed Reference

→ Use [QUICK_REFERENCE_CARD.md](QUICK_REFERENCE_CARD.md) - Commands to print
→ Or [INDEX.md](INDEX.md) - Complete file listing

---

## 🏗️ Architecture

The infrastructure is deployed in **3 layers**:

### Layer 1: Core (Networking & Shared Services)

**Files**: `core/main.bicep`, `core/core-resources.bicep`

**Creates**:

- Virtual Network (10.50.0.0/21) - 2,048 IPs
- 7 subnets (frontend, data, PE, build agents, AKS, Container Apps, Gateway)
- Key Vault (secrets management)
- Log Analytics Workspace (monitoring)
- Azure Container Registry (container images)
- Container App Environment (serverless containers)
- Private DNS Zone (internal service discovery)
- NAT Gateway (outbound traffic control)

**Deployment Time**: ~2-3 minutes  
**Cost Impact**: ~$30-50/month

### Layer 2: IaaS (Virtual Machines & Networking)

**Files**: `iaas/main.bicep`, `iaas/iaas-resources.bicep`

**Creates**:

- VMSS (Web/App tier) - D2ds_v6 instances
- SQL Server VM - D4ds_v6
- Application Gateway (WAF v2)
- Network interfaces & IPs
- Managed Identities (for secure access)
- Extensions (monitoring, security)

**Deployment Time**: ~5-10 minutes  
**Cost Impact**: ~$200-400/month

### Layer 3: PaaS (App Services & Databases)

**Files**: `paas/main.bicep`, `paas/paas-resources.bicep`

**Creates**:

- App Service (ASP.NET Core hosting)
- SQL Database (managed database)
- Application Insights (APM)
- Private Endpoints (for secure access)

**Deployment Time**: ~5-10 minutes  
**Cost Impact**: ~$50-150/month

---

## 🚀 Deployment Guide

### Quick Start (5 minutes)

```powershell
# 1. Prerequisites
az --version          # Azure CLI 2.50+
bicep version         # Bicep CLI 0.26+

# 2. Configure parameters
code core/parameters.bicepparam
# Edit: location, sqlAdminPassword, etc.

# 3. Deploy Core layer
az deployment group create `
  --name jobsite-core-prod `
  --resource-group jobsite-core-rg `
  --template-file core/main.bicep `
  --parameters @core/parameters.bicepparam

# 4. Get outputs (needed for next layers)
az deployment group show `
  --resource-group jobsite-core-rg `
  --name jobsite-core-prod `
  --query properties.outputs

# 5. Continue with IaaS and PaaS layers
# (See QUICK_START.md for complete steps)
```

### Full Details

See [QUICK_START.md](QUICK_START.md) for:

- Complete prerequisite checklist
- Step-by-step deployment for all 3 layers
- How to get outputs from each layer
- Validation commands

### Reference

See [QUICK_REFERENCE_CARD.md](QUICK_REFERENCE_CARD.md) for:

- One-page command reference (printable)
- Pre-deployment checklist
- Post-deployment validation
- Common troubleshooting

---

## 📂 File Structure

```
iac/bicep/
│
├── README.md                           ← This file
├── QUICK_START.md                      ← Deployment guide (5 min)
├── QUICK_REFERENCE_CARD.md             ← Printable commands
├── INDEX.md                            ← Complete file listing
│
├── core/                               ← Layer 1: Networking
│   ├── main.bicep
│   ├── core-resources.bicep
│   ├── parameters.bicepparam
│   └── [networking, KV, monitoring modules]
│
├── iaas/                               ← Layer 2: VMs
│   ├── main.bicep
│   ├── iaas-resources.bicep
│   ├── parameters.bicepparam
│   └── [VMSS, SQL, App Gateway modules]
│
├── paas/                               ← Layer 3: App Services
│   ├── main.bicep
│   ├── paas-resources.bicep
│   ├── parameters.bicepparam
│   └── [App Service, SQL DB, App Insights modules]
│
└── scripts/                            ← Deployment scripts
    ├── deploy-core.ps1
    ├── deploy-iaas.ps1
    ├── deploy-paas.ps1
    └── get-outputs.ps1
```

---

## 🔧 Configuration

### Key Parameters

Each layer uses a `.bicepparam` file:

```bicep
// Example: parameters.bicepparam
param location = 'swedencentral'
param environment = 'prod'
param vnetAddressPrefix = '10.50.0.0/21'
param sqlAdminPassword = 'CHANGE_ME_STRONG_PASSWORD'
param vmSize = 'Standard_D2ds_v6'
```

### Environment-Specific Parameters

Pre-configured parameter files exist:

- `parameters-dev.bicepparam` - Development (smaller SKUs)
- `parameters-staging.bicepparam` - Staging (medium SKUs)
- `parameters-prod.bicepparam` - Production (full SKUs)

---

## ✅ Deployment Checklist

### Before Deploying

- [ ] Azure subscription created and selected
- [ ] Azure CLI 2.50+ installed
- [ ] Bicep CLI 0.26+ installed
- [ ] Resource group exists
- [ ] Parameter file reviewed and updated
- [ ] All passwords are strong (15+ chars, mixed case, numbers, symbols)
- [ ] Region selected and has capacity for your SKU

### During Deployment

- [ ] Watch deployment progress
- [ ] Note any warnings (usually safe to ignore)
- [ ] Save outputs for next layer

### After Deployment

- [ ] All resources created successfully
- [ ] Validate with QUICK_REFERENCE_CARD.md commands
- [ ] Test connectivity to all tiers
- [ ] Check monitoring (Log Analytics, App Insights)
- [ ] Verify security (RBAC, Key Vault access)

---

## 📊 Infrastructure Details

### Network Architecture

| Subnet          | CIDR           | Purpose                | IPs |
| --------------- | -------------- | ---------------------- | --- |
| snet-fe         | 10.50.0.0/24   | Frontend / App Gateway | 251 |
| snet-data       | 10.50.1.0/26   | SQL VMs                | 61  |
| snet-gh-runners | 10.50.1.64/26  | Build agents (VMSS)    | 61  |
| snet-pe         | 10.50.1.128/27 | Private Endpoints      | 29  |
| GatewaySubnet   | 10.50.1.160/27 | VPN Gateway            | 29  |
| snet-aks        | 10.50.2.0/23   | AKS cluster            | 507 |
| snet-ca         | 10.50.4.0/26   | Container Apps         | 61  |
| Reserved        | 10.50.4.64+    | Future growth          | 896 |

**Total**: 2,048 IPs (56% used, 44% reserved)

### Security Configuration

✅ **Network**:

- Network Security Groups (NSGs) on all subnets
- Private Endpoints for Key Vault, SQL, Storage
- Private DNS zone for internal routing

✅ **Access Control**:

- RBAC with least privilege
- Managed Identities for VM access
- Service Principals for automation

✅ **Data Protection**:

- Encryption at rest (Storage, SQL, Key Vault)
- Encryption in transit (HTTPS, TLS 1.2+)
- All credentials in Key Vault
- No hardcoded secrets

✅ **Monitoring**:

- Log Analytics Workspace
- Application Insights
- Microsoft Defender for Cloud
- Diagnostic settings on all resources

---

## 🛠️ Common Tasks

### Deploy All 3 Layers

```powershell
# 1. Deploy Core
./scripts/deploy-core.ps1

# 2. Get Core outputs
./scripts/get-outputs.ps1 -ResourceGroup jobsite-core-rg

# 3. Deploy IaaS (using Core outputs)
./scripts/deploy-iaas.ps1

# 4. Deploy PaaS (using Core outputs)
./scripts/deploy-paas.ps1

# 5. Validate
az deployment group list --resource-group jobsite-core-rg
```

### Update a Specific Resource

```powershell
# Update just the VMSS (keep other resources)
az deployment group create \
  --name iaas-update \
  --resource-group jobsite-iaas-rg \
  --template-file iaas/main.bicep \
  --parameters @iaas/parameters.bicepparam
```

### Check Deployment Status

```powershell
# View recent deployments
az deployment group list --resource-group jobsite-core-rg

# View specific deployment
az deployment group show \
  --name jobsite-core-prod \
  --resource-group jobsite-core-rg

# View any errors
az deployment group show \
  --name jobsite-core-prod \
  --resource-group jobsite-core-rg \
  --query properties.provisioningState
```

---

## 🔗 Related Documentation

### Infrastructure Design

- [../../specs/001-network-redesign/plan.md](../../specs/001-network-redesign/plan.md) - Architecture decisions
- [../../specs/001-network-redesign/spec.md](../../specs/001-network-redesign/spec.md) - Network requirements
- [../../specs/001-network-redesign/tasks.md](../../specs/001-network-redesign/tasks.md) - Deployment tasks

### Deployment & Operations

- [QUICK_START.md](QUICK_START.md) - Step-by-step deployment
- [QUICK_REFERENCE_CARD.md](QUICK_REFERENCE_CARD.md) - Printable commands
- [../NETWORK_REDESIGN.md](../NETWORK_REDESIGN.md) - Migration guide

### Application Deployment

- [../../appV2/README.md](../../appV2/README.md) - .NET application
- [../../appV3/README.md](../../appV3/README.md) - Python application

---

## ❓ FAQ

### Q: How long does deployment take?

**A**: ~15-20 minutes for all 3 layers (Core: 2-3 min, IaaS: 5-10 min, PaaS: 5-10 min)

### Q: What if deployment fails?

**A**: See troubleshooting in QUICK_REFERENCE_CARD.md

### Q: Can I deploy just one layer?

**A**: Yes, but IaaS depends on Core outputs, and PaaS depends on Core outputs

### Q: How do I add/remove VMs?

**A**: Edit VMSS size in iaas/parameters.bicepparam, then redeploy IaaS layer

### Q: Where are my secrets stored?

**A**: All secrets are in Key Vault (not in templates or scripts)

### Q: Can I deploy to a different region?

**A**: Yes, change the `location` parameter in parameters.bicepparam

---

## 📞 Support

| Issue                 | Reference                                                                            |
| --------------------- | ------------------------------------------------------------------------------------ |
| Deployment errors     | QUICK_REFERENCE_CARD.md (Troubleshooting)                                            |
| What resources exist? | INDEX.md                                                                             |
| How do I deploy?      | QUICK_START.md                                                                       |
| Why this design?      | [../../specs/001-network-redesign/plan.md](../../specs/001-network-redesign/plan.md) |
| Network architecture? | [../../specs/001-network-redesign/spec.md](../../specs/001-network-redesign/spec.md) |

---

**Last Updated**: 2026-01-21  
**Status**: ✅ Production-ready  
**Next Step**: See [QUICK_START.md](QUICK_START.md)
