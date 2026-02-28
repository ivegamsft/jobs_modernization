# Phase 1 — Build Verification Tests

Automated tests that verify the appV1.5-buildable .NET Framework 4.8 Web Forms application compiles correctly.

## Prerequisites

- **MSBuild** — Visual Studio 2019+ or Build Tools (`.NET desktop development` workload)
- **NuGet** *(optional)* — `nuget.exe` in PATH for package restore; if absent, the test verifies packages are already present
- **.NET Framework 4.8 Targeting Pack** — Required for compilation

## Running the Tests

```powershell
# From this directory
.\Build-Verification.ps1

# From anywhere (explicit project path)
.\Build-Verification.ps1 -ProjectDir "C:\path\to\appV1.5-buildable"
```

## What's Tested

| Test ID | Name | What It Checks |
|---------|------|---------------|
| BLD-001 | Project file exists | `JobsSiteWeb.csproj` present (and `.sln` if created) |
| BLD-002 | NuGet restore succeeds | Package restore via `nuget.exe` or packages already in repo |
| BLD-003 | Debug build compiles | MSBuild Debug config → exit code 0, no errors |
| BLD-004 | Release build compiles | MSBuild Release config → exit code 0, no errors |
| BLD-005 | Build output exists | `bin\JobsSiteWeb.dll` present after build |

## Output

Each test reports **PASS**, **FAIL**, or **SKIP** with details. The script exits with code `0` if all tests pass, `1` if any test fails. Skipped tests (e.g., MSBuild not installed) do not cause failure.

## CI/CD Integration

The script returns structured `[PSCustomObject]` results and uses standard exit codes, making it suitable for GitHub Actions or Azure Pipelines:

```yaml
- name: Build Verification
  run: |
    powershell -ExecutionPolicy Bypass -File phase1-legacy-baseline/tests/Build-Verification.ps1
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| MSBuild not found | Install VS 2022 Build Tools with `.NET desktop development` workload |
| NuGet not found | Install via `winget install Microsoft.NuGet` or download from [nuget.org](https://www.nuget.org/downloads) |
| Build errors | Verify .NET Framework 4.8 Targeting Pack is installed |
