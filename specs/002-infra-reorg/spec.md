# Infrastructure Reorganization - Specification

**Goal**: Correct resource placement, add missing Web Front End, and formalize the 4-layer RG model.
**Status**: Ready for planning/execution
**Last Updated**: 2026-01-21

## Overview

Current deployment mixes resources across RGs and lacks an HTTP/HTTPS entry point. This spec defines the corrected state:

- Container Apps run from PaaS RG
- Build agents isolated in Agents RG
- Application Gateway v2 (WAF) fronts the web tier in IaaS RG
- Core RG remains the single shared networking layer

## Business Requirements

- **BR-001**: Keep clear separation of concerns by layer (Core, IaaS, PaaS, Agents).
- **BR-002**: Ensure HTTP/HTTPS ingress with WAF protection for the web tier.
- **BR-003**: Isolate build infrastructure for cost/control and independent scaling.
- **BR-004**: Maintain zero additional platform cost beyond services added (App Gateway only net-new).

## User Stories

### Infrastructure Engineer

I need resources in the correct RGs so deployments and ops match lifecycle and ownership.

- AC: Container Apps live in jobsite-paas-dev-rg; build VMSS lives in jobsite-agents-dev-rg; shared networking stays in jobsite-core-dev-rg.

### DevOps Engineer

I need a front door with WAF so traffic is secure and routable without manual host tweaks.

- AC: Application Gateway v2 deployed in jobsite-iaas-dev-rg with public IP, WAF_v2, and backend pool targeting web VMSS.

### Security Officer

I need segmentation and least-privilege boundaries enforced at RG and subnet levels.

- AC: 4 RGs mapped to roles; managed identities and KV-backed secrets; no hardcoded credentials.

## Design Constraints (Must)

- 4-layer RG model: core (shared), iaas (long-lived VMs + WFE), paas (managed services), agents (build).
- Application Gateway v2 (WAF_v2) with public IP in IaaS RG; frontend subnet sized /24.
- Build VMSS must use snet-gh-runners and reside in agents RG.
- Container Apps environment must live in paas RG and use the correct subnet from core VNet.
- All changes driven via Bicep/automation; no portal moves for production.

## Technical Requirements

- RG mapping table must match target state (see plan.md).
- Core VNet/subnets unchanged; references updated for PaaS/Agents/IaaS modules.
- Outputs: subnet IDs exposed for PaaS and Agents modules; App Gateway outputs published for consumer services.
- Monitoring: LAW wiring remains in core; diagnostics enabled on App Gateway and VMSS.

## Acceptance Criteria

- [ ] jobsite-paas-dev-rg contains Container Apps Environment (CAE) and related apps.
- [ ] jobsite-agents-dev-rg contains GitHub Runner VMSS and NIC/disk resources.
- [ ] jobsite-iaas-dev-rg contains Application Gateway v2 + public IP; backend pool targets web VMSS.
- [ ] Core RG unchanged except for any output additions; no stray PaaS/Agents resources in core.
- [ ] Bicep deployments succeed end-to-end with updated RG parameters.
- [ ] Connectivity: App Gateway health probes green; build agents can reach web and internet via NAT; PaaS services reach data as before.

## Success Metrics

- Zero manual portal moves; all via IaC.
- End-to-end deployment time ≤ 20 minutes.
- No broken links/diagnostics: LAW and App Insights continue to ingest.
- Security: no credentials in scripts; managed identities used where applicable.

## Open Questions

- Do we need blue/green for App Gateway introduction or can we deploy in place for dev? (default: deploy fresh in dev.)
- Any compliance tagging changes needed for the new Agents RG?
