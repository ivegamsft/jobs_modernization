targetScope = 'resourceGroup'

// ============================================================================
// VPN Gateway Module (optional - deploy separately when needed)
// ============================================================================

param environment string
param applicationName string
param location string
param vnetName string
param gatewaySubnetId string
param vpnRootCertificate string = ''
param vpnClientAddressPool string = '172.16.0.0/24'
param tags object

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'
var vpnGatewayName = '${resourcePrefix}-vpn-gw-${uniqueSuffix}'
var publicIpVpnName = '${resourcePrefix}-pip-vpn-${uniqueSuffix}'

// VPN Public IP
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

// VPN Gateway
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
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: publicIpVpn.id
          }
        }
      }
    ]
    vpnClientConfiguration: vpnRootCertificate != ''
      ? {
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
          aadTenant: '${az.environment().authentication.loginEndpoint}${subscription().tenantId}/'
          aadAudience: '41b23e61-6c1e-4545-b367-cd1864d40eab'
          aadIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
          vpnClientRootCertificates: [
            {
              name: 'RootCert'
              properties: {
                publicCertData: vpnRootCertificate
              }
            }
          ]
        }
      : null
  }
}

// Outputs
output vpnGatewayId string = vpnGateway.id
output vpnGatewayName string = vpnGateway.name
output vpnGatewayPublicIp string = publicIpVpn.properties.ipAddress
output publicIpVpnId string = publicIpVpn.id
