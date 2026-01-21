# IIS Installation Script for VMSS Instances

# This script is executed during VMSS provisioning to install and configure IIS

param(
    [string]$AppPath = "C:\inetpub\wwwroot\jobsite"
)

# Enable error handling
$ErrorActionPreference = "Stop"

Write-Host "Starting IIS installation..." -ForegroundColor Green

try {
    # Install IIS and required features
    Write-Host "Installing IIS and features..." -ForegroundColor Cyan
    
    Install-WindowsFeature -Name Web-Server `
        -IncludeManagementTools `
        -IncludeAllSubFeature `
        -ErrorAction Stop

    Install-WindowsFeature -Name Web-Asp-Net45 `
        -IncludeAllSubFeature `
        -ErrorAction Stop

    Install-WindowsFeature -Name Web-Net-Ext45 `
        -ErrorAction Stop

    Install-WindowsFeature -Name Web-Windows-Auth `
        -ErrorAction Stop

    Install-WindowsFeature -Name Web-Url-Rewrite `
        -ErrorAction Stop

    # Start IIS services
    Write-Host "Starting IIS services..." -ForegroundColor Cyan
    Start-Service W3SVC -ErrorAction Stop
    Start-Service WAS -ErrorAction Stop

    # Set services to auto-start
    Set-Service -Name W3SVC -StartupType Automatic
    Set-Service -Name WAS -StartupType Automatic
    Set-Service -Name IISADMIN -StartupType Automatic

    # Create application directory if specified
    if (-not (Test-Path $AppPath)) {
        Write-Host "Creating application directory: $AppPath" -ForegroundColor Cyan
        New-Item -Path $AppPath -ItemType Directory -Force | Out-Null
    }

    # Create a default health check page
    $healthCheckHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>JobSite Health Check</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .healthy { color: green; font-weight: bold; }
        .info { background-color: #f0f0f0; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>JobSite Application</h1>
    <p class="healthy">✓ IIS is operational</p>
    <div class="info">
        <p><strong>Server:</strong> $(hostname)</p>
        <p><strong>Time:</strong> $(Get-Date)</p>
        <p><strong>IIS Version:</strong> $([System.Environment]::OSVersion.VersionString)</p>
    </div>
    <p>For application deployment, replace this page with your application files.</p>
</body>
</html>
"@

    $healthCheckPath = Join-Path $AppPath "index.html"
    Set-Content -Path $healthCheckPath -Value $healthCheckHtml -Force

    Write-Host "IIS installation completed successfully!" -ForegroundColor Green
    Write-Host "Health check page available at: http://localhost/index.html" -ForegroundColor Green
    
    # Log completion
    "$(Get-Date): IIS installation completed successfully" | Add-Content -Path "C:\iis-install.log" -Force

}
catch {
    Write-Host "Error during IIS installation: $_" -ForegroundColor Red
    "$(Get-Date): ERROR - $_" | Add-Content -Path "C:\iis-install.log" -Force
    exit 1
}
