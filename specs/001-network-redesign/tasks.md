# 001-Network-Redesign - Tasks

**Feature**: Network Redesign  
**Status**: Ready for Implementation  
**Estimated Effort**: 8-12 hours (4-6 hours per person with 2-person team)

---

## Task Breakdown

### Phase 1: Validation & Preparation (1-2 hours)

#### Task 1.1: Validate Bicep Templates

**Effort**: 30 min  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] core/main.bicep passes `bicep build` validation
- [ ] core-resources.bicep passes validation
- [ ] No linting errors or warnings
- [ ] All variable references are valid

**Commands**:

```bash
cd iac/bicep/core
az bicep build -f main.bicep --outfile temp.json
bicep lint main.bicep core-resources.bicep
```

**Validation**:

- CIDR ranges don't overlap
- All subnet names match references in iaas/main.bicep
- VNet address space includes all subnets

---

#### Task 1.2: Backup Current Configuration

**Effort**: 30 min  
**Owner**: DevOps Engineer  
**Acceptance Criteria**:

- [ ] Current deployment configuration exported to JSON
- [ ] Current resource properties documented
- [ ] Rollback procedure documented
- [ ] Backup stored in git and Key Vault

**Steps**:

```bash
# Export current resources
az resource list --resource-group jobsite-core-dev-rg -o json > backup-core-resources.json
az deployment sub show --name jobsite-core-dev -o json > backup-core-deployment.json
az deployment sub show --name jobsite-iaas-dev -o json > backup-iaas-deployment.json

# Document any custom configs
az network vnet show -g jobsite-core-dev-rg -n jobsite-dev-vnet -o yaml > backup-vnet.yaml
```

**Validation**:

- All critical resources documented
- No sensitive data in backups (check before storing)

---

#### Task 1.3: Plan Migration Approach

**Effort**: 30 min  
**Owner**: Infrastructure Architect  
**Acceptance Criteria**:

- [ ] Deployment sequence decided (blue-green vs fresh start)
- [ ] Risk assessment completed
- [ ] Go/No-Go criteria defined
- [ ] Team alignment on approach

**Decision Framework**:

```
Fresh Start (Chosen):
- Dev environment, no customer impact
- Faster (2-4 hours vs 15-30 min migration)
- Cleaner testing of new arch
- Risks: Data loss (mitigated with backup)

Blue-Green:
- Run old and new in parallel
- Lower risk but longer process
- Higher infrastructure cost
- Better for production

Go Criteria:
✓ All templates validate
✓ Backups verified
✓ Team trained
✓ Rollback tested (dry-run)
```

**Validation**:

- Team consensus on approach
- Rollback plan documented

---

### Phase 2: Infrastructure Deployment (6-8 hours)

#### Task 2.1: Deploy Core Network Layer

**Effort**: 1-2 hours  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] Deployment completes successfully
- [ ] New VNet created (10.50.0.0/21)
- [ ] All 7 subnets created with correct CIDRs
- [ ] Deployment status shows "Succeeded"

**Commands**:

```bash
cd iac

# Deploy fresh Core infrastructure
az deployment sub create \
  --location swedencentral \
  --template-file bicep/core/main.bicep \
  --parameters environment=dev applicationName=jobsite location=swedencentral \
  --name "jobsite-core-dev-v2"

# Verify deployment
az deployment sub show --name "jobsite-core-dev-v2" \
  --query "properties.provisioningState" -o tsv

# Get outputs
CORE_OUTPUTS=$(az deployment sub show --name "jobsite-core-dev-v2" \
  --query "properties.outputs" -o json)
echo $CORE_OUTPUTS
```

**Validation**:

```bash
# Verify all subnets exist
az network vnet subnet list -g jobsite-core-dev-rg \
  --vnet-name jobsite-dev-vnet -o table

# Check IP allocations
az network vnet list -g jobsite-core-dev-rg -o json | \
  jq '.[] | {name, addressSpace}'
```

**Expected Output**:

```
✓ VNet: 10.50.0.0/21
✓ snet-fe: 10.50.0.0/24 (251 usable IPs)
✓ snet-data: 10.50.1.0/26 (59 usable IPs)
✓ snet-gh-runners: 10.50.1.64/26 (59 usable IPs)
✓ snet-pe: 10.50.1.128/27 (27 usable IPs)
✓ GatewaySubnet: 10.50.1.160/27 (27 usable IPs)
✓ snet-aks: 10.50.2.0/23 (507 usable IPs)
✓ snet-ca: 10.50.4.0/26 (59 usable IPs)
```

