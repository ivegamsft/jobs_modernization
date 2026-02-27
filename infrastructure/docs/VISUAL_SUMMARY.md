# Infrastructure Reorganization - Visual Summary

**At a Glance: What Changed, Why, and How**

---

## The 3 Problems (Current State)

```
┌─────────────────────────────────────────────────────────────────┐
│                   CURRENT (WRONG) ARCHITECTURE                  │
└─────────────────────────────────────────────────────────────────┘

🔴 PROBLEM #1: Container Apps in Wrong RG
┌──────────────────────────────────┐
│   jobsite-core-dev-rg            │
│   (Should be infrastructure)     │
├──────────────────────────────────┤
│ ✓ Virtual Network                │
│ ✓ Key Vault                      │
│ ✓ Log Analytics                  │
│ ✓ Container Registry             │
│ ❌ Container Apps Env ← WRONG!   │  Should be in PaaS RG
│ ❌ Container Apps instances      │
└──────────────────────────────────┘

🔴 PROBLEM #2: Build Agents in App Tier RG
┌──────────────────────────────────┐
│   jobsite-iaas-dev-rg            │
│   (Should be long-lived VMs)     │
├──────────────────────────────────┤
│ ✓ Web VMSS (long-lived)          │
│ ✓ SQL VM (long-lived)            │
│ ❌ Build VMSS (ephemeral) ← ?    │  Should be in separate RG
│ ❌ NICs & Disks                  │
└──────────────────────────────────┘

🔴 PROBLEM #3: No Web Front End (WFE)
┌──────────────────────────────────┐
│   jobsite-iaas-dev-rg            │
├──────────────────────────────────┤
│ ❌ NO Application Gateway        │  Missing HTTP/HTTPS ingress!
│ ❌ NO Public IP (WFE)            │  Missing load balancer!
│ ❌ NO WAF protection             │  Missing security!
│ ✓ Web VMSS (no load balancing)   │
│ ✓ SQL VM                         │
└──────────────────────────────────┘

❌ jobsite-agents-dev-rg  ← MISSING (doesn't exist)
```

---

## The Solution (Target State)

```
┌─────────────────────────────────────────────────────────────────┐
│                  CORRECTED (RIGHT) ARCHITECTURE                 │
│                         4-LAYER MODEL                           │
└─────────────────────────────────────────────────────────────────┘

✅ LAYER 1: Core Infrastructure (jobsite-core-dev-rg)
┌──────────────────────────────────┐
│  SHARED NETWORKING & SERVICES    │  Owner: Network Team
├──────────────────────────────────┤  Changes: Quarterly or less
│ ✅ Virtual Network (10.50.0.0/21)│
│ ✅ 7 Subnets                     │
│ ✅ Key Vault                     │
│ ✅ Log Analytics Workspace       │
│ ✅ Container Registry            │
│ ✅ NAT Gateway + Public IP       │
│ ✅ Private DNS Zones             │
└──────────────────────────────────┘
         ↓ (all other layers depend on this)

┌─────────────────┬────────────────┬─────────────────┐
│                 │                │                 │
│                 │                │                 │
v                 v                v                 v

✅ LAYER 2:      ✅ LAYER 3:      ✅ LAYER 4:
IaaS             PaaS             Agents (NEW)
jobsite-         jobsite-         jobsite-
iaas-dev-rg      paas-dev-rg      agents-dev-rg

Owner: Ops Team  Owner: Dev Team  Owner: CI/CD Team
Changes: Qty     Changes: Weekly  Changes: Hourly
Manual Scale     Auto Scale       Queue-based Scale

┌─────────────────┐ ┌────────────────┐ ┌──────────────────┐
│ APP TIER VMs    │ │ MANAGED        │ │ BUILD            │
│ & LOAD BALANCER │ │ SERVICES       │ │ INFRASTRUCTURE   │
├─────────────────┤ ├────────────────┤ ├──────────────────┤
│ ✅ App Gateway  │ │ ✅ Container   │ │ ✅ Build Agent   │
│    v2 (WFE)     │ │    Apps Env    │ │    VMSS (NEW)    │
│ ✅ Public IP    │ │ ✅ Container   │ │ ✅ NICs          │
│ ✅ Web VMSS     │ │    Apps        │ │ ✅ Disks         │
│ ✅ SQL VM       │ │ ✅ App Service │ │                  │
│ ✅ NICs & Disks │ │    Plan        │ │ Connected to:    │
│                 │ │ ✅ App Service │ │ snet-gh-runners  │
│ Subnets:        │ │ ✅ SQL Database│ │ (in Core VNet)   │
│ - snet-fe       │ │ ✅ App Insights│ │                  │
│ - snet-app      │ │                │ │ Outbound via:    │
│ - snet-db       │ │ Subnet:        │ │ NAT Gateway      │
│                 │ │ snet-managed   │ │ (in Core RG)     │
└─────────────────┘ └────────────────┘ └──────────────────┘
```

