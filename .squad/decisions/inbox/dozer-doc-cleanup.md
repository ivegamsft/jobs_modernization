# Decision: Infrastructure Documentation Cleanup

**Author:** Dozer (DevOps)  
**Date:** 2026-02-27  
**Status:** Executed  
**Impact:** Medium (documentation quality, security)

## Context

After the `iac/` → `infrastructure/` reorganization, all infrastructure documentation had stale paths. Two files contained plaintext passwords committed to git. The `infrastructure/bicep/` directory had 10 network security docs that were 80% duplicate content.

## Decision

1. **Delete 13 files** that were broken, contained credentials, or were pure duplicates
2. **Fix paths in 18 files** — all `iac/` references → `infrastructure/`, all `appV2/appV3` → `phase3-modernization/`
3. **Fix incorrect data** — core/README.md had wrong VNet CIDR, terraform/STATUS.md marked complete modules as pending

## Security Note

Two files contained plaintext passwords that were committed to git history:
- `infrastructure/DEPLOYMENT_STATUS.md` — VM admin password + certificate password
- `infrastructure/docs/CREDENTIALS_AND_NEXT_STEPS.md` — Same credentials

These passwords should be rotated if they were ever used in a real deployment. The files are removed from HEAD but remain in git history.

## Impact on Team

- **Morpheus:** No spec/plan docs affected
- **Scribe:** Should update any cross-references to deleted files
- **All agents:** `infrastructure/` docs are now accurate and can be trusted

## Files Remaining (33 .md files in infrastructure/)

Infrastructure docs are now clean, accurate, and non-redundant. Network security consolidated from 10 files → 5 essential docs.
