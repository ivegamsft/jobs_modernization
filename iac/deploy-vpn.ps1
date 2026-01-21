# Deploy VPN Gateway (takes 30-45 minutes)

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "VPN GATEWAY DEPLOYMENT SCRIPT" -ForegroundColor Cyan
Write-Host "WARNING: This deployment takes 30-45 minutes to complete" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$environment = "dev"
$applicationName = "jobsite"
$location = "westus"
$vpnClientAddressPool = "172.16.0.0/24"

# Optional: VPN Root Certificate (Base64 encoded certificate data without headers)
$vpnRootCertificate = ""

Write-Host "Deploying VPN Gateway to: ${applicationName}-core-${environment}-rg" -ForegroundColor Yellow
Write-Host "Location: $location" -ForegroundColor Gray
Write-Host ""

# Confirm before starting long-running deployment
$confirmation = Read-Host "This will take 30-45 minutes. Continue? (y/N)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

Set-Location "c:\git\jobs_modernization\iac\bicep\core"

$deploymentParams = @(
    "--name", "jobsite-vpn-gateway-dev"
    "--location", $location
    "--template-file", "deploy-vpn.bicep"
    "--parameters", "environment=$environment"
    "--parameters", "applicationName=$applicationName"
    "--parameters", "location=$location"
    "--parameters", "vpnClientAddressPool=$vpnClientAddressPool"
)

if ($vpnRootCertificate -ne "") {
    $deploymentParams += "--parameters"
    $deploymentParams += "vpnRootCertificate=$vpnRootCertificate"
}

Write-Host "Starting VPN Gateway deployment at $(Get-Date -Format 'HH:mm:ss')..." -ForegroundColor Yellow
Write-Host ""

az deployment sub create @deploymentParams

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ VPN Gateway deployment completed at $(Get-Date -Format 'HH:mm:ss')!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "❌ VPN Gateway deployment failed" -ForegroundColor Red
    exit 1
}
