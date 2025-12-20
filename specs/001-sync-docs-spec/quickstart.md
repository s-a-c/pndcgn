# Quickstart (Developer): pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Branch**: `001-sync-docs-spec`

## Goal

Implement the specification changes around:

- Output directory default: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- `.pndcgnignore` creation + seeding from `.gitignore` (stacking) + seed-once policy

## Local commands

```bash
# Run tests
shellspec

# Run help
./bin/pndcgn --help

# Dry-run
./bin/pndcgn --dry-run
```

## Acceptance checks

- First non-help run auto-creates `.pndcgnignore` at the source root.
- Seeded ignore includes `.pndcgn`.
- `.pndcgnignore` is not modified on subsequent runs.
- Outputs for a run land under `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.
