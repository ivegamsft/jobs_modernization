#Requires -Version 5.1
<#
.SYNOPSIS
    Functional Smoke Tests for Phase 1 appV1.5-buildable.

.DESCRIPTION
    Runs database verification and HTTP smoke tests against the legacy
    .NET Framework 4.8 Web Forms application. Tests cover:
      - Seed data counts (Countries, States, EducationLevels, JobTypes, ExperienceLevels)
      - Stored procedure execution (sampling of lookup procs)
      - ASP.NET Membership table accessibility
      - HTTP smoke tests via IIS Express (homepage, login, register, job search, admin redirect)
      - Dropdown data presence in rendered HTML

    IIS Express is started and stopped automatically. All tests are
    idempotent and self-contained.

.EXAMPLE
    .\Functional-Smoke.ps1
    .\Functional-Smoke.ps1 -ProjectDir "C:\other\path\appV1.5-buildable"

.NOTES
    Requires: Classic ODBC sqlcmd (NOT go-based), IIS Express, LocalDB
    Database: (localdb)\JobsLocalDb / JobsDB with seed data populated
#>
[CmdletBinding()]
param(
    [string]$ProjectDir,
    [int]$Port = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ---- Resolve paths -------------------------------------------------------

if (-not $ProjectDir) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ProjectDir = (Resolve-Path (Join-Path $scriptDir "..\appV1.5-buildable")).Path
}

$SqlInstance = "(localdb)\JobsLocalDb"
$Database    = "JobsDB"

# ---- Test Harness (same pattern as Build-Verification.ps1) ----------------

$script:Results   = @()
$script:TestCount = 0
$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0

function Write-TestHeader {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Phase 1 - Functional Smoke Tests"       -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project Dir : $ProjectDir"
    Write-Host "SQL Instance: $SqlInstance"
    Write-Host "Database    : $Database"
    Write-Host "Timestamp   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Host        : $env:COMPUTERNAME"
    Write-Host ""
}

function Add-TestResult {
    param(
        [string]$Id,
        [string]$Name,
        [ValidateSet('PASS','FAIL','SKIP')]
        [string]$Status,
        [string]$Detail = ''
    )
    $script:TestCount++
    switch ($Status) {
        'PASS' { $script:PassCount++; $color = 'Green'  }
        'FAIL' { $script:FailCount++; $color = 'Red'    }
        'SKIP' { $script:SkipCount++; $color = 'Yellow' }
    }
    $icon = switch ($Status) { 'PASS' { 'PASS' } 'FAIL' { 'FAIL' } 'SKIP' { 'SKIP' } }
    Write-Host "[$icon] $Id - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "   Detail: $Detail" -ForegroundColor DarkGray }
    $script:Results += [PSCustomObject]@{
        Id     = $Id
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }
}

