# VM Extensions Configuration

## Overview

Comprehensive VM extensions configured for security, monitoring, management, and specialized workloads across all infrastructure VMs and VMSS.

## Extension Matrix

| Extension                | WFE VM | SQL VM | Build Agents VMSS | Purpose                                  |
| ------------------------ | ------ | ------ | ----------------- | ---------------------------------------- |
| **Azure AD Auth**        | ✅     | ✅     | ✅                | Entra ID authentication for secure login |
| **Anti-malware**         | ✅     | ✅     | ✅                | Real-time protection, scheduled scans    |
| **Guest Configuration**  | ✅     | ✅     | ✅                | Azure Policy compliance monitoring       |
| **Azure Monitor Agent**  | ✅     | ✅     | ✅                | Centralized monitoring and metrics       |
| **Dependency Agent**     | ✅     | ✅     | ✅                | VM Insights and service dependencies     |
| **Key Vault Extension**  | ✅     | ✅     | ✅                | Automatic certificate/secret retrieval   |
| **DSC (IIS)**            | ✅     | ❌     | ❌                | IIS web server configuration             |
| **Application Insights** | ✅     | ❌     | ❌                | Application performance monitoring       |
| **SQL VM Extension**     | ❌     | ✅     | ❌                | SQL Server management and optimization   |
| **Azure DevOps Agent**   | ❌     | ❌     | ✅                | CI/CD pipeline execution                 |
| **Custom Script (RDP)**  | ✅     | ✅     | ❌                | Enable Remote Desktop access             |

## Extension Details

### 1. Azure AD (Entra) Authentication

**Extension:** `AADLoginForWindows`
**Publisher:** `Microsoft.Azure.ActiveDirectory`
**Version:** 2.0

**Purpose:**

- Enables Azure AD-based authentication for RDP/SSH
- Replaces local admin accounts with cloud identities
- Supports MFA and conditional access policies

**Benefits:**

- No password management (uses Azure AD credentials)
- Centralized access control
- Audit logging in Azure AD

**Usage:**

```powershell
# Login with Azure AD account
mstsc /v:51.12.90.221:50001
# Username: AzureAD\user@domain.com
```

---

### 2. Anti-malware Protection

**Extension:** `IaaSAntimalware`
**Publisher:** `Microsoft.Azure.Security`
**Version:** 1.3

**Configuration:**

- ✅ Real-time protection enabled
- ✅ Weekly scheduled scans (Sunday, 2:00 AM)
- ✅ Quick scan type for performance
- Exclusions:
  - **WFE:** `.log`, `.ldf` files, `C:\Windows\Temp`
  - **SQL:** `.log`, `.ldf`, `.mdf`, `.ndf` files, SQL Server folders

**Benefits:**

- Built-in Windows Defender integration
- Automatic signature updates
- No additional licensing cost

---

### 3. Guest Configuration (Machine Config)

**Extension:** `AzurePolicyforWindows`
**Publisher:** `Microsoft.GuestConfiguration`
**Version:** 1.0

**Purpose:**

- Enables Azure Policy guest configuration
- Continuous compliance monitoring
- Configuration drift detection

**Capabilities:**

- Audit OS configurations
- Enforce security baselines
- Report compliance status to Azure Policy

---

### 4. Azure Monitor Agent (AMA)

**Extension:** `AzureMonitorWindowsAgent`
**Publisher:** `Microsoft.Azure.Monitor`
**Version:** 1.0

**Purpose:**

- Next-generation monitoring agent
- Replaces Log Analytics Agent (MMA/OMS)
- Data Collection Rules (DCR) support

**Collects:**

- Performance metrics
- Event logs
- Custom logs
- IIS logs (WFE)
- SQL Server logs (SQL VM)

---

### 5. Dependency Agent

**Extension:** `DependencyAgentWindows`
**Publisher:** `Microsoft.Azure.Monitoring.DependencyAgent`
**Version:** 9.10

**Purpose:**

- Enables VM Insights service map
- Tracks network connections
- Identifies application dependencies

**Provides:**

- Process-level visibility
- Network traffic analysis
- Dependency mapping
- Performance correlation

---

### 6. Key Vault Extension

**Extension:** `KeyVaultForWindows`
**Publisher:** `Microsoft.Azure.KeyVault`
**Version:** 3.0

**Configuration:**

- Polling interval: 3600 seconds (1 hour)
- Authentication: Managed Identity
- Auto-sync: Disabled (manual trigger)

**Purpose:**

