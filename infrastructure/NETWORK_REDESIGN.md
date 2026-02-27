# Network Architecture Redesign - Production Ready

## Current Issues

- VNet too small (/24 = 256 IPs) split into 7 subnets
- Application Gateway subnet at minimum size (/27) - should be /24
- No room for growth or additional resources
- Tight IP allocation leaves no buffer for scaling

## Revised Architecture

### VNet Sizing

**Current**: `10.50.0.0/24` (256 IPs)  
**Revised**: `10.50.0.0/21` (2,048 IPs)

This provides 8x more IP addresses with room for future expansion.

### Subnet Allocation

| Subnet Name         | Current             | Revised                         | Usable IPs | Purpose                    | Justification                                                                      |
| ------------------- | ------------------- | ------------------------------- | ---------- | -------------------------- | ---------------------------------------------------------------------------------- |
| **snet-fe**         | 10.50.0.0/27 (32)   | **10.50.0.0/24** (256)          | 251        | Application Gateway v2     | Microsoft recommendation for v2 SKU. Supports up to 125 instances for autoscaling. |
| **snet-data**       | 10.50.0.64/27 (32)  | **10.50.1.0/26** (64)           | 59         | SQL VMs, Database tier     | Small growth (2-10 VMs). /26 provides adequate space.                              |
| **snet-gh-runners** | 10.50.0.128/27 (32) | **10.50.1.64/26** (64)          | 59         | GitHub Runners VMSS        | Build agents. Can scale to 50+ instances.                                          |
| **snet-pe**         | 10.50.0.96/27 (32)  | **10.50.1.128/27** (32)         | 27         | Private Endpoints          | Each PE = 1 IP. 27 PEs is sufficient.                                              |
| **GatewaySubnet**   | 10.50.0.32/27 (32)  | **10.50.1.160/27** (32)         | 27         | VPN Gateway                | Meets Azure recommendation (/27).                                                  |
| **snet-aks**        | 10.50.0.160/27 (32) | **10.50.2.0/23** (512)          | 507        | AKS cluster nodes          | Azure CNI Overlay recommended. Supports 250+ nodes.                                |
| **snet-ca**         | 10.50.0.192/27 (32) | **10.50.4.0/26** (64)           | 59         | Container Apps Environment | Workload profiles. 12 IPs infrastructure + 47 for scaling.                         |
| **(Reserved)**      | -                   | **10.50.4.64/26 - 10.50.7.255** | ~896       | Future expansion           | Buffer for new services, additional node pools, etc.                               |

### IP Address Summary

- **Total VNet**: 2,048 IPs
- **Allocated**: 1,152 IPs (56%)
- **Reserved for future**: 896 IPs (44%)

## Migration Strategy

### Option 1: In-Place Update (Non-Disruptive)

**CANNOT BE DONE** - Azure doesn't allow VNet or subnet resizing after deployment.

### Option 2: Blue-Green Deployment (Recommended)

1. Create new VNet with revised architecture
2. Deploy new Core infrastructure (Key Vault, ACR, Log Analytics can be reused)
3. Deploy IaaS and PaaS to new VNet
4. Migrate data (SQL, storage)
5. Update DNS and cut over traffic
6. Decommission old VNet after validation

**Estimated Downtime**: 15-30 minutes for DNS propagation

### Option 3: Fresh Start (Fastest)

1. Document current resource configurations
2. Tear down existing infrastructure
3. Deploy with new network architecture
4. Restore data from backups

**Estimated Downtime**: 2-4 hours

## Implementation Files

### 1. Core Resources Bicep Update

File: `iac/bicep/core/core-resources.bicep`

```bicep
var subnetConfig = {
  frontend: {
    name: 'snet-fe'
    prefix: '10.50.0.0/24'  // App Gateway - 251 usable IPs
  }
  data: {
    name: 'snet-data'
    prefix: '10.50.1.0/26'  // SQL VMs - 59 usable IPs
  }
  githubRunners: {
    name: 'snet-gh-runners'
    prefix: '10.50.1.64/26'  // Build agents - 59 usable IPs
  }
  privateEndpoint: {
    name: 'snet-pe'
    prefix: '10.50.1.128/27'  // Private Endpoints - 27 usable IPs
  }
  vpnGateway: {
    name: 'GatewaySubnet'
    prefix: '10.50.1.160/27'  // VPN Gateway - 27 usable IPs
  }
  aks: {
    name: 'snet-aks'
    prefix: '10.50.2.0/23'  // AKS nodes - 507 usable IPs
  }
  containerApps: {
    name: 'snet-ca'
    prefix: '10.50.4.0/26'  // Container Apps - 59 usable IPs
  }
}

// VNet address space
var vnetAddressPrefix = '10.50.0.0/21'  // 2,048 IPs
```

### 2. Core Main Bicep Update

File: `iac/bicep/core/main.bicep`

Update the default `vnetAddressPrefix` parameter:

```bicep
param vnetAddressPrefix string = '10.50.0.0/21'
```

## Benefits of Revised Architecture

1. **Application Gateway**: /24 allows autoscaling to 125 instances with room for maintenance
2. **AKS Ready**: /23 supports production-scale Kubernetes with Azure CNI Overlay
3. **Scalability**: 44% unused capacity for future growth
4. **Best Practices**: Aligns with Microsoft recommendations
5. **Operational Buffer**: Room for blue-green deployments and testing

## Cost Impact

**Network resources** (VNet, subnets, NAT Gateway): $0 - Same cost regardless of size
**Larger IP space**: No additional Azure charges
**Total Additional Cost**: **$0/month**

## Recommendation

✅ **Implement Option 2 (Blue-Green)** for production environments  
✅ **Implement Option 3 (Fresh Start)** for dev/test environments

Since this is a `dev` environment, **Option 3** is fastest and eliminates migration complexity.

## Next Steps

1. Backup current configurations and data
2. Update Bicep files with new subnet configuration
3. Deploy fresh infrastructure with revised network
4. Validate and test all services
5. Document IP assignments for future reference
