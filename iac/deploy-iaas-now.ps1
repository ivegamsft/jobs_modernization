# Deploy IAAS Infrastructure (Resilient Version)
# Handles Key Vault connectivity issues gracefully

$ErrorActionPreference = 'Stop'
$environment = "dev"
$location = "eastus"

Write-Host "Getting core infrastructure outputs..." -ForegroundColor Yellow
$coreOutputs = az deployment sub show --name "jobsite-core-dev" --query "properties.outputs" -o json | ConvertFrom-Json

$frontendSubnetId = $coreOutputs.frontendSubnetId.value
$dataSubnetId = $coreOutputs.dataSubnetId.value
$keyVaultName = $coreOutputs.keyVaultName.value

Write-Host "  Frontend Subnet: ...$(($frontendSubnetId -split '/')[-1])" -ForegroundColor Gray
Write-Host "  Data Subnet: ...$(($dataSubnetId -split '/')[-1])" -ForegroundColor Gray
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Gray
Write-Host ""

# Generate passwords
Write-Host "Generating passwords..." -ForegroundColor Yellow
$vmPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }) + "!Aa1"
$certPwd = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }) + "!Aa1"

# Try to store in Key Vault (but continue if it fails)
Write-Host "Attempting to store passwords in Key Vault..." -ForegroundColor Yellow
$ErrorActionPreference = 'Continue'
$kvStored = $false

try {
    az keyvault secret set --vault-name $keyVaultName --name "iaas-vm-admin-password" --value $vmPassword --output none 2>$null
    if ($LASTEXITCODE -eq 0) {
        az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-password" --value $certPwd --output none 2>$null
        if ($LASTEXITCODE -eq 0) {
            $kvStored = $true
            Write-Host "  ✅ Passwords stored in Key Vault" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "  ⚠️  Key Vault storage failed (continuing anyway)" -ForegroundColor Yellow
}

if (-not $kvStored) {
    Write-Host ""
    Write-Host "  📋 SAVE THESE CREDENTIALS:" -ForegroundColor Yellow
    Write-Host "     VM Admin Username: azureadmin" -ForegroundColor White
    Write-Host "     VM Admin Password: $vmPassword" -ForegroundColor White
}

Write-Host ""
$ErrorActionPreference = 'Stop'

# Generate cert
Write-Host "Generating Application Gateway certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate -Subject "CN=jobsite-appgw.local" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(2) -KeyExportPolicy Exportable
$pfxPath = "$env:TEMP\appgw-$(Get-Date -Format 'yyyyMMddHHmmss').pfx"
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password (ConvertTo-SecureString -String $certPwd -Force -AsPlainText) | Out-Null
$certData = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
Remove-Item $pfxPath -Force

# Try to store cert in Key Vault
$ErrorActionPreference = 'Continue'
try {
    az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-data" --value $certData --output none 2>$null
}
catch {
    # Silent fail
}
$ErrorActionPreference = 'Stop'

Write-Host "  ✅ Certificate generated" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Starting IAAS deployment..." -ForegroundColor Yellow
Write-Host "This will take approximately 15-20 minutes" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Deploy
az deployment sub create `
    --name "jobsite-iaas-$environment" `
    --location $location `
    --template-file "c:\git\jobs_modernization\iac\bicep\iaas\main.bicep" `
    --parameters environment=$environment `
    --parameters location=$location `
    --parameters frontendSubnetId=$frontendSubnetId `
    --parameters dataSubnetId=$dataSubnetId `
    --parameters adminPassword=$vmPassword `
    --parameters appGatewayCertData=$certData `
    --parameters appGatewayCertPassword=$certPwd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ IAAS deployment completed successfully!" -ForegroundColor Green
    
    if (-not $kvStored) {
        Write-Host ""
        Write-Host "📋 REMEMBER TO SAVE CREDENTIALS:" -ForegroundColor Yellow
        Write-Host "   VM Admin Username: azureadmin" -ForegroundColor White
        Write-Host "   VM Admin Password: $vmPassword" -ForegroundColor White
    }
}
else {
    Write-Host ""
    Write-Host "❌ IAAS deployment failed" -ForegroundColor Red
    exit 1
}
