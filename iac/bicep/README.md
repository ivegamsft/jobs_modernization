# Infrastructure as Code (IaC) for Legacy Job Site Application

## Overview

This folder contains **Bicep** templates for deploying the legacy ASP.NET 2.0 Web Forms Job Site application to Azure. The templates automate creation of all required infrastructure including App Service, SQL Database, Key Vault, monitoring, and networking.

## File Structure

```
iac/
├── main.bicep                    # Main template (orchestrates all resources)
├── main.dev.bicepparam          # Parameters for dev environment
├── main.staging.bicepparam      # Parameters for staging environment
├── main.prod.bicepparam         # Parameters for production environment
├── Deploy-Bicep.ps1             # PowerShell deployment script
├── deploy-bicep.sh              # Bash deployment script
└── README.md                     # This file
```

## Architecture

The Bicep template deploys the following Azure resources:

```
┌─────────────────────────────────────────────────────────┐
│               Resource Group                             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  App Service (ASP.NET 2.0 Web Forms)             │  │
│  │  - Managed Identity                              │  │
│  │  - HTTPS enforced                                │  │
│  │  - Application Insights integration              │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                      │
│  ┌────────────────▼─────────────────────────────────┐  │
│  │  App Service Plan (B2/S1/P1V2)                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  SQL Server + SQL Database                       │  │
│  │  - Encryption: TLS 1.2+                          │  │
│  │  - Firewall rules configured                     │  │
│  │  - Backup: Weekly (4 weeks), Monthly (12 months) │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Azure Key Vault                                 │  │
│  │  - SQL connection string                         │  │
│  │  - App Insights instrumentation key              │  │
│  │  - Access via Managed Identity                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Monitoring & Diagnostics                        │  │
│  │  - Log Analytics Workspace                       │  │
│  │  - Application Insights                          │  │
│  │  - Diagnostic Settings (App, SQL, KV)            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Storage Account                                 │  │
│  │  - Diagnostics logging                           │  │
│  │  - Blob storage for backups/uploads              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Environment Configurations

### Development

- **App Service**: B2 (2 cores, 3.5 GB RAM)
- **SQL Database**: Standard (S0 - 10 DTUs)
- **Cost**: ~$80-100/month
- **Purpose**: Development and testing

### Staging

- **App Service**: S1 (1 core, 1.75 GB RAM)
- **SQL Database**: Standard (S1 - 20 DTUs)
- **Cost**: ~$120-150/month
- **Purpose**: Pre-production testing

### Production

- **App Service**: P1V2 (2 cores, 3.5 GB RAM, always-on)
- **SQL Database**: Premium (P2 - 250 DTUs)
- **Cost**: ~$400-500/month
- **Purpose**: Production workloads with HA and auto-scale

## Prerequisites

### Required

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) or [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
- Azure subscription with contributor role
- Logged in to Azure (`az login` or `Connect-AzAccount`)

### Optional

- Git for version control
- Visual Studio Code with Bicep extension for editing

## Quick Start

### Option 1: PowerShell (Windows)

```powershell
# Deploy to development
./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg

# Deploy to staging
./Deploy-Bicep.ps1 -Environment staging -ResourceGroupName jobsite-staging-rg

# Deploy to production
./Deploy-Bicep.ps1 -Environment prod -ResourceGroupName jobsite-prod-rg -Location "westus2"

# Validate without deploying (WhatIf mode)
./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg -WhatIf
```

### Option 2: Bash (Linux/macOS)

```bash
# Deploy to development
./deploy-bicep.sh dev jobsite-dev-rg

# Deploy to staging
./deploy-bicep.sh staging jobsite-staging-rg eastus

# Deploy to production
./deploy-bicep.sh prod jobsite-prod-rg westus2
```

### Option 3: Azure CLI Direct

```bash
az deployment group create \
  --name jobsite-deploy-dev \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam

