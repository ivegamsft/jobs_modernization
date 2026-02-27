# Deploying Legacy ASP.NET to Azure VM

## Overview

This guide covers deploying the legacy ASP.NET 2.0 Web Forms application to an Azure Virtual Machine with IIS.

## Architecture

```
Internet
   ↓
Application Gateway / Load Balancer
   ↓
Azure VM (Windows Server 2022)
   ├── IIS with ASP.NET
   └── SQL Server 2022 (optional)
   ↓
Azure SQL Database (or on-VM SQL Server)
```

## Prerequisites

- Azure subscription
- RDP client (Remote Desktop)
- Legacy application code
- SQL Server database (BACPAC or backup file)

## Step 1: Create Azure VM

### Using Azure Portal

1. Go to Virtual Machines → Create
2. Configure:
   - Subscription: Select your subscription
   - Resource Group: `rg-jobsite-vm`
   - VM Name: `jobsite-vm`
   - Region: East US
   - Image: `Windows Server 2022 Datacenter`
   - Size: `Standard_B2s` (2 vCPU, 4 GB RAM)
   - Admin Username: `azureuser`
   - Admin Password: Generate strong password
   - Inbound Rules: Allow RDP (3389), HTTP (80), HTTPS (443)

3. Click "Review + Create" → "Create"

### Using Azure CLI

```powershell
# Variables
$resourceGroup = "rg-jobsite-vm"
$location = "eastus"
$vmName = "jobsite-vm"
$imageUrn = "MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest"
$vmSize = "Standard_B2s"
$adminUser = "azureuser"
$adminPassword = "P@ssw0rd123!Secure"

# Create Resource Group
az group create --name $resourceGroup --location $location

# Create Network Security Group
az network nsg create `
  --name jobsite-nsg `
  --resource-group $resourceGroup `
  --location $location

# Add inbound rules
az network nsg rule create `
  --nsg-name jobsite-nsg `
  --resource-group $resourceGroup `
  --name AllowRDP `
  --priority 100 `
  --direction Inbound `
  --access Allow `
  --protocol Tcp `
  --source-address-prefixes "*" `
  --destination-address-prefixes "*" `
  --source-port-ranges "*" `
  --destination-port-ranges 3389

az network nsg rule create `
  --nsg-name jobsite-nsg `
  --resource-group $resourceGroup `
  --name AllowHTTP `
  --priority 200 `
  --direction Inbound `
  --access Allow `
  --protocol Tcp `
  --destination-port-ranges 80

az network nsg rule create `
  --nsg-name jobsite-nsg `
  --resource-group $resourceGroup `
  --name AllowHTTPS `
  --priority 300 `
  --direction Inbound `
  --access Allow `
  --protocol Tcp `
  --destination-port-ranges 443

# Create Virtual Machine
az vm create `
  --name $vmName `
  --resource-group $resourceGroup `
  --image $imageUrn `
  --size $vmSize `
  --admin-username $adminUser `
  --admin-password $adminPassword `
  --nsg jobsite-nsg `
  --public-ip-sku Standard

# Open ports
az vm open-port --resource-group $resourceGroup --name $vmName --port 80
az vm open-port --resource-group $resourceGroup --name $vmName --port 443
az vm open-port --resource-group $resourceGroup --name $vmName --port 3389
```

## Step 2: Connect to VM

```powershell
# Get public IP
$publicIP = az vm list-ip-addresses --resource-group rg-jobsite-vm --name jobsite-vm --query [0].virtualMachines[0].ipAddresses[0].ipAddress -o tsv

# Connect via RDP
mstsc /v:$publicIP

# Or use Azure Bastion for secure connection
# Portal → VM → Bastion → Connect
```

## Step 3: Configure Windows Server

### Install IIS and ASP.NET

