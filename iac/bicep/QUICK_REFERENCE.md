# IaC Deployment Package - Quick Reference

## 📂 Files Created

```
iac/
├── 📄 main.bicep                     ← Main Bicep template (Azure infrastructure)
├── 🔧 main.dev.bicepparam          ← Dev environment config
├── 🔧 main.staging.bicepparam      ← Staging environment config
├── 🔧 main.prod.bicepparam         ← Production environment config
├── ⚙️  Deploy-Bicep.ps1            ← PowerShell deployment script (Windows)
├── ⚙️  deploy-bicep.sh              ← Bash deployment script (Linux/macOS)
├── 📖 README.md                     ← Complete documentation
├── 🚀 QUICK_START.md               ← 5-minute quick start
├── ✅ DEPLOYMENT_VALIDATION.md      ← Pre/post deployment checklist
├── 📋 PACKAGE_SUMMARY.md           ← Package overview
└── 📄 QUICK_REFERENCE.md           ← This file
```

## 🎯 Quick Commands

### Deploy Development Environment

**PowerShell:**

```powershell
./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg
```

**Bash:**

```bash
./deploy-bicep.sh dev jobsite-dev-rg
```

**Azure CLI:**

```bash
az deployment group create \
  --name jobsite-deploy-dev \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam
```

### Deploy Production Environment

**PowerShell:**

```powershell
./Deploy-Bicep.ps1 -Environment prod -ResourceGroupName jobsite-prod-rg
```

**Bash:**

```bash
./deploy-bicep.sh prod jobsite-prod-rg
```

## 🏗️ Resources Created

### Compute

- **App Service** - Hosts your .NET application
- **App Service Plan** - Compute resources with auto-scale capability

### Database

- **SQL Server** - Database server with TLS 1.2+ enforcement
- **SQL Database** - Application database with automated backups

### Security

- **Key Vault** - Stores connection strings and secrets
- **Managed Identity** - Secure credential access for App Service

### Monitoring

- **Application Insights** - Application performance monitoring
- **Log Analytics Workspace** - Centralized logging and diagnostics
- **Storage Account** - Diagnostic logs and blobs

## 📊 Environment Defaults

### Development (B2 / S0)

```
App Service:       B2 (2 cores, 3.5 GB)
SQL Database:      Standard S0 (10 DTUs)
Estimated Cost:    ~$90/month
Purpose:           Development and testing
```

### Staging (S1 / S1)

```
App Service:       S1 (1 core, 1.75 GB)
SQL Database:      Standard S1 (20 DTUs)
Estimated Cost:    ~$125/month
Purpose:           Pre-production testing
```

### Production (P1V2 / P2)

```
App Service:       P1V2 (2 cores, 3.5 GB, always-on)
SQL Database:      Premium P2 (250 DTUs)
Estimated Cost:    ~$420/month
Purpose:           Production workloads
```

## ⚙️ Configuration Steps

### 1. Update Parameters

Edit the appropriate parameter file:

```bicepparam
# main.dev.bicepparam (for dev)
# main.staging.bicepparam (for staging)
# main.prod.bicepparam (for production)

param sqlAdminPassword = 'YourStrongPassword!'  # ⚠️ CHANGE THIS!
param alertEmail = 'your-email@company.com'
param location = 'eastus'  # Change if needed
param appServiceSku = 'B2'  # Adjust sizing as needed
```

### 2. Run Deployment

```powershell
./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg
```

### 3. Capture Outputs

```bash
# Get your App Service URL
az deployment group show \
  --resource-group jobsite-dev-rg \
  --name jobsite-deploy-dev \
  --query "properties.outputs.appServiceUrl.value" -o tsv
```

### 4. Deploy Application

```powershell
# Package your app
Compress-Archive -Path "C:\path\to\app\*" -DestinationPath app.zip

# Deploy to App Service
az webapp deployment source config-zip \
  --resource-group jobsite-dev-rg \
  --name jobsite-app-dev-xxxxx \
  --src app.zip
```

## 🔑 Key Parameters

| Parameter             | Purpose                | Example                |
| --------------------- | ---------------------- | ---------------------- |
| `environment`         | Environment name       | dev, staging, prod     |
| `applicationName`     | Used in resource names | jobsite                |
| `location`            | Azure region           | eastus, westus2        |
| `appServiceSku`       | Compute size           | B1, S1, P1V2           |
| `sqlDatabaseEdition`  | SQL edition            | Standard, Premium      |
| `sqlServiceObjective` | SQL performance        | S0, S1, P1, P2         |
| `sqlAdminUsername`    | Database admin         | sqladmin               |
| `sqlAdminPassword`    | Database password      | **CHANGE THIS**        |
| `alertEmail`          | Alert recipient        | your-email@company.com |

## 📦 What Gets Deployed

| Resource                     | Count | Details                   |
| ---------------------------- | ----- | ------------------------- |
| **App Services**             | 1     | Hosts your application    |
| **SQL Servers**              | 1     | Database server           |
| **SQL Databases**            | 1     | jobsitedb database        |
| **Key Vaults**               | 1     | Secure secrets storage    |
| **App Insights**             | 1     | Monitoring and telemetry  |
| **Log Analytics Workspaces** | 1     | Centralized logging       |
| **Storage Accounts**         | 1     | Diagnostics storage       |
| **Managed Identities**       | 1     | Secure access credentials |
| **Firewall Rules**           | 2     | Azure Services + Local    |
| **Total Cost Resources**     | 11    | See pricing below         |

