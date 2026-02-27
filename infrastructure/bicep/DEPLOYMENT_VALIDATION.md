# Bicep Deployment Validation Checklist

Use this checklist before and after deploying the legacy Job Site application to Azure.

## Pre-Deployment Checklist

### Prerequisites

- [ ] Azure subscription is active and has quota
- [ ] Azure CLI or Azure PowerShell is installed
- [ ] Logged into Azure account (`az login` or `Connect-AzAccount`)
- [ ] Have appropriate permissions (Contributor role or equivalent)
- [ ] Git is configured if using version control

### Configuration

- [ ] Updated `main.dev.bicepparam` with correct parameters
- [ ] Updated `main.staging.bicepparam` with correct parameters
- [ ] Updated `main.prod.bicepparam` with correct parameters
- [ ] **Changed SQL admin password** in all parameter files
- [ ] Verified application name is consistent and valid
- [ ] Verified location is available in subscription
- [ ] Updated alert email address
- [ ] Ensured no hardcoded secrets in templates

### Template Validation

- [ ] Ran `az deployment group validate` successfully
- [ ] No syntax errors in Bicep files
- [ ] All referenced resources exist or will be created
- [ ] Parameters are correctly mapped
- [ ] Outputs are defined for important resources
- [ ] Resource names follow naming conventions

### Infrastructure Planning

- [ ] Reviewed cost estimates for chosen SKUs
- [ ] Confirmed App Service Plan SKU is appropriate for workload
- [ ] Confirmed SQL Database edition matches performance needs
- [ ] Planned for backup retention requirements
- [ ] Reviewed network connectivity requirements
- [ ] Identified any existing infrastructure to integrate with

### Security Review

- [ ] SQL firewall rules reviewed and appropriate
- [ ] HTTPS is enforced in App Service config
- [ ] TLS version is 1.2 or higher
- [ ] Managed Identity is configured for secure access
- [ ] Key Vault access policies are restrictive
- [ ] No credentials are hardcoded in templates
- [ ] Storage account has blob public access disabled
- [ ] Debug mode is disabled in production config

---

## Deployment Checklist

### Pre-Deployment

- [ ] Resource group name is unique and appropriate
- [ ] Backed up any existing configurations or data
- [ ] Notified team members about deployment
- [ ] Scheduled deployment during maintenance window
- [ ] Created incident ticket for tracking

### Deployment Execution

- [ ] Reviewed deployment parameters one final time
- [ ] Executed deployment script with correct environment
- [ ] Monitored deployment progress in Azure Portal
- [ ] No errors or warnings during deployment
- [ ] Deployment completed successfully
- [ ] All resources visible in Resource Group

### Immediate Post-Deployment

- [ ] Verified all resources created successfully
- [ ] App Service shows "Running" status
- [ ] SQL Database is online
- [ ] Key Vault is accessible
- [ ] Application Insights is receiving data
- [ ] Log Analytics Workspace is created
- [ ] Storage Account is accessible

---

## Post-Deployment Validation

### Resource Verification

- [ ] App Service Plan created with correct SKU
- [ ] App Service created and running
- [ ] SQL Server created with correct version
- [ ] SQL Database created and online
- [ ] Key Vault created with correct region
- [ ] Application Insights provisioned
- [ ] Log Analytics Workspace provisioned
- [ ] Storage Account created with correct redundancy
- [ ] Managed Identity created
- [ ] All resources tagged correctly

### Connectivity Testing

- [ ] App Service URL is accessible

  ```powershell
  Invoke-WebRequest -Uri "https://jobsite-app-dev-xxxxx.azurewebsites.net" -UseBasicParsing
  ```

- [ ] SQL Server accepts connections from App Service

  ```bash
  az sql server firewall-rule list --resource-group <rg> --server <sql-server>
  ```

- [ ] Database is accessible

  ```bash
  sqlcmd -S <sql-server>.database.windows.net -U sqladmin -P <password> -d jobsitedb -Q "SELECT @@version"
  ```

- [ ] Key Vault can be accessed by App Service
  ```bash
  az keyvault secret list --vault-name <kv-name>
  ```

### Configuration Verification

- [ ] Connection string in Key Vault is correct
- [ ] App Service has HTTPS enforced
- [ ] Managed Identity is assigned to App Service
- [ ] Key Vault access policy includes App Service identity
- [ ] Application Insights instrumentation key is in Key Vault
- [ ] App Settings contain required configuration

### Security Verification

- [ ] TLS 1.2+ is enforced
- [ ] Debug mode is disabled
- [ ] Custom errors are enabled
- [ ] HTTP redirect to HTTPS is enabled
- [ ] Firewall rules are appropriate
- [ ] Database is encrypted
- [ ] Key Vault purge protection is configured
- [ ] Blob public access is disabled

### Monitoring Setup

- [ ] Application Insights is receiving telemetry
- [ ] Log Analytics shows App Service logs
- [ ] Diagnostic settings are configured
- [ ] Default metrics are being collected
- [ ] No errors in Application Insights

---

## Application Deployment

### Web.config Updates

