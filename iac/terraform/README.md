# ============================================================================
# Terraform for Azure - Jobs Modernization
# Complete Infrastructure as Code using Terraform
# ============================================================================

## Overview

This directory contains Terraform configurations equivalent to the Bicep templates, following Azure and security best practices.

## Structure

```
terraform/
├── backend.tf              # Remote state configuration
├── backend-dev.hcl         # Dev backend config
├── provider.tf             # Azure provider setup
├── main.tf                 # Root module orchestration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── dev.tfvars              # Development environment
├── staging.tfvars          # Staging environment
├── prod.tfvars             # Production environment
├── core/                   # Networking, KeyVault, Log Analytics
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── iaas/                   # VMs for Web and SQL Server
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── paas/                   # App Service and Azure SQL
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── agents/                 # VMSS for CI/CD agents
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## Prerequisites

1. **Terraform** >= 1.6.0
2. **Azure CLI** installed and authenticated
3. **Azure Subscription** with appropriate permissions
4. **Backend Storage Account** (optional, for remote state)

## Quick Start

### 1. Initialize Backend (First Time)

Create storage account for Terraform state:

```powershell
# Set variables
$resourceGroup = "jobsite-tfstate-rg"
$storageAccount = "jobsitetfstatedev"
$location = "swedencentral"
$container = "tfstate"

# Create resource group
az group create --name $resourceGroup --location $location

# Create storage account
az storage account create `
  --resource-group $resourceGroup `
  --name $storageAccount `
  --sku Standard_LRS `
  --encryption-services blob `
  --https-only true `
  --min-tls-version TLS1_2

# Create container
az storage container create `
  --name $container `
  --account-name $storageAccount
```

### 2. Set Credentials

```powershell
# Export sensitive variables
$env:TF_VAR_sql_admin_password = "YourSecurePassword123!"
$env:TF_VAR_wfe_admin_password = "AnotherSecurePassword123!"
```

### 3. Initialize Terraform

```powershell
cd iac/terraform
terraform init -backend-config=backend-dev.hcl
```

### 4. Plan Deployment

```powershell
# Development environment
terraform plan -var-file="dev.tfvars" -out=tfplan

# Review the plan
terraform show tfplan
```

### 5. Apply Configuration

```powershell
terraform apply tfplan
```

## Deployment Scenarios

### Scenario 1: Development (IaaS Only)

```powershell
# dev.tfvars is configured for IaaS
terraform apply -var-file="dev.tfvars"
```

### Scenario 2: Staging (PaaS + Agents)

```powershell
# staging.tfvars enables PaaS and agents
terraform apply -var-file="staging.tfvars"
```

### Scenario 3: Production (PaaS + Agents)

```powershell
# prod.tfvars with production SKUs
terraform apply -var-file="prod.tfvars"
```

## Module Details

### Core Module
- **Virtual Network** with 7 subnets (frontend, data, GitHub runners, private endpoints, VPN gateway, AKS, Container Apps)
- **NAT Gateway** for outbound internet access
- **Key Vault** with RBAC, soft delete, purge protection
- **Log Analytics** and Application Insights
- **Private DNS Zone** for internal resolution
- **Container Registry** (Premium SKU)

### IaaS Module
- **Web Frontend VM** (Windows Server 2022)
- **SQL Server VM** (SQL Server 2022 on Windows Server 2022)
- **Load Balancer** with NAT rules for RDP
- **Network Security Groups** with least privilege rules
- **Managed Disks** (Premium SSD)
- **VM Extensions**: IIS, SQL, monitoring, anti-malware

### PaaS Module
- **App Service Plan** (Linux or Windows)
- **App Service** with managed identity
- **Azure SQL Server** with AAD authentication
- **Azure SQL Database** with TDE
- **Private Endpoints** for SQL
- **Diagnostic Settings**

### Agents Module
- **Virtual Machine Scale Set** (Windows Server 2022)
- **Auto-scaling** configuration
- **Azure DevOps agent** installation
- **Managed Identity**
- **Network integration**

## Security Features

✅ **Network Isolation**: Private subnets, NSGs, service endpoints  
✅ **Encryption**: TDE for SQL, disk encryption for VMs  
✅ **Key Management**: Azure Key Vault with RBAC  
✅ **Identity**: Managed identities, AAD integration  
✅ **Monitoring**: Log Analytics, Application Insights  
✅ **Access Control**: RBAC, conditional access policies  
✅ **Compliance**: Soft delete, purge protection, audit logs  

## Best Practices Implemented

1. **Modular Design**: Reusable modules for core, iaas, paas, agents
2. **State Management**: Remote state in Azure Storage with locking
3. **Variable Validation**: Input validation for critical parameters
4. **Sensitive Data**: Marked as sensitive, stored in Key Vault
5. **Tagging Strategy**: Consistent tagging across all resources
6. **Naming Convention**: Predictable, environment-specific naming
7. **Resource Dependencies**: Explicit depends_on for ordering
8. **Provider Features**: Soft delete, purge protection, graceful shutdown

## Environment Variables

```powershell
# Required
$env:TF_VAR_sql_admin_password = "<password>"
$env:TF_VAR_wfe_admin_password = "<password>"

# Optional (for Azure DevOps agents)
$env:TF_VAR_azuredevops_org_url = "https://dev.azure.com/yourorg"
$env:TF_VAR_azuredevops_pat = "<pat-token>"
$env:TF_VAR_azuredevops_agent_pool = "Default"
```

## Common Commands

```powershell
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy -var-file="dev.tfvars"

# Target specific module
terraform apply -target=module.core -var-file="dev.tfvars"

# Refresh state
terraform refresh -var-file="dev.tfvars"

# Output values
terraform output
```

## Outputs

After successful deployment:

```powershell
# Get all outputs
terraform output

# Get specific output
terraform output -raw key_vault_name
terraform output -json deployment_summary
```

## Troubleshooting

### Issue: State Lock

```powershell
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: Authentication

```powershell
# Re-authenticate with Azure
az login
az account set --subscription "<subscription-id>"
```

### Issue: Resource Already Exists

```powershell
# Import existing resource
terraform import module.core.azurerm_resource_group.core /subscriptions/<sub-id>/resourceGroups/<rg-name>
```

## Migration from Bicep

If migrating from existing Bicep deployments:

1. **Import existing resources** using `terraform import`
2. **Validate state** with `terraform plan`
3. **Apply incremental changes**
4. **Update CI/CD pipelines**

## CI/CD Integration

Terraform configs are integrated with:
- **GitHub Actions**: `.github/workflows/terraform-*.yml`
- **Azure DevOps**: `.azure-pipelines/terraform-*.yml`

## Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Best Practices](https://docs.microsoft.com/azure/architecture/framework/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## Support

For issues or questions, please refer to the main project README or open an issue in the repository.
