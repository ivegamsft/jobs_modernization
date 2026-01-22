# JobSite Infrastructure Modernization

**Status**: ✅ Infrastructure deployed and ready  
**Last Updated**: 2026-01-21  
**Version**: 3.0 (Python + Kubernetes)

---

## 📋 Quick Navigation

### 🎯 For Quick Start (5 minutes)

- **Start Here**: [specs/QUICKSTART.md](specs/QUICKSTART.md) - 5-minute infrastructure overview
- **Deploy Now**: [iac/bicep/QUICK_START.md](iac/bicep/QUICK_START.md) - Ready-to-run deployment commands

### 📚 For Complete Understanding (30 minutes)

- **Network Spec**: [specs/001-network-redesign/spec.md](specs/001-network-redesign/spec.md) - What we built
- **Infrastructure Reorg Spec**: [specs/002-infra-reorg/spec.md](specs/002-infra-reorg/spec.md) - Correct RG placement & WFE
- **Plans**: [specs/001-network-redesign/plan.md](specs/001-network-redesign/plan.md), [specs/002-infra-reorg/plan.md](specs/002-infra-reorg/plan.md)
- **Tasks**: [specs/001-network-redesign/tasks.md](specs/001-network-redesign/tasks.md), [specs/002-infra-reorg/tasks.md](specs/002-infra-reorg/tasks.md)

### 🔍 For Detailed Reference

- **All Specs**: [specs/INDEX.md](specs/INDEX.md)
- **Quick Starts**: [specs/QUICKSTART.md](specs/QUICKSTART.md) and [iac/bicep/QUICK_START.md](iac/bicep/QUICK_START.md)

---

## 🏗️ Project Structure

```
jobs_modernization/
├── README.md (this file)              ← Start here
├── specs/                             ← Specifications
│   ├── QUICKSTART.md                 ← 5-min overview
│   ├── INDEX.md                      ← Complete reference
│   ├── 001-network-redesign/         ← Network redesign feature
│   │   ├── spec.md                   ← Requirements
│   │   ├── plan.md                   ← Architecture decisions
│   │   ├── tasks.md                  ← Execution tasks (13 tasks)
│   │   ├── implementation.md         ← Step-by-step commands
│   │   ├── constitution.md           ← Quality standards
│   │   └── README.md                 ← Feature status
│   └── 002-infra-reorg/              ← RG/ingress/build reorg
│       ├── spec.md                   ← Corrected state & acceptance
│       ├── plan.md                   ← RG map, WFE, build isolation
│       ├── tasks.md                  ← Execution tasks
│       ├── implementation.md         ← Commands & validation
│       ├── constitution.md           ← Standards
│       └── README.md                 ← Status
├── iac/                              ← Infrastructure as Code
│   ├── bicep/                        ← Bicep IaC templates
│   │   ├── README.md                 ← Overview
│   │   ├── QUICK_START.md           ← Deployment guide
│   │   ├── core/                     ← Core network layer
│   │   ├── iaas/                     ← VMs & networking
│   │   └── paas/                     ← App Services & databases
│   ├── tf/                           ← Terraform (alternative)
│   └── scripts/                      ← Deployment scripts
├── appV1/                            ← Original ASP.NET 2.0 application
├── appV2/                            ← .NET 6 modernized version
│   ├── README.md
│   ├── MIGRATION_CHECKLIST.md
│   └── docs/
├── appV3/                            ← Python + Kubernetes version
│   ├── README.md
│   ├── MIGRATION_GUIDE.md
│   └── app/
├── Database/                         ← Database schemas & migrations
├── docs/                             ← General documentation
└── tests/                            ← Test suites
```

---

## 🎯 What This Project Does

### JobSite Application

A job portal connecting job seekers and employers. Three versions:

1. **AppV1** - Original ASP.NET 2.0 Web Forms (reference only)
2. **AppV2** - Modernized .NET 6.0 (production-ready)
3. **AppV3** - Python + FastAPI + Kubernetes (emerging)

