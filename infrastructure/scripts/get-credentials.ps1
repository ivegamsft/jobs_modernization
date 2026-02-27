# Retrieve Credentials from Key Vault
# This script retrieves all stored credentials from the Key Vault

$ErrorActionPreference = 'Continue'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "RETRIEVE CREDENTIALS FROM KEY VAULT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get Key Vault name from core deployment
Write-Host "Getting Key Vault name..." -ForegroundColor Yellow
$coreOutputs = az deployment sub show --name "jobsite-core-dev" --query "properties.outputs.keyVaultName.value" -o tsv

if (-not $coreOutputs) {
    Write-Host "❌ Could not find core deployment. Ensure core infrastructure is deployed." -ForegroundColor Red
    exit 1
}

$keyVaultName = $coreOutputs
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Green
Write-Host ""

# List all secrets
Write-Host "Available Secrets:" -ForegroundColor Yellow
Write-Host ""

$secrets = az keyvault secret list --vault-name $keyVaultName --query "[].name" -o tsv

if (-not $secrets) {
    Write-Host "  No secrets found in Key Vault" -ForegroundColor Gray
    exit 0
}

foreach ($secretName in $secrets) {
    Write-Host "  📌 $secretName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Retrieve IAAS credentials
Write-Host "IAAS Credentials:" -ForegroundColor Yellow
$vmPassword = az keyvault secret show --vault-name $keyVaultName --name "iaas-vm-admin-password" --query "value" -o tsv 2>$null
if ($vmPassword) {
    Write-Host "  VM Admin Username: azureadmin" -ForegroundColor White
    Write-Host "  VM Admin Password: $vmPassword" -ForegroundColor White
}
else {
    Write-Host "  (Not yet configured)" -ForegroundColor Gray
}
Write-Host ""

# Retrieve PaaS credentials
Write-Host "PaaS Credentials:" -ForegroundColor Yellow
$sqlAdminName = az keyvault secret show --vault-name $keyVaultName --name "paas-sql-aad-admin-name" --query "value" -o tsv 2>$null
if ($sqlAdminName) {
    Write-Host "  SQL AAD Admin: $sqlAdminName" -ForegroundColor White
}
else {
    Write-Host "  (Not yet configured)" -ForegroundColor Gray
}
Write-Host ""

# Retrieve legacy secrets (from original core deployment)
Write-Host "Legacy Secrets:" -ForegroundColor Yellow
$sqlUsername = az keyvault secret show --vault-name $keyVaultName --name "sql-admin-username" --query "value" -o tsv 2>$null
if ($sqlUsername) {
    $sqlPassword = az keyvault secret show --vault-name $keyVaultName --name "sql-admin-password" --query "value" -o tsv 2>$null
    Write-Host "  SQL Admin Username: $sqlUsername" -ForegroundColor White
    Write-Host "  SQL Admin Password: $sqlPassword" -ForegroundColor White
}
else {
    Write-Host "  (None)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 To retrieve a specific secret:" -ForegroundColor Cyan
Write-Host "   az keyvault secret show --vault-name $keyVaultName --name [secret-name] --query value -o tsv" -ForegroundColor Gray
Write-Host ""
