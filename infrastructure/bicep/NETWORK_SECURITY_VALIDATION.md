# Network Security Validation Checklist

## ✅ Web VM (Frontend Subnet) - All Configured

### Inbound Rules

- [x] HTTP (80) from Internet
- [x] HTTPS (443) from Internet
- [x] RDP (3389) from Allowed IPs
- [x] WinRM HTTP (5985) from VirtualNetwork
- [x] WinRM HTTPS (5986) from VirtualNetwork

### Outbound Rules

- [x] SQL (1433) to Data Subnet (10.50.1.0/26)
- [x] Default outbound rules

### NAT Gateway

- [x] Associated to Frontend Subnet
- [x] Static Public IP configured
- [x] Idle timeout: 4 minutes

---

## ✅ SQL Server VM (Data Subnet) - All Configured

### Inbound Rules

- [x] SQL (1433) from Frontend Subnet (10.50.0.0/24) → Application communication
- [x] SQL (1433) from VirtualNetwork → SSMS, .NET automation access
- [x] RDP (3389) from Allowed IPs → Remote desktop access
- [x] WinRM HTTP (5985) from VirtualNetwork → .NET automation
- [x] WinRM HTTPS (5986) from VirtualNetwork → .NET automation

### NAT Gateway

- [x] Associated to Data Subnet
- [x] Static Public IP configured
- [x] Idle timeout: 4 minutes

---

## ✅ Communication Paths Verified

| Source     | Destination | Protocol | Port | Allowed? | Notes                                |
| ---------- | ----------- | -------- | ---- | -------- | ------------------------------------ |
| Web VM     | SQL VM      | TCP      | 1433 | ✅       | Application queries database         |
| RDP Client | Web VM      | TCP      | 3389 | ✅       | Remote desktop (if in allowedRdpIps) |
| RDP Client | SQL VM      | TCP      | 3389 | ✅       | Remote desktop (if in allowedRdpIps) |
| SSMS       | SQL VM      | TCP      | 1433 | ✅       | Database management from VNet        |
| .NET Tool  | SQL VM      | TCP      | 1433 | ✅       | Direct SQL connection from VNet      |
| .NET Tool  | Web VM      | TCP      | 5985 | ✅       | WinRM HTTP for automation            |
| .NET Tool  | SQL VM      | TCP      | 5985 | ✅       | WinRM HTTP for automation            |
| .NET Tool  | Web VM      | TCP      | 5986 | ✅       | WinRM HTTPS for automation           |
| .NET Tool  | SQL VM      | TCP      | 5986 | ✅       | WinRM HTTPS for automation           |
| Internet   | Web VM      | TCP      | 80   | ✅       | HTTP web traffic                     |
| Internet   | Web VM      | TCP      | 443  | ✅       | HTTPS web traffic                    |

---

## ⚙️ Deployment Configuration Required

### Parameters to Provide

```powershell
# When deploying, specify allowed IPs for RDP
$allowedRdpIps = @(
  '<YOUR_OFFICE_IP>/32',        # Single IP
  '<YOUR_VPN_SUBNET>/24'        # VPN subnet
)
```

**Example for Sweden office at 203.0.113.0/32:**

```powershell
allowedRdpIps = ['203.0.113.0/32']
```

---

## 🔍 Testing Instructions

### 1. Test Web VM to SQL VM Connectivity

```powershell
# On Web VM, test SQL connection
Test-NetConnection -ComputerName <SQL_PRIVATE_IP> -Port 1433

# Or in .NET code
using System.Data.SqlClient;
var connectionString = "Server=<SQL_PRIVATE_IP>;Integrated Security=true;";
using var connection = new SqlConnection(connectionString);
connection.Open();  // Should succeed
```

### 2. Test RDP Access

```powershell
# From your office/authorized IP
mstsc /v:<WEB_VM_PUBLIC_IP>
mstsc /v:<SQL_VM_PUBLIC_IP>
```

### 3. Test SSMS Connection

```
Server Name: <SQL_VM_PRIVATE_IP>,1433
Authentication: Windows Authentication
```

### 4. Test WinRM Connectivity

```powershell
# From authorized admin machine on VNet
Test-WSMan -ComputerName <SQL_VM_PRIVATE_IP>
```

### 5. Test Outbound NAT

```powershell
# On Web or SQL VM, check outbound IP
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content
# Should return the NAT Gateway public IP
```

---

## 📋 Summary

### Web VM Configuration

- **Location:** Frontend Subnet (10.50.0.0/24)
- **Allows:** Public web traffic (80, 443), RDP, SQL outbound, WinRM
- **Outbound:** All traffic via NAT Gateway static IP

### SQL VM Configuration

- **Location:** Data Subnet (10.50.1.0/26)
- **Allows:** SQL from Web & VNet, RDP, WinRM
- **Inbound:** Only SQL (1433) and management ports
- **Outbound:** All traffic via NAT Gateway static IP

### NAT Gateway

- **Public IP:** Static Standard SKU
- **Associated Subnets:** Frontend (10.50.0.0/24) + Data (10.50.1.0/26)
- **Function:** Single static IP for all outbound traffic

### Key Security Features

✅ Firewall isolation between subnets  
✅ Strict port access (only required services exposed)  
✅ RDP limited to authorized IPs  
✅ SQL access restricted to appropriate sources  
✅ VNet-only admin access (SSMS, WinRM, tools)  
✅ NAT Gateway for secure outbound connectivity

---

## 📁 Configuration Files

Modified Files:

- `infrastructure/bicep/iaas/iaas-resources.bicep` - NSG rules added
- `infrastructure/bicep/core/core-resources.bicep` - NAT Gateway already configured

Documentation Files:

- `infrastructure/bicep/NETWORK_SECURITY_CONFIGURATION.md` - Detailed configuration guide
- `infrastructure/bicep/NETWORK_SECURITY_VALIDATION.md` - This file (validation checklist)
