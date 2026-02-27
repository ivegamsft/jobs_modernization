targetScope = 'resourceGroup'

// ============================================================================
// AGENTS Resources Module (deployed within resource group)
// GitHub Runners VMSS for CI/CD infrastructure
// ============================================================================

param environment string
param applicationName string
param location string
param githubRunnersSubnetId string
param adminUsername string
param agentVmSize string
param vmssInstanceCount int
@secure()
param adminPassword string
param tags object
param keyVaultCertificateUrls array = []
param azureDevOpsOrgUrl string = ''
param azureDevOpsPat string = ''
param azureDevOpsAgentPool string = 'Default'

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${applicationName}-${environment}'
var vmssName = '${resourcePrefix}-gh-runners-${uniqueSuffix}'

// Network Interface for VMSS
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
            id: githubRunnersSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// GitHub Runners VMSS
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: agentVmSize
    tier: 'Standard'
    capacity: vmssInstanceCount
  }
  properties: {
    orchestrationMode: 'Flexible'
    platformFaultDomainCount: 1
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'gh-agent'
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
        networkApiVersion: '2023-05-01'
        networkInterfaceConfigurations: [
          {
            name: 'vmss-nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: githubRunnersSubnetId
                    }
                    privateIPAddressVersion: 'IPv4'
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          // 1. Azure AD (Entra) Authentication
          {
            name: 'AADLoginForWindows'
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
          // 2. Anti-malware
          {
            name: 'IaaSAntimalware'
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
                  Extensions: '.log'
                  Paths: 'C:\\Windows\\Temp'
                }
              }
            }
          }
          // 3. Guest Configuration
          {
            name: 'AzurePolicyforWindows'
            properties: {
              publisher: 'Microsoft.GuestConfiguration'
              type: 'ConfigurationforWindows'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
              settings: {}
            }
          }
          // 4. Azure Monitor Agent
          {
            name: 'AzureMonitorWindowsAgent'
            properties: {
              publisher: 'Microsoft.Azure.Monitor'
              type: 'AzureMonitorWindowsAgent'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
              settings: {}
            }
          }
          // 5. Dependency Agent
          {
            name: 'DependencyAgentWindows'
            properties: {
              publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
              type: 'DependencyAgentWindows'
              typeHandlerVersion: '9.10'
              autoUpgradeMinorVersion: true
              settings: {}
            }
          }
          // 6. Key Vault Extension (conditional)
          if (!empty(keyVaultCertificateUrls)) {
            name: 'KeyVaultForWindows'
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
          // 7. Azure DevOps Agent
          {
            name: 'AzureDevOpsAgent'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-win-x64-3.236.1.zip -OutFile agent.zip; Expand-Archive -Path agent.zip -DestinationPath C:\\agent; cd C:\\agent; .\\config.cmd --unattended --url ${azureDevOpsOrgUrl} --auth pat --token ${azureDevOpsPat} --pool ${azureDevOpsAgentPool} --agent $env:COMPUTERNAME --runAsService; .\\run.cmd"'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output vmssId string = vmss.id
output vmssName string = vmss.name
output vmssResourceGroupId string = resourceGroup().id