## 💾 Security Built-In

✅ **HTTPS Enforced** - All connections are HTTPS only  
✅ **TLS 1.2+** - Modern encryption minimum  
✅ **Secrets in Key Vault** - No hardcoded credentials  
✅ **Managed Identity** - Secure credential access  
✅ **Firewall Rules** - Database access restricted  
✅ **Encryption at Rest** - Storage and database encrypted  
✅ **Diagnostics Enabled** - Full audit trail  
✅ **Backup Configured** - Daily automated backups

## 🚀 Deployment Flow

```
1. Update Parameters (5 min)
   └─ Edit main.dev.bicepparam

2. Validate Template (2 min)
   └─ Check syntax and resources

3. Create Resource Group (1 min)
   └─ Created automatically if not exists

4. Deploy Resources (10-15 min)
   ├─ App Service Plan
   ├─ App Service
   ├─ SQL Server
   ├─ SQL Database
   ├─ Key Vault
   ├─ App Insights
   └─ Log Analytics

5. Get Outputs (1 min)
   └─ URLs, names, connection strings

6. Deploy Application (5-10 min)
   ├─ Package app as ZIP
   ├─ Update web.config
   └─ Deploy to App Service

7. Test Application (5-10 min)
   └─ Verify functionality
```

**Total Time: 30-50 minutes**

## 🔍 Validation Commands

### Before Deployment

```bash
# Validate template syntax
az deployment group validate \
  --resource-group jobsite-dev-rg \
  --template-file main.bicep \
  --parameters main.dev.bicepparam

# Check subscription quota
az vm list-usage --location eastus -o table
```

### After Deployment

```bash
# Get all resource details
az resource list --resource-group jobsite-dev-rg -o table

# Test SQL connectivity
sqlcmd -S jobsite-sql-dev-xxxxx.database.windows.net \
       -U sqladmin \
       -P "YourPassword" \
       -d jobsitedb \
       -Q "SELECT @@version"

# Check App Service status
az webapp show --resource-group jobsite-dev-rg --name jobsite-app-dev-xxxxx
```

## 💰 Cost Control

### Estimate Costs

```bash
# View resource pricing
az cost management query --query-definition ...

# Or use Azure Pricing Calculator
# https://azure.microsoft.com/en-us/pricing/calculator/
```

### Reduce Costs

- Use **smaller SKUs** for dev/staging
- Enable **auto-shutdown** for dev environments
- Use **spot instances** for non-critical workloads
- Review **utilization metrics** monthly
- **Delete unused resources** promptly

## 📋 Pre-Deployment Checklist

- [ ] Azure CLI or PowerShell installed
- [ ] Logged into Azure (`az login`)
- [ ] **Changed SQL password** in parameters
- [ ] Verified resource group name is unique
- [ ] Reviewed cost estimates
- [ ] Confirmed all parameters are correct
- [ ] Scheduled deployment time
- [ ] Notified team members

## 📋 Post-Deployment Checklist

- [ ] All resources created successfully
- [ ] App Service shows "Running" status
- [ ] SQL Database is "Online"
- [ ] Can connect to database
- [ ] Application deployed successfully
- [ ] Application loads without errors
- [ ] Monitoring is working
- [ ] Backups are configured

## 🆘 Common Issues

| Issue                   | Solution                                  |
| ----------------------- | ----------------------------------------- |
| Deployment timeout      | Increase timeout or use `--no-wait`       |
| SQL connection fails    | Check firewall rules and credentials      |
| App shows 500 error     | Review App Insights and application logs  |
| High cost               | Review SKU sizes and resource utilization |
| Key Vault access denied | Verify Managed Identity has access policy |

## 📖 Documentation Map

| File                         | Purpose                 | Time   |
| ---------------------------- | ----------------------- | ------ |
| **QUICK_START.md**           | Get running fast        | 5 min  |
| **README.md**                | Complete reference      | 30 min |
| **DEPLOYMENT_VALIDATION.md** | Comprehensive checklist | 20 min |
| **PACKAGE_SUMMARY.md**       | Package overview        | 10 min |
| **QUICK_REFERENCE.md**       | This file - commands    | 2 min  |

## 🎓 Learn More

- [Bicep Official Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Deployment](https://learn.microsoft.com/azure/app-service/)
- [Azure SQL Best Practices](https://learn.microsoft.com/azure/azure-sql/)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)

## 🚀 Get Started Now!

### Option 1: Super Quick (5 minutes)

1. Edit `main.dev.bicepparam` (change SQL password)
2. Run `./Deploy-Bicep.ps1 -Environment dev -ResourceGroupName jobsite-dev-rg`
3. Done! ✅

### Option 2: With Validation (15 minutes)

1. Read [QUICK_START.md](QUICK_START.md)
2. Update parameters
3. Run deployment script
4. Verify resources in Azure Portal

### Option 3: Complete Approach (30 minutes)

1. Read [README.md](README.md) completely
2. Complete [DEPLOYMENT_VALIDATION.md](DEPLOYMENT_VALIDATION.md) checklist
3. Deploy infrastructure
4. Deploy application
5. Run full validation

---

**Need help? Check [README.md](README.md) or [QUICK_START.md](QUICK_START.md)** 📚
