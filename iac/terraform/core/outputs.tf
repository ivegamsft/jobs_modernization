# ============================================================================
# CORE MODULE - Outputs
# ============================================================================

output "resource_group_name" {
  description = "Core resource group name"
  value       = azurerm_resource_group.core.name
}

output "resource_group_id" {
  description = "Core resource group ID"
  value       = azurerm_resource_group.core.id
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "frontend_subnet_id" {
  description = "Frontend subnet ID"
  value       = azurerm_subnet.frontend.id
}

output "data_subnet_id" {
  description = "Data subnet ID"
  value       = azurerm_subnet.data.id
}

output "github_runners_subnet_id" {
  description = "GitHub Runners subnet ID"
  value       = azurerm_subnet.github_runners.id
}

output "pe_subnet_id" {
  description = "Private Endpoint subnet ID"
  value       = azurerm_subnet.private_endpoint.id
}

output "container_apps_subnet_id" {
  description = "Container Apps subnet ID"
  value       = azurerm_subnet.container_apps.id
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = azurerm_public_ip.nat.ip_address
}

output "container_registry_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}
