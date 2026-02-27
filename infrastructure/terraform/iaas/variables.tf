variable "environment" {
  type = string
}

variable "application_name" {
  type = string
}

variable "location" {
  type = string
}

variable "frontend_subnet_id" {
  type = string
}

variable "data_subnet_id" {
  type = string
}

variable "admin_username" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_size" {
  type = string
}

variable "sql_vm_size" {
  type = string
}

variable "allowed_rdp_ips" {
  type    = list(string)
  default = []
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

variable "wfe_admin_password" {
  type      = string
  sensitive = true
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}