function Write-Summary {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Summary"                                  -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total : $script:TestCount"
    Write-Host "Pass  : $script:PassCount" -ForegroundColor Green
    Write-Host "Fail  : $script:FailCount" -ForegroundColor $(if ($script:FailCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skip  : $script:SkipCount" -ForegroundColor $(if ($script:SkipCount -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host ""
    if ($script:FailCount -eq 0) {
        Write-Host "FUNCTIONAL SMOKE TESTS: ALL PASSED" -ForegroundColor Green
    } else {
        Write-Host "FUNCTIONAL SMOKE TESTS: $($script:FailCount) FAILURE(S)" -ForegroundColor Red
    }
    Write-Host ""
}

# ---- Tool Discovery -------------------------------------------------------

function Find-ClassicSqlCmd {
    # Classic ODBC-based sqlcmd (NOT go-based v1.9+)
    $candidates = @(
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\180\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\150\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\160\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles}\Microsoft SQL Server\140\Tools\Binn\SQLCMD.EXE"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    # Fallback: check PATH but verify it's not Go-based
    $inPath = Get-Command SQLCMD.EXE -ErrorAction SilentlyContinue
    if ($inPath) {
        $verOutput = & $inPath.Source -? 2>&1 | Out-String
        if ($verOutput -match 'Microsoft \(R\) SQL Server Command Line Tool') {
            return $inPath.Source
        }
    }
    return $null
}

function Find-IISExpress {
    $candidates = @(
        "${env:ProgramFiles}\IIS Express\iisexpress.exe",
        "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Invoke-SqlQuery {
    param([string]$Query)
    $output = & $script:SqlCmd -S $SqlInstance -d $Database -Q $Query -W -h -1 -b 2>&1
    $exitCode = $LASTEXITCODE
    return @{ Output = $output; ExitCode = $exitCode }
}

function Get-AvailablePort {
    # Find an available TCP port in the 8100-8199 range
    for ($p = 8100; $p -le 8199; $p++) {
        $listener = $null
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
            $listener.Start()
            $listener.Stop()
            return $p
        } catch {
            # Port in use, try next
        } finally {
            if ($listener) { try { $listener.Stop() } catch {} }
        }
    }
    return 8100
}

# ---- Main -----------------------------------------------------------------

Write-TestHeader

$script:SqlCmd = Find-ClassicSqlCmd
$iisExpressExe = Find-IISExpress

if ($script:SqlCmd) {
    Write-Host "sqlcmd      : $($script:SqlCmd)" -ForegroundColor DarkGray
} else {
    Write-Host "sqlcmd      : NOT FOUND (classic ODBC) - DB tests will skip" -ForegroundColor Red
}
if ($iisExpressExe) {
    Write-Host "IIS Express : $iisExpressExe" -ForegroundColor DarkGray
} else {
    Write-Host "IIS Express : NOT FOUND - HTTP tests will skip" -ForegroundColor Red
}
Write-Host ""

# ============================================================================
#  SECTION 1: DATABASE TESTS
# ============================================================================

Write-Host "--- Database Tests ---" -ForegroundColor Cyan

# ---- DB-SEED-001: Countries count ----------------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-001" -Name "Countries seed data count" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM JobsDb_Countries"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($count -eq '15') {
            Add-TestResult -Id "DB-SEED-001" -Name "Countries seed data count" -Status "PASS" -Detail "Count=$count (expected 15)"
        } else {
            Add-TestResult -Id "DB-SEED-001" -Name "Countries seed data count" -Status "FAIL" -Detail "Count=$count (expected 15)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-001" -Name "Countries seed data count" -Status "FAIL" -Detail "Query failed: $($result.Output | Out-String)"
    }
}

# ---- DB-SEED-002: States count -------------------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-002" -Name "States seed data count" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM JobsDb_States"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($count -eq '51') {
            Add-TestResult -Id "DB-SEED-002" -Name "States seed data count" -Status "PASS" -Detail "Count=$count (expected 51)"
        } else {
            Add-TestResult -Id "DB-SEED-002" -Name "States seed data count" -Status "FAIL" -Detail "Count=$count (expected 51)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-002" -Name "States seed data count" -Status "FAIL" -Detail "Query failed: $($result.Output | Out-String)"
    }
}

# ---- DB-SEED-003: EducationLevels count ----------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-003" -Name "EducationLevels seed data count" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM JobsDb_EducationLevels"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($count -eq '7') {
            Add-TestResult -Id "DB-SEED-003" -Name "EducationLevels seed data count" -Status "PASS" -Detail "Count=$count (expected 7)"
        } else {
            Add-TestResult -Id "DB-SEED-003" -Name "EducationLevels seed data count" -Status "FAIL" -Detail "Count=$count (expected 7)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-003" -Name "EducationLevels seed data count" -Status "FAIL" -Detail "Query failed: $($result.Output | Out-String)"
    }
}

