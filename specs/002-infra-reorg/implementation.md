# Infrastructure Reorganization - Implementation

Follow phases; run from repo root unless noted. Use Azure CLI logged into correct sub.

## Pre-checks

- az account show (correct sub)
- az bicep version (0.26+)
- PowerShell available for scripts
- Confirm parameter files updated (core/iaas/paas/agents)

## Deploy

1. Core (validate outputs)

```pwsh
cd iac/bicep/core
az deployment group create --resource-group jobsite-core-dev-rg --template-file main.bicep --parameters @parameters.bicepparam
```

2. IaaS with App Gateway

```pwsh
cd ../iaas
az deployment group create --resource-group jobsite-iaas-dev-rg --template-file main.bicep --parameters @parameters.bicepparam
```

3. PaaS (CAE in paas RG)

```pwsh
cd ../paas
az deployment group create --resource-group jobsite-paas-dev-rg --template-file main.bicep --parameters @parameters.bicepparam
```

4. Agents (build VMSS)

```pwsh
cd ../agents
az deployment group create --resource-group jobsite-agents-dev-rg --template-file main.bicep --parameters @parameters.bicepparam
```

## Validation

- App Gateway: `az network application-gateway show -g jobsite-iaas-dev-rg -n jobsite-dev-agw --query properties.backendAddressPools`
- Backend health: `az network application-gateway show-backend-health -g jobsite-iaas-dev-rg -n jobsite-dev-agw`
- Build agents: `az vmss list-instances -g jobsite-agents-dev-rg -n vmss-build-agents`; from instance, curl github.com and web tier IP.
- CAE location: `az containerapp env show -g jobsite-paas-dev-rg -n <env>`
- Diagnostics: Query LAW for AppGatewayFirewallLog and VMSS metrics.

## Cleanup

- Remove old CAE/build VMSS from incorrect RGs after successful validation.
- Update RG tags if needed.

## Rollback (dev)

- If failure, delete newly created resources in paas/agents/iaas RGs and redeploy previous template versions from git history.
