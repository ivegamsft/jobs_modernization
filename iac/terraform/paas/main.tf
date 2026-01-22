# PaaS Module - Placeholder
# TODO: Complete implementation based on Bicep paas-resources.bicep

resource "azurerm_resource_group" "paas" {
  name     = "${var.application_name}-paas-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Placeholder outputs
output "resource_group_name" {
  value = azurerm_resource_group.paas.name
}

output "app_service_name" {
  value = "TBD"
}

output "app_service_default_hostname" {
  value = "TBD"
}

output "sql_server_fqdn" {
  value = "TBD"
}

output "sql_database_name" {
  value = "TBD"
}
