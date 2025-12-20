# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## 1. Project Overview

**pndcgn** is a shell-based PDF documentation generation tool that converts Markdown files to PDF (and other formats) using Pandoc. The tool features intelligent SQLite-based caching, fingerprint-based change detection, and support for resumable runs. It's designed for batch processing documentation sets with high performance through caching and optional parallel processing.

## 2. Essential Commands

### 2.1. Running the Tool

```bash
# Run from project root - basic execution
./bin/pndcgn

# Preview what would be processed (dry-run mode)
./bin/pndcgn --dry-run

# Finalize a dry-run
./bin/pndcgn --finalize <run-id>

# Enable verbose output
./bin/pndcgn --verbose
```

### 2.2. Testing

```bash
# Run all tests (from project root)
shellspec

# Run specific test file
shellspec tests/pndcgn_spec.sh
shellspec tests/config_spec.sh
shellspec tests/processing_spec.sh
shellspec tests/database_spec.sh
shellspec tests/utilities_spec.sh

# Run specific test by line number
shellspec tests/pndcgn_spec.sh:25

# Generate coverage report with kcov (if installed)
shellspec --kcov

# View coverage report
open tests.results/coverage/index.html
```

### 2.3. Configuration

Configuration is managed via `.pndcgnignore` files (similar to `.gitignore`). The tool auto-creates this file on first run if it doesn't exist.

## 3. Code Architecture

### 3.1. Module Structure

The codebase follows a modular shell script architecture with a namespace prefix (`pndcgn_`) for all functions and variables:

```
bin/pndcgn                # Main controller - orchestrates entire workflow
src/
  constants.sh            # ANSI color codes and shared constants
  utilities.sh            # Helper functions (logging, paths, ULID fallback)
  database.sh             # SQLite operations and caching
  processing.sh           # File processing and conversion logic
tests/
  spec_helper.sh          # Test utilities and mocking framework
  pndcgn_spec.sh          # Main CLI entrypoint tests
  config_spec.sh          # Configuration management tests
  processing_spec.sh      # Processing function tests
  database_spec.sh         # Database operation tests
  utilities_spec.sh        # Utility function tests
  constants_spec.sh        # Constants validation tests
docs/                     # Comprehensive technical documentation
```

### 3.2. Key Design Patterns

**State Management**:
- Uses SQLite database (XDG-compliant location: `~/.local/state/pndcgn/pndcgn.db`) for persistent state
- Tracks runs via ULID-based run identifiers (sortable, timestamp-embedded)
- Implements fingerprint-based caching for change detection
- Supports WAL (Write-Ahead Logging) mode for concurrent access

**Configuration System**:
- `.pndcgnignore` file (similar to `.gitignore`) for file exclusion patterns
- Auto-created on first run with default patterns
- Seed-once policy: never auto-updated, explicit `--reseed` action required

**Error Handling**:
- Strict mode: `set -euo pipefail`
- Trap handlers for cleanup on INT/TERM signals
- Custom error function: `pndcgn_fail()`

### 3.3. Function Naming Conventions

All functions use the `pndcgn_` namespace prefix:
- `pndcgn_` - General namespace
- Module hints: `pndcgn_db_*` (database), `pndcgn_log_*` (logging)
- Verb-noun pattern: `pndcgn_compute_fingerprint`, `pndcgn_store_file`

Variables:
- Lowercase with underscores: `source_dir`, `run_id`
- Constants: Uppercase: `PNDCGN_DB`, `PNDCGN_ROOT`
- Global prefix: `pndcgn_*`

### 3.4. Current Implementation Status

The main script (`bin/pndcgn`) is fully implemented with:
- Complete argument parsing and validation
- Module-based architecture with all source files implemented:
  - `src/constants.sh` - ANSI codes and shared constants
  - `src/utilities.sh` - Helper functions (logging, paths, ULID fallback, prerequisites)
  - `src/database.sh` - SQLite operations and caching
  - `src/processing.sh` - File processing, fingerprinting, and conversion logic
- Comprehensive test suite with 88 examples (89.7% success rate)

## 4. Testing Framework

### 4.1. ShellSpec Configuration

Tests use **shellspec** with configuration in `.shellspec`:
- Default path: `tests/`
- Shell: `bash` with `--noprofile --norc`
- Format: documentation style with color output
- Optional parallel execution (currently commented out)

### 4.2. Test Environment

