# VM Infrastructure Deployment - Quick Reference Card

**Print this or save to your phone for quick access during deployment!**

---

## 📋 Pre-Deployment Checklist

- [ ] Azure CLI 2.50+ installed
- [ ] Bicep CLI 0.26+ installed
- [ ] VPN root certificate (base64)
- [ ] App Gateway cert (PFX, base64)
- [ ] Resource groups created
- [ ] Parameters updated
- [ ] Credentials prepared

---

## 🚀 Deployment Commands

### 1. Deploy Core Infrastructure

```bash
az deployment group create \
  --name jobsite-core-deploy \
  --resource-group jobsite-core-rg \
  --template-file infrastructure/bicep/core/main.bicep \
  --parameters infrastructure/bicep/core/parameters.bicepparam
```

### 2. Get Core Outputs

```bash
az deployment group show \
  --resource-group jobsite-core-rg \
  --name jobsite-core-deploy \
  --query properties.outputs
```

### 3. Deploy IaaS Infrastructure

```bash
az deployment group create \
  --name jobsite-iaas-deploy \
  --resource-group jobsite-iaas-rg \
  --template-file infrastructure/bicep/iaas/main.bicep \
  --parameters infrastructure/bicep/iaas/parameters.bicepparam \
    vnetId="<from-core>" \
    frontendSubnetId="<from-core>" \
    dataSubnetId="<from-core>" \
    logAnalyticsWorkspaceId="<from-core>"
```

---

## 🔧 Post-Deployment Quick Tasks

### SQL Server Initialization

```powershell
# RDP into SQL VM and run:
Initialize-Disk -Number 1 -PartitionStyle MBR
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS

# Create database
sqlcmd -S localhost -U jobsiteadmin -P "password" -Q "CREATE DATABASE jobsitedb"
```

### Add Private DNS Record

```bash
az network private-dns record-set a add-record \
  --resource-group jobsite-core-rg \
  --zone-name jobsite.internal \
  --record-set-name sql \
  --ipv4-address <SQL_PRIVATE_IP>
```

### Scale VMSS

```bash
az vmss scale \
  --resource-group jobsite-vm-rg \
  --name <vmss-name> \
  --new-capacity 3
```

---

## 📊 Architecture at a Glance

```
Internet ──→ [App GW WAF] ──→ [VMSS IIS] ──→ [SQL Server]
              10.50.224.0/27   10.50.0.0/27   10.50.0.32/27
                  (public)       (private)       (private)
                                    ↓
                            [NAT Gateway]
                                    ↓
                            [Internet Outbound]

VPN Clients ──→ [VPN GW] ──→ [All Subnets]
(10.70.0.0)   10.50.0.64/27 (private DNS)
```

---

## 🔑 Key Network Details

| Component   | CIDR/Details                |
| ----------- | --------------------------- |
| VNet        | 10.50.0.0/16                |
| Frontend    | 10.50.0.0/27 (VMSS)         |
| Data        | 10.50.0.32/27 (SQL)         |
| Gateway     | 10.50.0.64/27 (VPN)         |
| Private Ep  | 10.50.0.96/27 (PE)          |
| GitHub      | 10.50.0.128/27 (Runners)    |
| AKS         | 10.50.0.160/27 (Kubernetes) |
| Container   | 10.50.0.192/27 (Apps)       |
| App Gateway | 10.50.224.0/27 (WAF)        |
| VPN Clients | 10.70.0.0/24 (P2S)          |
| Private DNS | jobsite.internal            |

---

## 💻 VM Specifications

### VMSS (Web Frontend)

- **OS**: Windows Server 2019 Datacenter
- **Size**: D2s_v5 (2 vCPU, 4GB RAM)
- **Instances**: 1 (scale to 10)
- **Disk**: Premium_LRS (OS)
- **Auth**: Managed Identity + Azure AD
- **Features**: IIS, ASP.NET 4.5, Windows Auth

### SQL Server VM

- **OS**: Windows Server 2019
- **SQL**: SQL Server 2019 Standard
- **Size**: D2s_v5 (2 vCPU, 4GB RAM)
- **Disks**: Premium_LRS (OS + Data)
- **Auth**: Managed Identity
- **Config**: Standalone, private connectivity

### App Gateway

- **SKU**: WAF_v2 (minimum 2 instances)
- **Auth**: Certificate + AAD (configured)
- **Mode**: Detection (→ Prevention for prod)
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Logging**: Enabled to Log Analytics

---

## 📈 Estimated Costs

