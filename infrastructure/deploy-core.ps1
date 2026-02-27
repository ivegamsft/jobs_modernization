# Deploy Core Infrastructure with Consistent Password Generation
# Generates secure passwords following Azure best practices

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "CORE INFRASTRUCTURE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Load password generation function
. "$PSScriptRoot\scripts\New-SecurePassword.ps1"

# Parameters
$environment = "dev"
$applicationName = "jobsite"
$location = "swedencentral"
$vnetAddressPrefix = "10.50.0.0/21"

# Generate secure passwords (20 characters, meets all requirements)
Write-Host "1. Generating secure credentials..." -ForegroundColor Yellow
$sqlPassword = New-SecurePassword -Length 20
$wfePassword = New-SecurePassword -Length 20

Write-Host "   ✅ SQL Admin Password: 20 chars (uppercase, lowercase, numbers, special)" -ForegroundColor Green
Write-Host "   ✅ WFE Admin Password: 20 chars (uppercase, lowercase, numbers, special)" -ForegroundColor Green
Write-Host ""

# Deploy
Write-Host "2. Deploying core infrastructure..." -ForegroundColor Yellow
Write-Host "   Location: $location" -ForegroundColor Gray
Write-Host "   VNet: $vnetAddressPrefix" -ForegroundColor Gray
Write-Host ""

az deployment sub create `
    --name "jobsite-core-dev" `
    --location $location `
    --template-file "./bicep/core/main.bicep" `
    --parameters `
    environment=$environment `
    applicationName=$applicationName `
    location=$location `
    vnetAddressPrefix=$vnetAddressPrefix `
    sqlAdminUsername="jobsiteadmin" `
    sqlAdminPassword="$sqlPassword" `
    wfeAdminUsername="azureadmin" `
    wfeAdminPassword="$wfePassword"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ CORE DEPLOYMENT COMPLETE" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Key Vault: kv-dev-swc-ubzfsgu4p5" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Credentials stored in Key Vault:" -ForegroundColor Cyan
    Write-Host "  • sql-admin-username: jobsiteadmin" -ForegroundColor Yellow
    Write-Host "  • sql-admin-password: (secure 20-char password)" -ForegroundColor Yellow
    Write-Host "  • wfe-admin-username: azureadmin" -ForegroundColor Yellow
    Write-Host "  • wfe-admin-password: (secure 20-char password)" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
