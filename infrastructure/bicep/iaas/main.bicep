targetScope = 'subscription'

// ============================================================================
// IAAS Infrastructure Module - Subscription Scope Entry Point
// Deploys Resource Group and Web (WFE) + SQL VMs with networking
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param coreResourceGroupName string = 'jobsite-core-dev-rg'
param resourceGroupName string = '${applicationName}-iaas-${environment}-rg'
param adminUsername string = 'azureadmin'
@secure()
param adminPassword string = newGuid()
param vmSize string = 'Standard_D2ds_v6'
param sqlVmSize string = 'Standard_D4ds_v6'
param allowedRdpIps array = []
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// ============================================================================
// RESOURCE GROUP DEFINITION
// ============================================================================

resource iaasResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ============================================================================
// REFERENCE EXISTING CORE RESOURCES
// ============================================================================

resource coreResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: coreResourceGroupName
}

// Get reference to the VNet from core RG
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: 'jobsite-dev-vnet-ubzfsgu4p5eli'
  scope: coreResourceGroup
}

// Get frontend subnet
resource frontendSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'snet-fe'
  parent: vnet
}

// Get data subnet
resource dataSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'snet-data'
  parent: vnet
}

// ============================================================================
// DEPLOY IAAS RESOURCES TO NEW RG
// ============================================================================

module iaasResources './iaas-resources.bicep' = {
  name: 'iaas-resources-deployment'
  scope: iaasResourceGroup
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    frontendSubnetId: frontendSubnet.id
    dataSubnetId: dataSubnet.id
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    sqlVmSize: sqlVmSize
    allowedRdpIps: allowedRdpIps
    tags: tags
    appInsightsInstrumentationKey: ''
    appInsightsConnectionString: ''
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupId string = iaasResourceGroup.id
output resourceGroupName string = iaasResourceGroup.name

output wfeVmId string = iaasResources.outputs.wfeVmId
output wfeVmName string = iaasResources.outputs.wfeVmName
output wfeVmPrivateIp string = iaasResources.outputs.wfeVmPrivateIp

output sqlVmId string = iaasResources.outputs.sqlVmId
output sqlVmName string = iaasResources.outputs.sqlVmName
output sqlVmPrivateIp string = iaasResources.outputs.sqlVmPrivateIp
