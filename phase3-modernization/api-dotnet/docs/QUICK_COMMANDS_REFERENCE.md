# Quick Commands Reference

## Azure Login & Setup

```powershell
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "SubscriptionId"

# Show current context
az account show
```

## Resource Group Operations

```powershell
# Create resource group
az group create --name rg-jobsite --location eastus

# List resource groups
az group list --output table

# Delete resource group (deletes all resources)
az group delete --name rg-jobsite --yes
```

## App Service (PaaS) Commands

```powershell
# Create App Service Plan
az appservice plan create --name plan-jobsite --resource-group rg-jobsite --sku B1 --is-linux false

# Create App Service
az webapp create --name jobsite-app --resource-group rg-jobsite --plan plan-jobsite --runtime "DOTNETFRAMEWORK|v4.8"

# Start/Stop App Service
az webapp start --name jobsite-app --resource-group rg-jobsite
az webapp stop --name jobsite-app --resource-group rg-jobsite

# Restart App Service
az webapp restart --name jobsite-app --resource-group rg-jobsite

# Get App Service URL
az webapp show --name jobsite-app --resource-group rg-jobsite --query defaultHostName -o tsv

# Configure connection string
az webapp config connection-string set --name jobsite-app --resource-group rg-jobsite --settings connectionstring="YOUR_CONNECTION_STRING" --connection-string-type SQLServer

# View app settings
az webapp config appsettings list --name jobsite-app --resource-group rg-jobsite

# Deploy with ZIP
az webapp deployment source config-zip --resource-group rg-jobsite --name jobsite-app --src app.zip

# Stream logs
az webapp log tail --name jobsite-app --resource-group rg-jobsite

# Enable application logging
az webapp log config --name jobsite-app --resource-group rg-jobsite --application-logging filesystem --level verbose
```

## Virtual Machine (IaaS) Commands

```powershell
# Create VM
az vm create --name vm-jobsite --resource-group rg-jobsite --image "MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest" --size Standard_B2s --admin-username azureuser --admin-password "PASSWORD"

# Start/Stop VM
az vm start --name vm-jobsite --resource-group rg-jobsite
az vm stop --name vm-jobsite --resource-group rg-jobsite

# Deallocate VM (to save costs when not in use)
az vm deallocate --name vm-jobsite --resource-group rg-jobsite

# Delete VM
az vm delete --name vm-jobsite --resource-group rg-jobsite --yes

# Get public IP
az vm list-ip-addresses --resource-group rg-jobsite --name vm-jobsite --query [0].virtualMachines[0].ipAddresses[0].ipAddress -o tsv

# Open ports
az vm open-port --resource-group rg-jobsite --name vm-jobsite --port 80
az vm open-port --resource-group rg-jobsite --name vm-jobsite --port 443
az vm open-port --resource-group rg-jobsite --name vm-jobsite --port 3389

# Run command on VM
az vm run-command invoke --resource-group rg-jobsite --name vm-jobsite --command-id RunPowerShellScript --scripts "Get-Service"

# Connect via SSH (Linux)
ssh azureuser@<public-ip>

# RDP to Windows VM
mstsc /v:<public-ip>
```

## SQL Database (PaaS) Commands

```powershell
# Create SQL Server
az sql server create --name jobsite-sql --resource-group rg-jobsite --location eastus --admin-user sqladmin --admin-password "PASSWORD"

# Create SQL Database
az sql db create --server jobsite-sql --resource-group rg-jobsite --name JobSiteDb --edition Basic

# Get connection string
az sql db show-connection-string --client ado.net --server jobsite-sql --name JobSiteDb

# Configure firewall rule
az sql server firewall-rule create --server jobsite-sql --resource-group rg-jobsite --name "AllowAppService" --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255

# Import BACPAC
az sql db import --resource-group rg-jobsite --server jobsite-sql --name JobSiteDb --admin-user sqladmin --admin-password "PASSWORD" --file-path database.bacpac

# Export to BACPAC
az sql db export --resource-group rg-jobsite --server jobsite-sql --name JobSiteDb --admin-user sqladmin --admin-password "PASSWORD" --blob-uri "https://yourstorageaccount.blob.core.windows.net/exports/database.bacpac"

# Delete database
az sql db delete --server jobsite-sql --resource-group rg-jobsite --name JobSiteDb --yes

# Scale database
az sql db update --server jobsite-sql --resource-group rg-jobsite --name JobSiteDb --edition Standard --capacity 10
```

## Storage Account Commands

