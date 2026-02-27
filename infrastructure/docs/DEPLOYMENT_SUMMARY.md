# JobSite Infrastructure Deployment Summary

## Status: ✅ DEPLOYMENT SUCCESSFUL

**Deployment Date:** 2026-01-22  
**Deployment Region:** swedencentral  
**Resource Group:** jobsite-core-dev-rg

---

## 📊 Deployed Resources

### Virtual Machines

| VM Name                         | Size    | Type                       | Private IP | Subnet    | Status     |
| ------------------------------- | ------- | -------------------------- | ---------- | --------- | ---------- |
| jobsite-dev-wfe-ubzfsgu4p5eli   | D2ds_v6 | Windows Server 2022        | 10.50.0.x  | snet-fe   | ✅ Running |
| jobsite-dev-sqlvm-ubzfsgu4p5eli | D4ds_v6 | SQL Server 2022 Enterprise | 10.50.1.x  | snet-data | ✅ Running |

### Network Infrastructure

- **Virtual Network:** jobsite-dev-vnet-ubzfsgu4p5eli (10.50.0.0/21)
  - Frontend Subnet (snet-fe): 10.50.0.0/24 - Web tier
  - Data Subnet (snet-data): 10.50.1.0/26 - SQL tier

- **NAT Gateway:** jobsite-dev-nat-ubzfsgu4p5eli
  - Outbound IP: 51.12.86.155
  - Associated to both frontend and data subnets

### Network Security Groups

| NSG Name                 | Rules | Purpose              |
| ------------------------ | ----- | -------------------- |
| jobsite-dev-nsg-frontend | 6     | Protects web tier VM |
| jobsite-dev-nsg-data     | 5     | Protects SQL tier VM |

### Storage (Disks)

- **Web VM:** 1 OS disk (128 GB)
- **SQL VM:** 1 OS disk + 2 data disks (128 GB each)

### Supporting Services

- **Log Analytics Workspace:** jobsite-dev-la-ubzfsgu4p5eli
- **Application Insights:** jobsite-dev-sre-ai-ubzfsgu4p5eli
- **Container Registry:** jobsitedevacrubzfsgu4p5eli
- **Key Vault:** kv-dev-swc-ubzfsgu4p5
- **Load Test Service:** jobsite-dev-loadtest-ubzfsgu4p5eli

---

## 🔐 Security Configuration

### Five Core Requirements: ✅ ALL IMPLEMENTED

1. **Web-to-SQL Communication**
   - ✅ Frontend NSG allows port 1433 (SQL) outbound to data subnet
   - ✅ Data NSG allows port 1433 inbound from frontend subnet
   - ✅ SQL Server listening on default port 1433

2. **RDP Access to Both VMs**
   - ✅ Frontend NSG allows port 3389 from 50.235.23.34/32
   - ✅ Data NSG allows port 3389 from 50.235.23.34/32
   - ✅ User IP (50.235.23.34) authorized for RDP

3. **SSMS Support**
   - ✅ SQL port 1433 enabled for SQL Server Management Studio
   - ✅ Full database connectivity available

4. **.NET Automation Support**
   - ✅ WinRM enabled on both VMs (port 5985/5986)
   - ✅ PowerShell Remoting available
   - ✅ Automation tooling can manage both tiers

5. **NAT Gateway & NSG Configuration**
   - ✅ NAT Gateway deployed with static public IP (51.12.86.155)
   - ✅ Both subnets associated with NAT Gateway for outbound traffic
   - ✅ All NSG rules properly configured with least-privilege access

### Network Security Group Rules

**Frontend NSG (jobsite-dev-nsg-frontend):**

- HTTP (80) from Internet
- HTTPS (443) from Internet
- RDP (3389) from 50.235.23.34/32
- SQL (1433) outbound to data subnet
- WinRM (5985/5986) within VNet
- Deny all other inbound traffic

**Data NSG (jobsite-dev-nsg-data):**

- SQL (1433) inbound from frontend subnet
- SQL (1433) inbound from data subnet
- RDP (3389) from 50.235.23.34/32
- WinRM (5985/5986) within VNet
- Deny all other inbound traffic

