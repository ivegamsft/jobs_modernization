targetScope = 'resourceGroup'

// ============================================================================
// Core Infrastructure for VM-Based Job Site Deployment
// ============================================================================
// Deploys shared infrastructure: VNet, subnets, NAT Gateway, VPN, Private DNS,
// Key Vault, and Log Analytics

@description('Environment name (dev, staging, prod)')
param environment string

@description('Application name (no spaces)')
param applicationName string = 'jobsite'

@description('Azure location for resources')
param location string = resourceGroup().location

@description('VNet address space')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Administrator username for SQL Server')
param sqlAdminUsername string

@secure()
@description('Administrator password for SQL Server')
param sqlAdminPassword string

@description('VPN root certificate (public key in base64)')
param vpnRootCertificate string

@description('VPN client address pool (must be in a different range than VNet)')
param vpnClientAddressPool string = '10.70.0.0/24'

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  application: applicationName
  deployedDate: utcNow('u')
  deployedBy: 'Bicep'
  component: 'core'
}

// ============================================================================
// Variables
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'

// Subnet configuration - /27 subnets (32 addresses per subnet)
var subnetConfig = {
  frontend: {
    name: 'snet-fe'
    prefix: '10.50.0.0/27'
  }
  data: {
    name: 'snet-data'
    prefix: '10.50.0.32/27'
  }
  vpn: {
    name: 'GatewaySubnet' // Must be named 'GatewaySubnet'
    prefix: '10.50.0.64/27'
  }
  privateEndpoint: {
    name: 'snet-pe'
    prefix: '10.50.0.96/27'
  }
  githubRunners: {
    name: 'snet-gh-runners'
    prefix: '10.50.0.128/27'
  }
  aks: {
    name: 'snet-aks'
    prefix: '10.50.0.160/27'
  }
  containerApps: {
    name: 'snet-ca'
    prefix: '10.50.0.192/27'
  }
}

var natGatewayName = '${resourcePrefix}-nat-${uniqueSuffix}'
var publicIpNatName = '${resourcePrefix}-pip-nat-${uniqueSuffix}'
var vnetName = '${resourcePrefix}-vnet-${uniqueSuffix}'
var vpnGatewayName = '${resourcePrefix}-vpn-gw-${uniqueSuffix}'
var publicIpVpnName = '${resourcePrefix}-pip-vpn-${uniqueSuffix}'
var privateDnsZoneName = 'jobsite.internal'
var keyVaultName = '${resourcePrefix}-kv-${uniqueSuffix}'
var logAnalyticsWorkspaceName = '${resourcePrefix}-la-${uniqueSuffix}'

// ============================================================================
// Log Analytics Workspace
// ============================================================================

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

// ============================================================================
// Virtual Network & Subnets
// ============================================================================

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
        name: subnetConfig.vpn.name
        properties: {
          addressPrefix: subnetConfig.vpn.prefix
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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// ============================================================================
// NAT Gateway (for outbound connectivity from non-gateway subnets)
// ============================================================================

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

// ============================================================================
// VPN Gateway (Point-to-Site)
// ============================================================================

resource publicIpVpn 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpVpnName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGatewaySubnetRef 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: subnetConfig.vpn.name
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: vpnGatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          publicIPAddress: {
            id: publicIpVpn.id
          }
          subnet: {
            id: vpnGatewaySubnetRef.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPool
        ]
      }
      vpnClientProtocols: [
        'IkeV2'
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'Certificate'
        'AAD'
      ]
      // Use environment-specific login endpoint to avoid hardcoding public cloud URL
      aadTenant: '${az.environment().authentication.loginEndpoint}${subscription().tenantId}/'
      aadAudience: '41b23e61-6c1e-4545-b367-db180ea8d0ea'
      aadIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
      radiusServers: []
      vpnClientRootCertificates: [
        {
          name: 'RootCert'
          properties: {
            publicCertData: vpnRootCertificate
          }
        }
      ]
    }
  }
}

// ============================================================================
// Private DNS Zone
// ============================================================================

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

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

// ============================================================================
// Key Vault
// ============================================================================

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
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// ============================================================================
// Key Vault Secrets (SQL Admin Credentials)
// ============================================================================

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

// ============================================================================
// Outputs
// ============================================================================

@description('Virtual Network ID')
output vnetId string = vnet.id

@description('Virtual Network Name')
output vnetName string = vnet.name

@description('Frontend Subnet ID')
output frontendSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.frontend.name
)

@description('Data Subnet ID')
output dataSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetConfig.data.name)

@description('Private Endpoint Subnet ID')
output peSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnetConfig.privateEndpoint.name
)

@description('Key Vault ID')
output keyVaultId string = keyVault.id

@description('Key Vault Name')
output keyVaultName string = keyVault.name

@description('Private DNS Zone ID')
output privateDnsZoneId string = privateDnsZone.id

@description('Private DNS Zone Name')
output privateDnsZoneName string = privateDnsZone.name

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace Name')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('NAT Gateway Public IP Address')
output natGatewayPublicIp string = publicIpNat.properties.ipAddress

@description('VPN Gateway Public IP Address')
output vpnGatewayPublicIp string = publicIpVpn.properties.ipAddress
