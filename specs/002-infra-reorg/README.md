# Infrastructure Reorganization (Feature 002)

**Scope**: Fix RG placement, add Web Front End (App Gateway), and isolate build agents.
**Status**: Spec & plan complete — ready for execution.
**Owners**: Cloud/Infra + DevOps

## Summary

- Move Container Apps to PaaS RG (jobsite-paas-dev-rg).
- Create Agents RG (jobsite-agents-dev-rg) and move GitHub Runner VMSS there.
- Add Application Gateway v2 (WAF_v2) + public IP in IaaS RG (jobsite-iaas-dev-rg).
- Keep Core RG for shared networking (VNet, subnets, KV, LAW, ACR).

## Links

- [spec.md](spec.md)
- [plan.md](plan.md)
- [constitution.md](constitution.md)
- [tasks.md](tasks.md)
- [implementation.md](implementation.md)

## Read Order

1. spec.md – what/why
2. plan.md – architecture & decisions
3. constitution.md – standards
4. tasks.md – sequence and acceptance
5. implementation.md – commands & validation