---

#### Task 2.2: Deploy IaaS Layer (VMSS, SQL, App Gateway)

**Effort**: 2 hours  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] IaaS deployment completes successfully
- [ ] VMSS deployed to snet-gh-runners (correct subnet!)
- [ ] SQL VM deployed to snet-data
- [ ] Application Gateway deployed to snet-fe
- [ ] All resources healthy in portal

**Commands**:

```bash
cd iac

# Get Core outputs
CORE_OUTPUTS=$(az deployment sub show --name "jobsite-core-dev-v2" \
  --query "properties.outputs" -o json)

FRONTEND_SUBNET=$(echo $CORE_OUTPUTS | jq -r '.frontendSubnetId.value')
DATA_SUBNET=$(echo $CORE_OUTPUTS | jq -r '.dataSubnetId.value')
GITHUB_RUNNERS_SUBNET=$(echo $CORE_OUTPUTS | jq -r '.githubRunnersSubnetId.value')

# Deploy IaaS
./deploy-iaas-clean.ps1 \
  -VMPassword "YourPassword123!" \
  -CertPassword "YourCertPassword123!"

# Verify deployment
az deployment sub show --name "jobsite-iaas-dev" \
  --query "properties.provisioningState" -o tsv
```

**Validation**:

```bash
# Verify VMSS in correct subnet
az vmss list-instances -g jobsite-iaas-dev-rg -n jobsite-vmss --query \
  "[].networkProfile.networkInterfaces[].id" -o json

# Verify SQL VM
az vm list -g jobsite-iaas-dev-rg --query "[?name=='jobsite-sql'].{name, vmId}" -o table

# Check App Gateway
az network application-gateway list -g jobsite-iaas-dev-rg -o table
```

**Expected Output**:

```
✓ VMSS instances running in snet-gh-runners
✓ SQL VM running with IP in snet-data range
✓ App Gateway listening on snet-fe
✓ Network interfaces properly configured
```

**Troubleshooting**:

- If VMSS fails: Check networkApiVersion in networkProfile
- If SQL fails: Verify snet-data NAT Gateway association
- If App Gateway fails: Verify snet-fe has sufficient IPs

---

#### Task 2.3: Deploy PaaS Layer (App Service, SQL DB, App Insights)

**Effort**: 1-2 hours  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] PaaS deployment completes successfully
- [ ] App Service Plan created (S1 SKU)
- [ ] SQL Database provisioned
- [ ] Application Insights configured
- [ ] Container App Environment references Core CAE

**Commands**:

```bash
cd iac

# Deploy PaaS
az deployment sub create \
  --location swedencentral \
  --template-file bicep/paas/main.bicep \
  --parameters environment=dev applicationName=jobsite location=swedencentral \
  --name "jobsite-paas-dev-v2"

# Verify deployment
az deployment sub show --name "jobsite-paas-dev-v2" \
  --query "properties.provisioningState" -o tsv

# Get App Service URL
az app service list -g jobsite-paas-dev-rg --query "[].defaultHostName" -o tsv
```

**Validation**:

```bash
# Verify App Service
az app service show -g jobsite-paas-dev-rg -n jobsite-app --query "state" -o tsv

# Check SQL Database
az sql db list -g jobsite-paas-dev-rg -s jobsite-sql-server --query "[].name" -o tsv

# Verify App Insights
az monitor app-insights component show -g jobsite-paas-dev-rg \
  -a jobsite-app-insights --query "instrumentationKey" -o tsv
```

**Expected Output**:

```
✓ App Service running
✓ SQL Database created and healthy
✓ Application Insights capturing telemetry
✓ All connection strings in Key Vault
```

---

### Phase 3: Validation & Testing (2-3 hours)

#### Task 3.1: Verify Network Connectivity

**Effort**: 1 hour  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] VMSS can reach App Gateway
- [ ] App Gateway can reach VMSS backend
- [ ] App Service can reach SQL Database
- [ ] Private endpoints functioning
- [ ] No routing errors or blackholes

**Test Plan**:

