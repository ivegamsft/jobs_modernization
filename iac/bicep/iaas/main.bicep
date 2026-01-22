targetScope = 'subscription'

// ============================================================================
// IAAS Infrastructure Module - Subscription Scope Entry Point
// Deploys IaaS resources including VMSS, SQL VM, and Application Gateway
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param frontendSubnetId string
param dataSubnetId string
param githubRunnersSubnetId string
param adminUsername string = 'azureadmin'
@secure()
param adminPassword string = newGuid()
param vmSize string = 'Standard_D2ds_v6'
param vmssInstanceCount int = 2
param sqlVmSize string = 'Standard_D4ds_v6'
@secure()
param appGatewayCertData string
@secure()
param appGatewayCertPassword string
param resourceGroupName string = '${applicationName}-iaas-${environment}-rg'
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// Resource Group
resource iaasResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy IAAS resources into the resource group
module iaasResources './iaas-resources.bicep' = {
  scope: iaasResourceGroup
  name: 'iaas-resources-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    frontendSubnetId: frontendSubnetId
    dataSubnetId: dataSubnetId
    githubRunnersSubnetId: githubRunnersSubnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    vmssInstanceCount: vmssInstanceCount
    sqlVmSize: sqlVmSize
    appGatewayCertData: appGatewayCertData
    appGatewayCertPassword: appGatewayCertPassword
    tags: tags
  }
}

// Outputs
output resourceGroupName string = iaasResourceGroup.name
output vmssId string = iaasResources.outputs.vmssId
output vmssName string = iaasResources.outputs.vmssName
output sqlVmId string = iaasResources.outputs.sqlVmId
output sqlVmName string = iaasResources.outputs.sqlVmName
output sqlVmPrivateIp string = iaasResources.outputs.sqlVmPrivateIp
output appGatewayId string = iaasResources.outputs.appGatewayId
output appGatewayName string = iaasResources.outputs.appGatewayName
output appGatewayPublicIp string = iaasResources.outputs.appGatewayPublicIp
