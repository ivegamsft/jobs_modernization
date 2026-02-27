# ============================================================================
# Agents Module - CI/CD Infrastructure
# Deploys VMSS for GitHub Runners and Azure DevOps Agents
# ============================================================================

locals {
  unique_suffix   = substr(md5(azurerm_resource_group.agents.id), 0, 13)
  resource_prefix = "${var.application_name}-${var.environment}"
}

data "azurerm_client_config" "current" {}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "agents" {
  name     = "${var.application_name}-agents-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# VMSS FOR GITHUB RUNNERS / AZURE DEVOPS AGENTS
# ============================================================================

resource "azurerm_windows_virtual_machine_scale_set" "agents" {
  name                 = "${local.resource_prefix}-gh-runners-${local.unique_suffix}"
  location             = azurerm_resource_group.agents.location
  resource_group_name  = azurerm_resource_group.agents.name
  sku                  = var.agent_vm_size
  instances            = var.vmss_instance_count
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  computer_name_prefix = "gh-agent"
  upgrade_mode         = "Manual"
  tags                 = var.tags

  # Use Flexible orchestration for better control
  platform_fault_domain_count = 1
  single_placement_group      = false
  overprovision               = false

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = var.github_runners_subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Install Azure DevOps Agent if org URL and PAT provided
  extension {
    name                       = "AzureDevOpsAgent"
    publisher                  = "Microsoft.Compute"
    type                       = "CustomScriptExtension"
    type_handler_version       = "1.10"
    auto_upgrade_minor_version = true

    protected_settings = jsonencode({
      commandToExecute = var.azure_devops_org_url != "" && var.azure_devops_pat != "" ? "powershell.exe -ExecutionPolicy Bypass -Command \"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-win-x64-3.236.1.zip -OutFile C:\\agent.zip; Expand-Archive -Path C:\\agent.zip -DestinationPath C:\\agent -Force; cd C:\\agent; .\\config.cmd --unattended --url '${var.azure_devops_org_url}' --auth pat --token '${var.azure_devops_pat}' --pool '${var.azure_devops_agent_pool}' --agent $env:COMPUTERNAME --runAsService --windowsLogonAccount 'NT AUTHORITY\\SYSTEM'; .\\run.cmd --once\"" : "powershell.exe -Command \"Write-Host 'Azure DevOps configuration skipped - no org URL/PAT provided'\""
    })
  }

  # Azure AD (Entra) Authentication
  extension {
    name                       = "AADLoginForWindows"
    publisher                  = "Microsoft.Azure.ActiveDirectory"
    type                       = "AADLoginForWindows"
    type_handler_version       = "2.0"
    auto_upgrade_minor_version = true
    settings                   = jsonencode({ mdmId = "" })
  }

  # Anti-malware
  extension {
    name                       = "IaaSAntimalware"
    publisher                  = "Microsoft.Azure.Security"
    type                       = "IaaSAntimalware"
    type_handler_version       = "1.3"
    auto_upgrade_minor_version = true

    settings = jsonencode({
      AntimalwareEnabled        = true
      RealtimeProtectionEnabled = true
      ScheduledScanSettings = {
        isEnabled = true
        day       = 7
        time      = 120
        scanType  = "Quick"
      }
      Exclusions = {
        Extensions = ".log"
        Paths      = "C:\\Windows\\Temp;C:\\agent"
      }
    })
  }

  # Azure Monitor Agent
  extension {
    name                       = "AzureMonitorWindowsAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type                       = "AzureMonitorWindowsAgent"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true
  }

  # Dependency Agent for VM Insights
  extension {
    name                       = "DependencyAgentWindows"
    publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
    type                       = "DependencyAgentWindows"
    type_handler_version       = "9.10"
    auto_upgrade_minor_version = true
  }
}
