# Network Redesign - Specification

**Feature**: Azure VNet redesign for production-ready infrastructure  
**Scope**: Networking layer (Core infrastructure)  
**Status**: Ready for Technical Planning  
**Last Updated**: 2026-01-21

---

## Overview

The current network architecture uses a /24 VNet split into seven /27 subnets, leaving no room for growth and violating Microsoft's recommended subnet sizes for Application Gateway v2 and AKS deployments. This specification outlines a redesigned network that:

- Expands VNet from /24 to /21 (8x more capacity)
- Rightsizes all subnets to follow Azure best practices
- Reserves 44% capacity for future growth
- Maintains cost efficiency (no additional Azure charges)
- Supports production-scale workloads

## Business Requirements

### Growth & Scalability

- **BR-001**: Network must support 3-5x growth in resource count
- **BR-002**: Application Gateway must scale to 125 instances without IP exhaustion
- **BR-003**: AKS cluster must support 250+ nodes with standard workloads
- **BR-004**: Container Apps environment must support production-level replica scaling

### Operational Requirements

- **OR-001**: All resources must follow Microsoft Well-Architected Framework recommendations
- **OR-002**: Implement monitoring and diagnostics for all networking resources
- **OR-003**: Support both dev and production deployments with same network design
- **OR-004**: Enable future addition of services (API Gateway, Load Balancer, etc.)

### Security & Compliance

- **SR-001**: Separate subnets for different workload tiers (frontend, data, private endpoints)
- **SR-002**: Build agents must have isolated subnet (snet-gh-runners)
- **SR-003**: SQL workloads must have dedicated, protected subnet
- **SR-004**: Private endpoints for sensitive services must be available

### Cost Requirements

- **CR-001**: No increase in Azure networking costs (VNet/subnet resizing free)
- **CR-002**: Resource sizing optimized for regional availability
- **CR-003**: Support cost-effective regional choices (e.g., D-series v6 in Sweden Central)

## User Stories

### As an Infrastructure Engineer

I want a VNet design that follows Microsoft best practices and has room for growth, so that I can scale services confidently without redesigning the network every 6 months.

**Acceptance Criteria**:

- ✓ Application Gateway subnet ≥ /24 (Microsoft recommendation)
- ✓ AKS subnet ≥ /23 for production scale
- ✓ At least 40% unallocated IP space
- ✓ All sizing decisions documented with Azure references

### As an Application Developer

I want dedicated subnets for different workload types, so that network policies can be applied appropriately and resources can be scaled independently.

**Acceptance Criteria**:

- ✓ Frontend tier isolated in snet-fe
- ✓ Data tier isolated in snet-data
- ✓ Build agents isolated in snet-gh-runners
- ✓ Container apps with own dedicated subnet
- ✓ Private endpoints subnet for sensitive services

### As a DevOps Engineer

I want to deploy and redeploy infrastructure without network constraints, so that I can validate designs and make changes quickly.

**Acceptance Criteria**:

- ✓ Blue-green deployment supported (old VNet coexists with new)
- ✓ All networking resources defined in Bicep
- ✓ Deployment time < 10 minutes for network core
- ✓ Clear migration path with minimal service interruption

### As a Security Officer

I want proper network segmentation and no hardcoded credentials, so that we meet enterprise security standards.

**Acceptance Criteria**:

- ✓ No credentials in templates or scripts
- ✓ Private endpoints available for data access
- ✓ Network Security Groups configurable per tier
- ✓ Audit logging enabled for all network changes

## Design Constraints

### Must Have

- ✅ VNet with /21 CIDR (10.50.0.0/21)
- ✅ Application Gateway subnet: /24 minimum (snet-fe for WFE)
- ✅ AKS subnet: /23 minimum
- ✅ Container Apps subnet: /27 minimum (workload profiles)
- ✅ Backward compatible with existing resource names
- ✅ **Application Gateway v2 (WFE) with WAF protection** (HTTP/HTTPS ingress)
- ✅ **Build agents (GitHub Runners) in dedicated RG** (separate from long-lived app VMs)
- ✅ **Resource groups properly organized**:
  - Core RG: Networking + shared services (VNet, KV, LAW, ACR)
  - IaaS RG: Application VMs (Web VMSS, SQL VM, App Gateway)
  - PaaS RG: Managed services (Container Apps, App Service, SQL DB)
  - Agents RG: Build infrastructure (GitHub Runners VMSS)
