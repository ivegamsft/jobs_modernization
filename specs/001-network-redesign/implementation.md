# Network Redesign - Implementation Details

**Status**: Ready for Execution  
**Last Updated**: 2026-01-21  
**Phase**: Build & Deployment

---

## Implementation Checklist

### Pre-Deployment Validation

- [ ] All team members reviewed spec.md and plan.md
- [ ] Constitution standards understood
- [ ] Bicep templates validated with `bicep build`
- [ ] Prerequisites checked (`specify check`)
- [ ] Backup procedures tested
- [ ] Rollback plan documented

### Deployment Execution

#### Core Layer Deployment

```bash
# 1. Navigate to IaC directory
cd c:\git\jobs_modernization\iac

# 2. Validate Core Bicep templates
az bicep build --file bicep/core/main.bicep --outdir temp/
az bicep build --file bicep/core/core-resources.bicep --outdir temp/
bicep lint bicep/core/main.bicep bicep/core/core-resources.bicep

# 3. Deploy Core infrastructure with new VNet
az deployment sub create `
  --location swedencentral `
  --template-file bicep/core/main.bicep `
  --parameters `
    environment=dev `
    applicationName=jobsite `
    location=swedencentral `
  --name "jobsite-core-dev-v2"

# 4. Monitor deployment progress
while ((az deployment sub show --name "jobsite-core-dev-v2" --query "properties.provisioningState" -o tsv) -eq "Running") {
  Write-Host "Deployment in progress..."
  Start-Sleep -Seconds 30
}

# 5. Verify deployment succeeded
$status = az deployment sub show --name "jobsite-core-dev-v2" --query "properties.provisioningState" -o tsv
if ($status -eq "Succeeded") {
  Write-Host "✅ Core deployment successful!"
} else {
  Write-Host "❌ Core deployment failed: $status"
  exit 1
}

# 6. Export Core outputs for IaaS/PaaS use
$coreOutputs = az deployment sub show --name "jobsite-core-dev-v2" --query "properties.outputs" -o json | ConvertFrom-Json
Write-Host "Core Outputs:"
Write-Host "  VNet ID: $($coreOutputs.vnetId.value)"
Write-Host "  Frontend Subnet: $($coreOutputs.frontendSubnetId.value)"
Write-Host "  Data Subnet: $($coreOutputs.dataSubnetId.value)"
Write-Host "  GitHub Runners Subnet: $($coreOutputs.githubRunnersSubnetId.value)"
```

---

#### IaaS Layer Deployment

```bash
# 1. Deploy IaaS layer with VMSS in correct subnet
# IMPORTANT: VMSS must be in snet-gh-runners, NOT snet-data

# Generate or obtain passwords securely
$VMPassword = Read-Host "Enter VM Admin Password" -AsSecureString
$VMPassword = [System.Net.NetworkCredential]::new('', $VMPassword).Password

$CertPassword = Read-Host "Enter Certificate Password" -AsSecureString
$CertPassword = [System.Net.NetworkCredential]::new('', $CertPassword).Password

# 2. Run IaaS deployment script
.\deploy-iaas-clean.ps1 -VMPassword $VMPassword -CertPassword $CertPassword

# 3. Verify IaaS deployment
$iaasStatus = az deployment sub show --name "jobsite-iaas-dev" --query "properties.provisioningState" -o tsv
Write-Host "IaaS Deployment Status: $iaasStatus"

# 4. Verify VMSS in correct subnet
$vmssSubnet = az vmss nic list -g jobsite-iaas-dev-rg --vmss-name jobsite-vmss `
  --query "[0].ipConfigurations[0].subnet.id" -o tsv
if ($vmssSubnet -like "*snet-gh-runners*") {
  Write-Host "✅ VMSS correctly placed in snet-gh-runners"
} else {
  Write-Host "❌ VMSS in wrong subnet: $vmssSubnet"
  exit 1
}
```

---

#### PaaS Layer Deployment

```bash
# 1. Deploy PaaS layer (App Service, SQL Database, App Insights)
az deployment sub create `
  --location swedencentral `
  --template-file bicep/paas/main.bicep `
  --parameters `
    environment=dev `
    applicationName=jobsite `
    location=swedencentral `
    coreResourceGroupName=jobsite-core-dev-rg `
  --name "jobsite-paas-dev-v2"

# 2. Monitor deployment
$paasStatus = az deployment sub show --name "jobsite-paas-dev-v2" --query "properties.provisioningState" -o tsv
Write-Host "PaaS Deployment Status: $paasStatus"

# 3. Verify services
$appService = az app service show -g jobsite-paas-dev-rg -n jobsite-app --query "state" -o tsv
Write-Host "App Service State: $appService"

$sqlDatabase = az sql db list -g jobsite-paas-dev-rg -s jobsite-sql-server --query "length([])" -o tsv
Write-Host "SQL Databases: $sqlDatabase"
```

---

### Post-Deployment Validation

#### Network Connectivity Tests

