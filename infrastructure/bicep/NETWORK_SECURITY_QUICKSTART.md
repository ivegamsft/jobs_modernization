# Quick Start - Network Security Setup

**⏱️ Time: 5 minutes to understand, 15-20 minutes to deploy**

---

## What Has Been Done ✅

Your infrastructure now has:

1. ✅ **Web VM** - Publicly accessible, connects to SQL
2. ✅ **SQL VM** - Private, protected, serves only your app
3. ✅ **Network Security** - NSG rules controlling all traffic
4. ✅ **NAT Gateway** - Single public IP for outbound traffic
5. ✅ **Complete Documentation** - 6 comprehensive guides

---

## The Architecture in 30 Seconds

```
Internet (HTTP/HTTPS on 80, 443)
    ↓
[Web VM - Frontend Subnet] ← Your application here
    ↓ (port 1433)
[SQL VM - Data Subnet] ← Your database here
    ↓
[NAT Gateway - Static Public IP] ← All outbound traffic
```

**That's it.** Everything is configured. The Web VM can talk to the SQL VM. Both are protected. One port (1433) allows communication between them.

---

## Before You Deploy

### ⚠️ IMPORTANT: Get Your IP Address

You'll need your public IP address to allow RDP access:

```powershell
# Run this in PowerShell or browser
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content

# Output will be something like: 203.0.113.0
```

**Save this IP** - You'll need it during deployment as `allowedRdpIps`.

---

## Deploy in 3 Steps

### Step 1: Choose Your Method

#### Option A: PowerShell (Easiest)

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to your repo
cd c:\git\jobs_modernization

# 3. Deploy core network
az deployment group create `
  --name jobsite-core `
  --resource-group rg-jobsite-dev `
  --template-file ./iac/bicep/core/main.bicep `
  --parameters @./iac/bicep/core/parameters.bicepparam

# 4. Deploy VMs and security
az deployment group create `
  --name jobsite-iaas `
  --resource-group rg-jobsite-dev `
  --template-file ./iac/bicep/iaas/main.bicep `
  --parameters `
    environment=dev `
    applicationName=jobsite `
    location=swedencentral `
    adminUsername=azureadmin `
    allowedRdpIps='["203.0.113.0/32"]'  # CHANGE TO YOUR IP!
```

#### Option B: Azure Portal

1. Go to Azure Portal
2. Search "Deploy custom template"
3. Upload `iac/bicep/iaas/main.bicep`
4. Fill in parameters
5. Click Deploy

#### Option C: Azure CLI (Script)

```bash
# See DEPLOYMENT_EXAMPLES.md for complete script
./iac/bicep/scripts/deploy-infrastructure.sh
```

### Step 2: Wait (15-20 minutes)

Azure will:

- Create the VMs
- Configure the network
- Apply security rules
- Start all services

### Step 3: Validate (5 minutes)

```powershell
# Test Web VM to SQL VM
Test-NetConnection -ComputerName <SQL_VM_PRIVATE_IP> -Port 1433

# Test RDP access (if your IP is in allowedRdpIps)
mstsc /v:<WEB_VM_IP>

# Done!
```

---

## Network Security Rules (What's Configured)

### Web VM - What Can Connect?

| Traffic          | From                    | Port        | Allowed? |
| ---------------- | ----------------------- | ----------- | -------- |
| Website          | Internet                | 80 (HTTP)   | ✅       |
| Website          | Internet                | 443 (HTTPS) | ✅       |
| Remote Desktop   | Your IP (allowedRdpIps) | 3389        | ✅       |
| Database Queries | SQL VM                  | 1433        | ✅       |
| Automation Tools | VNet                    | 5985-5986   | ✅       |

### SQL VM - What Can Connect?

| Traffic        | From                    | Port      | Allowed? |
| -------------- | ----------------------- | --------- | -------- |
| Queries        | Web VM                  | 1433      | ✅       |
| SSMS           | Admins (VNet)           | 1433      | ✅       |
| Remote Desktop | Your IP (allowedRdpIps) | 3389      | ✅       |
| Tools          | .NET Tools (VNet)       | 5985-5986 | ✅       |