---

## Resource Movement Map

```
BEFORE                          AFTER

Core RG:                        Core RG:
├─ VNet          ──────────→   ├─ VNet ✓
├─ Subnets       ──────────→   ├─ Subnets ✓
├─ Key Vault     ──────────→   ├─ Key Vault ✓
├─ LAW           ──────────→   ├─ LAW ✓
├─ ACR           ──────────→   ├─ ACR ✓
├─ NAT           ──────────→   ├─ NAT ✓
└─ Container Apps ──X──→ PaaS RG

IaaS RG:                        IaaS RG:
├─ Web VMSS      ──────────→   ├─ App Gateway v2 (NEW) ✅
├─ SQL VM        ──────────→   ├─ Public IP (NEW) ✅
├─ NICs          ──────────→   ├─ Web VMSS ✓
└─ Disks         ──────────→   ├─ SQL VM ✓
                                ├─ NICs ✓
PaaS RG:                        └─ Disks ✓
├─ (mostly empty)
                                PaaS RG:
Agents RG:                      ├─ Container Apps Env ✅ (moved)
├─ (doesn't exist)              ├─ Container Apps ✅ (moved)
                                ├─ App Service Plan ✓
                                ├─ App Service ✓
                                ├─ SQL Database ✓
                                └─ App Insights ✓

                                Agents RG: (NEW)
                                ├─ Build VMSS ✅ (moved)
                                ├─ NICs ✅ (moved)
                                └─ Disks ✅ (moved)
```

---

## Architecture Changes Explained

### Change 1: Application Gateway v2 (WFE) - ADDED

```
BEFORE (No Load Balancer):          AFTER (With App Gateway):
┌─────────────────────────────┐     ┌─────────────────────────────┐
│                             │     │     INTERNET                │
│  Web VMSS                   │     │         ↓                   │
│  (no load balancing)        │     │   Public IP                 │
│                             │     │    (App GW)                 │
│  Users randomly hit         │     │         ↓                   │
│  whichever VM               │     │  App Gateway v2 (WAF_v2)    │
│                             │     │  • Load balancing ✓         │
│  Manual traffic routing     │     │  • SSL/TLS termination ✓    │
│  No WAF protection          │     │  • WAF rules (OWASP 3.1) ✓  │
│                             │     │  • Health probes ✓          │
│                             │     │  • Auto-scaling 2-10 ✓      │
│                             │     │         ↓                   │
│                             │     │  Web VMSS                   │
│                             │     │  (proper load balancing)    │
└─────────────────────────────┘     └─────────────────────────────┘
        Problem!                             Solution! ✓
```

### Change 2: Build Agents Isolated - REORGANIZED

```
BEFORE (Mixed):                     AFTER (Isolated):
┌────────────────────────────┐      ┌────────────────────────────┐
│  jobsite-iaas-dev-rg       │      │  jobsite-iaas-dev-rg       │
├────────────────────────────┤      ├────────────────────────────┤
│ Web VMSS (long-lived)      │      │ Web VMSS (long-lived) ✓    │
│ SQL VM (long-lived)        │      │ SQL VM (long-lived) ✓      │
│ Build VMSS (ephemeral) ❌  │      │ App Gateway (WFE) ✓        │
│                            │      │ Public IP (WFE) ✓          │
│ Different lifecycle:       │      │                            │
│ - Weekly updates           │      │ Consistent lifecycle:      │
│ - Manual scaling           │      │ - Quarterly updates        │
│ - Long running             │      │ - Manual scaling           │
│                            │      │ - Long running             │
└────────────────────────────┘      └────────────────────────────┘
        Problem!                     ┌────────────────────────────┐
                                    │  jobsite-agents-dev-rg     │
                                    ├────────────────────────────┤
                                    │ Build VMSS (ephemeral) ✓   │
                                    │ NICs, Disks ✓              │
                                    │                            │
                                    │ Different lifecycle:       │
                                    │ - Hourly creation/destroy  │
                                    │ - Queue-based scaling      │
                                    │ - Temporary                │
                                    │                            │
                                    │ Connected via:             │
                                    │ snet-gh-runners (core)     │
                                    │ NAT Gateway outbound       │
                                    └────────────────────────────┘
                                           Solution! ✓
```