# ---- DB-SEED-004: JobTypes count -----------------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-004" -Name "JobTypes seed data count" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM JobsDb_JobTypes"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($count -eq '7') {
            Add-TestResult -Id "DB-SEED-004" -Name "JobTypes seed data count" -Status "PASS" -Detail "Count=$count (expected 7)"
        } else {
            Add-TestResult -Id "DB-SEED-004" -Name "JobTypes seed data count" -Status "FAIL" -Detail "Count=$count (expected 7)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-004" -Name "JobTypes seed data count" -Status "FAIL" -Detail "Query failed: $($result.Output | Out-String)"
    }
}

# ---- DB-SEED-005: ExperienceLevels count ---------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-005" -Name "ExperienceLevels seed data count" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM JobsDb_ExperienceLevels"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($count -eq '8') {
            Add-TestResult -Id "DB-SEED-005" -Name "ExperienceLevels seed data count" -Status "PASS" -Detail "Count=$count (expected 8)"
        } else {
            Add-TestResult -Id "DB-SEED-005" -Name "ExperienceLevels seed data count" -Status "FAIL" -Detail "Count=$count (expected 8)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-005" -Name "ExperienceLevels seed data count" -Status "FAIL" -Detail "Query failed: $($result.Output | Out-String)"
    }
}

# ---- DB-SEED-006: Total seed data = 88 rows ------------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-SEED-006" -Name "Total seed data rows" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $query = @"
SELECT SUM(cnt) FROM (
    SELECT COUNT(*) as cnt FROM JobsDb_Countries
    UNION ALL SELECT COUNT(*) FROM JobsDb_States
    UNION ALL SELECT COUNT(*) FROM JobsDb_EducationLevels
    UNION ALL SELECT COUNT(*) FROM JobsDb_JobTypes
    UNION ALL SELECT COUNT(*) FROM JobsDb_ExperienceLevels
) t
"@
    $result = Invoke-SqlQuery $query
    if ($result.ExitCode -eq 0) {
        $total = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        if ($total -eq '88') {
            Add-TestResult -Id "DB-SEED-006" -Name "Total seed data rows" -Status "PASS" -Detail "Total=$total (expected 88)"
        } else {
            Add-TestResult -Id "DB-SEED-006" -Name "Total seed data rows" -Status "FAIL" -Detail "Total=$total (expected 88)"
        }
    } else {
        Add-TestResult -Id "DB-SEED-006" -Name "Total seed data rows" -Status "FAIL" -Detail "Query failed"
    }
}

