# VM Infrastructure Module

## Overview

This module deploys compute infrastructure for the JobSite application, including:

- **VMSS (Virtual Machine Scale Set)**: Web frontend with IIS
- **SQL Server VM**: Database server
- **Application Gateway**: WAF_v2 for web traffic

## Prerequisites

This module **depends on core infrastructure** (`../core/main.bicep`). Deploy the core module first and capture its outputs.

### Required from Core Module

- VNet ID
- Frontend Subnet ID
- Data Subnet ID
- Private Endpoint Subnet ID (for future use)
- Key Vault ID and Name
- Log Analytics Workspace ID
- Private DNS Zone ID

## Architecture

```
                    Internet
                        │
              [App Gateway WAF_v2]
                        │
            ┌───────────┴───────────┐
            │                       │
        [VMSS - IIS]          [SQL Server VM]
       10.50.0.0/27           10.50.0.32/27
       1-10 instances
            │                       │
            └───────┬───────────────┘
                    │
            [NAT Gateway]
                    │
            [Static Public IP]
```

## Components

### 1. VMSS (Web Frontend)

**Configuration:**

- **Image**: Windows Server 2019 Datacenter
- **Size**: D2s_v5 (configurable)
- **Instances**: 1 (manual scale, up to 10)
- **OS Disk**: Premium_LRS managed disk
- **Network**: Frontend subnet with dynamic private IP
- **Identity**: User-assigned managed identity

**Extensions:**

- Custom Script Extension: IIS installation
- Azure Monitor Agent: Diagnostic collection

**Scaling:**

- Currently manual (infrastructure for autoscale in place)
- Can scale via Azure Portal or CLI

### 2. SQL Server VM

**Configuration:**

- **Image**: SQL Server 2019 Standard on Windows Server 2019
- **Size**: D2s_v5 (configurable)
- **OS Disk**: Premium_LRS managed disk (128GB)
- **Data Disk**: Premium_LRS managed disk (128GB)
- **Network**: Data subnet with dynamic private IP
- **Identity**: User-assigned managed identity

**SQL Configuration:**

- Connectivity: Private (port 1433)
- Auto-patching: Enabled (Sundays 2-6 AM UTC)
- SQL Management: Full control enabled
- Backup: Disabled (configure separately)

### 3. Application Gateway

**Configuration:**

- **SKU**: WAF_v2 (Web Application Firewall v2)
- **Tier**: WAF_v2
- **Capacity**: 2 instances (minimum for WAF_v2)
- **Network**: Dedicated App Gateway subnet

**Listeners:**

- HTTP (port 80) → Backend pool
- HTTPS (port 443) → Backend pool with certificate

**Features:**

- Health probes on root path
- Cookie-based affinity disabled
- WAF enabled in Detection mode
- Diagnostic logging to Log Analytics

## Deployment

### Quick Deploy

```bash
# Navigate to module
cd iac/bicep/iaas

# Deploy with parameters
az deployment group create \
  --name jobsite-iaas-deployment \
  --resource-group jobsite-iaas-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam \
    vnetId="<core-output>" \
    frontendSubnetId="<core-output>" \
    dataSubnetId="<core-output>" \
    logAnalyticsWorkspaceId="<core-output>"
```

### Parameters

**Required:**

- `vnetId`: Virtual Network ID from core module
- `frontendSubnetId`: Frontend subnet for VMSS
- `dataSubnetId`: Data subnet for SQL Server
- `logAnalyticsWorkspaceId`: Log Analytics workspace from core
- `logAnalyticsWorkspaceId`: Log Analytics workspace from core
- `privateDnsZoneId`: Private DNS zone from core module
- `sqlAdminUsername`: SQL Server admin account
- `sqlAdminPassword`: SQL Server admin password (secure)
- `vmAdminPassword`: VM administrator password (secure)

**Optional:**

- `environment`: Environment name (default: 'dev')
- `applicationName`: App name (default: 'jobsite')
- `location`: Azure region (default: 'eastus')
- `vmssInstanceCount`: Initial VMSS instances (default: 1)
- `sqlVmSize`: SQL Server VM size (default: 'Standard_D2s_v5')
- `vmssVmSize`: VMSS VM size (default: 'Standard_D2s_v5')
- `vmAdminUsername`: VM admin account (default: 'azureuser')
- `tags`: Custom tags (default: auto-generated)

## Outputs

After deployment, retrieve outputs:

```bash
az deployment group show \
  --resource-group jobsite-vm-rg \
  --name jobsite-vm-deployment \
  --query properties.outputs
```

**Available Outputs:**

- `vmssId`: VMSS resource ID
- `vmssName`: VMSS name
- `sqlVmId`: SQL Server VM resource ID
- `sqlVmName`: SQL Server VM name
- `sqlVmPrivateIp`: SQL Server private IP address
- `appGatewayId`: Application Gateway ID
- `appGatewayName`: Application Gateway name
- `appGatewayPublicIp`: Application Gateway public IP

## Post-Deployment Configuration

### 1. IIS Configuration

The VMSS runs `iis-install.ps1` which:

- Installs IIS and required features
- Enables ASP.NET 4.5 and Windows Authentication
- Creates default health check page
- Starts IIS services with auto-restart

To deploy your application:

```bash
# RDP into VMSS instance
# Or use Bastion/custom extension to upload files
# Deploy application to: C:\inetpub\wwwroot\jobsite
```

### 2. SQL Server Configuration

After VM is running:

```powershell
# Connect to VM via RDP or Bastion
# Initialize data disk
Initialize-Disk -Number 1 -PartitionStyle MBR
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel Data

# Create database
sqlcmd -S localhost -U jobsiteadmin -P "YourPassword" -Q "CREATE DATABASE jobsitedb"

# Configure backups (if needed)
# Configure login for application user
```

