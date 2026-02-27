targetScope = 'resourceGroup'

// ============================================================================
// IAAS Resources Module (deployed within resource group)
// ============================================================================

param environment string
param applicationName string
param location string
param frontendSubnetId string
param dataSubnetId string
param adminUsername string
param vmSize string
param sqlVmSize string
param allowedRdpIps array = []
@secure()
param adminPassword string
param tags object
param keyVaultCertificateUrls array = []
param appInsightsInstrumentationKey string = ''
param appInsightsConnectionString string = ''

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'
var wfeVmName = '${resourcePrefix}-wfe-${uniqueSuffix}'
var sqlVmName = '${resourcePrefix}-sqlvm-${uniqueSuffix}'
var nsgFrontendName = '${resourcePrefix}-nsg-frontend'
var nsgDataName = '${resourcePrefix}-nsg-data'
var loadBalancerName = '${resourcePrefix}-lb'
var loadBalancerPublicIpName = '${resourcePrefix}-lb-pip'
var backendPoolName = 'BackendPool'
var frontendIpConfigName = 'LoadBalancerFrontEnd'

// ============================================================================
// LOAD BALANCER FOR INBOUND NAT RULES
// ============================================================================

// Public IP for Load Balancer
resource loadBalancerPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: loadBalancerPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${resourcePrefix}-lb-${uniqueSuffix}'
    }
  }
}

// Standard Load Balancer
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: loadBalancerName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          publicIPAddress: {
            id: loadBalancerPublicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    inboundNatRules: [
      {
        name: 'rdp-nat-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/loadBalancers/frontendIPConfigurations',
              loadBalancerName,
              frontendIpConfigName
            )
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50001
          frontendPortRangeEnd: 50100
          backendPort: 3389
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendPoolName)
          }
        }
      }
    ]
  }
}

// ============================================================================
// NETWORK SECURITY GROUPS
// ============================================================================

// NSG for Frontend Subnet (Web VM)
resource nsgFrontend 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgFrontendName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Allow HTTP from internet
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      // Allow HTTPS from internet
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      // Allow RDP from allowed IPs
      {
        name: 'AllowRDPFromAllowedIps'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefixes: allowedRdpIps
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      // Allow SQL communication to Data subnet (SQL VM)
      {
        name: 'AllowSQLToDataSubnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.50.1.0/26'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 125
          direction: 'Outbound'
        }
      }
      // Allow WinRM HTTP (5985) from VirtualNetwork
      {
        name: 'AllowWinRMHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5985'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      // Allow WinRM HTTPS (5986) from VirtualNetwork
      {
        name: 'AllowWinRMHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5986'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
    ]
  }
}

// NSG for Data Subnet (SQL VM)
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgDataName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Allow SQL (1433) from Frontend subnet (Web VM)
      {
        name: 'AllowSQLFromFrontendSubnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.50.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      // Allow SQL (1433) from VirtualNetwork for SSMS and .NET automation tools
      {
        name: 'AllowSQLFromVirtualNetwork'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Inbound'
        }
      }
      // Allow RDP from allowed IPs for remote management
      {
        name: 'AllowRDPFromAllowedIps'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefixes: allowedRdpIps
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      // Allow WinRM HTTP (5985) from VirtualNetwork
      {
        name: 'AllowWinRMHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5985'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      // Allow WinRM HTTPS (5986) from VirtualNetwork
      {
        name: 'AllowWinRMHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5986'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

// ============================================================================
// NAT GATEWAY INBOUND RULES (For RDP Access)
// ============================================================================
// Note: Inbound NAT rules must be created in the core resource group where 
// the NAT Gateway exists. These will be deployed separately via main.bicep

// ============================================================================
// WEB FRONTEND VM (WFE)
// ============================================================================

resource wfeNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${wfeVmName}-nic'
  location: location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsgFrontend.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: frontendSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendPoolName)
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    loadBalancer
  ]
}

resource wfeVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: wfeVmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'jobsite-wfe'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wfeNic.id
        }
      ]
    }
  }
}

// ============================================================================
// WFE VM EXTENSIONS
// ============================================================================

// 1. Base init (RDP enable + IIS install)
resource wfeVmInitCommand 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  parent: wfeVm
  name: 'enable-rdp-iis'
  location: location
  properties: {
    source: {
      script: '''
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService
Install-WindowsFeature Web-Server -IncludeManagementTools
Install-WindowsFeature Web-Asp-Net45
Install-WindowsFeature NET-Framework-45-Features
'''
    }
  }
}

// 2. Azure AD (Entra) Authentication
resource wfeVmAadExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: wfeVm
  name: 'AADLoginForWindows'
  location: location
  tags: tags
  dependsOn: [
    wfeVmInitCommand
  ]
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

// 3. Anti-malware
resource wfeVmAntimalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: wfeVm
  name: 'IaaSAntimalware'
  location: location
  tags: tags
  dependsOn: [
    wfeVmAadExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        day: 7
        time: 120
        scanType: 'Quick'
      }
      Exclusions: {
        Extensions: '.log;.ldf'
        Paths: 'C:\\Windows\\Temp'
      }
    }
  }
}

// 4. Guest Configuration (Machine Config)
resource wfeVmGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: wfeVm
  name: 'AzurePolicyforWindows'
  location: location
  tags: tags
  dependsOn: [
    wfeVmAntimalwareExtension
  ]
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}

// 5. Azure Monitor Agent
resource wfeVmMonitoringExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: wfeVm
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: tags
  dependsOn: [
    wfeVmGuestConfigExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}

