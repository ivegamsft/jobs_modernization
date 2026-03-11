# Bootstrap Scripts

This directory contains scripts for initializing Azure infrastructure prerequisites before deploying the Jobs Modernization project.

## ⚡ Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│ Bootstrap in 4 Steps                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 1️⃣  RUN BOOTSTRAP SCRIPT                                        │
│     $ cd bootstrap                                              │
│     $ .\bootstrap-azure.ps1                                    │
│     → Creates Service Principal + Terraform backend             │
│                                                                 │
│ 2️⃣  COPY SECRETS (from script output)                           │
│     AZURE_CLIENT_ID = ...                                      │
│     AZURE_TENANT_ID = ...                                      │
│     AZURE_SUBSCRIPTION_ID = ...                                │
│                                                                 │
│ 3️⃣  ADD TO GITHUB SECRETS                                       │
│     Settings → Secrets and variables → Actions                 │
│     Add 3 repository secrets (above)                           │
│                                                                 │
│ 4️⃣  VERIFY & DEPLOY                                             │
│     Test: Actions → Deploy Core Infrastructure → Run workflow   │
│     Look for: ✅ "Successfully authenticated with Azure"       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

⏱️  Total Time: ~5 minutes
📋 Manual Steps: 3 (run, copy, paste to GitHub)
🔐 Secrets Used: 3 (SERVICE PRINCIPAL)
✅ Workflows Ready: 5 (auto-configured)
```

## Purpose

Before you can deploy infrastructure using Bicep, Terraform, or GitHub Actions workflows, you need:

1. **Service Principal with OIDC** - For GitHub Actions to authenticate to Azure
2. **Terraform Backend Storage** - For storing Terraform remote state (if using Terraform)

These bootstrap scripts automate the one-time setup of these prerequisites.

---

## Quick Start

### Prerequisites

- **Azure CLI** - [Install](https://aka.ms/azure-cli)
- **PowerShell 7+** - [Install](https://aka.ms/powershell)
- **Azure Subscription** - With Owner or User Access Administrator role
- **Permissions** - Ability to create Azure AD applications and service principals
- **Storage data-plane access** - If reusing an existing storage account for Terraform state, your signed-in identity may also need **Storage Blob Data Contributor** on that storage account

### Login to Azure

```powershell
az login
az account set --subscription "Your-Subscription-Name-or-ID"
```

### Run Bootstrap

**Option 1: Complete Bootstrap (Recommended)**

Creates both Service Principal and Terraform backend:

```powershell
cd bootstrap
.\bootstrap-azure.ps1
```

**Option 2: Subscription-Scoped Permissions**

Grant Service Principal access to entire subscription:

```powershell
.\bootstrap-azure.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -Location "eastus"
```

**Option 3: Resource Group-Scoped Permissions (More Restrictive)**

Grant Service Principal access only to specific resource groups:

```powershell
.\bootstrap-azure.ps1 -ResourceGroupScope @('jobsite-dev-rg', 'jobsite-prod-rg')
```

**Option 4: Custom GitHub Org/Repo**

If you've forked this repository:

```powershell
.\bootstrap-azure.ps1 -GitHubOrg "your-org" -GitHubRepo "your-repo"
```

---

## Scripts

### 1. `bootstrap-azure.ps1` (Master Orchestrator)

**What it does:**
- Validates prerequisites (Azure CLI, PowerShell version, Azure login)
- Orchestrates execution of other bootstrap scripts
- Provides consolidated output and next steps

**Parameters:**
```powershell
-SubscriptionId       # Azure Subscription ID (optional, uses current if not provided)
-Location             # Azure region (default: swedencentral)
-ResourceGroupScope   # Array of RG names for scoped permissions (optional)
-SkipServicePrincipal # Skip SP creation if already exists
-SkipTerraformBackend # Skip Terraform backend if not needed
-GitHubOrg            # GitHub organization (default: chikamsoachumsft)
-GitHubRepo           # GitHub repository (default: jobs_modernization)
```

**Usage:**
```powershell
# Full bootstrap with defaults
.\bootstrap-azure.ps1

# Skip Terraform backend if not using Terraform
.\bootstrap-azure.ps1 -SkipTerraformBackend

# Re-run only Service Principal setup
.\bootstrap-azure.ps1 -SkipTerraformBackend
```

---

### 2. `bootstrap-service-principal.ps1`

**What it does:**
- Creates Azure AD Application and Service Principal
- Assigns Contributor role (subscription or resource group scoped)
- Creates GitHub OIDC federated credentials for:
  - Main branch deployments
  - Environment-specific deployments (dev, staging, prod)

**Parameters:**
```powershell
-AppName                    # Service Principal display name
-SubscriptionId             # Target subscription
-ResourceGroupScope         # Optional RG scoping
-GitHubOrg                  # GitHub org
-GitHubRepo                 # GitHub repo
-GitHubEnvironments         # Environments for OIDC (default: dev, staging, prod)
-CreateMainBranchCredential # Create main branch credential (default: true)
```

**Manual Usage:**
```powershell
# Basic - subscription-level access
.\bootstrap-service-principal.ps1

