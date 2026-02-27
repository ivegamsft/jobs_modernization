# PaaS Module Deployment Checklist

## Pre-Deployment Verification

### ✅ Prerequisites Completed

- [ ] Core module deployed to `jobsite-core-rg`
- [ ] Core module outputs captured
- [ ] Azure CLI installed and authenticated
- [ ] Bicep CLI installed (v0.25 or later)

### ✅ Files Prepared

- [ ] `paas/main.bicep` - Module template ✅
- [ ] `paas/parameters.bicepparam` - Parameter values ✅
- [ ] `paas/README.md` - Documentation ✅

### ✅ Resource Group Created

```bash
az group create --name jobsite-paas-rg --location eastus
```

- [ ] Resource group created
- [ ] Correct region selected (eastus)

## Configuration Checklist

### ✅ Step 1: Gather Core Module Outputs

Run this command to get core module outputs:

```bash
az deployment group show \
 [ ] `paas/main.bicep` - Module template ✅
 [ ] `paas/parameters.bicepparam` - Parameter values ✅
 [ ] `paas/README.md` - Documentation ✅
  -o json
```

Record these values:
Edit `paas/parameters.bicepparam`:

- [ ] `vnetId` = `/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-{env}`
- [ ] `peSubnetId` = `/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/virtualNetworks/jobsite-vnet-{env}/subnets/private-endpoints`
- [ ] `keyVaultId` = `/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.KeyVault/vaults/jobsite-kv-{suffix}`
- [ ] `keyVaultName` = `jobsite-kv-{suffix}`
- [ ] `logAnalyticsWorkspaceId` = `/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.OperationalInsights/workspaces/jobsite-la-{suffix}`
- [ ] `privateDnsZoneId` = `/subscriptions/{subId}/resourceGroups/jobsite-core-rg/providers/Microsoft.Network/privateDnsZones/jobsite.internal`

### ✅ Step 2: Update parameters.bicepparam

Edit `paas/parameters.bicepparam`:

```bicepparam
# Environment
param environment = 'dev'              # [ ] Updated
param applicationName = 'jobsite'      # [ ] Updated (if different)
param location = 'eastus'              # [ ] Updated
  --template-file infrastructure/bicep/paas/main.bicep \
  --parameters infrastructure/bicep/paas/parameters.bicepparam \
param appServiceSku = 'S1'             # [ ] Updated (B1 for dev, P1V2 for prod)

# SQL Database
param sqlDatabaseEdition = 'Standard'   # [ ] Updated
param sqlServiceObjective = 'S1'        # [ ] Updated
param sqlAdminUsername = 'jobsiteadmin' # [ ] Updated
param sqlAdminPassword = '...'          # [ ] Changed from default!

# Core Infrastructure (from outputs above)
param vnetId = '...'                   # [ ] Pasted from core outputs
param peSubnetId = '...'                # [ ] Pasted from core outputs
param keyVaultId = '...'                # [ ] Pasted from core outputs
param keyVaultName = '...'              # [ ] Pasted from core outputs
param logAnalyticsWorkspaceId = '...'   # [ ] Pasted from core outputs
param privateDnsZoneId = '...'          # [ ] Pasted from core outputs
param privateDnsZoneName = 'jobsite.internal' # [ ] Keep as-is
```

⚠️ **CRITICAL:**

- [ ] SQL admin password changed from default value
- [ ] All core infrastructure IDs copied correctly
- [ ] No typos in subscription IDs or resource names

### ✅ Step 3: Validate Bicep Template

```bash
cd infrastructure/bicep/paas
az bicep build --file main.bicep
```

Expected output:

```
(No warnings or errors)
```