```powershell
# Run as Administrator

# Install IIS with ASP.NET 4.8
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

Install-WindowsFeature -Name Web-AppInit
Install-WindowsFeature -Name Web-Asp-Net45

# Install URL Rewrite
Invoke-WebRequest `
  -Uri "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44F4-B6A6-3D50EADEA485/rewrite_amd64_en-US.msi" `
  -OutFile "UrlRewrite.msi"

msiexec.exe /i UrlRewrite.msi /quiet

# Install Web Deploy
Invoke-WebRequest `
  -Uri "https://aka.ms/webdeploy" `
  -OutFile "WebDeploy.msi"

msiexec.exe /i WebDeploy.msi ADDLOCAL=ALL /quiet
```

### Enable Necessary IIS Features

```powershell
# Enable ISAPI Extensions
Enable-WindowsOptionalFeature -FeatureName IIS-ISAPIExtensions -Online -NoRestart

# Enable ISAPI Filters
Enable-WindowsOptionalFeature -FeatureName IIS-ISAPIFilter -Online -NoRestart

# Enable Static Content
Enable-WindowsOptionalFeature -FeatureName IIS-StaticContent -Online -NoRestart

# Restart IIS
iisreset /restart
```

## Step 4: Install SQL Server (Optional - if on-VM)

### Install SQL Server 2022

```powershell
# Download SQL Server 2022 Developer Edition
$sqlUrl = "https://go.microsoft.com/fwlink/p/?linkid=2216019"
$sqlInstaller = "C:\sql_server_installer.exe"

Invoke-WebRequest -Uri $sqlUrl -OutFile $sqlInstaller

# Run installer
& $sqlInstaller /ConfigurationFile="C:\ConfigurationFile.ini"
```

### Or Use Azure SQL Database

```powershell
# Skip installation, use managed service instead
# See DEPLOY_TO_AZURE_PAAS.md for Azure SQL setup
```

## Step 5: Restore Database

### Option A: Restore from BACPAC

```powershell
# Copy BACPAC file to VM
# Then restore in SQL Server Management Studio

# Or via PowerShell:
$backupFile = "C:\JsskDb.bak"
$sqlInstance = "localhost"
$database = "JobSiteDb"

# Restore database
sqlcmd -S $sqlInstance -U sa -P "Password123!" -Q "RESTORE DATABASE [$database] FROM DISK = N'$backupFile'"
```

### Option B: Copy from On-Premises

```powershell
# On legacy server:
# Backup database to file

# Copy file to Azure VM using:
# - Copy-Item (if connected to same network)
# - Azure File Share
# - SCP/WinSCP

# Then restore in SQL Server
```

## Step 6: Create IIS Website

### Using IIS Manager

1. Open IIS Manager
2. Right-click "Sites" → "Add Website"
3. Configure:
   - Site name: `JobSite`
   - Physical path: `C:\inetpub\wwwroot\jobsite`
   - Binding:
     - Type: http
     - IP: All Unassigned
     - Port: 80
     - Host name: (leave blank)

### Using PowerShell

```powershell
# Create directory
New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\jobsite"

# Create IIS site
New-IISSite -Name "JobSite" `
  -BindingInformation "*:80:" `
  -PhysicalPath "C:\inetpub\wwwroot\jobsite" `
  -Passthru

# Create application pool
New-WebAppPool -Name "JobSitePool"

# Configure app pool
$appPool = Get-IISAppPool "JobSitePool"
$appPool.ProcessModel.IdentityType = "ApplicationPoolIdentity"
$appPool | Set-Item

# Assign pool to site
Set-ItemProperty "IIS:\Sites\JobSite" -Name "applicationPool" -Value "JobSitePool"
```

## Step 7: Deploy Application Files

### Option A: Copy Files Directly

```powershell
# Copy from local machine
Copy-Item -Path "C:\path\to\jobsite\*" -Destination "C:\inetpub\wwwroot\jobsite" -Recurse

# Or copy from network share
net use Z: \\fileserver\share /user:domain\user password
Copy-Item -Path "Z:\jobsite\*" -Destination "C:\inetpub\wwwroot\jobsite" -Recurse
```

### Option B: Use Web Deploy

```powershell
# On local machine:
& "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe" `
  -verb:sync `
  -source:contentPath="C:\path\to\local\jobsite" `
  -dest:contentPath="Default Web Site/JobSite",
  ComputerName="https://$publicIP:8172/msdeploy.axd",
  UserName="azureuser",
  Password="$password",
  AuthType="Basic"
```

