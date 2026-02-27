# Troubleshooting & FAQ

## Common Issues

### Database Connection Issues

**Problem**: `Cannot open database requested by the login`

**Solution**:

```bash
# Verify connection string in appsettings.json
# Check SQL Server is running
sqlcmd -L

# Test connection with Entity Framework
dotnet ef database update --project src/JobSite.Infrastructure -v
```

### Port Already in Use

**Problem**: `Address already in use`

**Solution**:

```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>

# Or use different port
dotnet run --project src/JobSite.Api -- --urls "http://localhost:5001"
```

### Migration Failures

**Problem**: `An error occurred while accessing the Microsoft.EntityFrameworkCore assembly`

**Solution**:

```bash
# Remove pending migrations
dotnet ef migrations remove --project src/JobSite.Infrastructure

# Clear EF tools cache
dotnet tool update --global dotnet-ef

# Try again
dotnet ef migrations add InitialCreate --project src/JobSite.Infrastructure
```

### NuGet Package Issues

**Problem**: `Unable to find package`

**Solution**:

```bash
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore packages
dotnet restore --no-cache

# Update global tools
dotnet tool update --global dotnet-ef
```

### Docker Compose Issues

**Problem**: `Cannot connect to SQL Server container`

**Solution**:

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs sqlserver

# Restart services
docker-compose restart

# Or start fresh
docker-compose down -v
docker-compose up
```

## FAQ

### Q: How do I reset the database?

```bash
# Drop and recreate
dotnet ef database drop --project src/JobSite.Infrastructure --force
dotnet ef database update --project src/JobSite.Infrastructure
```

### Q: How do I seed the database with test data?

See [SEEDING.md](./SEEDING.md) for detailed instructions.

### Q: How do I run tests in CI/CD?

```bash
dotnet test --logger "trx" --collect:"XPlat Code Coverage"
```

### Q: How do I generate API documentation?

```bash
# OpenAPI/Swagger documentation is auto-generated
# Access at: http://localhost:5000/swagger
```

### Q: How do I create a new migration?

```bash
dotnet ef migrations add DescriptiveName --project src/JobSite.Infrastructure
```

### Q: How do I debug the application?

**Visual Studio**:

1. Set breakpoint
2. Press F5
3. Application starts in debug mode

**VS Code**:

1. Click Run and Debug (Ctrl+Shift+D)
2. Select ".NET 5+ and .NET Core" configuration
3. Press F5

### Q: How do I update NuGet packages?

```bash
# Check outdated packages
dotnet outdated

# Update all packages
dotnet add package --latest --all

# Or update specific package
dotnet add package PackageName --version VersionNumber
```

### Q: How do I format code?

```bash
# Run code formatter
dotnet format

# Or in Visual Studio:
# Edit → Advanced → Format Document (Ctrl+K, Ctrl+D)
```

### Q: How do I run static analysis?

```bash
# Code style analysis
dotnet format --verify-no-changes --verbosity diagnostic

# Security scan
dotnet list package --vulnerable

# Build-time analysis
dotnet build /p:EnforceCodeStyleInBuild=true
```

## Performance Issues

### Slow Startup

**Check**:

- Database migrations on startup
- Large model configurations
- Dependency injection container size

**Solution**:

```csharp
// In Program.cs, avoid migration on startup
// services.AddMigration(); // Remove this
```

### Slow Queries

**Check**:

- Missing indexes
- N+1 query problems
- Large result sets without pagination

**Solution**:

```csharp
// Use .Include() for related entities
var company = await _context.Companies
    .Include(c => c.JobPostings)
    .FirstOrDefaultAsync(c => c.Id == id);

// Use pagination
var results = await query
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();
```

## Security Issues

### SQL Injection Risk

**Always use parameterized queries**:

```csharp
// ❌ AVOID
var sql = $"SELECT * FROM Companies WHERE Name = '{name}'";
var result = context.Companies.FromSqlRaw(sql);

// ✅ CORRECT
var result = context.Companies
    .FromSqlInterpolated($"SELECT * FROM Companies WHERE Name = {name}")
    .ToList();
```

### Hardcoded Secrets

**Use User Secrets or Key Vault**:

```bash
# User Secrets (development)
dotnet user-secrets set "Jwt:Secret" "value"

# Key Vault (production)
# Store in Azure Key Vault, access via configuration
```

### Missing HTTPS

**Always enable HTTPS**:

```csharp
// In Program.cs
app.UseHttpsRedirection();
```
