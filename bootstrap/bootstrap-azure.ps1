<#
.SYNOPSIS
Master bootstrap script for Azure infrastructure prerequisites.

.DESCRIPTION
Orchestrates the creation of all Azure resources required before deploying infrastructure:
1. Service Principal with GitHub OIDC federation
2. Terraform backend (Storage Account for remote state)
3. Validates prerequisites and provides deployment guidance

This script should be run once per Azure subscription before any deployments.

.PARAMETER SubscriptionId
Azure Subscription ID. If not provided, uses current subscription.

.PARAMETER Location
Azure region for resources. Default: 'swedencentral'

.PARAMETER ResourceGroupScope
Optional resource group name(s) to scope Service Principal permissions.
If not provided, grants subscription-level Contributor access.

.PARAMETER SkipServicePrincipal
Skip Service Principal creation (if already exists).

.PARAMETER SkipTerraformBackend
Skip Terraform backend creation (if already exists or not using Terraform).

.PARAMETER GitHubOrg
GitHub organization or user name. If not provided, inferred from git remote.

.PARAMETER GitHubRepo
GitHub repository name. If not provided, inferred from git remote.

.EXAMPLE
.\bootstrap-azure.ps1

.EXAMPLE
.\bootstrap-azure.ps1 -SubscriptionId '<SUBSCRIPTION_ID>' -Location '<AZURE_REGION>'

.EXAMPLE
.\bootstrap-azure.ps1 -SkipTerraformBackend

.NOTES
Requires:
- Azure CLI (az command)
- PowerShell 7+
- Owner or User Access Administrator role on subscription
- Permissions to create Azure AD applications
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = 'swedencentral',
    
    [Parameter(Mandatory = $false)]
    [string[]]$ResourceGroupScope,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipServicePrincipal,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTerraformBackend,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo
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
        $patterns = @(
            'github.com[:/](?<org>[^/]+)/(?<repo>[^/.]+)(?:\.git)?$',
            '^https://github.com/(?<org>[^/]+)/(?<repo>[^/.]+)(?:\.git)?$'
        )

        foreach ($pattern in $patterns) {
            if ($cleanUrl -match $pattern) {
                return @{ GitHubOrg = $matches['org']; GitHubRepo = $matches['repo'] }
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $allGood = $true
    
    # Check Azure CLI
    Write-Info "Checking Azure CLI..."
    try {
        $azVersion = az version --query '\"azure-cli\"' -o tsv 2>$null
        Write-Success "Azure CLI installed: $azVersion"
    } catch {
        Write-Error "Azure CLI not found. Install from: https://aka.ms/azure-cli"
        $allGood = $false
    }
    
    # Check PowerShell version
    Write-Info "Checking PowerShell version..."
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Success "PowerShell $($PSVersionTable.PSVersion)"
    } else {
        Write-Warning "PowerShell 7+ recommended (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check Azure login
    Write-Info "Checking Azure authentication..."
    try {
        $account = az account show --query '{user: user.name, subscription: name}' -o json | ConvertFrom-Json
        Write-Success "Logged in as: $($account.user)"
        Write-Info "Current subscription: $($account.subscription)"
    } catch {
        Write-Error "Not logged in to Azure. Run 'az login' first"
        $allGood = $false
    }
    
    if (-not $allGood) {
        Write-Error "Prerequisites check failed. Please resolve issues above."
        exit 1
    }
    
    Write-Success "All prerequisites met"
}

# ============================================================================
# Main Script
# ============================================================================

Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║             Azure Infrastructure Bootstrap                                 ║
║             Jobs Modernization Project                                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check prerequisites
Test-Prerequisites

# Set subscription if provided
if ($SubscriptionId) {
    Write-Info "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
} else {
    $currentSub = az account show --query '{id: id, name: name}' -o json | ConvertFrom-Json
    $SubscriptionId = $currentSub.id
    Write-Info "Using current subscription: $($currentSub.name)"
}

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

# Summary
Write-Header "Bootstrap Configuration"
Write-Host @"
  Subscription ID:   $SubscriptionId
  Location:          $Location
  GitHub Org:        $GitHubOrg
  GitHub Repo:       $GitHubRepo
  
  Components:
    Service Principal:     $(if ($SkipServicePrincipal) { 'SKIP' } else { 'CREATE' })
    Terraform Backend:     $(if ($SkipTerraformBackend) { 'SKIP' } else { 'CREATE' })
"@

Write-Host "`nPress Enter to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
Read-Host

# ============================================================================
# 1. Service Principal & OIDC
# ============================================================================

if (-not $SkipServicePrincipal) {
    Write-Header "Step 1: Service Principal & GitHub OIDC"
    
    $spParams = @{
        SubscriptionId = $SubscriptionId
        GitHubOrg = $GitHubOrg
        GitHubRepo = $GitHubRepo
    }
    
    if ($ResourceGroupScope) {
        $spParams['ResourceGroupScope'] = $ResourceGroupScope
    }
    
    & "$PSScriptRoot\bootstrap-service-principal.ps1" @spParams
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Service Principal creation failed"
        exit 1
    }
} else {
    Write-Info "Skipping Service Principal creation (use -SkipServicePrincipal:`$false to create)"
}

# ============================================================================
# 2. Terraform Backend
# ============================================================================

if (-not $SkipTerraformBackend) {
    Write-Header "Step 2: Terraform Backend Storage"
    
    & "$PSScriptRoot\bootstrap-terraform-backend.ps1" -Location $Location -SubscriptionId $SubscriptionId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform backend creation failed"
        exit 1
    }
} else {
    Write-Info "Skipping Terraform backend creation (use -SkipTerraformBackend:`$false to create)"
}

# ============================================================================
# Final Summary & Next Steps
# ============================================================================

Write-Header "Bootstrap Complete!"

Write-Host @"

┌─────────────────────────────────────────────────────────────────────────┐
│                              SUCCESS                                     │
└─────────────────────────────────────────────────────────────────────────┘

Azure infrastructure prerequisites have been configured.

Next Steps:

  1. Configure GitHub Secrets
     Navigate to: https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions
     
     Required secrets were printed by the Service Principal script above.
     Copy and paste:
       - AZURE_CLIENT_ID
       - AZURE_TENANT_ID  
       - AZURE_SUBSCRIPTION_ID

  2. Deploy Core Infrastructure
     Run the core infrastructure deployment:
     
     # Using Bicep:
     cd infrastructure/scripts
     .\deploy-core.ps1 -Environment dev -Location $Location
     
     # Or using Terraform:
     cd infrastructure/terraform
     terraform init -backend-config=backend-dev.hcl
     terraform apply -var-file=dev.tfvars

  3. Deploy Application Infrastructure
     Choose your deployment path:
     
     # IaaS (VMs + SQL Server):
     .\deploy-iaas.ps1 -Environment dev
     
     # PaaS (App Service + Azure SQL):
     .\deploy-paas.ps1 -Environment dev

  4. Set up GitHub Actions Workflows
     The workflows in .github/workflows/ are ready to use.
     They will automatically use OIDC authentication with the
     Service Principal created above.

Documentation:
  - Infrastructure: infrastructure/README.md
  - Workflows: .github/workflows/WORKFLOW_ORGANIZATION.md
  - Multi-phase migration: See phase1-legacy-baseline/, phase2-azure-migration/, phase3-modernization/

"@ -ForegroundColor Green

Write-Success "Bootstrap process completed successfully!"
