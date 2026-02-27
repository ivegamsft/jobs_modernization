# 4-Layer Resource Group Organization - Quick Reference

**Audience**: Infrastructure, DevOps, and Cloud Architecture Teams  
**Purpose**: One-page summary of resource group changes  
**Related Docs**: [Detailed Specification](RESOURCE_GROUP_ORGANIZATION_FIX.md) | [Architecture Plan](specs/001-network-redesign/plan.md)

---

## The Problem (3 Issues)

| Issue                         | Impact                                           | Status                   |
| ----------------------------- | ------------------------------------------------ | ------------------------ |
| **Container Apps in Core RG** | PaaS services mixed with infrastructure          | 🔄 Moving to paas-rg     |
| **Build Agents in IaaS RG**   | Ephemeral resources with long-lived VMs          | 🔄 Moving to agents-rg   |
| **WFE Missing**               | No HTTP/HTTPS ingress, no load balancing, no WAF | ✅ Adding App Gateway v2 |

---

## The Solution (4-Layer Architecture)

### Layer 1: Core RG (jobsite-core-dev-rg)

**Purpose**: Shared infrastructure (rarely changes)

```
✅ Virtual Network (10.50.0.0/21)
✅ 7 Subnets
✅ NAT Gateway + Public IP
✅ Key Vault
✅ Log Analytics Workspace
✅ Container Registry
✅ Private DNS Zones
```

**Owner**: Network Team  
**Changes**: Quarterly or less  
**Scaling**: N/A (infrastructure layer)

---

### Layer 2: IaaS RG (jobsite-iaas-dev-rg)

**Purpose**: Long-lived application VMs + load balancer

```
✅ Application Gateway v2 (WFE) ← NEW
✅ Public IP (App Gateway) ← NEW
✅ Web VMSS (D2ds_v6)
✅ SQL Server VM (D4ds_v6)
✅ Network Interfaces & Disks
```

**Owner**: Operations Team  
**Changes**: Quarterly  
**Scaling**: Manual (monthly capacity planning)

---

### Layer 3: PaaS RG (jobsite-paas-dev-rg)

**Purpose**: Managed services (auto-scaling)

```
✅ Container Apps Environment ← MOVED from core
✅ Container Apps
✅ App Service Plan
✅ App Service
✅ SQL Database
✅ Application Insights
```

**Owner**: DevOps/Development Team  
**Changes**: Weekly or more  
**Scaling**: Automatic (based on demand)

---

### Layer 4: Agents RG (jobsite-agents-dev-rg) ← NEW

**Purpose**: Ephemeral build infrastructure

```
✅ Build Agent VMSS (D2ds_v6, 1-5 instances) ← MOVED from iaas
✅ Network Interfaces
✅ Managed Disks
```

**Owner**: CI/CD Team  
**Changes**: Hourly (new agents created/destroyed)  
**Scaling**: Automatic (based on queue depth)  
**Network**: Connected via snet-gh-runners in Core VNet  
**Outbound**: Via NAT Gateway in Core RG

---

## Resource Movement Map

| Resource           | Current     | Correct    | Action        |
| ------------------ | ----------- | ---------- | ------------- |
| VNet               | core        | core       | ✓ Keep        |
| Key Vault          | core        | core       | ✓ Keep        |
| Log Analytics      | core        | core       | ✓ Keep        |
| Container Registry | core        | core       | ✓ Keep        |
| Container Apps Env | **core**    | **paas**   | 🔄 **MOVE**   |
| Container Apps     | **core**    | **paas**   | 🔄 **MOVE**   |
| App Gateway        | **MISSING** | **iaas**   | ✅ **CREATE** |
| Public IP (WFE)    | **MISSING** | **iaas**   | ✅ **CREATE** |
| Web VMSS           | iaas        | iaas       | ✓ Keep        |
| SQL VM             | iaas        | iaas       | ✓ Keep        |
| Build VMSS         | **iaas**    | **agents** | 🔄 **MOVE**   |

---

## Key Design Principles

