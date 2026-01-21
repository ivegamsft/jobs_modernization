#!/usr/bin/env pwsh
# IAAS Deployment - Final Clean Version
# Generated Credentials: Username: azureadmin | Password: 6-CtFhZr1y6nm8Q&C#to

param(
    [string]$VMPassword = "6-CtFhZr1y6nm8Q&C#to",
    [string]$CertPassword = "4lbeGK1H?&Xia12H%WGI"
)

$ErrorActionPreference = 'Stop'

Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
Write-Host "IAAS INFRASTRUCTURE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Step 1: Get Core Outputs
Write-Host "`n[1/4] Retrieving core deployment outputs..." -ForegroundColor Yellow

$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json
$outputs = $coreDeployment.properties.outputs

$frontendSubnetId = $outputs.frontendSubnetId.value
$dataSubnetId = $outputs.dataSubnetId.value

Write-Host "✅ Frontend Subnet: " + $($frontendSubnetId -split '/')[-1] -ForegroundColor Green
Write-Host "✅ Data Subnet: " + $($dataSubnetId -split '/')[-1] -ForegroundColor Green

# Step 2: Generate Certificate
Write-Host "`n[2/4] Generating self-signed certificate..." -ForegroundColor Yellow

$cert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw.local" `
    -DnsName "*.jobsite.local", "jobsite.local" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable `
    -KeyLength 2048

$pfxFile = Join-Path $env:TEMP "appgw-$(Get-Random).pfx"
$securePassword = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
$null = Export-PfxCertificate -Cert $cert -FilePath $pfxFile -Password $securePassword -Force

$certData = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pfxFile))
Remove-Item $pfxFile -Force

Write-Host "✅ Certificate generated and encoded to Base64" -ForegroundColor Green

# Step 3: Create Parameters JSON
Write-Host "`n[3/4] Creating deployment parameters..." -ForegroundColor Yellow

$deploymentParams = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentParameters.json#'
    'contentVersion' = '1.0.0.0'
    'parameters' = @{
        'environment' = @{ 'value' = 'dev' }
        'applicationName' = @{ 'value' = 'jobsite' }
        'location' = @{ 'value' = 'eastus' }
        'frontendSubnetId' = @{ 'value' = $frontendSubnetId }
        'dataSubnetId' = @{ 'value' = $dataSubnetId }
        'adminUsername' = @{ 'value' = 'azureadmin' }
        'adminPassword' = @{ 'value' = $VMPassword }
        'vmSize' = @{ 'value' = 'Standard_D2s_v4' }
        'vmssInstanceCount' = @{ 'value' = 2 }
        'sqlVmSize' = @{ 'value' = 'Standard_D4s_v4' }
        'appGatewayCertData' = @{ 'value' = $certData }
        'appGatewayCertPassword' = @{ 'value' = $CertPassword }
    }
}

$paramsJson = ConvertTo-Json -InputObject $deploymentParams -Depth 10
$paramsFile = Join-Path $env:TEMP "iaas-$([guid]::NewGuid().ToString().Substring(0, 8)).json"
[System.IO.File]::WriteAllText($paramsFile, $paramsJson, [System.Text.Encoding]::UTF8)

Write-Host "✅ Parameters file created" -ForegroundColor Green

# Step 4: Deploy
Write-Host "`n[4/4] Starting IAAS deployment..." -ForegroundColor Yellow
Write-Host "Estimated time: 15-20 minutes" -ForegroundColor Gray

$templateFile = "c:\git\jobs_modernization\iac\bicep\iaas\main.bicep"

Write-Host "`nDeploying resources:" -ForegroundColor Cyan
Write-Host "  - Virtual Machine Scale Set (VMSS)" -ForegroundColor Gray
Write-Host "  - SQL Server Virtual Machine" -ForegroundColor Gray
Write-Host "  - Application Gateway with SSL" -ForegroundColor Gray
Write-Host ""

az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location "eastus" `
    --template-file $templateFile `
    --parameters "@$paramsFile" `
    --no-wait

# Check initial status
Start-Sleep -Seconds 10
$status = az deployment sub show --name "jobsite-iaas-dev" --query "properties.provisioningState" -o tsv 2>$null

if ($status) {
    Write-Host "`n✅ Deployment started successfully!" -ForegroundColor Green
    Write-Host "Status: $status" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Monitor progress:" -ForegroundColor Cyan
    Write-Host "  az deployment sub show --name jobsite-iaas-dev --query properties.provisioningState -o tsv" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  Deployment may not have started. Check status:" -ForegroundColor Yellow
    Write-Host "  az deployment sub list --query '[?name==`jobsite-iaas-dev`]' -o table" -ForegroundColor Gray
}

# Cleanup
Remove-Item $paramsFile -Force 2>$null

# Credentials Summary
Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
Write-Host "CREDENTIALS" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "VM Access:" -ForegroundColor Yellow
Write-Host "  Username: azureadmin" -ForegroundColor White
Write-Host "  Password: $VMPassword" -ForegroundColor White
Write-Host ""
Write-Host "🔒 Save these credentials securely!" -ForegroundColor Red
Write-Host ""
