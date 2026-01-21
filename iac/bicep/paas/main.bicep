targetScope = 'subscription'

// ============================================================================
// PaaS Infrastructure Module - Subscription Scope Entry Point
// Deploys PaaS resources including App Service, SQL Database
// ============================================================================

param environment string = 'dev'
param applicationName string = 'jobsite'
param location string = 'westus'
param appServiceSku string = 'B1'
param sqlDatabaseEdition string = 'Standard'
param sqlServiceObjective string = 'S1'
param sqlAadAdminObjectId string
param sqlAadAdminName string
param peSubnetId string
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string
param coreResourceGroupName string
param containerAppSubnetId string
param resourceGroupName string = '${applicationName}-paas-${environment}-rg'
param tags object = {
  Application: 'JobSite'
  Environment: environment
  ManagedBy: 'Bicep'
}

// Resource Group
resource paasResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy PaaS resources into the resource group
module paasResources './paas-resources.bicep' = {
  scope: paasResourceGroup
  name: 'paas-resources-deployment'
  params: {
    environment: environment
    applicationName: applicationName
    location: location
    appServiceSku: appServiceSku
    sqlDatabaseEdition: sqlDatabaseEdition
    sqlServiceObjective: sqlServiceObjective
    sqlAadAdminObjectId: sqlAadAdminObjectId
    sqlAadAdminName: sqlAadAdminName
    peSubnetId: peSubnetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    coreResourceGroupName: coreResourceGroupName
    containerAppSubnetId: containerAppSubnetId
    tags: tags
  }
}

// Outputs
output resourceGroupName string = paasResourceGroup.name
output appServiceId string = paasResources.outputs.appServiceId
output appServiceName string = paasResources.outputs.appServiceName
output appServicePlanId string = paasResources.outputs.appServicePlanId
output sqlServerId string = paasResources.outputs.sqlServerId
output sqlServerName string = paasResources.outputs.sqlServerName
output sqlDatabaseId string = paasResources.outputs.sqlDatabaseId
output sqlDatabaseName string = paasResources.outputs.sqlDatabaseName
output appInsightsId string = paasResources.outputs.appInsightsId
output appInsightsInstrumentationKey string = paasResources.outputs.appInsightsInstrumentationKey
output appServiceManagedIdentityPrincipalId string = paasResources.outputs.appServiceManagedIdentityPrincipalId
output acrId string = paasResources.outputs.acrId
output acrName string = paasResources.outputs.acrName
output acrLoginServer string = paasResources.outputs.acrLoginServer
output containerAppEnvironmentId string = paasResources.outputs.containerAppEnvironmentId
output containerAppEnvironmentName string = paasResources.outputs.containerAppEnvironmentName
