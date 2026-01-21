# VM-Based JobSite Infrastructure - Quick Reference

## Deployment Checklist

### Pre-Deployment

- [ ] Azure subscription with permissions
- [ ] Azure CLI 2.50+ installed
- [ ] Bicep CLI 0.26+ installed
- [ ] Generate VPN root certificate (base64)
- [ ] Generate App Gateway certificate (PFX, base64)
- [ ] Prepare resource group names
- [ ] Prepare parameter values

### Deployment Order

1. Deploy Core Infrastructure (#core/main.bicep)
2. Capture core outputs
3. Deploy VM Infrastructure (#vm/main.bicep)
4. Execute post-deployment scripts

### Post-Deployment

- [ ] Configure IIS on VMSS instances
- [ ] Initialize SQL Server VM data disk
- [ ] Create SQL database
- [ ] Add Private DNS A records
- [ ] Configure Log Analytics alerts
- [ ] Update App Gateway certificate
- [ ] Test VPN connectivity
- [ ] Deploy application to VMSS

## Architecture Quick View

```
┌──────────────────────┐
│   Internet Clients   │
│   (VPN: 10.70.0.0)   │
└──────────┬───────────┘
           │
      [VPN Gateway]
           │
    ┌──────┴──────────────────────────┐
    │      VNet (10.50.0.0/16)         │
    │  ┌─────────────────────────────┐ │
    │  │  [App Gateway WAF_v2]        │ │  Port 443/80
    │  │  10.50.224.0/27              │ │─────────┐
    │  └─────────┬────────────────────┘ │         │
    │            │                      │         │
    │      [VMSS with IIS]              │         │
    │      10.50.0.0/27                 │         │
    │      1 instance (manual scale)     │         │
    │            │                      │         │
    │            │ (private)            │         │
    │      [SQL Server VM]              │         │
    │      10.50.0.32/27                │         │
    │      [NAT Gateway] ──┐             │         │
    │                     │             │         │
    └─────────────────────┼─────────────┘         │
                          │                       │
                   [Public IP]◄──────────────────┘
                   (Static)

    [Private DNS Zone: jobsite.internal]
    [Key Vault: Secrets & Certs]
    [Log Analytics: Monitoring]
```

## File Structure

```
iac/bicep/
├── core/
│   ├── main.bicep                    # VNet, subnets, VPN, DNS, KV, NAT
│   ├── parameters.bicepparam         # Parameter values
│   └── README.md                     # Detailed documentation
├── vm/
│   ├── main.bicep                    # VMSS, SQL VM, App Gateway
│   ├── parameters.bicepparam         # Parameter values
│   ├── DEPLOYMENT_GUIDE.md           # Step-by-step guide
│   ├── scripts/
│   │   └── iis-install.ps1          # IIS setup script
│   └── README.md                     # VM module docs
```

## Key Resources

### Core Infrastructure Resources

| Resource         | Type                                                  | Qty | SKU/Size         |
| ---------------- | ----------------------------------------------------- | --- | ---------------- |
| VNet             | Microsoft.Network/virtualNetworks                     | 1   | 10.50.0.0/16     |
| Subnets          | Microsoft.Network/virtualNetworks/subnets             | 8   | /27 each         |
| NAT Gateway      | Microsoft.Network/natGateways                         | 1   | Standard         |
| NAT GW Public IP | Microsoft.Network/publicIPAddresses                   | 1   | Standard         |
| VPN Gateway      | Microsoft.Network/virtualNetworkGateways              | 1   | VpnGw1           |
| VPN Public IP    | Microsoft.Network/publicIPAddresses                   | 1   | Standard         |
| Private DNS Zone | Microsoft.Network/privateDnsZones                     | 1   | jobsite.internal |
| DNS VNet Link    | Microsoft.Network/privateDnsZones/virtualNetworkLinks | 1   | -                |
| Key Vault        | Microsoft.KeyVault/vaults                             | 1   | Standard         |
| Log Analytics    | Microsoft.OperationalInsights/workspaces              | 1   | PerGB2018        |

### VM Infrastructure Resources

| Resource            | Type                                             | Qty | Details                     |
| ------------------- | ------------------------------------------------ | --- | --------------------------- |
| VMSS                | Microsoft.Compute/virtualMachineScaleSets        | 1   | WS2019, D2s_v5, 1 instance  |
| VMSS Identity       | Microsoft.ManagedIdentity/userAssignedIdentities | 1   | For Auth to Azure services  |
| SQL VM              | Microsoft.Compute/virtualMachines                | 1   | WS2019, SQL2019-Std, D2s_v5 |
| SQL VM Identity     | Microsoft.ManagedIdentity/userAssignedIdentities | 1   | For Auth to Azure services  |
| SQL Data Disk       | Microsoft.Compute/disks                          | 1   | Premium_LRS, 128GB          |
| App Gateway         | Microsoft.Network/applicationGateways            | 1   | WAF_v2, 2 instances         |
| App GW Public IP    | Microsoft.Network/publicIPAddresses              | 1   | Standard                    |
| Autoscale Settings  | Microsoft.Insights/autoscaleSettings             | 1   | Manual (disabled)           |
| Diagnostic Settings | Microsoft.Insights/diagnosticSettings            | 3   | To Log Analytics            |

## Network Subnets

| Subnet           | CIDR           | Hosts | NAT | Purpose                      |
| ---------------- | -------------- | ----- | --- | ---------------------------- |
| Frontend         | 10.50.0.0/27   | 30    | ✓   | VMSS with IIS                |
| Data             | 10.50.0.32/27  | 30    | ✓   | SQL Server VM                |
| Gateway          | 10.50.0.64/27  | 30    | ✗   | VPN Gateway                  |
| Private Endpoint | 10.50.0.96/27  | 30    | ✓   | PaaS private links           |
| GitHub Runners   | 10.50.0.128/27 | 30    | ✓   | CI/CD agents                 |
| AKS              | 10.50.0.160/27 | 30    | ✓   | Future Kubernetes            |
| Container Apps   | 10.50.0.192/27 | 30    | ✓   | Future serverless containers |
| App Gateway      | 10.50.224.0/27 | 30    | ✗   | WAF_v2                       |

## Common Commands

### Deploy Core

```bash
cd iac/bicep/core
az deployment group create \
  --resource-group jobsite-core-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam
```

### Deploy IaaS Infrastructure

```bash
cd iac/bicep/iaas
az deployment group create \
  --resource-group jobsite-iaas-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam \
    vnetId="<from-core-output>" \
    frontendSubnetId="<from-core-output>" \
    dataSubnetId="<from-core-output>" \
    logAnalyticsWorkspaceId="<from-core-output>"
```

### Get Outputs

```bash
az deployment group show \
  --resource-group jobsite-core-rg \
  --name <deployment-name> \
  --query properties.outputs
```

### Scale VMSS

```bash
az vmss scale \
  --resource-group jobsite-vm-rg \
  --name <vmss-name> \
  --new-capacity 3
```

### Update App Gateway SKU

```bash
az network application-gateway update \
  --resource-group jobsite-vm-rg \
  --name <appgw-name> \
  --set sku.capacity=4
```

## Monitoring Queries

### App Gateway Traffic

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"
| summarize count() by tostring(httpStatus_s)
```

### VMSS CPU Usage

```kusto
Perf
| where ObjectName == "Processor"
| where Computer contains "jobsite-vm"
| summarize AvgCpuPercent=avg(CounterValue) by bin(TimeGenerated, 5m), Computer
```

### VPN Connection Attempts

```kusto
AzureDiagnostics
| where ResourceType == "VIRTUALNETWORKGATEWAYS"
| where Category contains "GatewayDiagnosticLog"
```

## Cost Estimates (US East)

| Component                 | Monthly Cost    |
| ------------------------- | --------------- |
| VNet + Subnets            | $0              |
| NAT Gateway (30GB)        | ~$35            |
| VPN Gateway               | ~$35            |
| Public IPs (2x)           | ~$3             |
| VMSS (1 D2s_v5)           | ~$75            |
| SQL VM (1 D2s_v5)         | ~$75            |
| App Gateway (2 WAF_v2)    | ~$180           |
| Storage (OS + Data disks) | ~$20            |
| Key Vault                 | ~$1             |
| Private DNS Zone          | ~$1             |
| Log Analytics (5GB)       | ~$5             |
| **Total Estimate**        | **~$430/month** |

_Note: Actual costs may vary based on usage, data transfer, and region_

## Security Defaults

✓ **Enabled**

- RBAC on Key Vault
- Private DNS auto-registration
- WAF in Detection mode
- Azure Monitor Agent on VMs
- Network isolation via subnets
- NAT Gateway for outbound

⚠️ **Requires Configuration**

- Replace self-signed certificates
- Configure NSGs (if needed)
- Enable WAF Prevention mode
- Setup backup policies
- Configure Azure Defender
- Implement Azure Policy

❌ **Not Included**

- Azure Firewall
- Application Insights
- Azure DDoS Protection
- Bastion hosts (for RDP access)
- Site-to-Site VPN

## Next Steps

1. **Execute Core Deployment**: Deploy VNet, subnets, DNS, KV
2. **Capture Outputs**: Save subnet IDs, Key Vault name, etc.
3. **Execute VM Deployment**: Deploy VMSS, SQL Server, App Gateway
4. **Post-Configuration**:
   - IIS on VMSS
   - SQL Server setup
   - Private DNS records
   - Certificates
5. **Deploy Application**: Copy app binaries to VMSS
6. **Configure Monitoring**: Setup alerts and dashboards
7. **Security Hardening**: Add NSGs, enable WAF Prevention
8. **Test Failover**: Verify RTO/RPO capabilities

## Support Resources

- **Documentation**: [Core README](./core/README.md), [VM Deployment Guide](./vm/DEPLOYMENT_GUIDE.md)
- **Azure Docs**: https://docs.microsoft.com/azure/
- **Bicep Reference**: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
- **Architecture Patterns**: https://docs.microsoft.com/azure/architecture/

## Notes

- All VMs use managed identities for Azure service authentication
- Private DNS zone allows internal service discovery
- NAT Gateway provides consistent outbound IP for firewall rules
- VPN supports both certificate and Azure AD authentication
- App Gateway WAF_v2 requires 2+ instances minimum
- All resources tagged for cost tracking and organization