### Change 3: Container Apps Moved - REORGANIZED

```
BEFORE (Mixed):                     AFTER (Proper):
┌────────────────────────────┐      ┌────────────────────────────┐
│  jobsite-core-dev-rg       │      │  jobsite-core-dev-rg       │
├────────────────────────────┤      ├────────────────────────────┤
│ VNet + Subnets ✓           │      │ VNet + Subnets ✓           │
│ Key Vault ✓                │      │ Key Vault ✓                │
│ Log Analytics ✓            │      │ Log Analytics ✓            │
│ Container Registry ✓       │      │ Container Registry ✓       │
│ NAT Gateway ✓              │      │ NAT Gateway ✓              │
│ Container Apps Env ❌      │      │                            │
│ Container Apps ❌          │      │ Infrastructure layer only  │
│                            │      │ (rarely changes)           │
│ Mixed: Infrastructure +    │      └────────────────────────────┘
│ PaaS Services              │      ┌────────────────────────────┐
└────────────────────────────┘      │  jobsite-paas-dev-rg       │
        Problem!                    ├────────────────────────────┤
                                    │ Container Apps Env ✓       │
                                    │ Container Apps ✓           │
                                    │ App Service Plan ✓         │
                                    │ App Service ✓              │
                                    │ SQL Database ✓             │
                                    │ App Insights ✓             │
                                    │                            │
                                    │ Managed services layer     │
                                    │ (frequent changes,         │
                                    │ auto-scaling)              │
                                    └────────────────────────────┘
                                           Solution! ✓
```

---

## Timeline & Effort

```
┌─────────────────────────────────────────────────────────────────┐
│                    MIGRATION SCHEDULE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ DAY 1 - PREPARATION (1-2 hours)                               │
│ ├─ Create resource groups                                      │
│ ├─ Backup current configuration                                │
│ └─ Document network info                                       │
│                                                                 │
│ DAY 1-2 - CREATE MISSING RESOURCES (2-3 hours)                 │
│ ├─ Deploy Application Gateway v2 to iaas-rg                    │
│ └─ Prepare PaaS RG for Container Apps                          │
│                                                                 │
│ DAY 2 - MOVE RESOURCES (2-4 hours)                             │
│ ├─ Move Container Apps: core → paas                            │
│ └─ Move Build VMSS: iaas → agents                              │
│                                                                 │
│ DAY 2-3 - VALIDATE (1-2 hours)                                 │
│ ├─ Network connectivity tests                                  │
│ ├─ Resource group verification                                 │
│ └─ Application functionality tests                             │
│                                                                 │
│ TOTAL: 8-12 hours | 1-2 engineers | 3 days calendar time      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Metrics

```
╔════════════════════════════════════════════════════════════════╗
║                    BEFORE vs AFTER                             ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║ METRIC                  BEFORE           AFTER                ║
║ ─────────────────────────────────────────────────────────────
║ Resource Groups         3                4 (new agents-rg)
║ RG Organization         Misaligned       Proper 4-layer
║ Web Front End (WFE)     ❌ Missing       ✅ App Gateway v2
║ Load Balancing          Manual           Automatic
║ WAF Protection          ❌ None          ✅ OWASP 3.1
║ Build Agents Isolation  ❌ Mixed         ✅ Separate RG
║ Container Apps RG       Core (wrong)     PaaS (correct)
║ SSL/TLS Termination     ❌ None          ✅ App Gateway
║ Health Probes           ❌ None          ✅ Auto-health
║ Auto-scaling Setup      Partial          ✅ Proper per-tier
║                                                                ║
║ COST IMPACT:            $0/month         +$30/month           ║
║ EFFORT:                 -                8-12 hours           ║
║ TIMELINE:               -                3 days               ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

---

## Why 4 Layers?

