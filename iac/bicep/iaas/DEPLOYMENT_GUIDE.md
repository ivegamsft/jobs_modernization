# VM-Based Infrastructure Deployment Guide

## Overview

This Bicep deployment provides a complete infrastructure for hosting the JobSite application on Windows VMs with the following components:

### Core Infrastructure (#core)

- **Virtual Network**: 10.50.0.0/16 with /27 subnets for:
  - Frontend (VMSS)
  - Data (SQL Server)
  - VPN Gateway
  - Private Endpoints
  - GitHub Runners
  - AKS (future)
  - Container Apps (future)
  - App Gateway
- **VPN Gateway**: Point-to-Site with certificate and Azure AD authentication
- **Private DNS Zone**: `jobsite.internal` bound to VNet
- **NAT Gateway**: For outbound connectivity from compute subnets
- **Key Vault**: For storing secrets (RBAC-based)
- **Log Analytics Workspace**: For monitoring and diagnostics

### VM Infrastructure (#vm)

- **VMSS**: Windows Server 2019 with IIS (1 instance, manual scale)
- **SQL Server VM**: SQL Server 2019 Standard on Windows Server 2019
- **Application Gateway**: WAF_v2 with self-signed certificate and health probes
- **Auto-scale Settings**: Disabled by default (manual scaling)
- **Monitoring**: Diagnostic settings sending logs to Log Analytics

## Prerequisites

1. **Azure CLI**: Installed and authenticated
2. **Bicep CLI**: Version 0.26+ (included with latest Azure CLI)
3. **Certificates**:
   - VPN root certificate (base64 encoded)
   - App Gateway self-signed certificate (PFX format, base64 encoded)
4. **Azure Subscription**: With permissions to create resources

## Deployment Steps

### Step 1: Generate VPN Root Certificate

```powershell
# Generate root certificate
$params = @{
    KeyAlgorithm = 'RSA'
    KeyLength = 2048
    Subject = 'CN=JobSiteVPNRoot'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter = (Get-Date).AddYears(10)
}
$rootCert = New-SelfSignedCertificate @params

# Export certificate (public key only)
$certPath = "C:\temp\RootCertificate.cer"
Export-Certificate -Cert $rootCert -FilePath $certPath -Type CERT

# Convert to base64
$certContent = [Convert]::ToBase64String((Get-Content $certPath -AsByteStream))
Write-Host $certContent
```

### Step 2: Generate App Gateway Self-Signed Certificate

```powershell
# Generate certificate
$params = @{
    KeyAlgorithm = 'RSA'
    KeyLength = 2048
    Subject = 'CN=jobsite.internal'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter = (Get-Date).AddYears(1)
}
$cert = New-SelfSignedCertificate @params

# Export as PFX
$pfxPath = "C:\temp\AppGatewayCert.pfx"
$password = ConvertTo-SecureString -String "CertPassword123!" -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password

# Convert to base64
$pfxContent = [Convert]::ToBase64String((Get-Content $pfxPath -AsByteStream))
Write-Host $pfxContent
```

### Step 3: Create Resource Groups

```bash
# Create core infrastructure RG
az group create \
  --name jobsite-core-rg \
  --location eastus

# Create VM infrastructure RG (can be same or different)
az group create \
  --name jobsite-vm-rg \
  --location eastus
```

### Step 4: Deploy Core Infrastructure

```bash
cd iac/bicep/core

az deployment group create \
  --name jobsite-core-deployment \
  --resource-group jobsite-core-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam \
    environment=dev \
    applicationName=jobsite \
    sqlAdminUsername=jobsiteadmin \
    sqlAdminPassword='YourSecurePassword123!' \
    vpnRootCertificate='<BASE64_ENCODED_ROOT_CERT>' \
    vpnClientAddressPool='10.70.0.0/24'
```

### Step 5: Capture Core Outputs

```bash
# Store outputs for VM deployment
CORE_OUTPUTS=$(az deployment group show \
  --name jobsite-core-deployment \
  --resource-group jobsite-core-rg \
  --query properties.outputs)

echo $CORE_OUTPUTS
```

### Step 6: Deploy VM Infrastructure

```bash
cd ../vm

az deployment group create \
  --name jobsite-vm-deployment \
  --resource-group jobsite-vm-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam \
    environment=dev \
    applicationName=jobsite \
    vnetId='<FROM_CORE_OUTPUTS>' \
    frontendSubnetId='<FROM_CORE_OUTPUTS>' \
    dataSubnetId='<FROM_CORE_OUTPUTS>' \
    peSubnetId='<FROM_CORE_OUTPUTS>' \
    keyVaultId='<FROM_CORE_OUTPUTS>' \
    keyVaultName='<FROM_CORE_OUTPUTS>' \
    logAnalyticsWorkspaceId='<FROM_CORE_OUTPUTS>' \
    privateDnsZoneId='<FROM_CORE_OUTPUTS>' \
    sqlAdminUsername=jobsiteadmin \
    sqlAdminPassword='YourSecurePassword123!' \
    vmAdminPassword='VmSecurePassword123!'
```

## Network Architecture

