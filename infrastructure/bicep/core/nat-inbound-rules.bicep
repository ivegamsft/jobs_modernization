targetScope = 'resourceGroup'

// ============================================================================
// NAT Gateway Inbound Rules Module
// Deploys inbound NAT rules for RDP access to IaaS VMs
// ============================================================================

param natGatewayName string
param tags object = {}

// ============================================================================
// INBOUND NAT RULES
// ============================================================================

resource natGateway 'Microsoft.Network/natGateways@2023-11-01' existing = {
  name: natGatewayName
}

// Inbound NAT rule for Web VM RDP (port 13389 -> 3389)
resource wfeNatInboundRule 'Microsoft.Network/natGateways/inboundNatRules@2023-11-01' = {
  name: 'rdp-wfe'
  parent: natGateway
  properties: {
    frontendIPConfiguration: {
      id: '${natGateway.id}/frontendIpConfigurations/default'
    }
    backendPort: 3389
    frontendPort: 13389
    protocol: 'Tcp'
    idleTimeoutInMinutes: 4
  }
}

// Inbound NAT rule for SQL VM RDP (port 23389 -> 3389)
resource sqlNatInboundRule 'Microsoft.Network/natGateways/inboundNatRules@2023-11-01' = {
  name: 'rdp-sqlvm'
  parent: natGateway
  properties: {
    frontendIPConfiguration: {
      id: '${natGateway.id}/frontendIpConfigurations/default'
    }
    backendPort: 3389
    frontendPort: 23389
    protocol: 'Tcp'
    idleTimeoutInMinutes: 4
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output wfeInboundRuleId string = wfeNatInboundRule.id
output sqlInboundRuleId string = sqlNatInboundRule.id
