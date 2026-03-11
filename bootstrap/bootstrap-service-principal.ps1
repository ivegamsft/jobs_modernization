<#
.SYNOPSIS
Creates Azure Service Principal for GitHub Actions deployment with OIDC federation.

.DESCRIPTION
Creates or updates a Service Principal with:
- Contributor role on specified subscription or resource groups
- Federated credentials for GitHub OIDC authentication
- Proper naming and tagging for governance

.PARAMETER AppName
The display name for the Azure AD Application. If omitted, generated from repository name.

.PARAMETER SubscriptionId
Azure Subscription ID where permissions will be granted. If not provided, uses current subscription.

.PARAMETER ResourceGroupScope
Optional resource group name(s) to scope permissions. If not provided, grants subscription-level access.
Can be a single string or array of strings.

.PARAMETER GitHubOrg
GitHub organization or user name. If not provided, inferred from git remote.

.PARAMETER GitHubRepo
GitHub repository name. If not provided, inferred from git remote.

.PARAMETER GitHubEnvironments
GitHub environments to create federated credentials for. Default: @('dev', 'staging', 'prod')

.PARAMETER CreateMainBranchCredential
Create a federated credential for main branch pushes. Default: $true

.EXAMPLE
.\bootstrap-service-principal.ps1

.EXAMPLE
.\bootstrap-service-principal.ps1 -ResourceGroupScope 'jobsite-dev-rg','jobsite-prod-rg'

.EXAMPLE
.\bootstrap-service-principal.ps1 -GitHubOrg '<GITHUB_ORG>' -GitHubRepo '<GITHUB_REPO>' -SubscriptionId '<SUBSCRIPTION_ID>'

