targetScope = 'resourceGroup'

// ============================================================================
// VM Infrastructure for Job Site Application
// ============================================================================
// Deploys: VMSS for Web Frontend, SQL Server VM, and Application Gateway

@description('Environment name (dev, staging, prod)')
param environment string

@description('Application name (no spaces)')
param applicationName string = 'jobsite'

@description('Azure location for resources')
param location string = resourceGroup().location

@description('Virtual Network ID (from core deployment)')
param vnetId string

@description('Frontend Subnet ID (from core deployment)')
param frontendSubnetId string

@description('Data Subnet ID (from core deployment)')
param dataSubnetId string

@description('Log Analytics Workspace ID (from core deployment)')
param logAnalyticsWorkspaceId string

@description('Key Vault resource ID containing App Gateway certificate secrets')
param keyVaultId string

@description('Key Vault secret name for the App Gateway PFX (base64)')
param appGatewayCertSecretName string = 'appgw-pfx-base64'

@description('Key Vault secret name for the App Gateway PFX password')
param appGatewayCertPasswordSecretName string = 'appgw-pfx-password'

@description('VMSS instance count')
param vmssInstanceCount int = 1

@description('SQL Server VM size')
param sqlVmSize string = 'Standard_D2s_v5'

@description('VMSS VM size')
param vmssVmSize string = 'Standard_D2s_v5'

@description('SQL Server Admin Username')
param sqlAdminUsername string

@secure()
@description('SQL Server Admin Password')
param sqlAdminPassword string

@description('Administrator username for VMs')
param vmAdminUsername string = 'azureuser'

@secure()
@description('Administrator password for VMs')
param vmAdminPassword string

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  application: applicationName
  deployedDate: utcNow('u')
  deployedBy: 'Bicep'
  component: 'vm'
}

// ============================================================================
// Variables
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'

// Windows Server 2019 image details
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2019-Datacenter'
var imageVersion = 'latest'

// SQL Server 2019 Standard image
var sqlImagePublisher = 'MicrosoftSQLServer'
var sqlImageOffer = 'SQL2019-WS2019'
var sqlImageSku = 'Standard'

// Resource names
var vmssName = '${resourcePrefix}-vmss-${uniqueSuffix}'
var sqlVmName = '${resourcePrefix}-sql-${uniqueSuffix}'
var sqlVmNicName = '${sqlVmName}-nic'
var sqlVmOsDiskName = '${sqlVmName}-osdisk'
var sqlVmDataDiskName = '${sqlVmName}-datadisk'
var appGatewayName = '${resourcePrefix}-appgw-${uniqueSuffix}'
var appGatewayPublicIpName = '${resourcePrefix}-appgw-pip-${uniqueSuffix}'
var appGatewaySubnetName = 'snet-appgw'
var appGatewaySubnetPrefix = '10.50.224.0/27'

// Key Vault reference (for App Gateway cert)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  id: keyVaultId
}

// ============================================================================
// App Gateway Subnet (needs to be created separately from core)
// ============================================================================

resource vnetRef 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(vnetId, '/')[8]
}

resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnetRef
  name: appGatewaySubnetName
  properties: {
    addressPrefix: appGatewaySubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// ============================================================================
// VMSS for Web Frontend
// ============================================================================

resource vmssIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${vmssName}-identity'
  location: location
  tags: tags
}

resource vmssNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmssName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: frontendSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          primary: true
        }
      }
    ]
    networkSecurityGroup: null
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  tags: tags
  sku: {
    name: vmssVmSize
    capacity: vmssInstanceCount
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vmssIdentity.id}': {}
    }
  }
  properties: {
    orchestrationMode: 'Uniform'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: imagePublisher
          offer: imageOffer
          sku: imageSku
          version: imageVersion
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      }
      osProfile: {
        computerNamePrefix: '${resourcePrefix}-vm'
        adminUsername: vmAdminUsername
        adminPassword: vmAdminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          provisionVMAgent: true
          timeZone: 'UTC'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-config-1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: frontendSubnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'IISInstall'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File c:\\iis-install.ps1'
                fileUris: [
                  // Reference to storage account with script - implement separately
                  'https://raw.githubusercontent.com/your-repo/scripts/iis-install.ps1'
                ]
              }
            }
          }
          {
            name: 'AzureMonitorAgent'
            properties: {
              publisher: 'Microsoft.Azure.Monitor'
              type: 'AzureMonitorWindowsAgent'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              settings: {
                authentication: {
                  managedIdentity: {
                    'client-id': vmssIdentity.properties.clientId
                  }
                }
              }
            }
          }
        ]
      }
    }
  }
}

