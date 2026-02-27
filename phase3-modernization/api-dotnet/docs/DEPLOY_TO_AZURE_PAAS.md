# Deploying Legacy ASP.NET to Azure App Service

## Overview

This guide covers deploying the legacy ASP.NET 2.0 Web Forms application to Azure App Service (PaaS).

## Prerequisites

- Azure subscription
- Azure CLI installed
- Visual Studio 2022 or Web Deploy installed
- Legacy application code
- SQL Server database

## Architecture

```
Internet
   ↓
App Service Plan (.NET Framework)
   ↓
App Service (IIS/ASP.NET)
   ↓
Azure SQL Database
```

## Step 1: Create Azure Resources

### Option A: Using Azure Portal

1. Go to https://portal.azure.com
2. Create Resource Group
   - Name: `rg-jobsite-legacy`
   - Region: East US
3. Create App Service Plan
   - Name: `plan-jobsite-legacy`
   - OS: Windows
   - SKU: B1 (Basic) or S1 (Standard)
4. Create App Service
   - Name: `jobsite-legacy-app`
   - Runtime Stack: .NET Framework 4.8
   - Plan: Select plan created above
5. Create Azure SQL Database
   - Server: `jobsite-sqlserver`
   - Database: `JobSiteDb`
   - Username: `sqladmin`
   - Password: Generate strong password

### Option B: Using Azure CLI

```bash
# Variables
$resourceGroup = "rg-jobsite-legacy"
$location = "eastus"
$appServicePlan = "plan-jobsite-legacy"
$appService = "jobsite-legacy-app"
$sqlServer = "jobsite-sqlserver"
$sqlDatabase = "JobSiteDb"
$sqlAdmin = "sqladmin"
$sqlPassword = "P@ssw0rd123!Secure" # Change this

# Create Resource Group
az group create --name $resourceGroup --location $location

# Create App Service Plan (Windows)
az appservice plan create `
  --name $appServicePlan `
  --resource-group $resourceGroup `
  --sku B1 `
  --is-linux $false

# Create App Service
az webapp create `
  --name $appService `
  --resource-group $resourceGroup `
  --plan $appServicePlan `
  --runtime "DOTNETFRAMEWORK|v4.8"

# Create SQL Server
az sql server create `
  --name $sqlServer `
  --resource-group $resourceGroup `
  --location $location `
  --admin-user $sqlAdmin `
  --admin-password $sqlPassword

# Create SQL Database
az sql db create `
  --server $sqlServer `
  --resource-group $resourceGroup `
  --name $sqlDatabase `
  --edition Basic

# Add firewall rule for App Service
az sql server firewall-rule create `
  --server $sqlServer `
  --resource-group $resourceGroup `
  --name "AllowAppService" `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255
```

## Step 2: Update Connection String

### Update web.config

```xml
<configuration>
  <connectionStrings>
    <add name="connectionstring"
         connectionString="Server=tcp:jobsite-sqlserver.database.windows.net,1433;
                          Initial Catalog=JobSiteDb;
                          Persist Security Info=False;
                          User ID=sqladmin;
                          Password=YOUR_PASSWORD;
                          MultipleActiveResultSets=False;
                          Encrypt=True;
                          TrustServerCertificate=False;
                          Connection Timeout=30;"
         providerName="System.Data.SqlClient" />
    <add name="MyProviderConnectionString"
         connectionString="Server=tcp:jobsite-sqlserver.database.windows.net,1433;
                          Initial Catalog=JobSiteDb;
                          Persist Security Info=False;
                          User ID=sqladmin;
                          Password=YOUR_PASSWORD;
                          MultipleActiveResultSets=False;
                          Encrypt=True;
                          TrustServerCertificate=False;
                          Connection Timeout=30;"
         providerName="System.Data.SqlClient" />
  </connectionStrings>
</configuration>
```

## Step 3: Restore Database

### Option A: Using BACPAC

```bash
# Export from on-premises
# In SQL Server Management Studio:
# 1. Right-click database
# 2. Tasks > Export Data-tier Application
# 3. Save as .bacpac file

# Import to Azure
$bacpacPath = "C:\path\to\JsskDb.bacpac"
$resourceGroup = "rg-jobsite-legacy"
$sqlServer = "jobsite-sqlserver"
$sqlDatabase = "JobSiteDb"

az sql db import `
  --resource-group $resourceGroup `
  --server $sqlServer `
  --name $sqlDatabase `
  --admin-user sqladmin `
  --admin-password "YOUR_PASSWORD" `
  --file-path $bacpacPath
```

### Option B: Using SQL Scripts

```bash
# Generate script from legacy database
# In SQL Server Management Studio:
# 1. Right-click database
# 2. Tasks > Generate Scripts
# 3. Select all tables, stored procedures, etc.
# 4. Save as .sql file

