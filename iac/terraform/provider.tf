# ============================================================================
# Provider Configuration
# Azure Resource Manager with Best Practices
# ============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  # Security: Use Managed Identity or Service Principal
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
}

provider "azuread" {
  # tenant_id = var.tenant_id
}
