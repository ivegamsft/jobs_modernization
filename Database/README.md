# Database

## Overview
SQL Server database for the Jobs Modernization application. Contains job listings, application data, and related entities.

## Contents

### `JobsDB/`
SQL Server database project:
- Schema definitions
- Tables, views, stored procedures
- Database configuration

### `SEED_DATA_CONFLICT_ANALYSIS.md`
Analysis of seed data conflicts and resolution strategies.

## Schema

**Main Tables:**
- Jobs/Positions
- Applications
- Users/Candidates
- Companies
- Categories/Tags

*(For detailed schema, see database project files)*

## Usage Across Phases

### Phase 1 (Legacy)
- Direct SQL queries from Web Forms
- Connection strings hard-coded (appV1) or in web.config (appV1.5)

### Phase 2 (Azure Migration)
- Migrated to Azure SQL Database
- Managed service (backups, scaling, patching)
- Connection strings in Azure App Service configuration

### Phase 3 (Modernization)
- **api-dotnet:** Entity Framework Core with migrations
- **api-python:** SQLAlchemy ORM
- Code-first or database-first approaches

## Connection Strings

**Local Development:**
```
Server=localhost;Database=JobsDB;Integrated Security=true;
```

**Azure SQL:**
```
Server=tcp:{server}.database.windows.net;Database=JobsDB;User ID={user};Password={password};Encrypt=true;
```

See [Infrastructure Credentials](../infrastructure/docs/CREDENTIALS_AND_NEXT_STEPS.md) for Azure connection details.

## Migrations

**Phase 3 Modern APIs:**
- Entity Framework Core migrations in `api-dotnet/`
- Python Alembic migrations in `api-python/` (if applicable)

## Related Documentation

- [Infrastructure README](../infrastructure/README.md)
- [Phase 2 Migration](../phase2-azure-migration/README.md)