## Step 8: Update Configuration

### Update web.config

```xml
<configuration>
  <connectionStrings>
    <!-- For on-VM SQL Server -->
    <add name="connectionstring"
         connectionString="Server=localhost;Database=JobSiteDb;User Id=sa;Password=YourPassword;"
         providerName="System.Data.SqlClient" />

    <!-- For Azure SQL Database -->
    <add name="connectionstring"
         connectionString="Server=tcp:jobsite-sqlserver.database.windows.net,1433;Initial Catalog=JobSiteDb;Persist Security Info=False;User ID=sqladmin;Password=YourPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
         providerName="System.Data.SqlClient" />
  </connectionStrings>

  <system.web>
    <compilation debug="false" />
    <customErrors mode="RemoteOnly" />
  </system.web>
</configuration>
```

## Step 9: Configure Security

### Enable HTTPS

```powershell
# Request SSL certificate from Let's Encrypt or Azure
# Or use self-signed for testing:

New-SelfSignedCertificate `
  -DnsName "jobsite-vm.eastus.cloudapp.azure.com" `
  -CertStoreLocation "cert:\LocalMachine\My"

# Import certificate to IIS
# IIS Manager → Server Certificates → Import

# Create HTTPS binding
New-WebBinding -Name "JobSite" `
  -Protocol "https" `
  -Port 443 `
  -CertificateThumbprint "THUMBPRINT"
```

### Configure Firewall

```powershell
# Allow HTTP/HTTPS through Windows Firewall
New-NetFirewallRule -DisplayName "Allow HTTP" `
  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80

New-NetFirewallRule -DisplayName "Allow HTTPS" `
  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443

# Restrict RDP to specific IPs (optional)
New-NetFirewallRule -DisplayName "Allow RDP from Office" `
  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389 `
  -RemoteAddress "203.0.113.0/24"
```

## Step 10: Testing

```powershell
# Test website access
$url = "http://jobsite-vm.eastus.cloudapp.azure.com"
Invoke-WebRequest -Uri $url

# Check IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\*.log" -Tail 20

# Test SQL connection
sqlcmd -S localhost -U sa -P "Password123!" -Q "SELECT 1"
```

## Monitoring & Maintenance

### Enable Monitoring

```powershell
# Install Azure Monitor Agent
& "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureConnectedMachineAgent.exe" /install

# Set up alerts
# In Portal: VM → Monitoring → Alerts → Create alert rule

# Monitor disk space
Get-Volume | Where-Object {$_.DriveLetter -eq "C"} | Select-Object SizeRemaining
```

### Backup VM

```bash
# Create backup vault
az backup vault create `
  --resource-group rg-jobsite-vm `
  --name jobsite-backup-vault `
  --location eastus

# Enable backup
az backup protection enable-for-vm `
  --resource-group rg-jobsite-vm `
  --vault-name jobsite-backup-vault `
  --vm jobsite-vm `
  --policy-name DefaultPolicy
```

## Troubleshooting

### Website Not Accessible

```powershell
# Check IIS status
iisreset /status

# Check app pool status
Get-WebAppPoolState -Name "JobSitePool"

# Check bindings
Get-WebBinding -Name "JobSite"

# Test HTTP directly on VM
Invoke-WebRequest -Uri "http://localhost"
```

### SQL Connection Failed

```powershell
# Check SQL Server status
Get-Service -Name MSSQLSERVER

# Test connection
sqlcmd -S localhost -U sa -P "Password" -Q "SELECT 1"

# Check connection string in web.config
Select-String -Path "C:\inetpub\wwwroot\jobsite\web.config" -Pattern "connectionString"
```

### High Memory Usage

```powershell
# Restart app pool
Restart-WebAppPool -Name "JobSitePool"

# Check memory
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10
```

## Next Steps

1. Configure automated backups
2. Set up monitoring and alerts
3. Configure load balancer for HA
4. Set up disaster recovery
5. Plan migration to modern architecture