### 1. Lifecycle Separation

- **Core**: Infrastructure (rarely changes)
- **IaaS**: Long-lived VMs (quarterly updates)
- **PaaS**: Auto-scaling services (frequent changes)
- **Agents**: Ephemeral resources (hourly changes)

### 2. Independent Scaling

- **IaaS**: Manual scaling (capacity planning)
- **PaaS**: Automatic scaling (CPU/memory)
- **Agents**: Queue-based scaling (build queue depth)

### 3. Team Ownership

- **Core RG**: Network Team (one owner)
- **IaaS RG**: Ops Team (controls long-lived infrastructure)
- **PaaS RG**: DevOps Team (manages managed services)
- **Agents RG**: CI/CD Team (manages build pipeline)

### 4. Cost Tracking

- Separate billing per RG
- Cost centers per team
- Easy chargeback model

---

## Migration Timeline

### Phase 1: Preparation (1-2 hours)

```
1. Create jobsite-agents-dev-rg
2. Create/verify jobsite-paas-dev-rg
3. Backup Container Apps config
4. Backup Build VMSS config
```

### Phase 2: Create Missing Resources (2-3 hours)

```
1. Deploy Application Gateway v2 to iaas-rg
   - SKU: WAF_v2
   - Capacity: 2-10 (auto-scale)
   - Backend: Web VMSS instances
2. Verify health probes show healthy
```

### Phase 3: Move Resources (2-4 hours)

```
1. Move Container Apps Env: core → paas
   (Option: Move or redeploy, redeploy is safer)
2. Move Build VMSS: iaas → agents
3. Verify all connectivity works
```

### Phase 4: Validation (1-2 hours)

```
1. Health check all tiers
2. Test app functionality
3. Verify auto-scaling works
4. Check WAF rules are active
```

**Total**: 8-12 hours | **Downtime**: 30-60 min (or zero with parallel deploy)

---

## Network Connectivity (Unchanged)

**The good news**: Network stays the same! Only RG organization changes.

```
Internet
   ↓
Public IP (on App Gateway, in iaas-rg)
   ↓
Application Gateway v2 (snet-fe, in iaas-rg) ← NEW
   ↓
Web VMSS (snet-app, in iaas-rg)
   ↓
SQL VM (snet-db, stays in iaas-rg)

Build Agents (snet-gh-runners, moves to agents-rg)
   ↓
NAT Gateway (in core-rg)
   ↓
Internet (for package downloads, GitHub API)

Container Apps (moves to paas-rg)
   ↓
SQL Database (stays in paas-rg)
```

**All subnets**: Remain in Core VNet (no changes needed!)

---

## Success Criteria Checklist

### ✅ RG Organization

- [ ] Core RG: Only networking + shared services
- [ ] IaaS RG: App tier + WFE (App Gateway)
- [ ] PaaS RG: Managed services + Container Apps
- [ ] Agents RG: Build VMSS only

### ✅ Connectivity

- [ ] Web tier can reach DB: ✓
- [ ] App Gateway health probes: Healthy ✓
- [ ] Build agents reach internet: ✓
- [ ] Builds execute successfully: ✓

### ✅ WAF (Web Application Firewall)

- [ ] App Gateway has WAF_v2 SKU: ✓
- [ ] OWASP 3.1 rules enabled: ✓
- [ ] Detection mode active: ✓
- [ ] Rules blocking attacks: ✓

### ✅ Monitoring

- [ ] All VMs → Log Analytics: ✓
- [ ] All services → Diagnostics: ✓
- [ ] Defender for Cloud: Enabled ✓

---

## FAQ

**Q: Will there be downtime?**  
A: ~30-60 min if moving in-place. Zero if deploying in parallel then switching. Plan accordingly.

**Q: Why move Build Agents to separate RG?**  
A: They're ephemeral (created hourly), app VMs are long-lived (months). Different lifecycle = different RG.

**Q: Can App Gateway be deployed without Container Apps move?**  
A: Yes! They're independent. Deploy App Gateway first, move Container Apps later if needed.

