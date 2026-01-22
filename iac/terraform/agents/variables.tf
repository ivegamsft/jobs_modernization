variable "environment" {
  type = string
}

variable "application_name" {
  type = string
}

variable "location" {
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

variable "agent_vm_size" {
  type = string
}

variable "vmss_instance_count" {
  type = number
}

variable "azuredevops_org_url" {
  type      = string
  sensitive = true
  default   = ""
}

variable "azuredevops_pat" {
  type      = string
  sensitive = true
  default   = ""
}

variable "azuredevops_agent_pool" {
  type    = string
  default = "Default"
}

variable "github_runners_subnet_id" {
  type = string
}

variable "core_resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