// ============================================================================
// SQL Server VM
// ============================================================================

resource sqlVmIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${sqlVmName}-identity'
  location: location
  tags: tags
}

resource sqlVmNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: sqlVmNicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: dataSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          primary: true
        }
      }
    ]
    enableAcceleratedNetworking: false
  }
}

resource sqlVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: sqlVmName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sqlVmIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize
    }
    storageProfile: {
      imageReference: {
        publisher: sqlImagePublisher
        offer: sqlImageOffer
        sku: sqlImageSku
        version: 'latest'
      }
      osDisk: {
        name: sqlVmOsDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          name: sqlVmDataDiskName
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: sqlVmName
      adminUsername: sqlAdminUsername
      adminPassword: sqlAdminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: 'UTC'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sqlVmNic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

// ============================================================================
// SQL VM Extension for Auto Patching
// ============================================================================

resource sqlVmExtension 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2022-02-01' = {
  name: sqlVmName
  location: location
  tags: tags
  properties: {
    virtualMachineResourceId: sqlVm.id
    sqlServerLicenseType: 'PAYG'
    sqlManagement: 'Full'
    sqlImageSku: 'Standard'
    autoPatchingSettings: {
      enable: true
      dayOfWeek: 'Sunday'
      maintenanceWindowStartingHour: 2
      maintenanceWindowDuration: 4
    }
    autoBackupSettings: {
      enable: false
    }
    keyVaultCredentialSettings: {
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
// Application Gateway
// ============================================================================

resource appGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: appGatewayPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
      {
        name: 'appGatewayFrontendPortHttp'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            // VMSS instances will be added via scale set configuration
          ]
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
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'appGatewayHealthProbe')
          }
        }
      }
    ]
    httpListeners: [
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
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              appGatewayName,
              'appGatewayFrontendPortHttp'
            )
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
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
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              appGatewayName,
              'appGatewayFrontendPort'
            )
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, 'appGatewaySslCert')
          }
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              'appGatewayHttpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              'appGatewayBackendPool'
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
      {
        name: 'rule2'
        properties: {
          ruleType: 'Basic'
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
              'appGatewayBackendPool'
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
    probes: [
      {
        name: 'appGatewayHealthProbe'
        properties: {
          protocol: 'Http'
          host: 'localhost'
          path: '/'
          interval: 30
          timeout: 10
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    sslCertificates: [
      {
        name: 'appGatewaySslCert'
        properties: {
          data: keyVault.getSecret(appGatewayCertSecretName).value
          password: keyVault.getSecret(appGatewayCertPasswordSecretName).value
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      requestBodyCheck: true
      maxRequestBodySize: 128
      fileUploadLimitInMb: 100
    }
  }
}

// ============================================================================
// Scale Set Autoscale Settings (currently manual, can be automated)
// ============================================================================

resource vmssAutoscale 'Microsoft.Insights/autoscaleSettings@2021-05-01-preview' = {
  name: '${vmssName}-autoscale'
  location: location
  tags: tags
  properties: {
    enabled: false // Set to true and configure rules to enable autoscaling
    targetResourceUri: vmss.id
    profiles: [
      {
        name: 'Manual Scale'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: []
      }
    ]
  }
}

// ============================================================================
// Diagnostic Settings
// ============================================================================

resource vmssMonitoring 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vmss
  name: 'send-to-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource appGatewayMonitoring 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appGateway
  name: 'send-to-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('VMSS ID')
output vmssId string = vmss.id

@description('VMSS Name')
output vmssName string = vmss.name

@description('SQL VM ID')
output sqlVmId string = sqlVm.id

@description('SQL VM Name')
output sqlVmName string = sqlVm.name

@description('SQL VM Private IP')
output sqlVmPrivateIp string = sqlVmNic.properties.ipConfigurations[0].properties.privateIPAddress

@description('Application Gateway ID')
output appGatewayId string = appGateway.id

@description('Application Gateway Name')
output appGatewayName string = appGateway.name

@description('Application Gateway Public IP')
output appGatewayPublicIp string = appGatewayPublicIp.properties.ipAddress
