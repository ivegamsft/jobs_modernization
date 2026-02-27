#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Creates inbound NAT rules on the NAT Gateway for RDP access to IaaS VMs
.DESCRIPTION
  Adds port mappings to the NAT Gateway:
  - Port 13389 -> Web VM:3389 (RDP)
  - Port 23389 -> SQL VM:3389 (RDP)
#>

param(
    [string]$ResourceGroup = 'jobsite-core-dev-rg',
    [string]$NatGatewayName = 'jobsite-dev-nat-ubzfsgu4p5eli',
    [string]$WebVmName = '',  # Optional - will look up from IaaS RG
    [string]$SqlVmName = '',  # Optional - will look up from IaaS RG
    [string]$IaaSResourceGroup = 'jobsite-iaas-dev-rg'
)

Write-Host "================================"
Write-Host "Creating NAT Gateway Inbound Rules"
Write-Host "================================"

# If VM names not provided, look them up from IaaS RG
if (-not $WebVmName -or -not $SqlVmName) {
    Write-Host "Looking up VM names from $IaaSResourceGroup..."
    $vms = az vm list -g $IaaSResourceGroup --query "[].{name: name, id: id}" -o json | ConvertFrom-Json
  
    if (-not $WebVmName) {
        $WebVmName = ($vms | Where-Object { $_.name -like '*-wfe-*' }).name
        Write-Host "  Web VM: $WebVmName"
    }
  
    if (-not $SqlVmName) {
        $SqlVmName = ($vms | Where-Object { $_.name -like '*-sqlvm-*' }).name
        Write-Host "  SQL VM: $SqlVmName"
    }
}

$natGw = az network nat gateway show -g $ResourceGroup -n $NatGatewayName -o json | ConvertFrom-Json
Write-Host "NAT Gateway: $($natGw.name)"
Write-Host "Public IP: $($natGw.publicIpAddresses[0].id | Split-Path -Leaf)"
Write-Host ""

# Create inbound NAT rule for Web VM
Write-Host "Creating inbound NAT rule: rdp-wfe (13389 -> 3389)"
az network nat gateway inbound-rule create `
    -g $ResourceGroup `
    -n $NatGatewayName `
    --inbound-rule-name rdp-wfe `
    --frontend-port 13389 `
    --backend-port 3389 `
    --protocol tcp `
    -o none 2>/dev/null

if ($?) {
    Write-Host "✓ Created rdp-wfe inbound rule"
}
else {
    Write-Host "⚠ Rule may already exist or error occurred"
}

# Create inbound NAT rule for SQL VM
Write-Host "Creating inbound NAT rule: rdp-sqlvm (23389 -> 3389)"
az network nat gateway inbound-rule create `
    -g $ResourceGroup `
    -n $NatGatewayName `
    --inbound-rule-name rdp-sqlvm `
    --frontend-port 23389 `
    --backend-port 3389 `
    --protocol tcp `
    -o none 2>/dev/null

if ($?) {
    Write-Host "✓ Created rdp-sqlvm inbound rule"
}
else {
    Write-Host "⚠ Rule may already exist or error occurred"
}

Write-Host ""
Write-Host "NAT Gateway Inbound Rules Summary:"
Write-Host "===================================="
az network nat gateway inbound-rule list -g $ResourceGroup -n $NatGatewayName --query "[].{Name: name, FrontendPort: frontendPort, BackendPort: backendPort, Protocol: protocol}" -o table
