# ============================================================================
# Bicep Deployment Script for Legacy Job Site Application
# ============================================================================
# Usage: 
#   ./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg
#   ./Deploy-Bicep.ps1 -Environment prod -ResourceGroupName jobsite-prod-rg
#
# Prerequisites:
#   - Azure CLI or Azure PowerShell installed
#   - Logged in to Azure (az login or Connect-AzAccount)
#   - Appropriate permissions in target subscription
# ============================================================================

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [string]$Location = 'eastus',

    [string]$SubscriptionId = $null,

    [string]$KeyVaultName = $null,

    [string]$VpnCertSubject = 'CN=jobsite-vpn-root',

    [string]$AppGatewayCertSubject = 'CN=jobsite-appgw',

    [string]$AppGatewayCertPassword = $null,

    [switch]$WhatIf = $false
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$bicepFile = Join-Path $scriptRoot 'main.bicep'
$paramFile = Join-Path $scriptRoot "main.$Environment.bicepparam"
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$deploymentName = "jobsite-deploy-$Environment-$timestamp"
$tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "jobsite-certs-$timestamp"
$vpnRootCertBase64 = $null

New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Job Site Application - Bicep Deployment ($Environment)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Validation
# ============================================================================

Write-Host "📋 Validating deployment prerequisites..." -ForegroundColor Yellow

if (-not (Test-Path $bicepFile)) {
    Write-Host "❌ Bicep file not found: $bicepFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $paramFile)) {
    Write-Host "❌ Parameter file not found: $paramFile" -ForegroundColor Red
    exit 1
}

# Check for Azure CLI or PowerShell
$hasAzCli = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
$hasAzPs = $null -ne (Get-Command Get-AzContext -ErrorAction SilentlyContinue)

if (-not $hasAzCli -and -not $hasAzPs) {
    Write-Host "❌ Azure CLI or Azure PowerShell is required" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites validated" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Helper Functions - Certificates
# ============================================================================

function New-JobsiteVpnRootCert {
    param(
        [string]$Subject,
        [string]$ExportPath
    )

    $cert = New-SelfSignedCertificate -Type Custom -Subject $Subject -KeySpec Signature -KeyExportPolicy Exportable -HashAlgorithm SHA256 -KeyLength 2048 -KeyUsageProperty Sign -KeyUsage CertSign, CRLSign, DigitalSignature -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(3)
    Export-Certificate -Cert $cert -FilePath $ExportPath -Type CERT | Out-Null
    $bytes = [System.IO.File]::ReadAllBytes($ExportPath)
    return [Convert]::ToBase64String($bytes)
}

function New-JobsiteAppGatewayCert {
    param(
        [string]$Subject,
        [string]$ExportPath,
        [string]$Password
    )

    $cert = New-SelfSignedCertificate -DnsName $Subject.TrimStart('CN=') -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(2)
    $secPassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $ExportPath -Password $secPassword | Out-Null
    $bytes = [System.IO.File]::ReadAllBytes($ExportPath)
    return [PSCustomObject]@{
        Base64Pfx = [Convert]::ToBase64String($bytes)
        Password  = $Password
    }
}

# ============================================================================
# Azure Connection
# ============================================================================

Write-Host "🔐 Connecting to Azure..." -ForegroundColor Yellow

if ($hasAzPs) {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please login to Azure..."
        Connect-AzAccount
    }

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
}
else {
    $account = az account show 2>$null
    if (-not $account) {
        Write-Host "Please login to Azure..."
        az login
    }
}

Write-Host "✅ Connected to Azure" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Key Vault & Certificate Generation
# ============================================================================

