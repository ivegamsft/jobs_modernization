targetScope = 'resourceGroup'

// ============================================================================
// IAAS Infrastructure Module - Resource Group Scope
// Deploys IaaS resources including WFE VM, SQL VM, and Application Gateway
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'swedencentral'
param frontendSubnetId string
param dataSubnetId string
param gatewaySubnetId string = ''
param adminUsername string = 'azureadmin'
@secure()
param adminPassword string = newGuid()
param vmSize string = 'Standard_D2ds_v6'
param sqlVmSize string = 'Standard_D4ds_v6'
@secure()
param appGatewayCertData string
@secure()
param appGatewayCertPassword string
param allowedRdpIps array = []
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// Deploy IAAS resources
module iaasResources './iaas-resources.bicep' = {
  name: 'iaas-resources-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    frontendSubnetId: frontendSubnetId
    dataSubnetId: dataSubnetId
    gatewaySubnetId: gatewaySubnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    sqlVmSize: sqlVmSize
    appGatewayCertData: appGatewayCertData
    appGatewayCertPassword: appGatewayCertPassword
    allowedRdpIps: allowedRdpIps
    tags: tags
  }
}

// Outputs
output wfeVmId string = iaasResources.outputs.wfeVmId
output wfeVmName string = iaasResources.outputs.wfeVmName
output wfeVmPrivateIp string = iaasResources.outputs.wfeVmPrivateIp
output sqlVmId string = iaasResources.outputs.sqlVmId
output sqlVmName string = iaasResources.outputs.sqlVmName
output sqlVmPrivateIp string = iaasResources.outputs.sqlVmPrivateIp
output appGatewayId string = iaasResources.outputs.appGatewayId
output appGatewayName string = iaasResources.outputs.appGatewayName
output appGatewayPublicIp string = iaasResources.outputs.appGatewayPublicIp