```
Internet
    |
    v
[NAT Gateway] (10.50.224.0/27)
    |
    +---> [App Gateway WAF_v2] (10.50.224.0/27)
            |
            v
        [VMSS with IIS] (10.50.0.0/27) --NAT--> Internet
            |
            +---> [SQL Server VM] (10.50.0.32/27)

VPN Gateway (10.50.0.64/27) <--> External VPN Clients (10.70.0.0/24)
    |
    v
All subnets via Private DNS Zone (jobsite.internal)
```

## Key Configuration Details

### VMSS IIS Configuration

- Windows Server 2019 Datacenter
- Custom script extension runs IIS installation
- Azure Monitor Agent for diagnostics
- User-assigned managed identity
- Premium managed disks

### SQL Server VM

- SQL Server 2019 Standard
- Windows Server 2019
- Data disk for database files
- Auto-patching enabled (Sundays 2-6 AM UTC)
- Private network connectivity only
- Full SQL management enabled

### Application Gateway

- WAF_v2 SKU with 2 instances
- Detection mode (switch to Prevention in production)
- HTTP/HTTPS listeners
- Self-signed certificate (replace with proper cert in production)
- Health probes checking root path
- Diagnostic logging to Log Analytics

## Post-Deployment Tasks

### 1. IIS Configuration Script

Create `scripts/iis-install.ps1`:

```powershell
# Install IIS and required features
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature
Install-WindowsFeature -Name Web-Asp-Net45
Install-WindowsFeature -Name Web-Windows-Auth

# Start services
Start-Service W3SVC
Set-Service -Name W3SVC -StartupType Automatic
```

### 2. SQL Server Post-Configuration

- Initialize data disk (Format and assign drive letter)
- Create database: `jobsitedb`
- Configure backups
- Setup login for application user
- Configure firewall rules (open port 1433 to frontend subnet only)

### 3. VMSS Configuration

- Deploy application binaries
- Configure IIS application pool
- Configure web.config with connection strings
- Set up SSL bindings if using proper certificates

### 4. Private DNS Records

Add A records in `jobsite.internal` for:

- `sql.jobsite.internal` → SQL VM private IP (10.50.0.x)
- `app.jobsite.internal` → App Gateway private IP

### 5. Application Gateway Certificate

- Replace self-signed certificate with valid certificate in production
- Update HTTPS listener settings
- Configure certificate-based health probes if needed

## Monitoring & Diagnostics

All resources send metrics/logs to Log Analytics workspace. Monitor:

```kusto
// App Gateway access logs
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"

// VM performance metrics
Perf
| where ObjectName == "Processor" or ObjectName == "Memory"
| summarize AvgCpuPercent=avg(CounterValue) by Computer

// SQL VM metrics
AzureDiagnostics
| where ResourceType == "VIRTUALMACHINES"
| where Category == "ApplicationGatewayAccessLog"
```

## Scaling

### VMSS Scaling

Currently set to manual (1 instance). To enable autoscaling:

1. Update `parameters.bicepparam` with autoscale rules
2. Or manually update VMSS capacity via Azure Portal/CLI:
   ```bash
   az vmss scale --name <vmss-name> --resource-group <rg> --new-capacity 3
   ```

### App Gateway Scaling

Currently 2 instances with WAF_v2. Adjust capacity:

```bash
az network application-gateway update \
  --name <appgw-name> \
  --resource-group <rg> \
  --set sku.capacity=4
```

## Security Considerations

1. **Replace self-signed certificates** with proper certificates in production
2. **Enable WAF prevention mode** after testing
3. **Restrict network access** - add NSGs as needed
4. **Use Azure Policy** to enforce standards
5. **Implement Azure Backup** for VMs
6. **Enable Azure Defender** for comprehensive security
7. **Rotate secrets** stored in Key Vault regularly

## Troubleshooting

### VMSS Health Check Failing

- Verify IIS is running on instances
- Check health probe path matches application routes
- Review Application Gateway access logs

### SQL Connectivity Issues

- Verify SQL Server firewall allows port 1433 from frontend subnet
- Check private DNS resolution of SQL hostname
- Verify SQL authentication credentials

### VPN Connection Issues

- Verify VPN client certificate is installed
- Check VPN Gateway status in portal
- Review VPN Gateway diagnostics logs

## Cost Optimization

1. **Use reserved instances** for predictable workloads
2. **Right-size VMs** after performance testing
3. **Use managed disks** for cost efficiency (already enabled)
4. **Configure auto-shutdown** for non-production VMs
5. **Use spot instances** for dev/test (modify VMSS priority)
6. **Monitor costs** with Azure Cost Management

## Maintenance

### Monthly Tasks

- Review security updates in Azure Security Center
- Check App Gateway WAF rules for false positives
- Validate backup status
- Review Log Analytics retention policies

### Quarterly Tasks

- Performance baseline review
- Capacity planning assessment
- Disaster recovery drill
- Security compliance audit

## Support & Documentation

- [Azure Virtual Machines docs](https://docs.microsoft.com/azure/virtual-machines/)
- [Azure App Gateway docs](https://docs.microsoft.com/azure/application-gateway/)
- [SQL Server on Azure VMs](https://docs.microsoft.com/azure/azure-sql/virtual-machines/)
- [Bicep documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