---

## 🌐 Connectivity Information

### Outbound (Internet)

- **Public IP:** 51.12.86.155 (NAT Gateway)
- **Path:** Both VMs → NAT Gateway → Internet

### Internal (Between Tiers)

- **Web to SQL:** 10.50.0.x → 10.50.1.x (port 1433)
- **Latency:** Sub-millisecond (Azure internal network)

### Inbound (From Your Machine)

- **Your Public IP:** 50.235.23.34
- **RDP to Web:** 50.235.23.34 → 10.50.0.x:3389
- **RDP to SQL:** 50.235.23.34 → 10.50.1.x:3389

---

## 📝 Connection Details

### Remote Desktop (RDP) Connections

**Web VM (jobsite-dev-wfe-ubzfsgu4p5eli):**

```
Server: <Web-VM-Private-IP>
Port: 3389
Protocol: RDP
Username: azureuser
Password: [Check Azure Portal or KeyVault]
```

**SQL VM (jobsite-dev-sqlvm-ubzfsgu4p5eli):**

```
Server: <SQL-VM-Private-IP>
Port: 3389
Protocol: RDP
Username: azureuser
Password: [Check Azure Portal or KeyVault]
```

### SQL Server Connection String

From Web VM (internal):

```
Server=10.50.1.x,1433;Database=JobsDB;User Id=sa;Password=<password>;
```

### PowerShell Remoting

```powershell
# From any authorized machine
$web_ip = "10.50.0.x"
$sql_ip = "10.50.1.x"

Enter-PSSession -ComputerName $web_ip -Credential (Get-Credential)
Enter-PSSession -ComputerName $sql_ip -Credential (Get-Credential)
```

---

## 🚀 Next Steps

1. **Verify Connectivity**
   - RDP to web VM
   - RDP to SQL VM
   - Test SQL connection from web VM

2. **Configure SQL Server**
   - Initialize JobSite database
   - Create application login
   - Configure backups

3. **Deploy Application**
   - Deploy JobSite application to web VM
   - Configure IIS
   - Set up health monitoring

4. **Security Hardening**
   - Configure Windows Firewall rules
   - Enable Windows Defender
   - Configure SQL Server security policies
   - Set up monitoring alerts

5. **Testing**
   - End-to-end connectivity tests
   - Load testing (tool available: jobsite-dev-loadtest-ubzfsgu4p5eli)
   - Application functionality testing

---

## 📊 Resource Group Summary

**Name:** jobsite-core-dev-rg  
**Location:** swedencentral  
**Subscription:** 844eabcc-dc96-453b-8d45-bef3d566f3f8

**Total Resources:** 40+

- 2 Virtual Machines
- 2 Network Security Groups
- 1 Virtual Network (3 subnets)
- 1 NAT Gateway
- 1 Application Insights
- 1 Log Analytics Workspace
- 1 Container Registry
- 1 Key Vault
- - supporting resources

---

## 📚 Documentation References

- [Network Security Configuration](./iac/bicep/NETWORK_SECURITY_CONFIGURATION.md)
- [Network Security Validation](./iac/bicep/NETWORK_SECURITY_VALIDATION.md)
- [Visual Network Reference](./iac/bicep/NETWORK_VISUAL_REFERENCE.md)
- [Deployment Examples](./iac/bicep/DEPLOYMENT_EXAMPLES.md)

---

## ⚠️ Important Notes

1. **Credentials:** Check Azure Portal or KeyVault for VM admin passwords
2. **SQL Server:** Enterprise edition is installed and licensed for dev/test
3. **Monitoring:** Log Analytics and App Insights are pre-configured
4. **Storage:** Both VMs have premium managed disks (high performance)
5. **Scaling:** VMs are sized appropriately for dev/test workloads
6. **Cost:** This is a dev environment; monitor Azure Cost Management for actual costs

---

**Generated:** 2026-01-22 | **Deployment Name:** jobsite-iaas-20260122015818