# Execute script on Azure SQL
sqlcmd -S jobsite-sqlserver.database.windows.net -U sqladmin -P "YOUR_PASSWORD" -d JobSiteDb -i schema.sql
```

## Step 4: Deploy Application

### Option A: Using Visual Studio

1. Open solution in Visual Studio 2022
2. Right-click project → Publish
3. Select "Azure"
4. Select "App Service"
5. Configure:
   - Subscription
   - Resource Group: `rg-jobsite-legacy`
   - App Service: `jobsite-legacy-app`
6. Click "Publish"

### Option B: Using WebDeploy

```bash
# Publish locally first
$projectPath = "path\to\JobSite.webproj"
dotnet publish $projectPath -c Release -o publish

# Deploy using WebDeploy
$publishProfile = "jobsite-legacy-app - Web Deploy.PublishSettings"

# Download publish profile from Azure Portal
# App Service > Overview > Download publish profile

# Then deploy
& "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe" `
  -verb:sync `
  -source:contentPath="publish" `
  -dest:contentPath="D:\home\site\wwwroot",
  ComputerName="https://jobsite-legacy-app.scm.azurewebsites.net/msdeploy.axd?site=jobsite-legacy-app",
  UserName="`$jobsite-legacy-app",
  Password="YOUR_PUBLISH_PASSWORD",
  AuthType="Basic",
  EncryptPassword="False"
```

### Option C: Using Git Deployment

```bash
# Set up local Git repository
git init
git add .
git commit -m "initial commit"

# Add Azure remote
az webapp deployment source config-local-git `
  --name jobsite-legacy-app `
  --resource-group rg-jobsite-legacy

# Push to Azure
git push azure main
```

## Step 5: Configure Application Settings

### In Azure Portal:

1. Go to App Service → Configuration
2. Add Application Settings:

   ```
   Key: WEBSITE_LOAD_MODULES
   Value: AspNetCoreModule,AspNetCoreModuleV2

   Key: WEBSITE_NODE_DEFAULT_VERSION
   Value: 12.13.0

   Key: APPINSIGHTS_INSTRUMENTATIONKEY
   Value: (from Application Insights resource)
   ```

3. Add Connection Strings:
   - Name: `connectionstring`
   - Value: Your Azure SQL connection string
   - Type: SQL Server

4. Click Save

## Step 6: Enable HTTPS

```bash
# Add SSL certificate (free managed certificate)
az webapp config ssl create `
  --name jobsite-legacy-app `
  --resource-group rg-jobsite-legacy `
  --host-name jobsite-legacy-app.azurewebsites.net
```

## Step 7: Configure Logging

```bash
# Enable application logging
az webapp log config `
  --name jobsite-legacy-app `
  --resource-group rg-jobsite-legacy `
  --application-logging filesystem `
  --level verbose

# Stream logs
az webapp log tail `
  --name jobsite-legacy-app `
  --resource-group rg-jobsite-legacy
```

## Verification

1. Navigate to: `https://jobsite-legacy-app.azurewebsites.net`
2. Check application loads
3. Test login functionality
4. View logs: App Service → Log stream
5. Monitor performance: Application Insights

## Troubleshooting

### 500 Internal Server Error

```bash
# Check logs
az webapp log tail --name jobsite-legacy-app --resource-group rg-jobsite-legacy

# Check application event viewer
# In portal: Diagnose and solve problems
```

### Connection String Issues

```bash
# Verify database connectivity
# In App Service: Console
# Run: ping jobsite-sqlserver.database.windows.net

# Test SQL connection
sqlcmd -S jobsite-sqlserver.database.windows.net -U sqladmin -P "PASSWORD" -q "SELECT 1"
```

### Performance Issues

```bash
# Scale up App Service
az appservice plan update `
  --name plan-jobsite-legacy `
  --resource-group rg-jobsite-legacy `
  --sku S1
```

## Monitoring

Set up Application Insights:

```bash
# Create Application Insights
az monitor app-insights component create `
  --app jobsite-insights `
  --location eastus `
  --resource-group rg-jobsite-legacy `
  --application-type web

# Add to app settings
az webapp config appsettings set `
  --name jobsite-legacy-app `
  --resource-group rg-jobsite-legacy `
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show --app jobsite-insights --resource-group rg-jobsite-legacy --query instrumentationKey -o tsv)
```

## Cost Optimization

- Use B1 (Basic) tier for development
- Use S1 (Standard) for production
- Enable autoscaling for production loads
- Use reserved instances for long-term commitments
- Monitor costs regularly

## Next Steps

1. Test application thoroughly
2. Set up monitoring and alerts
3. Configure backup and recovery
4. Plan migration to modern architecture
5. Document runbooks and procedures
