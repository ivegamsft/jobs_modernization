# Network Security Configuration Summary

## Quick Reference

### ✅ What Has Been Configured

#### 1. **Web VM (Frontend Subnet: 10.50.0.0/24)**

**Inbound Traffic:**

- HTTP (80) - from Internet
- HTTPS (443) - from Internet
- RDP (3389) - from Allowed IPs only
- WinRM (5985, 5986) - from VirtualNetwork

**Outbound Traffic:**

- SQL (1433) - to Data Subnet (10.50.1.0/26)
- All other outbound via NAT Gateway

#### 2. **SQL VM (Data Subnet: 10.50.1.0/26)**

**Inbound Traffic:**

- SQL (1433) - from Frontend Subnet (10.50.0.0/24) ← Web VM communication
- SQL (1433) - from VirtualNetwork ← SSMS and .NET automation tools
- RDP (3389) - from Allowed IPs only
- WinRM (5985, 5986) - from VirtualNetwork

#### 3. **NAT Gateway**

**Status:** ✅ **Fully Configured**

**Configuration:**

- Public IP: Static (Standard SKU)
- Associated Subnets: Frontend + Data
- Function: Single outbound IP for all internal traffic
- Idle Timeout: 4 minutes

---

## Communication Matrix

| Source    | Destination | Port | Protocol | Purpose               | Status                 |
| --------- | ----------- | ---- | -------- | --------------------- | ---------------------- |
| Web VM    | SQL VM      | 1433 | TCP      | App queries database  | ✅ Allowed             |
| SQL VM    | Web VM      | 1433 | TCP      | Return data to app    | ✅ Allowed (response)  |
| Admin     | Web VM      | 3389 | TCP      | RDP remote desktop    | ✅ If in allowedRdpIps |
| Admin     | SQL VM      | 3389 | TCP      | RDP remote desktop    | ✅ If in allowedRdpIps |
| Admin     | SQL VM      | 1433 | TCP      | SSMS database mgmt    | ✅ From VNet           |
| .NET Tool | SQL VM      | 1433 | TCP      | Direct SQL connection | ✅ From VNet           |
| .NET Tool | Web VM      | 5985 | TCP      | WinRM automation      | ✅ From VNet           |
| .NET Tool | SQL VM      | 5985 | TCP      | WinRM automation      | ✅ From VNet           |
| Internet  | Web VM      | 80   | TCP      | HTTP web traffic      | ✅ Allowed             |
| Internet  | Web VM      | 443  | TCP      | HTTPS web traffic     | ✅ Allowed             |

---

## Files Modified

### Bicep Infrastructure Files

**[iac/bicep/iaas/iaas-resources.bicep](../iaas/iaas-resources.bicep)**

- Added NSG rule for Web VM to SQL VM communication (port 1433)
- Frontend NSG: SQL outbound rule to Data Subnet
- Data NSG: SQL inbound from Frontend, VirtualNetwork, RDP, WinRM

**[iac/bicep/core/core-resources.bicep](../core/core-resources.bicep)**

- ✅ Already configured: NAT Gateway with static public IP
- ✅ Already configured: NAT Gateway associated to both subnets
- No changes needed

### Documentation Files Created

1. **[NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md)**
   - Detailed network architecture
   - Complete NSG rule listings
   - Communication flow explanations
   - Troubleshooting guide

2. **[NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)**
   - Configuration checklist
   - Testing instructions
   - Validation procedures

3. **[DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)**
   - PowerShell deployment script
   - Azure CLI deployment script
   - Terraform example
   - Portal deployment steps
   - Post-deployment verification

---

## NSG Rules Summary Table

### Frontend NSG (Web VM)

| Priority | Name                   | Protocol | Port | Source         | Direction | Access |
| -------- | ---------------------- | -------- | ---- | -------------- | --------- | ------ |
| 100      | AllowHTTP              | TCP      | 80   | \*             | Inbound   | Allow  |
| 110      | AllowHTTPS             | TCP      | 443  | \*             | Inbound   | Allow  |
| 120      | AllowRDPFromAllowedIps | TCP      | 3389 | allowedRdpIps  | Inbound   | Allow  |
| 125      | AllowSQLToDataSubnet   | TCP      | 1433 | \*             | Outbound  | Allow  |
| 130      | AllowWinRMHTTP         | TCP      | 5985 | VirtualNetwork | Inbound   | Allow  |
| 140      | AllowWinRMHTTPS        | TCP      | 5986 | VirtualNetwork | Inbound   | Allow  |

### Data NSG (SQL VM)

| Priority | Name                       | Protocol | Port | Source         | Direction | Access |
| -------- | -------------------------- | -------- | ---- | -------------- | --------- | ------ |
| 100      | AllowSQLFromFrontendSubnet | TCP      | 1433 | 10.50.0.0/24   | Inbound   | Allow  |
| 105      | AllowSQLFromVirtualNetwork | TCP      | 1433 | VirtualNetwork | Inbound   | Allow  |
| 110      | AllowRDPFromAllowedIps     | TCP      | 3389 | allowedRdpIps  | Inbound   | Allow  |
| 120      | AllowWinRMHTTP             | TCP      | 5985 | VirtualNetwork | Inbound   | Allow  |
| 130      | AllowWinRMHTTPS            | TCP      | 5986 | VirtualNetwork | Inbound   | Allow  |

---