```powershell
# Create storage account
az storage account create --name sajobsite --resource-group rg-jobsite --location eastus --sku Standard_LRS

# List storage accounts
az storage account list --resource-group rg-jobsite --output table

# Get storage account connection string
az storage account show-connection-string --name sajobsite --resource-group rg-jobsite

# Create blob container
az storage container create --account-name sajobsite --name uploads

# Upload file
az storage blob upload --account-name sajobsite --container-name uploads --name "file.zip" --file "local-path/file.zip"

# Delete storage account
az storage account delete --name sajobsite --resource-group rg-jobsite --yes
```

## Key Vault Commands

```powershell
# Create Key Vault
az keyvault create --name kv-jobsite --resource-group rg-jobsite --location eastus

# Store secret
az keyvault secret set --vault-name kv-jobsite --name "DbPassword" --value "YourPassword"

# Get secret
az keyvault secret show --vault-name kv-jobsite --name "DbPassword" --query value -o tsv

# List secrets
az keyvault secret list --vault-name kv-jobsite --output table

# Delete secret
az keyvault secret delete --vault-name kv-jobsite --name "DbPassword"
```

## Monitoring & Diagnostics

```powershell
# Create Application Insights
az monitor app-insights component create --app jobsite-insights --location eastus --resource-group rg-jobsite --application-type web

# Get instrumentation key
az monitor app-insights component show --app jobsite-insights --resource-group rg-jobsite --query instrumentationKey -o tsv

# View metrics
az monitor metrics list-definitions --resource /subscriptions/{subscriptionId}/resourceGroups/rg-jobsite/providers/microsoft.web/sites/jobsite-app

# Create alert rule
az monitor metrics alert create --name HighCpuAlert --resource-group rg-jobsite --scopes /subscriptions/{subscriptionId}/resourceGroups/rg-jobsite/providers/microsoft.web/sites/jobsite-app --condition "avg Percentage CPU > 80" --window-size 5m --evaluation-frequency 1m
```

## Networking Commands

```powershell
# Create virtual network
az network vnet create --name vnet-jobsite --resource-group rg-jobsite --address-prefix 10.0.0.0/16

# Create subnet
az network vnet subnet create --name subnet-app --resource-group rg-jobsite --vnet-name vnet-jobsite --address-prefix 10.0.1.0/24

# Create NSG
az network nsg create --name nsg-jobsite --resource-group rg-jobsite --location eastus

# Add NSG rule
az network nsg rule create --nsg-name nsg-jobsite --resource-group rg-jobsite --name AllowHTTP --priority 200 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80

# Associate NSG with subnet
az network vnet subnet update --name subnet-app --resource-group rg-jobsite --vnet-name vnet-jobsite --network-security-group nsg-jobsite
```

## Deployment Commands

```powershell
# Deploy using ZIP file
az webapp deployment source config-zip --resource-group rg-jobsite --name jobsite-app --src app.zip

# Deploy using Git
az webapp deployment source config-local-git --name jobsite-app --resource-group rg-jobsite

# Get deployment status
az webapp deployment slot list --name jobsite-app --resource-group rg-jobsite

# Create deployment slot (for staging)
az webapp deployment slot create --name jobsite-app --resource-group rg-jobsite --slot staging

# Swap slots
az webapp deployment slot swap --name jobsite-app --resource-group rg-jobsite --slot staging
```

## Cost Optimization

```powershell
# Show costs by resource
az cost management forecast --timeframe MonthToDate --resource-group rg-jobsite

# List all resources and their costs
az resource list --resource-group rg-jobsite --query "[].{Name:name, Type:type}" --output table

# Check spending
az account show-spend --subscription "SubscriptionId"
```

## Troubleshooting

```powershell
# Check App Service logs
az webapp log download --name jobsite-app --resource-group rg-jobsite --log-file app.zip

# Verify connectivity to SQL
$sqlServer = "jobsite-sql.database.windows.net"
$port = 1433
Test-NetConnection -ComputerName $sqlServer -Port $port

# Check service health
az monitor service-health

# List recent operations
az monitor activity-log list --resource-group rg-jobsite --max-records 10 --output table
```

## Clean Up

```powershell
# Delete specific resource
az resource delete --ids "/subscriptions/{subscriptionId}/resourceGroups/rg-jobsite/providers/Microsoft.Web/sites/jobsite-app"

# Delete entire resource group
az group delete --name rg-jobsite --yes --no-wait

# List all resources to verify deletion
az resource list --resource-group rg-jobsite
```

## Useful Aliases

Add to PowerShell profile:

```powershell
Set-Alias -Name azg -Value "az group"
Set-Alias -Name azw -Value "az webapp"
Set-Alias -Name azs -Value "az sql"
Set-Alias -Name azv -Value "az vm"
Set-Alias -Name azk -Value "az keyvault"
```
