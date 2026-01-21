# Generate Strong Passwords and Deploy IAAS
# Addresses Azure CLI "content already consumed" issue

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "GENERATE STRONG PASSWORDS & DEPLOY IAAS" -ForegroundColor Cyan
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
    
    # Ensure we have at least one of each type
    $password = [char[]](
        $lowercase[(Get-Random -Maximum $lowercase.Length)],
        $uppercase[(Get-Random -Maximum $uppercase.Length)],
        $digits[(Get-Random -Maximum $digits.Length)],
        $special[(Get-Random -Maximum $special.Length)]
    )
    
    # Fill the rest randomly
    $allChars = $lowercase + $uppercase + $digits + $special
    $remaining = $Length - 4
    for ($i = 0; $i -lt $remaining; $i++) {
        $password += [char]$allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    # Shuffle
    return -join ($password | Sort-Object { Get-Random })
}

$vmPassword = New-StrongPassword -Length 20
$certPassword = New-StrongPassword -Length 20
$kvPassword = New-StrongPassword -Length 20

Write-Host "   VM Admin Password: $vmPassword" -ForegroundColor White
Write-Host "   Certificate Password: $certPassword" -ForegroundColor White
Write-Host "   (Saved securely)" -ForegroundColor Gray
Write-Host ""

# Get core outputs
Write-Host "Retrieving core deployment outputs..." -ForegroundColor Yellow
$coreJson = az deployment sub show --name "jobsite-core-dev" -o json
$coreOutputs = $coreJson | ConvertFrom-Json
$frontendSubnetId = $coreOutputs.properties.outputs.frontendSubnetId.value
$dataSubnetId = $coreOutputs.properties.outputs.dataSubnetId.value
$keyVaultName = $coreOutputs.properties.outputs.keyVaultName.value
Write-Host "   ✅ Core outputs retrieved" -ForegroundColor Green
Write-Host ""

# Save passwords to Key Vault
Write-Host "Storing passwords in Key Vault: $keyVaultName" -ForegroundColor Yellow
$ErrorActionPreference = 'Continue'

try {
    az keyvault secret set --vault-name $keyVaultName --name "iaas-vm-password" --value $vmPassword --output none --only-show-errors 2>$null
    Write-Host "   ✅ VM password stored" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Could not store in Key Vault (continuing)" -ForegroundColor Yellow
}

try {
    az keyvault secret set --vault-name $keyVaultName --name "iaas-cert-password" --value $certPassword --output none --only-show-errors 2>$null
    Write-Host "   ✅ Certificate password stored" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Could not store in Key Vault (continuing)" -ForegroundColor Yellow
}

Write-Host ""
$ErrorActionPreference = 'Stop'

# Generate certificate
Write-Host "Generating self-signed certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw.local" `
    -DnsName "*.jobsite.local", "jobsite.local" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyExportPolicy Exportable `
    -KeyLength 2048 `
    -KeyAlgorithm RSA

$certPath = "$env:TEMP\jobsite-appgw-$(Get-Random).pfx"
$securePwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
$null = Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $securePwd -Force

$certBytes = [IO.File]::ReadAllBytes($certPath)
$certData = [Convert]::ToBase64String($certBytes)
Remove-Item $certPath -Force
Write-Host "   ✅ Certificate generated and encoded" -ForegroundColor Green
Write-Host ""

# Create parameter file to avoid "content already consumed" issue
Write-Host "Creating deployment parameter file..." -ForegroundColor Yellow
$paramsFile = "$env:TEMP\iaas-deploy-params.json"
$paramsContent = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        environment = @{ value = 'dev' }
        applicationName = @{ value = 'jobsite' }
        location = @{ value = 'eastus' }
        frontendSubnetId = @{ value = $frontendSubnetId }
        dataSubnetId = @{ value = $dataSubnetId }
        adminUsername = @{ value = 'azureadmin' }
        adminPassword = @{ value = $vmPassword }
        vmSize = @{ value = 'Standard_D2s_v4' }
        vmssInstanceCount = @{ value = 2 }
        sqlVmSize = @{ value = 'Standard_D4s_v4' }
        appGatewayCertData = @{ value = $certData }
        appGatewayCertPassword = @{ value = $certPassword }
    }
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText($paramsFile, $paramsContent)
Write-Host "   ✅ Parameter file created: $paramsFile" -ForegroundColor Green
Write-Host ""

# Deploy using parameter file
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DEPLOYING IAAS INFRASTRUCTURE" -ForegroundColor Cyan
Write-Host "Estimated time: 15-20 minutes" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$deployCmd = "az deployment sub create " + `
    "--name jobsite-iaas-dev " + `
    "--location eastus " + `
    "--template-file ""c:\git\jobs_modernization\iac\bicep\iaas\main.bicep"" " + `
    "--parameters ""@$paramsFile"""

Write-Host "Command: $deployCmd" -ForegroundColor Gray
Write-Host ""

Invoke-Expression $deployCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ IAAS DEPLOYMENT SUCCEEDED" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 CREDENTIALS:" -ForegroundColor Cyan
    Write-Host "   VM Admin Username: azureadmin" -ForegroundColor White
    Write-Host "   VM Admin Password: $vmPassword" -ForegroundColor White
    Write-Host ""
    Write-Host "💾 Retrieve anytime:" -ForegroundColor Cyan
    Write-Host "   az keyvault secret show --vault-name $keyVaultName --name iaas-vm-password --query value -o tsv" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Check error messages above for details" -ForegroundColor Yellow
    exit 1
}
