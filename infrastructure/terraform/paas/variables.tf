variable "environment" {
  type = string
}

variable "application_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_service_sku" {
  type = string
}

variable "sql_aad_admin_object_id" {
  type = string
}

variable "sql_aad_admin_name" {
  type = string
}

variable "pe_subnet_id" {
  type = string
}

variable "container_apps_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "core_resource_group_name" {
  type = string
}

variable "sql_database_sku" {
  type    = string
  default = "S0"
}

variable "app_insights_instrumentation_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tags" {
  type = map(string)
}
