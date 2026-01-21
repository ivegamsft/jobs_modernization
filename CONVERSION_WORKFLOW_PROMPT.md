# Automated App Conversion Workflow Prompt

## Master Prompt for Full-Stack Application Conversion

Use this prompt with an AI coding assistant (GitHub Copilot, Claude, etc.) to automatically convert an ASP.NET Core application to a new technology stack.

---

## 🚀 THE PROMPT

```
You are an expert full-stack developer tasked with converting an existing application to a new technology stack. Execute this conversion workflow completely and autonomously.

## INPUT PARAMETERS
- SOURCE_APP_PATH: {path_to_source_application}
- TARGET_APP_NAME: {name_for_new_application}
- TARGET_FRONTEND: {react|vue|angular|flask-jinja2}
- TARGET_BACKEND: {dotnet|python-flask|python-fastapi|nodejs-express}
- TARGET_DATABASE: {sqlserver|postgresql|mysql|sqlite}
- DEPLOYMENT_TARGET: {docker|azure|aws|local}

## EXECUTION WORKFLOW

### PHASE 1: ANALYSIS (Automatic)
1. Scan the SOURCE_APP_PATH directory structure
2. Identify all:
   - Models/Entities (data structures)
   - Controllers/Routes (API endpoints)
   - Views/Templates (UI components)
   - Database schema (tables, relationships)
   - Authentication mechanisms
   - Configuration files
   - Business logic patterns
3. Generate a dependency map
4. Create a conversion plan document

### PHASE 2: PROJECT SCAFFOLDING (Automatic)
1. Create new project directory: TARGET_APP_NAME
2. Initialize project structure based on TARGET_BACKEND:
   - If python-flask: Create Flask app factory pattern with blueprints
   - If python-fastapi: Create FastAPI with routers
   - If nodejs-express: Create Express.js with MVC pattern
   - If dotnet: Create ASP.NET Core Web API
3. Setup package management (requirements.txt, package.json, etc.)
4. Create configuration files (.env, config.py, etc.)
5. Setup database connection based on TARGET_DATABASE

### PHASE 3: DATA LAYER CONVERSION (Automatic)
1. For each entity/model found in source:
   - Create equivalent model in target framework
   - Map data types appropriately
   - Preserve relationships (foreign keys, many-to-many)
   - Add validation decorators/attributes
2. Create database migration scripts
3. Create seed data scripts
4. Generate ORM configurations

### PHASE 4: BUSINESS LOGIC CONVERSION (Automatic)
1. For each controller/service in source:
   - Create equivalent route/endpoint
   - Convert business logic to target language
   - Preserve HTTP methods (GET, POST, PUT, DELETE)
   - Maintain URL patterns where possible
   - Add proper error handling
2. Create service layer abstractions
3. Implement dependency injection patterns

### PHASE 5: AUTHENTICATION CONVERSION (Automatic)
1. Analyze source authentication mechanism
2. Implement equivalent in target:
   - If Flask: Flask-Login + Flask-Bcrypt
   - If FastAPI: OAuth2 + JWT
   - If Express: Passport.js
3. Create login/register/logout routes
4. Implement protected route decorators
5. Setup session/token management

### PHASE 6: FRONTEND CONVERSION (Automatic)
Based on TARGET_FRONTEND:

If react:
- Create Vite + React + TypeScript project
- Convert views to React components
- Setup React Router
- Create API service layer with Axios
- Implement state management (Context/Redux)
- Add form handling with React Hook Form
- Style with TailwindCSS

If flask-jinja2:
- Create Jinja2 templates
- Convert views to templates
- Setup template inheritance (base.html)
- Create static files (CSS, JS)
- Add WTForms for form handling
- Style with Bootstrap 5

If vue:
- Create Vite + Vue 3 + TypeScript project
- Convert views to Vue components
- Setup Vue Router
- Create Pinia stores
- Implement Composition API patterns

### PHASE 7: DOCKER CONFIGURATION (Automatic)
1. Create Dockerfile for backend
2. Create Dockerfile for frontend (if separate)
3. Create docker-compose.yml with:
   - Backend service
   - Frontend service (if applicable)
   - Database service (TARGET_DATABASE)
   - Volume mounts
   - Network configuration
   - Health checks
4. Create .dockerignore files

### PHASE 8: TESTING SETUP (Automatic)
1. Create test directory structure
2. Setup testing framework:
   - Python: pytest + pytest-flask
   - Node: Jest + Supertest
   - React: Vitest + React Testing Library
3. Create sample tests for:
   - Model validation
   - Route handlers
   - Authentication flow
   - API integration

### PHASE 9: DOCUMENTATION (Automatic)
1. Generate README.md with:
   - Project overview
   - Setup instructions
   - Running locally
   - Docker commands
   - API documentation
2. Create MIGRATION_GUIDE.md
3. Add inline code comments

### PHASE 10: VALIDATION (Automatic)
1. Verify all files are created
2. Check for syntax errors
3. Validate Docker builds
4. Run test suite
5. Generate conversion report

## OUTPUT DELIVERABLES
1. Complete working application in TARGET_APP_NAME/
2. Docker configuration files
3. Database migration scripts
4. Test suite
5. Documentation
6. Conversion report with any manual steps needed

## EXECUTION RULES
- Do NOT ask for confirmation between phases
- Do NOT stop for user input unless critical error
- Create ALL files automatically
- Use best practices for target framework
- Preserve all business logic functionality
- Maintain API compatibility where possible
- Add comprehensive error handling
- Include logging throughout
- Follow security best practices

## ERROR HANDLING
- If a file cannot be parsed: Log warning, continue with best effort
- If a pattern is unknown: Use most common equivalent
- If dependency is missing: Add to requirements
- If conversion is ambiguous: Choose most maintainable option

BEGIN EXECUTION NOW.
```