| Component       | Monthly   |
| --------------- | --------- |
| VMSS (D2s_v5)   | ~$75      |
| SQL VM (D2s_v5) | ~$75      |
| App Gateway     | ~$180     |
| NAT Gateway     | ~$35      |
| VPN Gateway     | ~$35      |
| Other           | ~$25      |
| **TOTAL**       | **~$430** |

_Varies by region and actual usage_

---

## 🔐 Security Defaults

✅ **Already Enabled**

- RBAC Key Vault
- Private networks with NAT
- WAF on App Gateway
- Managed identities
- Diagnostic logging
- Premium disks

⚠️ **Requires Configuration**

- Replace self-signed cert
- Enable WAF Prevention mode
- Configure NSGs (if needed)
- Enable Azure Defender
- Setup backup policies

---

## 📊 Monitoring Quick Queries

### VMSS CPU Usage

```kusto
Perf
| where ObjectName == "Processor"
| where Computer contains "jobsite"
| summarize AvgCpu=avg(CounterValue) by bin(TimeGenerated, 5m)
```

### App Gateway Requests

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| summarize count() by httpStatus_s
```

### VPN Connections

```kusto
AzureDiagnostics
| where ResourceType == "VIRTUALNETWORKGATEWAYS"
| summarize count() by Category
```

---

## 🆘 Quick Troubleshooting

| Issue                 | Fix                                 |
| --------------------- | ----------------------------------- |
| VPN fails to deploy   | Check GatewaySubnet exists with /27 |
| App Gateway unhealthy | Verify IIS running on VMSS          |
| SQL unreachable       | Check private DNS record added      |
| Outbound blocked      | Check NAT Gateway associated        |
| Can't authenticate    | Verify managed identity created     |

---

## 🎯 Success Checklist

After deployment, verify:

- [ ] All resources in Resource Groups
- [ ] VMSS has 1 instance running
- [ ] SQL Server VM in Data subnet
- [ ] App Gateway healthy (backend green)
- [ ] IIS responds to localhost
- [ ] SQL connection works
- [ ] Private DNS resolves jobsite.internal
- [ ] VPN Gateway listening
- [ ] Log Analytics receiving data

---

## 📞 Help Resources

| Need             | File                   |
| ---------------- | ---------------------- |
| Quick start      | QUICKSTART_VM.md       |
| Step-by-step     | vm/DEPLOYMENT_GUIDE.md |
| Architecture     | core/README.md         |
| Troubleshooting  | vm/DEPLOYMENT_GUIDE.md |
| Navigation       | VM_INDEX.md            |
| Complete summary | COMPLETION_SUMMARY.md  |

---

## 🏁 Key Milestones

**T+0 min**: Read QUICKSTART_VM.md (5 min)
**T+5 min**: Generate certificates (10 min)
**T+15 min**: Deploy core infrastructure (10 min)
**T+25 min**: Deploy VM infrastructure (15 min)
**T+40 min**: Configure IIS & SQL (30 min)
**T+70 min**: Test & validate (15 min)
**T+85 min**: Live! 🚀

---

## 🔑 Important Outputs to Save

```
CORE MODULE OUTPUTS:
□ vnetId
□ vnetName
□ frontendSubnetId
□ dataSubnetId
□ peSubnetId
□ keyVaultId
□ keyVaultName
□ privateDnsZoneId
□ logAnalyticsWorkspaceId
□ natGatewayPublicIp
□ vpnGatewayPublicIp

VM MODULE OUTPUTS:
□ vmssId
□ vmssName
□ sqlVmId
□ sqlVmName
□ sqlVmPrivateIp
□ appGatewayId
□ appGatewayName
□ appGatewayPublicIp
```

---

## 📝 Quick Parameter Reference

| Parameter            | Example        | Where |
| -------------------- | -------------- | ----- |
| environment          | 'dev'          | Both  |
| applicationName      | 'jobsite'      | Both  |
| location             | 'eastus'       | Both  |
| vnetAddressPrefix    | '10.50.0.0/16' | Core  |
| vpnClientAddressPool | '10.70.0.0/24' | Core  |
| sqlAdminUsername     | 'jobsiteadmin' | Both  |
| sqlAdminPassword     | '\*\*\*'       | Both  |
| vpnRootCertificate   | '<base64>'     | Core  |
| vmAdminUsername      | 'azureuser'    | VM    |
| vmAdminPassword      | '\*\*\*'       | VM    |

---

**Print this card! Keep handy during deployment.** 🚀

---

**Version**: 1.0  
**Created**: 2026-01-21  
**Status**: Ready to Use
