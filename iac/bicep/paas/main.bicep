targetScope = 'resourceGroup'

// ============================================================================
// PaaS Application Deployment for JobSite
// ============================================================================
// This template deploys the legacy ASP.NET 2.0 Web Forms application to Azure
// using PaaS services (App Service, SQL Database). It integrates with the
// core infrastructure module for networking, DNS, Key Vault, and monitoring.

@description('Environment name (dev, staging, prod)')
param environment string

@description('Application name (no spaces)')
param applicationName string = 'jobsite'

@description('Azure location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU (B1, B2, S1, S2, P1V2, etc.)')
param appServiceSku string = 'S1'

@description('SQL Database edition (Standard, Premium)')
param sqlDatabaseEdition string = 'Standard'

@description('SQL Database service objective (S0, S1, S2, S3, etc.)')
param sqlServiceObjective string = 'S1'

@description('Administrator username for SQL Server')
param sqlAdminUsername string

@secure()
@description('Administrator password for SQL Server')
param sqlAdminPassword string

// ============================================================================
// Core Infrastructure Parameters (Required from core module)
// ============================================================================

@description('Private Endpoint Subnet ID from core module')
param peSubnetId string

@description('Key Vault Name from core module')
param keyVaultName string

@description('Log Analytics Workspace ID from core module')
param logAnalyticsWorkspaceId string

@description('Private DNS Zone Name from core module')
param privateDnsZoneName string = 'jobsite.internal'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  application: applicationName
  deployedDate: utcNow('u')
  deployedBy: 'Bicep'
  component: 'paas'
}

// ============================================================================
// Variables
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id)
var appServiceName = '${applicationName}-app-${environment}-${uniqueSuffix}'
var appServicePlanName = '${applicationName}-asp-${environment}'
var sqlServerName = '${applicationName}-sql-${environment}-${uniqueSuffix}'
var sqlDatabaseName = '${applicationName}db'
var appInsightsName = '${applicationName}-ai-${environment}'
var privateEndpointName = '${appServiceName}-pe'
var privateEndpointNicName = '${privateEndpointName}-nic'

// ============================================================================
// Resources - Core Module References
// ============================================================================

// Reference to existing Key Vault from core module
resource coreKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Reference to existing Log Analytics Workspace from core module
resource coreLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: split(logAnalyticsWorkspaceId, '/')[8]
}

// ============================================================================
// Resources - SQL Database
// ============================================================================

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Server Firewall Rule - Allow Azure Services
resource sqlFirewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Server Firewall Rule - Allow Local Development (adjust IP as needed)
resource sqlFirewallRuleLocal 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowLocalDevelopment'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255' // IMPORTANT: Change this to specific IP in production
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: sqlServiceObjective
    tier: sqlDatabaseEdition
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 268435456000 // 250 GB
  }
}

// SQL Database Backup Policy
resource sqlDatabaseBackup 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2021-11-01' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    weeklyRetention: 'P4W' // Keep weekly backups for 4 weeks
    monthlyRetention: 'P12M' // Keep monthly backups for 12 months
    yearlyRetention: 'P0Y' // Don't keep yearly
    weekOfYear: 1
  }
}

// ============================================================================
// Resources - Application Insights
// ============================================================================

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: coreLogAnalyticsWorkspace.id
  }
}

// ============================================================================
// Resources - Key Vault Secrets
// ============================================================================

// Key Vault Secrets - SQL Connection String (stored in core KV)
resource kvSecretSqlConnection 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: coreKeyVault
  name: 'paas-sql-connection-string'
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

// Key Vault Secret - App Insights Instrumentation Key (stored in core KV)
resource kvSecretAppInsights 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: coreKeyVault
  name: 'paas-appinsights-key'
  properties: {
    value: appInsights.properties.InstrumentationKey
  }
}

// ============================================================================
// Resources - App Service Plan & Service
// ============================================================================

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServiceSku
    capacity: environment == 'prod' ? 2 : 1
  }
  kind: 'Windows'
  properties: {
    reserved: false
  }
}

// Managed Identity for App Service
resource appServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${applicationName}-identity-${environment}'
  location: location
  tags: tags
}

// App Service
resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: appServiceName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appServiceIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: true
    hostingEnvironmentProfile: null
  }
}

// App Service Configuration
resource appServiceConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: appService
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.aspx'
      'index.html'
    ]
    netFrameworkVersion: 'v4.0'
    managedPipelineMode: 'Integrated'
    webSocketsEnabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    http20Enabled: true
    remoteDebuggingEnabled: false
    detailedErrorLoggingEnabled: environment != 'prod'
    publishingUsername: appService.name
    scmType: 'None'
    use32BitWorkerProcess: false
    alwaysOn: environment == 'prod'
    connectionStrings: [
      {
        name: 'connectionstring'
        connectionString: kvSecretSqlConnection.properties.value
        type: 'SQLAzure'
      }
    ]
    appSettings: [
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: kvSecretAppInsights.properties.value
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      {
        name: 'XDT_MicrosoftApplicationInsights_Mode'
        value: 'recommended'
      }
      {
        name: 'WEBSITE_RUN_FROM_PACKAGE'
        value: '0' // For legacy .NET Framework, run from App Service file system
      }
      {
        name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
        value: '7'
      }
    ]
  }
}

// ============================================================================
// Resources - Diagnostics Settings
// ============================================================================

// App Service Diagnostics Settings
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appService.name}-diagnostics'
  scope: appService
  properties: {
    workspaceId: coreLogAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
      {
        category: 'AppServiceApplicationLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
  }
}

// SQL Database Diagnostics Settings
resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDatabase.name}-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: coreLogAnalyticsWorkspace.id
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
      {
        category: 'AutomaticTuning'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
  }
}

// ============================================================================
// Resources - Private Endpoint & DNS for App Service
// ============================================================================

// Private Endpoint Network Interface for App Service
resource appServicePeNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: privateEndpointNicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: peSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    networkSecurityGroup: null
    enableIPForwarding: false
    enableAcceleratedNetworking: false
  }
}

// Private Endpoint for App Service
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${appServiceName}-connection'
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

// Reference to private DNS zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

// DNS A record for App Service
resource appServiceDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'app'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appServicePrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('App Service URL')
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'

@description('App Service Name')
output appServiceName string = appService.name

@description('App Service Private Endpoint IP')
output appServicePrivateIp string = appServicePrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]

@description('SQL Server Name')
output sqlServerName string = sqlServer.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Database Name')
output sqlDatabaseName string = sqlDatabase.name

@description('Application Insights Name')
output appInsightsName string = appInsights.name

@description('Application Insights Instrumentation Key')
output appInsightsKey string = appInsights.properties.InstrumentationKey

@description('SQL Connection String')
output sqlConnectionString string = kvSecretSqlConnection.properties.value

@description('Resource Group Name')
output resourceGroupName string = resourceGroup().name

@description('Deployment Location')
output deploymentLocation string = location
