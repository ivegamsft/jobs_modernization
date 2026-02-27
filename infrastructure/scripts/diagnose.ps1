# Troubleshooting & Diagnostics
$ErrorActionPreference = 'Continue'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE CLI DIAGNOSTICS & TROUBLESHOOTING" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. Check Azure CLI version
Write-Host "1. Checking Azure CLI..." -ForegroundColor Yellow
$cliVersion = az version -o json 2>$null | ConvertFrom-Json
Write-Host "   Azure CLI version: $($cliVersion.'azure-cli')" -ForegroundColor Gray
Write-Host ""

# 2. Check authentication
Write-Host "2. Checking authentication..." -ForegroundColor Yellow
$account = az account show -o json 2>$null | ConvertFrom-Json
if ($account) {
    Write-Host "   ✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
} else {
    Write-Host "   ❌ Not authenticated" -ForegroundColor Red
}
Write-Host ""

# 3. Check core deployment
Write-Host "3. Checking core deployment..." -ForegroundColor Yellow
$coreExists = az deployment sub show --name "jobsite-core-dev" -o json 2>$null | ConvertFrom-Json
if ($coreExists) {
    Write-Host "   ✅ Core deployment found: $($coreExists.properties.provisioningState)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Core deployment not found" -ForegroundColor Red
}
Write-Host ""

# 4. Validate IAAS Bicep
Write-Host "4. Validating IAAS Bicep template..." -ForegroundColor Yellow
$validation = az deployment sub validate `
    --name "test-validation" `
    --location eastus `
    --template-file "$PSScriptRoot\..\bicep\iaas\main.bicep" `
    --parameters environment=dev `
    --parameters location=eastus `
    --parameters frontendSubnetId="/dummy" `
    --parameters dataSubnetId="/dummy" `
    --parameters adminPassword="<REPLACE_WITH_SECURE_PASSWORD>" `
    --parameters appGatewayCertData="dummybase64" `
    --parameters appGatewayCertPassword="<REPLACE_WITH_SECURE_PASSWORD>" `
    -o json 2>&1

if ($validation -like "*error*" -or $validation -like "*Error*") {
    Write-Host "   ⚠️  Validation errors found:" -ForegroundColor Yellow
    Write-Host $validation -ForegroundColor Gray
} else {
    Write-Host "   ✅ Template is valid" -ForegroundColor Green
}
Write-Host ""

# 5. Check resource groups
Write-Host "5. Checking resource groups..." -ForegroundColor Yellow
$rgs = az group list --query "[?starts_with(name, 'jobsite')]" -o json 2>$null | ConvertFrom-Json
foreach ($rg in $rgs) {
    Write-Host "   ✅ $($rg.name) - $($rg.properties.provisioningState)" -ForegroundColor Green
}
Write-Host ""

# 6. Check deployments
Write-Host "6. Checking deployments..." -ForegroundColor Yellow
$deployments = az deployment sub list --query "[?contains(name, 'jobsite')]" -o json 2>$null | ConvertFrom-Json
$deployments = $deployments | Sort-Object -Property { $_.properties.timestamp } -Descending | Select-Object -First 5
foreach ($dep in $deployments) {
    Write-Host "   $($dep.name)" -ForegroundColor Gray
    Write-Host "      State: $($dep.properties.provisioningState)" -ForegroundColor $(if ($dep.properties.provisioningState -eq 'Succeeded') { 'Green' } else { 'Yellow' })
}
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Diagnostics complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
