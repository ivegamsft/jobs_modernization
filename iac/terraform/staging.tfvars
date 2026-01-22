# ============================================================================
# Staging Environment Configuration
# ============================================================================

environment      = "staging"
application_name = "jobsite"
location         = "swedencentral"

# Deployment toggles
deploy_iaas   = false
deploy_paas   = true
deploy_agents = true

# Networking
vnet_address_prefix = "10.51.0.0/21"

# Security - Set via environment variables or Azure KeyVault
sql_admin_username = "jobsiteadmin"
wfe_admin_username = "azureadmin"

# RDP Access
allowed_rdp_ips = []

# PaaS Configuration
app_service_sku       = "P1v3"
sql_database_edition  = "Standard"
sql_service_objective = "S2"

# Agents Configuration
agent_vm_size       = "Standard_D2ds_v6"
vmss_instance_count = 2

# Tags
tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps Team"
  Project    = "JobSite Modernization"
}
