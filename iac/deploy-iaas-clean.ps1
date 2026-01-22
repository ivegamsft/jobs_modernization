# Deploy IaaS Layer - Fresh deployment with WFE VM + SQL VM
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS LAYER DEPLOYMENT - WFE VM + SQL VM + APP GATEWAY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$environment = "dev"
$applicationName = "jobsite"
$location = "swedencentral"

# Wait for RG deletion to complete
Write-Host "1. Waiting for old RG deletion..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Get Core Outputs
Write-Host "2. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json
$outputs = $coreDeployment.properties.outputs

$frontendSubnetId = $outputs.frontendSubnetId.value
$dataSubnetId = $outputs.dataSubnetId.value
$githubRunnersSubnetId = $outputs.githubRunnersSubnetId.value
$keyVaultName = $outputs.keyVaultName.value

Write-Host "   ✅ Core outputs retrieved" -ForegroundColor Green
Write-Host "   Frontend Subnet: $frontendSubnetId" -ForegroundColor Gray
Write-Host "   Data Subnet: $dataSubnetId" -ForegroundColor Gray
Write-Host ""

# Deploy IaaS using subscription-level template
Write-Host "3. Deploying IaaS infrastructure..." -ForegroundColor Yellow
Write-Host "   Components: App Gateway, WFE VM, SQL VM" -ForegroundColor Gray
Write-Host ""

$deployment = az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location $location `
    --template-file "./bicep/iaas/main.bicep" `
    --parameters `
        environment=$environment `
        applicationName=$applicationName `
        location=$location `
        frontendSubnetId=$frontendSubnetId `
        dataSubnetId=$dataSubnetId `
        githubRunnersSubnetId=$githubRunnersSubnetId `
        vmSize="Standard_D2ds_v6" `
        vmssInstanceCount=0 `
        sqlVmSize="Standard_D4ds_v6" `
    -o json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ IaaS deployment succeeded" -ForegroundColor Green
    
    $deploymentJson = $deployment | ConvertFrom-Json
    Write-Host ""
    Write-Host "4. Deployment Summary:" -ForegroundColor Cyan
    Write-Host "   Resource Group: jobsite-iaas-dev-rg" -ForegroundColor Gray
    Write-Host "   Status: Succeeded" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ IAAS DEPLOYMENT COMPLETE" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resources Created:" -ForegroundColor Cyan
    Write-Host "  ✓ Application Gateway v2 (WFE network tier)" -ForegroundColor Green
    Write-Host "  ✓ WFE VM (Web Front End)" -ForegroundColor Green
    Write-Host "  ✓ SQL Server VM (Data tier)" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deployment -ForegroundColor Red
    exit 1
}
