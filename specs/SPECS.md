# JobSite Specifications - Spec Kit Integration

## Quick Start

This project uses **Spec-Driven Development** with GitHub's [Spec Kit](https://github.com/github/spec-kit) framework.

### Installation

Install Specify CLI (one-time setup):

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

Verify installation:

```bash
specify check
```

### Project Structure

```
specs/
├── 001-network-redesign/        # Feature: Network redesign
│   ├── README.md                # Feature overview & status
│   ├── constitution.md          # Project principles
│   ├── spec.md                  # What we're building
│   ├── plan.md                  # How we'll build it
│   ├── tasks.md                 # Actionable task list
│   └── implementation.md        # Build details
└── [more features...]
```

## Features

### 001: Network Redesign

**Status**: Specification & Plan Complete → Ready for Tasks

Redesign Azure VNet from /24 (256 IPs) to /21 (2,048 IPs) with properly-sized subnets following Microsoft best practices.

**Location**: `specs/001-network-redesign/`

**Key Files**:

- `spec.md` - Complete requirements and user stories
- `plan.md` - Technical architecture and implementation strategy
- `constitution.md` - Quality standards and principles

**Artifacts Created**:

- ✅ VNet redesign from /24 to /21
- ✅ App Gateway subnet: /27 → /24
- ✅ AKS subnet: /27 → /23
- ✅ VMSS subnet correction (snet-gh-runners)
- ✅ Updated Bicep templates (core-resources.bicep, core/main.bicep)
- ✅ 44% reserved capacity for future growth

---

## Spec-Driven Development Workflow

### Step 1: Read & Understand Specifications

Start by reviewing the feature's specification:

```bash
cat specs/001-network-redesign/spec.md
cat specs/001-network-redesign/plan.md
```

### Step 2: Review Constitution (Project Standards)

Understand quality standards before implementing:

```bash
cat specs/001-network-redesign/constitution.md
```

### Step 3: Generate Tasks

Create actionable task list from the plan:

```bash
/speckit.tasks

# or manually create tasks.md following the format in:
# specs/001-network-redesign/tasks.md
```

### Step 4: Execute Implementation

Run all tasks to build the specification:

```bash
/speckit.implement
```

### Step 5: Validate & Document

Verify everything works, then update implementation.md:

```bash
/speckit.analyze
/speckit.checklist
```

---

## Slash Commands Reference

When working with AI coding agents (Cursor, Copilot, Claude Code, etc.):

### Core Commands

- `/speckit.constitution` - Create/review project principles
- `/speckit.specify` - Define requirements (what we're building)
- `/speckit.plan` - Create implementation strategy (how we'll build it)
- `/speckit.tasks` - Break plan into actionable tasks
- `/speckit.implement` - Execute all tasks

### Optional Commands

- `/speckit.clarify` - Ask questions about underspecified areas
- `/speckit.analyze` - Cross-check specs for consistency
- `/speckit.checklist` - Generate quality validation checklist

---

## Current Implementation Status

### ✅ Complete

- **Specification (spec.md)**: Requirements, user stories, acceptance criteria
- **Technical Plan (plan.md)**: Architecture decisions, tech stack, timeline
- **Constitution (constitution.md)**: Quality standards and principles
- **Bicep Templates Updated**:
  - `iac/bicep/core/main.bicep` - VNet expanded to /21
  - `iac/bicep/core/core-resources.bicep` - Subnets resized per best practices

### 🔄 In Progress

- **Tasks (tasks.md)**: Actionable task breakdown
- **Implementation (implementation.md)**: Build execution details

### ⏳ Next Steps

1. Generate task list from plan.md
2. Execute implementation tasks
3. Validate deployment
4. Document lessons learned

---

## File Conventions

### Naming

- **spec.md**: Specification (what)
- **plan.md**: Implementation plan (how, architecture, tech stack)
- **constitution.md**: Quality standards and principles
- **tasks.md**: Breakdown into 1-3 hour tasks
- **implementation.md**: Execution details, commands, validation steps

### Format

All files use Markdown with:

- Clear headings and structure
- Links between related documents
- Tables for comparisons/decisions
- Code blocks for examples/commands
- Checklists for validation

---

## Example: Network Redesign Feature

### What (spec.md)

> Redesign Azure VNet from /24 (256 IPs) to /21 (2,048 IPs) with properly-sized subnets following Microsoft Well-Architected Framework recommendations.

### Why (User Stories)

> As an Infrastructure Engineer, I want a VNet with proper sizing so that I can scale services confidently without network redesigns every 6 months.

### How (plan.md)

> Use Bicep to define VNet with 7 subnets: snet-fe (/24), snet-data (/26), snet-gh-runners (/26), snet-pe (/27), GatewaySubnet (/27), snet-aks (/23), snet-ca (/26).

### Tasks (tasks.md)

1. Update core/main.bicep with new VNet CIDR
2. Update core-resources.bicep with subnet configurations
3. Validate Bicep templates
4. Deploy Core layer with fresh VNet
5. Validate connectivity and IP allocation
6. Update architecture documentation

---

## Best Practices

### Do's ✅

- Start with specification (what) before planning (how)
- Get approval on spec before writing code
- Use constitution to guide implementation
- Break large features into smaller tasks
- Test and validate before moving to next task
- Update documentation as you go

### Don'ts ❌

- Don't skip the specification phase
- Don't jump to code before planning
- Don't hardcode decisions in code
- Don't ignore quality standards
- Don't merge without validation
- Don't forget to update docs

---

## Resources

- **Spec Kit Repository**: https://github.com/github/spec-kit
- **Documentation**: https://github.github.io/spec-kit/
- **Video Overview**: https://www.youtube.com/watch?v=a9eR1xsfvHg
- **Spec-Driven Development Guide**: https://github.com/github/spec-kit/blob/main/spec-driven.md

---

## Support & Questions

For questions about:

- **Specifications**: Check the relevant `spec.md` file
- **Plans**: See the `plan.md` and `constitution.md`
- **Implementation**: Review `tasks.md` and `implementation.md`
- **Spec Kit**: Visit https://github.com/github/spec-kit/issues

---

**Last Updated**: 2026-01-21  
**Maintained By**: Infrastructure Team  
**Version**: 1.0