- ✅ **Enable Microsoft Defender for Cloud on all VMs** (threat detection + vulnerability management)
- ✅ **Connect Log Analytics Workspace to all VMs** (diagnostics, performance metrics, security logs)
- ✅ **Configure Private Endpoints for all sensitive services** (Key Vault, SQL Database, Storage)
- ✅ **Enable RBAC with principle of least privilege** on all resources (no overly permissive roles)
- ✅ **Store all credentials in Key Vault** (no hardcoded secrets, managed identities for VM access)
- ✅ **Follow Azure Naming Conventions** (kebab-case, resource type prefix, environment suffix per Azure guidelines)
  - Example: `jobsite-dev-vnet`, `jobsite-dev-snet-fe`, `jobsite-dev-agw`, `jobsite-dev-kv`

### Should Have

- 🔄 Support for multiple environments (dev, staging, prod)
- 🔄 NAT Gateway for outbound traffic control
- 🔄 Private DNS zone for internal service discovery
- 🔄 Azure Policy enforcement for compliance and naming standards
- 🔄 Automated security scanning in ACR for container images
- 🔄 SSL/TLS certificates for Application Gateway
- 🔄 WAF rule updates and tuning based on traffic patterns

### Out of Scope

- VPN Gateway expansion (currently unused)
- ExpressRoute connectivity
- Hybrid cloud networking scenarios
- Third-party security appliances

## Technical Requirements

### Network Architecture

| Subnet          | Current        | Target                   | Justification                                      |
| --------------- | -------------- | ------------------------ | -------------------------------------------------- |
| snet-fe         | 10.50.0.0/27   | 10.50.0.0/24             | App Gateway v2 needs 251 IPs min for 125 instances |
| snet-data       | 10.50.0.32/27  | 10.50.1.0/26             | SQL VMs + future database servers                  |
| snet-gh-runners | 10.50.0.128/27 | 10.50.1.64/26            | VMSS build agents, supports 50+ instances          |
| snet-pe         | 10.50.0.96/27  | 10.50.1.128/27           | Private endpoints (27 IPs sufficient)              |
| GatewaySubnet   | 10.50.0.64/27  | 10.50.1.160/27           | VPN gateway (meets /27 recommendation)             |
| snet-aks        | 10.50.0.160/27 | 10.50.2.0/23             | Azure CNI Overlay: 507 IPs for 250+ nodes          |
| snet-ca         | 10.50.0.192/27 | 10.50.4.0/26             | Container Apps: 12 infra + 47 for scaling          |
| **Reserved**    | -              | 10.50.4.64 - 10.50.7.255 | ~896 IPs for future expansion                      |

### IP Address Planning

- **VNet**: 10.50.0.0/21 = 2,048 IPs
- **Allocated**: 1,152 IPs (56%)
- **Reserved**: 896 IPs (44%)
- **Azure Reserved**: 8 IPs per subnet (network, broadcast, etc.)

### Resource Specifications

- **VNet**: Standard (no additional cost)
- **Subnets**: 7 managed (no cost per subnet)
- **NAT Gateway**: 1 shared (existing, retained)
- **Public IP - NAT**: 1 for NAT Gateway
- **Public IP - WFE**: 1 for Application Gateway (NEW)
- **Application Gateway v2**: WAF_v2 SKU with 2 capacity (NEW)

### Resource Group Organization

