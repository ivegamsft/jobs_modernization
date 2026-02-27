# Repository Reorganization — Windows Git Operations

**Author:** Dozer (DevOps)  
**Date:** 2026-02-27  
**Status:** Completed  
**Impact:** High (affects all future work)

---

## Decision

Use `git mv` for all file/folder moves to preserve Git history, with fallback strategies for Windows edge cases.

## Context

Executed Morpheus's approved repository reorganization (440 file operations). Windows filesystem has case-insensitive behavior that requires special handling for certain git operations.

## Approach

### Standard Moves (Works Every Time)
```powershell
git mv old-file.md new-location/old-file.md
git mv appV1 phase1-legacy-baseline/appV1-original
```
✅ Preserves Git history  
✅ Single command  
✅ Works for files and directories

### Directory Content Moves (When git mv Fails)
```powershell
Move-Item -Path "iac\*" -Destination "infrastructure\" -Force
Remove-Item -Path "iac" -Force
git add infrastructure\*
git add iac
```
✅ Moves all contents  
✅ Git tracks as renames via similarity detection  
⚠️ Requires manual git add

### Case-Only Renames (Windows Special Case)
```powershell
Move-Item -Path "Database" -Destination "Database_temp" -Force
Move-Item -Path "Database_temp" -Destination "database" -Force
git add database\*
git add Database
```
✅ Works around Windows case-insensitive filesystem  
✅ Git sees as rename  
⚠️ Requires temp directory

## Outcome

- **401 files renamed** with preserved history
- **8 new READMEs** created for learning journey
- **Root cleaned** from 15+ markdown files to 3 files total
- **Zero lost history** — all changes tracked properly

## Lessons for Future Reorganizations

1. **Always prefer `git mv`** — It's the safest way to preserve history
2. **Windows case renames** — Use temp directory technique
3. **Large directory moves** — If `git mv` fails, use `Move-Item` + `git add`
4. **Verify with `git status`** — Check that renames are detected (shows "R" not "D" + "A")
5. **Test incrementally** — Don't do all 440 operations in one command

## Related

- Implemented: [morpheus-repo-reorg.md](./morpheus-repo-reorg.md)
- Updated: `.squad/agents/dozer/history.md`
