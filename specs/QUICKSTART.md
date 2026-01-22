# Spec Kit Integration - Quick Reference

## 📋 Feature Status

| Feature                   | Spec | Plan | Tasks | Impl | Status           |
| ------------------------- | ---- | ---- | ----- | ---- | ---------------- |
| **001: Network Redesign** | ✅   | ✅   | ✅    | ✅   | Ready to Execute |

---

## 🎯 Quick Links

### For Reading First

1. **What?** → Read [spec.md](001-network-redesign/spec.md)
2. **Why?** → Read business requirements & user stories in spec
3. **How?** → Read [plan.md](001-network-redesign/plan.md)

### For Understanding Standards

→ Read [constitution.md](001-network-redesign/constitution.md)

### For Doing Work

1. **What tasks?** → Read [tasks.md](001-network-redesign/tasks.md)
2. **How to execute?** → Read [implementation.md](001-network-redesign/implementation.md)

---

## 🚀 Feature: Network Redesign (001)

**What**: Azure VNet redesign from /24 → /21 (8x capacity)

**Why**: Current network too small, blocks scaling, violates best practices

**Key Changes**:

- ✅ VNet: 10.50.0.0/24 → 10.50.0.0/21 (256 → 2,048 IPs)
- ✅ App Gateway subnet: /27 → /24 (Microsoft recommendation)
- ✅ AKS subnet: /27 → /23 (production scale)
- ✅ VMSS: moved to snet-gh-runners (correct subnet)
- ✅ 44% IP space reserved for growth

**Effort**: 10-15 hours (1-2 person team)

**Status**:

```
Specification: ✅ Complete
Plan: ✅ Complete
Tasks: ✅ Broken down
Implementation: ✅ Ready to execute
```

---

## 📁 File Structure

```
specs/
├── 001-network-redesign/
│   ├── README.md              ← Feature overview
│   ├── constitution.md        ← Quality standards
│   ├── spec.md                ← What we're building
│   ├── plan.md                ← How we'll build it
│   ├── tasks.md               ← 13 actionable tasks
│   └── implementation.md       ← Step-by-step commands
├── [more features...]
└── SPECS.md                   ← This file
```

---

## 🔄 Workflow Overview

```
1. SPECIFICATION PHASE
   ├─ Read spec.md (requirements, user stories)
   ├─ Read constitution.md (quality standards)
   └─ Get team alignment

2. PLANNING PHASE
   ├─ Read plan.md (architecture, tech stack)
   ├─ Review decisions and rationale
   └─ Verify approach with team

3. EXECUTION PHASE
   ├─ Read tasks.md (13 specific tasks)
   ├─ Follow implementation.md (commands & steps)
   ├─ Validate at each checkpoint
   └─ Update documentation

4. COMPLETION PHASE
   ├─ Run validation checklist
   ├─ Document lessons learned
   ├─ Update architecture diagrams
   └─ Mark feature as DONE
```

---

## 🛠️ Using Spec Kit Commands

If using an AI coding agent (Cursor, Copilot, etc.):

### Core Commands

```
/speckit.constitution  - Create/review project principles
/speckit.specify       - Define requirements
/speckit.plan          - Create implementation plan
/speckit.tasks         - Break into actionable tasks
/speckit.implement     - Execute all tasks
```

### Optional Commands

```
/speckit.clarify       - Clarify underspecified areas
/speckit.analyze       - Cross-check consistency
/speckit.checklist     - Generate quality validation
```

---

## 📊 Network Redesign Summary

### Current State (Before)

```
VNet: 10.50.0.0/24 (256 IPs total)
├── 7 subnets, each /27 (32 IPs)
└── 100% utilized, 0% buffer → BLOCKER
```

### Target State (After)

```
VNet: 10.50.0.0/21 (2,048 IPs total)
├── snet-fe: 10.50.0.0/24 (251 usable) - App Gateway v2
├── snet-data: 10.50.1.0/26 (59 usable) - SQL VMs
├── snet-gh-runners: 10.50.1.64/26 (59 usable) - Build agents
├── snet-pe: 10.50.1.128/27 (27 usable) - Private endpoints
├── GatewaySubnet: 10.50.1.160/27 (27 usable) - VPN Gateway
├── snet-aks: 10.50.2.0/23 (507 usable) - AKS nodes
├── snet-ca: 10.50.4.0/26 (59 usable) - Container Apps
└── RESERVED: 10.50.4.64-10.50.7.255 (896 IPs) - Future growth

Allocated: 1,152 IPs (56%)
Reserved: 896 IPs (44%) ✓ Proper buffer
```

### Key Benefits