| RG Name               | Purpose              | Contains                                          | Scope              |
| --------------------- | -------------------- | ------------------------------------------------- | ------------------ |
| jobsite-core-dev-rg   | Shared networking    | VNet, subnets, KV, LAW, ACR, NAT                  | Core layer         |
| jobsite-iaas-dev-rg   | Application VMs      | App Gateway (WFE), Web VMSS, SQL VM, NICs         | IaaS layer         |
| jobsite-paas-dev-rg   | Managed services     | Container Apps, App Service, SQL DB, App Insights | PaaS layer         |
| jobsite-agents-dev-rg | Build infrastructure | GitHub Runners VMSS, NICs, Disks                  | Agents layer (NEW) |

## Acceptance Criteria

### Functional

- [ ] All 7 subnets created with correct CIDR ranges
- [ ] Application Gateway v2 (WFE) deployed in jobsite-iaas-dev-rg
- [ ] Build agents (VMSS) deployed in jobsite-agents-dev-rg (not iaas-rg)
- [ ] Container Apps Environment deployed in jobsite-paas-dev-rg (not core-rg)
- [ ] VNet routes to Azure services (GatewaySubnet, Azure services)
- [ ] NAT Gateway applies to required subnets
- [ ] Private DNS zone created for internal service discovery
- [ ] Bicep templates validate without errors

### Performance

- [ ] VNet creation time < 2 minutes
- [ ] No IP conflicts with existing resources
- [ ] All resources deployable within 15 minutes
- [ ] Network latency between subnets < 1ms

### Security

- [ ] No hardcoded IPs or credentials in templates
- [ ] All subnets have Network Security Groups (NSGs) configured
- [ ] Private endpoints available for Key Vault, SQL, Storage
- [ ] Service endpoints enabled for Azure services where applicable
- [ ] Microsoft Defender for Cloud enabled on all VMs (threat detection, vulnerability scanning)
- [ ] Log Analytics diagnostic settings configured on all VMs (CPU, memory, disk, network metrics)
- [ ] All VMs monitored via Log Analytics Workspace with custom alerts configured
- [ ] RBAC configured with principle of least privilege (no overly permissive Owner/Contributor roles)
- [ ] All credentials stored in Key Vault (no hardcoded passwords or secrets)
- [ ] Managed identities configured for VM access to Azure services
- [ ] Private Endpoints created for: Key Vault, SQL Database, Storage Account, ACR
- [ ] Azure Naming Conventions applied to all resources (kebab-case, resource type prefixes, env suffixes)

### Operational

- [ ] Complete Bicep modules with documentation
- [ ] Deployment scripts for all layers (Core, IaaS, PaaS)
- [ ] Architecture diagrams in Mermaid format
- [ ] Migration guide for transitioning from old network

### Documentation

- [ ] Architecture decision record (ADR)
- [ ] Sizing calculations with Azure references
- [ ] Troubleshooting guide for common issues
- [ ] Cost analysis and budget impact

## Success Metrics

- **Deployment Success Rate**: 100% first-time success
- **Time to Scale**: Can add 50 nodes to AKS in < 5 minutes without network issues
- **IP Utilization**: Target 50-70% (allows growth, doesn't waste space)
- **Security Compliance**: Zero credentials in code, all secrets in Key Vault
- **Documentation Quality**: All design decisions traceable to Azure best practices
- **Team Satisfaction**: Infrastructure engineers feel confident deploying and scaling

## Open Questions & Clarifications

1. **VNet Peering**: Do we need to peer with other VNets for hub-spoke topology?
2. **Custom DNS**: Should we use Azure Private DNS Zone or custom DNS servers?
3. **Production Scale**: What is the maximum number of nodes/replicas we need to support?
4. **Disaster Recovery**: Should we plan for multi-region failover?
5. **Compliance**: Any industry-specific compliance requirements (GDPR, HIPAA)?

---

## Sign-Off

| Role                | Name  | Date | Approval |
| ------------------- | ----- | ---- | -------- |
| Product Manager     | [TBD] | -    | Pending  |
| Infrastructure Lead | [TBD] | -    | Pending  |
| Security Officer    | [TBD] | -    | Pending  |

---

**Next Step**: Review specification, answer open questions, then proceed to `/speckit.plan` for technical implementation strategy.
