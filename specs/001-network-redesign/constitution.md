# Network Redesign - Constitution

Project principles and quality standards for Azure infrastructure specifications and implementation.

## Core Principles

### 1. Production Readiness

- All designs must follow Azure Well-Architected Framework recommendations
- Subnet sizing must accommodate maximum expected scale + 20% buffer
- No hardcoded credentials or security vulnerabilities
- Comprehensive logging, monitoring, and diagnostics enabled

### 2. Scalability by Default

- VNet must provide 40%+ unallocated address space for growth
- Each subnet sized for 3-5x current resource count
- Architecture supports both vertical (instance size) and horizontal (replica count) scaling
- Network performance not constrained by IP allocation

### 3. Best Practices Adherence

- Application Gateway v2: Minimum /24 subnet (supports up to 125 instances)
- AKS: Minimum /23 with Azure CNI Overlay (supports 250+ nodes)
- Container Apps: /27 minimum for workload profiles, /23 for consumption-only
- All resources use Managed Identities, not connection strings or keys in code

### 4. Cost Optimization

- Resource selection based on regional availability (e.g., F-series unavailable in Sweden Central)
- D-series v6 preferred over v4 (better price-performance in target region)
- Network resources sized appropriately - oversizing adds no Azure cost
- Consolidate features into existing services (e.g., Container App Environment reuse)

### 5. Security by Design

- Zero hardcoded credentials in templates or scripts
- All passwords/certificates managed via Azure Key Vault or parameters
- Private endpoints for sensitive resources (SQL, Key Vault)
- Network isolation with dedicated subnets per workload tier
- Regular security reviews and dependency updates

### 6. Operational Excellence

- Infrastructure as Code with Bicep (version-controlled, reviewable)
- Comprehensive documentation of design decisions and rationale
- Modular architecture allowing independent layer deployment
- Clear separation of concerns (Core → IaaS + PaaS)

## Quality Standards

### Documentation Quality

- [ ] Design rationale documented for each subnet sizing decision
- [ ] References to Microsoft documentation for all sizing recommendations
- [ ] Architecture diagrams showing relationships between resources
- [ ] Cost analysis and budget impact statements

### Code Quality

- [ ] No hardcoded values - all parameters configurable
- [ ] Consistent naming conventions (resource prefix, environment tag)
- [ ] Comments explaining non-obvious configuration choices
- [ ] DRY principle - no duplicate resource definitions
- [ ] Modular structure - easy to understand and maintain

### Testing & Validation

- [ ] All templates pass Bicep linting
- [ ] Dry-run deployments validate template syntax
- [ ] Subnet IP calculations verified against Azure requirements
- [ ] Network connectivity tested between tiers
- [ ] Cost estimates provided before deployment

### Security Standards

- [ ] No credentials in git history or logs
- [ ] All secrets stored in Key Vault
- [ ] Network security groups configured per best practices
- [ ] Private endpoints for data tier access
- [ ] Managed identities for service-to-service auth

## Definition of Done

A specification is complete when:

1. ✅ Spec artifact describes the "what" clearly
2. ✅ Plan artifact describes the "how" with tech stack choices
3. ✅ All quality standards above are met
4. ✅ Implementation passes validation tests
5. ✅ Documentation is updated
6. ✅ Knowledge transfer completed

## Tools & Standards

- **IaC Language**: Bicep (Azure ARM templates)
- **Linting**: Bicep linter with strict mode
- **Documentation**: Markdown with mermaid diagrams
- **Version Control**: Git with atomic commits per logical change
- **Deployment**: Azure CLI with PowerShell automation
- **Monitoring**: Azure Monitor + Log Analytics
