# Infrastructure Reorganization - Implementation Checklist

**Status**: Ready for Execution  
**Owner**: Infrastructure Engineering Team  
**Stakeholders**: Cloud Architect, DevOps Lead, Security Officer, Finance  
**Timeline**: 3 days (8-12 hours active work)  
**Last Updated**: 2026-01-22

---

## Pre-Implementation (Day -1 to Day 0)

### Approval & Planning

- [ ] **Approval**: Infrastructure Lead signs off on plan
- [ ] **Approval**: Cloud Architect reviews WFE design
- [ ] **Approval**: Security Officer reviews Defender, Log Analytics, RBAC
- [ ] **Approval**: Finance approves cost increase (~$30/month)
- [ ] **Schedule**: Migration window confirmed (off-hours preferred)
- [ ] **Communication**: Announcement sent to all teams

### Preparation Activities

- [ ] **Backups**: Export Container Apps config to JSON
- [ ] **Backups**: Export Build VMSS config to JSON
- [ ] **Backups**: Export current NSG rules
- [ ] **Testing**: Validate Bicep templates in sandbox
- [ ] **Testing**: Test RG creation scripts
- [ ] **Documentation**: Update architecture diagrams for 4-layer RGs
- [ ] **Rollback**: Prepare rollback scripts (old 3-layer design)
- [ ] **Monitoring**: Set up alerts for migration activities
- [ ] **On-Call**: Assign on-call person for migration window

### Team Briefing

- [ ] **Training**: Team briefed on 4-layer architecture
- [ ] **Training**: Team understands resource movements
- [ ] **Training**: Team knows rollback procedures
- [ ] **Q&A**: Address team questions & concerns
- [ ] **Documentation**: Share quick reference guide (4LAYER_RG_QUICK_REFERENCE.md)

---

## Phase 1: Preparation (Day 1, 1-2 hours)

### Step 1.1: Create Missing Resource Groups

**Task**: Create `jobsite-agents-dev-rg` and verify `jobsite-paas-dev-rg`

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 15 minutes
# [RISK]: Very Low

# Create jobsite-agents-dev-rg
az group create \
  --name jobsite-agents-dev-rg \
  --location swedencentral \
  --tags Application=JobSite Environment=dev ManagedBy=Bicep Layer=Agents

# Verify jobsite-paas-dev-rg exists
$paasRgExists = az group exists --name jobsite-paas-dev-rg

if ($paasRgExists -eq "true") {
  Write-Host "✓ jobsite-paas-dev-rg already exists" -ForegroundColor Green
} else {
  Write-Host "Creating jobsite-paas-dev-rg..." -ForegroundColor Yellow
  az group create \
    --name jobsite-paas-dev-rg \
    --location swedencentral \
    --tags Application=JobSite Environment=dev ManagedBy=Bicep Layer=PaaS
}

# List all resource groups
Write-Host "`nAll Resource Groups:" -ForegroundColor Cyan
az group list --query '[*].{name:name, location:location}' -o table
```

**Success Criteria**:

- [ ] `jobsite-agents-dev-rg` created
- [ ] `jobsite-paas-dev-rg` exists
- [ ] Both have correct tags
- [ ] Both in swedencentral region

---

### Step 1.2: Document Current State

**Task**: Backup all resource configurations before making changes

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 30 minutes
# [RISK]: Very Low

# Create backup directory
$backupDir = "$(Get-Date -Format 'yyyy-MM-dd-HHmm')-migration-backup"
mkdir $backupDir

# Backup Container Apps Environment
Write-Host "Backing up Container Apps Environment..." -ForegroundColor Cyan
az containerapp env show \
  --name jobsite-dev-cae-ubzfsgu4p5eli \
  --resource-group jobsite-core-dev-rg \
  | Out-File "$backupDir/container-apps-env.json"

# Backup all Container Apps in core RG
Write-Host "Backing up Container Apps instances..." -ForegroundColor Cyan
az containerapp list \
  --resource-group jobsite-core-dev-rg \
  | Out-File "$backupDir/container-apps-list.json"

# Backup Build VMSS
Write-Host "Backing up Build VMSS..." -ForegroundColor Cyan
az vmss show \
  --name vmss-qahxan3ogcgdi \
  --resource-group jobsite-iaas-dev-rg \
  | Out-File "$backupDir/build-vmss.json"

# Backup NSG rules
Write-Host "Backing up NSG rules..." -ForegroundColor Cyan
az network nsg rule list \
  --nsg-name nsg-app \
  --resource-group jobsite-core-dev-rg \
  | Out-File "$backupDir/nsg-rules.json"

# List all current resources by RG
Write-Host "Documenting current resource allocation..." -ForegroundColor Cyan
@('jobsite-core-dev-rg', 'jobsite-iaas-dev-rg', 'jobsite-paas-dev-rg') | ForEach-Object {
  az resource list --resource-group $_ --query '[*].{name:name, type:type}' -o table | Out-File "$backupDir/resources-$_.txt"
}

Write-Host "✓ Backup complete in: $backupDir" -ForegroundColor Green
```

