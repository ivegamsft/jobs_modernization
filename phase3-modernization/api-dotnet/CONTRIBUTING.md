# Contributing Guide

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on code quality and team success

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Set up local environment: See [ENVIRONMENT_SETUP.md](./docs/ENVIRONMENT_SETUP.md)

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/add-job-search
```

### 2. Commit Changes

```bash
git add .
git commit -m "feat: add advanced job search filters"
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, test, chore
**Scope**: api, core, infrastructure, database, auth
**Subject**: imperative, lowercase, no period

**Example**:

```
feat(api): add job posting search endpoint

- Implement full-text search
- Add pagination support
- Add sorting by salary and date

Closes #123
```

### 3. Code Style

- Use C# naming conventions
- Run code formatter: `dotnet format`
- Follow [Microsoft C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Keep methods small and focused

### 4. Testing

```bash
# Write unit tests for new logic
# Write integration tests for API endpoints

dotnet test
```

**Test Naming Convention**: `MethodName_Condition_ExpectedResult`

Example:

```csharp
[Fact]
public async Task GetCompanyById_WithValidId_ReturnsCompany()
{
    // Arrange
    var companyId = 1;

    // Act
    var result = await _service.GetCompanyByIdAsync(companyId);

    // Assert
    Assert.NotNull(result);
    Assert.Equal(companyId, result.Id);
}
```

### 5. Documentation

- Add XML comments to public methods
- Update relevant .md files
- Keep API documentation in sync

```csharp
/// <summary>
/// Retrieves a company by its identifier.
/// </summary>
/// <param name="id">The company ID</param>
/// <param name="cancellationToken">Cancellation token</param>
/// <returns>Company if found; null otherwise</returns>
public async Task<Company?> GetCompanyByIdAsync(int id, CancellationToken cancellationToken = default)
{
    // Implementation
}
```

### 6. Pull Request Process

1. **Create PR**: Push your branch and create a pull request
2. **Description**: Include:
   - What does this PR do?
   - Why is it needed?
   - Related issues (#123)
   - Testing instructions
3. **Review**: Address reviewer feedback
4. **CI/CD**: Ensure all checks pass
5. **Merge**: Use "Squash and merge" for cleaner history

**PR Template**:

```markdown
## Description

Brief description of changes

## Related Issue

Closes #123

## Testing

How to test this change

## Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code formatted
- [ ] No breaking changes
```

### 7. Code Review Guidelines

**As an Author**:

- Keep PRs focused and reasonably sized (<400 lines)
- Provide context for reviewers
- Respond promptly to feedback
- Request re-review after changes

**As a Reviewer**:

- Check for correctness, clarity, and consistency
- Look for security issues
- Verify tests cover the changes
- Be respectful and constructive

## Project Structure Rules

- Follow the Clean Architecture layers
- DTOs should be in `Core/DTOs`
- Services should be in `Application/Services`
- Repositories should be in `Infrastructure/Data/Repositories`
- Database models in `Infrastructure/Data/Context`

## Common Tasks

### Adding a New Feature

1. Create domain model in `Core/Models/`
2. Create DTO in `Core/DTOs/`
3. Create repository interface in `Application/Interfaces/`
4. Create repository implementation in `Infrastructure/Data/Repositories/`
5. Create service interface in `Application/Interfaces/`
6. Create service implementation in `Application/Services/`
7. Create validator in `Application/Validators/`
8. Create controller in `Api/Controllers/`
9. Add unit tests in `Tests.Unit/`
10. Add integration tests in `Tests.Integration/`

### Adding a Database Migration

```bash
# Create model changes first
# Then create migration
dotnet ef migrations add FeatureDescription --project src/JobSite.Infrastructure

# Review generated migration file
# Apply migration
dotnet ef database update --project src/JobSite.Infrastructure
```

## Performance & Best Practices

- Use `async/await` for I/O operations
- Use `LINQ` efficiently (avoid N+1 queries)
- Cache frequently accessed data
- Validate input early
- Log important operations
- Handle exceptions appropriately

## Security Checklist

- [ ] No hardcoded secrets
- [ ] Input validation on all endpoints
- [ ] Use parameterized queries
- [ ] Implement proper authentication/authorization
- [ ] HTTPS enforced
- [ ] SQL injection prevention
- [ ] XSS prevention (where applicable)
- [ ] CSRF protection (where applicable)

## Useful Commands

```bash
# Build
dotnet build

# Run tests
dotnet test

# Run specific test
dotnet test --filter "TestMethodName"

# Code coverage
dotnet test /p:CollectCoverage=true

# Format code
dotnet format

# Create migration
dotnet ef migrations add MigrationName --project src/JobSite.Infrastructure

# Apply migration
dotnet ef database update --project src/JobSite.Infrastructure

# Remove last migration
dotnet ef migrations remove --project src/JobSite.Infrastructure

# Generate migration script
dotnet ef migrations script --project src/JobSite.Infrastructure -o script.sql
```

## Getting Help

- Check [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)
- Review existing issues and PRs
- Ask in project discussions
- Check Microsoft documentation

## Code of Merit

- Focus on code quality
- Respect team decisions
- Share knowledge
- Help others succeed
- Report security issues privately
