# Project Context

- **Owner:** ivegamsft
- **Project:** Legacy .NET job site application modernization — learning repository with multiple configurations (V1 .NET → V3 Python/K8s)
- **Stack:** .NET (legacy), Python, React, Azure, Bicep, Kubernetes, SQL Server
- **Created:** 2026-02-27

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-02-28: Phase 1 Milestone — Legacy Baseline Fully Operational

**Session summary (in order):**
1. Tank wrote seed data SQL for 4 empty lookup tables (Countries=15, States=51, EducationLevels=7, JobTypes=7)
2. Seed data deployed to LocalDB, all 88 rows verified
3. Mouse wrote 24 functional smoke tests — ALL PASSING:
   - Database seed data counts (5 tables verified)
   - Stored procedure execution (6 sprocs tested)
   - ASP.NET Membership tables verified
   - HTTP smoke tests (10 pages tested via IIS Express)
4. All committed and pushed to origin/main

**Scribe actions this session:**
- Merged 2 inbox decisions into `.squad/decisions.md`: seed-data-populated-2026-02-28, functional-smoke-tests-2026-02-28
- Updated `.squad/identity/now.md` — Phase 1 COMPLETE status
- Cleaned up `.squad/decisions/inbox/` (2 files removed)

**Phase 1 final status:**
- appV1.5 builds (0 errors), runs on IIS Express + LocalDB
- Database: 22 tables, 157 sprocs, 88 seed rows across 5 lookup tables
- Test suites: 5 build verification + 24 functional smoke = **29 tests, 29 passing**
- Phase 1 is COMPLETE. Ready for Phase 2 planning.