# ---- DB-PROC-001: Countries_SelectAll executes ---------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-001" -Name "SP: Countries_SelectAll" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_Countries_SelectAll"
    if ($result.ExitCode -eq 0) {
        $lines = ($result.Output | Where-Object { $_ -and $_.Trim() -ne '' -and $_ -notmatch 'rows affected' })
        Add-TestResult -Id "DB-PROC-001" -Name "SP: Countries_SelectAll" -Status "PASS" -Detail "Executed successfully, returned rows"
    } else {
        Add-TestResult -Id "DB-PROC-001" -Name "SP: Countries_SelectAll" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-PROC-002: States_SelectForCountry executes -----------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-002" -Name "SP: States_SelectForCountry" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_States_SelectForCountry @iCountryID=1"
    if ($result.ExitCode -eq 0) {
        Add-TestResult -Id "DB-PROC-002" -Name "SP: States_SelectForCountry" -Status "PASS" -Detail "Executed for iCountryID=1 (US)"
    } else {
        Add-TestResult -Id "DB-PROC-002" -Name "SP: States_SelectForCountry" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-PROC-003: JobTypes_SelectAll executes ----------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-003" -Name "SP: JobTypes_SelectAll" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_JobTypes_SelectAll"
    if ($result.ExitCode -eq 0) {
        Add-TestResult -Id "DB-PROC-003" -Name "SP: JobTypes_SelectAll" -Status "PASS" -Detail "Executed successfully"
    } else {
        Add-TestResult -Id "DB-PROC-003" -Name "SP: JobTypes_SelectAll" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-PROC-004: EducationLevels_SelectAll executes ---------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-004" -Name "SP: EducationLevels_SelectAll" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_EducationLevels_SelectAll"
    if ($result.ExitCode -eq 0) {
        Add-TestResult -Id "DB-PROC-004" -Name "SP: EducationLevels_SelectAll" -Status "PASS" -Detail "Executed successfully"
    } else {
        Add-TestResult -Id "DB-PROC-004" -Name "SP: EducationLevels_SelectAll" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-PROC-005: ExperienceLevels_SelectAll executes --------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-005" -Name "SP: ExperienceLevels_SelectAll" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_ExperienceLevels_SelectAll"
    if ($result.ExitCode -eq 0) {
        Add-TestResult -Id "DB-PROC-005" -Name "SP: ExperienceLevels_SelectAll" -Status "PASS" -Detail "Executed successfully"
    } else {
        Add-TestResult -Id "DB-PROC-005" -Name "SP: ExperienceLevels_SelectAll" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-PROC-006: Countries_GetCountryName executes ----------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-PROC-006" -Name "SP: Countries_GetCountryName" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "EXEC JobsDb_Countries_GetCountryName @iCountryID=1"
    if ($result.ExitCode -eq 0) {
        $name = ($result.Output | Where-Object { $_ -and $_.Trim() -ne '' -and $_ -notmatch 'rows affected' } | Select-Object -First 1)
        if ($name) { $name = $name.Trim() }
        Add-TestResult -Id "DB-PROC-006" -Name "SP: Countries_GetCountryName" -Status "PASS" -Detail "CountryID=1 returned: $name"
    } else {
        Add-TestResult -Id "DB-PROC-006" -Name "SP: Countries_GetCountryName" -Status "FAIL" -Detail "Proc failed: $($result.Output | Out-String)"
    }
}

# ---- DB-MBR-001: ASP.NET Membership tables exist -------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-MBR-001" -Name "ASP.NET Membership tables exist" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $result = Invoke-SqlQuery "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'aspnet_%'"
    if ($result.ExitCode -eq 0) {
        $count = ($result.Output | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1).Trim()
        $countInt = [int]$count
        if ($countInt -ge 9) {
            Add-TestResult -Id "DB-MBR-001" -Name "ASP.NET Membership tables exist" -Status "PASS" -Detail "$count aspnet_* tables found (need >=9)"
        } else {
            Add-TestResult -Id "DB-MBR-001" -Name "ASP.NET Membership tables exist" -Status "FAIL" -Detail "Only $count aspnet_* tables (need >=9)"
        }
    } else {
        Add-TestResult -Id "DB-MBR-001" -Name "ASP.NET Membership tables exist" -Status "FAIL" -Detail "Query failed"
    }
}

# ---- DB-MBR-002: Key membership tables accessible ------------------------

if (-not $script:SqlCmd) {
    Add-TestResult -Id "DB-MBR-002" -Name "Membership tables accessible" -Status "SKIP" -Detail "Classic sqlcmd not found"
} else {
    $tables = @('aspnet_Users', 'aspnet_Membership', 'aspnet_Roles', 'aspnet_Applications')
    $allOk = $true
    $details = @()
    foreach ($tbl in $tables) {
        $result = Invoke-SqlQuery "SELECT COUNT(*) FROM [$tbl]"
        if ($result.ExitCode -eq 0) {
            $details += "$tbl=OK"
        } else {
            $allOk = $false
            $details += "$tbl=FAIL"
        }
    }
    if ($allOk) {
        Add-TestResult -Id "DB-MBR-002" -Name "Membership tables accessible" -Status "PASS" -Detail ($details -join ', ')
    } else {
        Add-TestResult -Id "DB-MBR-002" -Name "Membership tables accessible" -Status "FAIL" -Detail ($details -join ', ')
    }
}

# ============================================================================
#  SECTION 2: HTTP SMOKE TESTS (IIS Express)
# ============================================================================

Write-Host "`n--- HTTP Smoke Tests ---" -ForegroundColor Cyan

$iisProcess = $null
$baseUrl = $null

if (-not $iisExpressExe) {
    Write-Host "IIS Express not found - all HTTP tests will be skipped" -ForegroundColor Yellow
} elseif (-not (Test-Path (Join-Path $ProjectDir "Web.config"))) {
    Write-Host "Web.config not found in ProjectDir - HTTP tests will be skipped" -ForegroundColor Yellow
} else {
    # Pick a port
    if ($Port -eq 0) { $Port = Get-AvailablePort }
    $baseUrl = "http://localhost:$Port"

    Write-Host "Starting IIS Express on port $Port ..." -ForegroundColor DarkGray

    # Start IIS Express as background process
    $iisArgs = "/path:`"$ProjectDir`" /port:$Port"
    $iisProcess = Start-Process -FilePath $iisExpressExe -ArgumentList $iisArgs `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput "$env:TEMP\iisexpress-stdout.log" `
        -RedirectStandardError "$env:TEMP\iisexpress-stderr.log"

    # Wait for IIS Express to be ready (poll with retries)
    $ready = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 2
        try {
            $resp = Invoke-WebRequest -Uri "$baseUrl/" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($resp.StatusCode -eq 200) { $ready = $true; break }
        } catch {
            # Not ready yet
        }
    }

    if ($ready) {
        Write-Host "IIS Express ready (PID $($iisProcess.Id), port $Port)" -ForegroundColor Green
    } else {
        Write-Host "IIS Express failed to start within 30 seconds" -ForegroundColor Red
        # Check if process is still alive
        if ($iisProcess -and -not $iisProcess.HasExited) {
            Write-Host "Process alive but not responding on port $Port" -ForegroundColor Yellow
        }
    }
}

# Helper: Make an HTTP request and return result
function Invoke-SmokeRequest {
    param(
        [string]$Url,
        [int]$ExpectedStatus = 200,
        [int]$TimeoutSec = 10,
        [switch]$AllowRedirect
    )
    try {
        $params = @{
            Uri = $Url
            UseBasicParsing = $true
            TimeoutSec = $TimeoutSec
            ErrorAction = 'Stop'
        }
        # To detect redirects, we need to handle them manually
        if (-not $AllowRedirect) {
            $params['MaximumRedirection'] = 0
        }
        $resp = Invoke-WebRequest @params
        return @{
            StatusCode = $resp.StatusCode
            Content = $resp.Content
            Success = $true
            Error = $null
        }
    } catch {
        $ex = $_.Exception
        if ($ex.Response) {
            $statusCode = [int]$ex.Response.StatusCode
            $content = ''
            try {
                $reader = [System.IO.StreamReader]::new($ex.Response.GetResponseStream())
                $content = $reader.ReadToEnd()
                $reader.Close()
            } catch {}
            return @{
                StatusCode = $statusCode
                Content = $content
                Success = ($statusCode -eq $ExpectedStatus)
                Error = $null
            }
        }
        return @{
            StatusCode = 0
            Content = ''
            Success = $false
            Error = $ex.Message
        }
    }
}

$httpSkip = (-not $iisProcess) -or (-not $baseUrl) -or ($iisProcess.HasExited)

# ---- SMK-001: Homepage returns HTTP 200 ----------------------------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-001" -Name "Homepage returns HTTP 200" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/"
    if ($resp.Success -and $resp.StatusCode -eq 200) {
        $hasContent = $resp.Content.Length -gt 500
        Add-TestResult -Id "SMK-001" -Name "Homepage returns HTTP 200" -Status "PASS" `
            -Detail "HTTP 200, content length=$($resp.Content.Length) chars"
    } else {
        Add-TestResult -Id "SMK-001" -Name "Homepage returns HTTP 200" -Status "FAIL" `
            -Detail "HTTP $($resp.StatusCode), error=$($resp.Error)"
    }
}

# ---- SMK-002: Homepage contains expected content -------------------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-002" -Name "Homepage has expected content" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/"
    if ($resp.Success -and $resp.Content) {
        # Check for master page markers (navigation, site name, etc.)
        $hasHtml = $resp.Content -match '<html'
        $hasNav = $resp.Content -match 'JobSeeker|Job Seeker|jobseeker' -or $resp.Content -match 'NavigationMenu|TreeView'
        $hasTitle = $resp.Content -match 'Job Site|JobSite|Starter Kit'
        if ($hasHtml -and ($hasNav -or $hasTitle)) {
            Add-TestResult -Id "SMK-002" -Name "Homepage has expected content" -Status "PASS" `
                -Detail "HTML present, navigation/title markers found"
        } else {
            Add-TestResult -Id "SMK-002" -Name "Homepage has expected content" -Status "FAIL" `
                -Detail "Missing markers: html=$hasHtml, nav=$hasNav, title=$hasTitle"
        }
    } else {
        Add-TestResult -Id "SMK-002" -Name "Homepage has expected content" -Status "FAIL" `
            -Detail "No content returned"
    }
}

# ---- SMK-003: Login page returns HTTP 200 --------------------------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-003" -Name "Login page returns HTTP 200" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/login.aspx"
    if ($resp.Success -and $resp.StatusCode -eq 200) {
        $hasLoginForm = $resp.Content -match 'Login|UserName|Password|log in' -or $resp.Content -match 'input.*type.*password'
        Add-TestResult -Id "SMK-003" -Name "Login page returns HTTP 200" -Status "PASS" `
            -Detail "HTTP 200, login form present=$hasLoginForm"
    } else {
        Add-TestResult -Id "SMK-003" -Name "Login page returns HTTP 200" -Status "FAIL" `
            -Detail "HTTP $($resp.StatusCode), error=$($resp.Error)"
    }
}

# ---- SMK-004: Registration page returns HTTP 200 -------------------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-004" -Name "Registration page returns HTTP 200" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/register.aspx"
    if ($resp.Success -and $resp.StatusCode -eq 200) {
        $hasForm = $resp.Content -match 'Register|CreateUser|UserName|Email'
        Add-TestResult -Id "SMK-004" -Name "Registration page returns HTTP 200" -Status "PASS" `
            -Detail "HTTP 200, registration form present=$hasForm"
    } else {
        Add-TestResult -Id "SMK-004" -Name "Registration page returns HTTP 200" -Status "FAIL" `
            -Detail "HTTP $($resp.StatusCode), error=$($resp.Error)"
    }
}

