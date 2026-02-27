# Quick Start: Deploy Legacy App to Azure with Bicep

This guide gets you up and running in 5 minutes.

## 1. Verify Prerequisites (2 minutes)

```powershell
# Check Azure CLI is installed
az version

# OR check Azure PowerShell
Get-Module -Name Az

# Login to Azure if needed
az login
```

## 2. Prepare Parameters (3 minutes)

Edit the parameter file for your environment:

**For Development:**

```powershell
# Open in VS Code or notepad
code main.dev.bicepparam

# Key parameters to update:
# - sqlAdminPassword: Change to a strong password
# - alertEmail: Your email address
# - location: Your preferred Azure region (eastus, westus2, etc)
```

**For Production:**

```powershell
code main.prod.bicepparam

# Update:
# - sqlAdminPassword: STRONG password only!
# - alertEmail: Admin email
# - applicationName: Your company's app name
```

## 3. Deploy to Azure (5 minutes)

### Option A: PowerShell (Windows)

```powershell
# Development
./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg -Location eastus

# Staging
./Deploy-Bicep.ps1 -Environment staging -ResourceGroupName jobsite-staging-rg -Location eastus

# Production
./Deploy-Bicep.ps1 -Environment prod -ResourceGroupName jobsite-prod-rg -Location eastus
```

### Option B: Bash (Linux/macOS)

```bash
# Development
./deploy-bicep.sh dev jobsite-dev-rg eastus

# Staging
./deploy-bicep.sh staging jobsite-staging-rg eastus

# Production
./deploy-bicep.sh prod jobsite-prod-rg eastus
```

### Option C: Azure CLI Only

```bash
# Validate template
az deployment group validate \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam

# Deploy
az deployment group create \
  --name jobsite-deploy-dev \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam
```

## 4. Get Your Resources (1 minute)

After deployment, capture these outputs:

```bash
# Get App Service URL
az deployment group show \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  --query "properties.outputs.appServiceUrl.value" -o tsv

# Get SQL Server name
az deployment group show \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  --query "properties.outputs.sqlServerName.value" -o tsv

# Get all outputs
az deployment group show \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  --query "properties.outputs" -o table
```

## 5. Deploy Your Application (5-10 minutes)

### Step 1: Package Your Application

```powershell
# Create a ZIP of your ASP.NET application
$sourceFolder = "C:\path\to\Jobs"  # Your application folder
$zipPath = "C:\temp\app.zip"

Compress-Archive -Path "$sourceFolder\*" -DestinationPath $zipPath -Force
```

### Step 2: Update web.config

Copy your SQL connection string to web.config:

```xml
<configuration>
  <connectionStrings>
    <add name="connectionstring"
         connectionString="Server=tcp:jobsite-sql-dev-xxxxx.database.windows.net,1433;
                           Initial Catalog=jobsitedb;
                           Persist Security Info=False;
                           User ID=sqladmin;
                           Password=YourPasswordHere;
                           Encrypt=True;
                           TrustServerCertificate=False;
                           Connection Timeout=30;"
         providerName="System.Data.SqlClient" />
  </connectionStrings>

  <appSettings>
    <!-- Your other settings -->
  </appSettings>
</configuration>
```

### Step 3: Deploy to App Service

```powershell
$appServiceName = "jobsite-app-dev-xxxxx"  # Replace with your App Service name
$resourceGroup = "jobsite-dev-rg"
$zipPath = "C:\temp\app.zip"

# Deploy the application
az webapp deployment source config-zip `
  --resource-group $resourceGroup `
  --name $appServiceName `
  --src $zipPath

# Or with PowerShell Az module
Publish-AzWebApp -ResourceGroupName $resourceGroup `
                  -Name $appServiceName `
                  -ArchivePath $zipPath `
                  -Force
```

### Step 4: Verify Application

```powershell
# Get your app URL
$appUrl = az deployment group show `
  --resource-group jobsite-dev-rg `
  --name jobsite-deploy-dev `
  --query "properties.outputs.appServiceUrl.value" -o tsv

# Open in browser
start $appUrl

# Or test with curl
curl -I $appUrl
```

## 6. Common Commands

### Check Deployment Status

```bash
# View deployment details
az deployment group show \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev

# View deployment logs
az deployment operation group list \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  -o table
```

### Monitor Your Application

```bash
# View Application Insights data
az monitor app-insights component show \
  --resource-group jobsite-dev-rg \
  --app jobsite-ai-dev

# View recent errors
az monitor app-insights metrics show \
  --resource-group jobsite-dev-rg \
  --app jobsite-ai-dev \
  --metric "serverRequestsPerSecond"
```

### Manage SQL Database

```bash
# Connect to SQL Database
sqlcmd -S jobsite-sql-dev-xxxxx.database.windows.net \
       -U sqladmin \
       -P "YourPassword" \
       -d jobsitedb

# Example query
sqlcmd -S jobsite-sql-dev-xxxxx.database.windows.net \
       -U sqladmin \
       -P "YourPassword" \
       -d jobsitedb \
       -Q "SELECT @@version"
```

### View Logs

```bash
# View app service logs
az webapp log tail \
  --resource-group jobsite-dev-rg \
  --name jobsite-app-dev-xxxxx

# View SQL logs
az monitor log-analytics query \
  --workspace "jobsite-law-dev" \
  --analytics-query "AzureDiagnostics | where ResourceType == 'SERVERS'"
```

### Delete Everything (Clean Up)

⚠️ **Warning**: This deletes all resources!

```bash
# Delete the entire resource group
az group delete --name jobsite-dev-rg --yes --no-wait

# Or just the App Service
az webapp delete --resource-group jobsite-dev-rg --name jobsite-app-dev-xxxxx
```

## Troubleshooting

### Deployment Fails

```powershell
# Validate template first
az deployment group validate \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam

# Check for error details
az deployment operation group list \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  -o json | ConvertFrom-Json | Select -ExpandProperty "[].properties.statusMessage"
```

### SQL Connection Fails

```bash
# Check firewall rules
az sql server firewall-rule list \
  --resource-group jobsite-dev-rg \
  --server jobsite-sql-dev-xxxxx

# Add your IP to firewall
az sql server firewall-rule create \
  --resource-group jobsite-dev-rg \
  --server jobsite-sql-dev-xxxxx \
  --name "MyIP" \
  --start-ip-address 203.0.113.0 \
  --end-ip-address 203.0.113.255
```

### App Service Shows Error

```bash
# Enable detailed logging
az webapp config appsettings set \
  --resource-group jobsite-dev-rg \
  --name jobsite-app-dev-xxxxx \
  --settings WEBSITE_HTTPLOGGING_RETENTION_DAYS=7

# View logs
az webapp log tail \
  --resource-group jobsite-dev-rg \
  --name jobsite-app-dev-xxxxx
```

## Next Steps

1. **Review [README.md](README.md)** for detailed documentation
2. **Review [DEPLOYMENT_VALIDATION.md](DEPLOYMENT_VALIDATION.md)** for comprehensive checklist
3. **Set up monitoring** alerts in Application Insights
4. **Plan scaling** strategy for production workloads
5. **Schedule backups** and test recovery procedures

## Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [SQL Database Docs](https://learn.microsoft.com/azure/azure-sql/)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)

## Need Help?

- Check Azure Portal for resource status
- Review Application Insights for errors
- Check Log Analytics for diagnostics
- View deployment history in resource group

---

**Happy deploying! 🚀**
