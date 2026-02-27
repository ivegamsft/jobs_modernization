# RDP Access Configuration

## Overview

RDP access is now enabled automatically during VM deployment using Custom Script Extensions.

## What Was Configured

### VM Extensions Added

Both WFE and SQL VMs now have a Custom Script Extension that runs on first boot:

**Extension Name:** `EnableRDP`
**Actions Performed:**

1. ✅ Enables RDP in Windows Registry (`fDenyTSConnections = 0`)
2. ✅ Enables Windows Firewall rules for Remote Desktop
3. ✅ Sets Terminal Service to start automatically
4. ✅ Starts Terminal Service (TermService)

### PowerShell Commands Executed

```powershell
Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Terminal Server `
    -Name fDenyTSConnections -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Set-Service -Name TermService -StartupType Automatic

Start-Service -Name TermService
```

## RDP Connection Details

### Load Balancer Configuration

- **Public IP:** 51.12.90.221
- **Port Range:** 50001-50100 → Backend Port 3389 (RDP)

### VM Port Mappings

| VM         | Private IP | RDP Port | Connection String    |
| ---------- | ---------- | -------- | -------------------- |
| **WFE VM** | 10.50.0.5  | 50001    | `51.12.90.221:50001` |
| **SQL VM** | 10.50.1.5  | 50002    | `51.12.90.221:50002` |

## How to Connect

### Using Remote Desktop Connection (mstsc)

#### Windows:

1. Open **Remote Desktop Connection** (Win+R → `mstsc`)
2. Enter connection details:
   - **WFE:** `51.12.90.221:50001`
   - **SQL:** `51.12.90.221:50002`
3. Click **Connect**
4. Enter credentials from Key Vault

#### PowerShell:

```powershell
# Connect to WFE VM
mstsc /v:51.12.90.221:50001

# Connect to SQL VM
mstsc /v:51.12.90.221:50002
```

### Using Azure CLI to Get Credentials

```powershell
# Get WFE credentials
$wfeUser = az keyvault secret show --vault-name kv-dev-swc-ubzfsgu4p5 `
    --name wfe-admin-username --query value -o tsv

$wfePwd = az keyvault secret show --vault-name kv-dev-swc-ubzfsgu4p5 `
    --name wfe-admin-password --query value -o tsv

Write-Host "WFE Login: $wfeUser" -ForegroundColor Cyan
Write-Host "Password retrieved from Key Vault" -ForegroundColor Gray

# Get SQL credentials
$sqlUser = az keyvault secret show --vault-name kv-dev-swc-ubzfsgu4p5 `
    --name sql-admin-username --query value -o tsv

$sqlPwd = az keyvault secret show --vault-name kv-dev-swc-ubzfsgu4p5 `
    --name sql-admin-password --query value -o tsv

Write-Host "`nSQL Login: $sqlUser" -ForegroundColor Cyan
Write-Host "Password retrieved from Key Vault" -ForegroundColor Gray
```

## Troubleshooting

### Connection Refused

✅ **Fixed:** Custom Script Extension automatically configures RDP on boot

### Firewall Blocking Connection

✅ **Fixed:** Windows Firewall rules enabled automatically
✅ **Fixed:** NSG allows RDP from your IP (50.235.23.34/32)
✅ **Fixed:** Load Balancer NAT rules configured (50001-50100 → 3389)

### Service Not Running

✅ **Fixed:** Terminal Service set to Automatic startup and started by extension

### Verify Extension Execution

```powershell
# Check if extension ran successfully on WFE
az vm extension show `
    --resource-group jobsite-iaas-dev-rg `
    --vm-name jobsite-dev-wfe-<suffix> `
    --name EnableRDP `
    --query "provisioningState" -o tsv

# Check if extension ran successfully on SQL VM
az vm extension show `
    --resource-group jobsite-iaas-dev-rg `
    --vm-name jobsite-dev-sqlvm-<suffix> `
    --name EnableRDP `
    --query "provisioningState" -o tsv
```

Expected output: `Succeeded`

### Manual RDP Configuration (If Needed)

If the extension fails, you can manually configure RDP via Azure Serial Console:

```powershell
# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name 'fDenyTSConnections' -Value 0

# Enable firewall rules
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Start service
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService
```

## Network Security

### Allowed Source IPs

RDP is restricted to your IP address: **50.235.23.34/32**

### NSG Rules

- **Name:** `AllowRDPFromAllowedIps`
- **Priority:** 110
- **Protocol:** TCP
- **Port:** 3389
- **Source:** Your IP (50.235.23.34/32)
- **Action:** Allow

## Architecture

```
Internet (Your IP: 50.235.23.34)
    ↓
Load Balancer (51.12.90.221)
    ├─ Port 50001 → WFE VM:3389
    └─ Port 50002 → SQL VM:3389
         ↓
NSG (allows RDP from your IP)
    ↓
VMs with RDP Enabled (via Custom Script Extension)
```

## Post-Deployment Verification

After deployment completes:

1. **Verify extensions installed:**

   ```powershell
   az vm extension list --resource-group jobsite-iaas-dev-rg `
       --vm-name <vm-name> --query "[].name" -o table
   ```

2. **Test RDP connection:**

   ```powershell
   mstsc /v:51.12.90.221:50001
   ```

3. **Check Event Logs on VM (after RDP):**
   - Open Event Viewer
   - Navigate to: Applications and Services Logs → Microsoft → Windows → TerminalServices-RemoteConnectionManager → Operational
   - Look for successful connection events

## Security Best Practices

✅ **Implemented:**

- RDP restricted to specific IP address
- Credentials stored in Key Vault (not in code)
- Strong passwords (20 characters, complexity requirements)
- RBAC-based access to Key Vault secrets
- NAT rules isolate VMs from direct internet exposure

🔐 **Additional Recommendations:**

- Use Bastion for production environments (removes public RDP ports)
- Enable JIT (Just-In-Time) access for temporary RDP sessions
- Configure Azure AD authentication for VMs
- Enable MFA for administrator accounts
- Monitor RDP connection logs via Azure Monitor
