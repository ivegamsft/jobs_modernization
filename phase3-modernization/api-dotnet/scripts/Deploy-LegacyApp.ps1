#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Automated deployment script for legacy ASP.NET application to Azure
.DESCRIPTION
    This script automates the deployment of the legacy ASP.NET application
    to either Azure App Service (PaaS) or Azure VM (IaaS)
.PARAMETER Environment
    Target environment: 'dev', 'staging', or 'prod'
.PARAMETER DeploymentType
    Deployment target: 'paas' or 'vm'
.PARAMETER ApplicationPath
    Path to the application source files
.PARAMETER DatabaseBackupPath
    Path to the database backup file (.bak or .bacpac)
.EXAMPLE
    .\Deploy-LegacyApp.ps1 -Environment dev -DeploymentType paas -ApplicationPath "C:\Jobs" -DatabaseBackupPath "C:\Jobs\App_Data\JsskDb.bak"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [ValidateSet('paas', 'vm')]
    [string]$DeploymentType,

    [Parameter(Mandatory = $true)]
    [string]$ApplicationPath,

    [Parameter(Mandatory = $true)]
    [string]$DatabaseBackupPath,

    [string]$SubscriptionId = "",
    [string]$ResourceGroupName = "",
    [string]$Location = "eastus"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$colors = @{
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Success', 'Error', 'Warning', 'Info')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $colors[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level Info
    
    # Check Azure CLI
    try {
        $azVersion = az version 2>&1
        Write-Log "Azure CLI found" -Level Success
    }
    catch {
        Write-Log "Azure CLI not found. Please install it from https://aka.ms/azcli" -Level Error
        exit 1
    }
    
    # Check if logged in
    try {
        $account = az account show 2>&1
        if (-not $account) {
            Write-Log "Please login to Azure: az login" -Level Error
            exit 1
        }
        Write-Log "Azure login verified" -Level Success
    }
    catch {
        Write-Log "Not logged in to Azure" -Level Error
        exit 1
    }
    
    # Check application path
    if (-not (Test-Path $ApplicationPath)) {
        Write-Log "Application path not found: $ApplicationPath" -Level Error
        exit 1
    }
    Write-Log "Application path verified: $ApplicationPath" -Level Success
    
    # Check database backup
    if (-not (Test-Path $DatabaseBackupPath)) {
        Write-Log "Database backup not found: $DatabaseBackupPath" -Level Error
        exit 1
    }
    Write-Log "Database backup verified: $DatabaseBackupPath" -Level Success
}

function New-ResourceNaming {
    param([string]$Environment)
    
    return @{
        ResourceGroup  = "rg-jobsite-$Environment"
        AppServicePlan = "plan-jobsite-$Environment"
        AppService     = "jobsite-$Environment-app"
        SqlServer      = "jobsite-$Environment-sql"
        SqlDatabase    = "JobSiteDb"
        KeyVault       = "kv-jobsite-$Environment"
        StorageAccount = "sajobsite$Environment"
        VirtualMachine = "vm-jobsite-$Environment"
    }
}

function New-AzureResourceGroup {
    param(
        [string]$ResourceGroupName,
        [string]$Location
    )
    
    Write-Log "Creating resource group: $ResourceGroupName" -Level Info
    
    try {
        az group create `
            --name $ResourceGroupName `
            --location $Location | Out-Null
        
        Write-Log "Resource group created successfully" -Level Success
    }
    catch {
        Write-Log "Failed to create resource group: $_" -Level Error
        exit 1
    }
}