```bash
# Test 1: VMSS to App Gateway (NSG rules)
# Connect to VMSS instance
VMSS_IP=$(az vmss list-instances -g jobsite-iaas-dev-rg \
  -n jobsite-vmss --query "[0].publicIps" -o tsv)

# Check connectivity to App Gateway backend IP
az network application-gateway show -g jobsite-iaas-dev-rg \
  -n jobsite-appgw --query "backendAddressPools" -o json

# Test 2: App Gateway health check
az network application-gateway http-settings show \
  -g jobsite-iaas-dev-rg --gateway-name jobsite-appgw \
  -n appgateway-backend-http-settings --query "pickHostNameFromBackendAddress" -o tsv

# Test 3: SQL connectivity
az sql server firewall-rule list -g jobsite-paas-dev-rg -s jobsite-sql-server -o table

# Test 4: Key Vault access
az keyvault secret list --vault-name $(az keyvault list -g jobsite-core-dev-rg \
  --query "[0].name" -o tsv) --query "[].name" -o tsv
```

**Validation Checklist**:

- [ ] VMSS instances healthy
- [ ] App Gateway shows all backends healthy
- [ ] SQL connection string works
- [ ] Key Vault accessible to App Service identity

---

#### Task 3.2: Validate IP Allocation & Utilization

**Effort**: 30 min  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] All subnet IPs accounted for
- [ ] Utilization between 20-70% (not 100%, not wasted)
- [ ] Growth capacity adequate for 3-5x scale
- [ ] No IP conflicts or collisions

**Commands**:

```bash
# Get VNet info
VNet=$(az network vnet list -g jobsite-core-dev-rg -o json)

# Calculate utilization per subnet
echo "Subnet IP Utilization:"
echo "snet-fe: $(az network vnet subnet show -g jobsite-core-dev-rg --vnet-name jobsite-dev-vnet -n snet-fe --query "addressPrefix" -o tsv) - Max instances: 125, Reserved: 44%"
echo "snet-data: ... - Max VMs: 10, Reserved: 50%"
echo "snet-gh-runners: ... - Max VMSS: 50, Reserved: 50%"
echo "snet-aks: ... - Max nodes: 250+, Reserved: 50%"

# Verify no overlaps
CIDRS=$(az network vnet subnet list -g jobsite-core-dev-rg \
  --vnet-name jobsite-dev-vnet --query "[].addressPrefix" -o tsv)
echo "All CIDRs: $CIDRS"
```

**Expected Result**:

```
✓ snet-fe: 251/256 IPs available, 0% used, 44% reserved
✓ snet-data: 59/64 IPs available, 5% used, 50% reserved
✓ snet-gh-runners: 59/64 IPs available, 3% used, 50% reserved
✓ snet-aks: 507/512 IPs available, 0% used, 50% reserved
✓ All subnets have adequate growth capacity
✓ No IP conflicts detected
```

---

#### Task 3.3: Test Monitoring & Diagnostics

**Effort**: 30 min  
**Owner**: DevOps Engineer  
**Acceptance Criteria**:

- [ ] All resources sending logs to Log Analytics
- [ ] Network diagnostics enabled
- [ ] Can query logs from all layers
- [ ] Alerts configured for critical conditions

**Commands**:

```bash
# Check Log Analytics workspace
LA_ID=$(az monitor log-analytics workspace list -g jobsite-core-dev-rg \
  --query "[0].id" -o tsv)

# Query logs
az monitor log-analytics query -w $LA_ID --query \
  "AzureNetworkAnalytics_CL | where TimeGenerated > ago(1h) | take 10"

# Check NSG Flow Logs
az network watcher flow-log list -g jobsite-core-dev-rg -o table

# Verify diagnostics settings
az monitor diagnostic-settings list --resource $(az network vnet list -g jobsite-core-dev-rg \
  --query "[0].id" -o tsv) -o json | jq '.[] | {name: .name, logs: .logs}'
```

**Validation Checklist**:

- [ ] VNet diagnostics enabled
- [ ] NSG flow logs configured
- [ ] Log Analytics receiving data
- [ ] Queries return results

---

### Phase 4: Documentation & Cleanup (1-2 hours)

#### Task 4.1: Update Architecture Documentation

**Effort**: 1 hour  
**Owner**: Technical Writer  
**Acceptance Criteria**:

- [ ] Network diagram updated with new subnets
- [ ] CIDR allocation table created
- [ ] Resource mapping documented
- [ ] Scaling limits documented per subnet
- [ ] Architecture Decision Record (ADR) created

**Deliverables**:

