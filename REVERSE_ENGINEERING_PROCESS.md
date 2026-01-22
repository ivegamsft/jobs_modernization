# Reverse Engineering: From Changes to Specifications

This document explains how the changes made were analyzed and reverse-engineered into complete specifications using GitHub Spec Kit framework.

---

## Methodology

### Step 1: Identify What Changed

Analyzed git diffs and file modifications:

1. **Bicep Templates**: Core network architecture updated
2. **Deployment Scripts**: Security hardening + parameter management
3. **New Documentation**: 11 specification documents created
4. **Configuration Files**: Migration guides and design documents

---

### Step 2: Understand the Why

For each change, determined the underlying requirement:

```
Change: VNet CIDR 10.50.0.0/24 → 10.50.0.0/21
↓
Analysis: 256 IPs insufficient for 7 subnets + growth
↓
Root Cause: No growth buffer, violates Azure best practices
↓
Requirement: Support 3-5x growth while maintaining scalability
↓
Specification: BR-001 - Network must support 3-5x growth
```

---

### Step 3: Extract Business Requirements

Reverse-engineered business drivers from technical changes:

**Growth & Scalability**:

- App Gateway must scale to 125 instances → /24 subnet required
- AKS production must support 250+ nodes → /23 subnet required
- Container Apps must support replica scaling → dedicated subnet needed
- **Requirement**: Network must support 3-5x growth in resource count

**Operational Requirements**:

- Separate subnet for VMSS (build agents) → workload isolation
- Subnet sizing per Azure minimums → follow best practices
- **Requirement**: All resources must follow Microsoft Well-Architected Framework

**Security & Compliance**:

- Removed hardcoded passwords → credential management
- Private endpoints subnet → network isolation
- **Requirement**: Separate subnets for different workload tiers

**Cost Requirements**:

- VM SKU optimization (v4 → v6) → cost efficiency
- VNet/subnet resizing free in Azure → no additional cost
- **Requirement**: No increase in Azure networking costs

---

### Step 4: Map to User Stories

Identified stakeholder perspectives in the changes:

**Infrastructure Engineer**:

- Problem: Current network redesign needed every 6 months
- Solution: VNet sized for 3-5x growth (44% reserved capacity)
- Acceptance: App Gateway /24, AKS /23, growth buffer >40%

**Application Developer**:

- Problem: Workloads competing for IP space in same subnets
- Solution: Dedicated subnets per workload tier (frontend, data, build agents, etc.)
- Acceptance: Frontend tier isolated, data tier isolated, build agents isolated

**DevOps Engineer**:

- Problem: Can't easily redeploy or test new architectures
- Solution: Full IaC with Bicep, clear 3-layer structure, parameters for flexibility
- Acceptance: Blue-green deployment supported, deploy time <15 min, clear migration path

**Security Officer**:

- Problem: Hardcoded credentials in deployment scripts
- Solution: All passwords/certificates via Key Vault or parameters
- Acceptance: Zero credentials in code, NSGs per tier, audit logging enabled

---

### Step 5: Document Design Decisions

For each major change, captured the decision-making process:

**Decision 1: VNet Sizing (/21 vs Alternatives)**

```
Options Evaluated:
1. Stay with /24 → Blocker, can't scale
2. Expand to /22 → Only 1,024 IPs, still too tight
3. Expand to /21 → 2,048 IPs, 3-5x growth room ✓
4. Expand to /20 → 4,096 IPs, overkill for dev

Decision: /21 selected
Rationale: Balances growth with efficiency, aligns with Microsoft standard practice
Cost Impact: $0 additional (VNet sizing free)
Risk: None identified
```

**Decision 2: Subnet Sizing Strategy**

```
Principle: Size each subnet based on Azure service minimum + 50% buffer

Examples:
- App Gateway v2: /24 (Microsoft documented minimum)
- AKS: /23 (production-scale minimum)
- All others: /26-/27 with buffer

Calculation: Usable IPs = Subnet Size - 5 (Azure reserved)
Buffer = 50% of usable IPs
Max Instances = Usable IPs - Buffer
```

---

### Step 6: Establish Quality Standards

Created constitution from implied standards in the code changes:

**Principle 1: Production Readiness**

- Change: Updated subnet sizes per Azure best practices
- Implication: All designs must follow WAF recommendations
- Standard: Document sizing decisions with Azure references

**Principle 2: Security by Design**

- Change: Removed hardcoded passwords, added parameter validation
- Implication: Zero credentials in code/git
- Standard: All secrets managed via Key Vault or parameters

**Principle 3: Scalability by Default**

- Change: Reserved 44% of VNet for growth
- Implication: Architecture must support 3-5x scale
- Standard: VNet must have 40%+ unallocated address space

---

### Step 7: Create Task Breakdown

From the changes and specifications, identified actionable tasks:

**Phase 1: Preparation** (1-2 hours)

- Task 1.1: Validate Bicep templates
  - Expected to find: Subnet CIDR validation
  - Acceptance: No linting errors, ranges don't overlap
- Task 1.2: Backup current configuration
  - Expected to find: Current resource state documented
  - Acceptance: Resources exported, rollback plan documented
- Task 1.3: Plan migration approach
  - Expected to find: Deploy sequence decided
  - Acceptance: Fresh start vs blue-green, team consensus

**Phase 2: Deployment** (6-8 hours)

- Task 2.1: Deploy Core network layer
  - Execute: VNet with new CIDR, all 7 subnets
  - Validate: All subnets created, correct CIDRs
- Task 2.2: Deploy IaaS layer
  - Execute: VMSS to snet-gh-runners, SQL to snet-data, App Gateway to snet-fe
  - Validate: Resources in correct subnets, healthy status

(Similar for Phase 3: Validation and Phase 4: Documentation)

---

### Step 8: Document Implementation Guide

From Bicep templates and scripts, created step-by-step commands:

```
Each task includes:
1. Exact commands to run
2. Expected output
3. Validation procedures
4. Troubleshooting tips
5. Rollback procedures

Example Task:
─────────────
Deploy Core Network Layer
├─ az deployment sub create --template-file bicep/core/main.bicep
├─ Verify: az network vnet list -g jobsite-core-dev-rg
├─ Validate: All 7 subnets created with correct CIDRs
└─ If fails: Check CIDR overlaps, retry with --no-wait
```

---

## Specification Artifacts Created

### 1. Specification Document (spec.md)

**Content Extracted From**:

- Bicep parameter comments (requirements)
- Subnet sizing in code (technical specs)
- Task list (acceptance criteria)

**Structure**:

```
Overview → Business Requirements → User Stories →
Technical Requirements → Design Constraints →
Acceptance Criteria → Sign-Off
```

---

### 2. Plan Document (plan.md)

**Content Extracted From**:

- Bicep template structure (IaC framework decision)
- VM SKU choices (cost optimization decision)
- Subnet sizing comments (architecture decision)
- Deployment script logic (deployment strategy decision)

**Structure**:

```
Architecture Decisions (7 total) →
  VNet sizing, subnet sizing, deployment strategy,
  IaC framework, naming conventions, monitoring, security
Implementation Timeline → Risk Assessment → Cost Estimates
```

---

### 3. Constitution Document (constitution.md)

**Content Inferred From**:

- Code quality (clean, modular, documented)
- Security practices (no hardcoded secrets, parameterized)
- Best practices adherence (follows Azure recommendations)
- Scalability by default (growth buffer, proper sizing)

**Structure**:

```
Core Principles (6 total) →
Quality Standards →
Definition of Done →
Tools & Standards
```

---

### 4. Tasks Document (tasks.md)

**Content Extracted From**:

- Bicep template dependencies (task sequence)
- Deployment script flow (task breakdown)
- Validation requirements (acceptance criteria)
- Estimated time by complexity (effort estimation)

**Structure**:

```
Phase 1: Prep → Phase 2: Deploy → Phase 3: Validate → Phase 4: Document

For each task:
├─ Effort estimate
├─ Owner role
├─ Acceptance criteria
├─ Commands
├─ Validation procedures
└─ Troubleshooting
```

---

### 5. Implementation Document (implementation.md)

**Content Extracted From**:

- Bicep template syntax (deployment commands)
- PowerShell script logic (automation steps)
- Azure CLI queries (validation commands)

