# Architecture Documentation

## Overview

The JobSite API follows a Clean Architecture pattern with separation of concerns across multiple layers. This design ensures testability, maintainability, and scalability.

## Architecture Layers

### 1. Presentation Layer (JobSite.Api)

**Responsibility**: Handle HTTP requests/responses and route them to appropriate services.

**Components**:

- Controllers: Handle API endpoints
- Middleware: Cross-cutting concerns (logging, error handling, authentication)
- Filters: Action-level validation and authorization
- Models: Response/request models

**Key Files**:

- `Controllers/CompaniesController.cs`
- `Middleware/ErrorHandlingMiddleware.cs`
- `appsettings.json`

### 2. Application Layer (JobSite.Application)

**Responsibility**: Implement business logic and orchestrate domain entities.

**Components**:

- Services: Business logic implementation
- Interfaces: Service contracts
- DTOs: Data Transfer Objects for API communication
- Validators: FluentValidation rules
- Mappers: AutoMapper profiles for DTO ↔ Entity conversion

**Key Files**:

- `Services/CompanyService.cs`
- `Interfaces/ICompanyService.cs`
- `Validators/CreateCompanyValidator.cs`

### 3. Domain Layer (JobSite.Core)

**Responsibility**: Define domain entities and business rules.

**Components**:

- Models: Entity definitions
- Enums: Domain enumerations
- Exceptions: Custom domain exceptions

**Key Files**:

- `Models/Company.cs`
- `Models/JobPosting.cs`
- `DTOs/CreateCompanyDto.cs`

### 4. Infrastructure Layer (JobSite.Infrastructure)

**Responsibility**: Handle persistence, external services, and system-level concerns.

**Components**:

- DbContext: Entity Framework Core context
- Repositories: Data access patterns
- Identity: ASP.NET Core Identity configuration
- Migrations: Database schema versions
- External Services: Email, file storage, etc.

**Key Files**:

- `Data/Context/JobSiteDbContext.cs`
- `Data/Repositories/CompanyRepository.cs`
- `Identity/AppUser.cs`

## Data Flow

```
HTTP Request
     ↓
Controllers (Presentation)
     ↓
Request Validation (Filters/Middleware)
     ↓
Services (Application)
     ↓
Repositories (Infrastructure)
     ↓
DbContext/Database (Infrastructure)
     ↓
Response Model
     ↓
HTTP Response
```

## Design Patterns

### Repository Pattern

- Abstracts data access logic
- Allows easy unit testing with mock repositories
- Enables switching data sources

**Example**:

```csharp
public interface IRepository<T>
{
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
}
```

### Service Layer Pattern

- Encapsulates business logic
- Validates business rules
- Coordinates multiple repositories

**Example**:

```csharp
public class CompanyService : ICompanyService
{
    private readonly IRepository<Company> _repository;

    public async Task<Company> CreateAsync(CreateCompanyDto dto)
    {
        // Validation
        // Business logic
        // Persistence
    }
}
```

### Dependency Injection

- Built-in to ASP.NET Core
- Constructor injection for loose coupling
- Configured in Program.cs

**Example**:

```csharp
services.AddScoped<ICompanyService, CompanyService>();
services.AddScoped<IRepository<Company>, CompanyRepository>();
```

## Database Schema

### Entity Relationships

```
Company (1) ──────→ (Many) JobPosting
    ↓
  UserId (Foreign Key to AspNetUsers)

AspNetUsers (1) ──────→ (Many) Resume
AspNetUsers (1) ──────→ (Many) JobSearch
```

### Entity Mappings

| Entity     | Table       | Key Features                      |
| ---------- | ----------- | --------------------------------- |
| Company    | Companies   | CompanyId (PK), UserId (FK)       |
| JobPosting | JobPostings | JobPostingId (PK), CompanyId (FK) |
| Resume     | Resumes     | ResumeId (PK), UserId (FK)        |
| AppUser    | AspNetUsers | Id (PK) - extends IdentityUser    |

## Security Architecture

### Authentication

- JWT (JSON Web Tokens) for API authentication
- ASP.NET Core Identity for user management
- Token refresh mechanism for long-lived sessions

### Authorization

- Role-based access control (RBAC)
- Policy-based authorization
- Claim-based authorization for fine-grained control

**Roles**:

- `Admin`: Full system access
- `Employer`: Can post jobs, view resumes
- `JobSeeker`: Can search jobs, post resumes

### Data Protection

- HTTPS/TLS for all communications
- Password hashing using ASP.NET Identity
- Secrets stored in Azure Key Vault
- SQL parameterization to prevent injection

## Deployment Architecture

### Development

- Local SQL Server (LocalDB)
- Docker Compose for orchestration
- IIS Express for testing

### Staging/Production

- Azure App Service for hosting
- Azure SQL Database for persistence
- Application Insights for monitoring
- Key Vault for secrets management
- CDN for static content distribution

```
Internet
   ↓
CDN (Static Content)
   ↓
Application Gateway (Load Balancing)
   ↓
App Service (Multiple Instances)
   ↓
Azure SQL Database (Replicated)
   ↓
Azure Storage (Blob Storage for Files)
   ↓
Application Insights (Monitoring/Logging)
```

## Error Handling Strategy

### API Error Responses

- Consistent error format (RFC 7231)
- Meaningful error messages
- Correlation IDs for tracking

### Logging

- Structured logging with Serilog
- Correlation IDs across request lifecycles
- Different log levels for different environments

### Monitoring

- Application Insights telemetry
- Custom metrics for business operations
- Health check endpoints

## Performance Considerations

### Caching

- Output caching for frequently accessed data
- Redis for distributed caching (future)
- Entity-level caching in EF Core

### Database Optimization

- Proper indexing on foreign keys
- Pagination for large result sets
- Lazy loading vs eager loading

### API Optimization

- Compression (gzip)
- Minimal JSON responses
- Async/await for non-blocking operations

## Testing Strategy

### Unit Testing

- Service logic testing with mocked repositories
- DTO validation testing
- Business rule testing

### Integration Testing

- API endpoint testing
- Database access testing
- End-to-end workflow testing

### Test Coverage Goals

- Services: >90%
- Controllers: >80%
- Overall: >80%