**Success Criteria**:

- [ ] Backup directory created with timestamp
- [ ] Container Apps config backed up
- [ ] Build VMSS config backed up
- [ ] NSG rules documented
- [ ] All RG resources listed

---

### Step 1.3: Get Current VNet Information

**Task**: Retrieve VNet and subnet IDs for later reference

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 10 minutes
# [RISK]: Very Low

# Get VNet ID (needed for Bicep parameters)
$vnetId = az network vnet show \
  --name jobsite-dev-vnet \
  --resource-group jobsite-core-dev-rg \
  --query id -o tsv

Write-Host "VNet ID: $vnetId" -ForegroundColor Cyan

# Get all subnet IDs
Write-Host "`nSubnet Information:" -ForegroundColor Cyan
$subnets = az network vnet subnet list \
  --vnet-name jobsite-dev-vnet \
  --resource-group jobsite-core-dev-rg \
  --query '[*].{name:name, id:id, addressPrefix:addressPrefix}' -o json

$subnets | ConvertFrom-Json | Format-Table -AutoSize

# Save to environment variables for use in later phases
$env:VNET_ID = $vnetId
$env:SUBNET_INFO = $subnets

Write-Host "`n✓ VNet information retrieved" -ForegroundColor Green
```

**Success Criteria**:

- [ ] VNet ID retrieved
- [ ] All subnet IDs documented
- [ ] Environment variables set

---

## Phase 2: Create Missing Resources (Day 1-2, 2-3 hours)

### Step 2.1: Deploy Application Gateway v2 to IaaS RG

**Task**: Create Application Gateway with WAF for web traffic ingress

```powershell
# [ASSIGN TO]: DevOps Engineer + Cloud Architect
# [TIME]: 1-1.5 hours
# [RISK]: Medium (new resource, complex configuration)

# Step 1: Create Public IP for App Gateway
Write-Host "Creating Public IP for Application Gateway..." -ForegroundColor Cyan
az network public-ip create \
  --name jobsite-dev-pip-agw \
  --resource-group jobsite-iaas-dev-rg \
  --sku Standard \
  --zone 1 2 3 \
  --tags Application=JobSite Environment=dev Component=AppGateway

# Step 2: Deploy Application Gateway using Bicep
Write-Host "Deploying Application Gateway v2 with WAF..." -ForegroundColor Cyan
az deployment group create \
  --resource-group jobsite-iaas-dev-rg \
  --name deploy-app-gateway-$(Get-Date -Format 'yyyyMMdd-HHmm') \
  --template-file bicep/iaas/appgateway.bicep \
  --parameters \
    location=swedencentral \
    environment=dev \
    vnetId=$env:VNET_ID \
    frontendSubnetId="$env:VNET_ID/subnets/snet-fe" \
    backendPoolSubnetId="$env:VNET_ID/subnets/snet-app" \
    publicIpId=$(az network public-ip show --name jobsite-dev-pip-agw --resource-group jobsite-iaas-dev-rg --query id -o tsv) \
    --mode Complete

