# Migration from Legacy to Modern Application

## Overview

This guide documents the process of migrating from the legacy ASP.NET 2.0 Web Forms application to the modern ASP.NET Core REST API.

## Data Migration Strategy

### Phase 1: User & Authentication Data

1. Migrate `aspnet_Users` to `AppUser` using ASP.NET Core Identity
2. Preserve existing password hashes
3. Migrate role assignments
4. Set up claim-based authorization

**SQL Script Template**:

```sql
INSERT INTO AspNetUsers (Id, UserName, Email, EmailConfirmed, ...)
SELECT UserId, UserName, LoweredEmail, 1, ...
FROM aspnet_Users
```

### Phase 2: Core Business Data

1. Migrate Companies
2. Migrate JobPostings
3. Migrate Resumes
4. Migrate reference data (Countries, States, etc.)

**Validation Checklist**:

- [ ] Record counts match
- [ ] Foreign keys are valid
- [ ] No orphaned records
- [ ] Data types converted correctly
- [ ] Date/time formats consistent

### Phase 3: Post-Migration Validation

1. Run data integrity checks
2. Verify relationships
3. Test data access patterns
4. Performance validation

## Legacy to Modern Mapping

### Authentication

| Legacy              | Modern      | Notes       |
| ------------------- | ----------- | ----------- |
| aspnet_Users        | AppUser     | Identity    |
| aspnet_Roles        | AppRole     | Identity    |
| FormsAuthentication | JWT Bearer  | Token-based |
| Profile provider    | User claims | Claim-based |

### Database

| Legacy             | Modern        | Notes       |
| ------------------ | ------------- | ----------- |
| Web Forms controls | API endpoints | REST        |
| ViewState          | DTOs          | Stateless   |
| Session            | JWT/Redis     | Distributed |
| .aspx pages        | Controllers   | MVC pattern |

### Data Access

| Legacy            | Modern                | Notes          |
| ----------------- | --------------------- | -------------- |
| Custom DAL        | Entity Framework Core | ORM            |
| Stored procedures | LINQ queries          | Entity mapping |
| DataSet           | Models/DTOs           | Strongly typed |
| SqlCommand        | DbContext             | Type-safe      |

## Running Parallel Systems

### Phase 1: Deploy Modern API (Read-only)

- Deploy API without user-facing features
- Point to production database (read-only)
- Test data access patterns
- Monitor for issues

### Phase 2: Shadow Deployment

- Deploy API alongside legacy application
- Mirror some write operations to both systems
- Validate data consistency
- Train support teams

### Phase 3: Cutover

- Stop writes to legacy system
- Run final data sync
- Switch users to new API
- Monitor closely

### Phase 4: Legacy System Retirement

- Keep legacy system in read-only mode for 30 days
- Archive database
- Decommission infrastructure
- Document lessons learned

## Data Validation Scripts

### Check Record Counts

```sql
-- Legacy system
SELECT 'Companies' as TableName, COUNT(*) as LegacyCount FROM Companies
UNION ALL
SELECT 'JobPostings', COUNT(*) FROM JobPostings
UNION ALL
SELECT 'Resumes', COUNT(*) FROM Resumes

-- Modern system
SELECT 'Companies' as TableName, COUNT(*) as ModernCount FROM Companies
UNION ALL
SELECT 'JobPostings', COUNT(*) FROM JobPostings
UNION ALL
SELECT 'Resumes', COUNT(*) FROM Resumes
```

### Check Referential Integrity

```sql
-- Find orphaned companies
SELECT DISTINCT c.CompanyId
FROM Companies c
LEFT JOIN AspNetUsers u ON c.UserId = u.Id
WHERE u.Id IS NULL

-- Find orphaned job postings
SELECT DISTINCT jp.CompanyId
FROM JobPostings jp
LEFT JOIN Companies c ON jp.CompanyId = c.Id
WHERE c.Id IS NULL
```

## API Compatibility Layer (Optional)

For gradual migration, consider a compatibility layer:

```csharp
[Route("api/v1/legacy")]
[ApiController]
public class LegacyCompatibilityController : ControllerBase
{
    // Endpoints that mimic legacy ASP.NET behavior
    // Provides transition time for dependent systems
}
```

## Communication Plan

### Week 1-2

- Announce migration plan
- Discuss timeline with stakeholders
- Begin testing

### Week 3-4

- Deploy to staging
- Run performance tests
- Train internal teams

### Week 5

- Schedule cutover window
- Notify users
- Execute migration
- Validate
- Monitor

## Rollback Plan

If migration fails:

1. Stop new API
2. Switch traffic back to legacy system
3. Investigate root cause
4. Fix issues
5. Re-test
6. Schedule new cutover attempt

**Time to Rollback**: < 15 minutes

## Success Metrics

- [ ] All data migrated successfully
- [ ] Zero data loss
- [ ] <1% API error rate
- [ ] Response time < 200ms (p95)
- [ ] Zero critical security issues
- [ ] 100% test coverage for critical paths
- [ ] Documentation complete
- [ ] Support trained

## Post-Migration

### Day 1-7

- Monitor error logs
- Check performance metrics
- Gather user feedback
- Fix critical issues

### Week 2-4

- Optimize performance bottlenecks
- Address user feedback
- Plan legacy system retirement

### Month 2+

- Full system monitoring
- Plan deprecation timeline
- Document migration process
- Share lessons learned
