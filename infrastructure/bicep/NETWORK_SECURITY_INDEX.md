# Network Security Configuration - Complete Documentation Index

**Last Updated:** January 22, 2026  
**Status:** ✅ Complete - All network security configured and documented  
**Environment:** Azure IaaS (Bicep)

---

## 📚 Documentation Files

### Quick Start (5 minutes)

| File                                                         | Purpose                                       | Audience        |
| ------------------------------------------------------------ | --------------------------------------------- | --------------- |
| [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md) | Executive summary with quick reference tables | Everyone        |
| [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md) | Diagrams, flowcharts, and visual explanations | Visual learners |

### Detailed Configuration (20-30 minutes)

| File                                                                     | Purpose                                                  | Audience                     |
| ------------------------------------------------------------------------ | -------------------------------------------------------- | ---------------------------- |
| [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md) | Complete NSG rules, communication flows, troubleshooting | Network engineers, DevOps    |
| [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)       | Testing procedures, validation checklist                 | QA, DevOps, Deployment teams |
| [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)                       | PowerShell, Azure CLI, Terraform, Portal instructions    | DevOps, Infrastructure teams |

### Reference Files

| File                                                     | Purpose                            |
| -------------------------------------------------------- | ---------------------------------- |
| [iaas/iaas-resources.bicep](./iaas/iaas-resources.bicep) | Bicep source code for NSGs and VMs |
| [core/core-resources.bicep](./core/core-resources.bicep) | Bicep source code for NAT Gateway  |
| [README.md](./README.md)                                 | Main Bicep documentation           |

---

## 🎯 Quick Navigation by Role

### 👤 I'm a Developer

**Start here:** [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md)

- Understand how Web and SQL VMs communicate
- See what ports are open and why

**Then read:** [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md)

- Quick reference tables
- Common issues

---

### 👨‍💼 I'm a DevOps/Infrastructure Engineer

**Start here:** [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md)

- Overview of what's configured
- NSG rules table
- Parameters needed

**Then read:** [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)

- Choose your deployment method (PowerShell/CLI/Terraform)
- Deploy infrastructure

**Then read:** [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)

- Validate deployment
- Test connectivity

---

### 🔒 I'm a Security Engineer

**Start here:** [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md)

- Complete NSG rule listing
- Security best practices
- Least privilege analysis

**Then read:** [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md)

- Security zones diagram
- Traffic decision tree

---

### 🧪 I'm QA / Test Engineer

**Start here:** [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)

- Validation checklist
- Testing instructions
- Communication paths matrix

**Use:** [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)

- Post-deployment verification scripts

---

### 📊 I'm a Manager / Stakeholder

**Start here:** [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md)

- Architecture overview
- What's been configured
- Timeline and costs

**Then read:** [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md)

- Architecture diagrams
- Security zones explained

---

## 📋 What Has Been Configured

### ✅ Web VM (Frontend Subnet)

- [x] HTTP/HTTPS inbound from Internet (80, 443)
- [x] RDP inbound from authorized IPs (3389)
- [x] SQL outbound to Data Subnet (1433)
- [x] WinRM inbound from VNet (5985, 5986)
- [x] Associated with NAT Gateway
- [x] NSG rules: `jobsite-dev-nsg-frontend`

### ✅ SQL VM (Data Subnet)

- [x] SQL inbound from Frontend Subnet (1433)
- [x] SQL inbound from VNet for SSMS/Tools (1433)
- [x] RDP inbound from authorized IPs (3389)
- [x] WinRM inbound from VNet (5985, 5986)
- [x] Associated with NAT Gateway
- [x] NSG rules: `jobsite-dev-nsg-data`

### ✅ NAT Gateway

- [x] Static Public IP (Standard SKU)
- [x] Associated to Frontend Subnet
- [x] Associated to Data Subnet
- [x] Configured in core network module
- [x] Idle timeout: 4 minutes

### ✅ Communication Flows

- [x] Web VM → SQL VM (Port 1433) ✅
- [x] SQL VM → Web VM (Responses) ✅
- [x] RDP to Web VM (Port 3389) ✅
- [x] RDP to SQL VM (Port 3389) ✅
- [x] SSMS to SQL VM (Port 1433) ✅
- [x] .NET Tools WinRM (Ports 5985/5986) ✅
- [x] Outbound via NAT Gateway ✅

---

## 🔍 Key Metrics

| Component            | Value                               |
| -------------------- | ----------------------------------- |
| VNet Address Space   | 10.50.0.0/21 (2,048 IPs)            |
| Frontend Subnet      | 10.50.0.0/24 (251 usable IPs)       |
| Data Subnet          | 10.50.1.0/26 (59 usable IPs)        |
| Web VM Size          | Standard_D2ds_v6 (2 vCPU, 8GB RAM)  |
| SQL VM Size          | Standard_D4ds_v6 (4 vCPU, 16GB RAM) |
| SQL Storage          | 2 × 128GB Premium SSD               |
| NSG Rules (Frontend) | 6 rules (4 inbound, 1 outbound)     |
| NSG Rules (Data)     | 5 rules (5 inbound)                 |
| NAT Gateway SKU      | Standard (production-ready)         |
| Deployment Time      | ~15-20 minutes                      |

---

## 🚀 Getting Started

### For Immediate Deployment

1. **Read** [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md) (5 min)
2. **Choose** deployment method from [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)
3. **Provide** `allowedRdpIps` parameter (your IP address)
4. **Deploy** using PowerShell/CLI/Terraform
5. **Validate** using [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)

### For Deep Understanding

1. **Study** [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md) (diagrams)
2. **Review** [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md) (details)
3. **Understand** NSG rules and subnet design
4. **Reference** [iaas/iaas-resources.bicep](./iaas/iaas-resources.bicep) (source code)