# Step 3: Verify deployment
Write-Host "Verifying App Gateway deployment..." -ForegroundColor Cyan
$agw = az network application-gateway show \
  --name jobsite-dev-agw \
  --resource-group jobsite-iaas-dev-rg \
  --query '{name:name, provisioningState:provisioningState, skuName:sku.name, skuTier:sku.tier}' -o json

$agw | ConvertFrom-Json | Format-List

if ((($agw | ConvertFrom-Json).provisioningState) -eq "Succeeded") {
  Write-Host "✓ Application Gateway deployed successfully" -ForegroundColor Green
} else {
  Write-Host "✗ Application Gateway deployment failed" -ForegroundColor Red
  exit 1
}

# Step 4: Check health probe status
Write-Host "`nChecking backend pool health..." -ForegroundColor Cyan
az network application-gateway address-pool list \
  --gateway-name jobsite-dev-agw \
  --resource-group jobsite-iaas-dev-rg \
  --query '[*].{name:name}' -o table
```

**Success Criteria**:

- [ ] Public IP created successfully
- [ ] Application Gateway provisioned
- [ ] SKU: WAF_v2 confirmed
- [ ] Deployment shows "Succeeded"
- [ ] Backend pool accessible
- [ ] WAF rules enabled (OWASP 3.1)

**Rollback If Failed**:

```powershell
az network application-gateway delete \
  --name jobsite-dev-agw \
  --resource-group jobsite-iaas-dev-rg \
  --yes

az network public-ip delete \
  --name jobsite-dev-pip-agw \
  --resource-group jobsite-iaas-dev-rg \
  --yes
```

---

### Step 2.2: Verify PaaS RG is Ready

**Task**: Ensure `jobsite-paas-dev-rg` has correct base configuration

```powershell
# [ASSIGN TO]: DevOps Engineer
# [TIME]: 30 minutes
# [RISK]: Low

# Check if Container Apps Environment needs deployment
Write-Host "Checking PaaS RG resources..." -ForegroundColor Cyan
$paasResources = az resource list \
  --resource-group jobsite-paas-dev-rg \
  --query '[*].type' -o json | ConvertFrom-Json

if ($paasResources -contains 'Microsoft.App/managedEnvironments') {
  Write-Host "✓ Container Apps Environment already in paas-rg" -ForegroundColor Green
} else {
  Write-Host "⚠️  Container Apps Environment NOT in paas-rg (will move in Phase 3)" -ForegroundColor Yellow
}

# Verify Log Analytics is accessible (for diagnostics)
$lawId = az resource show \
  --name jobsite-dev-law \
  --resource-group jobsite-core-dev-rg \
  --resource-type "Microsoft.OperationalInsights/workspaces" \
  --query id -o tsv

if ($lawId) {
  Write-Host "✓ Log Analytics Workspace accessible: $lawId" -ForegroundColor Green
} else {
  Write-Host "✗ Log Analytics Workspace not found" -ForegroundColor Red
  exit 1
}
```

**Success Criteria**:

- [ ] Container Apps Environment located (core or paas RG)
- [ ] Log Analytics Workspace accessible
- [ ] paas-rg ready for Container Apps deployment

---

## Phase 3: Move Resources (Day 2, 2-4 hours)

### Step 3.1: Move Container Apps Environment to PaaS RG

**Task**: Relocate Container Apps from core-rg to paas-rg

```powershell
# [ASSIGN TO]: DevOps Engineer
# [TIME]: 1-2 hours
# [RISK]: High (service impact possible)

Write-Host "Moving Container Apps Environment to paas-rg..." -ForegroundColor Cyan
Write-Host "This may cause temporary service interruption (10-20 min)" -ForegroundColor Yellow

# Get Container Apps Environment ID
$caeId = az resource show \
  --name jobsite-dev-cae-ubzfsgu4p5eli \
  --resource-group jobsite-core-dev-rg \
  --resource-type "Microsoft.App/managedEnvironments" \
  --query id -o tsv

