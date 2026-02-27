# Redeploy IaaS with WFE VM
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "REDEPLOYING IAAS LAYER (WFE VM + SQL + App Gateway)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$environment = "dev"
$applicationName = "jobsite"
$location = "swedencentral"
$resourceGroupName = "jobsite-iaas-dev-rg"

# Get Core Outputs
Write-Host "1. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json
$outputs = $coreDeployment.properties.outputs

$frontendSubnetId = $outputs.frontendSubnetId.value
$dataSubnetId = $outputs.dataSubnetId.value
$keyVaultName = $outputs.keyVaultName.value

Write-Host "   ✅ Core outputs retrieved" -ForegroundColor Green
Write-Host ""

# Get credentials from Key Vault
Write-Host "2. Retrieving credentials from Key Vault..." -ForegroundColor Yellow
$adminPassword = az keyvault secret show --vault-name $keyVaultName --name "iaas-admin-password" --query "value" -o tsv
$certData = az keyvault secret show --vault-name $keyVaultName --name "appgw-cert-data" --query "value" -o tsv
$certPassword = az keyvault secret show --vault-name $keyVaultName --name "appgw-cert-password" --query "value" -o tsv
Write-Host "   ✅ Credentials retrieved" -ForegroundColor Green
Write-Host ""

# Deploy IaaS
Write-Host "3. Deploying IaaS resources (WFE VM)..." -ForegroundColor Yellow

$deployment = az deployment group create `
    --resource-group $resourceGroupName `
    --template-file "./bicep/iaas/iaas-resources.bicep" `
    --parameters `
        environment=$environment `
        applicationName=$applicationName `
        location=$location `
        frontendSubnetId=$frontendSubnetId `
        dataSubnetId=$dataSubnetId `
        githubRunnersSubnetId=$frontendSubnetId `
        adminPassword=$adminPassword `
        appGatewayCertData=$certData `
        appGatewayCertPassword=$certPassword `
        vmSize="Standard_D2ds_v6" `
        vmssInstanceCount=0 `
    -o json 2>&1

if ($?) {
    Write-Host "   ✅ IaaS deployment succeeded" -ForegroundColor Green
    Write-Host ""
    
    $status = az deployment group show --resource-group $resourceGroupName --name "iaas-resources-deployment" --query "properties.provisioningState" -o tsv
    Write-Host "4. Deployment Status: $status" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ IAAS REDEPLOYMENT COMPLETE - WFE VM IS READY" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deployment
    exit 1
}