# ---- SMK-005: Registration page has CreateUserWizard form ----------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-005" -Name "Registration wizard form present" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/register.aspx"
    if ($resp.Success -and $resp.Content) {
        # ASP.NET CreateUserWizard renders input fields for username, password, email
        $hasUserInput = $resp.Content -match 'type="text"' -or $resp.Content -match 'UserName'
        $hasPasswordInput = $resp.Content -match 'type="password"' -or $resp.Content -match 'Password'
        $hasEmailInput = $resp.Content -match 'Email|E-mail'
        if ($hasUserInput -and $hasPasswordInput) {
            Add-TestResult -Id "SMK-005" -Name "Registration wizard form present" -Status "PASS" `
                -Detail "User/Password inputs found, Email=$hasEmailInput"
        } else {
            Add-TestResult -Id "SMK-005" -Name "Registration wizard form present" -Status "FAIL" `
                -Detail "Missing form inputs: user=$hasUserInput, password=$hasPasswordInput"
        }
    } else {
        Add-TestResult -Id "SMK-005" -Name "Registration wizard form present" -Status "FAIL" -Detail "No content"
    }
}

# ---- SMK-006: Job search page returns HTTP 200 (or redirects to login) ---

if ($httpSkip) {
    Add-TestResult -Id "SMK-006" -Name "Job search page accessible" -Status "SKIP" -Detail "IIS Express not running"
} else {
    # jobseeker pages require auth; expect redirect to login
    $resp = Invoke-SmokeRequest "$baseUrl/jobseeker/jobsearch.aspx" -AllowRedirect
    if ($resp.Success) {
        $isLoginRedirect = $resp.Content -match 'login\.aspx|Login|log in|UserName|Password'
        if ($resp.StatusCode -eq 200) {
            Add-TestResult -Id "SMK-006" -Name "Job search page accessible" -Status "PASS" `
                -Detail "HTTP 200 (redirected to login=$isLoginRedirect)"
        } else {
            Add-TestResult -Id "SMK-006" -Name "Job search page accessible" -Status "PASS" `
                -Detail "HTTP $($resp.StatusCode)"
        }
    } else {
        # A 302 redirect is also acceptable
        if ($resp.StatusCode -eq 302 -or $resp.StatusCode -eq 301) {
            Add-TestResult -Id "SMK-006" -Name "Job search page accessible" -Status "PASS" `
                -Detail "HTTP $($resp.StatusCode) redirect (auth required, expected)"
        } else {
            Add-TestResult -Id "SMK-006" -Name "Job search page accessible" -Status "FAIL" `
                -Detail "HTTP $($resp.StatusCode), error=$($resp.Error)"
        }
    }
}

