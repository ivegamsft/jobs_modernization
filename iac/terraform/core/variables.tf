# ============================================================================
# CORE MODULE - Variables
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "application_name" {
  description = "Application name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_address_prefix" {
  description = "Virtual Network address space"
  type        = string
}

variable "sql_admin_username" {
  description = "SQL admin username"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

variable "wfe_admin_username" {
  description = "VM admin username"
  type        = string
  sensitive   = true
}

variable "wfe_admin_password" {
  description = "VM admin password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}