---

## 📋 QUICK-USE TEMPLATES

### Template 1: ASP.NET to Flask + React
```
Convert the application at "./appV2" to a new stack:
- TARGET_APP_NAME: appV4
- TARGET_FRONTEND: react
- TARGET_BACKEND: python-flask
- TARGET_DATABASE: postgresql
- DEPLOYMENT_TARGET: docker

Execute the full conversion workflow automatically.
```

### Template 2: ASP.NET to Flask + Jinja2 (Server-Side)
```
Convert the application at "./appV2" to a new stack:
- TARGET_APP_NAME: appV3
- TARGET_FRONTEND: flask-jinja2
- TARGET_BACKEND: python-flask
- TARGET_DATABASE: sqlserver
- DEPLOYMENT_TARGET: docker

Execute the full conversion workflow automatically.
```

### Template 3: ASP.NET to FastAPI + Vue
```
Convert the application at "./appV2" to a new stack:
- TARGET_APP_NAME: appV5
- TARGET_FRONTEND: vue
- TARGET_BACKEND: python-fastapi
- TARGET_DATABASE: postgresql
- DEPLOYMENT_TARGET: azure

Execute the full conversion workflow automatically.
```

### Template 4: ASP.NET to Node.js + React
```
Convert the application at "./appV2" to a new stack:
- TARGET_APP_NAME: appV6
- TARGET_FRONTEND: react
- TARGET_BACKEND: nodejs-express
- TARGET_DATABASE: postgresql
- DEPLOYMENT_TARGET: docker

Execute the full conversion workflow automatically.
```

---

## 🔧 CUSTOMIZATION OPTIONS

### Add to prompt for specific needs:

**For Azure Deployment:**
```
Additionally, create Bicep infrastructure-as-code templates for Azure deployment including:
- App Service for backend
- Static Web Apps for frontend
- Azure SQL Database
- Key Vault for secrets
- Application Insights for monitoring
- CDN for static assets
```

**For CI/CD Pipeline:**
```
Additionally, create GitHub Actions workflows for:
- Build and test on PR
- Deploy to staging on merge to develop
- Deploy to production on merge to main
- Docker image building and pushing
```

**For Microservices:**
```
Additionally, split the monolith into microservices:
- Auth Service
- Job Service
- Resume Service
- Company Service
- API Gateway
Each with its own Dockerfile and docker-compose configuration.
```

**For Kubernetes:**
```
Additionally, create Kubernetes manifests:
- Deployments for each service
- Services for networking
- Ingress for routing
- ConfigMaps for configuration
- Secrets for sensitive data
- Horizontal Pod Autoscaler
```

---

## 📊 EXPECTED OUTPUT STRUCTURE

```
{TARGET_APP_NAME}/
├── app/
│   ├── __init__.py          # App factory
│   ├── config.py             # Configuration
│   ├── extensions.py         # Flask extensions
│   ├── models/               # Database models
│   ├── routes/               # API routes/blueprints
│   ├── forms/                # Form validation
│   ├── templates/            # Jinja2 templates (if applicable)
│   └── static/               # CSS, JS, images
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_models.py
│   └── test_routes.py
├── scripts/
│   ├── init-db.sql
│   └── seed_data.py
├── .env.example
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── run.py
├── README.md
└── MIGRATION_GUIDE.md
```

---

## 🎯 SUCCESS METRICS

The conversion is successful when:
- [ ] All source models are converted
- [ ] All API endpoints are replicated
- [ ] Authentication works correctly
- [ ] Docker containers build and run
- [ ] Database migrations complete
- [ ] Basic tests pass
- [ ] Application is accessible in browser
- [ ] CRUD operations work for all entities

---

## 💡 TIPS FOR BEST RESULTS

1. **Provide clear source path**: Ensure the source application path is accessible
2. **Start with analysis**: Let the AI analyze before converting
3. **Review phase by phase**: Check output after each major phase
4. **Test incrementally**: Run Docker builds early to catch issues
5. **Keep source unchanged**: Never modify the original application
6. **Use version control**: Commit after each successful phase

---

## 🔄 ITERATIVE REFINEMENT PROMPTS

After initial conversion, use these follow-up prompts:

**Fix errors:**
```
Review the conversion and fix any errors. Check:
1. Import statements
2. Database connections
3. Route definitions
4. Template rendering
Run the application and resolve any runtime errors.
```

**Add missing features:**
```
Compare the source application with the converted application.
Identify any missing features or functionality.
Implement the missing features maintaining the same patterns used in the conversion.
```

**Optimize performance:**
```
Review the converted application for performance optimizations:
1. Add database indexes
2. Implement caching where appropriate
3. Optimize queries (N+1 problems)
4. Add connection pooling
5. Implement lazy loading
```

**Enhance security:**
```
Review and enhance security:
1. Add CSRF protection
2. Implement rate limiting
3. Add input validation
4. Sanitize outputs
5. Add security headers
6. Review authentication flow
```

---

**Version**: 1.0
**Created**: January 21, 2026
**Compatible With**: GitHub Copilot, Claude, GPT-4, and similar AI coding assistants