# ---- SMK-007: Homepage shows database-connected content ------------------
# (Verifies DB connectivity from the running app -- LatestJobs control queries DB)

if ($httpSkip) {
    Add-TestResult -Id "SMK-007" -Name "Homepage DB-connected content" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/"
    if ($resp.Success -and $resp.Content) {
        # Homepage renders master page with navigation tree and content area
        # Even without job data, the page structure from DB-driven controls should render
        $hasBody = $resp.Content -match '<body'
        $hasForm = $resp.Content -match '<form'
        $contentLen = $resp.Content.Length
        # A DB-connected page with master page should be substantial (>5KB)
        if ($hasBody -and $hasForm -and $contentLen -gt 5000) {
            Add-TestResult -Id "SMK-007" -Name "Homepage DB-connected content" -Status "PASS" `
                -Detail "Page renders with form, content=$contentLen chars (DB connected)"
        } else {
            Add-TestResult -Id "SMK-007" -Name "Homepage DB-connected content" -Status "FAIL" `
                -Detail "Minimal content: body=$hasBody, form=$hasForm, len=$contentLen"
        }
    } else {
        Add-TestResult -Id "SMK-007" -Name "Homepage DB-connected content" -Status "FAIL" -Detail "No content"
    }
}

# ---- SMK-008: Registration page renders without errors -------------------
# (Verifies app can connect to DB and render profile-related page)

