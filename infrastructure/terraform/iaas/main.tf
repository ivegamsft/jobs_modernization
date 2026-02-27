# ============================================================================
# IaaS Module - Virtual Machines Infrastructure
# Deploys Windows Server VMs for Web Frontend and SQL Server
# ============================================================================

locals {
  unique_suffix   = substr(md5(azurerm_resource_group.iaas.id), 0, 13)
  resource_prefix = "${var.application_name}-${var.environment}"
}

data "azurerm_client_config" "current" {}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "iaas" {
  name     = "${var.application_name}-iaas-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# LOAD BALANCER
# ============================================================================

resource "azurerm_public_ip" "lb" {
  name                = "${local.resource_prefix}-lb-pip"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.resource_prefix}-lb-${local.unique_suffix}"
  tags                = var.tags
}

resource "azurerm_lb" "main" {
  name                = "${local.resource_prefix}-lb"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "BackendPool"
  loadbalancer_id = azurerm_lb.main.id
}

# ============================================================================
# NETWORK SECURITY GROUPS
# ============================================================================

resource "azurerm_network_security_group" "frontend" {
  name                = "${local.resource_prefix}-nsg-frontend"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "frontend_http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.frontend.name
}

resource "azurerm_network_security_rule" "frontend_https" {
  name                        = "AllowHTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.frontend.name
}

resource "azurerm_network_security_rule" "frontend_rdp" {
  name                        = "AllowRDPFromAllowedIps"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes     = var.allowed_rdp_ips
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.frontend.name
}

resource "azurerm_network_security_group" "data" {
  name                = "${local.resource_prefix}-nsg-data"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "data_sql_frontend" {
  name                        = "AllowSQLFromFrontendSubnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "10.50.0.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.data.name
}

resource "azurerm_network_security_rule" "data_sql_vnet" {
  name                        = "AllowSQLFromVirtualNetwork"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.data.name
}

resource "azurerm_network_security_rule" "data_rdp" {
  name                        = "AllowRDPFromAllowedIps"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes     = var.allowed_rdp_ips
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.iaas.name
  network_security_group_name = azurerm_network_security_group.data.name
}

# ============================================================================
# WEB FRONTEND VM
# ============================================================================

resource "azurerm_network_interface" "wfe" {
  name                = "${local.resource_prefix}-wfe-${local.unique_suffix}-nic"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.frontend_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "wfe" {
  network_interface_id      = azurerm_network_interface.wfe.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_network_interface_backend_address_pool_association" "wfe" {
  network_interface_id    = azurerm_network_interface.wfe.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_windows_virtual_machine" "wfe" {
  name                = "${local.resource_prefix}-wfe-${local.unique_suffix}"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.wfe_admin_password
  computer_name       = "jobsite-wfe"
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.wfe.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "wfe_init" {
  name                       = "enable-rdp-iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.wfe.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -ExecutionPolicy Bypass -Command \"Install-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-45-Features -IncludeManagementTools\""
  })
}

resource "azurerm_virtual_machine_extension" "wfe_aad" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.wfe.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  settings                   = jsonencode({ mdmId = "" })
  depends_on                 = [azurerm_virtual_machine_extension.wfe_init]
}

resource "azurerm_virtual_machine_extension" "wfe_monitor" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.wfe.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.wfe_aad]
}

# ============================================================================
# SQL SERVER VM
# ============================================================================

resource "azurerm_network_interface" "sql" {
  name                = "${local.resource_prefix}-sqlvm-${local.unique_suffix}-nic"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.data_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "sql" {
  network_interface_id      = azurerm_network_interface.sql.id
  network_security_group_id = azurerm_network_security_group.data.id
}

resource "azurerm_network_interface_backend_address_pool_association" "sql" {
  network_interface_id    = azurerm_network_interface.sql.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_managed_disk" "sql_data" {
  name                 = "${local.resource_prefix}-sqlvm-${local.unique_suffix}-data"
  location             = azurerm_resource_group.iaas.location
  resource_group_name  = azurerm_resource_group.iaas.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  tags                 = var.tags
}

resource "azurerm_managed_disk" "sql_log" {
  name                 = "${local.resource_prefix}-sqlvm-${local.unique_suffix}-log"
  location             = azurerm_resource_group.iaas.location
  resource_group_name  = azurerm_resource_group.iaas.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  tags                 = var.tags
}

resource "azurerm_windows_virtual_machine" "sql" {
  name                = "${local.resource_prefix}-sqlvm-${local.unique_suffix}"
  location            = azurerm_resource_group.iaas.location
  resource_group_name = azurerm_resource_group.iaas.name
  size                = var.sql_vm_size
  admin_username      = var.admin_username
  admin_password      = var.sql_admin_password
  computer_name       = "jobsite-sql"
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.sql.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "enterprise-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_data" {
  managed_disk_id    = azurerm_managed_disk.sql_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.sql.id
  lun                = 0
  caching            = "ReadOnly"
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_log" {
  managed_disk_id    = azurerm_managed_disk.sql_log.id
  virtual_machine_id = azurerm_windows_virtual_machine.sql.id
  lun                = 1
  caching            = "None"
}

resource "azurerm_virtual_machine_extension" "sql_aad" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.sql.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  settings                   = jsonencode({ mdmId = "" })
}

resource "azurerm_virtual_machine_extension" "sql_monitor" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.sql.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.sql_aad]
}

resource "azurerm_mssql_virtual_machine" "sql" {
  virtual_machine_id               = azurerm_windows_virtual_machine.sql.id
  sql_license_type                 = "AHUB"
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.sql_admin_password
  sql_connectivity_update_username = var.admin_username
  tags                             = var.tags

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.sql_data,
    azurerm_virtual_machine_data_disk_attachment.sql_log
  ]
}