# Resource group-scoped
.\bootstrap-service-principal.ps1 -ResourceGroupScope @('rg1', 'rg2')

# Custom environments
.\bootstrap-service-principal.ps1 -GitHubEnvironments @('dev', 'test', 'prod')
```

**Output:**
- Application ID (AZURE_CLIENT_ID)
- Tenant ID (AZURE_TENANT_ID)
- Subscription ID (AZURE_SUBSCRIPTION_ID)

**Copy these values to GitHub Secrets!**

---

### 3. `bootstrap-terraform-backend.ps1`

**What it does:**
- Creates resource group for Terraform state
- Creates storage account with appropriate settings
- Creates storage container for `.tfstate` files
- Outputs backend configuration

**Parameters:**
```powershell
-ResourceGroupName  # RG name (default: jobsite-tfstate-rg)
-StorageAccountName # Storage account name (optional, auto-generated if omitted)
-Location           # Azure region (default: swedencentral)
-ContainerName      # Container name (default: tfstate)
-SubscriptionId     # Target subscription (optional)
```

**Manual Usage:**
```powershell
# Basic
.\bootstrap-terraform-backend.ps1

# Custom names and location
.\bootstrap-terraform-backend.ps1 `
  -ResourceGroupName "my-tfstate-rg" `
  -StorageAccountName "mytfstate001" `
  -Location "eastus"
```

**Output:**
- Resource group created
- Storage account created
- Container created
- Backend configuration for `terraform init`

**Note:** Storage account names are globally unique in Azure. If you do not pass `-StorageAccountName`, the script generates a unique default based on the current subscription ID.

The backend script uses your Azure login (`--auth-mode login`) for container operations. This avoids failures on storage accounts where key-based authentication is disabled.

---

## Post-Bootstrap Steps

### ⚠️ REQUIRED: Configure GitHub Secrets

**These steps are REQUIRED before workflows can deploy to Azure.**

#### Step 1: Copy Bootstrap Output

After running the bootstrap script, you'll see output like:

```
✅ Service Principal Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add these secrets to GitHub:

AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789abc
AZURE_TENANT_ID=87654321-4321-4321-4321-cba987654321
AZURE_SUBSCRIPTION_ID=aaaabbbb-cccc-dddd-eeee-ffffffff0000
```

**Copy these three values exactly as shown.**

#### Step 2: Add Secrets to GitHub Actions

1. Go to your repository on GitHub
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret** (green button)

Add each secret one at a time:

**Secret #1: AZURE_CLIENT_ID**
- Name: `AZURE_CLIENT_ID`
- Value: `12345678-1234-1234-1234-123456789abc` (from bootstrap output)
- Click **Add secret**

**Secret #2: AZURE_TENANT_ID**
- Name: `AZURE_TENANT_ID`
- Value: `87654321-4321-4321-4321-cba987654321` (from bootstrap output)
- Click **Add secret**

**Secret #3: AZURE_SUBSCRIPTION_ID**
- Name: `AZURE_SUBSCRIPTION_ID`
- Value: `aaaabbbb-cccc-dddd-eeee-ffffffff0000` (from bootstrap output)
- Click **Add secret**

#### Step 3: Verify Secrets Are Configured

After adding all 3 secrets, you should see:

```
AZURE_CLIENT_ID
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID
```

Listed in the repository secrets.

**Do NOT include these secrets in code or commit to git.**

### 2. Verify OIDC Configuration in Workflows

Your workflows automatically use this pattern:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    
    permissions:
      id-token: write      # Required for OIDC
      contents: read

    steps:
      - name: Azure Login with OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

✅ **All deployment workflows already configured this way:**
- `deploy-core.yml` - Core networking, ACR, Key Vault
- `deploy-iaas.yml` - Virtual machines, SQL Server
- `deploy-paas.yml` - App Services, Azure SQL Database
- `deploy-phase1-app-paas.yml` - Legacy .NET 4.8 application (PaaS)
- `deploy-phase1-app-iaas.yml` - Legacy .NET 4.8 application (IaaS)

### 3. Required Secrets and App Settings Contract

The stack now uses an explicit dependency contract from IaC outputs to app deployment.

#### Repository Secrets Required

