# Network Security Configuration - IaaS Infrastructure

## Overview

This document describes the network security configuration for the IaaS infrastructure, including Web VM and SQL Server VM communication, NAT Gateway setup, and NSG rules.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AZURE VNET (10.50.0.0/21)              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Frontend Subnet (10.50.0.0/24) + NAT Gateway           │ │
│  │  ┌────────────────────────────────────────┐             │ │
│  │  │ Web VM (WFE)                          │             │ │
│  │  │ - Runs IIS / .NET Application        │             │ │
│  │  │ - Communicates to SQL VM on :1433    │             │ │
│  │  └────────────────────────────────────────┘             │ │
│  │  NSG Rules:                                             │ │
│  │  • HTTP (80) from Internet                              │ │
│  │  • HTTPS (443) from Internet                            │ │
│  │  • RDP (3389) from Allowed IPs                          │ │
│  │  • SQL (1433) OUT to Data Subnet                        │ │
│  │  • WinRM (5985, 5986) from VNet                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Data Subnet (10.50.1.0/26) + NAT Gateway               │ │
│  │  ┌────────────────────────────────────────┐             │ │
│  │  │ SQL Server VM                         │             │ │
│  │  │ - SQL 2022 on Windows Server 2022     │             │ │
│  │  │ - Listening on port 1433              │             │ │
│  │  └────────────────────────────────────────┘             │ │
│  │  NSG Rules:                                             │ │
│  │  • SQL (1433) from Frontend Subnet                       │ │
│  │  • SQL (1433) from VirtualNetwork (SSMS, .NET tools)    │ │
│  │  • RDP (3389) from Allowed IPs                          │ │
│  │  • WinRM (5985, 5986) from VNet                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  NAT Gateway Configuration                              │ │
│  │  • Public IP: Static (Standard SKU)                     │ │
│  │  • Associated to: Frontend + Data Subnets               │ │
│  │  • Idle Timeout: 4 minutes                              │ │
│  │  • Outbound SNAT: All outbound traffic uses Public IP   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Network Security Groups (NSGs)

### Frontend Subnet NSG (Web VM)

**Inbound Rules:**

| Priority | Name                   | Protocol | Port | Source         | Destination | Action |
| -------- | ---------------------- | -------- | ---- | -------------- | ----------- | ------ |
| 100      | AllowHTTP              | TCP      | 80   | Internet (\*)  | \*          | Allow  |
| 110      | AllowHTTPS             | TCP      | 443  | Internet (\*)  | \*          | Allow  |
| 120      | AllowRDPFromAllowedIps | TCP      | 3389 | AllowedRdpIps  | \*          | Allow  |
| 130      | AllowWinRMHTTP         | TCP      | 5985 | VirtualNetwork | \*          | Allow  |
| 140      | AllowWinRMHTTPS        | TCP      | 5986 | VirtualNetwork | \*          | Allow  |

**Outbound Rules:**

| Priority | Name                 | Protocol | Port | Source | Destination  | Action |
| -------- | -------------------- | -------- | ---- | ------ | ------------ | ------ |
| 125      | AllowSQLToDataSubnet | TCP      | 1433 | \*     | 10.50.1.0/26 | Allow  |

### Data Subnet NSG (SQL VM)

**Inbound Rules:**

| Priority | Name                       | Protocol | Port | Source         | Destination | Action |
| -------- | -------------------------- | -------- | ---- | -------------- | ----------- | ------ |
| 100      | AllowSQLFromFrontendSubnet | TCP      | 1433 | 10.50.0.0/24   | \*          | Allow  |
| 105      | AllowSQLFromVirtualNetwork | TCP      | 1433 | VirtualNetwork | \*          | Allow  |
| 110      | AllowRDPFromAllowedIps     | TCP      | 3389 | AllowedRdpIps  | \*          | Allow  |
| 120      | AllowWinRMHTTP             | TCP      | 5985 | VirtualNetwork | \*          | Allow  |
| 130      | AllowWinRMHTTPS            | TCP      | 5986 | VirtualNetwork | \*          | Allow  |

## Communication Flows

### 1. Web VM to SQL VM (Application Communication)

**Flow:**

```
Web VM (10.50.0.x) → TCP:1433 → SQL VM (10.50.1.x)
```

**Allowed By:**

- Frontend NSG: AllowSQLToDataSubnet (outbound)
- Data NSG: AllowSQLFromFrontendSubnet (inbound)

**Configuration:**

```bicep
// Frontend NSG Outbound Rule
{
  name: 'AllowSQLToDataSubnet'
  sourcePortRange: '*'
  destinationPortRange: '1433'
  destinationAddressPrefix: '10.50.1.0/26'  // Data Subnet
  direction: 'Outbound'
}

// Data NSG Inbound Rule
{
  name: 'AllowSQLFromFrontendSubnet'
  sourcePortRange: '*'
  destinationPortRange: '1433'
  sourceAddressPrefix: '10.50.0.0/24'  // Frontend Subnet
  direction: 'Inbound'
}
```

### 2. RDP Access (Remote Desktop)

**Flow:**

```
Admin IP → TCP:3389 → Web VM or SQL VM
```

**Requirements:**

- Provision `allowedRdpIps` parameter at deployment time
- Example: `allowedRdpIps = ['203.0.113.0/32', '198.51.100.0/24']`

**Allowed By:**

- Frontend NSG: AllowRDPFromAllowedIps (inbound)
- Data NSG: AllowRDPFromAllowedIps (inbound)