### 3. Update App Gateway Certificate

Replace self-signed certificate:

```bash
# Create/acquire valid certificate (PFX format)
# Convert to base64
$certContent = [Convert]::ToBase64String((Get-Content "cert.pfx" -AsByteStream))

# Update App Gateway
az network application-gateway ssl-cert update \
  --resource-group jobsite-vm-rg \
  --gateway-name <appgw-name> \
  --name appGatewaySslCert \
  --cert-file "cert.pfx" \
  --cert-password "password"
```

### 4. Add Private DNS Records

For SQL Server internal connectivity:

```bash
az network private-dns record-set a add-record \
  --resource-group jobsite-core-rg \
  --zone-name jobsite.internal \
  --record-set-name sql \
  --ipv4-address <SQL_VM_PRIVATE_IP>
```

### 5. Configure Azure Monitor

View monitoring data:

```kusto
// VMSS CPU usage
Perf
| where Computer startswith "jobsite-vm"
| where ObjectName == "Processor"
| summarize AvgCpuPercent=avg(CounterValue) by bin(TimeGenerated, 5m)

// App Gateway request status
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| summarize RequestCount=count() by tostring(httpStatus_s)
```

## Scaling

### VMSS Autoscaling

Enable autoscaling based on CPU usage:

```bash
az monitor autoscale create \
  --resource-group jobsite-vm-rg \
  --resource <vmss-name> \
  --resource-type "Microsoft.Compute/virtualMachineScaleSets" \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Add scale-up rule (CPU > 75%)
az monitor autoscale rule create \
  --resource-group jobsite-vm-rg \
  --autoscale-name <autoscale-name> \
  --condition "Percentage CPU > 75 avg 5m" \
  --scale out 1
```

### Manual VMSS Scaling

```bash
# Scale to 3 instances
az vmss scale \
  --resource-group jobsite-vm-rg \
  --name <vmss-name> \
  --new-capacity 3
```

### App Gateway Capacity

```bash
# Increase to 4 instances
az network application-gateway update \
  --resource-group jobsite-vm-rg \
  --name <appgw-name> \
  --set sku.capacity=4
```

## Monitoring

### Key Metrics to Monitor

**VMSS:**

- CPU Percentage
- Network In/Out
- Disk Read/Write
- Memory utilization (with agent)

**SQL Server:**

- CPU Percentage
- Disk I/O
- Network In/Out
- SQL connection count

**App Gateway:**

- Request count
- Response time
- Backend health status
- WAF-blocked requests

### Create Alerts

```bash
# Alert on high CPU
az monitor metrics alert create \
  --name "VMSS High CPU" \
  --resource-group jobsite-vm-rg \
  --scopes "/subscriptions/{subId}/resourceGroups/jobsite-vm-rg/providers/Microsoft.Compute/virtualMachineScaleSets/<vmss-name>" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Troubleshooting

### VMSS Health Issues

```bash
# Check VM instances
az vmss list-instances \
  --resource-group jobsite-vm-rg \
  --name <vmss-name> \
  --query "[].{id:id, vmId:vmId, powerState:powerState}"

# View extension status
az vmss extension list \
  --resource-group jobsite-vm-rg \
  --vmss-name <vmss-name>
```

### App Gateway Health

```bash
# Check backend health
az network application-gateway address-pool show \
  --resource-group jobsite-vm-rg \
  --gateway-name <appgw-name> \
  --name appGatewayBackendPool

# View access logs in Log Analytics
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"
| summarize count() by tostring(httpStatus_s), clientIP_s
```

### SQL Server Connectivity

```bash
# From VMSS instance, test SQL connectivity
sqlcmd -S <sql-vm-private-ip> -U jobsiteadmin -P "password"

# Or use private DNS name
sqlcmd -S sql.jobsite.internal -U jobsiteadmin -P "password"
```

## Security Best Practices

✅ **Implemented:**

- Managed identities for authentication
- Private network isolation
- Application Gateway WAF
- Diagnostic logging
- Premium managed disks

⚠️ **Recommended:**

- Add Network Security Groups
- Enable Azure Defender
- Configure backup policies
- Use Azure Bastion for VM access
- Implement Azure DDoS Protection
- Enable SQL Advanced Data Security

## Maintenance Schedule

### Daily

- Monitor application performance
- Review WAF blocks
- Check database health

### Weekly

- Review security alerts
- Validate backup status
- Monitor cost trends

### Monthly

- Apply Windows updates
- Review and rotate credentials
- Analyze scaling patterns
- Capacity planning review

## Cost Optimization

1. **Right-size VMs**: Monitor actual usage after deployment
2. **Reserved Instances**: For prod workloads, purchase RIs
3. **Spot Instances**: Use for dev/test VMSS
4. **Scheduled Shutdown**: Auto-shutdown for non-prod
5. **Storage Optimization**: Monitor disk utilization

## Related Documentation

- [Core Module README](../core/README.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Quick Start Reference](../QUICKSTART_VM.md)
- [Azure VMs Best Practices](https://docs.microsoft.com/azure/virtual-machines/windows/tutorial-azure-security)

## Support

For issues with:

- **Bicep syntax**: See [Bicep docs](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- **Azure VMs**: See [VM documentation](https://docs.microsoft.com/azure/virtual-machines/windows/)
- **App Gateway**: See [App Gateway docs](https://docs.microsoft.com/azure/application-gateway/)
- **SQL Server on VMs**: See [SQL on VMs](https://docs.microsoft.com/azure/azure-sql/virtual-machines/windows/)

---

**Module Version**: 1.0  
**Last Updated**: 2026-01-21  
**Status**: Production Ready