- Automatically download certificates from Key Vault
- Store in Windows certificate store
- Refresh on interval

**Use Cases:**

- SSL/TLS certificates for IIS
- Code signing certificates
- Service authentication certificates

---

### 7. DSC Extension (WFE Only)

**Extension:** `DSC`
**Publisher:** `Microsoft.Powershell`
**Version:** 2.77

**Configuration:**

- Script: `ContosoWebsite.ps1`
- Function: `ContosoWebsite`
- Source: Azure Quickstart Templates

**Purpose:**

- Automated IIS installation and configuration
- Web site deployment
- App pool configuration
- Firewall rules

**Installs:**

- IIS Web Server role
- .NET Framework features
- ASP.NET runtime
- Management tools

---

### 8. Application Insights (WFE Only)

**Extension:** `ApplicationInsightsMonitoringWindows`
**Publisher:** `Microsoft.Azure.Diagnostics`
**Version:** 2.8

**Purpose:**

- Codeless application performance monitoring
- Auto-instrumentation for .NET apps
- Distributed tracing
- Performance metrics

**Collects:**

- Request rates and response times
- Dependency calls
- Exceptions and failures
- Custom metrics

**Note:** Requires Application Insights resource in core infrastructure.

---

### 9. SQL VM Extension (SQL VM Only)

**Extension:** `SqlVirtualMachine`
**Publisher:** `Microsoft.SqlVirtualMachine`
**Version:** 2023-10-01

**Configuration:**

- SQL Management: Full
- License: AHUB (Azure Hybrid Benefit)
- Connectivity: Private
- Port: 1433
- Auto-backup: Disabled

**Features:**

- Automated patching
- Automated backup (when enabled)
- SQL best practices assessment
- Storage optimization
- License compliance

---

### 10. Azure DevOps Agent (Build Agents VMSS Only)

**Extension:** `CustomScriptExtension` (DevOps Agent)
**Publisher:** `Microsoft.Compute`
**Version:** 1.10

**Configuration:**

- Agent version: 3.236.1
- Install path: `C:\agent`
- Mode: Service (runs as Windows service)
- Pool: Configurable (default: "Default")

**Process:**

1. Downloads Azure DevOps agent package
2. Extracts to `C:\agent`
3. Configures with organization URL and PAT
4. Registers to specified agent pool
5. Runs as Windows service

**Requirements:**

- Azure DevOps organization URL
- Personal Access Token (PAT) with Agent Pools (read, manage) scope
- Agent pool name

---

### 11. Custom Script Extension (RDP Enable)

**Extension:** `CustomScriptExtension`
**Publisher:** `Microsoft.Compute`
**Version:** 1.10

**Purpose:**

- Enable Remote Desktop Protocol (RDP)
- Configure Windows Firewall
- Start Terminal Services

**Actions:**

```powershell
Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Terminal Server `
    -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService
```

---

## Managed Identity Configuration

All VMs and VMSS have **System-Assigned Managed Identity** enabled.

**Benefits:**

- No credential management in code
- Automatic Key Vault access
- Azure service authentication
- RBAC-based access control

**Access:**

- Key Vault: Secrets Officer role (assigned via RBAC)
- Azure Monitor: Monitoring Contributor
- Storage Account: Blob Data Reader (if needed)

---

## Extension Dependencies

Extensions are deployed in sequence to avoid conflicts:

### WFE VM Extension Chain:

```
RDP Enable → Azure AD → Anti-malware → Guest Config →
Azure Monitor → Dependency Agent → Key Vault → DSC → App Insights
```

### SQL VM Extension Chain:

```
RDP Enable → Azure AD → Anti-malware → Guest Config →
Azure Monitor → Dependency Agent → Key Vault → SQL VM Extension
```

### Build Agents VMSS Extensions:

All extensions are deployed in parallel within the VMSS extension profile.

---

## Troubleshooting

### Check Extension Status

```powershell
# WFE VM
az vm extension list `
    --resource-group jobsite-iaas-dev-rg `
    --vm-name jobsite-dev-wfe-<suffix> `
    --query "[].{Name:name, Status:provisioningState}" -o table

# SQL VM
az vm extension list `
    --resource-group jobsite-iaas-dev-rg `
    --vm-name jobsite-dev-sqlvm-<suffix> `
    --query "[].{Name:name, Status:provisioningState}" -o table

# Build Agents VMSS
az vmss extension list `
    --resource-group jobsite-agents-dev-rg `
    --vmss-name jobsite-dev-gh-runners-<suffix> `
    --query "[].{Name:name, Publisher:publisher}" -o table
```

