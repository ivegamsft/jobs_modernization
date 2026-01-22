# IaaS Module - Placeholder
# TODO: Complete implementation based on Bicep iaas-resources.bicep

resource "azurerm_resource_group" "iaas" {
  name     = "${var.application_name}-iaas-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Placeholder outputs
output "resource_group_name" {
  value = azurerm_resource_group.iaas.name
}

output "load_balancer_public_ip" {
  value = "TBD"
}

output "wfe_vm_name" {
  value = "TBD"
}

output "sql_vm_name" {
  value = "TBD"
}
