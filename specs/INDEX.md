# 📋 Specifications Index

GitHub Spec Kit integration for JobSite Infrastructure specifications.

**[→ Quick Start Guide](QUICKSTART.md)** | **[→ Spec Kit Docs](../SPECS.md)**

---

## 🎯 Features & Specifications

### 001: Network Redesign

**Status**: ✅ Ready to Execute  
**Effort**: 10-15 hours  
**Team**: 1-2 people

Azure VNet redesign for production-ready infrastructure:

- VNet expansion: 10.50.0.0/24 → 10.50.0.0/21 (8x capacity)
- Proper subnet sizing per Azure best practices
- Support for Application Gateway v2, AKS, Container Apps
- 44% capacity reserved for future growth

**Documents**:

- 📄 [Specification (What)](001-network-redesign/spec.md) - Requirements & user stories
- 📋 [Plan (How)](001-network-redesign/plan.md) - Architecture & tech stack
- 🎓 [Constitution](001-network-redesign/constitution.md) - Quality standards
- ✅ [Tasks](001-network-redesign/tasks.md) - 13 actionable tasks (Phases 1-4)
- 🔧 [Implementation](001-network-redesign/implementation.md) - Step-by-step commands

**Key Changes**:

```
Before:
├─ VNet: 10.50.0.0/24 (256 IPs)
├─ 7 × /27 subnets (32 IPs each)
└─ 100% utilized, NO growth buffer ❌

After:
├─ VNet: 10.50.0.0/21 (2,048 IPs)
├─ Subnets sized per Azure best practices
├─ App Gateway: /24 (Microsoft recommendation)
├─ AKS: /23 (production scale)
└─ 44% reserved buffer ✅
```

---

### 002: Infrastructure Reorganization

**Status**: ✅ Spec & Plan Ready  
**Effort**: 6-8 hours  
**Team**: Infra + DevOps

Fix RG placement, add App Gateway WFE, and isolate build agents:

- Move Container Apps Environment to jobsite-paas-dev-rg
- Create jobsite-agents-dev-rg and move GitHub Runner VMSS there
- Add Application Gateway v2 (WAF_v2) + public IP in jobsite-iaas-dev-rg
- Keep shared networking (VNet, KV, LAW, ACR, subnets) in jobsite-core-dev-rg

**Documents**:

- 📄 [Specification (What)](002-infra-reorg/spec.md) - Corrected state & acceptance
- 📋 [Plan (How)](002-infra-reorg/plan.md) - Decisions, RG map, deployment approach
- 🎓 [Constitution](002-infra-reorg/constitution.md) - Principles & standards
- ✅ [Tasks](002-infra-reorg/tasks.md) - Phased tasks and AC
- 🔧 [Implementation](002-infra-reorg/implementation.md) - Commands & validation

**Key Outcomes**:

```
Target RG Map:
├─ jobsite-core-dev-rg: VNet, subnets, KV, LAW, ACR, NAT
├─ jobsite-iaas-dev-rg: App Gateway v2, public IP, Web VMSS, SQL VM
├─ jobsite-paas-dev-rg: CAE + apps, App Service/Plan, SQL DB, App Insights
└─ jobsite-agents-dev-rg: GitHub Runner VMSS
```

---

## 📚 Document Guide

### Quick Reference

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute overview, links, FAQ
- **[001-network-redesign/README.md](001-network-redesign/README.md)** - Feature status & summary

### Deep Dives

- **[spec.md](001-network-redesign/spec.md)** (6 pages)
  - Business requirements
  - User stories with acceptance criteria
  - Technical specifications
  - Open questions
- **[plan.md](001-network-redesign/plan.md)** (8 pages)
  - Architecture decisions with rationale
  - Implementation strategy
  - Risk assessment
  - Timeline & dependencies
- **[constitution.md](001-network-redesign/constitution.md)** (4 pages)
  - Project principles
  - Quality standards
  - Definition of done
  - Tools & standards

### Execution

- **[tasks.md](001-network-redesign/tasks.md)** (10 pages)
  - 13 specific tasks organized in 4 phases
  - Effort estimates
  - Acceptance criteria for each task
  - Commands and validation steps
