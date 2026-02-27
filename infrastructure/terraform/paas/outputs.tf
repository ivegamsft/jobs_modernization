# ============================================================================
# PaaS Module Outputs
# ============================================================================

output "resource_group_name" {
  description = "The name of the PaaS resource group"
  value       = azurerm_resource_group.paas.name
}

output "resource_group_id" {
  description = "The ID of the PaaS resource group"
  value       = azurerm_resource_group.paas.id
}

output "app_service_name" {
  description = "The name of the App Service"
  value       = azurerm_windows_web_app.main.name
}

output "app_service_id" {
  description = "The ID of the App Service"
  value       = azurerm_windows_web_app.main.id
}

output "app_service_default_hostname" {
  description = "The default hostname of the App Service"
  value       = azurerm_windows_web_app.main.default_hostname
}

output "app_service_principal_id" {
  description = "The principal ID of the App Service managed identity"
  value       = azurerm_windows_web_app.main.identity[0].principal_id
}

output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_id" {
  description = "The ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_fqdn" {
  description = "The FQDN of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "sql_database_id" {
  description = "The ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
}

output "app_insights_instrumentation_key" {
  description = "The instrumentation key of Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "acr_name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "The login server of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_app_environment_id" {
  description = "The ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}
