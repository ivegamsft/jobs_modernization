# ============================================================================
# CORE MODULE - Main Configuration
# Networking, Key Vault, Log Analytics, Private DNS
# ============================================================================

# Random suffix for unique naming
resource "random_string" "unique_suffix" {
  length  = 13
  special = false
  upper   = false
}

locals {
  resource_prefix = "${var.application_name}-${var.environment}"
  unique_suffix   = random_string.unique_suffix.result
  location_abbr   = var.location == "swedencentral" ? "swc" : substr(replace(var.location, " ", ""), 0, 3)

  # Subnet Configuration - Production Ready Sizing
  subnet_config = {
    frontend = {
      name   = "snet-fe"
      prefix = "10.50.0.0/24" # 251 usable IPs
    }
    data = {
      name   = "snet-data"
      prefix = "10.50.1.0/26" # 59 usable IPs
    }
    github_runners = {
      name   = "snet-gh-runners"
      prefix = "10.50.1.64/26" # 59 usable IPs
    }
    private_endpoint = {
      name   = "snet-pe"
      prefix = "10.50.1.128/27" # 27 usable IPs
    }
    vpn_gateway = {
      name   = "GatewaySubnet"
      prefix = "10.50.1.160/27" # 27 usable IPs
    }
    aks = {
      name   = "snet-aks"
      prefix = "10.50.2.0/23" # 507 usable IPs
    }
    container_apps = {
      name   = "snet-ca"
      prefix = "10.50.4.0/26" # 59 usable IPs
    }
  }
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "core" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# LOG ANALYTICS WORKSPACE
# ============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.resource_prefix}-la-${local.unique_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ============================================================================
# APPLICATION INSIGHTS
# ============================================================================

resource "azurerm_application_insights" "main" {
  name                = "${local.resource_prefix}-ai-${local.unique_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# ============================================================================
# NAT GATEWAY
# ============================================================================

resource "azurerm_public_ip" "nat" {
  name                = "${local.resource_prefix}-pip-nat-${local.unique_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = "${local.resource_prefix}-nat-${local.unique_suffix}"
  location                = azurerm_resource_group.core.location
  resource_group_name     = azurerm_resource_group.core.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  zones                   = ["1", "2", "3"]
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# ============================================================================
# VIRTUAL NETWORK
# ============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet-${local.unique_suffix}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = [var.vnet_address_prefix]
  tags                = var.tags
}

# Frontend Subnet (Web VMs / App Gateway)
resource "azurerm_subnet" "frontend" {
  name                 = local.subnet_config.frontend.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.frontend.prefix]

  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_nat_gateway_association" "frontend" {
  subnet_id      = azurerm_subnet.frontend.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Data Subnet (SQL VMs)
resource "azurerm_subnet" "data" {
  name                 = local.subnet_config.data.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.data.prefix]

  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_nat_gateway_association" "data" {
  subnet_id      = azurerm_subnet.data.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# GitHub Runners Subnet (Build Agents)
resource "azurerm_subnet" "github_runners" {
  name                 = local.subnet_config.github_runners.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.github_runners.prefix]

  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_nat_gateway_association" "github_runners" {
  subnet_id      = azurerm_subnet.github_runners.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Private Endpoint Subnet
resource "azurerm_subnet" "private_endpoint" {
  name                 = local.subnet_config.private_endpoint.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.private_endpoint.prefix]

  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# VPN Gateway Subnet
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.vpn_gateway.prefix]
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = local.subnet_config.aks.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.aks.prefix]

  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# Container Apps Subnet
resource "azurerm_subnet" "container_apps" {
  name                 = local.subnet_config.container_apps.name
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_config.container_apps.prefix]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# ============================================================================
# KEY VAULT
# ============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment}-${local.location_abbr}-${substr(local.unique_suffix, 0, 10)}"
  location                   = azurerm_resource_group.core.location
  resource_group_name        = azurerm_resource_group.core.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  rbac_authorization_enabled      = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"

    # Allow access from subnets
    virtual_network_subnet_ids = [
      azurerm_subnet.frontend.id,
      azurerm_subnet.data.id,
      azurerm_subnet.github_runners.id
    ]
  }

  tags = var.tags
}

# Store admin passwords in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "wfe_admin_password" {
  name         = "wfe-admin-password"
  value        = var.wfe_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# ============================================================================
# PRIVATE DNS ZONE
# ============================================================================

resource "azurerm_private_dns_zone" "main" {
  name                = "${var.application_name}.internal"
  resource_group_name = azurerm_resource_group.core.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "${azurerm_virtual_network.main.name}-link"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = true
  tags                  = var.tags
}

# ============================================================================
# CONTAINER REGISTRY (Optional - for containerized workloads)
# ============================================================================

resource "azurerm_container_registry" "main" {
  name                = "${var.application_name}${var.environment}acr${substr(local.unique_suffix, 0, 10)}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "Premium"
  admin_enabled       = false

  network_rule_set {
    default_action = "Deny"
  }

  tags = var.tags
}
