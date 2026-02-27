# NAT Gateway Inbound Rules - Manual Configuration

## Issue

Bicep does not yet have full support for creating inbound NAT rules on a NAT Gateway. The API requires special handling for the frontend IP configuration reference.

## Solution

Inbound NAT rules need to be created via Azure CLI with the correct API structure.

### Create Inbound NAT Rules

```bash
# Web VM inbound rule (13389 -> 3389)
az rest --method PUT \
  --uri "/subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/natGateways/jobsite-dev-nat-ubzfsgu4p5eli/inboundNatRules/rdp-wfe?api-version=2023-11-01" \
  --body @- << EOF
{
  "properties": {
    "protocol": "Tcp",
    "frontendPort": 13389,
    "backendPort": 3389,
    "idleTimeoutInMinutes": 4,
    "frontendIpConfiguration": {
      "id": "/subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/natGateways/jobsite-dev-nat-ubzfsgu4p5eli/frontendIpConfigurations/default"
    }
  }
}
EOF

# SQL VM inbound rule (23389 -> 3389)
az rest --method PUT \
  --uri "/subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/natGateways/jobsite-dev-nat-ubzfsgu4p5eli/inboundNatRules/rdp-sqlvm?api-version=2023-11-01" \
  --body @- << EOF
{
  "properties": {
    "protocol": "Tcp",
    "frontendPort": 23389,
    "backendPort": 3389,
    "idleTimeoutInMinutes": 4,
    "frontendIpConfiguration": {
      "id": "/subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/jobsite-core-dev-rg/providers/Microsoft.Network/natGateways/jobsite-dev-nat-ubzfsgu4p5eli/frontendIpConfigurations/default"
    }
  }
}
EOF
```

## Current State

- ✅ Core infrastructure deployed with NAT Gateway
- ✅ IaaS VMs deployed in separate RG (jobsite-iaas-dev-rg)
- ✅ NSGs configured with RDP rules
- ⏳ Inbound NAT rules need manual creation

## Connection Details

### Via NAT Gateway (from external networks)

- **Web VM RDP**: `51.12.86.155:13389` → `10.50.0.5:3389`
- **SQL VM RDP**: `51.12.86.155:23389` → `10.50.1.5:3389`

### Direct (from same VNet)

- **Web VM RDP**: `10.50.0.5:3389`
- **SQL VM RDP**: `10.50.1.5:3389`

## Bicep Limitations

The `Microsoft.Network/natGateways/inboundNatRules@2023-11-01` resource type in Bicep currently has type validation issues. Until Microsoft provides full type definitions, these resources should be created via Azure CLI REST commands.
