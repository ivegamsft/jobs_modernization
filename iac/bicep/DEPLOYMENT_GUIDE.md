# Automated Bicep Deployment - Zero Interaction Required

## Overview

This deployment infrastructure is designed for **complete automation** with **zero user interaction** required. All resource groups, passwords, and resource names are auto-generated but can be overridden with command-line parameters.

## Architecture

The deployment is organized into three subscription-scoped modules:

### 1. **Core Infrastructure** (`core/`)

- **Resource Group**: `jobsite-core-{environment}-rg`
- **Resources**:
  - Virtual Network with 7 subnets (frontend, data, vpn gateway, private endpoint, GitHub runners, AKS, container apps)
  - NAT Gateway for outbound connectivity
  - VPN Gateway (Point-to-Site with certificate auth)
  - Key Vault with RBAC authorization
  - Log Analytics Workspace
  - Private DNS Zone (`jobsite.internal`)
- **Auto-Generated**:
  - SQL admin password (can override with `-SqlAdminPassword`)
  - Unique resource names using `uniqueString()`

### 2. **IAAS Infrastructure** (`iaas/`)

- **Resource Group**: `jobsite-iaas-{environment}-rg`
- **Resources**:
  - Virtual Machine Scale Set (web/app tier)
  - SQL Server VM with SQL IaaS extension (data tier)
  - Application Gateway with SSL termination
  - Public IP for Application Gateway
- **Auto-Generated**:
  - VM admin password (can override with `-VmAdminPassword`)
  - App Gateway certificate password (can override with `-AppGatewayCertPassword`)
  - Self-signed certificates (VPN root cert, App Gateway PFX cert)

### 3. **PAAS Infrastructure** (`paas/`)

- **Resource Group**: `jobsite-paas-{environment}-rg`
- **Resources**:
  - App Service Plan (S1 by default)
  - App Service with .NET 4.8 support
  - Azure SQL Server with SQL Database
  - Private Endpoint for SQL Server
  - Application Insights (integrated with Log Analytics)
- **Auto-Generated**:
  - SQL admin password (shares with core)
  - Unique resource names

## Deployment Models

Each module uses the **subscription-scope + module pattern**:

```
main.bicep (targetScope='subscription')
  ├─ Creates resource group
  └─ Calls *-resources.bicep module
       └─ Deploys all Azure resources (targetScope='resourceGroup')
```

This pattern allows:

- ✅ Single script to create resource groups and deploy resources
- ✅ Clean separation of concerns
- ✅ Proper Bicep scope handling
- ✅ No pre-deployment steps required

## Quick Start

### Prerequisites

```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Login to Azure
az login

# (Optional) Set subscription
az account set --subscription "your-subscription-id"
```

### Deploy All Infrastructure (Default: dev environment)

```powershell
cd iac/scripts
.\Deploy-Bicep.ps1
```

This single command will:

1. Generate all passwords automatically
2. Generate self-signed certificates (VPN root, App Gateway)
3. Create all three resource groups
4. Deploy core infrastructure (VNet, VPN, Key Vault, etc.)
5. Deploy IAAS infrastructure (VMSS, SQL VM, App Gateway)
6. Deploy PAAS infrastructure (App Service, SQL Database)
7. Display all generated passwords for you to save

### Deploy Specific Environments

```powershell
# Production deployment
.\Deploy-Bicep.ps1 -Environment prod -Location westus2

# Staging deployment
.\Deploy-Bicep.ps1 -Environment staging
```

### Deploy Individual Modules

```powershell
# Deploy only core infrastructure
.\Deploy-Bicep.ps1 -SkipIaas -SkipPaas

# Deploy only IAAS (requires core)
.\Deploy-Bicep.ps1 -SkipCore -SkipPaas

# Deploy only PAAS (requires core)
.\Deploy-Bicep.ps1 -SkipCore -SkipIaas
```

### Override Auto-Generated Values

```powershell
# Use custom passwords
.\Deploy-Bicep.ps1 `
    -Environment dev `
    -SqlAdminPassword "YourSecurePassword123!" `
    -VmAdminPassword "AnotherSecurePassword456!" `
    -AppGatewayCertPassword "CertPassword789!"

# Use different subscription and location
.\Deploy-Bicep.ps1 `
    -Environment prod `
    -Location westus2 `
    -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

## Script Parameters