# Validate first
az deployment group validate \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam
```

## Parameters

Edit the relevant `main.*.bicepparam` file to customize deployment:

```bicepparam
param environment = 'dev'                    # Environment name (dev/staging/prod)
param applicationName = 'jobsite'            # Application name (used in resource names)
param location = 'eastus'                    # Azure region
param appServiceSku = 'B2'                   # App Service Plan SKU
param sqlDatabaseEdition = 'Standard'        # SQL Database Edition (Standard/Premium)
param sqlServiceObjective = 'S0'             # SQL Service Objective (S0/S1/S2/P1/P2)
param sqlAdminUsername = 'sqladmin'          # SQL admin username (⚠️ Change this!)
param sqlAdminPassword = 'ChangeMe@12345678' # SQL admin password (⚠️ Change this!)
param alertEmail = 'your-email@company.com'  # Email for alerts
```

⚠️ **IMPORTANT**: Change the SQL credentials before deploying to production!

## Resource Names

Resources are created with unique names to avoid conflicts:

```
jobsite-app-{environment}-{unique-suffix}       # App Service
jobsite-asp-{environment}                       # App Service Plan
jobsite-sql-{environment}-{unique-suffix}       # SQL Server
jobsite-kv-{environment}-{unique-suffix}        # Key Vault
jobsite-ai-{environment}                        # Application Insights
jobsitesa{environment}{unique-suffix}           # Storage Account
jobsite-law-{environment}                       # Log Analytics Workspace
```

## Security Features

✅ **Enabled**

- TLS 1.2+ for all connections
- HTTPS enforced on App Service
- SQL Server firewall rules
- Azure Key Vault for secrets management
- Managed Identity for secure credential access
- Application Insights monitoring
- Log Analytics for audit trails
- Encryption enabled on storage

⚠️ **To Configure**

- Firewall rules (update IP ranges in bicep file)
- Key Vault access policies
- Network service endpoints
- Private endpoints (for higher security)
- Azure WAF (Web Application Firewall)

## Deployment Outputs

After successful deployment, you'll receive:

- App Service URL (e.g., `https://jobsite-app-dev-xxxxx.azurewebsites.net`)
- SQL Server FQDN
- SQL Database name
- Key Vault name
- Application Insights name

## Post-Deployment Steps

### 1. Deploy Application Package

```powershell
# Create deployment package
Compress-Archive -Path C:\path\to\application\* -DestinationPath app.zip

# Deploy to App Service
az webapp deployment source config-zip `
  --resource-group jobsite-dev-rg `
  --name jobsite-app-dev-xxxxx `
  --src app.zip
```

### 2. Update web.config

After deployment, update your `web.config`:

```xml
<!-- 1. Connection string from Key Vault -->
<add name="connectionstring"
     connectionString="Server=tcp:jobsite-sql-dev-xxxxx.database.windows.net,1433;
                       Initial Catalog=jobsitedb;
                       Persist Security Info=False;
                       User ID=sqladmin;
                       Password=YourPassword;
                       Encrypt=True;
                       TrustServerCertificate=False;
                       Connection Timeout=30;" />

<!-- 2. Enable Application Insights monitoring -->
<system.webServer>
  <modules>
    <add name="ApplicationInsightsWebTracking"
         type="Microsoft.ApplicationInsights.Web.ApplicationInsightsModule, Microsoft.AI.Web" />
  </modules>
</system.webServer>

<!-- 3. Security settings -->
<compilation debug="false" targetFramework="4.8" />
<customErrors mode="RemoteOnly" defaultRedirect="error500.aspx" />
<httpRuntime targetFramework="4.8" enableVersionHeader="false" />
```

### 3. Test Connectivity

```powershell
# Test SQL connection
sqlcmd -S jobsite-sql-dev-xxxxx.database.windows.net -U sqladmin -P YourPassword -d jobsitedb -Q "SELECT 1"