### 3. SSMS Access (SQL Server Management Studio)

**Flow:**

```
Admin Machine (VirtualNetwork) → TCP:1433 → SQL VM
```

**Allowed By:**

- Data NSG: AllowSQLFromVirtualNetwork (inbound)

**Configuration:**

```bicep
{
  name: 'AllowSQLFromVirtualNetwork'
  sourcePortRange: '*'
  destinationPortRange: '1433'
  sourceAddressPrefix: 'VirtualNetwork'  // Any subnet in the VNet
  direction: 'Inbound'
}
```

### 4. .NET Automation (Build/Deployment Tools)

**Supported Access Methods:**

#### A. Direct SQL Connection

```
Admin Tool → TCP:1433 → SQL VM
```

**Allowed By:**

- Data NSG: AllowSQLFromVirtualNetwork (inbound)

#### B. WinRM Remote Command Execution

```
Admin Tool → TCP:5985 or 5986 → Web VM or SQL VM
```

**Allowed By:**

- Frontend NSG: AllowWinRMHTTP/AllowWinRMHTTPS (inbound)
- Data NSG: AllowWinRMHTTP/AllowWinRMHTTPS (inbound)

**Configuration:**

```bicep
{
  name: 'AllowWinRMHTTP'
  sourcePortRange: '*'
  destinationPortRange: '5985'
  sourceAddressPrefix: 'VirtualNetwork'
  direction: 'Inbound'
}
{
  name: 'AllowWinRMHTTPS'
  sourcePortRange: '*'
  destinationPortRange: '5986'
  sourceAddressPrefix: 'VirtualNetwork'
  direction: 'Inbound'
}
```

## NAT Gateway Configuration

### Purpose

The NAT Gateway provides a single static public IP for outbound traffic from the subnets, enabling:

- Consistent outbound IP for firewall rules
- No exposure of internal VM IPs to external systems
- Secure outbound connectivity

### Configuration Details

**Core NAT Gateway:**

```bicep
resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: 'jobsite-dev-nat-[suffix]'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIpNat.id  // Static IP
      }
    ]
  }
}
```

**Public IP for NAT:**

```bicep
resource publicIpNat 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'jobsite-dev-pip-nat-[suffix]'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  // Static IP ensures consistent outbound IP
    idleTimeoutInMinutes: 4
  }
}
```

**Subnet Associations:**

```bicep
// Frontend Subnet
{
  name: 'snet-fe'
  properties: {
    addressPrefix: '10.50.0.0/24'
    natGateway: {
      id: natGateway.id  // Associated
    }
  }
}

// Data Subnet
{
  name: 'snet-data'
  properties: {
    addressPrefix: '10.50.1.0/26'
    natGateway: {
      id: natGateway.id  // Associated
    }
  }
}
```

### Outbound Flow

```
Web/SQL VM (Private IP)
    ↓
NAT Gateway (Translates private IPs to public IP)
    ↓
External Systems see traffic from: [Static Public IP]
```

## Deployment Parameters

When deploying the infrastructure, provide:

```bicep
param allowedRdpIps array = [
  '203.0.113.0/32',      // Your office IP
  '198.51.100.0/24'      // Your office subnet
]
```

## Security Best Practices Implemented

✅ **Least Privilege:** NSG rules only allow necessary ports  
✅ **Service Isolation:** Frontend and Data subnets are separate  
✅ **Web Access:** Public HTTP/HTTPS on port 80/443 only  
✅ **Admin Access:** RDP restricted to allowed IPs  
✅ **Database Security:** SQL port only exposed to Frontend subnet + VNet admins  
✅ **Remote Management:** WinRM for .NET automation over VNet  
✅ **Outbound Security:** NAT Gateway masks internal IPs with single static IP  
✅ **SSMS Support:** SQL Server Management Studio can connect via VNet access

## Troubleshooting

### Can't connect from Web VM to SQL VM?

- Check Frontend NSG has `AllowSQLToDataSubnet` outbound rule
- Check Data NSG has `AllowSQLFromFrontendSubnet` inbound rule
- Verify subnet CIDR blocks match rules (Frontend: 10.50.0.0/24, Data: 10.50.1.0/26)
- Ensure SQL service is running on SQL VM on port 1433

### Can't RDP to Web or SQL VM?

- Verify allowedRdpIps parameter is provided at deployment
- Check your public IP is in the allowed list
- Ensure NSG inbound RDP rule is not being overridden by a deny rule

### Can't access SQL via SSMS?

- SQL VM must be on VirtualNetwork or in Frontend subnet
- Verify Data NSG allows port 1433 from appropriate source
- Check SQL Server is configured for TCP/IP protocol
- Verify SQL Server Browser service is running (for named instances)

### Outbound traffic issues?

- Verify NAT Gateway is associated with the subnet
- Check NAT Gateway Public IP exists and is in Standard SKU
- Check subnet has no conflicting UDR (User Defined Routes)

## Files Location

- **IaaS Bicep Module:** [iac/bicep/iaas/iaas-resources.bicep](./iaas/iaas-resources.bicep)
- **Core Network Module:** [iac/bicep/core/core-resources.bicep](./core/core-resources.bicep)
- **Main IaaS Module:** [iac/bicep/iaas/main.bicep](./iaas/main.bicep)
- **Main Core Module:** [iac/bicep/core/main.bicep](./core/main.bicep)

## Related Documentation

- [IaaS README](./iaas/README.md)
- [Core README](./core/README.md)
- [Deployment Guide](../DEPLOYMENT_STATUS.md)
