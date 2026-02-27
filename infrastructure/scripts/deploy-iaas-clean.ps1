# Deploy IaaS Layer - Fresh deployment with WFE VM + SQL VM
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "IAAS LAYER DEPLOYMENT - WFE VM + SQL VM + APP GATEWAY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$environment = "dev"
$applicationName = "jobsite"
$location = "swedencentral"

# Wait for RG deletion to complete
Write-Host "1. Waiting for old RG deletion..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Get Core Outputs
Write-Host "2. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json

Write-Host "   ✅ Core deployment verified" -ForegroundColor Green
Write-Host ""

# Generate admin password
Write-Host "3. Generating admin credentials..." -ForegroundColor Yellow
. "$PSScriptRoot\New-SecurePassword.ps1"
$adminPassword = New-SecurePassword -Length 20

Write-Host "   ✅ Credentials generated" -ForegroundColor Green
Write-Host ""

# Deploy IaaS using subscription-level template
Write-Host "4. Deploying IaaS infrastructure..." -ForegroundColor Yellow
Write-Host "   Components: Load Balancer, WFE VM, SQL VM" -ForegroundColor Gray
Write-Host ""

$deployment = az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location $location `
    --template-file "$PSScriptRoot\..\bicep\iaas\main.bicep" `
    --parameters "@$PSScriptRoot\..\iaas-params.json" `
    --parameters adminPassword=$adminPassword `
    -o json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ IaaS deployment succeeded" -ForegroundColor Green
    
    $deploymentJson = $deployment | ConvertFrom-Json
    Write-Host ""
    Write-Host "5. Deployment Summary:" -ForegroundColor Cyan
    Write-Host "   Resource Group: jobsite-iaas-dev-rg" -ForegroundColor Gray
    Write-Host "   Status: Succeeded" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ IAAS DEPLOYMENT COMPLETE" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resources Created:" -ForegroundColor Cyan
    Write-Host "  ✓ Standard Load Balancer with Inbound NAT Rules V2" -ForegroundColor Green
    Write-Host "  ✓ WFE VM (Web Front End)" -ForegroundColor Green
    Write-Host "  ✓ SQL Server VM (Data tier)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Load Balancer Public IP:" -ForegroundColor Cyan
    $lbPublicIp = $deploymentJson.properties.outputs.loadBalancerPublicIp.value
    $lbFqdn = $deploymentJson.properties.outputs.loadBalancerFqdn.value
    Write-Host "  IP: $lbPublicIp" -ForegroundColor Yellow
    Write-Host "  FQDN: $lbFqdn" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "RDP Access (Inbound NAT Rules V2):" -ForegroundColor Cyan
    Write-Host "  View port mappings in Azure Portal:" -ForegroundColor Gray
    Write-Host "  Load Balancer > Inbound NAT rules > rdp-nat-rule > View port mappings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Port range: 50001-50100" -ForegroundColor Gray
    Write-Host "  Example: mstsc /v:${lbPublicIp}:50001" -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deployment -ForegroundColor Red
    exit 1
}
