#Requires -Version 5.1
<#
.SYNOPSIS
    Build Verification Tests for Phase 1 appV1.5-buildable.

.DESCRIPTION
    Runs 5 build verification tests against the legacy .NET Framework 4.8
    Web Forms application. Tests cover project existence, NuGet restore,
    Debug/Release compilation, and build output validation.

    This is a .NET Framework project using MSBuild + packages.config,
    NOT .NET Core / dotnet build.

.EXAMPLE
    .\Build-Verification.ps1
    .\Build-Verification.ps1 -ProjectDir "C:\other\path\appV1.5-buildable"

.NOTES
    Requires: MSBuild (Visual Studio 2019+ or Build Tools)
    Optional: nuget.exe in PATH for NuGet restore test
#>
[CmdletBinding()]
param(
    [string]$ProjectDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Resolve default ProjectDir relative to this script's location
if (-not $ProjectDir) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ProjectDir = (Resolve-Path (Join-Path $scriptDir "..\appV1.5-buildable")).Path
}

# ── Test Harness ──────────────────────────────────────────────────────

$script:Results   = @()
$script:TestCount = 0
$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0

function Write-TestHeader {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Phase 1 - Build Verification Tests"     -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project Dir : $ProjectDir"
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
    $icon = switch ($Status) { 'PASS' { '✅' } 'FAIL' { '❌' } 'SKIP' { '⏭️' } }
    Write-Host "$icon [$Status] $Id - $Name" -ForegroundColor $color
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
        Write-Host "BUILD VERIFICATION: ALL PASSED" -ForegroundColor Green
    } else {
        Write-Host "BUILD VERIFICATION: $($script:FailCount) FAILURE(S)" -ForegroundColor Red
    }
    Write-Host ""
}

# ── MSBuild Discovery ────────────────────────────────────────────────

function Find-MSBuild {
    <#
    .SYNOPSIS
        Locate MSBuild.exe via vswhere, then fall back to known paths.
    #>
    # Strategy 1: vswhere (most reliable)
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $found = & $vswhere -latest -requires Microsoft.Component.MSBuild `
                    -find "MSBuild\**\Bin\MSBuild.exe" 2>$null |
                    Select-Object -First 1
        if ($found -and (Test-Path $found)) { return $found }
    }

    # Strategy 2: Well-known Visual Studio paths
    $candidates = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    # Strategy 3: PATH
    $inPath = Get-Command MSBuild.exe -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }

    return $null
}

function Find-NuGet {
    <#
    .SYNOPSIS
        Locate nuget.exe in PATH or common locations.
    #>
    $inPath = Get-Command nuget.exe -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }

    $candidates = @(
        "$env:LOCALAPPDATA\NuGet\nuget.exe",
        "C:\ProgramData\chocolatey\bin\nuget.exe",
        "${env:ProgramFiles(x86)}\NuGet\nuget.exe",
        "$PSScriptRoot\nuget.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

# ── Test Execution ───────────────────────────────────────────────────

Write-TestHeader

$csproj = Join-Path $ProjectDir "JobsSiteWeb.csproj"
$packagesDir = Join-Path (Split-Path $ProjectDir) "packages"

# Discover tools
$msbuildExe = Find-MSBuild
$nugetExe   = Find-NuGet

if ($msbuildExe) {
    Write-Host "MSBuild     : $msbuildExe" -ForegroundColor DarkGray
} else {
    Write-Host "MSBuild     : NOT FOUND - build tests will fail" -ForegroundColor Red
}
if ($nugetExe) {
    Write-Host "NuGet       : $nugetExe" -ForegroundColor DarkGray
} else {
    Write-Host "NuGet       : NOT FOUND - restore test will attempt fallback" -ForegroundColor Yellow
}
Write-Host ""

# ── BLD-001: Solution/Project File Exists ────────────────────────────

$slnFiles = Get-ChildItem -Path (Split-Path $ProjectDir) -Filter "*.sln" -ErrorAction SilentlyContinue
$csprojExists = Test-Path $csproj

if ($csprojExists) {
    $detail = "Found: JobsSiteWeb.csproj"
    if ($slnFiles) {
        $detail += " + $($slnFiles.Name -join ', ')"
    } else {
        $detail += " (no .sln yet - expected, Tank creating)"
    }
    Add-TestResult -Id "BLD-001" -Name "Solution/project file exists" -Status "PASS" -Detail $detail
} else {
    Add-TestResult -Id "BLD-001" -Name "Solution/project file exists" -Status "FAIL" `
        -Detail "JobsSiteWeb.csproj not found at: $csproj"
}

# ── BLD-002: NuGet Restore Succeeds ─────────────────────────────────

