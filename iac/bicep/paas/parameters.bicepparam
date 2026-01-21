using './main.bicep'

// ============================================================================
// Environment & Deployment Settings
// ============================================================================
param environment = 'dev'
param applicationName = 'jobsite'
param location = 'eastus'

// ============================================================================
// SQL Database Settings
// ============================================================================
param sqlDatabaseEdition = 'Standard'
param sqlServiceObjective = 'S1'
param sqlAdminUsername = 'jobsiteadmin'
param sqlAdminPassword = 'ChangeMe@123456' // IMPORTANT: Change this in production!

// ============================================================================
// App Service Settings
// ============================================================================
param appServiceSku = 'S1'

// ============================================================================
// Core Infrastructure Integration (Required)
// ============================================================================
// These values should be obtained from the core module outputs
// Example: az deployment group create --template-file core/main.bicep -o table | grep -E "(vnetId|peSubnetId|keyVaultId|logAnalyticsWorkspaceId|privateDnsZoneId)"

// VNet ID from core module
// Example: /subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev
param vnetId = '/subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev'

// Private Endpoint Subnet ID from core module
// Example: /subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev/subnets/private-endpoints
param peSubnetId = '/subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-dev/subnets/private-endpoints'

// Key Vault ID from core module
// Example: /subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.KeyVault/vaults/jobsite-kv-{uniqueSuffix}
param keyVaultId = '/subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.KeyVault/vaults/jobsite-kv-{uniqueSuffix}'

// Key Vault Name from core module
// Example: jobsite-kv-a1b2c3d4e5f6
param keyVaultName = 'jobsite-kv-{uniqueSuffix}'

// Log Analytics Workspace ID from core module
// Example: /subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-{uniqueSuffix}
param logAnalyticsWorkspaceId = '/subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-{uniqueSuffix}'

// Private DNS Zone ID from core module
// Example: /subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/privateDnsZones/jobsite.internal
param privateDnsZoneId = '/subscriptions/{subscriptionId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/privateDnsZones/jobsite.internal'

// Private DNS Zone Name from core module
param privateDnsZoneName = 'jobsite.internal'
