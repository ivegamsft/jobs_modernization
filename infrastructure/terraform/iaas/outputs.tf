# ============================================================================
# IaaS Module Outputs
# ============================================================================

output "resource_group_name" {
  description = "The name of the IaaS resource group"
  value       = azurerm_resource_group.iaas.name
}

output "resource_group_id" {
  description = "The ID of the IaaS resource group"
  value       = azurerm_resource_group.iaas.id
}

output "load_balancer_public_ip" {
  description = "The public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "load_balancer_fqdn" {
  description = "The FQDN of the load balancer"
  value       = azurerm_public_ip.lb.fqdn
}

output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = azurerm_lb.main.id
}

output "wfe_vm_name" {
  description = "The name of the web frontend VM"
  value       = azurerm_windows_virtual_machine.wfe.name
}

output "wfe_vm_id" {
  description = "The ID of the web frontend VM"
  value       = azurerm_windows_virtual_machine.wfe.id
}

output "wfe_private_ip" {
  description = "The private IP address of the web frontend VM"
  value       = azurerm_network_interface.wfe.private_ip_address
}

output "sql_vm_name" {
  description = "The name of the SQL Server VM"
  value       = azurerm_windows_virtual_machine.sql.name
}

output "sql_vm_id" {
  description = "The ID of the SQL Server VM"
  value       = azurerm_windows_virtual_machine.sql.id
}

output "sql_private_ip" {
  description = "The private IP address of the SQL Server VM"
  value       = azurerm_network_interface.sql.private_ip_address
}
