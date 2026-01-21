# Deploy IAAS with certificates from Key Vault

$ErrorActionPreference = 'Stop'
$kvName = "jobsite-dev-kv-ubzfsgu4p5eli"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS DEPLOYMENT SCRIPT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Generate passwords and certificate
Write-Host "1. Generating passwords and certificate..." -ForegroundColor Yellow
$sqlPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 20 | ForEach-Object { [char]$_ }) + "!Aa1"
$vmPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 20 | ForEach-Object { [char]$_ }) + "!Aa1"
$certPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 20 | ForEach-Object { [char]$_ }) + "!Aa1"

$cert = New-SelfSignedCertificate -DnsName "jobsite-appgw.local" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(2) -KeyExportPolicy Exportable
$pfxPath = "$env:TEMP\appgw-$([Guid]::NewGuid().ToString()).pfx"
$securePassword = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
$certBytes = [System.IO.File]::ReadAllBytes($pfxPath)
$certBase64 = [System.Convert]::ToBase64String($certBytes)
Remove-Item $pfxPath -Force

Write-Host "   SQL Password: $($sqlPassword.Length) chars" -ForegroundColor Gray
Write-Host "   VM Password: $($vmPassword.Length) chars" -ForegroundColor Gray
Write-Host "   Certificate: $($certBase64.Length) bytes" -ForegroundColor Gray
Write-Host ""

# Store in Key Vault
Write-Host "2. Storing secrets in Key Vault: $kvName..." -ForegroundColor Yellow
az keyvault secret set --vault-name $kvName --name "iaas-sql-password" --value $sqlPassword | Out-Null
az keyvault secret set --vault-name $kvName --name "iaas-vm-password" --value $vmPassword | Out-Null
az keyvault secret set --vault-name $kvName --name "iaas-cert-data" --value $certBase64 | Out-Null
az keyvault secret set --vault-name $kvName --name "iaas-cert-password" --value $certPassword | Out-Null
Write-Host "   ✅ Secrets stored" -ForegroundColor Green
Write-Host ""

# Get core deployment outputs
Write-Host "3. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment group show --name jobsite-core-dev --resource-group jobsite-core-dev-rg -o json | ConvertFrom-Json
$outputs = $coreDeployment.properties.outputs

$vnetId = $outputs.vnetId.value
$frontendSubnetId = $outputs.frontendSubnetId.value
$dataSubnetId = $outputs.dataSubnetId.value
$logAnalyticsWorkspaceId = $outputs.logAnalyticsWorkspaceId.value

Write-Host "   VNet ID: $vnetId" -ForegroundColor Gray
Write-Host ""

# Deploy IAAS
Write-Host "4. Deploying IAAS infrastructure..." -ForegroundColor Yellow
Write-Host ""

Set-Location "c:\git\jobs_modernization\iac\bicep\iaas"

az deployment group create `
    --name "jobsite-iaas-dev" `
    --resource-group "jobsite-iaas-dev-rg" `
    --template-file "main.bicep" `
    --parameters "environment=dev" `
    --parameters "vnetId=$vnetId" `
    --parameters "frontendSubnetId=$frontendSubnetId" `
    --parameters "dataSubnetId=$dataSubnetId" `
    --parameters "logAnalyticsWorkspaceId=$logAnalyticsWorkspaceId" `
    --parameters "sqlAdminPassword=$sqlPassword" `
    --parameters "vmAdminPassword=$vmPassword" `
    --parameters "appGatewayCertData=$certBase64" `
    --parameters "appGatewayCertPassword=$certPassword"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ IAAS deployment completed successfully!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "❌ IAAS deployment failed" -ForegroundColor Red
    exit 1
}
