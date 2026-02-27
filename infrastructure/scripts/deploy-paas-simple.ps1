# Simple PaaS Deployment Script
# Run this after core infrastructure is deployed

$environment = "dev"
$location = "swedencentral"
$resourceGroupName = "jobsite-paas-$environment-$location-rg"

# Get core outputs
Write-Host "Getting core infrastructure outputs..." -ForegroundColor Yellow
$coreOutputs = az deployment sub show --name "jobsite-core-dev" --query "properties.outputs" -o json | ConvertFrom-Json

$peSubnetId = $coreOutputs.peSubnetId.value
$logAnalyticsWorkspaceId = $coreOutputs.logAnalyticsWorkspaceId.value
$keyVaultName = $coreOutputs.keyVaultName.value
$coreRgName = $coreOutputs.resourceGroupName.value

Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Gray
Write-Host ""

# Get current user for SQL AAD admin
Write-Host "Getting current user for SQL admin..." -ForegroundColor Yellow
$currentUser = az ad signed-in-user show -o json | ConvertFrom-Json
$sqlAadAdminObjectId = $currentUser.id
$sqlAadAdminName = $currentUser.userPrincipalName

Write-Host "  SQL AAD Admin: $sqlAadAdminName" -ForegroundColor Green

# Store SQL admin info in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "paas-sql-aad-admin-name" --value $sqlAadAdminName --output none
az keyvault secret set --vault-name $keyVaultName --name "paas-sql-aad-admin-object-id" --value $sqlAadAdminObjectId --output none
Write-Host "  ✅ Stored SQL AAD admin info in Key Vault" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Credentials stored in Key Vault: $keyVaultName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting PaaS deployment..." -ForegroundColor Yellow

# Deploy
az deployment sub create `
    --name "jobsite-paas-$environment" `
    --location $location `
    --template-file "$PSScriptRoot\..\bicep\paas\main.bicep" `
    --parameters environment=$environment `
    --parameters location=$location `
    --parameters resourceGroupName=$resourceGroupName `
    --parameters peSubnetId=$peSubnetId `
    --parameters logAnalyticsWorkspaceId=$logAnalyticsWorkspaceId `
    --parameters coreResourceGroupName=$coreRgName `
    --parameters sqlAadAdminObjectId=$sqlAadAdminObjectId `
    --parameters sqlAadAdminName=$sqlAadAdminName
