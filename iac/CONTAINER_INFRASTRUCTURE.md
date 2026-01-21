# Azure Container Infrastructure - Quick Reference

## Resources Added to Core Infrastructure

### 1. Azure Container Registry (ACR)
- **SKU**: Premium (required for Private Link)
- **Network**: Private endpoint in `snet-pe` subnet
- **DNS**: Private DNS zone `privatelink.azurecr.io`
- **Access**: RBAC-based (admin user disabled)
- **Public Access**: Disabled (private only)

### 2. Container Apps Environment
- **Network**: Dedicated subnet `snet-ca` (10.50.0.192/27)
- **Configuration**: Internal (VNet-integrated)
- **Logging**: Integrated with Log Analytics workspace
- **Diagnostics**: Container & System logs enabled

---

## Network Architecture

```
VNet (10.50.0.0/24)
├── snet-pe (10.50.0.96/27)
│   └── ACR Private Endpoint
│       └── Private DNS: privatelink.azurecr.io
│
└── snet-ca (10.50.0.192/27)
    └── Container Apps Environment
        ├── Static IP assigned
        ├── Internal load balancer
        └── Default domain: *.{env}.{region}.azurecontainerapps.io
```

---

## Usage Examples

### Push Image to ACR
```bash
# Login to ACR (via private endpoint)
az acr login --name {acrName}

# Tag image
docker tag myapp:latest {acrLoginServer}/myapp:latest

# Push image
docker push {acrLoginServer}/myapp:latest
```

### Deploy Container App
```bash
# Create container app
az containerapp create \
  --name myapp \
  --resource-group jobsite-core-dev-rg \
  --environment {containerAppsEnvName} \
  --image {acrLoginServer}/myapp:latest \
  --registry-server {acrLoginServer} \
  --registry-identity system \
  --target-port 80 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 10
```

### Grant ACR Access
```bash
# Enable managed identity for Container App
az containerapp identity assign \
  --name myapp \
  --resource-group jobsite-core-dev-rg \
  --system-assigned

# Get principal ID
principalId=$(az containerapp show \
  --name myapp \
  --resource-group jobsite-core-dev-rg \
  --query identity.principalId -o tsv)

# Grant ACR pull access
az role assignment create \
  --assignee $principalId \
  --role AcrPull \
  --scope {acrId}
```

---

## Outputs Available

After deployment, these outputs are available:

```powershell
$deployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json
$outputs = $deployment.properties.outputs

# ACR Details
$outputs.acrName.value              # ACR name
$outputs.acrLoginServer.value       # Login server URL
$outputs.acrId.value                # ACR resource ID

# Container Apps Environment
$outputs.containerAppsEnvName.value        # Environment name
$outputs.containerAppsEnvDefaultDomain.value  # Default domain
$outputs.containerAppsEnvStaticIp.value    # Static IP address
$outputs.containerAppsEnvId.value          # Resource ID
$outputs.containerAppsSubnetId.value       # Subnet ID
```

---

## Security Features

### ACR
- ✅ Private endpoint only (no public access)
- ✅ Private DNS resolution
- ✅ RBAC authorization (no admin user)
- ✅ Premium SKU for enhanced security
- ✅ Azure Services bypass for platform integration

### Container Apps Environment
- ✅ VNet-integrated (internal mode)
- ✅ Dedicated subnet with NAT Gateway
- ✅ Log Analytics integration
- ✅ Container and system logs enabled
- ✅ Metrics collection enabled

---

## Next Steps

1. **Build Container Images**
   - Containerize your applications
   - Tag for ACR

2. **Push to ACR**
   - Use `az acr build` for automated builds
   - Or push from local Docker

3. **Deploy Container Apps**
   - Create apps in Container Apps Environment
   - Configure scaling, secrets, ingress

4. **Configure Networking**
   - Set up internal ingress
   - Configure custom domains (optional)
   - Link to Application Gateway if needed

5. **Monitor**
   - Check logs in Log Analytics
   - Set up alerts
   - Monitor performance metrics

---

## Integration Points

### With IAAS
- Application Gateway can route to Container Apps
- VMSS can call Container Apps via internal network

### With PaaS
- App Service can connect to Container Apps
- SQL Database accessible via private network

### With DevOps
- GitHub Actions can build and push to ACR
- Azure Pipelines can deploy to Container Apps
- Self-hosted runners can access ACR via private endpoint

---

## Cost Optimization

### ACR
- Premium tier: ~$0.83/day base + storage
- Consider Standard for dev/test environments

### Container Apps
- Consumption plan: Pay for what you use
- Dedicated plan: Fixed monthly cost
- Free grant: 180,000 vCPU-seconds + 360,000 GiB-seconds/month

---

Generated: 2026-01-21
Network: Private, VNet-integrated
Logging: Centralized via Log Analytics
