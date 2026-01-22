# ============================================================================
# Production Environment Configuration
# ============================================================================

environment      = "prod"
application_name = "jobsite"
location         = "swedencentral"

# Deployment toggles
deploy_iaas   = false
deploy_paas   = true
deploy_agents = true

# Networking
vnet_address_prefix = "10.52.0.0/21"

# Security - Set via environment variables or Azure KeyVault
sql_admin_username = "jobsiteadmin"
wfe_admin_username = "azureadmin"

# RDP Access - Production should use Bastion or VPN
allowed_rdp_ips = []

# PaaS Configuration - Production-grade SKUs
app_service_sku        = "P2v3"
sql_database_edition   = "Premium"
sql_service_objective  = "P2"

# Agents Configuration
agent_vm_size        = "Standard_D4ds_v6"
vmss_instance_count  = 4

# Tags
tags = {
  CostCenter  = "Production"
  Owner       = "DevOps Team"
  Project     = "JobSite"
  Compliance  = "Required"
}