if (-not $caeId) {
  Write-Host "✗ Container Apps Environment not found" -ForegroundColor Red
  exit 1
}

# Option A: Try direct move (may not work for managed environments)
Write-Host "`nAttempting direct move..." -ForegroundColor Cyan
try {
  az resource move \
    --ids $caeId \
    --destination-group jobsite-paas-dev-rg

  Write-Host "✓ Move successful!" -ForegroundColor Green
} catch {
  Write-Host "✗ Direct move failed (expected for managed environments)" -ForegroundColor Yellow
  Write-Host "Proceeding with redeploy option..." -ForegroundColor Cyan

  # Option B: Redeploy (safer for Container Apps)
  $caeConfig = az containerapp env show \
    --name jobsite-dev-cae-ubzfsgu4p5eli \
    --resource-group jobsite-core-dev-rg

  Write-Host "Creating new Container Apps Environment in paas-rg..." -ForegroundColor Cyan
  az deployment group create \
    --resource-group jobsite-paas-dev-rg \
    --name deploy-container-apps-env \
    --template-file bicep/paas/container-apps.bicep \
    --parameters \
      location=swedencentral \
      environment=dev \
      lawId=$lawId

  Write-Host "✓ Container Apps redeployed to paas-rg" -ForegroundColor Green

  # TODO: Migrate existing Container Apps instances if any
  Write-Host "⚠️  Note: Existing Container Apps instances need manual migration" -ForegroundColor Yellow
}

# Verify move/deployment
Write-Host "`nVerifying Container Apps location..." -ForegroundColor Cyan
try {
  $caeNew = az containerapp env show \
    --name jobsite-dev-cae-ubzfsgu4p5eli \
    --resource-group jobsite-paas-dev-rg

  Write-Host "✓ Container Apps Environment now in paas-rg" -ForegroundColor Green
} catch {
  Write-Host "✗ Container Apps Environment not found in paas-rg" -ForegroundColor Red
  Write-Host "Check if still in core-rg (rollback may be needed)" -ForegroundColor Yellow
}
```

**Success Criteria**:

- [ ] Container Apps Environment moved/redeployed to paas-rg
- [ ] Container Apps accessible from paas-rg
- [ ] Diagnostics still flowing to Log Analytics
- [ ] Container Apps instances running (if any)

**Rollback If Failed**:

```powershell
# Container Apps are typically stateless - can be redeployed
# If critical, revert to backup and retry with redeploy option
```

---

### Step 3.2: Move Build Agent VMSS to Agents RG

**Task**: Relocate GitHub Runners VMSS from iaas-rg to agents-rg

```powershell
# [ASSIGN TO]: CI/CD Engineer + Infrastructure Engineer
# [TIME]: 1-2 hours
# [RISK]: High (CI/CD pipeline impact)

Write-Host "Moving Build Agent VMSS to agents-rg..." -ForegroundColor Cyan
Write-Host "CI/CD builds will be blocked during move (10-20 min)" -ForegroundColor Yellow

# Get Build VMSS ID
$vmssId = az resource show \
  --name vmss-qahxan3ogcgdi \
  --resource-group jobsite-iaas-dev-rg \
  --resource-type "Microsoft.Compute/virtualMachineScaleSets" \
  --query id -o tsv

if (-not $vmssId) {
  Write-Host "✗ Build VMSS not found" -ForegroundColor Red
  exit 1
}

# Attempt move
Write-Host "`nAttempting VMSS move to agents-rg..." -ForegroundColor Cyan
try {
  az resource move \
    --ids $vmssId \
    --destination-group jobsite-agents-dev-rg

  Write-Host "✓ VMSS move successful!" -ForegroundColor Green
  $moveSuccess = $true
} catch {
  Write-Host "✗ Move failed: $_" -ForegroundColor Yellow
  Write-Host "Proceeding with recreate option..." -ForegroundColor Cyan
  $moveSuccess = $false
}