- **[implementation.md](001-network-redesign/implementation.md)** (12 pages)
  - Pre-deployment checklist
  - Detailed deployment commands
  - Validation procedures
  - Monitoring commands
  - Troubleshooting guide
  - Rollback procedures

---

## 🚀 Getting Started

### Option 1: Quick Start (5 minutes)

```
1. Read QUICKSTART.md (this file points to it)
2. Read spec.md sections: Overview, User Stories
3. Run: Review plan.md architecture diagram
4. Jump to: tasks.md to understand effort
```

### Option 2: Full Review (30 minutes)

```
1. Read spec.md completely
2. Read plan.md completely
3. Review constitution.md standards
4. Understand each phase in tasks.md
```

### Option 3: Hands-On Execution (10-15 hours)

```
1. Follow tasks.md Phase by phase
2. Execute commands from implementation.md
3. Validate using checklists
4. Document your experience
```

---

## 📊 Specification Phases

### Phase 1: Specification (COMPLETE ✅)

Define **what** we're building:

- [x] Business requirements captured
- [x] User stories with acceptance criteria
- [x] Technical requirements defined
- [x] Constraints and assumptions documented

**Owner**: Product/Infrastructure PM  
**Duration**: Already complete

### Phase 2: Planning (COMPLETE ✅)

Define **how** we'll build it:

- [x] Architecture decisions made
- [x] Tech stack selected (Bicep, Azure CLI, PowerShell)
- [x] Implementation timeline created
- [x] Risks identified & mitigated
- [x] Cost estimates provided

**Owner**: Architecture Lead  
**Duration**: Already complete

### Phase 3: Execution (READY ⏳)

Actually **build** the specification:

- [ ] Task 1: Validation & preparation (1-2 hours)
- [ ] Task 2: Infrastructure deployment (6-8 hours)
- [ ] Task 3: Validation & testing (2-3 hours)
- [ ] Task 4: Documentation & cleanup (1-2 hours)

**Owner**: Infrastructure Engineer + DevOps Engineer  
**Duration**: 10-15 hours (1-2 person team)

### Phase 4: Completion (READY ⏳)

**Validate** and **document**:

- [ ] Acceptance criteria verified
- [ ] Architecture diagrams updated
- [ ] Runbooks created
- [ ] Team trained

**Owner**: Tech Lead + Team  
**Duration**: Included in Phase 3

---

## ✅ Status Dashboard

| Phase                | Status      | Progress | Owner          |
| -------------------- | ----------- | -------- | -------------- |
| **1: Specification** | ✅ Complete | 100%     | PM             |
| **2: Planning**      | ✅ Complete | 100%     | Architect      |
| **3: Execution**     | 🔄 Ready    | 0%       | Infra Engineer |
| **4: Completion**    | ⏳ Pending  | 0%       | Tech Lead      |

**Overall**: 50% complete (spec + plan done), ready for build phase

---

## 🎓 Key Concepts

### What is Spec-Driven Development?

Write specifications first, then code. Specifications:

- Describe the **what** (requirements) and **how** (architecture)
- Are reviewed and approved before coding starts
- Become source of truth for implementation
- Can be reused across teams and projects

### The 5-Step Process

```
1. CONSTITUTION  → Define principles & standards
2. SPECIFY       → Define what we're building
3. PLAN          → Define how we'll build it
4. TASKS         → Break plan into smaller tasks
5. IMPLEMENT     → Execute tasks per the plan
```

Our project is at step 5 (ready to execute).

### Why Use Spec Kit?

✅ Reduces rework (design errors caught early)  
✅ Better documentation (specs become reference)  
✅ Faster implementation (clear requirements)  
✅ Team alignment (everyone reads same spec)  
✅ Quality consistency (constitution ensures standards)

---

## 📖 How to Read These Documents

### For Product Managers

Read order: `spec.md` → User Stories → Acceptance Criteria

Key questions answered:

- What are we building?
- Why are we building it?
- How will we know it's successful?

### For Architects

Read order: `plan.md` → Architecture Decisions → Tech Stack

Key questions answered:

- What architecture choices did we make?
- Why those choices (with rationale)?
- What are the constraints?
- What could go wrong?

### For Engineers

Read order: `constitution.md` → `tasks.md` → `implementation.md`

Key sections:

- Quality standards to follow
- Specific tasks with acceptance criteria
- Exact commands to run
- Validation procedures
- Troubleshooting guide

