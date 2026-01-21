# Quick deployment status check
$ErrorActionPreference = 'Continue'

Write-Host "Checking deployment status..." -ForegroundColor Cyan
Write-Host ""

# Check Core
Write-Host "Core Infrastructure:" -ForegroundColor Yellow
az deployment sub show --name "jobsite-core-dev" --query "properties.provisioningState" -o tsv 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Status: $(az deployment sub show --name 'jobsite-core-dev' --query 'properties.provisioningState' -o tsv)" -ForegroundColor Green
}
Write-Host ""

# Check IAAS
Write-Host "IAAS Infrastructure:" -ForegroundColor Yellow
$iaasState = az deployment sub show --name "jobsite-iaas-dev" --query "properties.provisioningState" -o tsv 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Status: $iaasState" -ForegroundColor $(if ($iaasState -eq "Running") { "Yellow" } else { "Green" })
}
else {
    Write-Host "  Status: Not started" -ForegroundColor Gray
}
Write-Host ""

# Check PaaS
Write-Host "PaaS Infrastructure:" -ForegroundColor Yellow
$paasState = az deployment sub show --name "jobsite-paas-dev" --query "properties.provisioningState" -o tsv 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Status: $paasState" -ForegroundColor $(if ($paasState -eq "Running") { "Yellow" } else { "Green" })
}
else {
    Write-Host "  Status: Not started" -ForegroundColor Gray
}
Write-Host ""

# Check Resource Groups
Write-Host "Resource Groups:" -ForegroundColor Yellow
az group list --query "[?starts_with(name, 'jobsite')].{Name:name, State:properties.provisioningState}" -o table