✅ App Gateway can scale to 125 instances  
✅ AKS can support 250+ nodes  
✅ 44% growth capacity (no redesign for 3-5 years)  
✅ Follows all Microsoft best practices  
✅ Zero additional Azure cost

---

## ✅ Acceptance Criteria

### Functional

- [ ] VNet 10.50.0.0/21 created
- [ ] All 7 subnets with correct CIDRs
- [ ] No IP conflicts
- [ ] Bicep templates validate

### Performance

- [ ] VNet creation < 2 minutes
- [ ] Full stack deploy < 15 minutes
- [ ] No latency degradation

### Security

- [ ] No hardcoded credentials
- [ ] All secrets in Key Vault
- [ ] NSGs properly configured
- [ ] Audit logging enabled

### Documentation

- [ ] Architecture diagrams updated
- [ ] Deployment guide written
- [ ] Troubleshooting guide created
- [ ] Team trained

---

## 🚨 Known Risks & Mitigations

| Risk                       | Mitigation                          |
| -------------------------- | ----------------------------------- |
| VMSS network profile fails | Use networkApiVersion: '2023-05-01' |
| IP conflict                | Task 1.2 validates all CIDRs        |
| NSG rules too restrictive  | Task 3.1 validates connectivity     |
| Long deployment            | Deploy Core/IaaS/PaaS in parallel   |
| Data loss                  | Task 1.2 creates backups            |

**Fallback**: Keep old /24 network as fallback if needed

---

## 📞 Common Questions

**Q: How much does this cost?**  
A: $0 additional - VNet/subnet resizing is free. Compute costs unchanged.

**Q: How long to deploy?**  
A: 2-4 hours for fresh start (dev environment). Includes validation & docs.

**Q: Can we rollback?**  
A: Yes - keep old network or redeploy from Bicep in 15 minutes.

**Q: What if VMSS deploys to wrong subnet?**  
A: Fixed in iaas-resources.bicep - uses githubRunnersSubnetId now.

**Q: What about downtime?**  
A: For dev: Zero downtime (fresh start). For prod: Minimal with blue-green.

---

## 📚 References

- [Spec Kit Repo](https://github.com/github/spec-kit)
- [Spec-Driven Development Guide](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Microsoft VNet Best Practices](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-network)
- [App Gateway v2 Sizing](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure)
- [AKS Networking](https://learn.microsoft.com/en-us/azure/aks/concepts-network)

---

## 🎓 Learning Path

**New to Spec Kit?**

1. Read: [Spec-Driven Development](https://github.com/github/spec-kit/blob/main/spec-driven.md)
2. Watch: [Video Overview](https://www.youtube.com/watch?v=a9eR1xsfvHg)
3. Practice: Use `/speckit.constitution` command

**New to this project?**

1. Read: `SPECS.md` (this file)
2. Read: `specs/001-network-redesign/spec.md`
3. Read: `specs/001-network-redesign/plan.md`
4. Execute: Tasks from `specs/001-network-redesign/tasks.md`

---

## 🎯 Next Steps

Choose your path:

### Path A: Review & Understand

```
1. Read SPECS.md (this file)
2. Read 001-network-redesign/spec.md
3. Read 001-network-redesign/plan.md
4. Review constitution.md
→ Ready for tasks & implementation
```

### Path B: Quick Execute (If experienced with Bicep/Azure)

```
1. Skim spec.md (2 min)
2. Skim plan.md (3 min)
3. Follow tasks.md strictly (10-15 hours work)
4. Execute implementation.md commands
5. Validate using checklist
→ Network redesigned & documented
```

### Path C: Use Spec Kit Commands (If using AI agent)

```
1. /speckit.clarify (ask any unclear questions)
2. /speckit.tasks (break spec into tasks)
3. /speckit.implement (execute automatically)
4. /speckit.analyze (validate completeness)
→ Most of work automated
```

---

## 📝 Document Ownership

| Document          | Owner                   | Review            |
| ----------------- | ----------------------- | ----------------- |
| spec.md           | Product/Infra PM        | Architecture Lead |
| plan.md           | Architecture Lead       | Security & DevOps |
| constitution.md   | Engineering Lead        | Quality Lead      |
| tasks.md          | DevOps Engineer         | Tech Lead         |
| implementation.md | Infrastructure Engineer | Tech Lead         |

---

**Version**: 1.0  
**Last Updated**: 2026-01-21  
**Status**: ✅ Ready for Implementation

---

## 🚀 Let's Build!

Your infrastructure is ready for a production-grade network redesign.

**Next command**: Read `specs/001-network-redesign/tasks.md` and follow the task breakdown.

Questions? Review the relevant document:

- **What should we build?** → spec.md
- **Why this design?** → plan.md
- **What are the rules?** → constitution.md
- **How to execute?** → tasks.md & implementation.md
