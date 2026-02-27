# Environment Setup Guide

## Prerequisites

- .NET 8.0 SDK or later
- SQL Server 2022 or Azure SQL Database
- Docker & Docker Compose (optional, for containerized development)
- Visual Studio 2022, VS Code, or JetBrains Rider

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/jobsite.git
cd jobsite
```

### 2. Install Dependencies

```bash
dotnet restore
```

### 3. Database Setup

#### Option A: Using LocalDB

```bash
# Create migration
dotnet ef migrations add InitialCreate --project src/JobSite.Infrastructure

# Apply migration
dotnet ef database update --project src/JobSite.Infrastructure
```

#### Option B: Using Docker Compose

```bash
docker-compose up -d sqlserver

# Wait for SQL Server to start (30 seconds)
dotnet ef database update --project src/JobSite.Infrastructure --connection "Server=localhost,1433;Database=JobSiteDb;User Id=sa;Password=YourSecurePassword123!;"
```

### 4. Seed Database (Optional)

```bash
dotnet run --project src/JobSite.Api -- --seed-database
```

### 5. Run Application

#### Option A: Using dotnet CLI

```bash
dotnet run --project src/JobSite.Api
```

#### Option B: Using Docker Compose

```bash
docker-compose up
```

#### Option C: Using Visual Studio

1. Open `JobSite.sln`
2. Set `JobSite.Api` as startup project
3. Press F5

### 6. Access Application

- API: `http://localhost:5000`
- Swagger UI: `http://localhost:5000/swagger`
- Database: `localhost,1433` (SQL Server)

## Configuration

### Development Configuration

Create `appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=JobSiteDb;Trusted_Connection=true;"
  }
}
```

### User Secrets (for sensitive data)

```bash
# Initialize user secrets
dotnet user-secrets init --project src/JobSite.Api

# Add secrets
dotnet user-secrets set "Jwt:Secret" "your-secret-key" --project src/JobSite.Api
dotnet user-secrets set "SqlPassword" "your-password" --project src/JobSite.Api
```

## Running Tests

```bash
# Run all tests
dotnet test

# Run unit tests only
dotnet test tests/JobSite.Tests.Unit

# Run integration tests only
dotnet test tests/JobSite.Tests.Integration

# Run with code coverage
dotnet test /p:CollectCoverage=true /p:CoverageFormat=opencover
```

## Database Migrations

```bash
# Create new migration
dotnet ef migrations add MigrationName --project src/JobSite.Infrastructure

# Apply migrations
dotnet ef database update --project src/JobSite.Infrastructure

# Revert last migration
dotnet ef migrations remove --project src/JobSite.Infrastructure

# Generate migration script (SQL)
dotnet ef migrations script --project src/JobSite.Infrastructure -o migration.sql
```

## Building for Production

```bash
# Clean build
dotnet clean
dotnet build --configuration Release

# Publish
dotnet publish src/JobSite.Api -c Release -o ./publish

# Docker build
docker build -t jobsite-api:latest .
```

## Troubleshooting

### SQL Server Connection Issues

```bash
# Check SQL Server status
sqlcmd -L

# Test connection
dotnet ef database update --project src/JobSite.Infrastructure -v
```

### Port Already in Use

```bash
# Change port in launchSettings.json
# Or use:
dotnet run --project src/JobSite.Api -- --urls "http://localhost:5001"
```

### NuGet Package Restore Issues

```bash
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore packages
dotnet restore --no-cache
```

## IDE Setup

### Visual Studio Code

1. Install C# Dev Kit extension
2. Install REST Client extension (for testing APIs)
3. Press Ctrl+Shift+P → "Tasks: Run Build Task"

### Visual Studio 2022

1. Open `JobSite.sln`
2. Tools → NuGet Package Manager → Restore Packages
3. Build → Build Solution (Ctrl+Shift+B)

### JetBrains Rider

1. Open `JobSite.sln`
2. Right-click solution → Restore NuGet Packages
3. Build → Build Solution (Ctrl+Shift+B)

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/feature-name

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/feature-name

# Create pull request on GitHub
```
