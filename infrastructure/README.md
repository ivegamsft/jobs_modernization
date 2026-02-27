# Infrastructure

## Overview
Infrastructure as Code (IaC) for deploying the Jobs Modernization application to Azure.

## Contents

### `bicep/`
Azure Bicep templates for declarative infrastructure deployment.
- Resource group organization (4-layer structure)
- App Service + App Service Plan
- Azure SQL Server + Database
- Networking and security configuration

### `terraform/`
Terraform templates (alternative IaC approach, if applicable).

### `scripts/`
Deployment and utility scripts:
- `cleanup_secrets.py` — Remove sensitive data from configuration
- `CLEANUP_SECRETS.ps1` — PowerShell version of cleanup script

### `docs/`
Comprehensive infrastructure documentation:
- **4LAYER_RG_QUICK_REFERENCE.md** — Resource group organization strategy
- **DEPLOYMENT_COMPLETE.md** — IaaS deployment completion summary
- **DEPLOYMENT_SUMMARY.md** — Infrastructure deployment status
- **DOCUMENTATION_PACKAGE_README.md** — Index of infrastructure docs
- **IMPLEMENTATION_CHECKLIST.md** — Infrastructure implementation tasks
- **RESOURCE_GROUP_ORGANIZATION_FIX.md** — RG organization fix details
- **THE_ISSUE_AND_FIX.md** — Azure CLI deployment issue resolution
- **VISUAL_SUMMARY.md** — Infrastructure visual guide

### `vm-rdc-conns.rdg`
Remote Desktop connection file for Azure VMs (if applicable).

## Deployment

### Prerequisites
- Azure subscription
- Azure CLI or PowerShell Az module
- Appropriate permissions (Contributor or Owner)

### Quick Start
1. Review [4-Layer RG Quick Reference](./docs/4LAYER_RG_QUICK_REFERENCE.md)
2. Check [Implementation Checklist](./docs/IMPLEMENTATION_CHECKLIST.md)
3. Deploy Bicep templates: `az deployment group create --template-file bicep/main.bicep`

## Architecture

The infrastructure supports all three modernization phases:
- **Phase 1:** Baseline (can be hosted on-prem or IaaS)
- **Phase 2:** Azure PaaS (App Service + Azure SQL)
- **Phase 3:** Modern architecture (Container Apps / AKS)

## Resource Organization

**4-Layer Resource Group Strategy:**
1. **Networking Layer** — Virtual networks, NSGs, gateways
2. **Platform Layer** — Shared services (Key Vault, Log Analytics)
3. **Data Layer** — Databases, storage accounts
4. **Application Layer** — App Services, Container Apps

➡️ See [4-Layer Quick Reference](./docs/4LAYER_RG_QUICK_REFERENCE.md) for details

## Related Documentation

- [Phase 2: Azure Migration](../phase2-azure-migration/README.md)
- [Deployment Complete Summary](./docs/DEPLOYMENT_COMPLETE.md)
