# Network Security - Visual Reference

## Complete Network Architecture

```
╔════════════════════════════════════════════════════════════════════════════╗
║                           INTERNET (PUBLIC)                                ║
╚════════════════════════════════════════════════════════════════════════════╝
                    │                           │
                    │ HTTP (80)                 │ HTTPS (443)
                    │ HTTPS (443)               │
                    ▼                           ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                      AZURE VIRTUAL NETWORK (10.50.0.0/21)                  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  FRONTEND SUBNET (10.50.0.0/24)                                      │  │
│  │                                                                        │  │
│  │  ┌────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    WEB/APP VM (WFE)                            │  │  │
│  │  │  ┌──────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │ • IIS / ASP.NET Core Application                         │  │  │  │
│  │  │  │ • Private IP: 10.50.0.x (Dynamic)                        │  │  │  │
│  │  │  │ • NIC: jobsite-dev-wfe-xxx-nic                          │  │  │  │
│  │  │  │ • Size: Standard_D2ds_v6 (2 vCPU, 8GB RAM)              │  │  │  │
│  │  │  │ • OS: Windows Server 2022 Datacenter                    │  │  │  │
│  │  │  └──────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                                │  │  │
│  │  │  NSG: jobsite-dev-nsg-frontend                                │  │  │
│  │  │  ┌────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │ INBOUND Rules:                                         │  │  │  │
│  │  │  │ ✓ HTTP (80) from Internet                              │  │  │  │
│  │  │  │ ✓ HTTPS (443) from Internet                            │  │  │  │
│  │  │  │ ✓ RDP (3389) from allowedRdpIps                        │  │  │  │
│  │  │  │ ✓ WinRM HTTP (5985) from VirtualNetwork                │  │  │  │
│  │  │  │ ✓ WinRM HTTPS (5986) from VirtualNetwork               │  │  │  │
│  │  │  │                                                         │  │  │  │
│  │  │  │ OUTBOUND Rules:                                        │  │  │  │
│  │  │  │ ✓ SQL (1433) to Data Subnet (10.50.1.0/26)            │  │  │  │
│  │  │  │ ✓ All traffic via NAT Gateway                          │  │  │  │
│  │  │  └────────────────────────────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                        │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│           ▲                                                       │         │
│           │ TCP:1433                                             │         │
│           │ (SQL queries)                                        │         │
│           │                                                       ▼         │
│           │                                                   (Outbound)   │
│           │                                                   All traffic  │
│  ┌────────┼───────────────────────────────────────────────────────────┐   │
│  │        │                                                           │   │
│  │        │           NAT GATEWAY                                    │   │
│  │        │  ┌────────────────────────────────────┐                │   │
│  │        │  │ • Static Public IP (Azure assigned)│                │   │
│  │        │  │ • Idle Timeout: 4 minutes          │                │   │
│  │        │  │ • Standard SKU                     │                │   │
│  │        │  │ • Outbound SNAT for VMs            │                │   │
│  │        │  └────────────────────────────────────┘                │   │
│  │        │                                                         │   │
│  │        └─────────────────────────────────────────────────────────┘   │
│           │                                                               │
│  ┌────────┴──────────────────────────────────────────────────────────┐  │
│  │  DATA SUBNET (10.50.1.0/26)                                       │  │
│  │                                                                     │  │
│  │  ┌────────────────────────────────────────────────────────────┐   │  │
│  │  │                   SQL SERVER VM                            │   │  │
│  │  │  ┌──────────────────────────────────────────────────────┐  │   │  │
│  │  │  │ • SQL Server 2022 Standard Edition                  │  │   │  │
│  │  │  │ • Private IP: 10.50.1.x (Dynamic)                   │  │   │  │
│  │  │  │ • NIC: jobsite-dev-sqlvm-xxx-nic                   │  │   │  │
│  │  │  │ • Size: Standard_D4ds_v6 (4 vCPU, 16GB RAM)        │  │   │  │
│  │  │  │ • OS: Windows Server 2022 Datacenter               │  │   │  │
│  │  │  │ • Storage: 2 × Premium SSD 128GB (Data + Log)      │  │   │  │
│  │  │  │ • Port: 1433 (TCP/IP enabled)                      │  │   │  │
│  │  │  └──────────────────────────────────────────────────────┘  │   │  │
│  │  │                                                            │   │  │
│  │  │  NSG: jobsite-dev-nsg-data                               │   │  │
│  │  │  ┌──────────────────────────────────────────────────────┐  │   │  │
│  │  │  │ INBOUND Rules:                                       │  │   │  │
│  │  │  │ ✓ SQL (1433) from Frontend (10.50.0.0/24)           │  │   │  │
│  │  │  │ ✓ SQL (1433) from VirtualNetwork (SSMS, .NET)      │  │   │  │
│  │  │  │ ✓ RDP (3389) from allowedRdpIps                     │  │   │  │
│  │  │  │ ✓ WinRM HTTP (5985) from VirtualNetwork             │  │   │  │
│  │  │  │ ✓ WinRM HTTPS (5986) from VirtualNetwork            │  │   │  │
│  │  │  │                                                      │  │   │  │
│  │  │  │ OUTBOUND Rules:                                     │  │   │  │
│  │  │  │ ✓ All traffic via NAT Gateway                       │  │   │  │
│  │  │  └──────────────────────────────────────────────────────┘  │   │  │
│  │  └────────────────────────────────────────────────────────────┘   │  │
│  │                                                                     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Communication Flows

### Flow 1: Web Application to Database

```
User Browser                Web VM (IIS)              SQL Server VM
     │                          │                          │
     │ HTTP(80)/HTTPS(443)      │                          │
     ├─────────────────────────►│                          │
     │                          │ TCP:1433 (App Query)     │
     │                          ├─────────────────────────►│
     │                          │                          │
     │                          │ Return Data (Response)   │
     │                          │◄─────────────────────────┤
     │        HTML Response      │                          │
     │◄─────────────────────────┤                          │
     │                          │                          │