| Secret | Used By | Purpose |
|---|---|---|
| `AZURE_CLIENT_ID` | All deploy workflows | OIDC auth client ID |
| `AZURE_TENANT_ID` | All deploy workflows | OIDC tenant |
| `AZURE_SUBSCRIPTION_ID` | All deploy workflows | OIDC subscription |
| `SQL_AAD_ADMIN_OBJECT_ID` | `deploy-paas.yml` | Required input for Azure SQL AAD admin |
| `SQL_AAD_ADMIN_NAME` | `deploy-paas.yml` | Required input for Azure SQL AAD admin |
| `SQL_ADMIN_LOGIN` | `deploy-database-dac-paas.yml` | SQL auth login for DACPAC publish |
| `SQL_ADMIN_PASSWORD` | `deploy-database-dac-paas.yml`, `deploy-database-dac-iaas.yml` | SQL auth password for DACPAC publish |
| `VM_ADMIN_USERNAME` | `deploy-phase1-app-iaas.yml` | WinRM/PowerShell remoting user |
| `VM_ADMIN_PASSWORD` | `deploy-phase1-app-iaas.yml` | WinRM/PowerShell remoting password |

#### App Service App Settings Applied by Workflow

`deploy-phase1-app-paas.yml` automatically sets these in App Service:

| App Setting | Source |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | Workflow environment input |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | PaaS IaC output |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | PaaS IaC output |
| `JOBSITE_SQL_SERVER` | PaaS IaC output (`sqlServerName`) |
| `JOBSITE_SQL_DATABASE` | PaaS IaC output (`sqlDatabaseName`) |
| `WEBSITE_RUN_FROM_PACKAGE` | Static value `1` |

#### Cross-Workflow Dependency Artifacts

Each workflow exports an environment-specific dependency artifact for downstream workflows:

| Workflow | Artifact |
|---|---|
| `deploy-core.yml` | `core-deployment-outputs-{environment}` |
| `deploy-iaas.yml` | `iaas-deployment-outputs-{environment}` |
| `deploy-paas.yml` | `paas-deployment-outputs-{environment}` |
| `deploy-phase1-app-paas.yml` | `phase1-app-paas-dependencies-{environment}` |
| `deploy-phase1-app-iaas.yml` | `phase1-app-iaas-dependencies-{environment}` |
| `deploy-database-dac-paas.yml` | `database-paas-dependencies-{environment}` |
| `deploy-database-dac-iaas.yml` | `database-iaas-dependencies-{environment}` |
| `deploy-agents.yml` | `agents-deployment-outputs-{environment}` |
| `deploy-vpn.yml` | `vpn-deployment-outputs-{environment}` |

For manual (`workflow_dispatch`) app/database deploys, pass `build_run_id` so artifact download can resolve the triggering build run.

### 4. Initialize Terraform (If Using)

```powershell
cd ../infrastructure/terraform

# Initialize with remote backend
terraform init -backend-config=backend-dev.hcl

# Verify
terraform plan -var-file=dev.tfvars
```

### 5. Verify OIDC Authentication ✅

Before deploying, verify your OIDC setup works:

**Option A: Run a Test Deployment Workflow**

1. Go to GitHub repository → **Actions** tab
2. Click **Deploy Core Infrastructure** workflow
3. Click **Run workflow** (green button)
4. Select environment: `dev`
5. Click **Run workflow**
6. Watch the logs - should show:
   ```
   ✅ Welcome to github-actions-oidc
   ✅ Successfully authenticated with Azure using OIDC
   ```

**Option B: Manual Verification with Azure CLI**

```powershell
# Login as Service Principal (locally)
az login --service-principal `
  -u $AZURE_CLIENT_ID `
  --tenant $AZURE_TENANT_ID

# Check subscription
az account show --subscription $AZURE_SUBSCRIPTION_ID

# Expected output: Your subscription details with owner: "github-actions-oidc"
```

### 6. Deploy Infrastructure

Choose your deployment path:

**Bicep (Recommended):**
```powershell
cd ../infrastructure/scripts
.\deploy-core.ps1 -Environment dev
```

**Terraform:**
```powershell
cd ../infrastructure/terraform
terraform apply -var-file=dev.tfvars
```

---

## Troubleshooting

### Error: "Azure CLI not found"

Install Azure CLI: https://aka.ms/azure-cli

### Error: "Not logged in to Azure"

```powershell
az login
az account set --subscription "Your-Subscription-ID"
```

### Error: "Insufficient permissions"

You need one of these roles on the subscription:
- Owner
- User Access Administrator + Contributor

And this Azure AD permission:
- Application Administrator (or Global Administrator)

### Error: "Storage account name already taken"

Storage account names are globally unique. Choose a different name:

```powershell
.\bootstrap-terraform-backend.ps1 -StorageAccountName "myuniquename$(Get-Random -Maximum 9999)"
```

