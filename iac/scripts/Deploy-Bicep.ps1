# ============================================================================
# Bicep Deployment Script for Job Site Application - Full Automation
# ============================================================================
# This script deploys all infrastructure with zero user interaction required.
# Passwords and resource names are auto-generated but can be overridden.
# Resource groups are created by the Bicep templates.
#
# Usage:
#   ./Deploy-Bicep.ps1 -Environment dev
#   ./Deploy-Bicep.ps1 -Environment prod -Location westus2
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in to Azure (az login)
#   - Appropriate permissions in target subscription
# ============================================================================

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',

    [Parameter(Mandatory = $false)]
    [string]$Location = 'eastus',

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null,

    [Parameter(Mandatory = $false)]
    [string]$SqlAdminPassword = $null,

    [Parameter(Mandatory = $false)]
    [string]$VmAdminPassword = $null,

    [Parameter(Mandatory = $false)]
    [string]$AppGatewayCertPassword = $null,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCore = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SkipIaas = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPaas = $false,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$iacRoot = Split-Path -Parent $scriptRoot
$bicepRoot = Join-Path $iacRoot 'bicep'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "jobsite-certs-$timestamp"

New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Job Site Application - Automated Bicep Deployment" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Azure Authentication
# ============================================================================

Write-Host "🔑 Checking Azure authentication..." -ForegroundColor Yellow

$azContext = az account show --output json 2>$null | ConvertFrom-Json
if (-not $azContext) {
    Write-Host "❌ Not logged in to Azure. Please run: az login" -ForegroundColor Red
    exit 1
}

if ($SubscriptionId) {
    Write-Host "Setting subscription: $SubscriptionId" -ForegroundColor Gray
    az account set --subscription $SubscriptionId
    $azContext = az account show --output json | ConvertFrom-Json
}

Write-Host "✅ Authenticated as: $($azContext.user.name)" -ForegroundColor Green
Write-Host "   Subscription: $($azContext.name) ($($azContext.id))" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Auto-Generate Passwords
# ============================================================================