```markdown
# Updated Files:

- docs/ARCHITECTURE.md - New network diagram
- docs/NETWORK_DESIGN.md - Subnet sizing rationale
- iac/NETWORK_REDESIGN.md - Implementation details
- iac/bicep/README.md - Updated module documentation
```

**Content**:

```markdown
## Network Architecture v2

VNet: 10.50.0.0/21 (2,048 IPs)
Allocated: 1,152 IPs (56%)
Reserved: 896 IPs (44%)

### Subnet Allocation

| Name            | CIDR | Usable | Purpose           | Max Scale     |
| --------------- | ---- | ------ | ----------------- | ------------- |
| snet-fe         | /24  | 251    | App Gateway v2    | 125 instances |
| snet-data       | /26  | 59     | SQL VMs           | 10 VMs        |
| snet-gh-runners | /26  | 59     | Build agents      | 50 instances  |
| snet-pe         | /27  | 27     | Private endpoints | 27 endpoints  |
| GatewaySubnet   | /27  | 27     | VPN Gateway       | -             |
| snet-aks        | /23  | 507    | AKS cluster       | 250+ nodes    |
| snet-ca         | /26  | 59     | Container Apps    | 50+ replicas  |
```

---

#### Task 4.2: Clean Up Old Deployment (Optional)

**Effort**: 30 min  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] Old resource group deleted (if keeping separate)
- [ ] DNS records updated (if applicable)
- [ ] Backup verified before deletion
- [ ] All dependencies migrated to new network

**Decision**:

```
Option A (Recommended for dev):
- Delete old deployment completely
- Cleaner, simpler
- Can redeploy if issues arise

Option B (Safer):
- Keep old network dormant
- Easy rollback if problems
- Costs while idle

Option C (Parallel):
- Run both simultaneously
- More expensive
- Better for testing with traffic
```

**Commands** (if choosing Option A):

```bash
# Backup one more time
az deployment sub show --name "jobsite-core-dev" -o json > final-backup.json

# Delete old deployment
az group delete -n jobsite-core-dev-rg --yes --no-wait
az group delete -n jobsite-iaas-dev-rg --yes --no-wait
az group delete -n jobsite-paas-dev-rg --yes --no-wait

# Monitor cleanup
az group list --query "[?name=='jobsite-*'].{name, state: properties.provisioningState}"
```

---

#### Task 4.3: Knowledge Transfer & Runbooks

**Effort**: 1 hour  
**Owner**: Infrastructure Engineer  
**Acceptance Criteria**:

- [ ] Team trained on new architecture
- [ ] Common tasks documented (scale, monitor, troubleshoot)
- [ ] Runbooks created for on-call procedures
- [ ] Backup/recovery procedures documented

**Runbooks to Create**:

1. **Scale VMSS** - Add/remove instances
2. **Scale AKS** - Add nodes to cluster
3. **Monitor Network Health** - Check connectivity and diagnostics
4. **Troubleshoot Connectivity** - Common issues and fixes
5. **Emergency Rollback** - Return to previous version if needed

---

## Summary

| Phase           | Tasks                                | Effort          | Owner                   |
| --------------- | ------------------------------------ | --------------- | ----------------------- |
| **1: Prep**     | Validation, backup, planning         | 1-2h            | Infra Engineer          |
| **2: Deploy**   | Core, IaaS, PaaS layers              | 6-8h            | Infra Engineer          |
| **3: Validate** | Connectivity, IP util, monitoring    | 2-3h            | Infra Engineer + DevOps |
| **4: Document** | Architecture docs, cleanup, training | 1-2h            | Tech Writer + Infra     |
| **TOTAL**       |                                      | **10-15 hours** | 1-2 person team         |

---

## Dependencies

- ✅ Spec complete (spec.md)
- ✅ Plan approved (plan.md)
- ⏳ Bicep templates validated (Task 1.1)
- ⏳ Team trained on tasks (Task 1.3)

## Risks & Mitigation

| Risk                       | Mitigation                                    |
| -------------------------- | --------------------------------------------- |
| Subnet CIDR conflict       | Task 1.2 backup validates no overlaps         |
| VMSS network profile fails | Task 2.2 validates with networkApiVersion     |
| NSG rules too restrictive  | Task 3.1 validates all connectivity           |
| Long deployment time       | Deploy Core/IaaS/PaaS in parallel if possible |

---

**Last Updated**: 2026-01-21  
**Status**: Ready for `/speckit.implement`