### For QA/Testing

Read order: `spec.md` (Acceptance Criteria) → `tasks.md` (Task AC) → `implementation.md` (Validation)

Key focus:

- All acceptance criteria from spec covered?
- Are validations in tasks adequate?
- Can we automate the checks?

---

## 🔗 Cross-References

**From spec.md**:

- → `plan.md` for implementation approach
- → `constitution.md` for quality standards
- → `tasks.md` for effort estimates

**From plan.md**:

- → `spec.md` for requirements being addressed
- → `constitution.md` for principles applied
- → `tasks.md` for detailed steps

**From tasks.md**:

- → `implementation.md` for actual commands
- → `spec.md` for acceptance criteria
- → `constitution.md` for quality checks

**From implementation.md**:

- → `tasks.md` for task context
- → `spec.md` for validation criteria
- → `constitution.md` for quality standards

---

## 🎯 Success Criteria

### Specification Phase ✅

- [x] All requirements documented
- [x] User stories with AC criteria
- [x] Open questions identified
- [x] Team alignment confirmed

### Planning Phase ✅

- [x] Architecture designed with rationale
- [x] Tech stack selected and justified
- [x] Risks identified with mitigations
- [x] Timeline and effort estimated

### Execution Phase (NEXT)

- [ ] Tasks completed in order
- [ ] Acceptance criteria validated
- [ ] All validations passing
- [ ] Documentation updated

### Completion Phase

- [ ] Architecture diagrams finalized
- [ ] Runbooks created
- [ ] Team trained
- [ ] Lessons learned documented

---

## 🛠️ Tools Required

- **Azure CLI** - Cloud resource management
- **PowerShell** - Deployment automation
- **Bicep** - Infrastructure as Code
- **Git** - Version control
- **Text Editor** - Read specifications

---

## 📞 Support & Questions

| **Question Type**        | **Answer Location**                   |
| ------------------------ | ------------------------------------- |
| What are we building?    | `spec.md` → Overview                  |
| Why this design?         | `plan.md` → Architecture Decisions    |
| What are the rules?      | `constitution.md` → Quality Standards |
| How do I execute task X? | `tasks.md` → Task Description         |
| How do I run command Y?  | `implementation.md` → Commands        |

---

## 📋 Artifact Checklist

### Specification Artifacts

- [x] spec.md (6 pages, 2,000+ words)
- [x] constitution.md (4 pages, 1,000+ words)
- [x] README.md (feature overview)

### Planning Artifacts

- [x] plan.md (8 pages, 2,500+ words)
- [x] NETWORK_REDESIGN.md (migration guide)
- [x] Updated Bicep templates (core-resources.bicep, main.bicep)

### Execution Artifacts (Ready)

- [x] tasks.md (10 pages, 3,000+ words, 13 tasks)
- [x] implementation.md (12 pages, 4,000+ words, commands)
- [x] QUICKSTART.md (quick reference)
- [x] INDEX.md (this file)
- [x] SPECS.md (root level reference)

### Documentation Artifacts (Pending)

- [ ] Architecture diagrams (Mermaid format)
- [ ] Deployment runbooks
- [ ] Troubleshooting guide
- [ ] Training materials

---

## 🚀 Next Action

**You are here**: 📍 Reading specifications  
**Next step**: Choose your path:

```
If reviewing:
  → Read QUICKSTART.md (5 min)
  → Read spec.md (15 min)
  → Read plan.md (15 min)
  → Decision: Approve or feedback?

If executing:
  → Read tasks.md Phase 1 (30 min)
  → Execute Task 1.1-1.3 (1-2 hours)
  → Move to Phase 2 tasks
  → Follow implementation.md for commands

If extending:
  → Review constitution.md standards
  → Create new spec/plan following same format
  → Add to this index
```

---

**Version**: 1.0  
**Last Updated**: 2026-01-21  
**Status**: ✅ Ready for Execution  
**Maintained By**: Infrastructure Team

---

## 📚 Additional Resources

- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [Spec-Driven Development Guide](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Networking Best Practices](https://learn.microsoft.com/en-us/azure/networking/bpa)

---

_Built with Spec Kit to deliver production-grade infrastructure with clarity, quality, and repeatability._