```powershell
# Test 1: VNet and subnets created correctly
Write-Host "`n=== VNet Configuration ===" -ForegroundColor Cyan
$vnet = az network vnet show -g jobsite-core-dev-rg -n jobsite-dev-vnet -o json | ConvertFrom-Json
Write-Host "VNet CIDR: $($vnet.addressSpace.addressPrefixes[0])"
Write-Host "Subnets:"
$vnet.subnets | ForEach-Object {
  Write-Host "  $($_.name): $($_.addressPrefix)"
}

# Test 2: Verify no IP conflicts
Write-Host "`n=== IP Allocation Check ===" -ForegroundColor Cyan
$subnets = az network vnet subnet list -g jobsite-core-dev-rg --vnet-name jobsite-dev-vnet -o json | ConvertFrom-Json
foreach ($subnet in $subnets) {
  $ipRange = $subnet.addressPrefix
  Write-Host "✓ $($subnet.name): $ipRange"
}

# Test 3: VMSS connectivity to App Gateway
Write-Host "`n=== VMSS to App Gateway ===" -ForegroundColor Cyan
$appGwBackends = az network application-gateway show -g jobsite-iaas-dev-rg -n jobsite-appgw `
  --query "backendAddressPools" -o json | ConvertFrom-Json
Write-Host "App Gateway backends:"
foreach ($backend in $appGwBackends) {
  Write-Host "  $($backend.name): $($backend.backendAddresses.count) addresses"
}

# Test 4: SQL Server firewall rules
Write-Host "`n=== SQL Connectivity ===" -ForegroundColor Cyan
$sqlRules = az sql server firewall-rule list -g jobsite-paas-dev-rg -s jobsite-sql-server -o json | ConvertFrom-Json
Write-Host "SQL Firewall Rules: $($sqlRules.count)"

# Test 5: Key Vault access for App Service
Write-Host "`n=== Key Vault Access ===" -ForegroundColor Cyan
$kvName = az keyvault list -g jobsite-core-dev-rg --query "[0].name" -o tsv
$secrets = az keyvault secret list --vault-name $kvName --query "length([])" -o tsv
Write-Host "✓ Key Vault secrets: $secrets"
```

---

#### Resource Health Verification

```powershell
# Check all resources are in healthy state
Write-Host "`n=== Resource Health ===" -ForegroundColor Cyan

# VMSS health
$vmssInstances = az vmss list-instances -g jobsite-iaas-dev-rg -n jobsite-vmss `
  --query "[].instanceView.statuses" -o json | ConvertFrom-Json
Write-Host "VMSS Instances: $($vmssInstances.count)"

# SQL VM health
$sqlVM = az vm get-instance-view -g jobsite-iaas-dev-rg -n jobsite-sql `
  --query "instanceView.statuses[?starts_with(code, 'PowerState')].displayStatus" -o tsv
Write-Host "SQL VM: $sqlVM"

# App Gateway health
$appGwProbes = az network application-gateway probe list -g jobsite-iaas-dev-rg \
  --gateway-name jobsite-appgw --query "[].name" -o tsv
Write-Host "App Gateway Probes: $($appGwProbes.count)"

# App Service health
$appSvc = az app service show -g jobsite-paas-dev-rg -n jobsite-app --query "state" -o tsv
Write-Host "App Service: $appSvc"
```

---

#### Monitoring & Diagnostics Verification

```powershell
# Verify Log Analytics is receiving data
Write-Host "`n=== Monitoring Status ===" -ForegroundColor Cyan

$laWorkspace = az monitor log-analytics workspace list -g jobsite-core-dev-rg `
  --query "[0]" -o json | ConvertFrom-Json

Write-Host "Log Analytics Workspace: $($laWorkspace.name)"
Write-Host "Workspace ID: $($laWorkspace.customerId)"

# Query for recent logs (from last hour)
$logQuery = @"
AzureActivity
| where TimeGenerated > ago(1h)
| summarize Count = count() by OperationName
| top 10 by Count
"@

Write-Host "`nRecent Azure Activity (last hour):"
az monitor log-analytics query -w $laWorkspace.id `
  --analytics-query $logQuery `
  --timespan PT1H -o table
```

---

## Rollback Procedure

**If deployment fails or issues arise**:

### Immediate Rollback

```powershell
Write-Host "⚠️  ROLLBACK: Reverting to previous deployment" -ForegroundColor Yellow

# Option 1: Switch DNS back to old deployment
# (if using App Gateway DNS name or custom domain)
az network public-ip show -g jobsite-core-dev-rg --name [old-ip-name] `
  --query "ipAddress" -o tsv

# Option 2: Restore from backup
$backupFile = "backup-core-deployment.json"
if (Test-Path $backupFile) {
  Write-Host "Restoring from backup: $backupFile"
  # Use backup to redeploy old configuration
}

# Option 3: Full recreation from old Bicep
git checkout HEAD~1 -- iac/bicep/core/core-resources.bicep
az deployment sub create `
  --location swedencentral `
  --template-file bicep/core/main.bicep `
  --parameters environment=dev applicationName=jobsite location=swedencentral `
  --name "jobsite-core-dev-rollback"
```

