# VM-Based Infrastructure Deployment - Complete Index

## 📚 Documentation Map

This document provides complete navigation for the VM-based JobSite infrastructure deployment.

### 🚀 Start Here

**New to this deployment?**
→ Start with [QUICKSTART_VM.md](./QUICKSTART_VM.md) (5 minutes)

**Ready to deploy?**
→ Follow [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) (step-by-step)

**Need architecture details?**
→ Read [core/README.md](./core/README.md) and [vm/README.md](./vm/README.md)

---

## 📖 Core Documentation

### Quick References (5-15 minutes)

| Document                                                   | Purpose                             | Read Time |
| ---------------------------------------------------------- | ----------------------------------- | --------- |
| [QUICKSTART_VM.md](./QUICKSTART_VM.md)                     | Overview, architecture, checklist   | 5 min     |
| [core/DEPLOYMENT_SUMMARY.md](./core/DEPLOYMENT_SUMMARY.md) | What's been created, next steps     | 5 min     |
| [vm/README.md](./vm/README.md) — Scaling section           | Horizontal/vertical scaling options | 3 min     |
| [vm/README.md](./vm/README.md) — Monitoring section        | Key metrics to track                | 3 min     |

### In-Depth Documentation (30-60 minutes)

| Document                                           | Purpose                                     | Read Time |
| -------------------------------------------------- | ------------------------------------------- | --------- |
| [core/README.md](./core/README.md)                 | Core architecture, network design, security | 15 min    |
| [vm/README.md](./vm/README.md)                     | VM configuration, components, operations    | 15 min    |
| [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) | Step-by-step deployment, troubleshooting    | 30 min    |

### Code Files

| File                                                       | Lines | Purpose                                    |
| ---------------------------------------------------------- | ----- | ------------------------------------------ |
| [core/main.bicep](./core/main.bicep)                       | 638   | VNet, subnets, VPN, DNS, KV, Log Analytics |
| [vm/main.bicep](./vm/main.bicep)                           | 780+  | VMSS, SQL Server, App Gateway              |
| [vm/scripts/iis-install.ps1](./vm/scripts/iis-install.ps1) | 70    | IIS installation automation                |

### Configuration Files

| File                                                       | Purpose                        |
| ---------------------------------------------------------- | ------------------------------ |
| [core/parameters.bicepparam](./core/parameters.bicepparam) | Core infrastructure parameters |
| [vm/parameters.bicepparam](./vm/parameters.bicepparam)     | VM infrastructure parameters   |

---

## 🎯 Common Scenarios

### Scenario 1: "I need to deploy this infrastructure"

**Time Required**: 1-2 hours (including preparation)

**Steps**:

1. Read [QUICKSTART_VM.md](./QUICKSTART_VM.md) — Architecture overview (5 min)
2. Follow [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) — Deployment steps (30 min)
3. Configure post-deployment items — IIS, SQL, certificates (30 min)
4. Deploy your application (30 min)

**Key Files**:

- [core/main.bicep](./core/main.bicep)
- [vm/main.bicep](./vm/main.bicep)
- [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md)

### Scenario 2: "I need to understand the network architecture"

**Time Required**: 15-20 minutes

**Reading Order**:

1. [QUICKSTART_VM.md](./QUICKSTART_VM.md#architecture-highlights) — High-level architecture
2. [core/README.md](./core/README.md#components) — Detailed component descriptions
3. [core/README.md](./core/README.md#network-subnets) — Subnet allocation table
4. [QUICKSTART_VM.md](./QUICKSTART_VM.md#network-subnets) — Network subnets reference

### Scenario 3: "I need to scale the application"

**Time Required**: 5-10 minutes

**Reading Order**:

1. [vm/README.md](./vm/README.md#scaling) — Scaling options
2. [QUICKSTART_VM.md](./QUICKSTART_VM.md#common-commands) — Scale commands

**Commands**:

```bash
# Scale VMSS to 3 instances
az vmss scale --resource-group <rg> --name <vmss-name> --new-capacity 3

# Scale App Gateway to 4 instances
az network application-gateway update --resource-group <rg> --name <appgw-name> --set sku.capacity=4
```

### Scenario 4: "I need to monitor the infrastructure"

**Time Required**: 10-15 minutes

**Reading Order**:

1. [core/README.md](./core/README.md#monitoring-highlights) — Monitoring setup
2. [vm/README.md](./vm/README.md#monitoring) — Key metrics
3. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#monitoring--diagnostics) — Query examples

### Scenario 5: "I'm having deployment issues"

**Time Required**: 15-30 minutes

**Reading Order**:

1. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#troubleshooting) — Troubleshooting guide
2. [vm/README.md](./vm/README.md#troubleshooting) — Additional troubleshooting

**Check**:

- Certificates are base64 encoded
- Resource Groups are created
- Parameters are correctly updated
- Azure CLI is authenticated

### Scenario 6: "I need to understand costs"

**Time Required**: 5 minutes

**Reading Order**:

1. [QUICKSTART_VM.md](./QUICKSTART_VM.md#cost-estimates) — Cost breakdown table
2. [core/README.md](./core/README.md#cost-considerations) — Cost optimization tips

### Scenario 7: "I need to harden security"

**Time Required**: 15-20 minutes

**Reading Order**:

1. [core/README.md](./core/README.md#security-highlights) — What's already implemented
2. [vm/README.md](./vm/README.md#security-best-practices) — Additional security measures
3. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#security-considerations) — Security checklist

---

## 📂 File Structure Reference

```
iac/bicep/
├── QUICKSTART_VM.md                   ← READ THIS FIRST
│
├── core/                              ← Deploy First
│   ├── main.bicep                     (638 lines)
│   ├── parameters.bicepparam
│   ├── README.md                      (400+ lines)
│   └── DEPLOYMENT_SUMMARY.md          (300+ lines)
│
├── vm/                                ← Deploy Second
│   ├── main.bicep                     (780+ lines)
│   ├── parameters.bicepparam
│   ├── README.md                      (400+ lines)
│   ├── DEPLOYMENT_GUIDE.md            (500+ lines)
│   └── scripts/
│       └── iis-install.ps1           (70 lines)
```

---

## 🗺️ Content Map by Topic

### Understanding the Infrastructure

| Topic                 | File                       | Section                 |
| --------------------- | -------------------------- | ----------------------- |
| What's included?      | QUICKSTART_VM.md           | Overview section        |
| Architecture overview | QUICKSTART_VM.md           | Architecture Highlights |
| Network design        | core/README.md             | Deployment Architecture |
| Resource list         | core/DEPLOYMENT_SUMMARY.md | Resource Summary        |
| Components detail     | core/README.md             | Components section      |

### Preparing for Deployment

| Topic                 | File                   | Section               |
| --------------------- | ---------------------- | --------------------- |
| Prerequisites         | vm/DEPLOYMENT_GUIDE.md | Prerequisites         |
| Checklist             | QUICKSTART_VM.md       | Deployment Checklist  |
| Generate certificates | vm/DEPLOYMENT_GUIDE.md | Step 1 & 2            |
| Update parameters     | core/README.md         | Deployment Parameters |

### Executing Deployment

| Topic              | File                   | Section         |
| ------------------ | ---------------------- | --------------- |
| Core deployment    | vm/DEPLOYMENT_GUIDE.md | Step 3-4        |
| VM deployment      | vm/DEPLOYMENT_GUIDE.md | Step 5-6        |
| Capture outputs    | vm/DEPLOYMENT_GUIDE.md | Step 5          |
| Commands reference | QUICKSTART_VM.md       | Common Commands |

### Post-Deployment

| Topic             | File                   | Section                       |
| ----------------- | ---------------------- | ----------------------------- |
| IIS configuration | vm/DEPLOYMENT_GUIDE.md | Post-Deployment Tasks         |
| SQL Server setup  | vm/README.md           | Post-Deployment Configuration |
| DNS records       | vm/DEPLOYMENT_GUIDE.md | Post-Deployment Tasks         |
| App Gateway cert  | vm/README.md           | Post-Deployment Configuration |
| Monitoring setup  | core/README.md         | Post-Deployment Configuration |

### Scaling & Optimization

| Topic                | File           | Section           |
| -------------------- | -------------- | ----------------- |
| VMSS autoscaling     | vm/README.md   | Scaling           |
| App Gateway capacity | vm/README.md   | Scaling           |
| Right-sizing VMs     | vm/README.md   | Cost Optimization |
| Reserved instances   | core/README.md | Cost Optimization |

### Monitoring & Operations

| Topic             | File                   | Section                  |
| ----------------- | ---------------------- | ------------------------ |
| What to monitor   | vm/README.md           | Monitoring               |
| Query examples    | vm/DEPLOYMENT_GUIDE.md | Monitoring & Diagnostics |
| Create alerts     | vm/README.md           | Create Alerts            |
| Maintenance tasks | core/README.md         | Maintenance              |

### Troubleshooting

| Topic              | File                   | Section         |
| ------------------ | ---------------------- | --------------- |
| Deployment issues  | vm/DEPLOYMENT_GUIDE.md | Troubleshooting |
| VMSS health        | vm/README.md           | Troubleshooting |
| SQL connectivity   | vm/README.md           | Troubleshooting |
| App Gateway health | vm/README.md           | Troubleshooting |

---

## 🔍 Quick Lookup Table

**Looking for...**

| What                    | Where                              | Link                                                       |
| ----------------------- | ---------------------------------- | ---------------------------------------------------------- |
| 5-minute overview       | QUICKSTART_VM.md                   | [Link](./QUICKSTART_VM.md)                                 |
| Architecture diagram    | QUICKSTART_VM.md or core/README.md | [Link](./QUICKSTART_VM.md#architecture-quick-view)         |
| Deployment steps        | vm/DEPLOYMENT_GUIDE.md             | [Link](./vm/DEPLOYMENT_GUIDE.md#deployment-steps)          |
| Cost estimate           | QUICKSTART_VM.md                   | [Link](./QUICKSTART_VM.md#cost-estimates)                  |
| Network subnets         | QUICKSTART_VM.md                   | [Link](./QUICKSTART_VM.md#network-subnets)                 |
| Scaling commands        | QUICKSTART_VM.md                   | [Link](./QUICKSTART_VM.md#common-commands)                 |
| Monitoring queries      | vm/DEPLOYMENT_GUIDE.md             | [Link](./vm/DEPLOYMENT_GUIDE.md#monitoring--diagnostics)   |
| Troubleshooting         | vm/DEPLOYMENT_GUIDE.md             | [Link](./vm/DEPLOYMENT_GUIDE.md#troubleshooting)           |
| Security best practices | core/README.md                     | [Link](./core/README.md#security-highlights)               |
| What's been created     | core/DEPLOYMENT_SUMMARY.md         | [Link](./core/DEPLOYMENT_SUMMARY.md#what-has-been-created) |

---

## 📋 Reading Recommendations by Role

### DevOps Engineer

**Read** (in order):

1. [core/README.md](./core/README.md) (15 min)
2. [vm/README.md](./vm/README.md) (15 min)
3. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) (30 min)

**Focus Areas**:

- Network architecture and security
- Deployment procedures
- Monitoring and diagnostics
- Scaling strategies

**Key Files**:

- [core/main.bicep](./core/main.bicep)
- [vm/main.bicep](./vm/main.bicep)
- [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md)

### Cloud Architect

**Read** (in order):

1. [QUICKSTART_VM.md](./QUICKSTART_VM.md) (5 min)
2. [core/README.md](./core/README.md) (15 min)
3. [core/DEPLOYMENT_SUMMARY.md](./core/DEPLOYMENT_SUMMARY.md) (10 min)

**Focus Areas**:

- Architecture design
- Resource organization
- Security posture
- Cost implications
- Scalability considerations

**Key Sections**:

- [QUICKSTART_VM.md — Architecture](./QUICKSTART_VM.md#architecture-quick-view)
- [core/README.md — Deployment Architecture](./core/README.md#deployment-architecture)
- [core/DEPLOYMENT_SUMMARY.md — Resource Summary](./core/DEPLOYMENT_SUMMARY.md#resource-summary)

### Database Administrator

**Read** (in order):

1. [QUICKSTART_VM.md](./QUICKSTART_VM.md) (5 min) — Find SQL VM info
2. [vm/README.md](./vm/README.md#sql-server-vm) (10 min)
3. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#sql-server-post-configuration) (10 min)

**Focus Areas**:

- SQL Server VM configuration
- Disk allocation and initialization
- Database creation
- Auto-patching settings
- Backup and recovery
- High availability (future)

**Key Sections**:

- [vm/README.md — SQL Server VM](./vm/README.md#2-sql-server-vm)
- [vm/DEPLOYMENT_GUIDE.md — SQL Server Post-Configuration](./vm/DEPLOYMENT_GUIDE.md#2-sql-server-post-configuration)

### Application Administrator

**Read** (in order):

1. [QUICKSTART_VM.md](./QUICKSTART_VM.md) (5 min)
2. [vm/README.md](./vm/README.md#vmss-web-frontend) (10 min)
3. [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#1-iis-configuration) (10 min)

**Focus Areas**:

- VMSS and IIS configuration
- Application deployment
- Health monitoring
- Scaling for load
- Application Gateway routing

**Key Sections**:

- [vm/README.md — VMSS](./vm/README.md#1-vmss-web-frontend)
- [vm/DEPLOYMENT_GUIDE.md — IIS Configuration](./vm/DEPLOYMENT_GUIDE.md#1-iis-configuration-script)

### Security Engineer

**Read** (in order):

1. [core/README.md — Security Highlights](./core/README.md#security-highlights) (5 min)
2. [vm/README.md — Security Best Practices](./vm/README.md#security-best-practices) (10 min)
3. [vm/DEPLOYMENT_GUIDE.md — Security Considerations](./vm/DEPLOYMENT_GUIDE.md#security-considerations) (10 min)

**Focus Areas**:

- Network isolation
- Identity and access (RBAC)
- Encryption
- WAF configuration
- Monitoring and logging
- Compliance requirements

**Key Sections**:

- [core/README.md — Security Highlights](./core/README.md#security-highlights)
- [vm/README.md — Security Best Practices](./vm/README.md#security-best-practices)

---

## ✅ Deployment Checklist

Before you start deployment, ensure you've read:

- [ ] [QUICKSTART_VM.md](./QUICKSTART_VM.md) — Understand architecture
- [ ] [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) — Understand steps
- [ ] [core/README.md](./core/README.md#deployment-parameters) — Parameter values needed

Before you deploy, complete:

- [ ] Generate VPN root certificate
- [ ] Generate App Gateway certificate
- [ ] Create Resource Groups
- [ ] Update parameters.bicepparam files
- [ ] Test Azure CLI authentication
- [ ] Verify VM size availability in region

---

## 📞 Getting Help

**If you have a question about...**

| Topic            | Where to Look                                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- |
| Architecture     | [core/README.md](./core/README.md) or [core/DEPLOYMENT_SUMMARY.md](./core/DEPLOYMENT_SUMMARY.md)                 |
| Bicep syntax     | [vm/main.bicep](./vm/main.bicep) or [core/main.bicep](./core/main.bicep) comments                                |
| Deployment steps | [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md)                                                               |
| Parameters       | [core/README.md](./core/README.md#deployment-parameters)                                                         |
| Post-deployment  | [vm/README.md](./vm/README.md#post-deployment-configuration)                                                     |
| Scaling          | [vm/README.md](./vm/README.md#scaling)                                                                           |
| Monitoring       | [core/README.md](./core/README.md#monitoring--diagnostics) or [vm/README.md](./vm/README.md#monitoring)          |
| Troubleshooting  | [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md#troubleshooting)                                               |
| Security         | [core/README.md](./core/README.md#security-highlights) or [vm/README.md](./vm/README.md#security-best-practices) |
| Costs            | [QUICKSTART_VM.md](./QUICKSTART_VM.md#cost-estimates)                                                            |

---

## 🎓 Learning Resources

**External Resources**:

- [Azure Virtual Machines documentation](https://docs.microsoft.com/azure/virtual-machines/)
- [Bicep documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Application Gateway WAF documentation](https://docs.microsoft.com/azure/application-gateway/waf-overview)
- [Azure VPN Gateway documentation](https://docs.microsoft.com/azure/vpn-gateway/)

---

## 📊 Documentation Statistics

| Component     | Files  | Lines      | Words       |
| ------------- | ------ | ---------- | ----------- |
| Bicep Code    | 2      | 1,418+     | —           |
| Parameters    | 2      | 35         | —           |
| Documentation | 6      | 3,500+     | 40,000+     |
| Scripts       | 1      | 70         | —           |
| **TOTAL**     | **11** | **5,000+** | **40,000+** |

---

## 🚀 Next Steps

1. **Start Reading**: [QUICKSTART_VM.md](./QUICKSTART_VM.md) (5 min)
2. **Deep Dive**: [core/README.md](./core/README.md) (15 min)
3. **Get Ready**: [vm/DEPLOYMENT_GUIDE.md](./vm/DEPLOYMENT_GUIDE.md) (30 min)
4. **Deploy**: Follow step-by-step instructions (1-2 hours)
5. **Validate**: Check resources in Azure Portal
6. **Configure**: Post-deployment setup (30 min)
7. **Monitor**: Set up monitoring and alerts (15 min)

---

**Status**: ✅ Complete & Ready to Use  
**Last Updated**: 2026-01-21  
**Version**: 1.0  
**Total Documentation**: 5000+ lines of IaC & documentation