### For Troubleshooting

1. **Check** [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md#troubleshooting)
2. **Review** [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md) testing procedures
3. **Verify** NSG rules in Azure Portal
4. **Test** connectivity using provided scripts

---

## 📝 NSG Rules at a Glance

### Frontend NSG (Web VM)

```
INBOUND:
  100: Allow HTTP (80) from Internet
  110: Allow HTTPS (443) from Internet
  120: Allow RDP (3389) from allowedRdpIps
  130: Allow WinRM HTTP (5985) from VNet
  140: Allow WinRM HTTPS (5986) from VNet

OUTBOUND:
  125: Allow SQL (1433) to Data Subnet (10.50.1.0/26)
  (Default: Allow all other outbound via NAT Gateway)
```

### Data NSG (SQL VM)

```
INBOUND:
  100: Allow SQL (1433) from Frontend (10.50.0.0/24)
  105: Allow SQL (1433) from VirtualNetwork
  110: Allow RDP (3389) from allowedRdpIps
  120: Allow WinRM HTTP (5985) from VNet
  130: Allow WinRM HTTPS (5986) from VNet

OUTBOUND:
  (Default: Allow all outbound via NAT Gateway)
```

---

## ⚙️ Configuration Parameters

When deploying, you **MUST** provide:

```bicep
param allowedRdpIps array = [
  "203.0.113.0/32"      // CHANGE THIS to your IP
]
```

**Example values:**

```
// Single IP
"203.0.113.15/32"

// VPN Subnet
"198.51.100.0/24"

// Multiple IPs
["203.0.113.0/32", "203.0.113.1/32", "198.51.100.0/24"]
```

**Where to get your IP:**

```powershell
# Find your public IP
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content
```

---

## 🧪 Validation Checklist

Before going to production, verify:

- [ ] NAT Gateway is created and associated
- [ ] Frontend NSG has all 6 rules (4 inbound, 1 outbound)
- [ ] Data NSG has all 5 inbound rules
- [ ] Web VM can reach SQL VM on port 1433
- [ ] RDP works from authorized IPs
- [ ] SSMS can connect to SQL VM
- [ ] WinRM connectivity works
- [ ] Outbound traffic uses NAT Gateway IP
- [ ] NSG rules appear in Azure Portal
- [ ] VMs are in correct subnets

---

## 📞 Support & Resources

### Internal Documentation

- [Network Redesign](../NETWORK_REDESIGN.md) - Architecture decisions
- [Deployment Status](../DEPLOYMENT_STATUS.md) - Deployment logs
- [IaaS README](./iaas/README.md) - VM-specific details

### External Resources

- [Azure NSG Docs](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure NAT Gateway](https://learn.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-overview)
- [Bicep Language](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [ARM Template NSG](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups)

### Common Questions

**Q: Why do I need to provide allowedRdpIps?**  
A: Security best practice. RDP (port 3389) is restricted to authorized IPs only, not open to the Internet.

**Q: What's the difference between SQL rules in Frontend and Data NSGs?**  
A: Frontend allows SQL OUTBOUND (VMs initiating queries), Data allows SQL INBOUND (VMs receiving queries).

**Q: Why do both VMs connect to NAT Gateway?**  
A: So all outbound traffic uses a single static public IP for consistency and security.

**Q: Can I connect to SQL from outside the VNet?**  
A: No, by design. SQL port 1433 is only open to VirtualNetwork and Frontend subnet.

**Q: What if I need to access SQL from my office?**  
A: Use VPN to connect to VNet, then access SQL from VNet with SSMS or tools.

---

## 📊 Document Dependency Map

```
START HERE
    │
    ├─→ NETWORK_SECURITY_SUMMARY.md
    │       │
    │       ├─→ NETWORK_VISUAL_REFERENCE.md
    │       │
    │       └─→ NETWORK_SECURITY_CONFIGURATION.md
    │
    ├─→ DEPLOYMENT_EXAMPLES.md
    │       │
    │       └─→ Deploy using PowerShell/CLI/Terraform
    │
    └─→ NETWORK_SECURITY_VALIDATION.md
            │
            └─→ Test & Validate
```

---

## 🎓 Learning Path

**Beginner (30 min)**

1. [NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md) - Overview
2. [NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md) - Diagrams

**Intermediate (60 min)**

1. [NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md) - Details
2. [DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md) - How to deploy

**Advanced (90+ min)**

1. [NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md) - Testing
2. [iaas/iaas-resources.bicep](./iaas/iaas-resources.bicep) - Source code
3. [core/core-resources.bicep](./core/core-resources.bicep) - NAT Gateway code

---

## ✅ Configuration Status

| Item            | Status      | Details                     |
| --------------- | ----------- | --------------------------- |
| Web VM NSG      | ✅ Complete | 6 rules configured          |
| SQL VM NSG      | ✅ Complete | 5 rules configured          |
| NAT Gateway     | ✅ Complete | Static IP, both subnets     |
| Web-to-SQL      | ✅ Complete | Port 1433 bidirectional     |
| RDP Access      | ✅ Complete | Restricted to allowedRdpIps |
| SSMS Support    | ✅ Complete | Via VNet access             |
| .NET Automation | ✅ Complete | WinRM + SQL support         |
| Documentation   | ✅ Complete | 5 comprehensive docs        |
| Examples        | ✅ Complete | PowerShell, CLI, Terraform  |
| Validation      | ✅ Complete | Testing procedures ready    |

---

**Version:** 1.0  
**Last Updated:** 2026-01-22  
**Maintained By:** Infrastructure Team  
**Status:** Production Ready ✅
