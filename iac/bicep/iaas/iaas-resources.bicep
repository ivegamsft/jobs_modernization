targetScope = 'resourceGroup'

// ============================================================================
// IAAS Resources Module (deployed within resource group)
// ============================================================================

param environment string
param applicationName string
param location string
param frontendSubnetId string
param dataSubnetId string
param gatewaySubnetId string = ''
param adminUsername string
param vmSize string
param sqlVmSize string
param allowedRdpIps array = []
@secure()
param adminPassword string
@secure()
param appGatewayCertData string = ''
@secure()
param appGatewayCertPassword string = ''
param tags object

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'

var wfeVmName = '${resourcePrefix}-wfe-${uniqueSuffix}'
var sqlVmName = '${resourcePrefix}-sqlvm-${uniqueSuffix}'
var appGatewayName = '${resourcePrefix}-appgw-${uniqueSuffix}'
var publicIpAppGwName = '${resourcePrefix}-pip-appgw-${uniqueSuffix}'
var nsgFrontendName = '${resourcePrefix}-nsg-frontend'
var nsgDataName = '${resourcePrefix}-nsg-data'

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
      // Allow RDP for admin access (from allowed IPs)
      {
        name: 'AllowRDPFromAllowedIps'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: allowedRdpIps[0]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      // Allow WinRM (PowerShell automation) for .NET tools
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
      // Allow RDP for admin access (from allowed IPs)
      {
        name: 'AllowRDPFromAllowedIps'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: allowedRdpIps[0]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      // Allow WinRM (PowerShell automation) for .NET tools
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

// Public IP for Application Gateway
resource publicIpAppGw 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpAppGwName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// WFE VM (Web Front End - talks to SQL)
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
  dependsOn: [
    appGateway
  ]
}

resource wfeVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: wfeVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: take('${resourcePrefix}-wfe', 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
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
  dependsOn: [
    appGateway
  ]
}

// SQL VM (Data Tier)
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

resource sqlVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: sqlVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize
    }
    osProfile: {
      computerName: take('${resourcePrefix}-sql', 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'sql2022-ws2022'
        sku: 'standard-gen2'
        version: 'latest'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 128
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        {
          createOption: 'Empty'
          lun: 1
          diskSizeGB: 128
          caching: 'None'
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

// SQL VM Extension
resource sqlVmExtension 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01' = {
  name: sqlVmName
  location: location
  tags: tags
  properties: {
    virtualMachineResourceId: sqlVm.id
    sqlManagement: 'Full'
    sqlServerLicenseType: 'PAYG'
    storageConfigurationSettings: {
      diskConfigurationType: 'NEW'
      storageWorkloadType: 'GENERAL'
      sqlDataSettings: {
        luns: [0]
        defaultFilePath: 'F:\\Data'
      }
      sqlLogSettings: {
        luns: [1]
        defaultFilePath: 'G:\\Log'
      }
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: 'PRIVATE'
        port: 1433
      }
    }
  }
}

// Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: gatewaySubnetId != '' ? gatewaySubnetId : dataSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIpAppGw.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    sslCertificates: appGatewayCertData != ''
      ? [
          {
            name: 'appGatewaySslCert'
            properties: {
              data: appGatewayCertData
              password: appGatewayCertPassword
            }
          }
        ]
      : []
    backendAddressPools: [
      {
        name: 'wfe-backend-pool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'health-probe')
          }
        }
      }
    ]
    httpListeners: concat(
      appGatewayCertData != ''
        ? [
            {
              name: 'appGatewayHttpsListener'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    appGatewayName,
                    'appGatewayFrontendIP'
                  )
                }
                frontendPort: {
                  id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
                }
                protocol: 'Https'
                sslCertificate: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/sslCertificates',
                    appGatewayName,
                    'appGatewaySslCert'
                  )
                }
              }
            }
          ]
        : [],
      [
        {
          name: 'appGatewayHttpListener'
          properties: {
            frontendIPConfiguration: {
              id: resourceId(
                'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                appGatewayName,
                'appGatewayFrontendIP'
              )
            }
            frontendPort: {
              id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
            }
            protocol: 'Http'
          }
        }
      ]
    )
    requestRoutingRules: concat(
      appGatewayCertData != ''
        ? [
            {
              name: 'httpsRoutingRule'
              properties: {
                ruleType: 'Basic'
                priority: 100
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    appGatewayName,
                    'appGatewayHttpsListener'
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'wfe-backend-pool'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'appGatewayBackendHttpSettings'
                  )
                }
              }
            }
          ]
        : [],
      [
        {
          name: appGatewayCertData != '' ? 'httpToHttpsRedirect' : 'httpRoutingRule'
          properties: {
            ruleType: 'Basic'
            priority: 200
            httpListener: {
              id: resourceId(
                'Microsoft.Network/applicationGateways/httpListeners',
                appGatewayName,
                'appGatewayHttpListener'
              )
            }
            redirectConfiguration: appGatewayCertData != ''
              ? {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/redirectConfigurations',
                    appGatewayName,
                    'httpToHttpsRedirect'
                  )
                }
              : null
            backendAddressPool: appGatewayCertData == ''
              ? {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'wfe-backend-pool'
                  )
                }
              : null
            backendHttpSettings: appGatewayCertData == ''
              ? {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'appGatewayBackendHttpSettings'
                  )
                }
              : null
          }
        }
      ]
    )
    redirectConfigurations: appGatewayCertData != ''
      ? [
          {
            name: 'httpToHttpsRedirect'
            properties: {
              redirectType: 'Permanent'
              targetListener: {
                id: resourceId(
                  'Microsoft.Network/applicationGateways/httpListeners',
                  appGatewayName,
                  'appGatewayHttpsListener'
                )
              }
              includePath: true
              includeQueryString: true
            }
          }
        ]
      : []
    probes: [
      {
        name: 'health-probe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
  }
}

// Outputs
output wfeVmId string = wfeVm.id
output wfeVmName string = wfeVm.name
output wfeVmPrivateIp string = wfeNic.properties.ipConfigurations[0].properties.privateIPAddress
output sqlVmId string = sqlVm.id
output sqlVmName string = sqlVm.name
output sqlVmPrivateIp string = sqlVmNic.properties.ipConfigurations[0].properties.privateIPAddress
output appGatewayId string = appGateway.id
output appGatewayName string = appGateway.name
output appGatewayPublicIp string = publicIpAppGw.properties.ipAddress