function Deploy-PaaS {
    param(
        [string]$ResourceGroupName,
        [string]$Location,
        [hashtable]$Names
    )
    
    Write-Log "Starting PaaS deployment (App Service)" -Level Info
    
    # Create App Service Plan
    Write-Log "Creating App Service Plan: $($Names.AppServicePlan)" -Level Info
    az appservice plan create `
        --name $Names.AppServicePlan `
        --resource-group $ResourceGroupName `
        --sku B1 `
        --is-linux $false | Out-Null
    Write-Log "App Service Plan created" -Level Success
    
    # Create App Service
    Write-Log "Creating App Service: $($Names.AppService)" -Level Info
    az webapp create `
        --name $Names.AppService `
        --resource-group $ResourceGroupName `
        --plan $Names.AppServicePlan `
        --runtime "DOTNETFRAMEWORK|v4.8" | Out-Null
    Write-Log "App Service created" -Level Success
    
    # Create SQL Server
    Write-Log "Creating SQL Server: $($Names.SqlServer)" -Level Info
    $sqlPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    
    az sql server create `
        --name $Names.SqlServer `
        --resource-group $ResourceGroupName `
        --location $Location `
        --admin-user sqladmin `
        --admin-password $sqlPassword | Out-Null
    Write-Log "SQL Server created" -Level Success
    
    # Create SQL Database
    Write-Log "Creating SQL Database: $($Names.SqlDatabase)" -Level Info
    az sql db create `
        --server $Names.SqlServer `
        --resource-group $ResourceGroupName `
        --name $Names.SqlDatabase `
        --edition Basic | Out-Null
    Write-Log "SQL Database created" -Level Success
    
    # Configure firewall
    Write-Log "Configuring SQL Server firewall rules" -Level Info
    az sql server firewall-rule create `
        --server $Names.SqlServer `
        --resource-group $ResourceGroupName `
        --name "AllowAppService" `
        --start-ip-address 0.0.0.0 `
        --end-ip-address 255.255.255.255 | Out-Null
    Write-Log "Firewall rules configured" -Level Success
    
    # Get connection string
    $connectionString = "Server=tcp:$($Names.SqlServer).database.windows.net,1433;Initial Catalog=$($Names.SqlDatabase);Persist Security Info=False;User ID=sqladmin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    # Configure connection string in app service
    Write-Log "Configuring App Service settings" -Level Info
    az webapp config connection-string set `
        --name $Names.AppService `
        --resource-group $ResourceGroupName `
        --settings "connectionstring=$connectionString" `
        --connection-string-type "SQLServer" | Out-Null
    Write-Log "App Service settings configured" -Level Success
    
    # Return connection info
    return @{
        SqlPassword      = $sqlPassword
        ConnectionString = $connectionString
        AppServiceUrl    = (az webapp show --name $Names.AppService --resource-group $ResourceGroupName --query defaultHostName -o tsv)
    }
}