if (-not $csprojExists) {
    Add-TestResult -Id "BLD-002" -Name "NuGet restore succeeds" -Status "SKIP" `
        -Detail "Skipped - .csproj not found"
} else {
    $restoreSuccess = $false
    $restoreDetail  = ""

    if ($nugetExe) {
        # packages.config restore: nuget restore <csproj> -PackagesDirectory <dir>
        $restoreOutput = & $nugetExe restore $csproj -PackagesDirectory $packagesDir -NonInteractive 2>&1
        $restoreExit   = $LASTEXITCODE
        if ($restoreExit -eq 0) {
            $restoreSuccess = $true
            $restoreDetail  = "nuget.exe restore exit code 0"
        } else {
            $restoreDetail = "nuget.exe restore failed (exit $restoreExit): $($restoreOutput | Select-Object -Last 3 | Out-String)".Trim()
        }
    } else {
        # Fallback: verify packages already present (committed to repo)
        $pkgPath = Join-Path $packagesDir "Microsoft.CodeDom.Providers.DotNetCompilerPlatform.2.0.1"
        if (Test-Path $pkgPath) {
            $restoreSuccess = $true
            $restoreDetail  = "nuget.exe not available; packages already present in packages/ directory (committed to repo)"
        } else {
            $restoreDetail = "nuget.exe not found and packages directory missing. Install nuget.exe or run: dotnet tool install nuget.commandline -g"
        }
    }

    if ($restoreSuccess) {
        Add-TestResult -Id "BLD-002" -Name "NuGet restore succeeds" -Status "PASS" -Detail $restoreDetail
    } else {
        Add-TestResult -Id "BLD-002" -Name "NuGet restore succeeds" -Status "FAIL" -Detail $restoreDetail
    }
}

# ── BLD-003: Debug Build Compiles ────────────────────────────────────

if (-not $msbuildExe) {
    Add-TestResult -Id "BLD-003" -Name "Debug build compiles" -Status "SKIP" `
        -Detail "MSBuild not found. Install Visual Studio 2019+ or Build Tools."
} elseif (-not $csprojExists) {
    Add-TestResult -Id "BLD-003" -Name "Debug build compiles" -Status "SKIP" `
        -Detail "Skipped - .csproj not found"
} else {
    # Clean bin/obj first for a reliable test
    $binDir = Join-Path $ProjectDir "bin"
    $objDir = Join-Path $ProjectDir "obj"
    if (Test-Path $binDir) { Remove-Item "$binDir\*" -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $objDir) { Remove-Item "$objDir\*" -Recurse -Force -ErrorAction SilentlyContinue }

    $buildOutput = & $msbuildExe $csproj /t:Build /p:Configuration=Debug /nologo /verbosity:minimal /m 2>&1
    $buildExit = $LASTEXITCODE

    # Count errors (MSBuild reports " error " in output)
    $errorLines = $buildOutput | Where-Object { $_ -match '\berror\b' -and $_ -notmatch 'ErrorText' -and $_ -notmatch '0 Error' }
    $errorCount = ($errorLines | Measure-Object).Count

    if ($buildExit -eq 0 -and $errorCount -eq 0) {
        # Check for warnings
        $warnMatch = $buildOutput | Select-String '(\d+) Warning' | Select-Object -First 1
        $warnInfo = if ($warnMatch) { " ($($warnMatch.Matches.Value))" } else { "" }
        Add-TestResult -Id "BLD-003" -Name "Debug build compiles" -Status "PASS" `
            -Detail "MSBuild exit code 0, 0 errors$warnInfo"
    } else {
        $errorSample = ($errorLines | Select-Object -First 5) -join "`n   "
        Add-TestResult -Id "BLD-003" -Name "Debug build compiles" -Status "FAIL" `
            -Detail "MSBuild exit code $buildExit, $errorCount error(s):`n   $errorSample"
    }
}

# ── BLD-004: Release Build Compiles ──────────────────────────────────

if (-not $msbuildExe) {
    Add-TestResult -Id "BLD-004" -Name "Release build compiles" -Status "SKIP" `
        -Detail "MSBuild not found. Install Visual Studio 2019+ or Build Tools."
} elseif (-not $csprojExists) {
    Add-TestResult -Id "BLD-004" -Name "Release build compiles" -Status "SKIP" `
        -Detail "Skipped - .csproj not found"
} else {
    $buildOutput = & $msbuildExe $csproj /t:Build /p:Configuration=Release /nologo /verbosity:minimal /m 2>&1
    $buildExit = $LASTEXITCODE

    $errorLines = $buildOutput | Where-Object { $_ -match '\berror\b' -and $_ -notmatch 'ErrorText' -and $_ -notmatch '0 Error' }
    $errorCount = ($errorLines | Measure-Object).Count

    if ($buildExit -eq 0 -and $errorCount -eq 0) {
        $warnMatch = $buildOutput | Select-String '(\d+) Warning' | Select-Object -First 1
        $warnInfo = if ($warnMatch) { " ($($warnMatch.Matches.Value))" } else { "" }
        Add-TestResult -Id "BLD-004" -Name "Release build compiles" -Status "PASS" `
            -Detail "MSBuild exit code 0, 0 errors$warnInfo"
    } else {
        $errorSample = ($errorLines | Select-Object -First 5) -join "`n   "
        Add-TestResult -Id "BLD-004" -Name "Release build compiles" -Status "FAIL" `
            -Detail "MSBuild exit code $buildExit, $errorCount error(s):`n   $errorSample"
    }
}

# ── BLD-005: Build Output Exists ─────────────────────────────────────

$expectedDll = Join-Path $ProjectDir "bin\JobsSiteWeb.dll"

if (-not $msbuildExe -and -not (Test-Path $expectedDll)) {
    Add-TestResult -Id "BLD-005" -Name "Build output exists" -Status "SKIP" `
        -Detail "MSBuild not available and no prior build output found"
} else {
    if (Test-Path $expectedDll) {
        $dllInfo = Get-Item $expectedDll
        $sizeKB = [math]::Round($dllInfo.Length / 1KB, 1)
        Add-TestResult -Id "BLD-005" -Name "Build output exists" -Status "PASS" `
            -Detail "bin\JobsSiteWeb.dll found ($sizeKB KB, modified $($dllInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    } else {
        Add-TestResult -Id "BLD-005" -Name "Build output exists" -Status "FAIL" `
            -Detail "Expected output not found: $expectedDll"
    }
}

# ── Summary & Exit ───────────────────────────────────────────────────

Write-Summary

# Return structured results for CI/CD consumption
$script:Results

# Exit with non-zero if any test failed
if ($script:FailCount -gt 0) {
    exit 1
} else {
    exit 0
}
