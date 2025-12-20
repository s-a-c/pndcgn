Compliant with [AGENTS.md](AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

# Contract: .pndcgnignore

**Branch**: `001-sync-docs-spec`
**Date**: 2025-12-14

## Purpose

Defines which paths under the source directory root should be excluded from discovery/traversal.

## Location

- Stored at the **source directory root** as `.pndcgnignore`.

## Format

- Gitignore-style patterns (glob-like matching), interpreted relative to the source root.

## Seeding

- On first non-help run, if the file does not exist:
  - Seed from applicable `.gitignore` rules (closest-first stacking) when available.
  - Otherwise seed from a built-in default.

## Required default ignores

- Must include `.pndcgn` (the default output directory name).

## Updates

- After creation, `.pndcgnignore` is never auto-modified.
- The tool provides an explicit reseed action to regenerate the file from current ignore rules.
