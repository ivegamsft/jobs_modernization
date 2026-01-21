# Deploy IAAS and PaaS Infrastructure
# This script deploys the application layers after core infrastructure is ready

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS & PAAS DEPLOYMENT SCRIPT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Parameters
$environment = "dev"
$applicationName = "jobsite"
$location = "eastus"

# ============================================================================
# Get Core Outputs
# ============================================================================

Write-Host "1. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json

if (-not $coreDeployment) {
    Write-Host "❌ Core deployment not found. Deploy core infrastructure first." -ForegroundColor Red
    exit 1
}

$outputs = $coreDeployment.properties.outputs
$frontendSubnetId = $outputs.frontendSubnetId.value
$dataSubnetId = $outputs.dataSubnetId.value
$peSubnetId = $outputs.peSubnetId.value
$logAnalyticsWorkspaceId = $outputs.logAnalyticsWorkspaceId.value
$keyVaultName = $outputs.keyVaultName.value

Write-Host "   ✅ Core outputs retrieved" -ForegroundColor Green
Write-Host "   Key Vault: $keyVaultName" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Generate and Store Passwords in Key Vault
# ============================================================================

Write-Host "2. Generating and storing passwords in Key Vault..." -ForegroundColor Yellow

function New-SecurePassword {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $special = "!@#$%"
    $password = -join ((1..12) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $password += $special[(Get-Random -Maximum $special.Length)]
    $password += "Aa1"
    return $password
}

$vmAdminPassword = New-SecurePassword
$appGatewayCertPassword = New-SecurePassword

# Store passwords in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "iaas-vm-admin-password" --value $vmAdminPassword --output none
az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-password" --value $appGatewayCertPassword --output none

Write-Host "   ✅ Stored: iaas-vm-admin-password" -ForegroundColor Green
Write-Host "   ✅ Stored: iaas-appgw-cert-password" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Generate App Gateway Certificate
# ============================================================================

Write-Host "3. Generating Application Gateway certificate..." -ForegroundColor Yellow

$cert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw.local" `
    -DnsName "*.jobsite.local", "jobsite.local" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable

$pfxPath = "$env:TEMP\appgw-$([Guid]::NewGuid().ToString()).pfx"
$securePassword = ConvertTo-SecureString -String $appGatewayCertPassword -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
$certBytes = [System.IO.File]::ReadAllBytes($pfxPath)
$certBase64 = [System.Convert]::ToBase64String($certBytes)
Remove-Item $pfxPath -Force

# Store certificate data in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "iaas-appgw-cert-data" --value $certBase64 --output none

Write-Host "   ✅ Certificate generated and stored in Key Vault" -ForegroundColor Green
Write-Host "   ✅ Stored: iaas-appgw-cert-data" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Deploy IAAS Infrastructure
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DEPLOYING IAAS INFRASTRUCTURE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\git\jobs_modernization\iac\bicep\iaas"

Write-Host "4. Deploying VMSS, SQL VM, and Application Gateway..." -ForegroundColor Yellow

az deployment sub create `
    --name "jobsite-iaas-$environment" `
    --location $location `
    --template-file "main.bicep" `
    --parameters "environment=$environment" `
    --parameters "applicationName=$applicationName" `
    --parameters "location=$location" `
    --parameters "frontendSubnetId=$frontendSubnetId" `
    --parameters "dataSubnetId=$dataSubnetId" `
    --parameters "adminPassword=$vmAdminPassword" `
    --parameters "appGatewayCertData=$certBase64" `
    --parameters "appGatewayCertPassword=$appGatewayCertPassword"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ IAAS deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ IAAS deployment completed!" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Deploy PaaS Infrastructure
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DEPLOYING PAAS INFRASTRUCTURE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get current user for SQL AAD admin
Write-Host "5. Getting current user details for SQL AAD admin..." -ForegroundColor Yellow
$currentUser = az ad signed-in-user show -o json | ConvertFrom-Json
$sqlAadAdminObjectId = $currentUser.id
$sqlAadAdminName = $currentUser.userPrincipalName

# Store SQL admin info in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "paas-sql-aad-admin-name" --value $sqlAadAdminName --output none
az keyvault secret set --vault-name $keyVaultName --name "paas-sql-aad-admin-object-id" --value $sqlAadAdminObjectId --output none

Write-Host "   SQL AAD Admin: $sqlAadAdminName" -ForegroundColor Gray
Write-Host "   ✅ Stored SQL AAD admin info in Key Vault" -ForegroundColor Green
Write-Host ""

Set-Location "c:\git\jobs_modernization\iac\bicep\paas"

Write-Host "6. Deploying App Service, SQL Database, and Application Insights..." -ForegroundColor Yellow

az deployment sub create `
    --name "jobsite-paas-$environment" `
    --location $location `
    --template-file "main.bicep" `
    --parameters "environment=$environment" `
    --parameters "applicationName=$applicationName" `
    --parameters "location=$location" `
    --parameters "peSubnetId=$peSubnetId" `
    --parameters "logAnalyticsWorkspaceId=$logAnalyticsWorkspaceId" `
    --parameters "sqlAadAdminObjectId=$sqlAadAdminObjectId" `
    --parameters "sqlAadAdminName=$sqlAadAdminName"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ PaaS deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ PaaS deployment completed!" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Deployment Summary
# ============================================================================

Write-Host "═� CREDENTIALS STORED IN KEY VAULT: $keyVaultName" -ForegroundColor Yellow
Write-Host "   VM Admin Username: azureadmin" -ForegroundColor White
Write-Host "   Retrieve passwords with:" -ForegroundColor Gray
Write-Host "   az keyvault secret show --vault-name $keyVaultName --name iaas-vm-admin-password --query value -o tsv" -ForegroundColor Gray═" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 SAVE THESE CREDENTIALS:" -ForegroundColor Yellow
Write-Host "   VM Admin Username: azureadmin" -ForegroundColor White
Write-Host "   VM Admin Password: $vmAdminPassword" -ForegroundColor White
Write-Host ""

# Get deployment outputs
$iaasDeployment = az deployment sub show --name "jobsite-iaas-$environment" -o json | ConvertFrom-Json
$paasDeployment = az deployment sub show --name "jobsite-paas-$environment" -o json | ConvertFrom-Json

Write-Host "🌐 Resource URLs:" -ForegroundColor Yellow
Write-Host "   App Gateway IP: $($iaasDeployment.properties.outputs.appGatewayPublicIp.value)" -ForegroundColor White
Write-Host "   App Service: https://$($paasDeployment.properties.outputs.appServiceName.value).azurewebsites.net" -ForegroundColor White
Write-Host ""

Write-Host "✅ All infrastructure deployed successfully!" -ForegroundColor Green
