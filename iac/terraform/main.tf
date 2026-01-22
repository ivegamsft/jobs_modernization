# ============================================================================
# Main Terraform Configuration
# Orchestrates deployment of all infrastructure layers
# ============================================================================

# Data source for current Azure subscription
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# ============================================================================
# CORE INFRASTRUCTURE MODULE
# Networking, KeyVault, Log Analytics, Private DNS
# ============================================================================

module "core" {
  source = "./core"

  environment         = var.environment
  application_name    = var.application_name
  location            = var.location
  vnet_address_prefix = var.vnet_address_prefix

  # Security credentials
  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password
  wfe_admin_username = var.wfe_admin_username
  wfe_admin_password = var.wfe_admin_password

  tags = local.common_tags
}

# ============================================================================
# IAAS MODULE (VMs for Web and SQL Server)
# Conditional deployment based on var.deploy_iaas
# ============================================================================

module "iaas" {
  source = "./iaas"
  count  = var.deploy_iaas ? 1 : 0

  environment      = var.environment
  application_name = var.application_name
  location         = var.location

  # Network dependencies from core
  frontend_subnet_id = module.core.frontend_subnet_id
  data_subnet_id     = module.core.data_subnet_id

  # VM Configuration
  admin_username  = var.wfe_admin_username
  admin_password  = var.wfe_admin_password
  vm_size         = var.vm_size
  sql_vm_size     = var.sql_vm_size
  allowed_rdp_ips = var.allowed_rdp_ips

  # Monitoring
  app_insights_instrumentation_key = module.core.app_insights_instrumentation_key
  app_insights_connection_string   = module.core.app_insights_connection_string

  tags = local.common_tags

  depends_on = [module.core]
}

# ============================================================================
# PAAS MODULE (App Service + Azure SQL)
# Conditional deployment based on var.deploy_paas
# ============================================================================

module "paas" {
  source = "./paas"
  count  = var.deploy_paas ? 1 : 0

  environment      = var.environment
  application_name = var.application_name
  location         = var.location

  # App Service Configuration
  app_service_sku = var.app_service_sku

  # Azure SQL Configuration
  sql_database_edition    = var.sql_database_edition
  sql_service_objective   = var.sql_service_objective
  sql_admin_username      = var.sql_admin_username
  sql_admin_password      = var.sql_admin_password
  sql_aad_admin_object_id = var.sql_aad_admin_object_id
  sql_aad_admin_name      = var.sql_aad_admin_name

  # Network dependencies from core
  pe_subnet_id             = module.core.pe_subnet_id
  container_apps_subnet_id = module.core.container_apps_subnet_id

  # Monitoring
  log_analytics_workspace_id = module.core.log_analytics_workspace_id

  # Core resource group for dependencies
  core_resource_group_name = module.core.resource_group_name

  tags = local.common_tags

  depends_on = [module.core]
}

# ============================================================================
# AGENTS MODULE (VMSS for CI/CD)
# Conditional deployment based on var.deploy_agents
# ============================================================================

module "agents" {
  source = "./agents"
  count  = var.deploy_agents ? 1 : 0

  environment      = var.environment
  application_name = var.application_name
  location         = var.location

  # VMSS Configuration
  admin_username      = var.wfe_admin_username
  admin_password      = var.wfe_admin_password
  agent_vm_size       = var.agent_vm_size
  vmss_instance_count = var.vmss_instance_count

  # Azure DevOps / GitHub Configuration
  azuredevops_org_url    = var.azuredevops_org_url
  azuredevops_pat        = var.azuredevops_pat
  azuredevops_agent_pool = var.azuredevops_agent_pool

  # Network dependencies from core
  github_runners_subnet_id = module.core.github_runners_subnet_id

  # Core resource group for dependencies
  core_resource_group_name = module.core.resource_group_name

  tags = local.common_tags

  depends_on = [module.core]
}

# ============================================================================
# LOCAL VARIABLES
# ============================================================================

locals {
  common_tags = merge(
    var.tags,
    {
      Application = "JobSite"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "jobs_modernization"
    }
  )
}
