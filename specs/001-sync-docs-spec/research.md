# Research: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Branch**: `001-sync-docs-spec`
**Date**: 2025-12-14
**Spec**: [spec.md](./spec.md)

## Decisions

### Decision: Default output directory is hidden under target

- **Chosen**: Default run output directory is `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.
- **Rationale**: Keeps generated artifacts out of the user’s normal directory listing while still being easy to find and clean. Reduces accidental commits; pairs naturally with ignore defaults.
- **Alternatives considered**:
  - `${TARGET_DIR}/pndcgn/...` (more visible, higher chance of accidental commits)
  - `${TARGET_DIR}/${TYPE}-${RUN_ID}/` (no tool namespace)

### Decision: Ignore configuration via `.pndcgnignore`

- **Chosen**: Support `.pndcgnignore` discovered relative to the **source directory root**.
- **Rationale**: Lets users point `pndcgn` at subtrees without requiring repo-root config; makes behavior portable for “docs-only” subsets.
- **Alternatives considered**:
  - Only repo-root ignore file (less portable)
  - Global ignore file only (surprising per-project differences)

### Decision: Seeding `.pndcgnignore` from `.gitignore` with stacking behavior

- **Chosen**: If `.pndcgnignore` does not exist, auto-create it on the first non-help run and seed it from applicable `.gitignore` rules using closest-first stacking (git-like behavior).
- **Rationale**: Matches user expectations: “ignore what git ignores for this subtree.” Provides a good default without requiring manual config.
- **Alternatives considered**:
  - Only repo-root `.gitignore` (often wrong for nested subtrees)
  - Built-in ignore list only (misses repo-specific ignored paths)

### Decision: Seed once; never auto-update `.pndcgnignore`

- **Chosen**: After `.pndcgnignore` exists, never modify it automatically. Provide an explicit, user-invoked action to reseed.
- **Rationale**: Avoids silently rewriting user intent. Preserves explicit configuration.
- **Alternatives considered**:
  - Auto-sync on each run (surprising and destructive)
  - Auto-sync only if unchanged (more complex; defer unless needed)

### Decision: Default ignore content must include `.pndcgn`

- **Chosen**: Seeded defaults must include `.pndcgn` so generated outputs are ignored by default.
- **Rationale**: Prevents accidental commits and reduces noise.

### Decision: ULID generation via sqlite-ulid extension with Bash fallback

- **Chosen**: Use `sqlite-ulid` extension's `ulid()` function for ULID generation when available, with Bash-based fallback if extension cannot be downloaded, installed, or loaded.
- **Rationale**: Extension provides native SQLite integration and better performance, while Bash fallback ensures tool remains functional offline or on unsupported platforms. Fallback maintains same ULID format (26 characters, lexicographically sortable, timestamp-embedded) for consistency.
- **Alternatives considered**:
  - Bash-only ULID generation (simpler, but misses SQLite-native integration benefits)
  - Extension-only (fails on network issues or unsupported platforms, violates offline-capable constraint)
  - UUID instead of ULID (not lexicographically sortable, loses timestamp ordering benefit)

## Implementation Notes (non-binding)

- **Git ignore stacking**: Prefer using git tooling when available (e.g., `git` installed and source directory is within a git work tree) to avoid re-implementing full `.gitignore` semantics. Provide a fallback when git is unavailable.
- **Reseed action**: Provide an explicit reseed action (e.g., `--reseed`) that regenerates `.pndcgnignore` from current ignore rules.
  - **Fingerprint impact**: Reseeding can change the effective input set and therefore MUST be treated as a configuration change that can invalidate fingerprints used for `--finalize` and `--resume` validation.
  - **Allowed behavior**: If reseed occurs between dry-run and finalize (or for a resumable run), the tool should detect the mismatch and fail safely with an actionable message (or require creating a new run).
