targetScope = 'resourceGroup'

// ============================================================================
// VNet Lookup Helper Module
// Returns information about existing VNet for VPN Gateway deployment
// ============================================================================

param environment string
param applicationName string

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'
var vnetName = '${resourcePrefix}-vnet-${uniqueSuffix}'

// Reference existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output gatewaySubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'GatewaySubnet')