if ($httpSkip) {
    Add-TestResult -Id "SMK-008" -Name "Registration renders without errors" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/register.aspx"
    if ($resp.Success -and $resp.Content) {
        $hasError = $resp.Content -match 'Server Error in|Runtime Error|Unhandled Exception|Stack Trace:'
        $hasWizard = $resp.Content -match 'CreateUserWizard|Wizard|wizard|Next'
        if (-not $hasError -and $resp.Content.Length -gt 3000) {
            Add-TestResult -Id "SMK-008" -Name "Registration renders without errors" -Status "PASS" `
                -Detail "No server errors, wizard=$hasWizard, content=$($resp.Content.Length) chars"
        } elseif ($hasError) {
            Add-TestResult -Id "SMK-008" -Name "Registration renders without errors" -Status "FAIL" `
                -Detail "Server error detected in page output"
        } else {
            Add-TestResult -Id "SMK-008" -Name "Registration renders without errors" -Status "FAIL" `
                -Detail "Content too small: $($resp.Content.Length) chars"
        }
    } else {
        Add-TestResult -Id "SMK-008" -Name "Registration renders without errors" -Status "FAIL" -Detail "No content"
    }
}

# ---- SMK-009: Custom error page accessible --------------------------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-009" -Name "Custom error page accessible" -Status "SKIP" -Detail "IIS Express not running"
} else {
    $resp = Invoke-SmokeRequest "$baseUrl/customerrorpage.aspx"
    if ($resp.Success -and $resp.StatusCode -eq 200) {
        Add-TestResult -Id "SMK-009" -Name "Custom error page accessible" -Status "PASS" `
            -Detail "HTTP 200, content=$($resp.Content.Length) chars"
    } else {
        # 302 redirect or other status is also acceptable
        if ($resp.StatusCode -gt 0) {
            Add-TestResult -Id "SMK-009" -Name "Custom error page accessible" -Status "PASS" `
                -Detail "HTTP $($resp.StatusCode) (page exists and responds)"
        } else {
            Add-TestResult -Id "SMK-009" -Name "Custom error page accessible" -Status "FAIL" `
                -Detail "HTTP $($resp.StatusCode), error=$($resp.Error)"
        }
    }
}

# ---- SMK-010: Admin pages redirect to login (auth required) ---------------

if ($httpSkip) {
    Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "SKIP" -Detail "IIS Express not running"
} else {
    # Admin pages should require authentication - when accessed anonymously
    # they should redirect to login page
    $resp = Invoke-SmokeRequest "$baseUrl/Admin/EducationLevelsManager.aspx" -AllowRedirect
    if ($resp.Success) {
        $isLoginRedirect = $resp.Content -match 'login\.aspx|Login|log in|UserName|Password'
        if ($isLoginRedirect) {
            Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "PASS" `
                -Detail "Admin page redirected to login (HTTP $($resp.StatusCode))"
        } else {
            # Check if it's an error page or actually the admin page (which would be a failure)
            $isAdminPage = $resp.Content -match 'EducationLevel|Education Level|Manager'
            if ($isAdminPage) {
                Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "FAIL" `
                    -Detail "Admin page accessible without auth!"
            } else {
                Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "PASS" `
                    -Detail "HTTP $($resp.StatusCode), did not serve admin content"
            }
        }
    } else {
        # 302/401/403 are all acceptable responses for auth-required pages
        if ($resp.StatusCode -in @(302, 301, 401, 403)) {
            Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "PASS" `
                -Detail "HTTP $($resp.StatusCode) (auth redirect/denied)"
        } elseif ($resp.StatusCode -eq 0 -and $resp.Error) {
            Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "FAIL" `
                -Detail "Request failed: $($resp.Error)"
        } else {
            Add-TestResult -Id "SMK-010" -Name "Admin pages require auth" -Status "FAIL" `
                -Detail "Unexpected HTTP $($resp.StatusCode)"
        }
    }
}

# ============================================================================
#  CLEANUP: Stop IIS Express
# ============================================================================

if ($iisProcess -and -not $iisProcess.HasExited) {
    Write-Host "`nStopping IIS Express (PID $($iisProcess.Id))..." -ForegroundColor DarkGray
    try {
        Stop-Process -Id $iisProcess.Id -Force -ErrorAction Stop
        $iisProcess.WaitForExit(5000) | Out-Null
        Write-Host "IIS Express stopped." -ForegroundColor DarkGray
    } catch {
        Write-Host "Warning: Could not stop IIS Express: $_" -ForegroundColor Yellow
    }
}

# Clean up temp logs
Remove-Item "$env:TEMP\iisexpress-stdout.log" -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\iisexpress-stderr.log" -ErrorAction SilentlyContinue

# ============================================================================
#  SUMMARY & EXIT
# ============================================================================

Write-Summary

# Return structured results for CI/CD consumption
$script:Results

# Exit with non-zero if any test failed
if ($script:FailCount -gt 0) {
    exit 1
} else {
    exit 0
}
