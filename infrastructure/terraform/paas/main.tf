# ============================================================================
# PaaS Module - Platform as a Service Resources
# Deploys App Service, Azure SQL Database, Container Registry
# ============================================================================

locals {
  unique_suffix   = substr(md5("${azurerm_resource_group.paas.id}-${var.location}"), 0, 13)
  resource_prefix = "${var.application_name}-${var.environment}"
}

data "azurerm_client_config" "current" {}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "paas" {
  name     = "${var.application_name}-paas-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# APP SERVICE PLAN & APP SERVICE
# ============================================================================

resource "azurerm_service_plan" "main" {
  name                = "${var.application_name}-asp-${var.environment}-${local.unique_suffix}"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  os_type             = "Windows"
  sku_name            = var.app_service_sku
  tags                = var.tags
}

resource "azurerm_windows_web_app" "main" {
  name                = "${var.application_name}-app-${var.environment}-${local.unique_suffix}"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on                         = true
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    use_32_bit_worker                 = false
    vnet_route_all_enabled            = false
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 10

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v4.0"
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = var.app_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = var.app_insights_connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  identity {
    type = "SystemAssigned"
  }
}

# ============================================================================
# AZURE SQL SERVER & DATABASE
# ============================================================================

resource "azurerm_mssql_server" "main" {
  name                          = "${var.application_name}-sql-${var.environment}-${local.unique_suffix}"
  location                      = azurerm_resource_group.paas.location
  resource_group_name           = azurerm_resource_group.paas.name
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags

  azuread_administrator {
    login_username              = var.sql_aad_admin_name
    object_id                   = var.sql_aad_admin_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_database" "main" {
  name           = "${var.application_name}db"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 250
  sku_name       = var.sql_database_sku
  zone_redundant = false
  tags           = var.tags
}

# Grant App Service Managed Identity access to SQL Database
resource "azurerm_role_assignment" "app_to_sql" {
  scope                = azurerm_mssql_database.main.id
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_windows_web_app.main.identity[0].principal_id
}

# ============================================================================
# PRIVATE ENDPOINT FOR SQL SERVER
# ============================================================================

resource "azurerm_private_endpoint" "sql" {
  name                = "${azurerm_mssql_server.main.name}-pe"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${azurerm_mssql_server.main.name}-pe-connection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

# ============================================================================
# APPLICATION INSIGHTS
# ============================================================================

resource "azurerm_application_insights" "main" {
  name                = "${var.application_name}-ai-${var.environment}"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = var.tags
}

# ============================================================================
# CONTAINER REGISTRY (Optional - Basic tier for cost optimization)
# ============================================================================

resource "azurerm_container_registry" "main" {
  name                = "${var.application_name}acr${var.environment}${substr(local.unique_suffix, 0, 8)}"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Grant App Service pull access to ACR
resource "azurerm_role_assignment" "app_to_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_windows_web_app.main.identity[0].principal_id
}

# ============================================================================
# CONTAINER APPS ENVIRONMENT (for future containerization)
# ============================================================================

resource "azurerm_container_app_environment" "main" {
  name                           = "${var.application_name}-cae-${var.environment}"
  location                       = azurerm_resource_group.paas.location
  resource_group_name            = azurerm_resource_group.paas.name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.container_apps_subnet_id
  internal_load_balancer_enabled = true
  tags                           = var.tags
}