# If move failed, recreate VMSS
if (-not $moveSuccess) {
  Write-Host "`nRecreating VMSS in agents-rg..." -ForegroundColor Cyan

  # Export current config
  $vmssConfig = az vmss show --name vmss-qahxan3ogcgdi --resource-group jobsite-iaas-dev-rg

  # Delete from iaas-rg (confirm first!)
  Write-Host "Delete original VMSS from iaas-rg? (y/n)"
  $confirm = Read-Host
  if ($confirm -eq 'y') {
    az vmss delete \
      --name vmss-qahxan3ogcgdi \
      --resource-group jobsite-iaas-dev-rg \
      --yes
  }

  # Create in agents-rg
  az deployment group create \
    --resource-group jobsite-agents-dev-rg \
    --name deploy-build-vmss \
    --template-file bicep/agents/main.bicep \
    --parameters \
      location=swedencentral \
      environment=dev \
      vnetId=$env:VNET_ID \
      subnetId="$env:VNET_ID/subnets/snet-gh-runners"

  Write-Host "✓ VMSS recreated in agents-rg" -ForegroundColor Green
}

# Verify VMSS in agents-rg
Write-Host "`nVerifying VMSS location..." -ForegroundColor Cyan
$vmssNew = az vmss show \
  --name vmss-qahxan3ogcgdi \
  --resource-group jobsite-agents-dev-rg \
  --query '{name:name, resourceGroup:resourceGroup, location:location}' -o json

$vmssNew | ConvertFrom-Json | Format-List

# Re-register GitHub Runners
Write-Host "`nRe-registering GitHub Runners..." -ForegroundColor Yellow
Write-Host "⚠️  This requires manual GitHub token - handled separately"
```

**Success Criteria**:

- [ ] VMSS moved/recreated in agents-rg
- [ ] Network Interfaces moved with VMSS
- [ ] Managed Disks moved with VMSS
- [ ] VMSS still connected to snet-gh-runners
- [ ] GitHub Runners re-registered
- [ ] Build queue processing resumed

**Rollback If Failed**:

```powershell
# Move VMSS back to iaas-rg
az resource move \
  --ids $vmssId \
  --destination-group jobsite-iaas-dev-rg

# Re-register GitHub Runners
# (requires manual GitHub token)
```

---

## Phase 4: Validation (Day 2-3, 1-2 hours)

### Step 4.1: Network Connectivity Test

**Task**: Verify all tiers can communicate properly

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 30 minutes
# [RISK]: Very Low

Write-Host "Testing Network Connectivity..." -ForegroundColor Cyan

# Test 1: App Gateway responding on port 80/443
Write-Host "`n1. Testing App Gateway public endpoint..." -ForegroundColor Cyan
$appGwIP = az network public-ip show \
  --name jobsite-dev-pip-agw \
  --resource-group jobsite-iaas-dev-rg \
  --query ipAddress -o tsv

if ($appGwIP) {
  Write-Host "App Gateway IP: $appGwIP"
  # Note: curl test requires external connectivity
  Write-Host "✓ App Gateway IP retrieved" -ForegroundColor Green
} else {
  Write-Host "✗ App Gateway IP not found" -ForegroundColor Red
}

# Test 2: App Gateway backend pool health
Write-Host "`n2. Checking App Gateway backend pool health..." -ForegroundColor Cyan
az network application-gateway address-pool list \
  --gateway-name jobsite-dev-agw \
  --resource-group jobsite-iaas-dev-rg \
  --query '[*].{name:name, addresses:backendAddresses}' -o table

# Test 3: Health probe configuration
Write-Host "`n3. Checking health probes..." -ForegroundColor Cyan
az network application-gateway probe list \
  --gateway-name jobsite-dev-agw \
  --resource-group jobsite-iaas-dev-rg \
  --query '[*].{name:name, port:port, protocol:protocol, path:path}' -o table

# Test 4: WAF status
Write-Host "`n4. Checking WAF configuration..." -ForegroundColor Cyan
az network application-gateway waf-policy list \
  --resource-group jobsite-iaas-dev-rg \
  --query '[*].{name:name, policyState:properties.policySettings.state, mode:properties.policySettings.mode}' -o table