### Infrastructure

- **Networking**: Azure VNet with 7 properly-sized subnets
- **Compute**: VMSS (web tier), SQL VMs, Container Apps
- **Services**: App Gateway, Log Analytics, Key Vault, ACR
- **Security**: Defender, Private Endpoints, RBAC, Managed Identities

---

## 🚀 Getting Started

### For Infrastructure Deployment

```powershell
# 1. Review the network design
cat specs/001-network-redesign/spec.md

# 2. Follow quick start
cd iac/bicep
cat QUICK_START.md

# 3. Execute deployment (see Phase 1-4 in tasks.md)
az deployment sub create --name jobsite-core-dev \
  --location swedencentral \
  --template-file core/main.bicep \
  --parameters @core/parameters.bicepparam
```

### For Application Development

#### AppV2 (.NET 6)

```bash
cd appV2
cat README.md                    # Application overview
cat MIGRATION_CHECKLIST.md       # What's been modernized
```

#### AppV3 (Python)

```bash
cd appV3
cat README.md                    # Application overview
cat MIGRATION_GUIDE.md           # How to run it
```

### For Database Management

```bash
cd Database
cat JobsDB/README.md             # Database structure
ls JobsDB/Scripts/               # Migration scripts
```

---

## 📊 Project Status

### ✅ Completed

- [x] Infrastructure designed (network, compute, security)
- [x] Bicep templates created (Core, IaaS, PaaS layers)
- [x] Specifications written (5-step framework)
- [x] 13 deployment tasks documented
- [x] AppV2 modernization (.NET 6)
- [x] AppV3 modernization (Python + FastAPI)

### 🔄 In Progress

- [ ] AppV3 testing and validation
- [ ] Kubernetes deployment (appV3)
- [ ] CI/CD pipeline automation

### ⏳ Planned

- [ ] Multi-region failover setup
- [ ] Advanced monitoring dashboards
- [ ] Disaster recovery runbooks

---

## 📖 Documentation by Purpose

### For Stakeholders & PMs

Read in this order:

1. [specs/QUICKSTART.md](specs/QUICKSTART.md) - Fast orientation
2. [specs/001-network-redesign/spec.md](specs/001-network-redesign/spec.md) - Network redesign requirements
3. [specs/002-infra-reorg/spec.md](specs/002-infra-reorg/spec.md) - RG/WFE/build reorg requirements

### For Architects & Engineers

Read in this order:

1. [specs/001-network-redesign/plan.md](specs/001-network-redesign/plan.md) - VNet/subnet design
2. [specs/002-infra-reorg/plan.md](specs/002-infra-reorg/plan.md) - RG map, App Gateway, build isolation
3. [iac/bicep/README.md](iac/bicep/README.md) - IaC structure
4. [specs/001-network-redesign/constitution.md](specs/001-network-redesign/constitution.md) and [specs/002-infra-reorg/constitution.md](specs/002-infra-reorg/constitution.md) - Quality standards

### For Implementers (DevOps/SRE)

Read in this order:

1. [specs/001-network-redesign/tasks.md](specs/001-network-redesign/tasks.md) and [specs/002-infra-reorg/tasks.md](specs/002-infra-reorg/tasks.md) - Task sequences
2. [iac/bicep/QUICK_START.md](iac/bicep/QUICK_START.md) - Deployment commands
3. [specs/001-network-redesign/implementation.md](specs/001-network-redesign/implementation.md) and [specs/002-infra-reorg/implementation.md](specs/002-infra-reorg/implementation.md) - Detailed steps

### For Developers (AppV2/AppV3)

Read in this order:

1. [appV2/README.md](appV2/README.md) - .NET 6 application overview
2. [appV3/README.md](appV3/README.md) - Python application overview
3. [appV3/MIGRATION_GUIDE.md](appV3/MIGRATION_GUIDE.md) - How to run locally

---

## 🔧 Key Technologies