```

**NSG Rules Involved:**

- Frontend: Allow HTTP/HTTPS inbound, SQL outbound
- Data: Allow SQL inbound from Frontend subnet

---

### Flow 2: Remote Desktop Access

```
Admin Workstation (IP in allowedRdpIps)    Web or SQL VM
          │                                      │
          │ RDP (TCP:3389)                      │
          ├─────────────────────────────────────►│
          │                                      │
          │ Remote Desktop Session               │
          ◄─────────────────────────────────────►│
```

**NSG Rules Involved:**

- Frontend/Data: Allow RDP from allowedRdpIps

---

### Flow 3: SSMS Database Management

```
Admin Workstation (on VNet)      SQL Server VM
         │                            │
         │ SSMS Connection Setup      │
         │ TCP:1433                   │
         ├───────────────────────────►│
         │                            │
         │ Database Queries           │
         │ SQL Protocol (1433)        │
         ◄───────────────────────────►│
         │                            │
         │ Disconnection              │
         │                            │
```

**NSG Rules Involved:**

- Data: Allow SQL inbound from VirtualNetwork

---

### Flow 4: WinRM Automation

```
.NET Admin Tool (on VNet)        Web or SQL VM
         │                            │
         │ WinRM Connection Setup     │
         │ TCP:5985 or 5986           │
         ├───────────────────────────►│
         │                            │
         │ Remote Commands            │
         │ WinRM Protocol             │
         ◄───────────────────────────►│
         │                            │
         │ Command Results            │
         │                            │
```

**NSG Rules Involved:**

- Frontend/Data: Allow WinRM (5985, 5986) from VirtualNetwork

---

### Flow 5: Outbound Internet Traffic

```
Web/SQL VM                NAT Gateway           Internet Service
     │                         │                       │
     │ Outbound traffic        │                       │
     │ (VMs private IP)        │                       │
     ├────────────────────────►│ Translate to          │
     │                         │ NAT GW Public IP      │
     │                         ├──────────────────────►│
     │                         │                       │
     │                         │ Response traffic      │
     │                         │◄──────────────────────┤
     │ Response to VM          │                       │
     │◄────────────────────────┤                       │
```

**Configuration:**

- NAT Gateway static public IP masks all VMs' internal IPs
- Outbound connections appear to come from NAT Gateway IP

---

## Subnet Layout

```
VNET: 10.50.0.0/21 (2,048 IPs)
│
├─ Frontend (10.50.0.0/24) - 251 usable IPs
│  ├─ Web VM: 10.50.0.x (Dynamic)
│  └─ NSG: nsg-frontend
│
├─ Data (10.50.1.0/26) - 59 usable IPs
│  ├─ SQL VM: 10.50.1.x (Dynamic)
│  └─ NSG: nsg-data
│
└─ Other subnets (for future expansion)
   ├─ GitHub Runners (10.50.1.64/26)
   ├─ Private Endpoints (10.50.1.128/27)
   ├─ VPN Gateway (10.50.1.160/27)
   ├─ AKS (10.50.2.0/23)
   └─ Container Apps (10.50.4.0/26)