| Parameter                 | Required | Default        | Description                                 |
| ------------------------- | -------- | -------------- | ------------------------------------------- |
| `-Environment`            | No       | `dev`          | Deployment environment (dev, staging, prod) |
| `-Location`               | No       | `eastus`       | Azure region for all resources              |
| `-SubscriptionId`         | No       | Current        | Azure subscription ID                       |
| `-SqlAdminPassword`       | No       | Auto-generated | SQL Server admin password                   |
| `-VmAdminPassword`        | No       | Auto-generated | VM admin password                           |
| `-AppGatewayCertPassword` | No       | Auto-generated | Certificate password for App Gateway        |
| `-SkipCore`               | No       | `false`        | Skip core infrastructure deployment         |
| `-SkipIaas`               | No       | `false`        | Skip IAAS infrastructure deployment         |
| `-SkipPaas`               | No       | `false`        | Skip PAAS infrastructure deployment         |
| `-WhatIf`                 | No       | `false`        | Preview deployment without executing        |

## What Gets Auto-Generated

### Passwords

- **SQL Admin Password**: 16-character random password with letters, numbers, symbols
- **VM Admin Password**: 16-character random password with letters, numbers, symbols
- **App Gateway Cert Password**: 16-character random password

All passwords are displayed at the end of deployment and should be saved securely.

### Certificates

- **VPN Root Certificate**: Self-signed root CA for VPN client authentication
  - Subject: `CN=jobsite-vpn-root`
  - Valid: 3 years
  - Format: CER (public key only) → base64
- **App Gateway Certificate**: Self-signed SSL certificate for App Gateway
  - Subject: `CN=jobsite-appgw`
  - DNS Names: `*.jobsite.local`, `jobsite.local`
  - Valid: 3 years
  - Format: PFX (with private key) → base64

### Resource Names

All resources use the pattern: `{applicationName}-{resourceType}-{environment}-{uniqueSuffix}`

Example for `dev` environment:

- VNet: `jobsite-dev-vnet-abc123xyz`
- Key Vault: `jobsite-dev-kv-abc123xyz`
- VMSS: `jobsite-dev-vmss-abc123xyz`
- SQL VM: `jobsite-dev-sqlvm-abc123xyz`
- App Gateway: `jobsite-dev-appgw-abc123xyz`
- App Service: `jobsite-app-dev-abc123xyz`
- SQL Server: `jobsite-sql-dev-abc123xyz`

The `uniqueSuffix` is generated using `uniqueString(resourceGroup().id)` to ensure globally unique names.

## Example Output

```
═══════════════════════════════════════════════════════════════════
Job Site Application - Automated Bicep Deployment
═══════════════════════════════════════════════════════════════════
Environment: dev
Location: eastus
═══════════════════════════════════════════════════════════════════

🔑 Checking Azure authentication...
✅ Authenticated as: user@company.com
   Subscription: Production (12345678-1234-1234-1234-123456789012)

🔐 Generated SQL Admin Password (save this securely!)
   Password: x7K#mP2qL9@wR4tN

🔐 Generated VM Admin Password (save this securely!)
   Password: B5$nF8jH3&vC1xQ6

🔐 Generated App Gateway Certificate Password

📜 Generating self-signed certificates...
✅ VPN Root Certificate generated
✅ App Gateway Certificate generated

═══════════════════════════════════════════════════════════════════
DEPLOYING CORE INFRASTRUCTURE
═══════════════════════════════════════════════════════════════════

🚀 Deploying core infrastructure...
✅ Core infrastructure deployed successfully
   Resource Group: jobsite-core-dev-rg
   VNet: jobsite-dev-vnet-abc123xyz
   Key Vault: jobsite-dev-kv-abc123xyz

═══════════════════════════════════════════════════════════════════
DEPLOYING IAAS INFRASTRUCTURE
═══════════════════════════════════════════════════════════════════

🚀 Deploying IAAS infrastructure...
✅ IAAS infrastructure deployed successfully
   Resource Group: jobsite-iaas-dev-rg
   VMSS: jobsite-dev-vmss-abc123xyz
   SQL VM: jobsite-dev-sqlvm-abc123xyz
   App Gateway IP: 20.10.5.123

═══════════════════════════════════════════════════════════════════
DEPLOYING PAAS INFRASTRUCTURE
═══════════════════════════════════════════════════════════════════

🚀 Deploying PAAS infrastructure...
✅ PAAS infrastructure deployed successfully
   Resource Group: jobsite-paas-dev-rg
   App Service: jobsite-app-dev-abc123xyz
   SQL Server: jobsite-sql-dev-abc123xyz

🧹 Cleaning up temporary files...

═══════════════════════════════════════════════════════════════════
DEPLOYMENT COMPLETE!
═══════════════════════════════════════════════════════════════════

📝 SAVE THESE CREDENTIALS SECURELY:
   SQL Admin Password: x7K#mP2qL9@wR4tN
   VM Admin Password: B5$nF8jH3&vC1xQ6
   App Gateway Cert Password: Z3@pY7rT4$mL9nK2
```