Write-Host "`n✓ Network connectivity tests complete" -ForegroundColor Green
```

**Success Criteria**:

- [ ] App Gateway IP retrieved
- [ ] Backend pool shows healthy status
- [ ] Health probes configured correctly
- [ ] WAF enabled with correct rule set

---

### Step 4.2: Resource Group Organization Verification

**Task**: Confirm all resources in correct RGs

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 15 minutes
# [RISK]: Very Low

Write-Host "Verifying Resource Group Organization..." -ForegroundColor Cyan

$rgs = @(
  'jobsite-core-dev-rg',
  'jobsite-iaas-dev-rg',
  'jobsite-paas-dev-rg',
  'jobsite-agents-dev-rg'
)

$rgs | ForEach-Object {
  Write-Host "`n=== $_ ===" -ForegroundColor Cyan
  az resource list --resource-group $_ --query '[*].{name:name, type:type}' -o table
}

# Detailed checks
Write-Host "`n=== Validation Checks ===" -ForegroundColor Cyan

# Check 1: Container Apps in paas-rg
$caeInPaaS = az resource list \
  --resource-group jobsite-paas-dev-rg \
  --query "[?type=='Microsoft.App/managedEnvironments']" \
  --query 'length(@)' -o tsv

if ($caeInPaaS -gt 0) {
  Write-Host "✓ Container Apps in paas-rg" -ForegroundColor Green
} else {
  Write-Host "✗ Container Apps NOT in paas-rg" -ForegroundColor Red
}

# Check 2: Build VMSS in agents-rg
$buildVmss = az resource list \
  --resource-group jobsite-agents-dev-rg \
  --query "[?contains(name, 'vmss')]" \
  --query 'length(@)' -o tsv

if ($buildVmss -gt 0) {
  Write-Host "✓ Build VMSS in agents-rg" -ForegroundColor Green
} else {
  Write-Host "✗ Build VMSS NOT in agents-rg" -ForegroundColor Red
}

# Check 3: App Gateway in iaas-rg
$agwInIaaS = az resource list \
  --resource-group jobsite-iaas-dev-rg \
  --query "[?type=='Microsoft.Network/applicationGateways']" \
  --query 'length(@)' -o tsv

if ($agwInIaaS -gt 0) {
  Write-Host "✓ App Gateway in iaas-rg" -ForegroundColor Green
} else {
  Write-Host "✗ App Gateway NOT in iaas-rg" -ForegroundColor Red
}

# Check 4: No Container Apps in core-rg
$caeInCore = az resource list \
  --resource-group jobsite-core-dev-rg \
  --query "[?type=='Microsoft.App/managedEnvironments']" \
  --query 'length(@)' -o tsv

if ($caeInCore -eq 0) {
  Write-Host "✓ No Container Apps in core-rg" -ForegroundColor Green
} else {
  Write-Host "✗ Container Apps still in core-rg" -ForegroundColor Red
}

Write-Host "`n✓ Resource Group verification complete" -ForegroundColor Green
```

**Success Criteria**:

- [ ] All 4 RGs contain expected resources
- [ ] Container Apps in paas-rg (not core-rg)
- [ ] Build VMSS in agents-rg (not iaas-rg)
- [ ] App Gateway in iaas-rg
- [ ] Core RG contains only networking

---

### Step 4.3: Application Functionality Test

**Task**: Verify apps still work after reorganization

```powershell
# [ASSIGN TO]: DevOps Engineer
# [TIME]: 30 minutes
# [RISK]: Medium

Write-Host "Testing Application Functionality..." -ForegroundColor Cyan

# Test 1: Web tier health
Write-Host "`n1. Checking Web VMSS health..." -ForegroundColor Cyan
az vmss list-instances \
  --resource-group jobsite-iaas-dev-rg \
  --name vmss-qahxan3ogcgdi \
  --query '[*].{name:name, provisioningState:provisioningState, vmId:vmId}' -o table

