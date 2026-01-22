# Agents Module - Placeholder
# TODO: Complete implementation based on Bicep agents-resources.bicep

resource "azurerm_resource_group" "agents" {
  name     = "${var.application_name}-agents-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Placeholder outputs
output "resource_group_name" {
  value = azurerm_resource_group.agents.name
}

output "vmss_name" {
  value = "TBD"
}

output "vmss_id" {
  value = "TBD"
}
