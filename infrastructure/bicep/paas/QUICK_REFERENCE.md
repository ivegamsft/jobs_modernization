# PaaS Module - Quick Reference Guide

## 30-Second Overview

The **PaaS module** (`infrastructure/bicep/paas/`) deploys App Service + SQL Database integrated with core infrastructure.

**Key Point:** Depends on core module, no duplicate resources.

## Quick Deploy (4 Steps)

### 1️⃣ Get Core Outputs

```bash
az deployment group show -g jobsite-core-rg -n main --query properties.outputs -o json
```

Copy these core outputs (replace in parameters.bicepparam):

- `peSubnetId`
- `keyVaultName`
- `logAnalyticsWorkspaceId`

### 2️⃣ Update Parameters

```bash
# Edit this file with values from Step 1:
vi infrastructure/bicep/paas/parameters.bicepparam

# KEY CHANGES:
# - Core IDs: peSubnetId, keyVaultName, logAnalyticsWorkspaceId
# - sqlAdminPassword (CHANGE FROM DEFAULT!)
# - environment (dev/staging/prod)
# - appServiceSku (B1 for dev, S1+ for prod)
```

### 3️⃣ Validate & Deploy

```bash
cd infrastructure/bicep/paas

# Validate first
az bicep build --file main.bicep

# Deploy
az deployment group create \
  --resource-group jobsite-paas-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam
```

### 4️⃣ Verify

```bash
# Check resources created
az resource list -g jobsite-paas-rg -o table

# Check secrets in Key Vault
az keyvault secret list --vault-name {keyVaultName}

# Get outputs
az deployment group show -g jobsite-paas-rg -n paas-deployment \
  --query properties.outputs -o json
```

## File Structure

```
paas/
├── main.bicep              ← Template (472 lines, ready to deploy)
├── parameters.bicepparam   ← Configuration (update before deploy)
├── README.md               ← Full documentation
├── DEPLOYMENT_CHECKLIST.md ← Step-by-step guide
├── INTEGRATION_SUMMARY.md  ← What changed from original
└── QUICK_REFERENCE.md      ← This file
```

## Key Resources Created

| Resource         | Name Pattern                    | Notes                        |
| ---------------- | ------------------------------- | ---------------------------- |
| App Service Plan | `jobsite-asp-{env}`             | Windows, configurable SKU    |
| App Service      | `jobsite-app-{env}-{suffix}`    | ASP.NET 4.0 hosting          |
| SQL Server       | `jobsite-sql-{env}-{suffix}`    | Standard, TLS 1.2 min        |
| SQL Database     | `jobsitedb`                     | 250GB, auto backups          |
| App Insights     | `jobsite-ai-{env}`              | Linked to core Log Analytics |
| Private Endpoint | `jobsite-app-{env}-{suffix}-pe` | For network isolation        |
| DNS Record       | `app` in `jobsite.internal`     | Private access               |

## Parameter Quick Reference

| Parameter             | Example                                               | Notes                 |
| --------------------- | ----------------------------------------------------- | --------------------- |
| `environment`         | `dev`                                                 | dev/staging/prod      |
| `appServiceSku`       | `S1`                                                  | B1 (dev), P1V2 (prod) |
| `sqlDatabaseEdition`  | `Standard`                                            | Standard/Premium      |
| `sqlServiceObjective` | `S1`                                                  | S0/S1/S2/S3           |
| `vnetId`              | `/subscriptions/.../virtualNetworks/jobsite-vnet-dev` | From core outputs     |
| `keyVaultName`        | `jobsite-kv-abc123`                                   | From core outputs     |

## Common Commands

### Check Deployment Status

```bash
az deployment group show -g jobsite-paas-rg -n paas-deployment \
  --query properties.provisioningState
```

### View Errors

```bash
az deployment group show -g jobsite-paas-rg -n paas-deployment \
  --query properties.error
```

### Get App Service Details

```bash
az webapp show -g jobsite-paas-rg \
  -n {appServiceName} --query properties
```

### Test SQL Connection

```bash
# From App Service Kudu Console:
# https://{appServiceName}.scm.azurewebsites.net
# Run: test-netconnection {sqlServerFqdn} -p 1433
```

### View Secrets in Key Vault

```bash
# List all secrets
az keyvault secret list --vault-name {keyVaultName} -o table

# View specific secret
az keyvault secret show --vault-name {keyVaultName} \
  --name paas-sql-connection-string --query value
```

### Query Logs

```bash
# In Log Analytics, run these KQL queries:
# App logs
AppServiceHTTPLogs | take 100

# SQL logs
AzureDiagnostics | where ResourceProvider == "MICROSOFT.SQL" | take 100

# All diagnostics
AzureDiagnostics | where TimeGenerated > ago(1h)
```

