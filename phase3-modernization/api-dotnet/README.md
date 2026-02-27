# Job Site Modernization

This folder contains the modernized version of the legacy Job Site Starter Kit, migrated from ASP.NET 2.0 Web Forms to ASP.NET Core with a clean architecture approach.

## Project Structure

### `/src` - Source Code

- **JobSite.Api** - ASP.NET Core REST API with controllers and middleware
- **JobSite.Core** - Domain models and data transfer objects (DTOs)
- **JobSite.Application** - Business logic, services, and interfaces
- **JobSite.Infrastructure** - Data access, Entity Framework, authentication, external services

### `/tests` - Test Projects

- **JobSite.Tests.Unit** - Unit tests for services and business logic
- **JobSite.Tests.Integration** - Integration tests for database and API

### `/docs` - Documentation

- **migration** - Migration guides and breaking changes documentation

### `/config` - Configuration

- Environment-specific configuration files
- Deployment settings

## Architecture Overview

```
Presentation Layer (API)
        ↓
Application Layer (Services & Interfaces)
        ↓
Domain Layer (Models & Entities)
        ↓
Infrastructure Layer (Data Access, Identity)
        ↓
Database
```

## Key Features of Modernization

- ✅ ASP.NET Core 8.0+
- ✅ Entity Framework Core for data access
- ✅ ASP.NET Core Identity for authentication/authorization
- ✅ Dependency Injection built-in
- ✅ RESTful API architecture
- ✅ Configuration management (appsettings.json)
- ✅ Async/await patterns
- ✅ Unit and integration testing
- ✅ Logging with Serilog or built-in ILogger
- ✅ Input validation with FluentValidation

## Migration Progress

- [ ] Database schema analysis and modernization
- [ ] Entity models creation
- [ ] DbContext setup with EF Core
- [ ] Repository pattern implementation
- [ ] Service layer implementation
- [ ] API controller creation
- [ ] Identity/Authentication migration
- [ ] Data migration from legacy database
- [ ] Unit tests
- [ ] Integration tests
- [ ] API documentation (Swagger/OpenAPI)
