# Phase 2: Azure Migration

## Goal
Host the legacy application on Azure App Service + Azure SQL with minimal code changes (lift-and-shift).

## Migration Strategy

This phase demonstrates a **PaaS migration** approach:
- Move legacy app to Azure App Service
- Migrate SQL Server database to Azure SQL
- Update connection strings for cloud hosting
- Apply minimal code changes (configuration only)

## Key Concepts

- **Lift-and-Shift:** Migrate without rewriting
- **PaaS Hosting:** Azure App Service for web tier
- **Azure SQL:** Managed database service
- **Configuration Management:** Connection strings, app settings

## Infrastructure

All Azure infrastructure is deployed via Bicep/Terraform templates:
- Resource groups (4-layer organization)
- Azure App Service + App Service Plan
- Azure SQL Server + Database
- Networking and security

➡️ [Infrastructure Documentation](../infrastructure/README.md)

## Deployment Guides

See `infrastructure/docs/` for detailed deployment documentation:
- Deployment checklists
- Resource group organization
- Credential management
- Troubleshooting guides

## Lessons Learned

**What Works:**
- PaaS reduces operational overhead
- Managed database simplifies administration
- Azure handles scaling and availability

**Challenges:**
- Connection string management
- Authentication changes for Azure SQL
- Cost optimization for legacy workloads

## Next Step

➡️ [Phase 3: Modernization](../phase3-modernization/README.md) — Build modern API + React UI
