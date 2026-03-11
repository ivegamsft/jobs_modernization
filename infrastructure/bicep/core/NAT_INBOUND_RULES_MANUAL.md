# NAT Gateway Inbound Rules - Manual Configuration

## Issue

Bicep does not yet have full support for creating inbound NAT rules on a NAT Gateway. The API requires special handling for the frontend IP configuration reference.

## Solution

Inbound NAT rules need to be created via Azure CLI with the correct API structure.

### Create Inbound NAT Rules

```bash
# Web VM inbound rule (13389 -> 3389)
az rest --method PUT \
  --uri "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<CORE_RESOURCE_GROUP>/providers/Microsoft.Network/natGateways/<NAT_GATEWAY_NAME>/inboundNatRules/rdp-wfe?api-version=2023-11-01" \
  --body @- << EOF
{
  "properties": {
    "protocol": "Tcp",
    "frontendPort": 13389,
    "backendPort": 3389,
    "idleTimeoutInMinutes": 4,
    "frontendIpConfiguration": {
      "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<CORE_RESOURCE_GROUP>/providers/Microsoft.Network/natGateways/<NAT_GATEWAY_NAME>/frontendIpConfigurations/default"
    }
  }
}
EOF

# SQL VM inbound rule (23389 -> 3389)
az rest --method PUT \
  --uri "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<CORE_RESOURCE_GROUP>/providers/Microsoft.Network/natGateways/<NAT_GATEWAY_NAME>/inboundNatRules/rdp-sqlvm?api-version=2023-11-01" \
  --body @- << EOF
{
  "properties": {
    "protocol": "Tcp",
    "frontendPort": 23389,
    "backendPort": 3389,
    "idleTimeoutInMinutes": 4,
    "frontendIpConfiguration": {
      "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<CORE_RESOURCE_GROUP>/providers/Microsoft.Network/natGateways/<NAT_GATEWAY_NAME>/frontendIpConfigurations/default"
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

- **Web VM RDP**: `<NAT_PUBLIC_IP>:13389` → `<WEB_VM_PRIVATE_IP>:3389`
- **SQL VM RDP**: `<NAT_PUBLIC_IP>:23389` → `<SQL_VM_PRIVATE_IP>:3389`

### Direct (from same VNet)

- **Web VM RDP**: `<WEB_VM_PRIVATE_IP>:3389`
- **SQL VM RDP**: `<SQL_VM_PRIVATE_IP>:3389`

## Bicep Limitations

The `Microsoft.Network/natGateways/inboundNatRules@2023-11-01` resource type in Bicep currently has type validation issues. Until Microsoft provides full type definitions, these resources should be created via Azure CLI REST commands.
