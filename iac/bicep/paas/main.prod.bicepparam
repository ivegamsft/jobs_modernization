using './main.bicep'

param environment = 'prod'
param applicationName = 'jobsite'
param location = 'eastus'
param appServiceSku = 'P1V2'
param sqlDatabaseEdition = 'Premium'
param sqlServiceObjective = 'P2'
param sqlAdminUsername = 'sqladmin'
param sqlAdminPassword = 'ChangeMe@ProdPassword!' // ⚠️ Change this! Use Key Vault in real deployment
param peSubnetId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-prod/subnets/snet-pe'
param keyVaultName = 'jobsite-kv-prod'
param logAnalyticsWorkspaceId = '/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-prod'
param privateDnsZoneName = 'jobsite.internal'
