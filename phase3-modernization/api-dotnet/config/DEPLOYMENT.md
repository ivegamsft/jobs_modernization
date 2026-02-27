# Azure Deployment Scripts

## Prerequisites

- Azure CLI installed
- Azure subscription with appropriate permissions
- Resource group already created

## Deployment Steps

### Development Environment

```bash
az deployment group create \
  --name jobsite-deployment \
  --resource-group rg-jobsite-dev \
  --template-file config/main.bicep \
  --parameters environment=dev location=eastus
```

### Staging Environment

```bash
az deployment group create \
  --name jobsite-deployment \
  --resource-group rg-jobsite-staging \
  --template-file config/main.bicep \
  --parameters environment=staging location=eastus \
  --parameters appServicePlanSkuName=S1
```

### Production Environment

```bash
az deployment group create \
  --name jobsite-deployment \
  --resource-group rg-jobsite-prod \
  --template-file config/main.bicep \
  --parameters environment=prod location=eastus \
  --parameters appServicePlanSkuName=P1V2
```

## Validate Template

```bash
az deployment group validate \
  --resource-group rg-jobsite-dev \
  --template-file config/main.bicep \
  --parameters environment=dev
```

## What Gets Created

- App Service Plan
- App Service (Web App)
- SQL Server & Database
- Application Insights & Log Analytics
- Key Vault
- Storage Account
- Networking & Firewall Rules
