# Quick Start: Legacy App Deployment

## Choose Your Deployment Option

### Option 1: Azure App Service (PaaS) - Recommended

- **Pros**: Managed, automatic patching, scaling, least maintenance
- **Cons**: Limited customization, higher cost for high compute
- **Best for**: Quick deployment, minimal ops overhead
- **See**: [DEPLOY_TO_AZURE_PAAS.md](./DEPLOY_TO_AZURE_PAAS.md)

### Option 2: Azure VM (IaaS)

- **Pros**: Full control, can install anything, can co-locate SQL Server
- **Cons**: You manage OS patching, more maintenance required
- **Best for**: Complex requirements, hybrid scenarios
- **See**: [DEPLOY_TO_AZURE_VM.md](./DEPLOY_TO_AZURE_VM.md)

### Option 3: On-Premises VM

- **Pros**: Complete control, no cloud costs for compute
- **Cons**: You manage everything, no cloud benefits
- **Best for**: Keeping within corporate infrastructure

## Fastest Deployment Path (PaaS)

### 5 Minutes: Create Resources

```powershell
# Login to Azure
az login

# Create resources
$rg = "rg-jobsite"
$appName = "jobsite-app"

# Create app service plan
az appservice plan create `
  --name "$appName-plan" `
  --resource-group $rg `
  --sku B1 `
  --is-linux $false

# Create app service
az webapp create `
  --name $appName `
  --resource-group $rg `
  --plan "$appName-plan" `
  --runtime "DOTNETFRAMEWORK|v4.8"

# Create SQL database
az sql db create `
  --resource-group $rg `
  --server jobsite-sql `
  --name JobSiteDb `
  --edition Basic
```

### 10 Minutes: Deploy Application

```powershell
# In Visual Studio:
# 1. Right-click project
# 2. Select "Publish"
# 3. Choose "Azure App Service"
# 4. Select your app service
# 5. Click "Publish"

# Or from command line:
dotnet publish -c Release -o publish
# Then upload publish folder via Azure Portal
```

### 5 Minutes: Configure Database

```powershell
# Update connection string in web.config
# Restore database from backup
# Test application
```

## Key Configuration Steps

### 1. Update web.config Connection String

```xml
<connectionStrings>
  <add name="connectionstring"
       connectionString="Server=tcp:jobsite-sql.database.windows.net,1433;Initial Catalog=JobSiteDb;User ID=sqladmin;Password=YourPassword;Encrypt=True;TrustServerCertificate=False;"
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### 2. Restore Database

```bash
# Export database from legacy server as BACPAC
# Then import to Azure SQL:
az sql db import `
  --resource-group rg-jobsite `
  --server jobsite-sql `
  --name JobSiteDb `
  --admin-user sqladmin `
  --admin-password "PASSWORD" `
  --file-path database.bacpac
```

### 3. Test Application

- Navigate to: `https://jobsite-app.azurewebsites.net`
- Test login functionality
- Check Application Insights logs

## Checklist

```
Deployment Option Selected: [ ] PaaS  [ ] VM  [ ] On-Premises

Resources Created:
  [ ] Resource Group
  [ ] App Service (or VM)
  [ ] SQL Database
  [ ] Network Security Group
  [ ] Storage Account (if needed)

Application Deployed:
  [ ] Web files copied
  [ ] web.config updated
  [ ] HTTPS enabled
  [ ] Custom domain configured (optional)

Database Restored:
  [ ] Database created
  [ ] Tables and data imported
  [ ] Connection string verified
  [ ] Login credentials updated

Testing Complete:
  [ ] Application loads
  [ ] Login works
  [ ] Database queries work
  [ ] Logging configured
  [ ] Monitoring enabled
```

## Troubleshooting Quick Links

| Issue                     | Solution                                              |
| ------------------------- | ----------------------------------------------------- |
| 500 Error                 | Check logs in App Service or Event Viewer             |
| Can't connect to database | Verify connection string, check firewall rules        |
| Login not working         | Verify authentication provider is configured          |
| Slow performance          | Scale up App Service SKU, check SQL performance       |
| Certificate error         | Ensure SSL certificate is valid, HTTPS binding exists |

## Support Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [ASP.NET Framework Migration Guide](https://docs.microsoft.com/en-us/dotnet/architecture/modernize-with-azure-containers/deploy-existing-net-apps)

## Next Steps After Deployment

1. **Monitoring**: Set up Application Insights alerts
2. **Backup**: Configure daily backups
3. **Scaling**: Test load and scale up if needed
4. **Security**: Enable Azure AD, configure WAF
5. **Migration**: Plan transition to modern architecture
