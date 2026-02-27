# Core Infrastructure Deployment

## Overview

The core infrastructure module deploys the foundational networking, security, and monitoring resources that support the VM-based JobSite deployment.

## Components

### 1. Virtual Network (VNet)

- **Address Space**: 10.50.0.0/21 (2,048 IPs)
- **Region**: Configurable (default: swedencentral)
- **Purpose**: Provides isolated network for all resources

### 2. Subnets

| Subnet            | CIDR Block       | Purpose               | NAT Gateway |
| ----------------- | ---------------- | --------------------- | ----------- |
| Frontend          | 10.50.0.0/24     | App Gateway / VMSS    | ✓           |
| Data              | 10.50.1.0/26     | SQL Server VM         | ✓           |
| GitHub Runners    | 10.50.1.64/26    | Self-hosted runners   | ✓           |
| Private Endpoints | 10.50.1.128/27   | PaaS private links    | ✓           |
| GatewaySubnet     | 10.50.1.160/27   | VPN Gateway           | ✗           |
| AKS               | 10.50.2.0/23     | AKS cluster nodes     | ✓           |
| Container Apps    | 10.50.4.0/26     | Container Apps Env    | ✓           |

### 3. NAT Gateway

- **Purpose**: Provides outbound Internet connectivity with static IP
- **Associated Subnets**: Frontend, Data, GitHub Runners, AKS, Container Apps
- **Public IP**: Static Standard SKU
- **Benefits**:
  - Consistent outbound IP for firewall rules
  - Reduced SNAT port exhaustion
  - No need for UDRs for common scenarios

### 4. VPN Gateway (Point-to-Site)

- **Type**: Route-based VPN
- **SKU**: VpnGw1
- **Authentication Methods**:
  - Certificate-based (uses provided root certificate)
  - Azure AD-based (built-in)
- **Client Address Pool**: 10.70.0.0/24 (configurable)
- **Protocols**: IKEv2, OpenVPN
- **Use Case**: Remote access for administrators and developers

### 5. Private DNS Zone

- **Zone Name**: `jobsite.internal`
- **Binding**: Automatically linked to VNet
- **Registration**: Enabled (Azure-managed records auto-register)
- **Use Cases**:
  - Internal service discovery
  - SQL Server hostname resolution
  - Internal application endpoints
  - Future: PaaS private link integration

### 6. Key Vault

- **SKU**: Standard
- **Access Model**: RBAC (Azure role-based access control)
- **Purposes**:
  - Store SQL Server credentials
  - Store VPN certificates
  - Store application secrets
  - Rotate credentials regularly

#### Pre-populated Secrets

- `sql-admin-username`: SQL Server admin account
- `sql-admin-password`: SQL Server admin password

**Note**: Additional secrets (certificates, connection strings, API keys) should be added post-deployment.

### 7. Log Analytics Workspace

- **Retention**: 30 days (configurable)
- **Pricing Tier**: PerGB2018 (pay-as-you-go)
- **Purpose**: Centralized monitoring and diagnostics
- **Integrated with**:
  - Application Gateway (logs & metrics)
  - VMSS (performance metrics)
  - SQL Server VM (if agent installed)
  - Network diagnostics

**Typical Usage**:

```kusto
// Query application gateway logs
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| summarize RequestCount=count() by tostring(httpStatus_s)
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Subscription                    │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐   │
│  │          VNet (10.50.0.0/21)                     │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  Frontend Subnet   (10.50.0.0/27)        │   │   │
│  │  │  ├─ VMSS Instance #1                     │   │   │
│  │  │  └─ (Future: VMSS Instance #2, #3...)   │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  Data Subnet       (10.50.0.32/27)       │   │   │
│  │  │  └─ SQL Server VM                        │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  Gateway Subnet    (10.50.0.64/27)       │   │   │
│  │  │  └─ VPN Gateway                          │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  Private Endpoint Subnet (10.50.0.96/27) │   │   │
│  │  │  └─ (Future: PaaS private endpoints)    │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  Additional Subnets (Runners, AKS, CA)  │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  App Gateway Subnet (10.50.224.0/27)    │   │   │
│  │  │  └─ WAF_v2 (deployed separately)        │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│  │                                                  │   │
│  │  NAT Gateway ──────┬──── Static Public IP       │   │
│  │                    │                             │   │
│  │                    └──── FE, Data, PE, Runners  │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                              │
│    ┌────────────────────┼────────────────────┐         │
│    ▼                    ▼                    ▼          │
│ ┌─────┐          ┌─────────────┐      ┌──────────┐    │
│ │ KV  │ ◄────── │ Secrets mgmt │     │ Cert mgmt│    │
│ └─────┘          └─────────────┘      └──────────┘    │
│    │                                                    │
│    ▼                                                    │
│ ┌────────────────────────────────────────────────┐    │
│ │   Private DNS Zone (jobsite.internal)         │    │
│ │   • Linked to VNet with auto-registration     │    │
│ │   • Internal service discovery                 │    │
│ └────────────────────────────────────────────────┘    │
│    │                                                    │
│    ▼                                                    │
│ ┌────────────────────────────────────────────────┐    │
│ │   Log Analytics Workspace                      │    │
│ │   • Monitoring & Diagnostics                   │    │
│ │   • 30-day retention                           │    │
│ └────────────────────────────────────────────────┘    │
│                                                        │
│  VPN Gateway ◄─────────────── Internet Clients       │
│  │                            (10.70.0.0/24)         │
│  │                                                    │
│  └─────────► Remote Access (IKEv2/OpenVPN)          │
└─────────────────────────────────────────────────────────┘
```