.NOTES
Requires:
- Azure CLI (az command)
- Owner or User Access Administrator role on the subscription/resource groups
- Permission to create Azure AD applications
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$AppName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ResourceGroupScope,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory = $false)]
    [string[]]$GitHubEnvironments = @('dev', 'staging', 'prod'),
    
    [Parameter(Mandatory = $false)]
    [bool]$CreateMainBranchCredential = $true
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# Functions
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host "`n$('='*80)" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=$('='*79)" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Get-GitHubRepoContext {
    param([string]$WorkingPath)

    try {
        $remoteUrl = git -C $WorkingPath remote get-url origin 2>$null
        if (-not $remoteUrl) {
            return $null
        }

        $cleanUrl = $remoteUrl.Trim()
        if ($cleanUrl -match 'github.com[:/](?<org>[^/]+)/(?<repo>[^/.]+)(?:\.git)?$') {
            return @{ GitHubOrg = $matches['org']; GitHubRepo = $matches['repo'] }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-DefaultAppName {
    param([string]$RepoName)

    $sanitized = ($RepoName -replace '[^a-zA-Z0-9-]', '-').ToLowerInvariant()
    return "github-actions-$sanitized-deploy"
}

# ============================================================================
# Main Script
# ============================================================================

Write-Header "Service Principal & OIDC Bootstrap"

# Check Azure CLI
Write-Info "Checking Azure CLI installation..."
try {
    $azVersion = az version --query '\"azure-cli\"' -o tsv 2>$null
    Write-Success "Azure CLI version: $azVersion"
} catch {
    Write-Error "Azure CLI is not installed or not in PATH"
    Write-Host "Install from: https://aka.ms/azure-cli"
    exit 1
}

# Set or get subscription
if ($SubscriptionId) {
    Write-Info "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
} else {
    $currentSub = az account show --query '{id: id, name: name}' -o json | ConvertFrom-Json
    $SubscriptionId = $currentSub.id
    Write-Info "Using current subscription: $($currentSub.name) ($SubscriptionId)"
}

# Verify login
Write-Info "Verifying Azure authentication..."
$account = az account show --query '{user: user.name, tenant: tenantId}' -o json | ConvertFrom-Json
if (-not $account) {
    Write-Error "Not logged in to Azure. Run 'az login' first"
    exit 1
}
Write-Success "Logged in as: $($account.user)"
$tenantId = $account.tenant

# Resolve GitHub repo context if not explicitly provided
if ([string]::IsNullOrWhiteSpace($GitHubOrg) -or [string]::IsNullOrWhiteSpace($GitHubRepo)) {
    $repoContext = Get-GitHubRepoContext -WorkingPath (Join-Path $PSScriptRoot '..')
    if ($repoContext) {
        if ([string]::IsNullOrWhiteSpace($GitHubOrg)) {
            $GitHubOrg = $repoContext.GitHubOrg
        }
        if ([string]::IsNullOrWhiteSpace($GitHubRepo)) {
            $GitHubRepo = $repoContext.GitHubRepo
        }
        Write-Info "Inferred GitHub repository: $GitHubOrg/$GitHubRepo"
    }
}

if ([string]::IsNullOrWhiteSpace($GitHubOrg) -or [string]::IsNullOrWhiteSpace($GitHubRepo)) {
    Write-Error "GitHubOrg and GitHubRepo are required. Pass them as parameters or run from a git repo with an origin remote."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = Get-DefaultAppName -RepoName $GitHubRepo
    Write-Info "Generated AppName: $AppName"
}

# ============================================================================
# Create or Get Service Principal
# ============================================================================

Write-Header "Service Principal Creation"

# Check if app already exists
Write-Info "Checking for existing application '$AppName'..."
$existingApp = az ad app list --display-name $AppName --query "[0]" -o json 2>$null | ConvertFrom-Json

if ($existingApp) {
    Write-Warning "Application '$AppName' already exists"
    $appId = $existingApp.appId
    $objectId = $existingApp.id
    Write-Info "App ID: $appId"
    Write-Info "Object ID: $objectId"
} else {
    Write-Info "Creating new application '$AppName'..."
    $newApp = az ad app create --display-name $AppName --query '{appId: appId, id: id}' -o json | ConvertFrom-Json
    $appId = $newApp.appId
    $objectId = $newApp.id
    Write-Success "Application created: $appId"
}

# Check if service principal exists
Write-Info "Checking for service principal..."
$existingSp = az ad sp list --filter "appId eq '$appId'" --query "[0].id" -o tsv 2>$null

if ($existingSp) {
    Write-Success "Service principal already exists: $existingSp"
    $spObjectId = $existingSp
} else {
    Write-Info "Creating service principal..."
    $spObjectId = az ad sp create --id $appId --query "id" -o tsv
    Write-Success "Service principal created: $spObjectId"
}

# ============================================================================
# Assign Roles
# ============================================================================

Write-Header "Role Assignment"

if ($ResourceGroupScope) {
    Write-Info "Assigning Contributor role to resource groups..."
    foreach ($rgName in $ResourceGroupScope) {
        Write-Info "  - Resource Group: $rgName"
        
        # Check if RG exists
        $rgExists = az group exists --name $rgName
        if ($rgExists -eq 'false') {
            Write-Warning "Resource Group '$rgName' does not exist. Skipping..."
            continue
        }
        
        # Assign role
        try {
            az role assignment create `
                --assignee $appId `
                --role "Contributor" `
                --resource-group $rgName `
                --output none 2>$null
            Write-Success "Contributor role assigned to $rgName"
        } catch {
            Write-Warning "Role may already exist or assignment failed: $_"
        }
    }
} else {
    Write-Info "Assigning Contributor role at subscription level..."
    try {
        az role assignment create `
            --assignee $appId `
            --role "Contributor" `
            --scope "/subscriptions/$SubscriptionId" `
            --output none 2>$null
        Write-Success "Contributor role assigned to subscription"
    } catch {
        Write-Warning "Role may already exist or assignment failed: $_"
    }
}

# ============================================================================
# Create Federated Credentials for GitHub OIDC
# ============================================================================

Write-Header "GitHub OIDC Federated Credentials"

$repoPath = "$GitHubOrg/$GitHubRepo"
Write-Info "Repository: $repoPath"

# Helper function to create federated credential
function New-FederatedCredential {
    param(
        [string]$Name,
        [string]$Subject,
        [string]$Description
    )
    
    Write-Info "Creating federated credential: $Name"
    Write-Info "  Subject: $Subject"
    
    # Check if credential already exists
    $existing = az ad app federated-credential list --id $objectId --query "[?name=='$Name']" -o json | ConvertFrom-Json
    
    if ($existing) {
        Write-Warning "Federated credential '$Name' already exists. Updating..."
        try {
            az ad app federated-credential update `
                --id $objectId `
                --federated-credential-id $existing[0].id `
                --subject $Subject `
                --output none
            Write-Success "Updated: $Name"
        } catch {
            Write-Warning "Update may have failed: $_"
        }
    } else {
        try {
            az ad app federated-credential create `
                --id $objectId `
                --parameters @"
{
    \"name\": \"$Name\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"$Subject\",
    \"audiences\": [\"api://AzureADTokenExchange\"],
    \"description\": \"$Description\"
}
"@ `
                --output none
            Write-Success "Created: $Name"
        } catch {
            Write-Error "Failed to create federated credential '$Name': $_"
        }
    }
}

# Create credential for main branch
if ($CreateMainBranchCredential) {
    New-FederatedCredential `
        -Name "github-main-branch" `
        -Subject "repo:$repoPath:ref:refs/heads/main" `
        -Description "GitHub Actions deployments from main branch"
}

# Create credentials for each environment
foreach ($env in $GitHubEnvironments) {
    New-FederatedCredential `
        -Name "github-env-$env" `
        -Subject "repo:$repoPath:environment:$env" `
        -Description "GitHub Actions deployments to $env environment"
}

# ============================================================================
# Output Summary
# ============================================================================

Write-Header "Setup Complete"

Write-Host @"

Service Principal Details:
  Application Name:    $AppName
  Application ID:      $appId
  Object ID:           $objectId
  Tenant ID:           $tenantId
  Subscription ID:     $SubscriptionId

GitHub Secrets Required:
  Add these secrets to your GitHub repository settings:
  
  AZURE_CLIENT_ID:        $appId
  AZURE_TENANT_ID:        $tenantId
  AZURE_SUBSCRIPTION_ID:  $SubscriptionId

Next Steps:
    1. Add the secrets above to GitHub: https://github.com/$repoPath/settings/secrets/actions
    2. Configure your GitHub workflows to use the three secrets above with azure/login@v2.
    3. Trigger a deployment workflow and confirm Azure login succeeds.

"@

Write-Success "Bootstrap complete!"