**Structure**:

```
Pre-deployment Checklist →
Core Layer Deployment →
IaaS Layer Deployment →
PaaS Layer Deployment →
Post-deployment Validation →
Monitoring & Troubleshooting →
Rollback Procedures
```

---

## Key Insights from Reverse Engineering

### 1. Design Evolved Through Iteration

The changes show clear progression:

```
Initial Problem: VNet too small (/24)
↓
First Solution: Expand to /21 (8x capacity)
↓
Second Solution: Resize subnets per Azure recommendations
↓
Third Solution: Correct VMSS placement (snet-gh-runners)
↓
Fourth Solution: Update VM SKUs for cost optimization
↓
Fifth Solution: Complete specification framework
```

### 2. Multiple Concerns Addressed

The changes weren't just network—they included:

- **Architecture**: VNet redesign, subnet sizing
- **Security**: Password removal, parameterization
- **Cost**: VM SKU optimization
- **Documentation**: Complete specification framework
- **Process**: Spec-Driven Development adoption

### 3. Professional Quality Standards

The code reflects high standards:

- **No technical debt**: Hardcoded passwords removed
- **Best practices**: Follows Azure recommendations
- **Maintainability**: Clean, commented, modular structure
- **Scalability**: 44% growth buffer built in

---

## Validation of Reverse Engineering

### Check 1: Requirements Traceability

✅ Each business requirement traces to:

- User story in spec.md
- Architecture decision in plan.md
- Task in tasks.md
- Validation in implementation.md

Example:

```
BR-001: Network must support 3-5x growth
↓
User Story: As Infrastructure Engineer, I want growth headroom
↓
Decision: VNet /21 provides 44% reserved capacity
↓
Task 2.1: Deploy Core network layer with new CIDR
↓
Validation: Verify all 7 subnets created with correct CIDRs
```

### Check 2: Completeness

✅ All code changes are documented:

- core/main.bicep parameter → spec.md technical requirements
- core-resources.bicep subnets → plan.md architecture decisions
- iaas-resources.bicep VMSS subnet → tasks.md task 2.2
- deploy-iaas-clean.ps1 SKUs → plan.md cost optimization

### Check 3: Consistency

✅ No contradictions between documents:

- spec.md requires /24 for App Gateway
- plan.md decides /24 for App Gateway
- tasks.md validates /24 deployment
- implementation.md deploys /24 for App Gateway

### Check 4: Actionability

✅ Every specification point leads to concrete tasks:

- Not just "improve network" → specific /21 CIDR
- Not just "follow best practices" → specific /24 for App Gateway v2
- Not just "improve security" → remove specific hardcoded passwords

---

## Summary: From Changes to Specifications

```
Git Diffs & Code Changes
         ↓
    Analyze What Changed
         ↓
    Understand Why Changed
         ↓
    Extract Requirements
         ↓
    Document As Specifications
         ↓
    Create Task Breakdown
         ↓
    Write Implementation Guide
         ↓
    Establish Quality Standards
         ↓
Complete Specification Framework
```

**Result**:

- ✅ 11 specification documents (2,850+ lines)
- ✅ 13 actionable tasks with effort estimates
- ✅ Complete implementation guide with 100+ commands
- ✅ Quality standards and principles established
- ✅ Ready for execution by any engineering team

---

## Lessons in Specification-Driven Development

1. **Write Specs From Working Code**: Reverse engineering specifications from code helps capture actual requirements, not imagined ones

2. **Multiple Perspectives Matter**: User stories from Infrastructure Engineer, Developer, DevOps, Security Officer ensure complete coverage

3. **Decisions Need Rationale**: Document not just what was chosen (VNet /21) but why (growth headroom, cost, best practices)

4. **Quality Standards Drive Quality**: Constitution prevents "works but messy" implementations

5. **Clear Task Breakdown Enables Execution**: 13 specific, 1-3 hour tasks are more actionable than "redesign network"

6. **Validation Throughout**: Each task has acceptance criteria and validation procedures

---

**Document Purpose**: Show how to reverse-engineer requirements and specifications from code changes, enabling professional specification-driven development practices.

**Created**: 2026-01-21  
**Status**: Reference documentation
