# Update Core Infrastructure - Add ACR & Container Apps Environment
# This updates the existing core deployment with new container resources

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "UPDATE CORE INFRASTRUCTURE" -ForegroundColor Cyan
Write-Host "Adding: ACR + Container Apps Environment" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get current core deployment to reuse parameters
Write-Host "Getting existing core deployment parameters..." -ForegroundColor Yellow
$existingDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json

if (-not $existingDeployment) {
    Write-Host "❌ Core deployment not found. Deploy core first." -ForegroundColor Red
    exit 1
}

$params = $existingDeployment.properties.parameters
$environment = $params.environment.value
$location = $params.location.value
$sqlAdminUsername = $params.sqlAdminUsername.value

# Get SQL password from Key Vault
Write-Host "Retrieving SQL password from Key Vault..." -ForegroundColor Yellow
$outputs = $existingDeployment.properties.outputs
$kvName = $outputs.keyVaultName.value
$sqlPassword = az keyvault secret show --vault-name $kvName --name "sql-admin-password" --query value -o tsv

Write-Host "   ✅ Parameters retrieved" -ForegroundColor Green
Write-Host ""

# Deploy updated core infrastructure
Write-Host "Deploying updated core infrastructure..." -ForegroundColor Yellow
Write-Host "New resources:" -ForegroundColor Cyan
Write-Host "  - Azure Container Registry (Premium, Private)" -ForegroundColor White
Write-Host "  - ACR Private Endpoint + Private DNS" -ForegroundColor White
Write-Host "  - Container Apps Environment (VNet-integrated)" -ForegroundColor White
Write-Host "  - Log Analytics integration" -ForegroundColor White
Write-Host ""

az deployment sub create `
    --name "jobsite-core-dev" `
    --location $location `
    --template-file "$PSScriptRoot\..\bicep\core\main.bicep" `
    --parameters environment=$environment `
    --parameters location=$location `
    --parameters sqlAdminUsername=$sqlAdminUsername `
    --parameters sqlAdminPassword=$sqlPassword

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Core infrastructure updated successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Get new outputs
    $updatedDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json
    $newOutputs = $updatedDeployment.properties.outputs
    
    Write-Host "New Resources Created:" -ForegroundColor Cyan
    Write-Host "  ACR Name: $($newOutputs.acrName.value)" -ForegroundColor White
    Write-Host "  ACR Login Server: $($newOutputs.acrLoginServer.value)" -ForegroundColor White
    Write-Host "  Container Apps Environment: $($newOutputs.containerAppsEnvName.value)" -ForegroundColor White
    Write-Host "  Container Apps Domain: $($newOutputs.containerAppsEnvDefaultDomain.value)" -ForegroundColor White
    Write-Host "  Container Apps Static IP: $($newOutputs.containerAppsEnvStaticIp.value)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Build and push container images to ACR" -ForegroundColor Gray
    Write-Host "  2. Deploy Container Apps to the environment" -ForegroundColor Gray
    Write-Host "  3. Configure ACR integration with AKS/Container Apps" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host "Check errors above for details" -ForegroundColor Yellow
    exit 1
}