| Layer          | Technology                          | Purpose                   |
| -------------- | ----------------------------------- | ------------------------- |
| **IaC**        | Bicep, PowerShell                   | Infrastructure automation |
| **Compute**    | Azure VMs, VMSS, AKS                | Application hosting       |
| **Database**   | SQL Server, SQL Database            | Data persistence          |
| **AppV2**      | .NET 6.0, ASP.NET Core              | Web application           |
| **AppV3**      | Python 3.11, FastAPI                | API-first application     |
| **Container**  | Docker, Kubernetes                  | AppV3 deployment          |
| **Monitoring** | Log Analytics, Application Insights | Observability             |
| **Security**   | Key Vault, Managed Identity, RBAC   | Secrets & access control  |

---

## 💡 Key Improvements Made

### Infrastructure

- ✅ VNet expanded 8x (256 → 2,048 IPs)
- ✅ All subnets follow Azure best practices
- ✅ 44% growth buffer for 3-5 years
- ✅ Security hardened (Defender, RBAC, Private Endpoints)

### Application

- ✅ AppV2: Modernized to .NET 6 with ASP.NET Core
- ✅ AppV3: Rewritten in Python for cloud-native deployment
- ✅ Both versions include Docker support
- ✅ Both have monitoring and logging integrated

### Security

- ✅ Removed all hardcoded credentials
- ✅ All secrets in Key Vault
- ✅ Managed Identities for VM access
- ✅ RBAC with principle of least privilege
- ✅ Private Endpoints for sensitive services
- ✅ Microsoft Defender for Cloud enabled

---

## 📋 Common Tasks

### Deploy Infrastructure

```powershell
# See: specs/001-network-redesign/tasks.md (Phase 2)
# Or:  iac/bicep/QUICK_START.md
```

### Update Application

```bash
# AppV2 (.NET)
cd appV2
dotnet build
dotnet publish

# AppV3 (Python)
cd appV3
python -m pip install -r requirements.txt
python run.py
```

### Check Deployment Status

```powershell
# See: iac/DEPLOYMENT_STATUS.md
az deployment group list --resource-group jobsite-core-rg
```

### Troubleshoot Issues

```powershell
# See: specs/001-network-redesign/implementation.md (Troubleshooting section)
# Or:  appV2/docs/TROUBLESHOOTING.md
# Or:  appV3/README.md (Running Locally section)
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](appV2/CONTRIBUTING.md) for guidelines.

### Spec-Driven Development

This project uses GitHub Spec Kit for structured feature development:

```
spec.md        → What we're building (requirements)
    ↓
plan.md        → How we'll build it (architecture)
    ↓
constitution.md → Quality standards
    ↓
tasks.md       → Actionable task list
    ↓
implementation.md → Detailed execution steps
```

New features should follow this pattern. See [specs/QUICKSTART.md](specs/QUICKSTART.md) for examples.

---

## 📞 Support

| Question                   | Answer Location                                                          |
| -------------------------- | ------------------------------------------------------------------------ |
| How do I deploy?           | [iac/bicep/QUICK_START.md](iac/bicep/QUICK_START.md)                     |
| What's the network design? | [specs/001-network-redesign/spec.md](specs/001-network-redesign/spec.md) |
| Why this architecture?     | [specs/001-network-redesign/plan.md](specs/001-network-redesign/plan.md) |
| How do I run the app?      | [appV2/README.md](appV2/README.md) or [appV3/README.md](appV3/README.md) |
| What changed from AppV1?   | [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)                                 |
| How do I navigate docs?    | [HOW_TO_NAVIGATE.md](HOW_TO_NAVIGATE.md)                                 |

---

## 📄 License

See [LICENSE](appV2/LICENSE) file.

---

**Ready to get started?**
→ Start with [specs/QUICKSTART.md](specs/QUICKSTART.md) (5 minutes)
→ Then review [specs/001-network-redesign/spec.md](specs/001-network-redesign/spec.md) (15 minutes)
→ Then see [iac/bicep/QUICK_START.md](iac/bicep/QUICK_START.md) (10 minutes)