**Q: Will NSG rules still work?**  
A: Yes! Subnet-level rules apply regardless of RG. VNet connectivity unchanged.

**Q: What if the move fails?**  
A: Have rollback plan ready. Either keep old + new coexisting, or redeploy the 3-layer design.

**Q: How much will this cost?**  
A: ~$30/month for App Gateway. Build agents already exist (cost unchanged). One-time effort ~$700.

---

## Team Responsibilities

### Network Team

- ✅ Approves RG organization
- ✅ Validates subnet connectivity
- ✅ Ensures NSG rules work correctly
- ✅ Maintains Core RG

### Operations Team

- ✅ Manages IaaS RG (VMs)
- ✅ Tests App Gateway deployment
- ✅ Monitors VMSS health
- ✅ Handles manual scaling

### DevOps Team

- ✅ Manages PaaS RG (Container Apps, App Service, etc.)
- ✅ Moves Container Apps to paas-rg
- ✅ Updates Bicep templates
- ✅ Validates auto-scaling

### CI/CD Team

- ✅ Manages Agents RG (build infrastructure)
- ✅ Moves Build VMSS to agents-rg
- ✅ Re-registers GitHub Runners
- ✅ Tests build pipeline

### Security Team

- ✅ Reviews RG ownership model
- ✅ Validates WAF rules
- ✅ Ensures Log Analytics flowing
- ✅ Verifies Defender for Cloud enabled

---

## Bicep File Updates Required

```
infrastructure/bicep/
├── core/
│   └── main.bicep (no changes)
├── iaas/
│   ├── main.bicep (updated RG reference)
│   ├── appgateway.bicep (NEW - WFE)
│   └── compute.bicep (no changes)
├── paas/
│   ├── main.bicep (updated RG reference)
│   └── container-apps.bicep (updated to use paas-rg)
├── agents/
│   ├── main.bicep (NEW)
│   └── vmss.bicep (NEW - moved from iaas)
└── scripts/
    ├── deploy-core.ps1 (no changes)
    ├── deploy-iaas.ps1 (add App Gateway)
    ├── deploy-paas.ps1 (add Container Apps)
    └── deploy-agents.ps1 (NEW)
```

---

## Implementation Checklist

**Week 1: Planning & Approval**

- [ ] Review all specification documents
- [ ] Get approvals from all stakeholders
- [ ] Schedule migration window
- [ ] Prepare Bicep templates

**Week 2: Testing & Preparation**

- [ ] Test Bicep templates
- [ ] Create backup of current state
- [ ] Prepare validation scripts
- [ ] Brief team on changes

**Week 3: Execution**

- [ ] Phase 1: Preparation (1-2 hours)
- [ ] Phase 2: Create missing resources (2-3 hours)
- [ ] Phase 3: Move resources (2-4 hours)
- [ ] Phase 4: Validation (1-2 hours)
- [ ] Documentation & training

---

## Contact & Support

- **Infrastructure Lead**: [Name] - RG organization, network design
- **Cloud Architect**: [Name] - Scalability, WAF configuration
- **DevOps Lead**: [Name] - Bicep templates, deployment automation
- **On-Call During Migration**: [Name] - [Phone] - [Email]

---

## Related Documents

📖 **Detailed Specifications**:

- [specs/001-network-redesign/spec.md](specs/001-network-redesign/spec.md) - Business requirements
- [specs/001-network-redesign/plan.md](specs/001-network-redesign/plan.md) - Architecture decisions with Bicep code
- [RESOURCE_GROUP_ORGANIZATION_FIX.md](RESOURCE_GROUP_ORGANIZATION_FIX.md) - Detailed migration guide

📋 **Task Lists**:

- [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) - Task-by-task execution checklist

🔍 **Monitoring**:

- [scripts/validate-rg-organization.ps1](scripts/validate-rg-organization.ps1) - Post-migration validation

---

**Version**: 1.0  
**Last Updated**: 2026-01-22  
**Status**: Ready for Implementation