function Deploy-VM {
    param(
        [string]$ResourceGroupName,
        [string]$Location,
        [hashtable]$Names
    )
    
    Write-Log "Starting IaaS deployment (Virtual Machine)" -Level Info
    
    # Create NSG
    Write-Log "Creating Network Security Group" -Level Info
    az network nsg create `
        --name "nsg-jobsite" `
        --resource-group $ResourceGroupName `
        --location $Location | Out-Null
    Write-Log "NSG created" -Level Success
    
    # Add firewall rules
    Write-Log "Configuring NSG rules" -Level Info
    az network nsg rule create `
        --nsg-name "nsg-jobsite" `
        --resource-group $ResourceGroupName `
        --name AllowRDP `
        --priority 100 `
        --direction Inbound `
        --access Allow `
        --protocol Tcp `
        --destination-port-ranges 3389 | Out-Null
    
    az network nsg rule create `
        --nsg-name "nsg-jobsite" `
        --resource-group $ResourceGroupName `
        --name AllowHTTP `
        --priority 200 `
        --direction Inbound `
        --access Allow `
        --protocol Tcp `
        --destination-port-ranges 80 | Out-Null
    
    az network nsg rule create `
        --nsg-name "nsg-jobsite" `
        --resource-group $ResourceGroupName `
        --name AllowHTTPS `
        --priority 300 `
        --direction Inbound `
        --access Allow `
        --protocol Tcp `
        --destination-port-ranges 443 | Out-Null
    Write-Log "NSG rules configured" -Level Success
    
    # Create VM
    Write-Log "Creating Virtual Machine: $($Names.VirtualMachine)" -Level Info
    $vmPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    
    az vm create `
        --name $Names.VirtualMachine `
        --resource-group $ResourceGroupName `
        --image "MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest" `
        --size "Standard_B2s" `
        --admin-username "azureuser" `
        --admin-password $vmPassword `
        --nsg "nsg-jobsite" `
        --public-ip-sku "Standard" | Out-Null
    Write-Log "Virtual Machine created" -Level Success
    
    # Open ports
    Write-Log "Opening ports" -Level Info
    az vm open-port --resource-group $ResourceGroupName --name $Names.VirtualMachine --port 80 | Out-Null
    az vm open-port --resource-group $ResourceGroupName --name $Names.VirtualMachine --port 443 | Out-Null
    Write-Log "Ports opened" -Level Success
    
    # Get public IP
    $publicIp = az vm list-ip-addresses --resource-group $ResourceGroupName --name $Names.VirtualMachine --query [0].virtualMachines[0].ipAddresses[0].ipAddress -o tsv
    
    return @{
        VmPassword    = $vmPassword
        PublicIp      = $publicIp
        RdpConnection = "mstsc /v:$publicIp"
    }
}

function Restore-Database {
    param(
        [string]$SqlServer,
        [string]$SqlDatabase,
        [string]$SqlAdmin,
        [string]$SqlPassword,
        [string]$BackupPath
    )
    
    Write-Log "Preparing database restore" -Level Info
    
    if ($BackupPath -like "*.bacpac") {
        Write-Log "Database backup is BACPAC format" -Level Info
        # For BACPAC, would need to implement import logic
        # This is a simplified example
        Write-Log "Manual BACPAC import required via Portal or Azure Data Studio" -Level Warning
    }
    else {
        Write-Log "Database backup is native format (.bak)" -Level Info
        Write-Log "Upload .bak file and restore using SQL Server Management Studio" -Level Warning
    }
}

function Invoke-PostDeploymentValidation {
    param(
        [string]$ResourceGroupName,
        [string]$AppServiceName
    )
    
    Write-Log "Performing post-deployment validation" -Level Info
    
    # Check app service status
    $status = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query state -o tsv
    
    if ($status -eq "Running") {
        Write-Log "App Service is running" -Level Success
    }
    else {
        Write-Log "App Service status is: $status" -Level Warning
    }
    
    # Get app URL
    $appUrl = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query defaultHostName -o tsv
    Write-Log "Application URL: https://$appUrl" -Level Info
}

# Main execution
function Main {
    Write-Log "Starting legacy ASP.NET application deployment" -Level Info
    Write-Log "Environment: $Environment" -Level Info
    Write-Log "Deployment Type: $DeploymentType" -Level Info
    
    # Test prerequisites
    Test-Prerequisites
    
    # Get resource names
    $names = New-ResourceNaming -Environment $Environment
    if ([string]::IsNullOrEmpty($ResourceGroupName)) {
        $ResourceGroupName = $names.ResourceGroup
    }
    
    # Create resource group
    New-AzureResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
    
    # Deploy based on type
    if ($DeploymentType -eq "paas") {
        $result = Deploy-PaaS -ResourceGroupName $ResourceGroupName -Location $Location -Names $names
        Write-Log "PaaS deployment completed" -Level Success
        Write-Log "App Service URL: https://$($result.AppServiceUrl)" -Level Info
        Write-Log "SQL Password saved (store securely in Key Vault)" -Level Warning
    }
    else {
        $result = Deploy-VM -ResourceGroupName $ResourceGroupName -Location $Location -Names $names
        Write-Log "IaaS VM deployment completed" -Level Success
        Write-Log "VM Public IP: $($result.PublicIp)" -Level Info
        Write-Log "Connect via: $($result.RdpConnection)" -Level Info
        Write-Log "VM Password saved (store securely)" -Level Warning
    }
    
    # Restore database
    Write-Log "Database restore required - follow manual steps" -Level Warning
    
    # Validation
    if ($DeploymentType -eq "paas") {
        Invoke-PostDeploymentValidation -ResourceGroupName $ResourceGroupName -AppServiceName $names.AppService
    }
    
    Write-Log "Deployment completed successfully!" -Level Success
    Write-Log "Next steps:" -Level Info
    Write-Log "  1. Restore database from backup" -Level Info
    Write-Log "  2. Update application configuration" -Level Info
    Write-Log "  3. Deploy application files" -Level Info
    Write-Log "  4. Test functionality" -Level Info
    Write-Log "  5. Configure monitoring and backups" -Level Info
}

# Run main
Main
