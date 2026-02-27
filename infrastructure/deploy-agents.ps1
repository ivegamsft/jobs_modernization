# Deploy Agents Infrastructure
# Deploys GitHub Runners VMSS for CI/CD

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AGENTS DEPLOYMENT SCRIPT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Parameters
$environment = "dev"
$applicationName = "jobsite"
$location = "swedencentral"
$agentTemplateFile = "./bicep/agents/main.bicep"

# ============================================================================
# Get Azure DevOps Configuration
# ============================================================================

Write-Host "0. Configuring Azure DevOps agent pool..." -ForegroundColor Yellow
$azureDevOpsOrgUrl = Read-Host "   Enter your Azure DevOps organization URL (e.g., https://dev.azure.com/myorg)"
$azureDevOpsPat = Read-Host "   Enter your Azure DevOps Personal Access Token (PAT)" -AsSecureString
$azureDevOpsAgentPool = Read-Host "   Enter agent pool name (default: 'Default')" 

if ([string]::IsNullOrEmpty($azureDevOpsAgentPool)) {
    $azureDevOpsAgentPool = "Default"
}

# Convert secure string to plain text for template
$azureDevOpsPatPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemAlloc($azureDevOpsPat))

Write-Host "   ✅ Azure DevOps configuration captured" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Get Core Outputs
# ============================================================================

Write-Host "1. Retrieving core infrastructure outputs..." -ForegroundColor Yellow
$coreDeployment = az deployment sub show --name "jobsite-core-dev" -o json | ConvertFrom-Json

if (-not $coreDeployment) {
    Write-Host "❌ Core deployment not found. Deploy core infrastructure first." -ForegroundColor Red
    exit 1
}

$outputs = $coreDeployment.properties.outputs

Write-Host "   ✅ Core outputs retrieved" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Get or Generate Admin Password
# ============================================================================

Write-Host "2. Managing agent credentials..." -ForegroundColor Yellow

$keyVaultName = $outputs.keyVaultName.value

# Try to get existing password from Key Vault
$existingPassword = az keyvault secret show --vault-name $keyVaultName --name "agents-admin-password" -o json 2>$null | ConvertFrom-Json

if ($existingPassword) {
    $adminPassword = $existingPassword.value
    Write-Host "   ✅ Using existing password from Key Vault" -ForegroundColor Green
}
else {
    # Generate new password - must meet Windows complexity requirements
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $special = "!@#$%^&*"
    $password = ""
    $password += $chars[(Get-Random -Maximum $chars.Length)].ToString().ToUpper()  # Uppercase
    $password += $chars[(Get-Random -Maximum $chars.Length)]  # Lowercase
    $password += (0..9 | Get-Random)  # Number
    $password += $special[(Get-Random -Maximum $special.Length)]  # Special char
    $password += -join ((1..12) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    
    $adminPassword = $password
    
    # Store in Key Vault
    az keyvault secret set --vault-name $keyVaultName --name "agents-admin-password" --value $adminPassword | Out-Null
    Write-Host "   ✅ Generated and stored new password in Key Vault" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# Deploy Agents Infrastructure
# ============================================================================

Write-Host "3. Deploying agents infrastructure..." -ForegroundColor Yellow

$agentParams = @{
    environment          = $environment
    applicationName      = $applicationName
    location             = $location
    adminPassword        = $adminPassword
    agentVmSize          = "Standard_D2ds_v6"
    vmssInstanceCount    = 2
    azureDevOpsOrgUrl    = $azureDevOpsOrgUrl
    azureDevOpsPat       = $azureDevOpsPatPlain
    azureDevOpsAgentPool = $azureDevOpsAgentPool
}

$paramString = $agentParams.GetEnumerator() | ForEach-Object {
    if ($_.Value -is [securestring]) {
        "$($_.Key)=$($_.Value)"
    }
    elseif ($_.Value -is [string] -and $_.Value.StartsWith("/subscriptions/")) {
        "$($_.Key)=$($_.Value)"
    }
    else {
        "$($_.Key)=$($_.Value)"
    }
}

Write-Host "   Deploying from: $agentTemplateFile" -ForegroundColor Gray
Write-Host "   Parameters: environment=$environment, location=$location, vmSize=D2ds_v6" -ForegroundColor Gray

$deployment = az deployment sub create `
    --template-file $agentTemplateFile `
    --location $location `
    --parameters @agentParams `
    -o json 2>&1

if ($?) {
    Write-Host "   ✅ Agents deployment submitted" -ForegroundColor Green
    
    $deploymentId = $deployment | ConvertFrom-Json | Select-Object -ExpandProperty id
    Write-Host "   Deployment ID: $deploymentId" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "4. Waiting for deployment to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    $status = az deployment sub show --name "jobsite-agents-dev" --query "properties.provisioningState" -o tsv
    Write-Host "   Status: $status" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ AGENTS DEPLOYMENT INITIATED" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}
else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deployment -ForegroundColor Red
    exit 1
}
