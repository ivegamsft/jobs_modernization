# Deployment Summary - Jobs Modernization

## Configuration Updates (Latest)

### Location

- **Changed from**: East US → **West US**
- All modules (Core, IaaS, PaaS) now default to `westus`

### VM SKUs (IaaS)

- **VMSS**: `Standard_D2s_v4` (Dv4 Family)
- **SQL VM**: `Standard_D4s_v4` (Dv4 Family)
- **Changed from**: Dv3 Family SKUs

### PaaS Security Configuration

- ✅ App Service: System-assigned managed identity
- ✅ SQL Server: Azure AD-only authentication (RBAC)
- ✅ SQL Server: Public network access disabled
- ✅ Private Endpoint: SQL connected via private link to Core VNet
- ✅ RBAC: App Service MI granted SQL DB Contributor role

### App Gateway Configuration

- ✅ Fixed: Backend HTTP settings now includes `pickHostNameFromBackendAddress: true`
- ✅ SSL/TLS: Self-signed certificate support with HTTPS listener
- ✅ Redirect: HTTP to HTTPS permanent redirect configured

## Deployment Status

### Core Infrastructure (East US deployment completed)

- Resource Group: `jobsite-core-dev-rg`
- VNet: `jobsite-dev-vnet-ubzfsgu4p5eli` (10.50.0.0/16)
- Subnets: Frontend, Data, Private Endpoints
- Key Vault: `kv-ubzfsgu4-dev`
- Log Analytics: `jobsite-dev-la-ubzfsgu4p5eli`
- Private DNS: `jobsite.internal`
- VPN Gateway: Public IP `20.185.241.52`
- NAT Gateway: Public IP `172.191.117.215`

**Note**: Core was deployed in East US. For production consistency, redeploy Core in West US or keep regional separation.

### IaaS (Pending - West US)

- Ready to deploy with Dv4 SKUs
- App Gateway probe configuration fixed

### PaaS (In Progress/Pending - West US)

- Configured with managed identity + RBAC
- Requires redeployment in West US to match new location

## Next Steps

1. **Deploy Core in West US** (if consistency needed):

   ```powershell
   az deployment sub create \
     --name jobsite-core-westus \
     --location westus \
     --template-file iac/bicep/core/main.bicep \
     --parameters environment=dev applicationName=jobsite \
                  vnetAddressPrefix=10.50.0.0/16 \
                  sqlAdminUsername=jobsiteadmin \
                  sqlAdminPassword=<secure>
   ```

2. **Deploy IaaS in West US**:

   ```powershell
   # Fetch Core outputs (from westus deployment)
   $core = az deployment sub show --name jobsite-core-westus -o json | ConvertFrom-Json
   $frontendSubnetId = $core.properties.outputs.frontendSubnetId.value
   $dataSubnetId = $core.properties.outputs.dataSubnetId.value

   # Generate credentials and certificate
   $vmPassword = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 20 | % {[char]$_}) + "!Aa1"
   $certPassword = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 20 | % {[char]$_}) + "!Aa1"
   $cert = New-SelfSignedCertificate -DnsName "jobsite-appgw.local" -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(2) -KeyExportPolicy Exportable
   $pfxPath = "$env:TEMP\appgw-$([Guid]::NewGuid()).pfx"
   $secure = ConvertTo-SecureString -String $certPassword -AsPlainText -Force
   Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $secure | Out-Null
   $certBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
   Remove-Item $pfxPath -Force

   # Deploy IaaS
   az deployment sub create \
     --name jobsite-iaas-westus \
     --location westus \
     --template-file iac/bicep/iaas/main.bicep \
     --parameters environment=dev location=westus \
                  frontendSubnetId=$frontendSubnetId \
                  dataSubnetId=$dataSubnetId \
                  adminUsername=azureadmin \
                  adminPassword=$vmPassword \
                  appGatewayCertData=$certBase64 \
                  appGatewayCertPassword=$certPassword \
                  vmSize=Standard_D2s_v4 \
                  sqlVmSize=Standard_D4s_v4
   ```

3. **Deploy PaaS in West US**:

   ```powershell
   $peSubnetId = $core.properties.outputs.peSubnetId.value
   $logAnalyticsWorkspaceId = $core.properties.outputs.logAnalyticsWorkspaceId.value
   $currentUser = az ad signed-in-user show | ConvertFrom-Json

   az deployment sub create \
     --name jobsite-paas-westus \
     --location westus \
     --template-file iac/bicep/paas/main.bicep \
     --parameters environment=dev location=westus \
                  peSubnetId=$peSubnetId \
                  logAnalyticsWorkspaceId=$logAnalyticsWorkspaceId \
                  sqlAadAdminObjectId=$currentUser.id \
                  sqlAadAdminName=$currentUser.displayName
   ```

## Fixes Applied

### App Gateway Probe Issue

**Problem**: Probe with `pickHostNameFromBackendHttpSettings: true` requires backend HTTP settings to define `HostName` property or set `pickHostNameFromBackendAddress: true`.

**Solution**: Added `pickHostNameFromBackendAddress: true` to backend HTTP settings in [iac/bicep/iaas/iaas-resources.bicep](../iac/bicep/iaas/iaas-resources.bicep).

### SQL Server Authentication

**Problem**: Policy restrictions on SQL Server creation with admin login/password.

**Solution**: Switched to Azure AD-only authentication with managed identity for App Service access.

### Regional Constraints

**Problem**: East US had quota limitations and policy restrictions.

**Solution**: Changed default location to West US for all modules.
