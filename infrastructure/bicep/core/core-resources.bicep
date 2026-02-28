targetScope = 'resourceGroup'

// ============================================================================
// Core Resources Module (deployed within resource group)
// ============================================================================

param environment string
param applicationName string
param location string
param vnetAddressPrefix string
param sqlAdminUsername string
@secure()
param sqlAdminPassword string
param wfeAdminUsername string
@secure()
param wfeAdminPassword string
param tags object

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'

// Subnet Configuration - Production Ready Sizing
// VNet: 10.50.0.0/21 (2,048 IPs)
// Design: Follows Azure best practices with room for growth
var subnetConfig = {
  frontend: {
    name: 'snet-fe'
    prefix: '10.50.0.0/24' // App Gateway v2: 251 usable IPs (Microsoft recommendation)
  }
  data: {
    name: 'snet-data'
    prefix: '10.50.1.0/26' // SQL VMs: 59 usable IPs
  }
  githubRunners: {
    name: 'snet-gh-runners'
    prefix: '10.50.1.64/26' // Build agents VMSS: 59 usable IPs
  }
  privateEndpoint: {
    name: 'snet-pe'
    prefix: '10.50.1.128/27' // Private Endpoints: 27 usable IPs
  }
  vpnGateway: {
    name: 'GatewaySubnet'
    prefix: '10.50.1.160/27' // VPN Gateway: 27 usable IPs (Azure recommendation)
  }
  aks: {
    name: 'snet-aks'
    prefix: '10.50.2.0/23' // AKS cluster: 507 usable IPs (supports 250+ nodes)
  }
  containerApps: {
    name: 'snet-ca'
    prefix: '10.50.4.0/26' // Container Apps: 59 usable IPs (12 infra + 47 scaling)
  }
}

var natGatewayName = '${resourcePrefix}-nat-${uniqueSuffix}'
var publicIpNatName = '${resourcePrefix}-pip-nat-${uniqueSuffix}'
var vnetName = '${resourcePrefix}-vnet-${uniqueSuffix}'
var privateDnsZoneName = '${applicationName}.internal'
var locationAbbr = location == 'swedencentral' ? 'swc' : take(replace(location, ' ', ''), 3)
var keyVaultName = 'kv-${environment}-${locationAbbr}-${take(uniqueSuffix, 10)}'
var logAnalyticsWorkspaceName = '${resourcePrefix}-la-${uniqueSuffix}'
var acrName = '${applicationName}${environment}acr${uniqueSuffix}'

// Log Analytics
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

// NAT Gateway Public IP
resource publicIpNat 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpNatName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIpNat.id
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetConfig.frontend.name
        properties: {
          addressPrefix: subnetConfig.frontend.prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.data.name
        properties: {
          addressPrefix: subnetConfig.data.prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.vpnGateway.name
        properties: {
          addressPrefix: subnetConfig.vpnGateway.prefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.privateEndpoint.name
        properties: {
          addressPrefix: subnetConfig.privateEndpoint.prefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.githubRunners.name
        properties: {
          addressPrefix: subnetConfig.githubRunners.prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.aks.name
        properties: {
          addressPrefix: subnetConfig.aks.prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetConfig.containerApps.name
        properties: {
          addressPrefix: subnetConfig.containerApps.prefix
          natGateway: {
            id: natGateway.id
          }
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

// VNet Link
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-vnetlink'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enableRbacAuthorization: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Key Vault Secrets
resource sqlAdminUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-admin-username'
  properties: {
    value: sqlAdminUsername
  }
}

resource sqlAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-admin-password'
  properties: {
    value: sqlAdminPassword
  }
}

// WFE VM Admin Credentials
resource wfeAdminUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'wfe-admin-username'
  properties: {
    value: wfeAdminUsername
  }
}

resource wfeAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'wfe-admin-password'
  properties: {
    value: wfeAdminPassword
  }
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

// ACR Private Endpoint
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${acrName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetConfig.privateEndpoint.name)
    }
    privateLinkServiceConnections: [
      {
        name: '${acrName}-pe-connection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

// ACR Private DNS Zone
resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

// ACR Private DNS Zone VNet Link
resource acrPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: acrPrivateDnsZone
  name: '${acrPrivateDnsZone.name}-vnetlink'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// ACR Private Endpoint DNS Group
resource acrPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: acrPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// Note: Container Apps Environment moved to PaaS resource group
// Core only provides the subnet (snet-ca) for PaaS to use

// ============================================================================
// SRE & Testing Infrastructure
// ============================================================================

// Azure Load Testing
var loadTestingName = '${resourcePrefix}-loadtest-${uniqueSuffix}'

resource loadTesting 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: loadTestingName
  location: location
  tags: union(tags, { Purpose: 'SRE-LoadTesting' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Load testing service for ${applicationName} with Playwright support'
  }
}

// Load Testing Diagnostics
resource loadTestingDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: loadTesting
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

// Load Testing RBAC - Grant Key Vault secrets access
resource loadTestingKvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, loadTesting.id, 'kv-secrets-user')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    ) // Key Vault Secrets User
    principalId: loadTesting.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure Chaos Studio - Chaos Experiments Workspace
var chaosStudioName = '${resourcePrefix}-chaos-${uniqueSuffix}'

// Note: Chaos Studio targets are configured at the resource level (VMs, AKS, etc.)
// This creates the managed identity and RBAC for running experiments

// Chaos Studio Managed Identity
resource chaosIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${chaosStudioName}-identity'
  location: location
  tags: union(tags, { Purpose: 'SRE-ChaosEngineering' })
}

// Chaos Studio RBAC - Reader access to monitoring
resource chaosMonitoringReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, chaosIdentity.id, 'monitoring-reader')
  scope: logAnalyticsWorkspace
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
    ) // Monitoring Reader
    principalId: chaosIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Note: Subscription-level Contributor role for Chaos Studio must be assigned separately or via parent module

// SRE Monitoring - Application Insights for SRE workflows
var sreAppInsightsName = '${resourcePrefix}-sre-ai-${uniqueSuffix}'

resource sreAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: sreAppInsightsName
  location: location
  tags: union(tags, { Purpose: 'SRE-Monitoring' })
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output frontendSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.frontend.name
)
output dataSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetConfig.data.name)
output githubRunnersSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.githubRunners.name
)
output peSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.privateEndpoint.name
)
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output natGatewayPublicIp string = publicIpNat.properties.ipAddress
output natGatewayName string = natGateway.name
output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output containerAppsSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.containerApps.name
)
output loadTestingId string = loadTesting.id
output loadTestingName string = loadTesting.name
output loadTestingIdentityPrincipalId string = loadTesting.identity.principalId
output chaosIdentityId string = chaosIdentity.id
output chaosIdentityName string = chaosIdentity.name
output chaosIdentityPrincipalId string = chaosIdentity.properties.principalId
output chaosIdentityClientId string = chaosIdentity.properties.clientId
output sreAppInsightsId string = sreAppInsights.id
output sreAppInsightsName string = sreAppInsights.name
output sreAppInsightsInstrumentationKey string = sreAppInsights.properties.InstrumentationKey
output sreAppInsightsConnectionString string = sreAppInsights.properties.ConnectionString
