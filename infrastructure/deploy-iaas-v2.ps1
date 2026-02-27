# Direct IAAS Deployment - No Invoke-Expression
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS DEPLOYMENT - STRONG PASSWORDS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Generate Strong Passwords
Write-Host "Generating strong passwords..." -ForegroundColor Yellow
function New-StrongPassword {
    param([int]$Length = 20)
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $digits = '0123456789'
    $special = '!@#$%&*-_+=?'
    
    $password = [char[]](
        $lowercase[(Get-Random -Maximum $lowercase.Length)],
        $uppercase[(Get-Random -Maximum $uppercase.Length)],
        $digits[(Get-Random -Maximum $digits.Length)],
        $special[(Get-Random -Maximum $special.Length)]
    )
    
    $allChars = $lowercase + $uppercase + $digits + $special
    $remaining = $Length - 4
    for ($i = 0; $i -lt $remaining; $i++) {
        $password += [char]$allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    return (-join ($password | Sort-Object { Get-Random }))
}

$vmPassword = New-StrongPassword -Length 20
$certPassword = New-StrongPassword -Length 20

Write-Host "   ✅ VM Admin Password: $vmPassword" -ForegroundColor Green
Write-Host "   ✅ Certificate Password: $certPassword" -ForegroundColor Green
Write-Host ""

# Get core outputs
Write-Host "Getting core outputs..." -ForegroundColor Yellow
$coreJson = az deployment sub show --name "jobsite-core-dev" -o json
$coreOutputs = $coreJson | ConvertFrom-Json
$feSubnet = $coreOutputs.properties.outputs.frontendSubnetId.value
$dataSubnet = $coreOutputs.properties.outputs.dataSubnetId.value
$githubRunnersSubnet = $coreOutputs.properties.outputs.githubRunnersSubnetId.value
$kvName = $coreOutputs.properties.outputs.keyVaultName.value
Write-Host "   ✅ Outputs retrieved" -ForegroundColor Green
Write-Host ""

# Store in Key Vault
Write-Host "Storing in Key Vault..." -ForegroundColor Yellow
$ErrorActionPreference = 'Continue'
az keyvault secret set --vault-name $kvName --name "iaas-vm-password" --value $vmPassword --output none 2>$null | Out-Null
az keyvault secret set --vault-name $kvName --name "iaas-cert-password" --value $certPassword --output none 2>$null | Out-Null
Write-Host "   ✅ Passwords stored" -ForegroundColor Green
Write-Host ""
$ErrorActionPreference = 'Stop'

# Generate certificate
Write-Host "Generating certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw.local" `
    -DnsName "*.jobsite.local", "jobsite.local" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable

$tmpCert = "$env:TEMP\jsc-$(Get-Random).pfx"
$null = Export-PfxCertificate -Cert $cert -FilePath $tmpCert -Password (ConvertTo-SecureString $certPassword -AsPlainText -Force) -Force

$certB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tmpCert))
Remove-Item $tmpCert
Write-Host "   ✅ Certificate ready" -ForegroundColor Green
Write-Host ""

# Create params JSON
Write-Host "Creating parameter file..." -ForegroundColor Yellow
$params = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        environment = @{ value = 'dev' }
        applicationName = @{ value = 'jobsite' }
        location = @{ value = 'swedencentral' }
        frontendSubnetId = @{ value = $feSubnet }
        dataSubnetId = @{ value = $dataSubnet }
        githubRunnersSubnetId = @{ value = $githubRunnersSubnet }
        adminUsername = @{ value = 'azureadmin' }
        adminPassword = @{ value = $vmPassword }
        vmSize = @{ value = 'Standard_D2ds_v6' }
        vmssInstanceCount = @{ value = 2 }
        sqlVmSize = @{ value = 'Standard_D4ds_v6' }
        appGatewayCertData = @{ value = $certB64 }
        appGatewayCertPassword = @{ value = $certPassword }
    }
}

$paramsJson = $params | ConvertTo-Json -Depth 10
$paramsFile = "$env:TEMP\iaas-params-$([guid]::NewGuid().ToString().Substring(0,8)).json"
[IO.File]::WriteAllText($paramsFile, $paramsJson, [System.Text.Encoding]::UTF8)
Write-Host "   ✅ Parameters saved to: $paramsFile" -ForegroundColor Green
Write-Host ""

# Deploy
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Starting deployment (15-20 minutes)..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location "swedencentral" `
    --template-file "c:\git\jobs_modernization\iac\bicep\iaas\main.bicep" `
    --parameters "@$paramsFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ DEPLOYMENT SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Credentials:" -ForegroundColor Cyan
    Write-Host "  Username: azureadmin" -ForegroundColor White
    Write-Host "  Password: $vmPassword" -ForegroundColor White
} else {
    Write-Host "❌ DEPLOYMENT FAILED - Check errors above" -ForegroundColor Red
    exit 1
}

Remove-Item $paramsFile -Force 2>$null
