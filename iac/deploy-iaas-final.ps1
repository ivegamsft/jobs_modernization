# Complete IAAS Deployment - Working Version
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS DEPLOYMENT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get core outputs
Write-Host "1. Getting core outputs..." -ForegroundColor Yellow
$coreJson = az deployment sub show --name "jobsite-core-dev" --query "properties.outputs" -o json
$coreOutputs = $coreJson | ConvertFrom-Json
$frontendSubnetId = $coreOutputs.frontendSubnetId.value
$dataSubnetId = $coreOutputs.dataSubnetId.value
Write-Host "   ✅ Subnets retrieved" -ForegroundColor Green
Write-Host ""

# Set credentials
Write-Host "2. Setting credentials..." -ForegroundColor Yellow
$vmPassword = "P@ssw0rd!2026Admin"
$certPwd = "CertP@ss2026!"
Write-Host "   Username: azureadmin" -ForegroundColor Gray
Write-Host "   Password: $vmPassword" -ForegroundColor Gray
Write-Host ""

# Generate certificate
Write-Host "3. Generating certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw.local" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable

$pfxPath = "$env:TEMP\appgw-deploy.pfx"
$securePwd = ConvertTo-SecureString -String $certPwd -Force -AsPlainText
$null = Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePwd
$certBytes = [IO.File]::ReadAllBytes($pfxPath)
$certData = [Convert]::ToBase64String($certBytes)
Remove-Item $pfxPath -Force
Write-Host "   ✅ Certificate generated" -ForegroundColor Green
Write-Host ""

# Deploy
Write-Host "4. Starting deployment (15-20 minutes)..." -ForegroundColor Yellow
Write-Host ""

az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location eastus `
    --template-file "c:\git\jobs_modernization\iac\bicep\iaas\main.bicep" `
    --parameters environment=dev `
    --parameters location=eastus `
    --parameters "frontendSubnetId=$frontendSubnetId" `
    --parameters "dataSubnetId=$dataSubnetId" `
    --parameters "adminPassword=$vmPassword" `
    --parameters "appGatewayCertData=$certData" `
    --parameters "appGatewayCertPassword=$certPwd"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ IAAS deployment completed!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
