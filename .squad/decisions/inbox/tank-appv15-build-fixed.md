# Decision: appV1.5 Build Now Works — Web Site → WAP Migration Completed

**Author:** Tank (Backend Dev)
**Date:** 2026-02-28
**Status:** Implemented & Verified
**Impact:** High (unblocks Phase 1 testing, deployment, and all downstream work)

## Context

appV1.5-buildable was supposed to be the "minimal changes to make buildable" version of the legacy .NET Web Forms app. However, the Web Site → Web Application Project migration was incomplete. The project had a WAP-style .csproj but was missing critical elements.

## What Was Wrong (4 categories, 232+ compile errors)

1. **App_Code files as Content, not Compile** — 12 business logic files (BOL/DAL) were `<Content>` items in the .csproj. WAP requires them as `<Compile>` so they're included in the assembly.

2. **No .designer.cs files** — 28 ASPX/ASCX/Master files had no designer files. WAP needs these to declare server control fields (Label, TextBox, GridView, etc.) that code-behind references. Web Site projects generate these dynamically.

3. **No ProfileCommon class** — ASP.NET Web Site projects auto-generate a typed `ProfileCommon` class from Web.config `<profile>` definition. WAP does not. Pages using `Profile.JobSeeker.ResumeID`, `Profile.Employer.CompanyID`, etc. couldn't compile.

4. **Duplicate class names** — Both `employer/MyFavorites.aspx.cs` and `jobseeker/MyFavorites.aspx.cs` defined `MyFavorites_aspx`. Web Site projects compile pages independently; WAP compiles everything into one assembly.

## What Was Fixed

| Fix | Files Changed | Notes |
|-----|---------------|-------|
| App_Code → Compile | .csproj | 12 items changed from Content to Compile |
| Designer files generated | 28 new .designer.cs files | Auto-generated from ASPX markup |
| ProfileCommon.cs created | 1 new file | Typed profile matching Web.config definition |
| BasePage.cs created | 1 new file | Provides typed `Profile` property for pages |
| Page inheritance updated | 6 .cs files | Changed `: Page` to `: BasePage` where typed Profile used |
| Class name collision fixed | 2 files | Renamed employer's MyFavorites to `employer_MyFavorites_aspx` |
| Removed `using ASP;` | 1 file | Runtime namespace, invalid in WAP |

## Build Command

```powershell
# Requires: VS 2022 with .NET Framework 4.8 targeting pack
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"

# NuGet restore (one-time, needs nuget.exe)
nuget restore JobsSiteWeb.csproj -PackagesDirectory ..\packages

# Build
& $msbuild JobsSiteWeb.csproj /t:Build /p:Configuration=Debug
```

## Result

- **Debug build:** ✅ 0 errors, 9 warnings (pre-existing legacy warnings)
- **Release build:** ✅ 0 errors
- **Output:** `bin\JobsSiteWeb.dll` (53KB)

## Remaining Work (not in scope for this fix)

1. **No .sln file** — Build works against .csproj directly, but a .sln would help VS integration
2. **CodeFile vs CodeBehind** — ASPX directives still use `CodeFile=` (Web Site pattern). Should be `CodeBehind=` for WAP. Affects runtime only, not build.
3. **Connection strings** — Still point to hardcoded `C:\GIT\APPMIGRATIONWORKSHOP\...` path. Need updating for local dev.
4. **Runtime testing** — Builds ≠ runs. Need IIS Express + database to verify runtime behavior.

## Impact on Team

- **Mouse (Tester):** Build Verification tests (5 in TEST_PLAN.md) should now pass
- **Morpheus (Lead):** Deployment plan's "Building appV1.5" section is now executable
- **Dozer (DevOps):** CI/CD pipeline can use this build command
