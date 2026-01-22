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

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'
var wfeVmName = '${resourcePrefix}-wfe-${uniqueSuffix}'
var sqlVmName = '${resourcePrefix}-sqlvm-${uniqueSuffix}'
var nsgFrontendName = '${resourcePrefix}-nsg-frontend'
var nsgDataName = '${resourcePrefix}-nsg-data'

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
      // Allow SQL (1433) from Web VM subnet (10.50.0.0/24)
      {
        name: 'AllowSQLFromWebVM'
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
      // Allow SQL (1433) from VirtualNetwork for SSMS and .NET tools
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
        }
      }
    ]
  }
}

resource wfeVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: wfeVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: wfeVmName
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
        }
      }
    ]
  }
}

resource sqlVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: sqlVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize
    }
    osProfile: {
      computerName: sqlVmName
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
        sku: 'standard'
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

// SQL VM Extension for SQL Server management
resource sqlVmExtension 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01-preview' = {
  name: '${sqlVmName}-sqlvm-config'
  location: location
  tags: tags
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

output wfeVmId string = wfeVm.id
output wfeVmName string = wfeVm.name
output wfeVmPrivateIp string = wfeNic.properties.ipConfigurations[0].properties.privateIPAddress

output sqlVmId string = sqlVm.id
output sqlVmName string = sqlVm.name
output sqlVmPrivateIp string = sqlVmNic.properties.ipConfigurations[0].properties.privateIPAddress
