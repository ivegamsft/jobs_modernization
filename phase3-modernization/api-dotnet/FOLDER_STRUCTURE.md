# Folder Structure Guide

## Detailed Structure

```
Modernized/
├── src/
│   ├── JobSite.Api/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   ├── Filters/
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   └── JobSite.Api.csproj
│   │
│   ├── JobSite.Core/
│   │   ├── Models/
│   │   │   ├── Company.cs
│   │   │   ├── JobPosting.cs
│   │   │   ├── JobSeeker.cs
│   │   │   ├── Resume.cs
│   │   │   ├── JobSearch.cs
│   │   │   └── ...
│   │   │
│   │   ├── DTOs/
│   │   │   ├── CreateCompanyDto.cs
│   │   │   ├── CreateJobPostingDto.cs
│   │   │   └── ...
│   │   │
│   │   ├── Enums/
│   │   └── JobSite.Core.csproj
│   │
│   ├── JobSite.Application/
│   │   ├── Interfaces/
│   │   │   ├── ICompanyService.cs
│   │   │   ├── IJobPostingService.cs
│   │   │   ├── IJobSeekerService.cs
│   │   │   ├── IAuthService.cs
│   │   │   └── ...
│   │   │
│   │   ├── Services/
│   │   │   ├── CompanyService.cs
│   │   │   ├── JobPostingService.cs
│   │   │   ├── JobSeekerService.cs
│   │   │   ├── AuthService.cs
│   │   │   └── ...
│   │   │
│   │   ├── Validators/
│   │   ├── Mappers/
│   │   └── JobSite.Application.csproj
│   │
│   └── JobSite.Infrastructure/
│       ├── Data/
│       │   ├── Context/
│       │   │   └── JobSiteDbContext.cs
│       │   │
│       │   ├── Repositories/
│       │   │   ├── IRepository.cs
│       │   │   ├── Repository.cs
│       │   │   ├── CompanyRepository.cs
│       │   │   ├── JobPostingRepository.cs
│       │   │   └── ...
│       │   │
│       │   └── Migrations/
│       │       ├── 202401200000_InitialCreate.cs
│       │       └── ...
│       │
│       ├── Identity/
│       │   ├── AppUser.cs
│       │   ├── AppRole.cs
│       │   └── IdentityService.cs
│       │
│       ├── Services/
│       │   └── (External services, email, storage, etc.)
│       │
│       └── JobSite.Infrastructure.csproj
│
├── tests/
│   ├── JobSite.Tests.Unit/
│   │   ├── Services/
│   │   ├── Validators/
│   │   └── JobSite.Tests.Unit.csproj
│   │
│   └── JobSite.Tests.Integration/
│       ├── Controllers/
│       ├── Repositories/
│       └── JobSite.Tests.Integration.csproj
│
├── docs/
│   ├── migration/
│   │   ├── MIGRATION_GUIDE.md
│   │   ├── DATABASE_SCHEMA.md
│   │   ├── API_ENDPOINTS.md
│   │   ├── BREAKING_CHANGES.md
│   │   └── DATA_MIGRATION_PLAN.md
│   │
│   └── ARCHITECTURE.md
│
├── config/
│   ├── docker-compose.yml
│   ├── appsettings.Production.json.template
│   └── deployment.yaml
│
├── .gitignore
├── README.md
├── FOLDER_STRUCTURE.md
├── MIGRATION_CHECKLIST.md
└── .sln (JobSite.sln)
```

## Layer Responsibilities

### JobSite.Api (Presentation Layer)

- HTTP request/response handling
- Controllers with action methods
- API routing and middleware
- Input validation and error handling
- Dependency injection setup
- Authentication/authorization filters

### JobSite.Core (Domain Layer)

- Domain entities (Company, JobPosting, Resume, etc.)
- Data Transfer Objects (DTOs)
- Enums and constants
- **No business logic** - just data structures

### JobSite.Application (Business Logic Layer)

- Service classes implementing interfaces
- Business logic and workflows
- Data validation using FluentValidation
- Mapping between DTOs and entities
- Orchestration of complex operations

### JobSite.Infrastructure (Data Access Layer)

- Entity Framework Core DbContext
- Repository pattern implementations
- Database migrations
- ASP.NET Core Identity setup
- External service integrations (email, file storage, etc.)

## Naming Conventions

| Item           | Convention     | Example             |
| -------------- | -------------- | ------------------- |
| Classes        | PascalCase     | `CompanyService`    |
| Interfaces     | IPascalCase    | `ICompanyService`   |
| Methods        | PascalCase     | `GetCompanyAsync()` |
| Properties     | PascalCase     | `CompanyName`       |
| Private fields | \_camelCase    | `_logger`           |
| Constants      | UPPER_CASE     | `MAX_FILE_SIZE`     |
| DTOs           | \*Dto suffix   | `CreateCompanyDto`  |
| Async methods  | \*Async suffix | `GetCompanyAsync()` |
