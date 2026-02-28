# Functional Smoke Tests Automated

**Decision ID:** functional-smoke-tests-2026-02-28  
**Author:** Mouse (QA Engineer)  
**Date:** 2026-02-28  
**Status:** Implemented & Verified  
**Impact:** Medium (enables Phase 1 functional gate)

## Context

TEST_PLAN.md categories 2-4 (Database, Smoke, Integration) now have automated coverage. 24 tests verify seed data, stored procedures, membership tables, and HTTP endpoints.

## What Was Created

- `phase1-legacy-baseline/tests/Functional-Smoke.ps1` -- 24 tests, pure PowerShell, self-contained

## Test Results (All Passing)

- 6 seed data count tests (88 total rows across 5 lookup tables)
- 6 stored procedure execution tests (SelectAll + parameterized calls)
- 2 ASP.NET Membership table tests (existence + accessibility)
- 10 HTTP smoke tests via IIS Express (homepage, login, register, auth, error page)

## Key Technical Findings

1. **Classic sqlcmd required** -- Go-based sqlcmd v1.9 does NOT work with LocalDB named pipes. Must use ODBC-based sqlcmd at `Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE`.
2. **Stored proc parameter prefix** -- Legacy procs use `@i` prefix (e.g., `@iCountryID`), not `@CountryID`.
3. **Registration page structure** -- CreateUserWizard multi-step; dropdowns for country/education/jobtype are on profile pages (auth-required), not on registration form.

## Team Impact

- **Dozer:** CI/CD command: `powershell -ExecutionPolicy Bypass -File phase1-legacy-baseline/tests/Functional-Smoke.ps1`
- **Tank:** Seed data deployment confirmed working; all 88 rows verified
- **Morpheus:** Phase 1 functional baseline now has automated gate (24 tests)

## Commit

1226c0d
