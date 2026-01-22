# ============================================================================
# Development Environment Configuration
# ============================================================================

environment      = "dev"
application_name = "jobsite"
location         = "swedencentral"
subscription_id  = "844eabcc-dc96-453b-8d45-bef3d566f3f8"

# Deployment toggles
deploy_iaas   = true
deploy_paas   = false
deploy_agents = false

# Networking
vnet_address_prefix = "10.50.0.0/21"

# Security - Set via environment variables or Azure KeyVault
# export TF_VAR_sql_admin_password="<password>"
# export TF_VAR_wfe_admin_password="<password>"
sql_admin_username = "jobsiteadmin"
wfe_admin_username = "azureadmin"

# RDP Access - Add your IP address
allowed_rdp_ips = [
  # "YOUR.PUBLIC.IP.ADDRESS/32"
]

# IaaS Configuration
vm_size     = "Standard_D2ds_v6"
sql_vm_size = "Standard_D4ds_v6"

# PaaS Configuration (when enabled)
app_service_sku  = "S1"
sql_database_sku = "S1"

# Agents Configuration (when enabled)
agent_vm_size       = "Standard_D2ds_v6"
vmss_instance_count = 2

# Tags
tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps Team"
  Project    = "JobSite Modernization"
}
