# Inbound NAT Rules via Load Balancer

**✅ DEPLOYED**: Standard Load Balancer with Inbound NAT Rules V2

## Deployed Configuration

**Load Balancer Public IP**: **51.12.90.221**  
**Resource Group**: jobsite-iaas-dev-rg  
**NAT Rule**: rdp-nat-rule (Inbound NAT Rule V2)

### Port Mappings

Inbound NAT Rule V2 automatically assigns ports from the range:

- **Port Range**: 50001-50100
- **Backend Port**: 3389 (RDP)
- **Backend Pool**: 2 VMs

| VM Name                         | Private IP | Role         | Port Mapping   |
| ------------------------------- | ---------- | ------------ | -------------- |
| jobsite-dev-wfe-qahxan3ovcgdi   | 10.50.0.5  | Web Frontend | View in Portal |
| jobsite-dev-sqlvm-qahxan3ovcgdi | 10.50.1.5  | SQL Server   | View in Portal |

### Viewing Auto-Assigned Ports

**Azure Portal**:

1. Navigate to Load Balancer: `jobsite-dev-lb`
2. Go to: **Inbound NAT rules**
3. Click: **rdp-nat-rule**
4. Click: **View port mappings**

This shows which specific port (e.g., 50001, 50002) is mapped to each VM.

### Connecting via RDP

Once you know the port mapping from the portal:

```powershell
# Example (check portal for actual port):
mstsc /v:51.12.90.221:50001  # WFE
mstsc /v:51.12.90.221:50002  # SQL VM
```

## Architecture

**Outbound Traffic**: NAT Gateway (51.12.86.155) in core RG  
**Inbound RDP**: Load Balancer (51.12.90.221) in IaaS RG

- NAT Gateway handles VM → Internet
- Load Balancer handles Internet → VMs (RDP only)
- NSG allows RDP from 50.235.23.34/32

## Important Notes

- **Inbound NAT V1** retiring September 30, 2027
- **Inbound NAT V2** (current) automatically manages port mappings
- Port assignments persist for existing VMs
- New VMs added to backend pool get auto-assigned ports
- Maximum 100 VMs supported (50001-50100 range)

## Management

### List NAT Rules

```powershell
az network lb inbound-nat-rule list -g jobsite-iaas-dev-rg --lb-name jobsite-dev-lb -o table
```

### View Backend Pool

```powershell
az network lb address-pool show -g jobsite-iaas-dev-rg --lb-name jobsite-dev-lb -n BackendPool
```

## References

- [Azure Load Balancer Inbound NAT Rules](https://learn.microsoft.com/en-us/azure/load-balancer/inbound-nat-rules)
- [Manage Inbound NAT Rules](https://learn.microsoft.com/en-us/azure/load-balancer/manage-inbound-nat-rules)
- [View Port Mappings](https://learn.microsoft.com/en-us/azure/load-balancer/manage-inbound-nat-rules#view-port-mappings)
