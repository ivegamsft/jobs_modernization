<#
.SYNOPSIS
Environment setup helper for JobSite AppV3

.DESCRIPTION
Interactively creates .env file with secure values and proper validation

.EXAMPLE
.\setup-environment.ps1
#>

$ErrorActionPreference = 'Stop'

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $Message".PadRight(66) -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

Write-Header "JobSite AppV3 Environment Configuration Helper"

# Check if .env exists
if (Test-Path .env) {
    Write-Warning ".env file already exists"
    $response = Read-Host "Back it up and recreate? (y/n)"
    if ($response -ne 'y') {
        Write-Info "Exiting without changes"
        exit 0
    }
    Copy-Item .env .env.backup
    Remove-Item .env
    Write-Success "Backed up to .env.backup"
}

# Generate SECRET_KEY
Write-Info "Generating SECRET_KEY..."
$bytes = [byte[]]::new(32)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$SECRET_KEY = [Convert]::ToBase64String($bytes)
Write-Success "SECRET_KEY generated"

# Get SQL Server password
Write-Host ""
Write-Host "🔒 SQL Server Password Configuration" -ForegroundColor Yellow
Write-Host "   Requirements: 8+ chars, uppercase, lowercase, number, special char"

do {
    $MSSQL_SA_PASSWORD = Read-Host "   Enter MSSQL_SA_PASSWORD" -AsSecureString
    $plainPassword = [System.Net.NetworkCredential]::new('', $MSSQL_SA_PASSWORD).Password
    
    if ($plainPassword.Length -lt 8) {
        Write-Error "Password too short (minimum 8 characters)"
    }
    elseif ($plainPassword -notmatch '[A-Z]') {
        Write-Error "Password must contain uppercase letters"
    }
    elseif ($plainPassword -notmatch '[a-z]') {
        Write-Error "Password must contain lowercase letters"
    }
    elseif ($plainPassword -notmatch '[0-9]') {
        Write-Error "Password must contain numbers"
    }
    elseif ($plainPassword -notmatch '[!@#$%^&*()_+=\[\]{};:,.<>?]') {
        Write-Error "Password must contain special characters"
    }
    else {
        Write-Success "Password validated"
        break
    }
} while ($true)

# Get database URL
Write-Host ""
Write-Host "📊 Database Configuration" -ForegroundColor Yellow
Write-Host "   SQL Server example:"
Write-Host "   mssql+pyodbc://sa:PASSWORD@sqlserver:1433/JobsDB?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
Write-Host "   PostgreSQL example:"
Write-Host "   postgresql://user:pass@localhost:5432/jobsite_db"

do {
    $DATABASE_URL = Read-Host "   Enter DATABASE_URL"
    if ([string]::IsNullOrWhiteSpace($DATABASE_URL)) {
        Write-Error "DATABASE_URL cannot be empty"
    }
    else {
        break
    }
} while ($true)

# Create .env file
$envContent = @"
# Flask Application
FLASK_APP=run.py
FLASK_ENV=development
FLASK_DEBUG=1

# Security
SECRET_KEY=$SECRET_KEY

# Database Configuration
DATABASE_URL=$DATABASE_URL

# SQL Server Settings
MSSQL_SA_PASSWORD=$plainPassword

# Application Settings
APP_NAME=JobSite
ITEMS_PER_PAGE=10
"@

Set-Content -Path .env -Value $envContent -Encoding UTF8
Write-Success ".env file created successfully!"
Write-Info "Location: $(Get-Location)\.env"
Write-Info "Permissions: Readable by current user only"

Write-Host ""
Write-Host "⚡ Next steps:" -ForegroundColor Yellow
Write-Host "   1. Ensure Docker Desktop is running"
Write-Host "   2. Run: docker-compose up -d"
Write-Host "   3. Wait for SQL Server to be healthy: docker-compose logs -f sqlserver"
Write-Host "   4. Access app at: http://localhost:5000"
Write-Host ""

Write-Host "📋 To verify connectivity:" -ForegroundColor Yellow
Write-Host "   docker-compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q 'SELECT @@version'"
Write-Host ""

Write-Success "Setup complete!"
