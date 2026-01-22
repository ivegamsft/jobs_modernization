# ============================================================================
# Terraform Outputs
# Export key infrastructure details
# ============================================================================

# ============================================================================
# CORE OUTPUTS
# ============================================================================

output "core_resource_group_name" {
  description = "Core resource group name"
  value       = module.core.resource_group_name
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.core.vnet_id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.core.vnet_name
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = module.core.key_vault_id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.core.key_vault_name
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.core.log_analytics_workspace_id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP address"
  value       = module.core.nat_gateway_public_ip
}

# ============================================================================
# IAAS OUTPUTS
# ============================================================================

output "iaas_load_balancer_public_ip" {
  description = "Load Balancer public IP for IaaS VMs"
  value       = var.deploy_iaas ? module.iaas[0].load_balancer_public_ip : null
}

output "iaas_wfe_vm_name" {
  description = "Web frontend VM name"
  value       = var.deploy_iaas ? module.iaas[0].wfe_vm_name : null
}

output "iaas_sql_vm_name" {
  description = "SQL Server VM name"
  value       = var.deploy_iaas ? module.iaas[0].sql_vm_name : null
}

output "iaas_resource_group_name" {
  description = "IaaS resource group name"
  value       = var.deploy_iaas ? module.iaas[0].resource_group_name : null
}

# ============================================================================
# PAAS OUTPUTS
# ============================================================================

output "paas_app_service_url" {
  description = "App Service default hostname"
  value       = var.deploy_paas ? module.paas[0].app_service_default_hostname : null
}

output "paas_app_service_name" {
  description = "App Service name"
  value       = var.deploy_paas ? module.paas[0].app_service_name : null
}

output "paas_sql_server_fqdn" {
  description = "Azure SQL Server FQDN"
  value       = var.deploy_paas ? module.paas[0].sql_server_fqdn : null
}

output "paas_sql_database_name" {
  description = "Azure SQL Database name"
  value       = var.deploy_paas ? module.paas[0].sql_database_name : null
}

output "paas_resource_group_name" {
  description = "PaaS resource group name"
  value       = var.deploy_paas ? module.paas[0].resource_group_name : null
}

# ============================================================================
# AGENTS OUTPUTS
# ============================================================================

output "agents_vmss_name" {
  description = "VMSS name for CI/CD agents"
  value       = var.deploy_agents ? module.agents[0].vmss_name : null
}

output "agents_vmss_id" {
  description = "VMSS ID for CI/CD agents"
  value       = var.deploy_agents ? module.agents[0].vmss_id : null
}

output "agents_resource_group_name" {
  description = "Agents resource group name"
  value       = var.deploy_agents ? module.agents[0].resource_group_name : null
}

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed components"
  value = {
    environment      = var.environment
    location         = var.location
    core_deployed    = true
    iaas_deployed    = var.deploy_iaas
    paas_deployed    = var.deploy_paas
    agents_deployed  = var.deploy_agents
  }
}
