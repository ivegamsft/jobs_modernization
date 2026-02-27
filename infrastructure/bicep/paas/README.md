# PaaS Application Deployment Module

This Bicep module deploys a legacy ASP.NET 2.0 Web Forms application to Azure using Platform-as-a-Service (PaaS) resources. It is designed to integrate with the **core infrastructure module** (#core) for networking, security, and monitoring.

## Overview

The PaaS module includes:

- **App Service** - Windows-based ASP.NET hosting with managed identity
- **App Service Plan** - Windows Server hosting with configurable SKU
- **SQL Database** - Azure SQL Database (PaaS) with backup policies
- **Application Insights** - Application performance monitoring
- **Key Vault Secrets** - SQL connection string and App Insights key (stored in core KV)
- **Private Endpoint** - Network isolation via private endpoint in PE subnet
- **Private DNS Record** - Internal DNS registration (jobsite.internal)
- **Diagnostics** - All resources log to core Log Analytics workspace

## Architecture

```
┌─────────────────────────────────────────┐
│        Core Infrastructure              │
│  (VNet, Subnets, KV, Log Analytics)     │
└─────────────────────────────────────────┘
           ▲              ▲
           │ Dependencies │
           │              │
    ┌──────┴──────────────┴─────────┐
    │  PaaS Module (App Service)    │
    │                               │
    │  • App Service (private link) │
    │  • SQL Database               │
    │  • App Insights               │
    │  • Key Vault Secrets          │
    │  • Private DNS Records        │
    └───────────────────────────────┘
```

## Prerequisites

Before deploying the PaaS module, you **must** have:

1. **Core Infrastructure Deployed** - Run the #core module first:

   ```bash
   cd infrastructure/bicep/core
   az deployment group create \
     --resource-group jobsite-core-rg \
     --template-file main.bicep \
     --parameters parameters.bicepparam
   ```

2. **Core Module Outputs** - Extract these from the core deployment:
   - `vnetId` - Virtual Network ID
   - `peSubnetId` - Private Endpoints subnet ID
   - `keyVaultId` - Key Vault ID
   - `keyVaultName` - Key Vault name
   - `logAnalyticsWorkspaceId` - Log Analytics Workspace ID
   - `privateDnsZoneId` - Private DNS Zone ID
   - `privateDnsZoneName` - Private DNS Zone name (default: `jobsite.internal`)

## Parameters

### Environment & Deployment

| Parameter         | Type   | Default     | Description                                   |
| ----------------- | ------ | ----------- | --------------------------------------------- |
| `environment`     | string | (required)  | Environment name: `dev`, `staging`, or `prod` |
| `applicationName` | string | `jobsite`   | Application name (no spaces)                  |
| `location`        | string | RG location | Azure region for resources                    |

### App Service Settings

| Parameter       | Type   | Default | Description                     |
| --------------- | ------ | ------- | ------------------------------- |
| `appServiceSku` | string | `S1`    | SKU: B1, B2, S1, S2, P1V2, etc. |

### SQL Database Settings

| Parameter             | Type   | Default    | Description                                |
| --------------------- | ------ | ---------- | ------------------------------------------ |
| `sqlDatabaseEdition`  | string | `Standard` | Edition: `Standard` or `Premium`           |
| `sqlServiceObjective` | string | `S1`       | Service objective: S0, S1, S2, S3, etc.    |
| `sqlAdminUsername`    | string | (required) | SQL Server administrator username          |
| `sqlAdminPassword`    | string | (required) | SQL Server administrator password (secure) |

### Core Infrastructure Integration (Required)

| Parameter                 | Type   | Description                                         |
| ------------------------- | ------ | --------------------------------------------------- |
| `vnetId`                  | string | Virtual Network ID from core module                 |
| `peSubnetId`              | string | Private Endpoint subnet ID from core module         |
| `keyVaultId`              | string | Key Vault ID from core module                       |
| `keyVaultName`            | string | Key Vault name from core module                     |
| `logAnalyticsWorkspaceId` | string | Log Analytics Workspace ID from core module         |
| `privateDnsZoneId`        | string | Private DNS Zone ID from core module                |
| `privateDnsZoneName`      | string | Private DNS Zone name (default: `jobsite.internal`) |

## Deployment

### Step 1: Update Parameters

Edit `parameters.bicepparam` with core infrastructure outputs:

```bicepparam
param environment = 'dev'
param applicationName = 'jobsite'
param location = 'eastus'

// Copy values from core module outputs
param peSubnetId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev/subnets/private-endpoints'
param keyVaultName = 'jobsite-kv-abc123'
param logAnalyticsWorkspaceId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-abc123'
param privateDnsZoneName = 'jobsite.internal'

param sqlAdminUsername = 'jobsiteadmin'
param sqlAdminPassword = 'ChangeMe@123456'  // IMPORTANT: Change this!
```

### Step 2: Deploy

```bash
cd infrastructure/bicep/paas

# Validate first
az bicep build --file main.bicep

# Deploy to resource group
az deployment group create \
  --resource-group jobsite-paas-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam
```

### Step 3: Verify Deployment

```bash
# Check resources were created
az resource list --resource-group jobsite-paas-rg --query "[].{name:name, type:type}" -o table

# Get outputs
az deployment group show \
  --resource-group jobsite-paas-rg \
  --name main \
  --query properties.outputs
```

## Resources Created

### App Service Resources

- **App Service Plan** - Windows, scalable (1 instance in dev, 2 in prod)
- **App Service** - ASP.NET 4.0 Web Forms hosting
- **App Service Configuration** - .NET Framework, connection strings, app settings
- **Managed Identity** - User-assigned for secure Azure resource access

### Database Resources

- **SQL Server** - Azure SQL Server with minimal TLS 1.2
- **SQL Database** - Standard/Premium tier with backup policies
- **Firewall Rules** - Allow Azure services and development IPs

### Monitoring Resources

- **Application Insights** - Linked to core Log Analytics workspace
- **Diagnostic Settings** - App Service and SQL Database logging

### Networking Resources

- **Private Endpoint** - App Service accessible only via private link
- **Private Endpoint NIC** - Network interface for private connection
- **DNS A Record** - Registers app service as `app.jobsite.internal`

## Key Vault Secrets

Secrets are automatically stored in the **core** Key Vault:

| Secret Name                  | Description                              |
| ---------------------------- | ---------------------------------------- |
| `paas-sql-connection-string` | SQL Database connection string           |
| `paas-appinsights-key`       | Application Insights instrumentation key |

## App Service Configuration

### Connection Strings

- **connectionstring** - SQL Azure connection (from Key Vault secret)

### App Settings

- **APPINSIGHTS_INSTRUMENTATIONKEY** - Application Insights key
- **APPLICATIONINSIGHTS_CONNECTION_STRING** - Full connection string
- **ApplicationInsightsAgent_EXTENSION_VERSION** - v3 (latest)
- **XDT_MicrosoftApplicationInsights_Mode** - recommended
- **WEBSITE_RUN_FROM_PACKAGE** - 0 (run from file system for legacy apps)
- **WEBSITE_HTTPLOGGING_RETENTION_DAYS** - 7 days retention

## Networking

### Private Access

The App Service is **not** directly accessible from the internet:

- **Public hostname** - `https://{appServiceName}.azurewebsites.net` (blocked)
- **Private hostname** - `https://app.jobsite.internal` (via private link)
- **Access via** - Application Gateway, VPN, or bastion

### DNS Resolution

Internal DNS automatically resolves:

```
app.jobsite.internal → {private-endpoint-ip}
```

## Security Best Practices

✅ **Implemented:**

- Private endpoint for App Service (no public access)
- HTTPS only (minTlsVersion: 1.2)
- Secrets stored in central Key Vault (RBAC-based)
- Managed identity for authentication
- Diagnostics to centralized Log Analytics
- SQL Server firewall rules

⚠️ **Recommended Actions:**

1. **Restrict SQL Firewall** - Change `AllowLocalDevelopment` to your IP
2. **Use RBAC** - Grant Key Vault access via managed identity
3. **Enable Advanced Threat Protection** - On SQL Server
4. **Configure WAF** - Use App Gateway in front (from #vm module)
5. **Set Alerts** - Create alerts in Log Analytics for failures

## Outputs

The module outputs:

```bicep
appServiceUrl             // Public App Service URL (for reference)
appServiceName            // App Service resource name
appServicePrivateIp       // Private endpoint IP address
sqlServerName             // SQL Server name
sqlServerFqdn             // SQL Server fully qualified domain name
sqlDatabaseName           // Database name
appInsightsName           // Application Insights name
appInsightsKey            // Instrumentation key
sqlConnectionString       // Connection string (from Key Vault)
resourceGroupName         // Resource group name
deploymentLocation        // Azure region
```

## Deployment Separation

**Important:** This module should be deployed to a **separate resource group**:

```
jobsite-core-rg     → Core infrastructure (VNet, DNS, KV, Log Analytics)
jobsite-vm-rg       → Virtual Machines (VMSS, SQL VM, App Gateway)
jobsite-paas-rg     → PaaS Services (App Service, SQL Database)
```

## Updating & Troubleshooting

### Adding Custom Domains

After deployment, add custom domains to App Service:

```bash
az webapp config hostname add \
  --resource-group jobsite-paas-rg \
  --webapp-name {appServiceName} \
  --hostname app.jobsite.com
```

### Viewing Logs

Query application logs:

```kusto
AppServiceConsoleLogs
| where TimeGenerated > ago(24h)
| project TimeGenerated, ResultDescription
| order by TimeGenerated desc
```

### Scaling

Update the SKU in parameters:

```bicepparam
param appServiceSku = 'P1V2'  // For higher performance
```

Then redeploy:

```bash
az deployment group create --resource-group jobsite-paas-rg --template-file main.bicep --parameters parameters.bicepparam
```

## Dependencies

### Deployment Order

1. **#core** module (VNet, subnets, DNS, KV, Log Analytics)
2. **#vm** module (App Gateway - optional, for WAF)
3. **#paas** module (this module)

### Integration Points

This module depends on core infrastructure:

```
┌─────────────────────┐
│  This Module (PaaS) │
├─────────────────────┤
│ Uses from #core:    │
│ • vnetId            │
│ • peSubnetId        │
│ • keyVaultName      │ → References existing resources
│ • logAnalyticsId    │   (no duplication)
│ • privateDnsZoneName│
└─────────────────────┘
```

## Cost Optimization

### Dev Environment

- App Service SKU: B1 (burstable, cost-effective)
- SQL Database: S0 (smallest standard)
- 1 App Service Plan instance
- Result: ~$50-70/month

### Prod Environment

- App Service SKU: P1V2 (premium)
- SQL Database: S3 (standard with good performance)
- 2 App Service Plan instances (high availability)
- Result: ~$300-400/month

### Estimated Total (with core + vm)

- Dev: ~$500-600/month
- Prod: ~$2000-2500/month

## Cleanup

To delete this module's resources:

```bash
az deployment group delete \
  --resource-group jobsite-paas-rg \
  --name main
```

Or delete the entire resource group:

```bash
az group delete \
  --resource-group jobsite-paas-rg \
  --yes --no-wait
```

## Support & Documentation

- [App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/sql-database/)
- [Private Link Documentation](https://docs.microsoft.com/azure/private-link/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## Related Modules

- **#core** - Core infrastructure (VNet, DNS, KV, monitoring)
- **#vm** - Virtual machine resources (VMSS, SQL VM, App Gateway)

---

**Last Updated:** 2024
**Module Version:** 1.0
**Bicep Version:** 0.25+