```
┌─────────────────────────────────────────────────────────────────┐
│           WHY 4 LAYERS INSTEAD OF 3?                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Lifecycle Perspective:                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                         │
│  │CORE  │  │IaaS  │  │PaaS  │  │AGENTS│                         │
│  │      │  │      │  │      │  │      │                         │
│  │Rarely│  │Qty   │  │Weekly│  │Hourly│                         │
│  │Change│  │      │  │Change│  │Change│                         │
│  │      │  │Quarter│  │      │  │      │                         │
│  │      │  │Updates│  │      │  │      │                         │
│  └──────┘  └──────┘  └──────┘  └──────┘                         │
│     ↑         ↑         ↑        ↑                               │
│   6 mo      1-3 mo     1 week   1 hour                          │
│                                                                 │
│  Scaling Perspective:                                           │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                         │
│  │CORE  │  │IaaS  │  │PaaS  │  │AGENTS│                         │
│  │      │  │      │  │      │  │      │                         │
│  │Manual│  │Manual│  │Auto  │  │Queue │                         │
│  │None  │  │Capacity│Scale  │  │Scale │                         │
│  │      │  │Planning│(CPU %)│  │(Queue│                         │
│  │      │  │        │       │  │depth)│                         │
│  └──────┘  └──────┘  └──────┘  └──────┘                         │
│                                                                 │
│  Cost Tracking:                                                 │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                         │
│  │$Fixed│  │$App  │  │$PaaS │  │$CI/CD│                         │
│  │Infra │  │Tier  │  │Costs │  │Costs │                         │
│  │Costs │  │Costs │  │      │  │      │                         │
│  └──────┘  └──────┘  └──────┘  └──────┘                         │
│                                                                 │
│  RESULT: Better control, clearer responsibility, easier        │
│          automation, improved cost tracking, better RBAC        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Checklist

```
✅ INFRASTRUCTURE ORGANIZATION
  ☐ Core RG: Networking only
  ☐ IaaS RG: App tier + WFE
  ☐ PaaS RG: Managed services
  ☐ Agents RG: Build infrastructure

✅ NETWORK CONNECTIVITY
  ☐ Web ↔ Database: Connected ✓
  ☐ Public ↔ App GW: Responding ✓
  ☐ App GW ↔ Web VMSS: Health probes OK ✓
  ☐ Build agents ↔ Internet: Outbound OK ✓

✅ APPLICATION GATEWAY (WFE)
  ☐ Deployed in iaas-rg
  ☐ WAF_v2 SKU enabled
  ☐ OWASP 3.1 rules active
  ☐ Health probes healthy
  ☐ HTTP → HTTPS redirect working
  ☐ SSL/TLS termination working

✅ CONTAINER APPS
  ☐ Moved to paas-rg
  ☐ Still reachable
  ☐ Diagnostics flowing

✅ BUILD AGENTS
  ☐ Moved to agents-rg
  ☐ Auto-scaling working
  ☐ GitHub runners active
  ☐ Builds executing

✅ OPERATIONS
  ☐ Team trained
  ☐ Documentation updated
  ☐ Monitoring configured
  ☐ Alerts active
```

---

## Quick Facts

```
╔════════════════════════════════════════════════════════════════╗
║                    QUICK FACTS                                 ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  🎯 Goal: Fix 3 infrastructure organization problems          ║
║  📊 Scope: 4 resource groups, 50+ resources                   ║
║  ⏱️  Time: 8-12 hours (one team, 3 days calendar)             ║
║  💰 Cost: +$30/month (App Gateway + auto-scaling)             ║
║  📈 Effort: Low complexity, well-documented                   ║
║  🎓 Training: 2-4 hours for team                              ║
║  ⚠️  Risk: Medium (but mitigations provided)                  ║
║  ✅ Quality: Production-ready documentation                   ║
║                                                                ║
║  KEY COMPONENTS:                                              ║
║  • Application Gateway v2 (WFE)                               ║
║  • Build VMSS in separate RG                                 ║
║  • Container Apps in PaaS RG                                 ║
║  • 4-layer RG organization                                   ║
║                                                                ║
║  DELIVERABLES:                                                ║
║  • 6 comprehensive documents                                  ║
║  • 3,100+ lines of documentation                             ║
║  • 200+ lines of Bicep code                                  ║
║  • 50+ PowerShell scripts                                     ║
║  • Complete validation procedures                             ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

---

**Visual Summary Complete**

For detailed information, see:

- [4LAYER_RG_QUICK_REFERENCE.md](4LAYER_RG_QUICK_REFERENCE.md) (1-page reference)
- [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) (step-by-step execution)
- [INDEX.md](INDEX.md) (complete navigation)
