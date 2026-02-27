# Phase 3: Modernization

## Goal
Build modern API backends and React UI that run alongside the legacy application using the **strangler fig pattern**.

## Modern Implementations

### `api-dotnet/`
**ASP.NET Core 6+ with Clean Architecture**
- Modern .NET API
- Clean architecture (Domain, Application, Infrastructure layers)
- Entity Framework Core
- Dependency injection
- Unit and integration tests

➡️ [.NET API Documentation](./api-dotnet/README.md)

### `api-python/`
**Python Flask Alternative**
- Python Flask API
- Alternative backend implementation
- RESTful endpoints
- Database integration

➡️ [Python API Documentation](./api-python/README.md)

### `ui-react/`
**React SPA Frontend** *(In Progress)*
- Modern React single-page application
- Responsive UI
- API integration
- Modern UX/UI design

➡️ [React UI Documentation](./ui-react/README.md)

## Modernization Strategy

**Strangler Fig Pattern:**
1. Deploy modern API alongside legacy app
2. Route new features to modern API
3. Gradually migrate existing features
4. Eventually replace legacy monolith

**Benefits:**
- Minimize risk (no "big bang" rewrite)
- Incremental value delivery
- Test modern architecture in production
- Learn and adapt as you go

## Documentation

- **[React Conversion Plan](./docs/REACT_CONVERSION_PLAN.md)** — Strategy for building React UI
- **[Conversion Workflow](./docs/CONVERSION_WORKFLOW_PROMPT.md)** — AI-assisted conversion process

## Architecture

| Component | Legacy (Phase 1-2) | Modern (Phase 3) |
|-----------|-------------------|------------------|
| **UI** | Web Forms | React SPA |
| **Backend** | .NET Framework | .NET Core / Python |
| **API** | None (monolith) | RESTful API |
| **Database** | Direct SQL | ORM (EF Core) |
| **Hosting** | App Service | Container Apps / AKS |

## Technologies

- **Frontend:** React, TypeScript, Vite
- **Backend:** ASP.NET Core 6+, Python Flask
- **Database:** Entity Framework Core, SQL Server
- **Testing:** xUnit, Pytest
- **Containerization:** Docker, Kubernetes

## Previous Steps

⬅️ [Phase 1: Legacy Baseline](../phase1-legacy-baseline/README.md)  
⬅️ [Phase 2: Azure Migration](../phase2-azure-migration/README.md)
