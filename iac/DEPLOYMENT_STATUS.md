# Job Site Infrastructure Deployment - Status & Next Steps

## Current Status

### ✅ Completed
- **Core Infrastructure**: Deployed successfully
  - VNet with 7 subnets
  - NAT Gateway
  - Key Vault: `kv-ubzfsgu4-dev`
  - Log Analytics Workspace
  - Private DNS Zone
  - Time: ~5-10 minutes

### ⏸️ Pending
- **IAAS Infrastructure** - Azure CLI issues preventing deployment
- **PaaS Infrastructure** - Awaiting IAAS completion

---

## Generated Credentials

### Strong Passwords (20 characters with special chars)

```
VM Admin Username:        azureadmin
VM Admin Password:        6-CtFhZr1y6nm8Q&C#to
Certificate Password:     4lbeGK1H?&Xia12H%WGI
```

**Action**: Save these immediately and securely

---

## Option 1: Deploy via Azure Portal (Recommended)

1. Go to https://portal.azure.com
2. Search for "Deploy a custom template"
3. Click "Build your own template in the editor"
4. Paste the contents of: `iac/bicep/iaas/main.bicep`
5. Click "Save"
6. Fill in parameters:
   ```
   Environment: dev
   Location: eastus
   Front-end Subnet ID: /subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/virtualNetworks/jobsite-dev-vnet-ubzfsgu4p5eli/subnets/snet-fe
   Data Subnet ID: /subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/virtualNetworks/jobsite-dev-vnet-ubzfsgu4p5eli/subnets/snet-data
   Admin Password: 6-CtFhZr1y6nm8Q&C#to
   App Gateway Cert Password: 4lbeGK1H?&Xia12H%WGI
   ```
7. For `appGatewayCertData`, use the base64-encoded certificate (will be generated)
8. Click "Review + create" → "Create"

---

## Option 2: Deploy via Azure CLI (Troubleshoot First)

```powershell
# Test CLI functionality
az --version
az account show

# Run diagnostics
pwsh -File c:\git\jobs_modernization\iac\diagnose.ps1

# Try manual deployment
cd c:\git\jobs_modernization\iac
.\deploy-iaas-v2.ps1
```

---

## Option 3: Deploy via Bicep CLI

```powershell
bicep build c:\git\jobs_modernization\iac\bicep\iaas\main.bicep
az deployment sub create `
    --name jobsite-iaas-dev `
    --location eastus `
    --template-file main.json `
    --parameters @params.json
```

---

## Deployment Architecture

```
Core Infrastructure (Deployed ✅)
├── VNet (10.50.0.0/24)
│   ├── snet-fe (10.50.0.0/27)
│   ├── snet-data (10.50.0.32/27)
│   ├── snet-pe (10.50.0.96/27)
│   └── GatewaySubnet (10.50.0.64/27)
├── NAT Gateway
├── Key Vault
├── Log Analytics
└── Private DNS Zone

↓

IAAS Infrastructure (Pending ⏸️)
├── VMSS (Web/App tier) - 2 instances
│   ├── OS: Windows Server 2022
│   ├── Size: Standard_D2s_v4
│   └── Backend to App Gateway
├── SQL VM (Data tier)
│   ├── OS: SQL Server 2022
│   ├── Size: Standard_D4s_v4
│   └── Private network
└── Application Gateway
    ├── Public IP
    ├── SSL termination
    └── Path-based routing

↓

PaaS Infrastructure (Planning)
├── App Service Plan (S1)
├── App Service
├── Azure SQL Server
├── SQL Database
├── Application Insights
└── Private Endpoint
```

---

## Troubleshooting Notes

### "Content Already Consumed" Error
- Caused by Azure CLI session issues
- Workaround: Use parameter files or Portal
- Restart PowerShell session if persists

### Network Connectivity
- Ensure NAT Gateway is working
- VPN Gateway (separate, optional deployment): `.\deploy-vpn.ps1`

### Certificate Issues
- Self-signed cert generated automatically
- Valid for 2 years
- PFX format, password protected

---

## Next Steps

1. **Choose deployment method** above
2. **Deploy IAAS infrastructure** (15-20 min)
3. **Verify VMSS & SQL VM** are running
4. **Deploy PaaS infrastructure** (10-15 min)
5. **Test end-to-end connectivity**
6. **Optional**: Deploy VPN Gateway separately

---

## Passwords Stored In

- Key Vault: `kv-ubzfsgu4-dev`
- Retrieve: `az keyvault secret show --vault-name kv-ubzfsgu4-dev --name [secret-name]`

---

## Key Files

- Bicep Templates:
  - `iac/bicep/core/main.bicep` ✅
  - `iac/bicep/iaas/main.bicep` ⏸️
  - `iac/bicep/paas/main.bicep` ⏹️
  - `iac/bicep/core/deploy-vpn.bicep` (Optional)

- Deployment Scripts:
  - `iac/deploy-iaas-v2.ps1`
  - `iac/deploy-app-layers.ps1`
  - `iac/get-credentials.ps1`
  - `iac/diagnose.ps1`

---

## Support

For issues:
1. Check `iac/diagnose.ps1` output
2. Review Azure Portal deployment history
3. Check Resource Group activity logs
4. Verify Core infrastructure is fully deployed first