## Network Access

### Private Access via VPN

```
1. Connect: Point-to-Site VPN (from core module)
2. Resolve: app.jobsite.internal
3. Access: https://app.jobsite.internal
```

### Private Access via App Gateway

```
1. Deploy: App Gateway from #vm module
2. Configure: Backend pool → App Service
3. Create: Routing rule for app.jobsite.internal
4. Access: https://app.jobsite.com
```

### ❌ NO Public Internet Access

- `https://jobsite-app-...azurewebsites.net` → BLOCKED
- Private endpoint required for all access

## Cost Estimate

### Dev Environment

- App Service (B1): ~$10/month
- SQL Database (S0): ~$15/month
- Other services: ~$5/month
- **Total: ~$30/month**

### Prod Environment

- App Service (P1V2): ~$100/month
- SQL Database (S3): ~$150/month
- Other services: ~$10/month
- **Total: ~$260/month**

## Troubleshooting Quick Links

| Issue                 | Command                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| Deployment failed?    | `az deployment group show -g jobsite-paas-rg -n paas-deployment --query properties.error`               |
| Can't connect to SQL? | Check firewall: `az sql server firewall-rule list -g jobsite-paas-rg -s {sqlServerName}`                |
| DNS not resolving?    | Verify record: `az network private-dns record-set a show -g jobsite-core-rg -z jobsite.internal -n app` |
| App not showing logs? | Check LA linked: `az monitor app-insights component show -g jobsite-paas-rg -a {appInsightsName}`       |

## Critical Security Points

⚠️ **Before Deployment:**

- [ ] SQL admin password changed from default
- [ ] All core infrastructure IDs correct
- [ ] Location matches core module (eastus)

✅ **After Deployment:**

- [ ] Private endpoint accessible only via VPN/App Gateway
- [ ] Secrets stored in core Key Vault (encrypted)
- [ ] Diagnostics flowing to core Log Analytics
- [ ] SQL firewall restricted (in production)
- [ ] HTTPS enforced on App Service (TLS 1.2 min)

## Key Outputs (After Deployment)

```bash
appServiceUrl              # Public URL (blocked by PE)
appServiceName             # Deployed name
appServicePrivateIp        # PE IP for DNS
sqlServerFqdn              # SQL server hostname
sqlDatabaseName            # Database name (jobsitedb)
appInsightsKey             # Instrumentation key
```

## Integration Points with Other Modules

```
Core Module (#core)          PaaS Module (#paas)
├── VNet              ←→      Referenced for PE subnet
├── Private DNS       ←→      Creates A record
├── Key Vault         ←→      Stores secrets
└── Log Analytics     ←→      Diagnostics destination
```

## Scaling Up to Production

**Current (Dev):**

```bicepparam
environment = 'dev'
appServiceSku = 'S1'
sqlServiceObjective = 'S1'
```

**To Production:**

```bicepparam
environment = 'prod'
appServiceSku = 'P1V2'        # or P2V2
sqlServiceObjective = 'S3'    # or higher
# Re-deploy (auto-scales to 2 instances)
```

## Estimated Deployment Time

- **Validation:** < 1 minute
- **Actual Deployment:** 5-10 minutes
- **Post-deployment checks:** 2-3 minutes
- **Total:** ~15 minutes

## Documentation Map

- **Quick Reference** ← You are here
- **Full Deployment Guide:** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Complete Documentation:** [README.md](README.md)
- **Integration Details:** [INTEGRATION_SUMMARY.md](INTEGRATION_SUMMARY.md)
- **Template Code:** [main.bicep](main.bicep)

## Need Help?

| Question                    | Resource                                                                                           |
| --------------------------- | -------------------------------------------------------------------------------------------------- |
| How do I deploy?            | See [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)                                             |
| What's in the template?     | See [main.bicep](main.bicep) and [README.md](README.md)                                            |
| What changed from original? | See [INTEGRATION_SUMMARY.md](INTEGRATION_SUMMARY.md)                                               |
| How do I access the app?    | See [README.md - Networking](README.md#networking)                                                 |
| How do I troubleshoot?      | See [DEPLOYMENT_CHECKLIST.md - Troubleshooting](DEPLOYMENT_CHECKLIST.md#troubleshooting-checklist) |

---

**Module Status:** ✅ Ready for Production Deployment
**Last Updated:** 2024
**Version:** 1.0

**Next Step:** [Run 4-Step Deploy](#quick-deploy-4-steps) or see [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) for detailed steps.
