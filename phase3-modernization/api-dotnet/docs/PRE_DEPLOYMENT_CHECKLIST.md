# Pre-Deployment Checklist

## Application Assessment

- [ ] Confirm .NET Framework version (target: 4.5+)
- [ ] Verify all dependencies are documented
- [ ] Check for deprecated APIs or controls
- [ ] Identify third-party components and licenses
- [ ] Test application in staging environment
- [ ] Review event log for warnings/errors
- [ ] Document database schema and stored procedures
- [ ] Back up current database and application files

## Infrastructure Requirements

- [ ] Azure subscription with sufficient quota
- [ ] Resource group naming convention decided
- [ ] Network topology designed (virtual network, subnets)
- [ ] Backup and disaster recovery plan
- [ ] Monitoring and alerting strategy
- [ ] SSL certificates (or plan to use Azure's managed certs)
- [ ] Custom domain name (if required)

## Database Preparation

- [ ] Database backup created (.bak or .bacpac file)
- [ ] Database file sizes documented
- [ ] Estimated recovery time defined
- [ ] Test restore procedure on staging
- [ ] Identify database logins to migrate
- [ ] Document stored procedures and functions
- [ ] Note any special database features (replication, CDC, etc.)

## Configuration Files

- [ ] web.config reviewed and updated templates created
- [ ] Connection strings documented
- [ ] Secrets extracted and moved to Azure Key Vault
- [ ] Email settings (SMTP) configured
- [ ] File paths reviewed (bin, data folders, etc.)
- [ ] IIS URL rewrite rules documented

## Security Review

- [ ] No credentials in source code
- [ ] No hardcoded secrets in web.config
- [ ] HTTPS endpoints configured
- [ ] Authentication method verified (Forms, Basic, etc.)
- [ ] Authorization checks documented
- [ ] SQL injection vulnerability assessment done
- [ ] XSS vulnerability assessment done
- [ ] CORS configuration planned
- [ ] Rate limiting strategy defined

## Testing Plan

### Functional Testing

- [ ] Home page loads
- [ ] Login/logout works
- [ ] User registration (if applicable)
- [ ] Core workflows tested
- [ ] Error pages display correctly
- [ ] Database connections work
- [ ] File uploads/downloads work

### Performance Testing

- [ ] Page load times acceptable
- [ ] Database query performance verified
- [ ] Memory usage monitored
- [ ] CPU usage monitored
- [ ] Concurrent user load tested

### Compatibility Testing

- [ ] Chrome latest version
- [ ] Firefox latest version
- [ ] Edge latest version
- [ ] Safari (if applicable)
- [ ] Mobile browsers (if applicable)

## Deployment Testing

### Staging Deployment

- [ ] Deploy to staging environment
- [ ] Run full functional test suite
- [ ] Load test staging
- [ ] Security scan staging
- [ ] Database restore tested
- [ ] Backup/recovery tested
- [ ] Rollback procedure tested

### Pre-Production Readiness

- [ ] Monitoring and alerts configured
- [ ] Logging enabled and tested
- [ ] Backup scheduled
- [ ] Documentation complete
- [ ] Support runbooks created
- [ ] Incident response plan ready
- [ ] Team trained on new environment

## Deployment Window

- [ ] Maintenance window scheduled
- [ ] Stakeholders notified
- [ ] User communication plan
- [ ] Rollback triggers defined
- [ ] Success criteria defined
- [ ] Validation steps documented
- [ ] Post-deployment checklist prepared

## Post-Deployment

- [ ] Monitor application for 24 hours
- [ ] Check error logs
- [ ] Verify performance metrics
- [ ] Validate data integrity
- [ ] Confirm backups running
- [ ] Document issues and solutions
- [ ] Plan next phase (modernization)

## Sign-Off

- [ ] Project Manager: ********\_******** Date: **\_\_\_**
- [ ] Technical Lead: ********\_******** Date: **\_\_\_**
- [ ] Security Officer: ********\_******** Date: **\_\_\_**
- [ ] DBA: ********\_******** Date: **\_\_\_**
- [ ] Operations: ********\_******** Date: **\_\_\_**
