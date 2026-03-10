# Bootstrap Scripts

This directory contains scripts for initializing Azure infrastructure prerequisites before deploying the Jobs Modernization project.

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
-StorageAccountName # Storage account name (default: jobsitetfstate)
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

---

## Post-Bootstrap Steps

### 1. Configure GitHub Secrets

Navigate to: `https://github.com/{org}/{repo}/settings/secrets/actions`

Add these secrets (values printed by bootstrap script):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Application ID | `12345678-1234-...` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `87654321-4321-...` |
| `AZURE_SUBSCRIPTION_ID` | Target Azure Subscription ID | `abcdef12-3456-...` |

### 2. Verify OIDC Configuration

Your workflows should use this pattern:

```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

✅ All workflows in `.github/workflows/` are already configured this way.

### 3. Initialize Terraform (If Using)

```powershell
cd ../infrastructure/terraform

# Initialize with remote backend
terraform init -backend-config=backend-dev.hcl

# Verify
terraform plan -var-file=dev.tfvars
```

### 4. Deploy Infrastructure

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