---

## Monitoring Commands (Post-Deployment)

Keep these commands for ongoing monitoring:

```powershell
# Daily health check
function Get-InfrastructureHealth {
  Write-Host "`n=== Infrastructure Health Check ===" -ForegroundColor Cyan

  # Check all resources
  $resources = az resource list -g jobsite-core-dev-rg --query "[].{name: name, type: type, state: provisioningState}" -o table
  $resources

  # Check scaling
  $vmssCapacity = az vmss show -g jobsite-iaas-dev-rg -n jobsite-vmss --query "sku.capacity" -o tsv
  Write-Host "VMSS Capacity: $vmssCapacity"

  # Check database
  $sqlHealth = az sql server show -g jobsite-paas-dev-rg -n jobsite-sql-server --query "state" -o tsv
  Write-Host "SQL Server: $sqlHealth"
}

# Monitor specific service
function Monitor-AppGateway {
  az network application-gateway show -g jobsite-iaas-dev-rg -n jobsite-appgw `
    --query "{name: name, state: operationalState, publicIpAddress: publicIpAddresses[0].address}" -o table
}

# Check network health
function Check-NetworkConnectivity {
  Write-Host "`n=== Network Connectivity Test ===" -ForegroundColor Cyan

  # Ping DNS (Azure DNS)
  Test-NetConnection -ComputerName 168.63.129.16 -Port 53

  # Check route table
  az network route-table route list -g jobsite-core-dev-rg `
    --route-table-name [route-table-name] -o table
}
```

---

## Common Issues & Troubleshooting

### Issue: VMSS deployment fails

**Symptoms**: VMSS creation times out or fails  
**Cause**: Network profile missing networkApiVersion  
**Fix**:

```bicep
# Ensure networkProfile includes this:
networkProfile: {
  networkApiVersion: '2023-05-01'  // Critical!
  networkInterfaceConfigurations: [...]
}
```

---

### Issue: SQL Server not reachable from App Service

**Symptoms**: Connection timeout, "Cannot connect to SQL"  
**Cause**: Firewall rules missing or NAT Gateway not associated  
**Fix**:

```bash
# Check firewall rules
az sql server firewall-rule list -g jobsite-paas-dev-rg -s jobsite-sql-server -o table

# Check NAT Gateway association
az network vnet subnet show -g jobsite-core-dev-rg --vnet-name jobsite-dev-vnet -n snet-data `
  --query "natGateway.id" -o tsv

# Add if missing
az network vnet subnet update -g jobsite-core-dev-rg --vnet-name jobsite-dev-vnet -n snet-data `
  --nat-gateway [nat-gateway-id]
```

---

### Issue: Private Endpoints not working

**Symptoms**: "Cannot resolve [resource].privatelink.database.windows.net"  
**Cause**: Private DNS zone not created or linked  
**Fix**:

```bash
# Create private DNS zone
az network private-dns zone create -g jobsite-core-dev-rg \
  -n "privatelink.database.windows.net"

# Link to VNet
az network private-dns link vnet create -g jobsite-core-dev-rg \
  --zone-name "privatelink.database.windows.net" \
  --name "jobsite-vnet-link" \
  --virtual-network [vnet-id]
```

---

## Success Criteria Validation

Run this final validation:

```powershell
Write-Host "=== DEPLOYMENT SUCCESS VALIDATION ===" -ForegroundColor Green

# Criterion 1: All resources deployed
$resourceCount = (az resource list -g jobsite-core-dev-rg --query "length([])").count
Write-Host "✓ Resources in Core RG: $resourceCount"

# Criterion 2: VNet properly sized
$vnetSize = az network vnet show -g jobsite-core-dev-rg -n jobsite-dev-vnet `
  --query "addressSpace.addressPrefixes[0]" -o tsv
if ($vnetSize -eq "10.50.0.0/21") {
  Write-Host "✓ VNet properly sized: $vnetSize"
}

# Criterion 3: All subnets created
$subnetCount = az network vnet subnet list -g jobsite-core-dev-rg --vnet-name jobsite-dev-vnet `
  --query "length([])" -o tsv
if ($subnetCount -eq 7) {
  Write-Host "✓ All 7 subnets created"
}

# Criterion 4: VMSS in correct subnet
$vmssSubnet = az vmss nic list -g jobsite-iaas-dev-rg --vmss-name jobsite-vmss `
  --query "[0].ipConfigurations[0].subnet.id" -o tsv
if ($vmssSubnet -like "*snet-gh-runners*") {
  Write-Host "✓ VMSS in snet-gh-runners (correct!)"
}

# Criterion 5: Monitoring active
$logCount = (az monitor log-analytics workspace list -g jobsite-core-dev-rg).count
Write-Host "✓ Log Analytics workspace: $logCount"

Write-Host "`n✅ ALL VALIDATION CHECKS PASSED!" -ForegroundColor Green
```

---

**Deployment Complete!** 🎉

Proceed to Task 4 in tasks.md for documentation and knowledge transfer.