### View Extension Logs

On the VM, extension logs are located at:

```
C:\WindowsAzure\Logs\Plugins\<Publisher>.<ExtensionName>\<Version>\
```

### Common Issues

**Anti-malware not starting:**

- Check Windows Defender service status
- Verify exclusions don't block critical files

**Key Vault extension failing:**

- Verify managed identity has Key Vault access
- Check Key Vault firewall rules
- Ensure secrets exist in vault

**DSC extension failing:**

- Check internet connectivity for script download
- Verify PowerShell execution policy
- Review DSC configuration script

**Azure DevOps agent not registering:**

- Verify PAT token is valid and not expired
- Check organization URL is correct
- Ensure agent pool exists
- Verify network connectivity to Azure DevOps

---

## Security Best Practices

✅ **Implemented:**

- Managed identities for all authentication
- Anti-malware with real-time protection
- Guest configuration for compliance
- Dependency tracking for security analysis
- Key Vault integration for secrets

🔐 **Recommendations:**

- Enable Azure Defender for VMs
- Configure Data Collection Rules for detailed logging
- Set up Azure Policy guest assignments
- Enable JIT access instead of permanent RDP
- Use Azure Bastion for production

---

## Cost Implications

| Extension            | Cost | Notes                                   |
| -------------------- | ---- | --------------------------------------- |
| Azure AD Auth        | Free | Included with Azure AD                  |
| Anti-malware         | Free | Windows Defender included               |
| Guest Configuration  | Free | Azure Policy included                   |
| Azure Monitor Agent  | Free | Agent is free, data ingestion charged   |
| Dependency Agent     | Free | Agent is free, data ingestion charged   |
| Key Vault Extension  | Free | Key Vault operations charged separately |
| DSC                  | Free | Extension free, compute time only       |
| Application Insights | Paid | Based on data ingestion (~$2.30/GB)     |
| SQL VM Extension     | Free | Included with SQL Server licensing      |
| Azure DevOps Agent   | Free | Parallel jobs may require licensing     |

**Estimated Monthly Costs:**

- Azure Monitor data ingestion: $50-200/month (all VMs)
- Application Insights: $20-100/month (WFE only)
- Total: $70-300/month for monitoring

---

## Deployment Parameters

### IaaS Main Bicep

```bicep
module iaasResources './iaas-resources.bicep' = {
  params: {
    keyVaultName: 'kv-dev-swc-ubzfsgu4p5'
    appInsightsInstrumentationKey: '<from-core-outputs>'
    appInsightsConnectionString: '<from-core-outputs>'
  }
}
```

### Agents Main Bicep

```bicep
module agentsResources './agents-resources.bicep' = {
  params: {
    keyVaultName: 'kv-dev-swc-ubzfsgu4p5'
    azureDevOpsOrgUrl: 'https://dev.azure.com/<org>'
    azureDevOpsPat: '<secure-pat-token>'
    azureDevOpsAgentPool: 'Default'
  }
}
```

---

## Monitoring and Alerts

### Recommended Alerts:

1. **Extension Failures:**
   - Alert when extension provisioning fails
   - Severity: High

2. **Anti-malware Threats:**
   - Alert on malware detection
   - Severity: Critical

3. **Compliance Drift:**
   - Alert on Guest Configuration non-compliance
   - Severity: Medium

4. **Performance Issues:**
   - CPU > 80% for 15 minutes
   - Memory > 90% for 10 minutes
   - Disk latency > 50ms
   - Severity: Warning

### Dashboards:

- VM Insights: Service map and performance
- Application Insights: App performance dashboard
- Azure Monitor: Custom workbooks for infrastructure
- Azure Policy: Compliance dashboard

---

## Next Steps

1. **Deploy IaaS VMs:**

   ```powershell
   cd C:\git\jobs_modernization\iac
   .\deploy-iaas-clean.ps1
   ```

2. **Verify Extensions:**
   - Check Azure Portal → VM → Extensions + applications
   - Review extension logs for any errors

3. **Configure Application Insights:**
   - Create Application Insights resource in core
   - Update IaaS deployment with instrumentation key

4. **Deploy Build Agents:**
   - Generate Azure DevOps PAT token
   - Update agents deployment with PAT
   - Deploy VMSS

5. **Test Functionality:**
   - RDP with Azure AD credentials
   - Verify IIS is running on WFE
   - Check SQL Server connectivity
   - Test DevOps agent registration
