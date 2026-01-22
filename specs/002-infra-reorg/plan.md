# Infrastructure Reorganization - Plan

**Tech Stack**: Bicep, Azure CLI, PowerShell
**Region**: Sweden Central
**Approach**: Redeploy to correct RGs (no portal moves) then validate

## Architecture Decisions

### 1) RG Model (4-Layer)

Decision: Core (shared), IaaS (app VMs + WFE), PaaS (managed services), Agents (build).
Rationale: Align lifecycle, cost tracking, and security boundaries.
Outcome: Bicep entry points per layer; parameters supply core outputs.

### 2) Resource Placement

Decision: Move CAE to paas RG; move build VMSS to agents RG; keep VNet in core; add App Gateway in iaas.
Rationale: PaaS belongs with managed services; build infra is ephemeral; WFE missing.
Outcome: Updated module parameters and scopes; subnet IDs consumed from core outputs.

### 3) Web Front End (App Gateway v2)

Decision: Deploy WAF_v2 with public IP, /24 frontend subnet, backend = web VMSS.
Rationale: Provide HTTP/HTTPS ingress, WAF, SSL termination, path-based routing ready.
Outcome: Bicep module in iaas layer; diagnostics to LAW; WAF mode Detection in dev.

### 4) Build Agents Isolation

Decision: Dedicated RG + snet-gh-runners subnet; VMSS auto-scale 1-5.
Rationale: Different lifecycle and security posture; cost isolation.
Outcome: New agents module consuming core subnet output; outbound via NAT.

### 5) Deployment Strategy

Decision: Fresh deploy to target RGs for dev; no in-place move.
Rationale: Lower risk, consistent with current automation; portal moves error-prone.
Outcome: Delete stray resources only after successful redeploy and validation.

### 6) Monitoring & Security

Decision: Keep LAW in core; enable diagnostics on App Gateway/VMSS; Defender on VMs; KV for secrets.
Rationale: Preserve observability and security posture while reorganizing.
Outcome: Diagnostic settings added/verified in modules; no secrets in scripts.

## Target State (RG Map)

- jobsite-core-dev-rg: VNet + subnets, KV, LAW, ACR, NAT, Private DNS.
- jobsite-iaas-dev-rg: App Gateway v2 + public IP, Web VMSS, SQL VM, NICs/disks.
- jobsite-paas-dev-rg: Container Apps Environment + apps, App Service/Plan, SQL DB, App Insights, private endpoints.
- jobsite-agents-dev-rg: GitHub Runner VMSS + NICs/disks.

## Timeline (Dev)

- Prep: 1-2h (update Bicep, params, outputs).
- Deploy: 3-4h (core validation, iaas with App Gateway, paas, agents).
- Validate: 1-2h (health probes, connectivity, diagnostics).
- Cleanup: 0.5h (remove old resources, update docs).

## Risks & Mitigations

- App Gateway backend miswired → Use correct subnet (/24) and health probes; validate before cutover.
- Build agents offline after move → Test connectivity to internet and web tier via snet-gh-runners.
- Portal drift → Lock to IaC; block portal moves during change window.
- Downtime risk → For dev, tolerate brief; for prod later, use blue/green or staged gateway.

## Dependencies

- Core VNet/subnet outputs published (snet-fe, snet-gh-runners, snet-ca, etc.).
- LAW and KV already present in core.
- Valid certificates for App Gateway (self-signed acceptable in dev).

## Validation Plan

- App Gateway: healthy backends, HTTP 200, WAF logs in LAW.
- Build agents: az vmss list-instances in agents RG; outbound curl to GitHub; ping web tier.
- PaaS: CAE reachable; diagnostic flows to LAW/App Insights.
- RG audit: no stray PaaS/Agents resources in core; no build agents in iaas.
