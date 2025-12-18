# Implementation Plan: pndcgn Spec Consolidation

**Branch**: `001-sync-docs-spec` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-sync-docs-spec/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

---

<details><summary>Table of Contents</summary>>

- [Implementation Plan: pndcgn Spec Consolidation](#implementation-plan-pndcgn-spec-consolidation)
  - [1. Summary](#1-summary)
  - [2. Technical Context](#2-technical-context)
  - [3. Constitution Check](#3-constitution-check)
    - [3.1. I. Shell-First Architecture ✅](#31-i-shell-first-architecture-)
    - [3.2. II. Test-First Development ✅](#32-ii-test-first-development-)
    - [3.3. III. Documentation-Driven Design ✅](#33-iii-documentation-driven-design-)
    - [3.4. IV. State Management via SQLite ✅](#34-iv-state-management-via-sqlite-)
    - [3.5. V. Intelligent Caching ✅](#35-v-intelligent-caching-)
    - [3.6. VI. Resumable Operations ✅](#36-vi-resumable-operations-)
    - [3.7. VII. Unix Philosophy ✅](#37-vii-unix-philosophy-)
  - [4. Project Structure](#4-project-structure)
    - [4.1. Documentation (this feature)](#41-documentation-this-feature)
    - [4.2. Source Code (repository root)](#42-source-code-repository-root)
  - [5. Complexity Tracking](#5-complexity-tracking)

</details>

---

## 1. Summary

Consolidate documentation specifications and implement core features for pndcgn, a Bash-based documentation generator that converts markdown and text files into various formats (default: PDF) using Pandoc. The tool provides intelligent caching, resumable operations, and configuration via `.pndcgnignore` and TOML files. Key features include dry-run/finalize workflow, run management, and XDG-compliant state management via SQLite.

## 2. Technical Context

**Language/Version**: Bash 5.0+ (strict mode: `set -euo pipefail`)
**Primary Dependencies**:

- `pandoc` - Document conversion engine
- `sqlite3` - State management with WAL mode
- `sqlite-ulid` extension (optional, with Bash fallback) - ULID generation
- `fzf` (optional) - Interactive directory selection
- ShellSpec - Testing framework

**Storage**: SQLite database at `${XDG_STATE_HOME:-${HOME}/.local/state}/pndcgn/cache.sqlite`
**Testing**: ShellSpec framework (BDD/TDD pattern, minimum 50% coverage target, 70% for utility modules)
**Target Platform**: Unix-like systems (Linux, macOS) with Bash 5.0+
**Project Type**: Single CLI application
**Performance Goals**:

- Repeat runs with unchanged inputs complete at least 5× faster than initial run (SC-001)
- O(1) fingerprint computation (only first 64KB hashed)
- Cache hit/miss tracking and reporting

**Constraints**:

- Pure Bash implementation (no Python/Ruby dependencies for core logic)
- XDG Base Directory Specification compliance
- Minimal external dependencies (pandoc, sqlite3 required; fzf, sqlite-ulid optional)
- Strict mode enforcement (`set -euo pipefail`)
- Function namespacing: `pndcgn_` prefix
- Variable namespacing: `pndcgn_` or `PNDCGN_` prefix

**Scale/Scope**:

- Handles projects with thousands of documentation files
- Concurrent runs supported via SQLite WAL mode
- Single-user tool (no multi-user authentication required)

## 3. Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### 3.1. I. Shell-First Architecture ✅

- **Status**: COMPLIANT
- Pure Bash implementation with strict mode (`set -euo pipefail`)
- Function namespacing with `pndcgn_` prefix
- Variable namespacing with `pndcgn_`/`PNDCGN_` prefix
- No language dependencies for core logic (pandoc/sqlite3 are external tools, not language runtimes)

### 3.2. II. Test-First Development ✅

- **Status**: COMPLIANT
- ShellSpec framework required
- BDD/TDD pattern enforced (Red-Green-Refactor)
- Minimum 50% code coverage target (70% for utility modules)
- Tests executable with `bash` (not dependent on user's shell configuration)

### 3.3. III. Documentation-Driven Design ✅

- **Status**: COMPLIANT
- Feature specified in `spec.md` with user stories
- Technical specifications in contracts/
- API reference in function signatures
- Test plans align with requirements

### 3.4. IV. State Management via SQLite ✅

- **Status**: COMPLIANT
- SQLite with WAL mode for concurrent access
- ULID-based run identifiers
- Fingerprint-based caching (`{size}:{mtime}:{sha256_first_64KB}`)
- Parameterized queries via `.param set`

### 3.5. V. Intelligent Caching ✅

- **Status**: COMPLIANT
- O(1) fingerprint computation (first 64KB only)
- Cache hit/miss ratio tracking
- Idempotent operations (unchanged inputs produce identical output without reprocessing)

### 3.6. VI. Resumable Operations ✅

- **Status**: COMPLIANT
- Run state tracked in database (`running`, `complete`, `failed`, `interrupted`)
- `--resume` flag supported
- Dry-run → finalize workflow via `--dry-run` then `--finalize RUN_ID`
- Fingerprint validation ensures consistency

### 3.7. VII. Unix Philosophy ✅

- **Status**: COMPLIANT
- Single purpose: Convert markdown to formats via Pandoc
- Text in/out: Logs to stdout, errors to stderr
- Exit codes: 0 = success, 1 = error, 2 = invalid usage
- Pipeline-friendly: Accepts paths as arguments
- XDG standards: State in `${XDG_STATE_HOME:-${HOME}/.local/state}/pndcgn/`
- Configuration in `pndcgn.toml` or `${XDG_CONFIG_HOME}/pndcgn/pndcgn.toml`

**Constitution Check Result**: ✅ ALL GATES PASSED

## 4. Project Structure

### 4.1. Documentation (this feature)

```text
specs/001-sync-docs-spec/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── cli.md
│   ├── pndcgnignore.md
│   └── toml-config.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### 4.2. Source Code (repository root)

```text
bin/
└── pndcgn               # Main CLI entrypoint

src/
├── constants.sh         # ANSI codes and shared constants (no dependencies)
├── utilities.sh         # Helper functions (may use constants)
├── database.sh          # SQLite operations (may use constants and utilities)
└── processing.sh        # Conversion logic (may use all above)

tests/
├── spec_helper.sh       # Test framework setup
├── *_spec.sh            # ShellSpec test files
├── unit/                # Unit tests for individual functions
├── integration/         # Integration tests for component interactions
└── database/            # Database-specific tests

docs/                    # User-facing documentation
├── 010-overview.md
├── 020-requirements.md
├── 040-user-guide.md
├── 050-technical-specification.md
├── 060-database-schema.md
├── 070-api-reference.md
├── 080-output-formats.md
└── 100-system-test-plan.md
```

**Structure Decision**: Single project structure following the existing pndcgn codebase layout. The main CLI entrypoint is `bin/pndcgn`, with modular source files in `src/` that follow a strict dependency order (constants → utilities → database → processing). Tests are organized by type (unit, integration, database) using ShellSpec framework.

## 5. Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - all constitution gates passed. No complexity justification required.

---