- [ ] Updated connection string with SQL Server FQDN

  ```xml
  <add name="connectionstring"
       connectionString="Server=tcp:jobsite-sql-dev-xxxxx.database.windows.net,1433;
                         Initial Catalog=jobsitedb;..." />
  ```

- [ ] Updated Application Insights instrumentation key
- [ ] Set compilation debug="false"
- [ ] Set customErrors mode="RemoteOnly"
- [ ] Verified all appSettings values

### Application Package

- [ ] Built application in Release mode
- [ ] Packaged application as ZIP file
- [ ] Included web.config with correct settings
- [ ] Verified no local secrets in package
- [ ] Confirmed file size is reasonable

### Deployment

- [ ] Deployed application package to App Service

  ```bash
  az webapp deployment source config-zip --resource-group <rg> --name <app-name> --src app.zip
  ```

- [ ] Deployment completed successfully
- [ ] No deployment errors in logs
- [ ] Application is accessible at deployed URL
- [ ] Application loads without errors

### Application Testing

- [ ] Home page loads correctly
- [ ] Login page is accessible
- [ ] Database connectivity is working
- [ ] Application connects to SQL Database
- [ ] Data operations (read/write) function correctly
- [ ] User authentication works
- [ ] Authorization checks function properly
- [ ] No 500 errors in application logs
- [ ] Application Insights shows page loads

---

## Performance & Cost

### Performance Baseline

- [ ] Measured initial response time
- [ ] Verified no database connectivity issues
- [ ] Checked Application Insights for errors
- [ ] Confirmed acceptable performance under test load
- [ ] Memory usage is within limits
- [ ] CPU utilization is healthy

### Cost Monitoring

- [ ] Enabled cost tracking in Azure Portal
- [ ] Reviewed estimated monthly cost
- [ ] Cost is within budget
- [ ] Set up budget alerts
- [ ] Reviewed resource utilization
- [ ] Confirmed SKUs are appropriately sized

### Scaling Readiness

- [ ] Auto-scale rules are configured (if applicable)
- [ ] Tested scale-up scenarios
- [ ] Tested scale-down scenarios
- [ ] Confirmed database can handle increased load
- [ ] Verified connection pool settings

---

## Backup & Disaster Recovery

### Backup Configuration

- [ ] SQL Database backups are enabled
- [ ] Backup retention policy is set
- [ ] Automated backups are running
- [ ] Backup location is correct
- [ ] Tested restore from backup
- [ ] Documented recovery procedures

### Disaster Recovery

- [ ] Backup strategy is documented
- [ ] Recovery RTO (Recovery Time Objective) is defined
- [ ] Recovery RPO (Recovery Point Objective) is defined
- [ ] Tested failover procedures
- [ ] Documented failover steps
- [ ] Created runbook for disaster recovery

---

## Documentation

### Deployment Documentation

- [ ] Documented resource names and IDs
- [ ] Documented connection strings and endpoints
- [ ] Documented Key Vault secrets
- [ ] Documented firewall rules
- [ ] Created deployment summary
- [ ] Saved parameter files securely

### Operational Documentation

- [ ] Created monitoring guide
- [ ] Documented alert thresholds
- [ ] Created troubleshooting guide
- [ ] Documented scaling procedures
- [ ] Created backup procedures
- [ ] Created runbooks for common tasks

### Security Documentation

- [ ] Documented security groups
- [ ] Documented access control policies
- [ ] Documented encryption settings
- [ ] Documented compliance requirements
- [ ] Created security review checklist

---

## Sign-Off

### Testing Completion

- [ ] All tests passed successfully
- [ ] No critical issues remain
- [ ] Performance is acceptable
- [ ] Security review completed
- [ ] Cost is within budget

### Approval

- [ ] Development team approves
- [ ] Operations team approves
- [ ] Security team approves
- [ ] Business owner approves

### Go-Live

- [ ] Production deployment scheduled
- [ ] Team members notified
- [ ] Runbooks prepared
- [ ] Monitoring alerts configured
- [ ] Support team briefed

---

## Common Issues & Solutions

| Issue                   | Solution                                                          |
| ----------------------- | ----------------------------------------------------------------- |
| Deployment timeout      | Increase timeout in script or use `--no-wait` parameter           |
| SQL connection failed   | Check firewall rules, credentials, database status                |
| Key Vault access denied | Verify Managed Identity has access policy                         |
| High costs              | Review SKU sizes, consider auto-scaling down                      |
| App Service 500 errors  | Check Application Insights, review logs, verify connection string |
| Slow performance        | Check SQL Database DTU usage, review App Service Plan SKU         |
| Backup failed           | Check storage account permissions, verify backup settings         |

---

## Next Steps After Validation

1. **Monitor**: Set up continuous monitoring and alerts
2. **Optimize**: Review performance and optimize resource utilization
3. **Plan**: Create maintenance schedule for updates and patches
4. **Train**: Train operations team on deployment and support procedures
5. **Document**: Maintain updated documentation
6. **Iterate**: Collect feedback and improve infrastructure code

---

**Checklist Last Updated**: 2026-01-20  
**Template Version**: 1.0  
**Bicep Language Version**: 0.13+