```

---

## NSG Rule Priority Matrix

### Frontend NSG (Web VM)

| Priority | Type     | Port | Source        | Action | Purpose   |
| -------- | -------- | ---- | ------------- | ------ | --------- |
| 100      | Inbound  | 80   | Internet      | Allow  | HTTP      |
| 110      | Inbound  | 443  | Internet      | Allow  | HTTPS     |
| 120      | Inbound  | 3389 | allowedRdpIps | Allow  | RDP Admin |
| 125      | Outbound | 1433 | 10.50.1.0/26  | Allow  | SQL Query |
| 130      | Inbound  | 5985 | VNet          | Allow  | WinRM     |
| 140      | Inbound  | 5986 | VNet          | Allow  | WinRM     |

### Data NSG (SQL VM)

| Priority | Type    | Port | Source        | Action | Purpose      |
| -------- | ------- | ---- | ------------- | ------ | ------------ |
| 100      | Inbound | 1433 | 10.50.0.0/24  | Allow  | Web VM Query |
| 105      | Inbound | 1433 | VNet          | Allow  | SSMS / Tools |
| 110      | Inbound | 3389 | allowedRdpIps | Allow  | RDP Admin    |
| 120      | Inbound | 5985 | VNet          | Allow  | WinRM        |
| 130      | Inbound | 5986 | VNet          | Allow  | WinRM        |

---

## Security Zones

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET (Public)                    │
│                                                             │
│                    HTTP/HTTPS (80, 443)                    │
└───────────────────────┬───────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│            PERIMETER ZONE (Frontend Subnet)                 │
│                                                             │
│  • Web Server / IIS Application                            │
│  • Public HTTP(S) access allowed                           │
│  • RDP from authorized IPs only                            │
│  • NAT Gateway for outbound                                │
│                                                             │
│  NSG Rules:                                                 │
│  ✓ IN: 80, 443 (Public)                                    │
│  ✓ IN: 3389 (Admin only)                                   │
│  ✓ OUT: 1433 to Database                                  │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ Internal VNet
                        │ Port 1433 (SQL)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              DATABASE ZONE (Data Subnet)                    │
│                                                             │
│  • SQL Server 2022 Premium Managed VM                      │
│  • NOT directly accessible from Internet                    │
│  • Only from Frontend subnet or VNet admins                │
│  • NAT Gateway for outbound                                │
│                                                             │
│  NSG Rules:                                                 │
│  ✓ IN: 1433 from Frontend (Queries)                        │
│  ✓ IN: 1433 from VNet (SSMS, Tools)                        │
│  ✓ IN: 3389 (Admin only)                                   │
│  ✓ OUT: Via NAT Gateway                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Traffic Decision Tree

```
Incoming Traffic to Web VM (Port 80/443)?
├─ YES → Allow (Internet to IIS)
└─ NO → Check next rule

Incoming Traffic to Web VM (Port 3389 RDP)?
├─ From allowedRdpIps?
│  ├─ YES → Allow
│  └─ NO → Block
└─ NO → Check next rule

Incoming Traffic to Web VM (Port 5985/5986 WinRM)?
├─ From VirtualNetwork?
│  ├─ YES → Allow
│  └─ NO → Block
└─ NO → Deny (default)

---

Web VM Outgoing Traffic to Data Subnet (Port 1433)?
├─ YES → Allow (Application to Database)
└─ NO → Route through NAT Gateway

Web VM Outgoing Traffic (Other)?
└─ Route through NAT Gateway (Translate to NAT Public IP)

---

Incoming Traffic to SQL VM (Port 1433)?
├─ From Frontend Subnet (10.50.0.0/24)?
│  ├─ YES → Allow (Application queries)
│  └─ NO → Check next
├─ From VirtualNetwork?
│  ├─ YES → Allow (SSMS, .NET tools)
│  └─ NO → Block
└─ NO → Check next rule

Incoming Traffic to SQL VM (Port 3389 RDP)?
├─ From allowedRdpIps?
│  ├─ YES → Allow
│  └─ NO → Block
└─ NO → Check next rule

Incoming Traffic to SQL VM (Port 5985/5986 WinRM)?
├─ From VirtualNetwork?
│  ├─ YES → Allow
│  └─ NO → Block
└─ NO → Deny (default)
```

---

## Key Takeaways

✅ **Web VM** is publicly accessible (HTTP/HTTPS)  
✅ **SQL VM** is NOT publicly accessible (protected)  
✅ **Web-to-SQL** communication on port 1433  
✅ **RDP access** is restricted by IP allowlist  
✅ **SSMS access** available from VNet  
✅ **WinRM access** for .NET automation tools  
✅ **NAT Gateway** masks all outbound IPs  
✅ **Network isolation** between zones
