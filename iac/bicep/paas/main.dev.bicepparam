using './main.bicep'

param environment = 'dev'
param applicationName = 'jobsite'
param location = 'eastus'
param appServiceSku = 'B2'
param sqlDatabaseEdition = 'Standard'
param sqlServiceObjective = 'S0'
param sqlAdminUsername = 'sqladmin'
param sqlAdminPassword = 'ChangeMe@12345678!' // ⚠️ Change this! Use Key Vault in real deployment
param peSubnetId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev/subnets/snet-pe'
param keyVaultName = 'jobsite-kv-dev'
param logAnalyticsWorkspaceId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-dev'
param privateDnsZoneName = 'jobsite.internal'