### Blocked (Good Security)

| Traffic | Attempted         | Blocked Because           |
| ------- | ----------------- | ------------------------- |
| SSH     | Internet → Web VM | Not a Windows feature     |
| SQL     | Internet → SQL VM | Behind private subnet     |
| Any     | Random IPs → RDP  | Must be in allowedRdpIps  |
| Any     | Unauthorized IPs  | NSG rules deny by default |

---

## After Deployment - What You Get

### Infrastructure Resources

```
Resource Group: rg-jobsite-dev
├── Virtual Network (10.50.0.0/21)
│   ├── Frontend Subnet (10.50.0.0/24)
│   │   └── Web VM (jobsite-dev-wfe-xxx)
│   ├── Data Subnet (10.50.1.0/26)
│   │   └── SQL VM (jobsite-dev-sqlvm-xxx)
│   └── Other subnets (for expansion)
├── NAT Gateway (jobsite-dev-nat-xxx)
├── Public IP (jobsite-dev-pip-nat-xxx)
├── NSG - Frontend (jobsite-dev-nsg-frontend)
├── NSG - Data (jobsite-dev-nsg-data)
├── Network Interfaces (for each VM)
└── Storage (OS disks, SQL data/log)
```

### Network Access

```
✅ Your Web Application
   ↓
   Can query SQL Database on port 1433
   ✅

✅ Your Admin Team
   Can RDP to both VMs (if IP in allowedRdpIps)
   ✅

✅ .NET Automation Tools
   Can connect to SQL via direct connection
   Can use WinRM to both VMs
   ✅

✅ Internet Users
   Can access your website (80/443)
   ✓ Cannot access SQL directly
   ✓ Cannot SSH/RDP without authorization
   ✅ Safe!
```

---

## Common Tasks

### Task 1: Connect to Web VM via RDP

```
1. Make sure your IP is in allowedRdpIps (required at deployment)
2. Get the public IP of the Web VM from Azure Portal
3. Open Remote Desktop (mstsc.exe on Windows)
4. Enter: <PUBLIC_IP>
5. Username: azureadmin
6. Password: (what you entered at deployment)
```

### Task 2: Connect to SQL VM via SSMS

```
1. Get the PRIVATE IP of the SQL VM from Azure Portal
2. On any machine on the VNet, open SQL Server Management Studio
3. Server: <PRIVATE_IP>,1433
4. Authentication: Windows Authentication
5. Click Connect
6. Start managing your database!
```

### Task 3: Deploy Your Application

```
1. RDP to Web VM using instructions above
2. Install IIS, .NET, your application
3. Configure connection string to SQL VM private IP
4. Your app will automatically connect to database
5. Done!
```

### Task 4: Allow More RDP Access

```
To allow a new IP to RDP:

1. In Azure Portal, find the NSG (nsg-frontend or nsg-data)
2. Go to Inbound Rules
3. Find "AllowRDPFromAllowedIps"
4. Edit it
5. Add new IP to source addresses
6. Save
```

---

## Troubleshooting

### "Can't connect to SQL from Web VM"

1. Check if SQL Server is running on the SQL VM
2. Check if SQL is listening on port 1433
3. Verify NSG allows 1433 from Frontend to Data subnet
4. Check firewall on SQL VM

### "Can't RDP to Web VM"

1. Make sure your public IP is in allowedRdpIps
2. Check NSG allows 3389 from your IP
3. Verify RDP service is running on VM
4. Try from a different network to confirm

### "SSMS can't connect to SQL"

1. Make sure you're on the VNet (or VPN)
2. Use PRIVATE IP of SQL VM, not public
3. Use Windows Authentication (not SQL login)
4. Verify NSG allows 1433 from VirtualNetwork

### "Can't access website"

1. Check if IIS is installed on Web VM
2. Check if port 80/443 is open (should be by default)
3. Check firewall on Web VM allows HTTP/HTTPS
4. Check application is running and responding

---

## Documentation

If you need more details, check:

