# ============================================================================
# Terraform Backend Configuration
# Azure Storage Account for State Management
# ============================================================================

terraform {
  backend "azurerm" {
    # Backend will be configured via backend config file or CLI
    # terraform init -backend-config=backend-dev.hcl
    
    # Uncomment and configure for direct usage:
    # resource_group_name  = "jobsite-tfstate-rg"
    # storage_account_name = "jobsitetfstate<uniqueid>"
    # container_name       = "tfstate"
    # key                  = "jobsite.terraform.tfstate"
  }
}
