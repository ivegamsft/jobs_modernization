<#
.SYNOPSIS
Bootstrap Terraform backend infrastructure (Resource Group, Storage Account, Container).

.DESCRIPTION
Creates the necessary Azure resources for Terraform state management if they don't already exist.
Checks for and creates:
- Resource Group
- Storage Account (with appropriate SKU and settings)
- Storage Container for tfstate

.PARAMETER ResourceGroupName
The name of the resource group for Terraform state. Default: 'jobsite-tfstate-rg'

.PARAMETER StorageAccountName
The name of the storage account for Terraform state. Default: 'jobsitetfstate'

.PARAMETER Location
Azure region for resources. Default: 'swedencentral'

.PARAMETER ContainerName
Name of the storage container for tfstate. Default: 'tfstate'

.PARAMETER SubscriptionId
Azure Subscription ID. If not provided, uses current subscription.

.EXAMPLE
.\bootstrap-terraform-backend.ps1 -ResourceGroupName 'my-tfstate-rg' -StorageAccountName 'mytfstate' -Location 'eastus'

.EXAMPLE
.\bootstrap-terraform-backend.ps1
# Uses defaults

.NOTES
Requires:
- Azure CLI (az command)
- Appropriate Azure permissions to create RG and storage account
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = 'jobsite-tfstate-rg',
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = 'jobsitetfstate',
    
    [Parameter(Mandatory = $false)]
    [string]$Location = 'swedencentral',
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = 'tfstate',
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
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

# ============================================================================
# Main Script
# ============================================================================

Write-Header "Terraform Backend Bootstrap"

Write-Info "Parameters:"
Write-Host "  Resource Group:     $ResourceGroupName"
Write-Host "  Storage Account:    $StorageAccountName"
Write-Host "  Location:           $Location"
Write-Host "  Container:          $ContainerName"

if ($SubscriptionId) {
    Write-Host "  Subscription:       $SubscriptionId"
}

# Check Azure CLI
try {
    $null = az --version 2>&1
    Write-Success "Azure CLI is available"
}
catch {
    Write-Error "Azure CLI not found. Please install it first."
    exit 1
}

# Set subscription if specified
if ($SubscriptionId) {
    Write-Info "Setting subscription to $SubscriptionId..."
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to set subscription"
        exit 1
    }
    Write-Success "Subscription set"
}

# Get current subscription info
$currentSub = az account show --query "{id: id, name: name}" -o json | ConvertFrom-Json
Write-Info "Using subscription: $($currentSub.name) ($($currentSub.id))"

# ============================================================================
# Create/Check Resource Group
# ============================================================================

Write-Header "Resource Group"

$rgExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if ($rgExists) {
    Write-Success "Resource Group '$ResourceGroupName' already exists"
    $rg = az group show --name $ResourceGroupName --query "{name: name, location: location}" -o json | ConvertFrom-Json
    Write-Info "Location: $($rg.location)"
}
else {
    Write-Info "Creating Resource Group '$ResourceGroupName' in $Location..."
    $rg = az group create --name $ResourceGroupName --location $Location --query "{name: name, location: location, id: id}" -o json | ConvertFrom-Json
    Write-Success "Resource Group created"
    Write-Info "Resource ID: $($rg.id)"
}

# ============================================================================
# Create/Check Storage Account
# ============================================================================

Write-Header "Storage Account"

$storageExists = az storage account exists --name $StorageAccountName --resource-group $ResourceGroupName | ConvertFrom-Json
if ($storageExists.exists) {
    Write-Success "Storage Account '$StorageAccountName' already exists"
    $storage = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query "{name: name, id: id, primaryEndpoints: primaryEndpoints}" -o json | ConvertFrom-Json
    Write-Info "Storage ID: $($storage.id)"
}
else {
    Write-Info "Creating Storage Account '$StorageAccountName' in $ResourceGroupName..."
    try {
        $storage = az storage account create `
            --name $StorageAccountName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku "Standard_LRS" `
            --kind "StorageV2" `
            --access-tier "Hot" `
            --min-tls-version "TLS1_2" `
            --query "{name: name, id: id, primaryEndpoints: primaryEndpoints}" `
            -o json | ConvertFrom-Json
        
        Write-Success "Storage Account created"
        Write-Info "Storage ID: $($storage.id)"
    }
    catch {
        Write-Error "Failed to create Storage Account: $_"
        exit 1
    }
}

# Get storage account key
Write-Info "Retrieving storage account key..."
$storageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --query "[0].value" `
    -o tsv

if (-not $storageKey) {
    Write-Error "Failed to retrieve storage account key"
    exit 1
}
Write-Success "Storage account key retrieved"

# ============================================================================
# Create/Check Storage Container
# ============================================================================

Write-Header "Storage Container"

# Check if container exists
$containerExists = $false
try {
    $containers = az storage container list `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --query "[?name=='$ContainerName'].name" `
        -o tsv
    
    if ($containers) {
        $containerExists = $true
    }
}
catch {
    # If query fails, container likely doesn't exist
    $containerExists = $false
}

if ($containerExists) {
    Write-Success "Storage Container '$ContainerName' already exists"
}
else {
    Write-Info "Creating Storage Container '$ContainerName'..."
    try {
        az storage container create `
            --name $ContainerName `
            --account-name $StorageAccountName `
            --account-key $storageKey `
            --public-access off | Out-Null
        
        Write-Success "Storage Container created"
    }
    catch {
        Write-Error "Failed to create Storage Container: $_"
        exit 1
    }
}

# ============================================================================
# Output Configuration
# ============================================================================

Write-Header "Terraform Backend Configuration"

Write-Host "`nAdd the following to your backend-dev.hcl (or similar):" -ForegroundColor Cyan
Write-Host @"
resource_group_name  = "$ResourceGroupName"
storage_account_name = "$StorageAccountName"
container_name       = "$ContainerName"
key                  = "dev/terraform.tfstate"
"@ -ForegroundColor Yellow

Write-Host "`nTo initialize Terraform with this backend, run:" -ForegroundColor Cyan
Write-Host "  terraform init -backend-config=backend-dev.hcl" -ForegroundColor Yellow

Write-Host "`nOr use inline backend config:" -ForegroundColor Cyan
Write-Host "  terraform init -backend-config=""resource_group_name=$ResourceGroupName"" -backend-config=""storage_account_name=$StorageAccountName"" -backend-config=""container_name=$ContainerName"" -backend-config=""key=dev/terraform.tfstate""" -ForegroundColor Yellow

Write-Header "Bootstrap Complete"

Write-Success "All backend resources are ready for Terraform"
Write-Info "Summary:"
Write-Host "  • Resource Group:   $ResourceGroupName"
Write-Host "  • Storage Account:  $StorageAccountName"
Write-Host "  • Container:        $ContainerName"
Write-Host "  • Location:         $Location"