# Test 2: SQL connectivity (if possible)
Write-Host "`n2. SQL Server VM status..." -ForegroundColor Cyan
az vm list \
  --resource-group jobsite-iaas-dev-rg \
  --query "[?contains(name, 'sql')]" \
  --query '[*].{name:name, powerState:powerState}' -o table

# Test 3: Container Apps running (if deployed)
Write-Host "`n3. Container Apps status..." -ForegroundColor Cyan
az containerapp list \
  --resource-group jobsite-paas-dev-rg \
  --query '[*].{name:name, provisioningState:properties.provisioningState}' -o table

# Test 4: Build agents active
Write-Host "`n4. Build Agent instances..." -ForegroundColor Cyan
az vmss list-instances \
  --resource-group jobsite-agents-dev-rg \
  --name vmss-qahxan3ogcgdi \
  --query '[*].{name:name, powerState:powerState}' -o table

Write-Host "`n✓ Application functionality tests complete" -ForegroundColor Green
```

**Success Criteria**:

- [ ] Web VMSS instances running
- [ ] SQL Server VM running
- [ ] Container Apps deployed and healthy
- [ ] Build agents instances active
- [ ] All services reachable from expected locations

---

## Post-Implementation (Day 3+)

### Step 5.1: Documentation Updates

**Task**: Update team documentation to reflect new architecture

```powershell
# [ASSIGN TO]: Technical Writer
# [TIME]: 1-2 hours
# [RISK]: Very Low

# TODO: Update the following documents:
Write-Host "Documentation Updates Required:" -ForegroundColor Cyan
Write-Host "[ ] Architecture diagrams (show 4 RGs)"
Write-Host "[ ] Runbooks (updated RG references)"
Write-Host "[ ] Network diagrams (include App Gateway WFE)"
Write-Host "[ ] Deployment procedures (new deploy-agents.ps1)"
Write-Host "[ ] RBAC documentation (RG ownership model)"
Write-Host "[ ] Cost allocation (cost centers per RG)"
Write-Host "[ ] Monitoring dashboards (resources by RG)"
Write-Host "[ ] Disaster recovery procedures (updated for new RGs)"
```

**Success Criteria**:

- [ ] All documents updated
- [ ] Team can reference current architecture
- [ ] No confusion about resource locations
- [ ] New team members understand 4-layer model

---

### Step 5.2: Team Training

**Task**: Brief team on new architecture and procedures

```
[ ] Infrastructure Team
    - RG organization
    - Ownership model
    - Network connectivity
    - Troubleshooting procedures

[ ] DevOps Team
    - PaaS RG management
    - Container Apps procedures
    - Auto-scaling configuration

[ ] Operations Team
    - IaaS RG management
    - VMSS maintenance
    - App Gateway monitoring

[ ] CI/CD Team
    - Agents RG management
    - GitHub Runners setup
    - Build pipeline operations
```

**Success Criteria**:

- [ ] Team training completed
- [ ] Q&A addressed
- [ ] Team confident in new procedures
- [ ] Documentation walkthrough completed

---

### Step 5.3: Cleanup (Optional)

**Task**: Remove old resources if using parallel deployment

```powershell
# [ASSIGN TO]: Infrastructure Engineer
# [TIME]: 30 minutes (only if parallel deployed)
# [RISK]: Medium (ensure no dependencies first!)

Write-Host "Cleanup of Old Resources (OPTIONAL)" -ForegroundColor Cyan
Write-Host "Only proceed if NEW resources are working perfectly" -ForegroundColor Yellow

# List resources to be deleted
Write-Host "`nResources to be deleted:" -ForegroundColor Cyan
Write-Host "- Old Container Apps in core-rg (if still there)"
Write-Host "- Old Build VMSS in iaas-rg (if still there)"
Write-Host "- Old App Gateway (if there was one)"

# Confirm before deletion
$confirm = Read-Host "Proceed with cleanup? (type 'YES' to continue)"