function New-SecurePassword {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = -join ((1..16) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $password
}

if (-not $SqlAdminPassword) {
    $SqlAdminPassword = New-SecurePassword
    Write-Host "🔐 Generated SQL Admin Password (save this securely!)" -ForegroundColor Yellow
    Write-Host "   Password: $SqlAdminPassword" -ForegroundColor Yellow
    Write-Host ""
}

if (-not $VmAdminPassword) {
    $VmAdminPassword = New-SecurePassword
    Write-Host "🔐 Generated VM Admin Password (save this securely!)" -ForegroundColor Yellow
    Write-Host "   Password: $VmAdminPassword" -ForegroundColor Yellow
    Write-Host ""
}

if (-not $AppGatewayCertPassword) {
    $AppGatewayCertPassword = New-SecurePassword
    Write-Host "🔐 Generated App Gateway Certificate Password" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Certificate Generation
# ============================================================================

Write-Host "📜 Generating self-signed certificates..." -ForegroundColor Yellow

# VPN Root Certificate (CER format → base64)
$vpnCertPath = Join-Path $tempPath "vpn-root.cer"
$vpnCert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=jobsite-vpn-root" `
    -KeySpec Signature `
    -KeyExportPolicy Exportable `
    -HashAlgorithm SHA256 `
    -KeyLength 2048 `
    -KeyUsageProperty Sign `
    -KeyUsage CertSign, CRLSign, DigitalSignature `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -NotAfter (Get-Date).AddYears(3)

Export-Certificate -Cert $vpnCert -FilePath $vpnCertPath -Type CERT | Out-Null
$vpnCertBytes = [System.IO.File]::ReadAllBytes($vpnCertPath)
$vpnRootCertBase64 = [Convert]::ToBase64String($vpnCertBytes)
Write-Host "✅ VPN Root Certificate generated" -ForegroundColor Green

# App Gateway Certificate (PFX format → base64)
$appGwCertPath = Join-Path $tempPath "appgw-cert.pfx"
$appGwCert = New-SelfSignedCertificate `
    -Subject "CN=jobsite-appgw" `
    -DnsName "*.jobsite.local", "jobsite.local" `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -NotAfter (Get-Date).AddYears(3) `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -HashAlgorithm SHA256

$certPassword = ConvertTo-SecureString -String $AppGatewayCertPassword -Force -AsPlainText
Export-PfxCertificate -Cert $appGwCert -FilePath $appGwCertPath -Password $certPassword | Out-Null
$appGwCertBytes = [System.IO.File]::ReadAllBytes($appGwCertPath)
$appGwCertBase64 = [Convert]::ToBase64String($appGwCertBytes)
Write-Host "✅ App Gateway Certificate generated" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Deploy Core Infrastructure
# ============================================================================

if (-not $SkipCore) {
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "DEPLOYING CORE INFRASTRUCTURE" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $coreDeploymentName = "jobsite-core-$Environment-$timestamp"
    $coreBicepPath = Join-Path $bicepRoot 'core\main.bicep'

    $coreParamsFile = Join-Path $tempPath "core-params.json"
    $coreParamsJson = @{
        '$schema'        = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        'contentVersion' = '1.0.0.0'
        'parameters'     = @{
            'environment'        = @{ 'value' = $Environment }
            'location'           = @{ 'value' = $Location }
            'sqlAdminPassword'   = @{ 'value' = $SqlAdminPassword }
            'vpnRootCertificate' = @{ 'value' = $vpnRootCertBase64 }
        }
    } | ConvertTo-Json -Depth 10
    
    [System.IO.File]::WriteAllText($coreParamsFile, $coreParamsJson)

    if ($WhatIf) {
        Write-Host "🔍 WHAT-IF: Would deploy core infrastructure" -ForegroundColor Yellow
    }
    else {
        Write-Host "🚀 Deploying core infrastructure..." -ForegroundColor Yellow
        $coreResult = az deployment sub create `
            --name $coreDeploymentName `
            --location $Location `
            --template-file $coreBicepPath `
            --parameters $coreParamsFile `
            --output json | ConvertFrom-Json

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Core deployment failed" -ForegroundColor Red
            exit 1
        }

        $coreOutputs = $coreResult.properties.outputs
        Write-Host "✅ Core infrastructure deployed successfully" -ForegroundColor Green
        Write-Host "   Resource Group: $($coreOutputs.resourceGroupName.value)" -ForegroundColor Green
        Write-Host "   VNet: $($coreOutputs.vnetName.value)" -ForegroundColor Green
        Write-Host "   Key Vault: $($coreOutputs.keyVaultName.value)" -ForegroundColor Green
        Write-Host ""
    }
}

# ============================================================================
# Deploy IAAS Infrastructure
# ============================================================================

if (-not $SkipIaas -and -not $WhatIf) {
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "DEPLOYING IAAS INFRASTRUCTURE" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $iaasDeploymentName = "jobsite-iaas-$Environment-$timestamp"
    $iaasBicepPath = Join-Path $bicepRoot 'iaas\main.bicep'

    $iaasParamsFile = Join-Path $tempPath "iaas-params.json"
    $iaasParamsJson = @{
        '$schema'        = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        'contentVersion' = '1.0.0.0'
        'parameters'     = @{
            'environment'             = @{ 'value' = $Environment }
            'location'                = @{ 'value' = $Location }
            'vnetId'                  = @{ 'value' = $coreOutputs.vnetId.value }
            'frontendSubnetId'        = @{ 'value' = $coreOutputs.frontendSubnetId.value }
            'dataSubnetId'            = @{ 'value' = $coreOutputs.dataSubnetId.value }
            'logAnalyticsWorkspaceId' = @{ 'value' = $coreOutputs.logAnalyticsWorkspaceId.value }
            'adminPassword'           = @{ 'value' = $VmAdminPassword }
            'appGatewayCertData'      = @{ 'value' = $appGwCertBase64 }
            'appGatewayCertPassword'  = @{ 'value' = $AppGatewayCertPassword }
        }
    } | ConvertTo-Json -Depth 10
    
    [System.IO.File]::WriteAllText($iaasParamsFile, $iaasParamsJson)

    Write-Host "🚀 Deploying IAAS infrastructure..." -ForegroundColor Yellow
    $iaasResult = az deployment sub create `
        --name $iaasDeploymentName `
        --location $Location `
        --template-file $iaasBicepPath `
        --parameters $iaasParamsFile `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ IAAS deployment failed" -ForegroundColor Red
        exit 1
    }

    $iaasOutputs = $iaasResult.properties.outputs
    Write-Host "✅ IAAS infrastructure deployed successfully" -ForegroundColor Green
    Write-Host "   Resource Group: $($iaasOutputs.resourceGroupName.value)" -ForegroundColor Green
    Write-Host "   VMSS: $($iaasOutputs.vmssName.value)" -ForegroundColor Green
    Write-Host "   SQL VM: $($iaasOutputs.sqlVmName.value)" -ForegroundColor Green
    Write-Host "   App Gateway IP: $($iaasOutputs.appGatewayPublicIp.value)" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# Deploy PAAS Infrastructure
# ============================================================================

if (-not $SkipPaas -and -not $WhatIf) {
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "DEPLOYING PAAS INFRASTRUCTURE" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $paasDeploymentName = "jobsite-paas-$Environment-$timestamp"
    $paasBicepPath = Join-Path $bicepRoot 'paas\main.bicep'

    $paasParamsFile = Join-Path $tempPath "paas-params.json"
    $paasParamsJson = @{
        '$schema'        = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        'contentVersion' = '1.0.0.0'
        'parameters'     = @{
            'environment'             = @{ 'value' = $Environment }
            'location'                = @{ 'value' = $Location }
            'sqlAdminPassword'        = @{ 'value' = $SqlAdminPassword }
            'peSubnetId'              = @{ 'value' = $coreOutputs.peSubnetId.value }
            'keyVaultName'            = @{ 'value' = $coreOutputs.keyVaultName.value }
            'logAnalyticsWorkspaceId' = @{ 'value' = $coreOutputs.logAnalyticsWorkspaceId.value }
        }
    } | ConvertTo-Json -Depth 10
    
    [System.IO.File]::WriteAllText($paasParamsFile, $paasParamsJson)

    Write-Host "🚀 Deploying PAAS infrastructure..." -ForegroundColor Yellow
    $paasResult = az deployment sub create `
        --name $paasDeploymentName `
        --location $Location `
        --template-file $paasBicepPath `
        --parameters $paasParamsFile `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ PAAS deployment failed" -ForegroundColor Red
        exit 1
    }

    $paasOutputs = $paasResult.properties.outputs
    Write-Host "✅ PAAS infrastructure deployed successfully" -ForegroundColor Green
    Write-Host "   Resource Group: $($paasOutputs.resourceGroupName.value)" -ForegroundColor Green
    Write-Host "   App Service: $($paasOutputs.appServiceName.value)" -ForegroundColor Green
    Write-Host "   SQL Server: $($paasOutputs.sqlServerName.value)" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# Cleanup
# ============================================================================

Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📝 SAVE THESE CREDENTIALS SECURELY:" -ForegroundColor Yellow
Write-Host "   SQL Admin Password: $SqlAdminPassword" -ForegroundColor Yellow
Write-Host "   VM Admin Password: $VmAdminPassword" -ForegroundColor Yellow
Write-Host "   App Gateway Cert Password: $AppGatewayCertPassword" -ForegroundColor Yellow
Write-Host ""