## Deployment Parameters

### Required Parameters

- `environment`: Environment name (dev, staging, prod)
- `applicationName`: Application identifier
- `sqlAdminUsername`: SQL Server admin account
- `sqlAdminPassword`: SQL Server admin password (secure)
- `vpnRootCertificate`: Base64-encoded VPN root certificate public key

### Optional Parameters

- `location`: Azure region (default: eastus)
- `vnetAddressPrefix`: VNet CIDR (default: 10.50.0.0/21)
- `vpnClientAddressPool`: VPN client pool (default: 10.70.0.0/24)
- `tags`: Custom resource tags

## Key Outputs

The deployment produces these outputs for use by VM module:

```bicep
vnetId                    // Full resource ID of VNet
vnetName                  // VNet name
frontendSubnetId          // Frontend subnet ID
dataSubnetId              // Data subnet ID
peSubnetId                // Private endpoint subnet ID
keyVaultId                // Key Vault resource ID
keyVaultName              // Key Vault name
privateDnsZoneId          // Private DNS zone ID
privateDnsZoneName        // Private DNS zone name
logAnalyticsWorkspaceId   // Log Analytics workspace ID
natGatewayPublicIp        // NAT Gateway public IP address
vpnGatewayPublicIp        // VPN Gateway public IP address
```

## Security Highlights

1. **Network Isolation**: Private VNet with no direct Internet access to compute
2. **Outbound NAT**: Static IP via NAT Gateway for consistent firewall rules
3. **VPN Access**: Multi-factor authentication options (certificates + AAD)
4. **RBAC Key Vault**: No access policies, roles assigned explicitly
5. **Private DNS**: Internal-only service discovery
6. **Monitoring**: All network activity logged to Log Analytics

## Cost Considerations

### Monthly Estimates (US East 1)

- VNet + Subnets: ~$0 (included in Azure)
- NAT Gateway: ~$32 + data processing
- VPN Gateway: ~$35 + processing
- Private DNS Zone: ~$0.90
- Key Vault: ~$0.60 (standard operations)
- Log Analytics: ~$0.99/GB ingested

**Total Estimate**: ~$70-100/month for core infrastructure

## Post-Deployment Configuration

### 1. Add Private DNS A Records

```bash
# Example: SQL Server record
az network private-dns record-set a add-record \
  --resource-group <rg> \
  --zone-name jobsite.internal \
  --record-set-name sql \
  --ipv4-address <SQL_VM_PRIVATE_IP>
```

### 2. Configure Key Vault Access

```bash
# Grant access to specific user/service principal
az keyvault set-policy \
  --name <keyvault-name> \
  --resource-group <rg> \
  --object-id <principal-id> \
  --secret-permissions get list
```

### 3. Test VPN Connectivity

- Download VPN client from VPN Gateway portal
- Install certificates (root + client)
- Connect and verify connection to jobsite.internal resources

### 4. Configure Log Analytics Alerts

- Set up alerts for VPN failures
- Monitor NAT Gateway port exhaustion
- Alert on failed authentication attempts

## Related Documentation

- [VM Module](../vm/README.md) - Depends on this core infrastructure
- [Deployment Guide](vm/DEPLOYMENT_GUIDE.md) - End-to-end deployment steps
- [Azure Network Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/network-segmentation-best-practices)

## Troubleshooting

### VPN Gateway Creation Fails

- Ensure `GatewaySubnet` exists with /27 or larger
- Verify no other gateways in same resource group
- Check quota limits for public IPs

### DNS Resolution Fails

- Verify subnet DNS settings (should be Azure-managed)
- Check private DNS zone VNet link status
- Test with `nslookup jobsite.internal` from VM

### NAT Gateway Issues

- Verify subnets are associated with NAT Gateway
- Check public IP allocation method (must be Static)
- Monitor SNAT port usage in Log Analytics

## Maintenance Schedule

### Monthly

- Review Log Analytics query performance
- Check DNS records for accuracy
- Validate VPN connectivity

### Quarterly

- Update Key Vault certificates/secrets
- Review VPN authentication logs
- Optimize NAT Gateway data processing costs

### Annually

- Renew VPN root certificate
- Review security group policies
- Disaster recovery testing
