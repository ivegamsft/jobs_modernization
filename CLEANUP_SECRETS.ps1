#!/usr/bin/env pwsh
# Git history cleanup - Run this in a FRESH PowerShell window

$ErrorActionPreference = 'Stop'

# Set environment to prevent VIM from opening
[Environment]::SetEnvironmentVariable('GIT_EDITOR', 'false', [EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable('GIT_PAGER', 'cat', [EnvironmentVariableTarget]::Process)

Set-Location 'c:\git\jobs_modernization'

Write-Host "Step 1: Clean up git-filter-repo artifacts..." -ForegroundColor Cyan
Remove-Item -Force -Recurse '.git-rewrite' -ErrorAction SilentlyContinue

Write-Host "Step 2: Create secret replacement file..." -ForegroundColor Cyan
@'
6-CtFhZr1y6nm8Q&C#to==>***REDACTED-PASSWORD***
4lbeGK1H?&Xia12H%WGI==>***REDACTED-PASSWORD***
'@ | Out-File -FilePath '.secret-replace.txt' -Encoding UTF8

Write-Host "Step 3: Running git-filter-repo to clean history..." -ForegroundColor Cyan
python -m git_filter_repo --replace-text '.secret-replace.txt' --force

Write-Host "Step 4: Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item -Force '.secret-replace.txt' -ErrorAction SilentlyContinue

Write-Host "Step 5: Restore origin remote..." -ForegroundColor Cyan
git remote add origin https://github.com/chikamsoachumsft/jobs_modernization

Write-Host "Step 6: Force push to GitHub..." -ForegroundColor Yellow
Write-Host "Running: git push --force-with-lease origin main" -ForegroundColor Gray
git push --force-with-lease origin main

Write-Host "`n✅ History cleanup complete!" -ForegroundColor Green
Write-Host "Verify the password is gone:" -ForegroundColor Green
$found = git log --all -S "6-CtFhZr1y6nm8Q" --oneline
if ($found) {
  Write-Host "WARNING: Password still found in history!" -ForegroundColor Red
  Write-Host $found
} else {
  Write-Host "✅ Password successfully removed from history" -ForegroundColor Green
}
