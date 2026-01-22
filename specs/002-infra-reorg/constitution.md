# Infrastructure Reorganization - Constitution

## Principles

1. Layered ownership: Core, IaaS, PaaS, Agents each have clear scope.
2. Security by design: WAF at edge, isolated build subnet/RG, KV for all secrets.
3. IaC only: No portal moves; redeploy to correct scopes.
4. Observability first: Diagnostics to LAW, App Gateway/VMSS logs enabled.
5. Least privilege: RBAC aligned to RGs; managed identities preferred.

## Quality Standards

- Naming follows existing kebab-case + env (jobsite-dev-...).
- No hardcoded credentials; parameters or KV only.
- All resource placements encoded in Bicep with explicit scopes.
- Subnet choices unchanged from core VNet; consumers must reference outputs.
- WAF_v2 configured (Detection in dev; Prevention when promoted).

## Definition of Done

- Spec, plan, tasks implemented; deployments succeed without manual moves.
- App Gateway online with healthy backends and WAF logging.
- Build agents operating from agents RG, able to reach web + internet.
- CAE running from paas RG; diagnostics still flowing.
- RG audit clean: resources match target map; documentation updated.

## Tools & References

- Azure CLI, PowerShell scripts, Bicep modules per layer.
- Log Analytics Workspace in core for diagnostics.
- Key Vault in core for secrets and certificates.
