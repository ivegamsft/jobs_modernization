# Simple IAAS Deployment Script
# Run this after core infrastructure is deployed

$environment = "dev"
$location = "eastus"

# Get core outputs
Write-Host "Getting core infrastructure outputs..." -ForegroundColor Yellow
$coreOutputs = az deployment sub show --name "jobsite-core-dev" --query "properties.outputs" -o json | ConvertFrom-Json

$frontendSubnetId = $coreOutputs.frontendSubnetId.value
$dataSubnetId = $coreOutputs.dataSubnetId.value
$keyVaultName = $coreOutputs.keyVaultName.value

Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Gray
Write-Host ""

# Generate passwords
Write-Host "Generating and storing passwords in Key Vault..." -ForegroundColor Yellow
$vmPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }) + "!Aa1"
$certPwd = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }) + "!Aa1"

# Store VM password in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "iaas-vm-admin-password" --value $vmPassword --output none
Write-Host "  ✅ Stored: iaas-vm-admin-password" -ForegroundColor Green

# Generate cert
$cert = New-SelfSignedCertificate -Subject "CN=jobsite-appgw.local" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(2) -KeyExportPolicy Exportable
$pfxPath = "$env:TEMP\appgw.pfx"
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password (ConvertTo-SecureString -String $certPwd -Force -AsPlainText) | Out-Null
$certData = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
Remove-Item $pfxPath -Force

# Store cert data and password in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-data" --value $certData --output none
az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-password" --value $certPwd --output none
Write-Host "  ✅ Stored: iaas-appgw-cert-data" -ForegroundColor Green
Write-Host "  ✅ Stored: iaas-appgw-cert-password" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Passwords stored in Key Vault: $keyVaultName" -ForegroundColor Cyan
Write-Host "   Retrieve with: az keyvault secret show --vault-name $keyVaultName --name [secret-name]" -ForegroundColor Gray
Write-Host ""
Write-Host "Starting IAAS deployment..." -ForegroundColor Yellow

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
