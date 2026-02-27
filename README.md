# Jobs Modernization — A Learning Journey

This repository demonstrates modernizing a legacy .NET Web Forms application to modern Azure cloud architecture through three phases.

## The Three-Phase Story

### 📦 Phase 1: Legacy Baseline
**Goal:** Get the legacy .NET 2.0 app running as-is.

- **Folder:** `phase1-legacy-baseline/`
- **App Versions:**
  - `appV1-original/` — Original code (can't build, reference only)
  - `appV1.5-buildable/` — Minimal changes to make it buildable
- **Learn:** Legacy architecture, code quality issues, .NET 2.0 → .NET Framework migration

➡️ [Start Phase 1](./phase1-legacy-baseline/README.md)

---

### ☁️ Phase 2: Azure Migration
**Goal:** Host on Azure App Service + Azure SQL with minimal code changes.

- **Folder:** `phase2-azure-migration/`
- **Key Concepts:** Lift-and-shift, PaaS hosting, connection string management
- **Learn:** Azure deployment, infrastructure as code, migration strategies

➡️ [Start Phase 2](./phase2-azure-migration/README.md)

---

### 🚀 Phase 3: Modernization
**Goal:** Add modern API + React UI alongside legacy app.

- **Folder:** `phase3-modernization/`
- **Modern Implementations:**
  - `api-dotnet/` — ASP.NET Core 6+ (clean architecture)
  - `api-python/` — Python Flask alternative
  - `ui-react/` — React SPA frontend (in progress)
- **Learn:** Clean architecture, API design, React integration, strangler fig pattern

➡️ [Start Phase 3](./phase3-modernization/README.md)

---

## Supporting Folders

### 🏗️ Infrastructure
**Folder:** `infrastructure/`

Bicep and Terraform templates for Azure deployment. All infrastructure documentation consolidated here.

➡️ [Infrastructure Guide](./infrastructure/README.md)

---

### 🗄️ Database
**Folder:** `database/`

SQL Server database project, schema, and seed data.

➡️ [Database Guide](./database/README.md)

---

### 📋 Specifications
**Folder:** `specs/`

Feature specifications using GitHub Spec Kit framework (spec → plan → tasks → implementation).

➡️ [Specs Index](./specs/README.md)

---

## Quick Start

**For Learners:**
1. Read [Learning Path](./docs/LEARNING_PATH.md)
2. Start with [Phase 1](./phase1-legacy-baseline/README.md)

**For Infrastructure Engineers:**
1. Review [Infrastructure Guide](./infrastructure/README.md)
2. Check [Deployment Docs](./infrastructure/docs/)

**For Developers:**
1. Explore [Phase 3 Modernization](./phase3-modernization/README.md)
2. Review [Clean Architecture API](./phase3-modernization/api-dotnet/README.md)

---

## Technologies

| Layer | Phase 1 | Phase 2 | Phase 3 |
|-------|---------|---------|---------|
| **UI** | Web Forms | Web Forms (hosted) | React SPA |
| **Backend** | .NET 2.0 | .NET Framework 4.x | .NET 6+ / Python |
| **Database** | SQL Server | Azure SQL | Azure SQL |
| **Hosting** | IIS on-prem | Azure App Service | Container Apps / AKS |
| **Architecture** | Monolith | Monolith (PaaS) | Clean Architecture + API |

---

**Learning Repository** — Built to teach .NET modernization strategies.