# Verify App Service
$url = "https://jobsite-app-dev-xxxxx.azurewebsites.net"
Invoke-WebRequest -Uri $url -UseBasicParsing
```

### 4. Monitor Application

1. **Azure Portal**: Search for Application Insights resource
2. **View Metrics**: Check application health and performance
3. **Set Alerts**: Configure alerts for errors and performance thresholds
4. **View Logs**: Check diagnostic logs in Log Analytics

## Troubleshooting

### Deployment Fails with "Insufficient Quota"

- Check your subscription quota for the region
- Try a different region or contact Azure support

### SQL Connection Fails

- Verify firewall rules allow your IP
- Check connection string in Key Vault
- Ensure database is accessible: `az sql db show --resource-group <rg> --server <sql-server> --name jobsitedb`

### App Service Shows Error

- Check Application Insights for error details
- Review Application Logs in Log Analytics
- Enable HTTP logs: `az webapp config appsettings set --resource-group <rg> --name <app-name> --settings WEBSITE_HTTPLOGGING_RETENTION_DAYS=7`

### High Costs

- Review App Service Plan SKU (consider downsizing)
- Check SQL Database DTU usage
- Review retention policies for logs

## Cost Estimation

| Environment | App Service | SQL Database | Storage | Monitoring | **Total/Month** |
| ----------- | ----------- | ------------ | ------- | ---------- | --------------- |
| **Dev**     | $60         | $15          | $10     | $5         | **$90**         |
| **Staging** | $85         | $25          | $10     | $5         | **$125**        |
| **Prod**    | $250        | $150         | $10     | $10        | **$420**        |

_Estimates based on Azure pricing (Jan 2024). Actual costs may vary._

## Scaling

### Vertical Scaling (Change SKU)

```bash
# Change App Service Plan
az appservice plan update \
  --resource-group jobsite-prod-rg \
  --name jobsite-asp-prod \
  --sku P2V2
```

### Horizontal Scaling (Add Instances)

```bash
# For P1V2+ SKUs, enable auto-scale
az monitor autoscale create \
  --resource-group jobsite-prod-rg \
  --resource-name jobsite-asp-prod \
  --resource-type "Microsoft.Web/serverfarms" \
  --min-count 2 --max-count 10 \
  --count 2
```

### SQL Database Scaling

```bash
# Change SQL Database SKU
az sql db update \
  --resource-group jobsite-prod-rg \
  --server jobsite-sql-prod-xxxxx \
  --name jobsitedb \
  --service-objective P2
```

## Maintenance

### Backup Management

- **App Service**: Automatic backups stored in storage account
- **SQL Database**: Automated backups (daily for 7 days, weekly for 4 weeks, monthly for 12 months)
- **Manual Backup**: `az sql db export --resource-group <rg> --server <sql> --name jobsitedb --admin-login sqladmin --admin-password <pwd> --storage-key-type SharedAccessKey --storage-key <key> --storage-uri https://<storage>.blob.core.windows.net`

### Updates & Patching

- **OS**: Automatic monthly patching
- **Runtime**: Monitor notifications in Azure Portal
- **Extensions**: Application Insights extension auto-updates

### Monitoring Alerts

Configure alerts in Application Insights:

- Error rate > 5%
- Response time > 2 seconds
- Server availability < 99%
- Failed requests > 10

## Cleanup

⚠️ **Warning**: This will delete all resources and data

```bash
# Delete entire resource group
az group delete --resource-group jobsite-dev-rg --yes --no-wait

# Or delete specific resources
az resource delete --resource-group jobsite-dev-rg --ids /subscriptions/.../providers/Microsoft.Sql/servers/jobsite-sql-dev-xxxxx
```

## Support & Documentation

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure SQL Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/)
- [Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)

## License

Same as parent project

## Version History

| Version | Date       | Changes                                          |
| ------- | ---------- | ------------------------------------------------ |
| 1.0     | 2026-01-20 | Initial Bicep template for legacy app deployment |
