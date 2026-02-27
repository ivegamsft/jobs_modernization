# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture, scope, decisions | Morpheus | System design, modernization strategy, tech stack choices, code review |
| Backend, APIs, services, database | Tank | .NET legacy code, Python services, REST APIs, SQL Server, data layer |
| Frontend, UI, components | Trinity | React conversion, UI components, client-side logic, CSS, accessibility |
| Infrastructure, deployment, CI/CD | Dozer | Azure resources, Bicep templates, Kubernetes config, pipelines, networking |
| Testing, quality, validation | Mouse | Unit tests, integration tests, multi-config validation, edge cases |
| Code review | Morpheus | Review PRs, check quality, suggest improvements |
| Scope & priorities | Morpheus | What to build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never needs routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Morpheus |
| `squad:morpheus` | Architecture/scope work | Morpheus |
| `squad:tank` | Backend/API/database work | Tank |
| `squad:trinity` | Frontend/UI work | Trinity |
| `squad:dozer` | Infrastructure/DevOps work | Dozer |
| `squad:mouse` | Testing/quality work | Mouse |

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what branch are we on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn Mouse to write test cases simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied, route to that member. Morpheus handles all `squad` (base label) triage.