// 6. Dependency Agent (for VM Insights)
resource wfeVmDependencyExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: wfeVm
  name: 'DependencyAgentWindows'
  location: location
  tags: tags
  dependsOn: [
    wfeVmMonitoringExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

// 7. Key Vault Extension (conditional, requires certificate URLs)
resource wfeVmKeyVaultExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(keyVaultCertificateUrls)) {
  parent: wfeVm
  name: 'KeyVaultForWindows'
  location: location
  tags: tags
  dependsOn: [
    wfeVmDependencyExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForWindows'
    typeHandlerVersion: '3.0'
    autoUpgradeMinorVersion: true
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        linkOnRenewal: false
        observedCertificates: keyVaultCertificateUrls
        requireInitialSync: false
      }
      authenticationSettings: {
        msiEndpoint: 'http://169.254.169.254/metadata/identity/oauth2/token'
        msiClientId: ''
      }
    }
  }
}

// 8. Application Insights Extension
resource wfeVmAppInsightsExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(appInsightsConnectionString)) {
  parent: wfeVm
  name: 'ApplicationMonitoringWindows'
  location: location
  tags: tags
  dependsOn: [
    wfeVmInitCommand
  ]
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'ApplicationInsightsMonitoringWindows'
    typeHandlerVersion: '2.8'
    autoUpgradeMinorVersion: true
    settings: {
      instrumentationKey: appInsightsInstrumentationKey
      connectionString: appInsightsConnectionString
    }
  }
}

// ============================================================================
// SQL SERVER VM
// ============================================================================

resource sqlVmNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${sqlVmName}-nic'
  location: location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsgData.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: dataSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendPoolName)
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    loadBalancer
  ]
}

resource sqlVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: sqlVmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize
    }
    osProfile: {
      computerName: 'jobsite-sql'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'sql2022-ws2022'
        sku: 'enterprise-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        {
          lun: 1
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sqlVmNic.id
        }
      ]
    }
  }
}

// ============================================================================
// SQL VM EXTENSIONS
// ============================================================================

// 1. Enable RDP
resource sqlVmRdpExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'EnableRDP'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -Command "Set-ItemProperty -Path HKLM:\\System\\CurrentControlSet\\Control\\Terminal` Server -Name fDenyTSConnections -Value 0; Enable-NetFirewallRule -DisplayGroup Remote` Desktop; Set-Service -Name TermService -StartupType Automatic; Start-Service -Name TermService"'
    }
  }
}

// 2. Azure AD (Entra) Authentication
resource sqlVmAadExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'AADLoginForWindows'
  location: location
  tags: tags
  dependsOn: [
    sqlVmRdpExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

// 3. Anti-malware
resource sqlVmAntimalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'IaaSAntimalware'
  location: location
  tags: tags
  dependsOn: [
    sqlVmAadExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        day: 7
        time: 120
        scanType: 'Quick'
      }
      Exclusions: {
        Extensions: '.log;.ldf;.mdf;.ndf'
        Paths: 'C:\\Program Files\\Microsoft SQL Server'
      }
    }
  }
}

// 4. Guest Configuration (Machine Config)
resource sqlVmGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'AzurePolicyforWindows'
  location: location
  tags: tags
  dependsOn: [
    sqlVmAntimalwareExtension
  ]
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}

// 5. Azure Monitor Agent
resource sqlVmMonitoringExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: tags
  dependsOn: [
    sqlVmGuestConfigExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}

// 6. Dependency Agent (for VM Insights)
resource sqlVmDependencyExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: sqlVm
  name: 'DependencyAgentWindows'
  location: location
  tags: tags
  dependsOn: [
    sqlVmMonitoringExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

// 7. Key Vault Extension (conditional, requires certificate URLs)
resource sqlVmKeyVaultExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(keyVaultCertificateUrls)) {
  parent: sqlVm
  name: 'KeyVaultForWindows'
  location: location
  tags: tags
  dependsOn: [
    sqlVmDependencyExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForWindows'
    typeHandlerVersion: '3.0'
    autoUpgradeMinorVersion: true
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        linkOnRenewal: false
        observedCertificates: keyVaultCertificateUrls
        requireInitialSync: false
      }
      authenticationSettings: {
        msiEndpoint: 'http://169.254.169.254/metadata/identity/oauth2/token'
        msiClientId: ''
      }
    }
  }
}

// 8. SQL VM Extension for SQL Server management
resource sqlVmExtension 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01' = {
  name: sqlVmName
  location: location
  tags: tags
  dependsOn: [
    sqlVmDependencyExtension
  ]
  properties: {
    virtualMachineResourceId: sqlVm.id
    sqlManagement: 'Full'
    sqlServerLicenseType: 'AHUB'
    wsfcStaticIp: ''
    autoBackupSettings: {
      enable: false
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: 'Private'
        port: 1433
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output loadBalancerPublicIp string = loadBalancerPublicIp.properties.ipAddress
output loadBalancerFqdn string = loadBalancerPublicIp.properties.dnsSettings.fqdn
output loadBalancerId string = loadBalancer.id
output loadBalancerName string = loadBalancer.name

output wfeVmId string = wfeVm.id
output wfeVmName string = wfeVm.name
output wfeVmPrivateIp string = wfeNic.properties.ipConfigurations[0].properties.privateIPAddress

output sqlVmId string = sqlVm.id
output sqlVmName string = sqlVm.name
output sqlVmPrivateIp string = sqlVmNic.properties.ipConfigurations[0].properties.privateIPAddress
