Compliant with [AGENTS.md](AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

# Contract: CLI

**Branch**: `001-sync-docs-spec`
**Date**: 2025-12-14

## Commands

### Primary command

- **Name**: `pndcgn`

## Arguments

- `SOURCE_DIR` (optional): Defaults to current working directory.
  - If `fzf` is installed and available, and SOURCE_DIR is not provided, an interactive folder selection interface is offered using `fzf`.
  - The `fzf` interface displays only directories (folders) from the current working directory and its subdirectories.
  - If `fzf` is not available or the user cancels the selection, falls back to current working directory.
  - This integration is optional and does not affect normal operation if `fzf` is unavailable.
- `TARGET_DIR` (optional): Defaults to current working directory.

## Options

- `--type <TYPE>`: Output type (default: `pdf`).
- `--dry-run`: Preview mode; produces no output artifacts.
- `--finalize <RUN_ID>`: Finalize a prior dry-run if inputs/config are unchanged.
- `--resume <RUN_ID>`: Resume an interrupted run.
- `--force`: Bypass cache.
- `--reseed`: Explicitly re-seed `.pndcgnignore` from current ignore rules (never automatic).
  - NOTE: Reseeding can change the effective input set and therefore can invalidate previously computed fingerprints used for finalize/resume validation.
- `--clean <RUN_ID> [RUN_ID...]`: Remove outputs for one or more specified run IDs (requires confirmation).
  - MUST warn if fingerprint validation fails or if output paths contain non-pndcgn artifacts.
- `--drop`: Clear all cache/state (requires confirmation).
  - MUST warn if fingerprint validation fails or if output paths contain non-pndcgn artifacts.
- `--help`: Print usage.

## Output locations

- Default run output directory: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.

## Ignore configuration

- Ignore file: `.pndcgnignore`, discovered relative to the source directory root.
- If missing on first non-help run, it is auto-created.
- Seed-once from applicable `.gitignore` rules using closest-first stacking; never auto-updated.

## Exit codes

- `0`: Success
- `1`: Runtime error
- `2`: Invalid usage
