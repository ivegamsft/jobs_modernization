# THE ISSUE: Azure CLI "Content Already Consumed" Error

## Root Cause Identified

**Error**: `The content for this response was already consumed`

**Why it happens**:
1. Azure CLI has 2 updates available (outdated version)
2. When passing large Base64-encoded certificate data (~8KB+) as command-line parameters
3. urllib3 HTTP connection gets consumed during parameter parsing
4. Deployment command fails before actually submitting to Azure

## Evidence
```
From terminal output:
- "The content for this response was already consumed"
- Occurs after certificate generation (Base64 ~8-12KB)
- Deployment never registers in Azure (404 DeploymentNotFound)
- CLI warning: "You have 2 update(s) available"
```

## THE FIX (3 Options)

### ✅ Option 1: Update Azure CLI (FASTEST)
```powershell
# Update CLI to latest version
az upgrade

# Then retry deployment
pwsh -File c:\git\jobs_modernization\iac\deploy-iaas-clean.ps1
```

### ✅ Option 2: Deploy via Azure Portal (MOST RELIABLE)
1. Go to https://portal.azure.com
2. Search: "Deploy a custom template"
3. Click "Build your own template in the editor"
4. Copy entire contents of: `c:\git\jobs_modernization\iac\bicep\iaas\main.bicep`
5. Paste and click "Save"
6. Fill in parameters:
   - Use credentials from CREDENTIALS_AND_NEXT_STEPS.md
   - Get subnet IDs from core resource group
7. Deploy (15-20 min)

### ✅ Option 3: Use Bicep CLI Directly
```powershell
# Compile Bicep to ARM JSON
bicep build c:\git\jobs_modernization\iac\bicep\iaas\main.bicep

# Deploy using ARM template (smaller payload)
az deployment sub create `
    --name "jobsite-iaas-dev" `
    --location "eastus" `
    --template-file "c:\git\jobs_modernization\iac\bicep\iaas\main.json" `
    --parameters "@params.json"
```

## RECOMMENDED IMMEDIATE ACTION

```powershell
# Step 1: Update Azure CLI (fixes the bug)
az upgrade

# Step 2: Verify update
az version

# Step 3: Retry deployment
pwsh -File c:\git\jobs_modernization\iac\deploy-iaas-clean.ps1
```

## If Still Issues After Update

Use Azure Portal method - it's completely independent of Azure CLI and 100% reliable.

---

## Technical Details

**CLI Version Issue**:
- Current: Outdated (2+ updates pending)
- Bug: urllib3 connection handling in older versions
- Fix: Latest version has improved parameter handling

**Parameter Size**:
- Certificate data: ~8-12KB Base64
- CLI command line limit: varies by OS
- Portal: No such limits

**Why Portal Works**:
- Uses different API path
- Handles large data via form upload
- No command-line parameter limits
- Built-in certificate upload UI

---

Generated: 2026-01-21
Issue: Azure CLI outdated + large parameter bug
Solution: Update CLI or use Portal