## Critical Parameters

### When Deploying, Provide:

```powershell
# Your allowed RDP IPs - MUST BE PROVIDED AT DEPLOYMENT TIME
allowedRdpIps = [
  "203.0.113.0/32",        # Your office IP
  "198.51.100.0/24",       # Your VPN subnet (optional)
  "192.0.2.5/32"           # Another location (optional)
]
```

**Why:** RDP (port 3389) is only accessible from these IPs. If not provided, RDP will be blocked.

---

## Security Checklist

- ✅ Web VM cannot receive traffic from Internet on SQL port (1433)
- ✅ SQL VM only accepts SQL from Frontend subnet and VNet admins
- ✅ RDP is restricted to authorized IPs (not open to Internet)
- ✅ WinRM is restricted to VNet (for .NET automation)
- ✅ Outbound traffic uses NAT Gateway (single static IP)
- ✅ No unnecessary ports exposed
- ✅ SSMS can connect via VNet access
- ✅ .NET tools can use both direct SQL and WinRM access

---

## Testing Checklist

After deployment, verify:

```powershell
# Test 1: Web VM to SQL VM connectivity
Test-NetConnection -ComputerName $sqlVmPrivateIp -Port 1433

# Test 2: RDP access to Web VM
mstsc /v:$webVmIp

# Test 3: RDP access to SQL VM
mstsc /v:$sqlVmIp

# Test 4: SSMS can connect to SQL
# Server: $sqlVmPrivateIp,1433
# Authentication: Windows

# Test 5: Outbound IP via NAT Gateway
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content
# Should show NAT Gateway public IP

# Test 6: WinRM connectivity
Test-WSMan -ComputerName $sqlVmPrivateIp
```

---

## Common Issues & Solutions

### Problem: Web VM can't connect to SQL VM

**Check:**

- [ ] Frontend NSG has outbound rule for port 1433
- [ ] Data NSG has inbound rule for port 1433 from 10.50.0.0/24
- [ ] SQL Server is running on port 1433
- [ ] Firewall on SQL VM allows port 1433

**Solution:** Review `NETWORK_SECURITY_CONFIGURATION.md` section "Web VM to SQL VM Communication"

### Problem: Can't RDP to VMs

**Check:**

- [ ] Your public IP is in `allowedRdpIps` array
- [ ] NSG inbound RDP rule is present (priority 120/110)
- [ ] You're using correct credentials
- [ ] VM is running and accepting connections

**Solution:** Add your IP to `allowedRdpIps` parameter and redeploy

### Problem: SSMS can't connect

**Check:**

- [ ] Data NSG allows SQL from VirtualNetwork
- [ ] SQL Server is configured for TCP/IP
- [ ] SQL Server Browser is running
- [ ] Correct connection string format

**Solution:** Try direct IP:port format `<PRIVATE_IP>,1433` instead of hostname

### Problem: Outbound traffic not using NAT Gateway

**Check:**

- [ ] NAT Gateway is associated to the subnet
- [ ] No User Defined Routes (UDRs) conflict
- [ ] Subnet exists and has valid configuration

**Solution:** Check core deployment output for NAT Gateway ID

---

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                    AZURE VNET (10.50.0.0/21)                  │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Frontend Subnet (10.50.0.0/24)                          │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────┐                     │  │
│  │  │  Web VM (WFE)                   │                     │  │
│  │  │  - Runs .NET App                │                     │  │
│  │  │  - HTTP/HTTPS listening         │                     │  │
│  │  │  - Connects to SQL on :1433     │                     │  │
│  │  └─────────────────────────────────┘                     │  │
│  │                                                            │  │
│  │  NSG Rules (Frontend):                                    │  │
│  │  ✓ Inbound: HTTP(80), HTTPS(443), RDP(3389), WinRM       │  │
│  │  ✓ Outbound: SQL(1433) to Data subnet                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│           │                              │                      │
│           │ (Can connect on :1433)       │ (Outbound via NAT)  │
│           │                              │                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  NAT Gateway (Static Public IP)                            │  │
│  │  - Single IP for all outbound traffic                      │  │
│  │  - Associated to both Frontend & Data subnets             │  │
│  │  - Idle timeout: 4 minutes                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│           ▲                                                       │
│           │ (Return traffic)                                     │
│           │                                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Data Subnet (10.50.1.0/26)                              │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────┐                     │  │
│  │  │  SQL Server VM                  │                     │  │
│  │  │  - SQL 2022                     │                     │  │
│  │  │  - Listening on :1433           │                     │  │
│  │  │  - Premium SSD storage          │                     │  │
│  │  └─────────────────────────────────┘                     │  │
│  │                                                            │  │
│  │  NSG Rules (Data):                                        │  │
│  │  ✓ Inbound: SQL(1433) from Frontend, RDP(3389), WinRM    │  │
│  │  ✓ Outbound: All via NAT                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└────────────────────────────────────────────────────────────────┘
```

---

## Next Steps

1. **Review** [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md) for complete details
2. **Use** [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md) to deploy infrastructure
3. **Validate** using [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)
4. **Monitor** NSG rules in Azure Portal after deployment
5. **Test** connectivity following verification checklist

---

## Support Resources

- [Azure NSG Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure NAT Gateway](https://learn.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-overview)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)

---

**Last Updated:** January 22, 2026  
**Status:** ✅ Complete - All network security configured and documented
