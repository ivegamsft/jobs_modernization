targetScope = 'subscription'

// ============================================================================
// AGENTS Infrastructure Module - Subscription Scope Entry Point
// Deploys GitHub Runners VMSS and supporting infrastructure
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param coreResourceGroupName string = 'jobsite-core-dev-rg'
param resourceGroupName string = '${applicationName}-agents-${environment}-rg'
param adminUsername string = 'azureadmin'
@secure()
param adminPassword string = newGuid()
param agentVmSize string = 'Standard_D2ds_v6'
param vmssInstanceCount int = 2
param coreVnetName string
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
  Layer: 'Agents'
}

// ============================================================================
// RESOURCE GROUP DEFINITION
// ============================================================================

resource agentsResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
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
  name: coreVnetName
  scope: coreResourceGroup
}

// Get GitHub runners subnet
resource githubRunnersSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'snet-github-runners'
  parent: vnet
}

// ============================================================================
// DEPLOY AGENTS RESOURCES
// ============================================================================

// Deploy agents resources
module agentsResources './agents-resources.bicep' = {
  scope: agentsResourceGroup
  name: 'agents-resources-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    githubRunnersSubnetId: githubRunnersSubnet.id
    adminUsername: adminUsername
    adminPassword: adminPassword
    agentVmSize: agentVmSize
    vmssInstanceCount: vmssInstanceCount
    tags: tags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

// Outputs
output agentsResourceGroupId string = agentsResourceGroup.id
output agentsResourceGroupName string = agentsResourceGroup.name
output vmssId string = agentsResources.outputs.vmssId
output vmssName string = agentsResources.outputs.vmssName