The `tests/spec_helper.sh` provides:
- **Test isolation**: Creates temporary directory per test
- **Mocking framework**: Mocks external commands (pandoc, sqlite3, uv, yq)
- **Shared constants**: Sources `src/constants.sh` for consistent output testing
- **Setup/cleanup hooks**: `setup_test_env()` and `cleanup_test_env()`

### 4.3. Mock System

External commands are mocked to print their invocation:
```bash
mock_all_commands()  # Creates mock functions for all external deps
cleanup_mocks()      # Unsets all mock functions
```

### 4.4. Writing Tests

Follow the existing patterns in `tests/pndcgn_spec.sh` and other spec files:
```bash
Describe "Component name"
    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'
    BeforeEach 'mock_all_commands'
    AfterEach 'cleanup_mocks'

    Context "when condition"
        It "does something"
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/module.sh"
            When call pndcgn_function_name "arg"
            The status should be success
            The output should include "expected text"
        End
    End
End
```

**Note**: For accurate coverage tracking, use `When run source` instead of direct dot sourcing (see `tests/README.md` for details).

## 5. Dependencies

### 5.1. Core Runtime Dependencies

Required for execution:
- `bash` - Shell environment
- `pandoc` - PDF generation engine
- `sqlite3` - State management database
- `uv` - Python package installer (for Pandoc filters)

### 5.2. Pandoc Filters

The tool integrates with these Pandoc filters (documented in README.md):
- `pandoc-plantuml-filter` - PlantUML diagram rendering
- `mermaid-filter` - Mermaid diagram rendering
- `pandoc-dbml-filter` - DBML diagram rendering
- `pandoc-fignos` - Figure numbering
- `pandoc-tablenos` - Table numbering
- `pandoc-secnos` - Section numbering
- `pandoc-imagine` - Generic diagram processing
- `pandoc-include` - File inclusion

### 5.3. Testing Dependencies

- `shellspec` - Test framework
- `kcov` - Coverage reporting (optional)

## 6. Development Workflow

### 6.1. Making Changes

1. **Understand the architecture**: Review `docs/050-technical-specification.md` and `docs/070-api-reference.md`
2. **Follow BDD/TDD**: The project uses test-driven development
3. **Maintain namespace**: All functions must use `pndcgn_` prefix
4. **Preserve error handling**: Keep `set -euo pipefail` and trap handlers
5. **Update constants**: Add new ANSI codes to `src/constants.sh`
6. **Source order matters**: Constants → Utilities → Database → Processing

### 6.2. Before Committing

Run the test suite to ensure no regressions:
```bash
shellspec
```

The test suite should have high coverage - use kcov to verify:
```bash
shellspec --kcov
```

### 6.3. Code Style

- Use 4-space indentation (consistent with existing code)
- Follow existing patterns for option parsing (`case "$1" in`)
- Use `printf` instead of `echo` for consistency
- Include descriptive comments for complex logic
- Maintain readonly variable declarations where applicable

## 7. Documentation

The `docs/` directory contains comprehensive technical documentation using a numbered naming scheme (`000-index.md`, `010-overview.md`, etc.):

- **000-index.md** - Documentation index
- **020-requirements.md** - Feature requirements and behaviors
- **050-technical-specification.md** - System architecture and data flow
- **070-api-reference.md** - Function signatures and usage
- **100-system-test-plan.md** - End-to-end test scenarios
- **110-implementation-plan.md** - Development roadmap
- **120-feature-unit-test-plan.md** - Unit test specifications

When adding features, update relevant documentation files following the established hierarchical numbering format (1, 1.1, 1.1.1).

## 8. Important Constraints

### 8.1. Configuration System

The configuration loading uses AWK parsing for TOML:
```bash
value=$(awk -F '=' '/output_root/ {gsub(/[ "\\t]/, "", $2); print $2}' "$config_file")
```

When modifying configuration parsing, ensure:
- Empty values are detected and reported as malformed
- Double quotes are stripped from values
- Default values use parameter expansion: `${VAR:-default}`

### 8.2. Database Schema

The SQLite database (XDG location: `~/.local/state/pndcgn/pndcgn.db`) uses:
- `runs` - Tracks execution runs with ULID, timestamps, status, and statistics
- `generated_files` - Maps fingerprints to output file paths with run IDs

Always use WAL mode and parameterized queries via `.param set`.

### 8.3. Output Structure

Generated files go to:
```
${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/
  ├── {dewey-prefix}-{filename}.{ext}  # Generated outputs
  └── _index.md                         # Run index with navigation
```

The output directory structure uses Dewey Decimal-style prefixes for logical sorting and organization.