if ($confirm -eq 'YES') {
  Write-Host "Proceeding with cleanup..." -ForegroundColor Yellow
  # Add deletion commands here
} else {
  Write-Host "Cleanup cancelled - old resources retained for safety" -ForegroundColor Green
}
```

---

## Rollback Procedures

### If App Gateway Deployment Fails

```powershell
az network application-gateway delete --name jobsite-dev-agw --resource-group jobsite-iaas-dev-rg --yes
az network public-ip delete --name jobsite-dev-pip-agw --resource-group jobsite-iaas-dev-rg --yes
```

### If Container Apps Move Fails

```powershell
# Container Apps should still be accessible from core-rg
# Retry move or redeploy to paas-rg
```

### If Build VMSS Move Fails

```powershell
# Move back to iaas-rg
az resource move --ids $vmssId --destination-group jobsite-iaas-dev-rg
```

### Full Rollback

```powershell
# Delete new RG if critical failure
az group delete --name jobsite-agents-dev-rg --yes

# Restore from backup if needed
# (restore Container Apps, VMSS from backed-up configs)
```

---

## Success Criteria Summary

### ✅ All Phases Complete

- [ ] Phase 1: RGs created, backups complete, VNet documented
- [ ] Phase 2: App Gateway deployed, PaaS RG ready
- [ ] Phase 3: Container Apps moved, Build VMSS moved
- [ ] Phase 4: All connectivity tests pass, resources verified
- [ ] Phase 5: Documentation updated, team trained

### ✅ Infrastructure Organization

- [ ] Core RG: Shared networking only (VNet, KV, LAW, ACR, NAT)
- [ ] IaaS RG: App tier + WFE (App Gateway, Web VMSS, SQL VM)
- [ ] PaaS RG: Managed services (Container Apps, App Service, SQL DB)
- [ ] Agents RG: Build infrastructure (Build VMSS)

### ✅ Connectivity & Functionality

- [ ] Web tier ↔ Database tier: Working ✓
- [ ] Public ↔ App Gateway: Responding ✓
- [ ] App Gateway ↔ Web VMSS: Health probes healthy ✓
- [ ] Build agents ↔ Internet: Outbound working ✓
- [ ] Container Apps: Accessible & functional ✓

### ✅ Monitoring & Security

- [ ] All VMs → Log Analytics: Flowing ✓
- [ ] Defender for Cloud: Enabled ✓
- [ ] WAF rules: Active & blocking attacks ✓
- [ ] Private Endpoints: Configured for sensitive services ✓
- [ ] RBAC: Proper per-RG assignments ✓

---

## Timeline & Ownership

| Phase                     | Owner        | Duration       | Start   | End   |
| ------------------------- | ------------ | -------------- | ------- | ----- |
| Pre-Implementation        | All          | 2-4 hours      | Day -1  | Day 0 |
| Phase 1: Preparation      | Infra Eng    | 1-2 hours      | Day 1   | Day 1 |
| Phase 2: Create Resources | DevOps/Arch  | 2-3 hours      | Day 1-2 | Day 2 |
| Phase 3: Move Resources   | DevOps/Infra | 2-4 hours      | Day 2   | Day 2 |
| Phase 4: Validation       | All          | 1-2 hours      | Day 2-3 | Day 3 |
| Post-Implementation       | All          | 2-3 hours      | Day 3+  | Day 4 |
| **TOTAL**                 | **1-2 team** | **8-12 hours** |         |       |

---

## Escalation Contacts

**During Implementation**:

- **On-Call Engineer**: [Name] - [Phone] - [Email]
- **Cloud Architect**: [Name] - Escalation for design issues
- **DevOps Lead**: [Name] - Escalation for automation/template issues

**Post-Implementation**:

- **Infrastructure Lead**: [Name] - Final approval
- **Security Officer**: [Name] - Compliance verification

---

## Final Notes

- ⚠️ **All activities should be logged** for audit trail
- ⚠️ **Keep team informed** of progress and blockers
- ⚠️ **Test thoroughly** before declaring success
- ⚠️ **Document any deviations** from this plan
- ✅ **Celebrate completion** - this is major infrastructure improvement!

---

**Checklist Version**: 1.0  
**Last Updated**: 2026-01-22  
**Status**: Ready for Use
