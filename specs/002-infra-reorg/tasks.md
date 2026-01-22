# Infrastructure Reorganization - Tasks

Phases with owners and acceptance. Effort ~6-8h (dev environment).

## Phase 1: Prep

- **T1.1 Update Bicep modules** (1h) — Add agents/main.bicep, App Gateway module in iaas, move CAE to paas scopes. _AC_: lint/validate passes; parameters include subnet outputs.
- **T1.2 Update params/outputs** (0.5h) — Ensure core outputs publish snet-fe, snet-gh-runners, snet-ca; iaas/paas/agents params consume them. _AC_: outputs file reviewed.

## Phase 2: Deploy

- **T2.1 Deploy core** (0.5h) — No changes expected; verify outputs. _AC_: deployment success, outputs present.
- **T2.2 Deploy iaas (App Gateway + web/SQL)** (1.5h) — App Gateway in iaas RG with public IP, backend to VMSS. _AC_: provisioningState Succeeded; backend health green.
- **T2.3 Deploy paas (CAE + apps)** (1h) — CAE now in paas RG. _AC_: CAE exists in paas RG; diagnostics wired.
- **T2.4 Deploy agents (build VMSS)** (1h) — VMSS in agents RG using snet-gh-runners. _AC_: instances running; outbound to internet works.

## Phase 3: Validate

- **T3.1 Connectivity checks** (0.5h) — App Gateway → web VMSS healthy; build agents → web tier and internet; PaaS → data tier. _AC_: tests recorded.
- **T3.2 Diagnostics & WAF** (0.5h) — Logs in LAW for App Gateway/VMSS; WAF logs present. _AC_: queries return entries.

## Phase 4: Cleanup & Docs

- **T4.1 Remove misplaced resources** (0.5h) — Delete old CAE/build VMSS from wrong RGs after success. _AC_: RG audit clean.
- **T4.2 Update documentation** (0.5h) — Specs index, README pointers updated; old status/docs removed. _AC_: links resolve; deleted files removed.
