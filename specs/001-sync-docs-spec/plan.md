# Implementation Plan: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Branch**: `001-sync-docs-spec` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-sync-docs-spec/spec.md`

## Summary

Align implementation planning artifacts to the current consolidated spec for **pndcgn**, focusing on:

- Hidden run output directory default: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- `.pndcgnignore` lifecycle: discover at source root, seed-once from gitignore stacking (or built-in), never auto-update, explicit reseed action
- sqlite-ulid extension integration with Bash fallback for ULID generation
- Optional fzf integration for interactive source directory selection
- Output fingerprint format: `{total_size}:{artifact_count}:{sha256_of_all_content}`

See Phase 0 decisions in [research.md](./research.md).

## Technical Context

**Language/Version**: Bash (strict mode: `set -euo pipefail`)
**Primary Dependencies**: pandoc + sqlite3 + shellspec (test) + curl (for extension download)
**SQLite Extension**: sqlite-ulid v0.2.1 (auto-downloaded, Bash fallback if unavailable)
**Storage**: SQLite (persistent state/cache) with WAL mode
**Testing**: ShellSpec (BDD-style)
**Target Platform**: macOS + Linux (bash-based CLI)
**Project Type**: single CLI tool
**Performance Goals**: repeat run (no changes) ≥ 5× faster than first run (per spec SC-001)
**Constraints**: deterministic outputs; seed-once ignore; resumable runs; cache-first behavior; offline-capable (Bash ULID fallback)
**Scale/Scope**: source trees with many docs/assets; support incremental rebuilds

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Shell-first architecture: **PASS** (Bash-only core; namespacing required)
- Test-first development: **PASS** (ShellSpec; tests required before implementation)
- Documentation-driven design: **PASS** (spec and docs drive implementation)
- State via SQLite: **PASS** (persistent cache/state in SQLite with sqlite-ulid extension)
- Intelligent caching + resumable operations: **PASS** (required by spec and constitution)
- Unix philosophy: **PASS** (XDG-compliant paths, composable CLI, text in/out)

Notes:

- `.pndcgnignore` is treated as configuration (not state). Auto-creating it is an explicit, documented side effect.
- sqlite-ulid extension is optional; Bash fallback ensures offline operation capability.
- fzf integration is optional; tool functions without it.

## Project Structure

### Documentation (this feature)

```text
specs/001-sync-docs-spec/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── cli.md
│   └── pndcgnignore.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
bin/
└── pndcgn                     # primary entrypoint

src/
├── constants.sh                # ANSI codes, shared constants
├── database.sh                 # SQLite operations, extension loading
├── processing.sh               # Conversion logic, fingerprinting
└── utilities.sh                # Helper functions (ULID fallback, paths, logging)

lib/                            # Auto-created directory for sqlite-ulid extension
└── ulid0.so/.dylib            # Downloaded extension (platform-specific)

tests/
├── config_spec.sh
├── constants_spec.sh
├── database_spec.sh
├── processing_spec.sh
├── utilities_spec.sh
├── pndcgn_spec.sh              # Main controller tests
├── spec_helper.sh
└── README.md

docs/
└── (project documentation)
```

**Structure Decision**: single CLI tool, shell-based modules under `src/`, executable entrypoint under `bin/`, ShellSpec tests under `tests/`, extension storage in `lib/` directory.

## Complexity Tracking

No constitution violations are required by this plan.
