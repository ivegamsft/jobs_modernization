# ============================================================================
# Terraform Variables
# Define all input variables for infrastructure deployment
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "application_name" {
  description = "Application name"
  type        = string
  default     = "jobsite"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# ============================================================================
# DEPLOYMENT OPTIONS
# ============================================================================

variable "deploy_iaas" {
  description = "Deploy IaaS resources (VMs)"
  type        = bool
  default     = true
}

variable "deploy_paas" {
  description = "Deploy PaaS resources (App Service, Azure SQL)"
  type        = bool
  default     = false
}

variable "deploy_agents" {
  description = "Deploy CI/CD agents (VMSS)"
  type        = bool
  default     = false
}

# ============================================================================
# NETWORKING
# ============================================================================

variable "vnet_address_prefix" {
  description = "Virtual Network address space"
  type        = string
  default     = "10.50.0.0/21"
}

# ============================================================================
# SECURITY & CREDENTIALS
# ============================================================================

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "jobsiteadmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password (20+ chars, mixed case, numbers, special chars)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.sql_admin_password) >= 20
    error_message = "SQL admin password must be at least 20 characters."
  }
}

variable "wfe_admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "azureadmin"
  sensitive   = true
}

variable "wfe_admin_password" {
  description = "VM administrator password (20+ chars, mixed case, numbers, special chars)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.wfe_admin_password) >= 20
    error_message = "VM admin password must be at least 20 characters."
  }
}

variable "allowed_rdp_ips" {
  description = "List of allowed IP addresses for RDP access (CIDR notation)"
  type        = list(string)
  default     = []
}

# ============================================================================
# IAAS CONFIGURATION
# ============================================================================

variable "vm_size" {
  description = "VM size for web servers"
  type        = string
  default     = "Standard_D2ds_v6"
}

variable "sql_vm_size" {
  description = "VM size for SQL Server"
  type        = string
  default     = "Standard_D4ds_v6"
}

# ============================================================================
# PAAS CONFIGURATION
# ============================================================================

variable "app_service_sku" {
  description = "App Service SKU"
  type        = string
  default     = "S1"
}

variable "sql_database_edition" {
  description = "Azure SQL Database edition"
  type        = string
  default     = "Standard"
}

variable "sql_service_objective" {
  description = "Azure SQL Database service objective"
  type        = string
  default     = "S1"
}

variable "sql_aad_admin_object_id" {
  description = "Azure AD admin object ID for SQL"
  type        = string
  default     = ""
}

variable "sql_aad_admin_name" {
  description = "Azure AD admin name for SQL"
  type        = string
  default     = ""
}

# ============================================================================
# AGENTS CONFIGURATION
# ============================================================================

variable "agent_vm_size" {
  description = "VM size for CI/CD agents"
  type        = string
  default     = "Standard_D2ds_v6"
}

variable "vmss_instance_count" {
  description = "Number of agent instances in VMSS"
  type        = number
  default     = 2
  
  validation {
    condition     = var.vmss_instance_count >= 1 && var.vmss_instance_count <= 100
    error_message = "VMSS instance count must be between 1 and 100."
  }
}

variable "azuredevops_org_url" {
  description = "Azure DevOps organization URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azuredevops_pat" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azuredevops_agent_pool" {
  description = "Azure DevOps agent pool name"
  type        = string
  default     = "Default"
}