- **[NETWORK_SECURITY_SUMMARY.md](./NETWORK_SECURITY_SUMMARY.md)** - Overview (5 min)
- **[NETWORK_VISUAL_REFERENCE.md](./NETWORK_VISUAL_REFERENCE.md)** - Diagrams (10 min)
- **[NETWORK_SECURITY_CONFIGURATION.md](./NETWORK_SECURITY_CONFIGURATION.md)** - Details (20 min)
- **[NETWORK_SECURITY_VALIDATION.md](./NETWORK_SECURITY_VALIDATION.md)** - Testing (15 min)
- **[DEPLOYMENT_EXAMPLES.md](./DEPLOYMENT_EXAMPLES.md)** - Scripts (10 min)

---

## Security Checklist

After deployment, verify:

- [ ] Web VM is publicly accessible (HTTP/HTTPS work)
- [ ] SQL VM is NOT publicly accessible (cannot reach SQL from Internet)
- [ ] RDP works from authorized IPs only
- [ ] Web VM can query SQL VM (port 1433)
- [ ] SSMS can connect to SQL VM
- [ ] Outbound traffic uses NAT Gateway IP
- [ ] NSG rules are in place (Azure Portal)
- [ ] No unnecessary ports are open

---

## Cost Estimate

| Resource    | Size                      | Monthly Cost    |
| ----------- | ------------------------- | --------------- |
| Web VM      | D2ds_v6 (2 CPU, 8GB RAM)  | ~$100           |
| SQL VM      | D4ds_v6 (4 CPU, 16GB RAM) | ~$200           |
| Storage     | Premium SSD (300GB)       | ~$30            |
| NAT Gateway | Standard                  | ~$45            |
| VNet/Subnet | Basic networking          | ~$0 (free tier) |
| **Total**   |                           | **~$375/month** |

---

## Next Actions

1. ✅ Read this file (you're done!)
2. → Get your IP address (see "Before You Deploy" section)
3. → Deploy using Step 1-3 above
4. → Wait 15-20 minutes
5. → Validate using Step 3 above
6. → Access your infrastructure
7. → Celebrate! 🎉

---

## Still Have Questions?

### "Where are my VMs?"

Azure Portal → Virtual Machines → Look for `jobsite-dev-wfe-xxx` and `jobsite-dev-sqlvm-xxx`

### "What's the public IP of my Web VM?"

Azure Portal → Virtual Machines → jobsite-dev-wfe-xxx → Overview → Public IP address

### "What's the private IP of my SQL VM?"

Azure Portal → Virtual Machines → jobsite-dev-sqlvm-xxx → Overview → Private IP address

### "How do I change the NSG rules?"

Azure Portal → Network Security Groups → jobsite-dev-nsg-frontend/data → Inbound Rules → Edit

### "How do I add a new allowed RDP IP?"

See "Task 4: Allow More RDP Access" above

### "Can I access SQL from the Internet?"

No, and that's good! SQL is protected. Only accessible from VNet or Web VM.

### "Do I need VPN to connect to SQL?"

Only if you're not on the VNet already. If you're on-premises, use VPN or ExpressRoute.

---

## Quick Reference

**Your Infrastructure:**

- Web VM: `jobsite-dev-wfe-xxx` (Frontend Subnet 10.50.0.0/24)
- SQL VM: `jobsite-dev-sqlvm-xxx` (Data Subnet 10.50.1.0/26)
- NAT Gateway: `jobsite-dev-nat-xxx` (Static Public IP)
- Network: `jobsite-dev-vnet-xxx` (10.50.0.0/21)

**Key Ports:**

- 80: HTTP (Internet → Web VM)
- 443: HTTPS (Internet → Web VM)
- 1433: SQL (Web VM → SQL VM, Admins → SQL VM)
- 3389: RDP (allowedRdpIps → Both VMs)
- 5985/5986: WinRM (VNet → Both VMs)

**Default Credentials:**

- Username: azureadmin
- Password: (what you entered at deployment)

---

**You're all set! Your secure, isolated infrastructure is ready to go.** ✅

For detailed information, see [NETWORK_SECURITY_INDEX.md](./NETWORK_SECURITY_INDEX.md)
