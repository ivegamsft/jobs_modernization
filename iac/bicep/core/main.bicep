targetScope = 'subscription'

// ============================================================================
// Core Infrastructure Module - Subscription Scope Entry Point
// Deploys shared infrastructure including networking, VPN, Key Vault, and
// Private DNS for the Job Site application
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param vnetAddressPrefix string = '10.50.0.0/21'
param sqlAdminUsername string = 'jobsiteadmin'
@secure()
param sqlAdminPassword string = newGuid()
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// Resource Group
var resourceGroupName = '${applicationName}-core-${environment}-rg'

resource coreResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy core resources into the resource group
module coreResources './core-resources.bicep' = {
  scope: coreResourceGroup
  name: 'core-resources-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    tags: tags
  }
}

// Outputs
output resourceGroupName string = coreResourceGroup.name
output vnetId string = coreResources.outputs.vnetId
output vnetName string = coreResources.outputs.vnetName
output frontendSubnetId string = coreResources.outputs.frontendSubnetId
output dataSubnetId string = coreResources.outputs.dataSubnetId
output peSubnetId string = coreResources.outputs.peSubnetId
output keyVaultId string = coreResources.outputs.keyVaultId
output keyVaultName string = coreResources.outputs.keyVaultName
output privateDnsZoneId string = coreResources.outputs.privateDnsZoneId
output privateDnsZoneName string = coreResources.outputs.privateDnsZoneName
output logAnalyticsWorkspaceId string = coreResources.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = coreResources.outputs.logAnalyticsWorkspaceName
output natGatewayPublicIp string = coreResources.outputs.natGatewayPublicIp
output acrId string = coreResources.outputs.acrId
output acrName string = coreResources.outputs.acrName
output acrLoginServer string = coreResources.outputs.acrLoginServer
output containerAppsEnvId string = coreResources.outputs.containerAppsEnvId
output containerAppsEnvName string = coreResources.outputs.containerAppsEnvName
output containerAppsEnvDefaultDomain string = coreResources.outputs.containerAppsEnvDefaultDomain
output containerAppsEnvStaticIp string = coreResources.outputs.containerAppsEnvStaticIp
output containerAppsSubnetId string = coreResources.outputs.containerAppsSubnetId