if (-not $KeyVaultName) {
    Write-Host "⚠️  Key Vault name not provided. Skipping certificate generation." -ForegroundColor Yellow
}
else {
    if (-not $hasAzCli) {
        Write-Host "❌ Azure CLI is required for Key Vault secret operations." -ForegroundColor Red
        exit 1
    }

    Write-Host "🔑 Ensuring Key Vault: $KeyVaultName" -ForegroundColor Yellow

    $kvExists = az keyvault show --name $KeyVaultName 2>$null
    if (-not $kvExists) {
        Write-Host "Creating Key Vault $KeyVaultName in $Location (soft-delete enabled by default)" -ForegroundColor Gray
        az keyvault create --name $KeyVaultName --resource-group $ResourceGroupName --location $Location | Out-Null
    }

    if (-not $AppGatewayCertPassword) {
        $AppGatewayCertPassword = [System.Guid]::NewGuid().ToString('N')
    }

    $vpnCertPath = Join-Path $tempPath 'vpn-root.cer'
    $appGwPfxPath = Join-Path $tempPath 'appgw.pfx'

    Write-Host "🔧 Generating VPN root certificate ($VpnCertSubject)" -ForegroundColor Yellow
    $vpnRootCertBase64 = New-JobsiteVpnRootCert -Subject $VpnCertSubject -ExportPath $vpnCertPath

    Write-Host "🔧 Generating App Gateway certificate ($AppGatewayCertSubject)" -ForegroundColor Yellow
    $appGwCert = New-JobsiteAppGatewayCert -Subject $AppGatewayCertSubject -ExportPath $appGwPfxPath -Password $AppGatewayCertPassword

    Write-Host "💾 Storing certificates in Key Vault" -ForegroundColor Yellow
    az keyvault secret set --vault-name $KeyVaultName --name 'vpn-root-cert-base64' --value $vpnRootCertBase64 | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name 'appgw-pfx-base64' --value $appGwCert.Base64Pfx | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name 'appgw-pfx-password' --value $appGwCert.Password | Out-Null

    Write-Host "✅ Certificates generated and stored in Key Vault" -ForegroundColor Green
    Write-Host "   vpn-root-cert-base64" -ForegroundColor Gray
    Write-Host "   appgw-pfx-base64" -ForegroundColor Gray
    Write-Host "   appgw-pfx-password" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# Resource Group
# ============================================================================

Write-Host "📦 Checking resource group: $ResourceGroupName" -ForegroundColor Yellow

if ($hasAzPs) {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    
    if (-not $rg) {
        Write-Host "Creating resource group: $ResourceGroupName in $Location"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tags @{
            environment  = $Environment
            application  = 'jobsite'
            deployedDate = Get-Date -Format 'u'
        }
    }
}
else {
    $rg = az group show --name $ResourceGroupName 2>$null
    
    if (-not $rg) {
        Write-Host "Creating resource group: $ResourceGroupName in $Location"
        az group create --name $ResourceGroupName --location $Location --tags @{
            environment = $Environment
            application = 'jobsite'
        }
    }
}

Write-Host "✅ Resource group ready: $ResourceGroupName" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Bicep Validation
# ============================================================================

Write-Host "🔍 Validating Bicep template..." -ForegroundColor Yellow

$validateCmd = @(
    'deployment', 'group', 'validate',
    '--resource-group', $ResourceGroupName,
    '--template-file', $bicepFile,
    '--parameters', $paramFile
)

if ($vpnRootCertBase64) {
    $validateCmd += @('vpnRootCertificate=' + $vpnRootCertBase64)
}

$validateResult = az @validateCmd 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Bicep validation failed:" -ForegroundColor Red
    Write-Host $validateResult
    exit 1
}

Write-Host "✅ Bicep template validated" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Deployment
# ============================================================================

Write-Host "🚀 Starting deployment..." -ForegroundColor Yellow
Write-Host "Deployment Name: $deploymentName" -ForegroundColor Gray
Write-Host "Environment: $Environment" -ForegroundColor Gray
Write-Host "Location: $Location" -ForegroundColor Gray

if ($WhatIf) {
    Write-Host "(Running in WhatIf mode - no resources will be created)" -ForegroundColor Cyan
    Write-Host ""
}

$deployCmd = @(
    'deployment', 'group', 'create',
    '--name', $deploymentName,
    '--resource-group', $ResourceGroupName,
    '--template-file', $bicepFile,
    '--parameters', $paramFile
)

if ($WhatIf) {
    $deployCmd += '--what-if'
}

if ($vpnRootCertBase64) {
    $deployCmd += @('vpnRootCertificate=' + $vpnRootCertBase64)
}

Write-Host ""
$deploymentOutput = az @deployCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deploymentOutput
    exit 1
}

Write-Host "✅ Deployment completed successfully" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Output
# ============================================================================

Write-Host "📊 Deployment Outputs:" -ForegroundColor Yellow
Write-Host ""

$outputs = az deployment group show --resource-group $ResourceGroupName --name $deploymentName --query "properties.outputs" -o json | ConvertFrom-Json

foreach ($key in $outputs.PSObject.Properties.Name) {
    $value = $outputs.$key.value
    Write-Host "$($key): $value" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Clean up temp cert artifacts
if (Test-Path $tempPath) {
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
}

# ============================================================================
# Next Steps
# ============================================================================

Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the deployed resources in Azure Portal"
Write-Host "2. Deploy your application package to App Service:"
Write-Host "   az webapp deployment source config-zip --resource-group $ResourceGroupName --name <app-service-name> --src app.zip"
Write-Host "3. Monitor application health in Application Insights"
Write-Host "4. Test the application at the deployed URL"
Write-Host ""

exit 0