### Federated Credential Already Exists

The script will update existing credentials. If you need to delete and recreate:

```powershell
# List credentials
az ad app federated-credential list --id <app-object-id>

# Delete specific credential
az ad app federated-credential delete --id <app-object-id> --federated-credential-id <cred-id>
```

### ⚠️ OIDC Issues in Workflows

#### Error: "Unauthorized: The service principal does not have explicit permissions"

**Cause:** GitHub Secrets not configured

**Solution:**
1. Run bootstrap script again to get exact values
2. Add all 3 secrets to GitHub:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
3. Verify secrets are listed in Settings → Secrets → Actions
4. Re-run workflow

#### Error: "Invalid resource group" or "Resource not found" in workflow

**Cause:** Workflow running but Azure login failing silently

**Solution:**
1. Check workflow logs for Azure login step
2. Verify secrets are correct in GitHub
3. Ensure Service Principal has permissions for the resource group
4. Run locally to verify: `az login --service-principal -u $AZURE_CLIENT_ID --tenant $AZURE_TENANT_ID`

#### Error: "Insufficient permissions" in workflow

**Cause:** Service Principal doesn't have access to target resource group

**Solution:**
```powershell
# Re-run bootstrap with resource group scope
.\bootstrap-azure.ps1 -ResourceGroupScope @('target-rg-name')
```

#### Workflow never appears in Actions tab

**Cause:** Secrets not configured yet

**Solution:**
- Workflows won't trigger automatically until secrets are added
- Add all 3 secrets to GitHub first
- Push a new commit to trigger workflows
- Or manually trigger via "Run workflow" button

---

## Security Notes

### Service Principal Permissions

By default, the Service Principal gets **Contributor** role:
- ✅ Can create/modify/delete Azure resources
- ❌ Cannot manage role assignments
- ❌ Cannot modify policies

**Subscription-scoped** (default):
- Full access to all resources in the subscription
- Suitable for development/testing
- **Recommended:** Use resource group scoping for production

**Resource group-scoped** (recommended for production):
```powershell
.\bootstrap-azure.ps1 -ResourceGroupScope @(
    'jobsite-dev-rg',
    'jobsite-staging-rg', 
    'jobsite-prod-rg'
)
```

### OIDC vs Secrets

This setup uses **OIDC (Federated Credentials)** which is more secure than long-lived secrets:

✅ **OIDC Benefits:**
- No secrets to rotate
- Token lifetime is 5 minutes
- Locked to specific GitHub org/repo/environment
- No secret stored in GitHub

❌ **Traditional Secrets:**
- Long-lived credentials
- Must rotate regularly
- Risk if GitHub compromised

### Terraform State Security

The Terraform backend storage account:
- Uses HTTPS only
- Enables versioning (recover deleted state)
- Uses Azure AD authentication
- Lifecycle management for old versions

---

## Re-Running Bootstrap

### Update Service Principal

To add new GitHub environments or change permissions:

```powershell
.\bootstrap-service-principal.ps1 -GitHubEnvironments @('dev', 'staging', 'prod', 'preview')
```

### Recreate from Scratch

```powershell
# Delete existing Service Principal
az ad app delete --id <app-id>

# Delete Terraform backend (WARNING: deletes state!)
az group delete --name jobsite-tfstate-rg --yes

# Re-run bootstrap
.\bootstrap-azure.ps1
```

---

## Multi-Subscription Setup

For production scenarios with separate subscriptions:

```powershell
# Dev subscription
.\bootstrap-azure.ps1 -SubscriptionId "dev-sub-id" -GitHubEnvironments @('dev')

# Staging subscription  
.\bootstrap-azure.ps1 -SubscriptionId "staging-sub-id" -GitHubEnvironments @('staging')

# Prod subscription
.\bootstrap-azure.ps1 -SubscriptionId "prod-sub-id" -GitHubEnvironments @('prod')
```

Then create environment-specific GitHub secrets:
- `AZURE_CLIENT_ID_DEV`, `AZURE_CLIENT_ID_PROD`
- `AZURE_SUBSCRIPTION_ID_DEV`, `AZURE_SUBSCRIPTION_ID_PROD`

---

## Related Documentation

- **Infrastructure README:** `../infrastructure/README.md`
- **Workflow Organization:** `../.github/workflows/WORKFLOW_ORGANIZATION.md`
- **Bicep Deployment Guide:** `../infrastructure/bicep/README.md`
- **Terraform Guide:** `../infrastructure/terraform/README.md`

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Azure CLI error messages
3. Verify Azure subscription permissions
4. Check GitHub repository settings

---

**Last Updated:** March 2026  
**Scripts Version:** 1.0.0
