# Migration Guide: appV2 (ASP.NET Core) to appV3 (Python Flask)

This document provides a comprehensive guide for migrating from the ASP.NET Core application (appV2) to the Python Flask application (appV3).

## Overview

| Component | appV2 (ASP.NET Core) | appV3 (Python Flask) |
|-----------|---------------------|---------------------|
| Framework | ASP.NET Core 8.0 | Flask 3.0 |
| Language | C# | Python 3.11+ |
| Database | SQL Server | PostgreSQL |
| ORM | Entity Framework Core | SQLAlchemy |
| Auth | ASP.NET Identity | Flask-Login + Bcrypt |
| Templates | Razor Views | Jinja2 |
| CSS | Bootstrap | Bootstrap 5 |

## Migration Steps

### 1. Database Migration

#### Schema Mapping

| SQL Server Table | PostgreSQL Table |
|-----------------|------------------|
| `JobsDb_Companies` | `companies` |
| `JobsDb_JobPostings` | `job_postings` |
| `JobsDb_Resumes` | `resumes` |
| `JobsDb_Countries` | `countries` |
| `JobsDb_States` | `states` |
| `JobsDb_EducationLevels` | `education_levels` |
| `JobsDb_ExperienceLevels` | `experience_levels` |
| `JobsDb_JobTypes` | `job_types` |
| `JobsDb_MyJobs` | `my_jobs` |
| `JobsDb_MyResumes` | `my_resumes` |
| `JobsDb_MySearches` | `my_searches` |
| `aspnet_Users` | `users` |

#### Data Type Mapping

| SQL Server | PostgreSQL |
|-----------|-----------|
| `VARCHAR` | `VARCHAR` |
| `TEXT` | `TEXT` |
| `INT` | `INTEGER` |
| `MONEY` | `NUMERIC(12,2)` |
| `DATETIME` | `TIMESTAMP` |
| `SMALLDATETIME` | `TIMESTAMP` |
| `BIT` | `BOOLEAN` |
| `CHAR(1)` | `BOOLEAN` |

#### Migration Script

```sql
-- Export from SQL Server
SELECT * INTO OUTFILE '/tmp/countries.csv' 
FROM JobsDb_Countries;

-- Import to PostgreSQL
COPY countries(id, country_name) FROM '/tmp/countries.csv' WITH CSV;
```

### 2. Code Migration

#### Entity Framework to SQLAlchemy

**C# (Entity Framework)**:
```csharp
public class Company
{
    public int Id { get; set; }
    public string CompanyName { get; set; }
    public virtual ICollection<JobPosting> JobPostings { get; set; }
}
```

**Python (SQLAlchemy)**:
```python
class Company(db.Model):
    __tablename__ = 'companies'
    
    id = db.Column(db.Integer, primary_key=True)
    company_name = db.Column(db.String(255), nullable=False)
    job_postings = db.relationship('JobPosting', backref='company', lazy='dynamic')
```

#### Controllers to Flask Routes

**C# (ASP.NET Controller)**:
```csharp
[HttpGet]
public async Task<IActionResult> Index()
{
    var jobs = await _context.JobPostings.ToListAsync();
    return View(jobs);
}
```

**Python (Flask Route)**:
```python
@app.route('/')
def index():
    jobs = JobPosting.query.all()
    return render_template('index.html', jobs=jobs)
```

### 3. Authentication Migration

The ASP.NET Identity system is replaced with Flask-Login and Flask-Bcrypt:

- User passwords are hashed using bcrypt
- Session management uses Flask's secure session handling
- Role-based access uses custom decorators (`@login_required`, `@employer_required`)

### 4. Configuration Migration

**appsettings.json → .env**:
```env
# ASP.NET (appsettings.json)
# "ConnectionStrings": { "DefaultConnection": "..." }

# Flask (.env)
DATABASE_URL=postgresql://user:pass@localhost:5432/jobsite_db
SECRET_KEY=your-secret-key
```

### 5. Template Migration

**Razor (.cshtml) → Jinja2 (.html)**:

| Razor Syntax | Jinja2 Syntax |
|-------------|--------------|
| `@Model.Title` | `{{ job.title }}` |
| `@if (condition) { }` | `{% if condition %}{% endif %}` |
| `@foreach (var item in list)` | `{% for item in list %}{% endfor %}` |
| `@Html.ActionLink()` | `{{ url_for('route') }}` |
| `@Html.Partial()` | `{% include 'partial.html' %}` |

## Running Both Applications

During migration, you can run both applications side by side:

```bash
# appV2 (ASP.NET Core on port 5001)
cd appV2
dotnet run --urls=http://localhost:5001

# appV3 (Flask on port 5000)
cd appV3
flask run --port=5000
```

## Testing the Migration

1. **Functional Testing**: Compare feature parity between both apps
2. **Data Validation**: Verify all data migrated correctly
3. **Performance Testing**: Compare response times
4. **Security Testing**: Verify authentication and authorization

## Rollback Plan

If issues arise, the original appV2 application remains available. Simply:

1. Stop the Flask application
2. Point DNS/load balancer back to the ASP.NET application
3. Investigate and fix issues in appV3

## Post-Migration Cleanup

After successful migration:

1. Archive the appV2 codebase
2. Update CI/CD pipelines for Python
3. Update monitoring and logging configurations
4. Train team on Python/Flask development
