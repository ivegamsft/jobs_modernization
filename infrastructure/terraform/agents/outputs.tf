# ============================================================================
# Agents Module Outputs
# ============================================================================

output "resource_group_name" {
  description = "The name of the Agents resource group"
  value       = azurerm_resource_group.agents.name
}

output "resource_group_id" {
  description = "The ID of the Agents resource group"
  value       = azurerm_resource_group.agents.id
}

output "vmss_name" {
  description = "The name of the VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.agents.name
}

output "vmss_id" {
  description = "The ID of the VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.agents.id
}

output "vmss_principal_id" {
  description = "The principal ID of the VMSS managed identity"
  value       = azurerm_windows_virtual_machine_scale_set.agents.identity[0].principal_id
}
