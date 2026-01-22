# JobSite Infrastructure Specification

## 001-network-redesign

Azure Virtual Network (VNet) redesign for production-ready multi-tier infrastructure supporting Application Gateway v2, AKS, Container Apps, and SQL workloads.

### Feature Status

- [ ] Specification Complete
- [ ] Plan Complete
- [ ] Implementation Complete

### Artifacts

#### Specification

- **spec.md** - Complete network design specification
- **constitution.md** - Project principles and quality standards

#### Plan

- **plan.md** - Technical implementation strategy

#### Tasks & Implementation

- **tasks.md** - Actionable task breakdown
- **implementation.md** - Build and deployment steps

---

## Quick Summary

**Current State**: VNet 10.50.0.0/24 with 7 /27 subnets (256 total IPs)

**Target State**: VNet 10.50.0.0/21 with properly sized subnets (2,048 total IPs)

**Key Improvement Areas**:

1. Application Gateway v2 subnet: /27 → /24 (Microsoft recommendation)
2. AKS subnet: /27 → /23 (production-scale support)
3. VNet growth capacity: 100% utilized → 56% utilized (44% reserved)
4. VMSS placement: moved to dedicated snet-gh-runners subnet

**Status**: Ready for Spec Kit workflow
