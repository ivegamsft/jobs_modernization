targetScope = 'subscription'

// ============================================================================
// VPN Gateway Deployment - Subscription Scope Entry Point
// Deploys VPN Gateway into existing core infrastructure
// WARNING: This deployment takes 30-45 minutes to complete
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param vpnRootCertificate string = ''
param vpnClientAddressPool string = '172.16.0.0/24'
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// Reference existing resource group
var resourceGroupName = '${applicationName}-core-${environment}-rg'

resource coreResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: resourceGroupName
}

// Get existing VNet
module vnetLookup './vnet-lookup.bicep' = {
  scope: coreResourceGroup
  name: 'vnet-lookup'
  params: {
    environment: environment
    applicationName: applicationName
  }
}

// Deploy VPN Gateway
module vpnGateway './vpn-gateway.bicep' = {
  scope: coreResourceGroup
  name: 'vpn-gateway-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    vnetName: vnetLookup.outputs.vnetName
    gatewaySubnetId: vnetLookup.outputs.gatewaySubnetId
    vpnRootCertificate: vpnRootCertificate
    vpnClientAddressPool: vpnClientAddressPool
    tags: tags
  }
}

// Outputs
output vpnGatewayId string = vpnGateway.outputs.vpnGatewayId
output vpnGatewayName string = vpnGateway.outputs.vpnGatewayName
output vpnGatewayPublicIp string = vpnGateway.outputs.vpnGatewayPublicIp