## Validation

Validate Bicep templates without deploying:

```powershell
# Validate core
cd iac/bicep/core
az bicep build --file main.bicep

# Validate IAAS
cd ../iaas
az bicep build --file main.bicep

# Validate PAAS
cd ../paas
az bicep build --file main.bicep
```

## Deployment Time Estimates

- **Core Infrastructure**: ~30-45 minutes (VPN Gateway is slow to provision)
- **IAAS Infrastructure**: ~20-30 minutes (SQL VM deployment and config)
- **PAAS Infrastructure**: ~10-15 minutes

**Total end-to-end**: ~60-90 minutes for all three modules

## Troubleshooting

### Issue: "Not logged in to Azure"

```powershell
az login
```

### Issue: "Insufficient permissions"

Ensure your Azure account has:

- Contributor role on the subscription
- Key Vault Administrator role (or enable RBAC authorization)

### Issue: "VPN Gateway deployment is slow"

This is expected. VPN Gateways can take 30-45 minutes to provision. The script will wait.

### Issue: "Want to see what will be deployed without actually deploying"

```powershell
.\Deploy-Bicep.ps1 -WhatIf
```

### Issue: "Need to redeploy after failure"

The script is idempotent. Simply run it again with the same parameters. Azure will update existing resources.

## Security Considerations

### Auto-Generated Passwords

- Passwords are 16 characters with mixed case, numbers, and symbols
- Strong enough for non-production environments
- **For production**, always use custom passwords:
  ```powershell
  .\Deploy-Bicep.ps1 -Environment prod -SqlAdminPassword "..." -VmAdminPassword "..."
  ```

### Certificates

- Self-signed certificates are suitable for dev/test environments
- **For production**, use certificates from a trusted CA:
  1. Generate certificates from CA
  2. Convert to base64
  3. Pass as parameters in the Bicep templates

### Key Vault

- RBAC authorization enabled by default
- No access policies pre-configured
- Assign roles using Azure Portal or CLI after deployment

### Network Security

- NAT Gateway provides secure outbound connectivity
- VPN Gateway allows secure remote access
- Private endpoints for SQL Database
- Application Gateway with SSL termination

## Next Steps After Deployment

1. **Configure Key Vault Access**

   ```powershell
   # Grant yourself Key Vault Administrator role
   az role assignment create \
     --role "Key Vault Administrator" \
     --assignee your-email@company.com \
     --scope /subscriptions/{sub-id}/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.KeyVault/vaults/{kv-name}
   ```

2. **Configure VPN Client**
   - Download VPN client configuration from Azure Portal
   - Install root certificate on client machine
   - Connect to VPN

3. **Deploy Application Code**
   - IAAS: RDP to VMSS instances, install IIS, deploy app
   - PAAS: Use Azure CLI or Visual Studio to deploy app to App Service

4. **Configure DNS**
   - Point your domain to the Application Gateway public IP
   - Configure custom domain in App Service (for PAAS)

5. **Set Up Monitoring**
   - Configure alerts in Application Insights
   - Review metrics in Log Analytics Workspace

## Cost Optimization

To reduce costs in dev/test environments:

```powershell
# Deploy only PAAS (no expensive VMSS, SQL VM, VPN Gateway)
.\Deploy-Bicep.ps1 -SkipIaas

# Use smaller SKUs (edit main.bicep parameters)
# - App Service: B1 instead of S1
# - SQL Database: Basic instead of Standard
```

## Clean Up

To delete all resources:

```powershell
# Delete all three resource groups
az group delete --name jobsite-core-dev-rg --yes --no-wait
az group delete --name jobsite-iaas-dev-rg --yes --no-wait
az group delete --name jobsite-paas-dev-rg --yes --no-wait
```

## Support

For issues or questions:

1. Review this README
2. Check Bicep validation: `az bicep build --file main.bicep`
3. Review Azure deployment logs in Azure Portal
4. Check the GitHub repository issues

---

**Last Updated**: 2025
**Version**: 2.0 (Subscription-scoped with full automation)