- [ ] Build successful
- [ ] Only warnings (no errors)
- [ ] Review warnings (they're informational, not blocking)

## Deployment Checklist

### ✅ Step 4: Pre-Deployment Validation

**Option A: Validate Only (Recommended First)**

```bash
az deployment group validate \
  --resource-group jobsite-paas-rg \
  --template-file infrastructure/bicep/paas/main.bicep \
  --parameters infrastructure/bicep/paas/parameters.bicepparam
```

Expected: `Deployment template validation succeeded`

- [ ] Validation passed without errors

**Option B: What-If (See what will be created)**

```bash
az deployment what-if \
  --resource-group jobsite-paas-rg \
  --template-file infrastructure/bicep/paas/main.bicep \
  --parameters infrastructure/bicep/paas/parameters.bicepparam
```

Review the output:

- [ ] Creating: App Service
- [ ] Creating: App Service Plan
- [ ] Creating: SQL Server
- [ ] Creating: SQL Database
- [ ] Creating: Application Insights
- [ ] Creating: Private Endpoint
- [ ] Creating: Network Interface
- [ ] Creating: DNS A record
- [ ] Creating: Key Vault Secrets (in core KV)
- [ ] Creating: Diagnostics Settings

### ✅ Step 5: Deploy

```bash
az deployment group create \
  --resource-group jobsite-paas-rg \
  --template-file infrastructure/bicep/paas/main.bicep \
  --parameters infrastructure/bicep/paas/parameters.bicepparam \
  --name paas-deployment
```

Monitor deployment:

- [ ] Deployment started
- [ ] Watch Azure Portal or run: `az deployment group show --resource-group jobsite-paas-rg --name paas-deployment --query properties.provisioningState`
- [ ] Deployment completed (provisioningState = `Succeeded`)

**Estimated deployment time:** 5-10 minutes

## Post-Deployment Verification

### ✅ Step 6: Verify Resources Created

```bash
az resource list --resource-group jobsite-paas-rg -o table
```

Verify these resources exist:

- [ ] App Service Plan (`jobsite-asp-...`)
- [ ] App Service (`jobsite-app-...`)
- [ ] SQL Server (`jobsite-sql-...`)
- [ ] SQL Database (`jobsitedb`)
- [ ] Application Insights (`jobsite-ai-...`)
- [ ] Private Endpoint (`jobsite-app-...-pe`)
- [ ] Network Interface for PE (`jobsite-app-...-pe-nic`)
- [ ] Managed Identity (`jobsite-identity-...`)

### ✅ Step 7: Verify Key Vault Secrets

```bash
az keyvault secret list --vault-name {keyVaultName} -o table
```

Should see:

- [ ] `paas-sql-connection-string` - ✅ Present
- [ ] `paas-appinsights-key` - ✅ Present

### ✅ Step 8: Verify DNS Records

```bash
az network private-dns record-set a show \
  --resource-group jobsite-core-rg \
  --zone-name jobsite.internal \
  --name app
```

Should show:

- [ ] Name: `app`
- [ ] Zone: `jobsite.internal`
- [ ] Type: `A`
- [ ] IPv4 address: (should match private endpoint IP)

### ✅ Step 9: Verify App Service Configuration

```bash
az webapp config show \
  --resource-group jobsite-paas-rg \
  --name {appServiceName}
```

Verify settings:

- [ ] Net Framework Version: `v4.0`
- [ ] Managed Pipeline Mode: `Integrated`
- [ ] Minimum TLS: `1.2`
- [ ] Always On: `true` (prod) or `false` (dev)
- [ ] Connection strings: `connectionstring` present
- [ ] HTTPS only: `true`

### ✅ Step 10: View Deployment Outputs

```bash
az deployment group show \
  --resource-group jobsite-paas-rg \
  --name paas-deployment \
  --query properties.outputs -o json
```

Record these for reference:

- [ ] `appServiceUrl` - Public URL (will be blocked by private endpoint)
- [ ] `appServiceName` - Deployed name
- [ ] `appServicePrivateIp` - Private endpoint IP
- [ ] `sqlServerName` - SQL Server name
- [ ] `sqlServerFqdn` - SQL Server FQDN
- [ ] `sqlDatabaseName` - Database name
- [ ] `appInsightsName` - App Insights name
- [ ] `appInsightsKey` - Instrumentation key

## Post-Deployment Configuration

### ✅ Step 11: SQL Database Setup

If deploying application database:

```bash
# Get SQL Server admin credentials
# Server: {sqlServerFqdn}
# Login: {sqlAdminUsername}
# Password: (from parameters)
# Database: jobsitedb

# Using Azure Data Studio or SQL Server Management Studio:
# - Connect to server
# - Execute application schema scripts
# - Create application users
# - Grant appropriate permissions
```

- [ ] Database schema deployed
- [ ] Application user created
- [ ] Permissions configured

### ✅ Step 12: Application Deployment

If deploying ASP.NET application:

```bash
# Option 1: Via Azure Portal
# - App Service > Deployment Center
# - Connect to GitHub/Azure DevOps/Local Git
# - Configure build and deploy

# Option 2: Via Azure CLI/PowerShell
# - Publish application using Azure CLI
# - az webapp deployment source config-zip ...

# Option 3: Via Visual Studio
# - Right-click project > Publish
# - Select Azure App Service target
# - Deploy
```

- [ ] Application code deployed
- [ ] Web.config updated with Key Vault references
- [ ] Application accessible via private endpoint

### ✅ Step 13: Networking Configuration

For accessing the App Service:

**From VPN:**

```
1. Connect to Point-to-Site VPN
2. DNS automatically resolves app.jobsite.internal
3. Access: https://app.jobsite.internal
```

**From App Gateway (if using #vm module):**

```
1. Configure backend pool to point to App Service
2. Create routing rules for app.jobsite.internal
3. Access: https://app.jobsite.com (via WAF)
```

- [ ] VPN connectivity verified (if applicable)
- [ ] App Gateway configured (if applicable)
- [ ] DNS resolution tested

### ✅ Step 14: Monitoring Verification

Check Log Analytics:

```kusto
# In Log Analytics Workspace
AppServiceHTTPLogs
| where TimeGenerated > ago(24h)
| summarize Count = count() by ResultDescription
```

- [ ] App Service logs appearing in Log Analytics
- [ ] SQL Database logs appearing in Log Analytics
- [ ] Application Insights metrics visible
- [ ] No error logs (or only expected errors)

## Troubleshooting Checklist

### If Deployment Fails

- [ ] Check error messages in Azure Portal > Deployments
- [ ] Verify all core infrastructure IDs in parameters
- [ ] Confirm Key Vault exists and is accessible
- [ ] Check subscription quota limits
- [ ] Verify SQL admin password meets complexity requirements

### If DNS Not Resolving

- [ ] Verify DNS A record created: `az network private-dns record-set a show ...`
- [ ] Confirm you're inside VNet or connected via VPN
- [ ] Check private endpoint NIC has correct IP
- [ ] Verify DNS zone linked to VNet

### If App Service Can't Connect to SQL

- [ ] Verify SQL Server firewall allows Azure services
- [ ] Check Key Vault secret content: `az keyvault secret show --name paas-sql-connection-string ...`
- [ ] Verify SQL admin credentials
- [ ] Test SQL connectivity from Kudu console (App Service > Advanced Tools)

### If Application Insights Not Showing Data

- [ ] Verify instrumentation key in app settings
- [ ] Check Application Insights SDK installed in app
- [ ] Confirm Web.config has ApplicationInsights enabled
- [ ] Query: `AppServiceAppLogs | take 10` in Log Analytics

## Rollback Procedure

If issues occur and rollback needed:

```bash
# Option 1: Delete resource group (destroys everything)
az group delete --name jobsite-paas-rg --yes --no-wait

# Option 2: Delete specific resources
az resource delete --ids /subscriptions/.../{resourceId}

# Option 3: Restore from backup (if previous deployment saved)
# Restore via Azure portal if point-in-time recovery available
```

- [ ] Understood rollback implications
- [ ] Backup strategy in place (if needed)

## Success Criteria - All Green ✅

The deployment is **successful** when:

- ✅ All resources created (verified in Step 6)
- ✅ Key Vault secrets present (verified in Step 7)
- ✅ DNS records created (verified in Step 8)
- ✅ App Service configured correctly (verified in Step 9)
- ✅ Monitoring data flowing to Log Analytics (verified in Step 14)
- ✅ Application accessible via private endpoint
- ✅ SQL database connected and operational
- ✅ Application Insights collecting metrics

## Next Steps After Successful Deployment

1. **Configure Custom Domain** (if not using app.jobsite.internal)

   ```bash
   az webapp config hostname add --resource-group jobsite-paas-rg \
     --webapp-name {appServiceName} --hostname yourdomain.com
   ```

2. **Set Up Alerts**
   - Create action group for notifications
   - Create metric alerts for failures
   - Create log alerts for errors

3. **Enable Backups**
   - SQL database automated backups (already configured)
   - Application code backup via deployment slots

4. **Scale Configuration**
   - Set auto-scale rules based on metrics
   - Configure scale-out threshold (80% CPU)
   - Configure scale-in threshold (20% CPU)

5. **Security Hardening**
   - Restrict SQL Server firewall to specific IPs
   - Enable SQL Advanced Threat Protection
   - Configure DDoS protection on App Gateway
   - Enable WAF rules (if using App Gateway)

---

**Deployment Checklist Version:** 1.0
**Last Updated:** 2024
**Status:** Ready for Deployment ✅
