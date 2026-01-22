# Specifications Framework

**Framework**: GitHub Spec Kit (Spec-Driven Development)  
**Purpose**: Structured approach to designing and building features  
**Status**: Framework active and ready for new features

---

## 📖 How to Use

### The 5-Step Specification Process

Every feature follows this structure:

```
1. spec.md           → What are we building? (Requirements & user stories)
   ↓
2. plan.md          → How will we build it? (Architecture & decisions)
   ↓
3. constitution.md  → What are our quality standards? (Principles & definition of done)
   ↓
4. tasks.md         → What are the specific tasks? (Actionable work items)
   ↓
5. implementation.md → How do we execute? (Step-by-step commands)
```

### Finding Information

| Question              | File                | Purpose                                                    |
| --------------------- | ------------------- | ---------------------------------------------------------- |
| What are we building? | `spec.md`           | Business requirements, user stories, acceptance criteria   |
| Why this approach?    | `plan.md`           | Architecture decisions, rationale, alternatives considered |
| What quality?         | `constitution.md`   | Principles, standards, definition of done, tools           |
| What to do?           | `tasks.md`          | 13-20 specific tasks with effort estimates and phases      |
| How to build it?      | `implementation.md` | Exact commands, validation procedures, troubleshooting     |
| Status?               | `README.md`         | Feature status, blockers, when each phase is ready         |

---

## 🎯 Current Features

### 001: Network Redesign

**Status**: ✅ Spec & Plan Complete → Ready for Tasks

**Location**: `001-network-redesign/`

**What**: Azure VNet redesign from /24 (256 IPs) to /21 (2,048 IPs)

**Why**:

- Current network has zero growth capacity
- Subnet sizes violate Azure best practices for App Gateway v2 and AKS
- Need 3-5 year growth runway

**Key Improvements**:

- VNet 8x larger (256 → 2,048 IPs)
- All subnets properly sized per Microsoft recommendations
- 44% reserved for future growth
- No additional Azure costs
- Security hardened (Defender, RBAC, Private Endpoints, Key Vault)

**Effort**: 10-15 hours (1-2 person team)

**Files**:

- ✅ [spec.md](001-network-redesign/spec.md) - 4 user stories, 6 requirement categories
- ✅ [plan.md](001-network-redesign/plan.md) - 7 architecture decisions with rationale
- ✅ [constitution.md](001-network-redesign/constitution.md) - 6 principles, quality standards
- ✅ [tasks.md](001-network-redesign/tasks.md) - 13 tasks across 4 phases
- ✅ [implementation.md](001-network-redesign/implementation.md) - 100+ deployment commands
- ✅ [README.md](001-network-redesign/README.md) - Feature status dashboard

---

### 002: Infrastructure Reorganization

**Status**: ✅ Spec & Plan Ready → Ready for Tasks

**Location**: `002-infra-reorg/`

**What**: Fix RG placement, add App Gateway WFE, isolate build agents, keep core networking shared.

**Why**:

- Container Apps must live in PaaS RG for lifecycle/cost separation
- Build agents need their own RG for isolation and scaling
- Web tier lacks an HTTP/HTTPS front door with WAF
- Preserve 4-layer model for ownership and security

**Key Improvements**:

- jobsite-paas-dev-rg hosts CAE and apps (moved from core)
- jobsite-agents-dev-rg hosts GitHub Runner VMSS (moved from iaas)
- jobsite-iaas-dev-rg gains Application Gateway v2 (WAF_v2) + public IP
- jobsite-core-dev-rg remains shared networking (VNet, KV, LAW, ACR)

**Effort**: 6-8 hours (1-2 person team)

**Files**:

- ✅ [spec.md](002-infra-reorg/spec.md) - Corrected state & acceptance
- ✅ [plan.md](002-infra-reorg/plan.md) - RG map, WFE, build isolation
- ✅ [constitution.md](002-infra-reorg/constitution.md) - Principles & standards
- ✅ [tasks.md](002-infra-reorg/tasks.md) - Phased tasks and AC
- ✅ [implementation.md](002-infra-reorg/implementation.md) - Commands & validation
- ✅ [README.md](002-infra-reorg/README.md) - Status snapshot

---

## 🚀 Quick Start by Role

### Product Manager / Project Lead

**Read first**: [001-network-redesign/spec.md](001-network-redesign/spec.md)

**Questions answered**:

- What is being built? → Overview section
- Why? → Business Requirements section
- When? → Status in README.md
- How much effort? → Tasks section has effort estimates
- What's the risk? → Plan section has risk assessment

**Time**: 15 minutes

---

### Solution Architect / Tech Lead

**Read first**: [001-network-redesign/plan.md](001-network-redesign/plan.md)

**Questions answered**:

- What's the design? → Architecture Decisions section
- Why this design? → Each decision has detailed rationale
- What were the alternatives? → Alternatives Considered section
- What are the constraints? → spec.md Design Constraints section
- What quality standards apply? → constitution.md

**Time**: 30 minutes

---

### Infrastructure Engineer / DevOps

**Read first**: [001-network-redesign/tasks.md](001-network-redesign/tasks.md)

**Questions answered**:

- What do I need to do? → 13 specific tasks in 4 phases
- How long will it take? → Effort estimate for each task
- What's the order? → Phase 1 → Phase 2 → Phase 3 → Phase 4
- How do I do it? → See implementation.md for exact commands
- What could go wrong? → constitution.md has standards, implementation.md has troubleshooting

**Time**: 45 minutes to review, 10-15 hours to execute

---

### Developer / Security Engineer

**Read first**: [001-network-redesign/constitution.md](001-network-redesign/constitution.md)

**Questions answered**:

- What standards apply? → 6 core principles
- What's the definition of done? → Quality standards section
- What tools should we use? → Tools & Standards section
- What are we building? → See spec.md
- How do we build it? → See plan.md and implementation.md

**Time**: 20 minutes

---

## 📋 Feature Template

To create a new feature, copy this structure:

```
specs/
└── 002-feature-name/
    ├── README.md            # Status dashboard
    ├── spec.md              # What + Why
    ├── plan.md              # Architecture
    ├── constitution.md      # Quality standards
    ├── tasks.md             # Task breakdown
    └── implementation.md    # How-to guide
```

**Each file should contain**:

### spec.md (500-800 lines)

- Feature overview
- Business requirements (categorized)
- User stories with acceptance criteria
- Design constraints (must, should, out of scope)
- Technical requirements
- Success metrics

### plan.md (700-1000 lines)

- Architecture overview (diagrams)
- Architecture decisions (3-7 decisions with rationale)
- Alternatives considered
- Risk assessment
- Effort estimate (phases with hours)
- Timeline

### constitution.md (300-500 lines)

- Core principles (3-6 principles)
- Quality standards (code, security, docs)
- Definition of done
- Tools & technologies
- Process steps

### tasks.md (800-1200 lines)

- Task breakdown in phases (2-4 phases)
- Each task with: ID, title, description, effort, acceptance criteria
- Dependencies between tasks
- Success criteria for each phase

### implementation.md (1000-1500 lines)

- Pre-implementation checklist
- Step-by-step execution (with actual commands)
- Validation procedures for each step
- Common issues & troubleshooting
- Rollback procedures

### README.md (200-300 lines)

- Feature status dashboard
- Key metrics (lines of code, test coverage, etc.)
- Blockers / open questions
- Timeline and completion percentage
- Quick links to each document

---

## 🔍 How to Review a Specification

### For Approval (1 hour)

1. **Read spec.md** (20 min)
   - Does it match business needs?
   - Are all requirements captured?
   - Are user stories clear?

2. **Read plan.md** (20 min)
   - Is the architecture sound?
   - Are decisions well-reasoned?
   - Are there hidden risks?

3. **Review tasks.md** (20 min)
   - Is the effort estimate realistic?
   - Is the phase breakdown sensible?
   - Are there dependencies on other work?

4. **Decision**: Approve or request changes

### For Detailed Review (2 hours)

Follow the same steps as above, plus:

5. **Read constitution.md** (15 min)
   - Are quality standards appropriate?
   - Are the tools/technologies correct?

6. **Review implementation.md** (20 min)
   - Are the commands correct?
   - Are validation procedures thorough?
   - Is the troubleshooting guide complete?

7. **Q&A**: Schedule discussion to clarify

---

## 📊 Index of All Specs

### Active Features

| Feature               | Status             | Link                                         | Effort | Lead         |
| --------------------- | ------------------ | -------------------------------------------- | ------ | ------------ |
| 001: Network Redesign | ✅ Ready for Tasks | [001-network-redesign](001-network-redesign) | 10-15h | Architecture |
| (Next feature)        | 📋 Planned         | TBD                                          | TBD    | TBD          |

---

## 🎓 Learning Resources

### Understanding Spec-Driven Development

- [REVERSE_ENGINEERING_PROCESS.md](../REVERSE_ENGINEERING_PROCESS.md) - How this process was discovered
- [001-network-redesign/spec.md](001-network-redesign/spec.md) - Example of complete spec
- [001-network-redesign/plan.md](001-network-redesign/plan.md) - Example of detailed plan

### GitHub Spec Kit

- Official: [github.com/github/spec-kit](https://github.com/github/spec-kit)
- Documentation: Included in SPECS.md

---

## ✅ Quality Checklist

### Before Submitting a Specification

- [ ] spec.md: All business requirements captured
- [ ] spec.md: At least 3-4 user stories with AC
- [ ] spec.md: Design constraints (must/should/out of scope)
- [ ] spec.md: Success metrics defined
- [ ] plan.md: Architecture diagrams included
- [ ] plan.md: 3-7 architecture decisions documented
- [ ] plan.md: Alternatives considered section included
- [ ] plan.md: Risk assessment with 5+ identified risks
- [ ] constitution.md: 3-6 core principles defined
- [ ] constitution.md: Quality standards for code/security/docs
- [ ] tasks.md: 10-20 tasks with effort estimates
- [ ] tasks.md: Tasks organized in 2-4 phases
- [ ] tasks.md: Dependencies identified
- [ ] implementation.md: 50+ commands documented
- [ ] implementation.md: Validation procedures for key steps
- [ ] implementation.md: Troubleshooting section with 5+ issues
- [ ] README.md: Status dashboard complete
- [ ] README.md: Links to all documents work

---

## 🔗 Navigation

- **Back to Project**: [../README.md](../README.md)
- **All Documents**: [../HOW_TO_NAVIGATE.md](../HOW_TO_NAVIGATE.md)
- **Choose Your Role**: [QUICKSTART.md](QUICKSTART.md)

---

**Last Updated**: 2026-01-21  
**Framework Status**: Active and ready for new features
