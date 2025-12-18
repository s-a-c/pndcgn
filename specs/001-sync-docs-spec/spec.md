# Feature Specification: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Feature Branch**: `001-sync-docs-spec`
**Created**: 2025-12-14
**Status**: Draft
**Input**: User description: "incorporate @docs , @.scratch/project-restoration/020-implementation-adjustments.md , @.scratch/project-restoration/021-additional-notes.md"

**Documentation Structure**: This specification follows hierarchical structure per Constitution §III (Documentation-Driven Design). Sections use markdown headers (`##`, `###`, `####`) which create implicit hierarchical numbering when rendered. The structure satisfies the constitutional requirement for "sequential numbering (1, 1.1, 1.1.1) excluding main title" through markdown's hierarchical header structure.

---

<details><summary>Table of Contents</summary>>

- [Feature Specification: pndcgn Spec Consolidation](#feature-specification-pndcgn-spec-consolidation)
  - [1. Clarifications](#1-clarifications)
    - [1.1. Session 2025-12-14](#11-session-2025-12-14)
  - [2. User Scenarios *(mandatory)*](#2-user-scenarios-mandatory)
    - [2.1. User Story 1 - Generate documentation outputs for a project (Priority: P1)](#21-user-story-1---generate-documentation-outputs-for-a-project-priority-p1)
    - [2.2. User Story 2 - Preview a run and finalize safely (Priority: P2)](#22-user-story-2---preview-a-run-and-finalize-safely-priority-p2)
    - [2.3. User Story 3 - Manage runs and understand results (Priority: P3)](#23-user-story-3---manage-runs-and-understand-results-priority-p3)
  - [3. Test Requirements *(mandatory)*](#3-test-requirements-mandatory)
    - [3.1. Test Environment](#31-test-environment)
    - [3.2. Test Fixtures](#32-test-fixtures)
      - [3.2.1. User Story 1 Fixture ("Small Fixture Project")](#321-user-story-1-fixture-small-fixture-project)
      - [3.2.2. User Story 2 Fixture (Dry-Run Test Data)](#322-user-story-2-fixture-dry-run-test-data)
      - [3.2.3. User Story 3 Fixture (Interrupted Run Test Data)](#323-user-story-3-fixture-interrupted-run-test-data)
      - [3.2.4. SC-001 Performance Fixture ("Representative Project")](#324-sc-001-performance-fixture-representative-project)
      - [3.2.5. Edge Case Fixtures](#325-edge-case-fixtures)
    - [3.3. Test Data Requirements](#33-test-data-requirements)
    - [3.4. Test Coverage Requirements](#34-test-coverage-requirements)
    - [3.5. Edge Cases](#35-edge-cases)
  - [4. Requirements *(mandatory)*](#4-requirements-mandatory)
    - [4.1. Functional Requirements](#41-functional-requirements)
    - [4.2. Key Entities *(include if feature involves data)*](#42-key-entities-include-if-feature-involves-data)
  - [5. Success Criteria *(mandatory)*](#5-success-criteria-mandatory)
    - [5.1. Measurable Outcomes](#51-measurable-outcomes)
  - [6. Assumptions](#6-assumptions)
  - [7. Out of Scope](#7-out-of-scope)
  - [8. Non-Functional Requirements *(phased delivery)*](#8-non-functional-requirements-phased-delivery)
    - [8.1. NFR-SEC: Security Requirements](#81-nfr-sec-security-requirements)
      - [8.1.1. File System Security](#811-file-system-security)
      - [8.1.2. Input Validation Security](#812-input-validation-security)
      - [8.1.3. State Management Security](#813-state-management-security)
      - [8.1.4. Configuration Security](#814-configuration-security)
      - [8.1.5. Destructive Operations Security](#815-destructive-operations-security)
      - [8.1.6. Data Privacy](#816-data-privacy)
      - [8.1.7. Logging \& Information Disclosure Security](#817-logging--information-disclosure-security)
      - [8.1.8. Threat Model Coverage](#818-threat-model-coverage)
    - [8.2. NFR-CLI: CLI User Experience](#82-nfr-cli-cli-user-experience)
      - [8.2.1. Accessibility](#821-accessibility)
      - [8.2.2. Help \& Version Output](#822-help--version-output)
      - [8.2.3. Output Modes](#823-output-modes)
      - [8.2.4. Terminal Behavior](#824-terminal-behavior)
      - [8.2.5. Run ID Display](#825-run-id-display)
      - [8.2.6. Timing \& Duration](#826-timing--duration)
      - [8.2.7. Confirmation Prompts](#827-confirmation-prompts)
      - [8.2.8. Progress Reporting](#828-progress-reporting)
      - [8.2.9. Final Summary Output](#829-final-summary-output)
      - [8.2.10. Error Messages](#8210-error-messages)
      - [8.2.11. fzf Integration](#8211-fzf-integration)
      - [8.2.12. Keyboard Interrupt](#8212-keyboard-interrupt)
    - [8.3. NFR-CACHE: Caching \& State Management](#83-nfr-cache-caching--state-management)
      - [8.3.1. Fingerprint Computation](#831-fingerprint-computation)
      - [8.3.2. Cache Behavior](#832-cache-behavior)
      - [8.3.3. Database State](#833-database-state)
      - [8.3.4. Run State Machine](#834-run-state-machine)
      - [8.3.5. Resume Behavior](#835-resume-behavior)
      - [8.3.6. Dry-Run/Finalize](#836-dry-runfinalize)
      - [8.3.7. ULID Generation](#837-ulid-generation)
      - [8.3.8. Cache Metrics](#838-cache-metrics)
      - [8.3.9. Cleanup Operations](#839-cleanup-operations)
    - [8.4. NFR-EDGE: Extended Edge Cases](#84-nfr-edge-extended-edge-cases)
      - [8.4.1. Source Directory](#841-source-directory)
      - [8.4.2. Target Directory](#842-target-directory)
      - [8.4.3. Input Files](#843-input-files)
      - [8.4.4. Output Type](#844-output-type)
      - [8.4.5. Concurrent Operations](#845-concurrent-operations)
      - [8.4.6. Signal Handling](#846-signal-handling)
      - [8.4.7. Resume Edge Cases](#847-resume-edge-cases)
      - [8.4.8. Finalize Edge Cases](#848-finalize-edge-cases)
      - [8.4.9. External Dependencies](#849-external-dependencies)
      - [8.4.10. Configuration Edge Cases](#8410-configuration-edge-cases)
      - [8.4.11. Cleanup Edge Cases](#8411-cleanup-edge-cases)
      - [8.4.12. Resource Exhaustion](#8412-resource-exhaustion)
    - [8.5. NFR-TOML: TOML Configuration](#85-nfr-toml-toml-configuration)
      - [8.5.1. File Discovery](#851-file-discovery)
      - [8.5.2. Pattern Syntax](#852-pattern-syntax)
      - [8.5.3. Extension Syntax](#853-extension-syntax)
      - [8.5.4. TOML Parsing](#854-toml-parsing)
      - [8.5.5. Error Handling](#855-error-handling)
      - [8.5.6. Validation](#856-validation)
      - [8.5.7. Pattern Precedence](#857-pattern-precedence)
      - [8.5.8. Integration](#858-integration)
      - [8.5.9. Edge Cases](#859-edge-cases)
      - [8.5.10. Documentation](#8510-documentation)

</details>

---

## 1. Clarifications

### 1.1. Session 2025-12-14

- Q: What input files count as “documentation sources”? → A: Configurable include/exclude patterns are supported; if no configuration is provided, defaults apply (defaults include: docs + doc-assets allowlist plus all text-based files, excluding common ignore directories).
- Q: What counts as a “common non-relevant directory” to exclude by default? → A: Use `.pndcgnignore` defaults (seeded from `.gitignore` on first run).
- Q: Where should `.pndcgnignore` live? → A: In the source directory root (the directory passed as the source input).
- Q: Should `.pndcgnignore` be auto-created on first run when missing? → A: Yes (auto-create on first non-help run).
- Q: What should the output run directory structure be? → A: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.
- Q: When seeding `.pndcgnignore` from `.gitignore`, which rules should be used? → A: Merge all applicable `.gitignore` files (closest-first), matching git’s ignore stacking behavior.
- Q: What should happen if `.pndcgnignore` already exists but `.gitignore` changes later? → A: Never auto-update; only seed on first creation (explicit reseed action only).
- Q: How should the system handle errors and edge cases? → A: Explicit error messages with exit codes and actionable recovery guidance (messages to stderr, exit codes per Unix conventions, include recovery steps when applicable).
- Q: Where and how should include/exclude pattern configuration be stored? → A: `.pndcgnignore` file (exclude patterns) plus optional TOML config file for explicit include patterns (if TOML config not present, use defaults: include docs + doc-assets allowlist plus all text-based files).
- Q: What is the CLI interface for cleanup operations? → A: `--clean <RUN_ID> [RUN_ID...]` removes specific run outputs (accepts one or more run IDs); `--drop` clears all cache/state. Both require confirmation and MUST warn if fingerprint is invalid or if output_path contains non-pndcgn artifacts.
- Q: What format should progress reporting and statistics use? → A: Human-readable summary to stdout (counts, timing, cache efficiency) plus structured data available via database queries for programmatic access.
- Q: What format should the run index artifact use? → A: Markdown index file (`_index.md`) with navigation links and statistics, placed in the run output directory.
- Q: What algorithm should be used for fingerprint computation? → A: `{size}:{mtime}:{sha256_first_64KB}` format (size in bytes, modification time as Unix timestamp, SHA256 hash of first 64KB of file content).
- Q: What should the run fingerprint include for finalize/resume validation? → A: Combined fingerprint of all input file fingerprints plus configuration state (output type, source/target paths, ignore rules content).
- Q: What output types should be supported? → A: All pandoc-supported output types (pdf, html, epub, docx, odt, rtf, etc.) with validation against pandoc's list of supported formats.
- Q: Where should the TOML config file be located? → A: Hierarchy: first check XDG config directory (`${XDG_CONFIG_HOME:-${HOME}/.config}/pndcgn/pndcgn.toml`), then fall back to source directory root (`pndcgn.toml`). Source directory config overrides XDG config if both exist.
- Q: How should the system handle concurrent runs? → A: Allow concurrent runs with database-level locking (SQLite WAL mode); each run gets its own run ID and output directory. Database handles coordination automatically.
- Q: How should the system handle sqlite-ulid extension download failures? → A: Fall back to alternative ULID generation method (e.g., Bash-based) if extension download fails or extension is unavailable.
- Q: What format should be used for output_fingerprint? → A: Combined fingerprint format similar to input fingerprint: `{total_size}:{artifact_count}:{sha256_of_all_content}` (total size in bytes, artifact count, SHA256 hash of concatenated artifact content).
- Q: How should default patterns and extensions interact when both are present in defaults? → A: OR logic: include file if it matches ANY pattern OR ANY extension (e.g., `README.txt` matches extension `txt` even if no pattern matches it).
- Q: What should be included in the built-in default for .pndcgnignore when no .gitignore exists? → A: Comprehensive: `.pndcgn` plus an extensive list of common ignores (build dirs, cache dirs, logs, temp files, dependency directories, version control directories, etc.).
- Q: What constitutes a "representative project" for SC-001 performance testing? → A: A project containing at least 50 markdown/text documentation files across multiple nested directories, with a mix of file sizes (<1KB to <100KB), representing a typical documentation structure with common assets.

## 2. User Scenarios *(mandatory)*

### 2.1. User Story 1 - Generate documentation outputs for a project (Priority: P1)

As a documentation maintainer, I want to run **pndcgn** against a project directory so that I receive a navigable set of generated documentation artifacts (default: PDF) that are easy to browse and share.

**Why this priority**: This is the core user value—turning a project’s documentation sources into an organized output set.

**Independent Test**: Can be fully tested by running the tool against a small fixture project and confirming the expected output directory and index are produced.

**Acceptance Scenarios**:

1. **Given** a directory containing documentation sources, **When** I run the tool with default inputs, **Then** it generates output in a new run directory under my current working directory.
2. **Given** a directory containing documentation sources, **When** I request a specific output format and a specific output location, **Then** it generates outputs under that location and produces a navigable index for the run.

---

### 2.2. User Story 2 - Preview a run and finalize safely (Priority: P2)

As a documentation maintainer, I want to perform a **dry-run** to understand what will be generated, and then **finalize** that same plan later, so that I can avoid surprises while still having a fast, repeatable workflow.

**Why this priority**: Dry-run/finalize reduces risk for large repos and supports cautious workflows.

**Independent Test**: Can be tested by performing a dry-run, recording the run identifier, changing nothing, then finalizing and verifying outputs are produced.

**Acceptance Scenarios**:

1. **Given** a directory of documentation sources, **When** I run the tool in dry-run mode, **Then** no output artifacts are created and the tool prints a run identifier that can be used to finalize later.
2. **Given** a previous dry-run identifier and unchanged inputs, **When** I finalize that dry-run, **Then** the tool produces the same set of outputs that the dry-run described.
3. **Given** a previous dry-run identifier and inputs that have changed since that dry-run, **When** I attempt to finalize, **Then** the tool refuses to finalize and explains what changed.

---

### 2.3. User Story 3 - Manage runs and understand results (Priority: P3)

As a documentation maintainer, I want to resume interrupted runs, clean up old runs, and review run statistics, so that the tool stays reliable over time and I can understand what happened during generation.

**Why this priority**: Run management and reporting turn the tool from “one-off script” into something teams can trust and operate.

**Independent Test**: Can be tested by interrupting a run, resuming it, and validating that already-generated outputs are not repeated.

**Acceptance Scenarios**:

1. **Given** a previously started run that did not complete, **When** I resume it by run identifier, **Then** it continues work and does not repeat already-completed work.
2. **Given** completed runs, **When** I request cleanup, **Then** the tool removes only the specified run outputs and does not affect unrelated data without explicit confirmation.
3. **Given** a completed run, **When** I review run statistics, **Then** I can see a human-readable summary (counts, timing, cache efficiency) and can query detailed statistics from the database.

---

## 3. Test Requirements *(mandatory)*

**Purpose**: Define test environment, fixtures, and data requirements to ensure all scenarios are testable with deterministic inputs.

### 3.1. Test Environment

**ShellSpec Framework**: All tests MUST use ShellSpec framework for BDD/TDD pattern compliance (Constitution §II).

**Test Execution**: Tests MUST be executable with `bash` (not dependent on user's shell configuration).

**Test Isolation**: Each test MUST run in isolation using temporary directories. Tests MUST clean up after themselves and MUST NOT rely on shared state between test runs.

**Prerequisites for Testing**: Test environment MUST have:

- `bash` 5.0+ (strict mode: `set -euo pipefail`)
- ShellSpec framework installed
- `pandoc` (for integration tests)
- `sqlite3` (for database tests)
- `shasum` or `openssl` (for fingerprint computation tests)

**CI Environment**: Tests MUST pass in CI environments with minimal dependencies. Mock external commands (pandoc, sqlite3) when testing in isolation.

### 3.2. Test Fixtures

#### 3.2.1. User Story 1 Fixture ("Small Fixture Project")

**Purpose**: Test basic generation workflow independently.

**Structure**:

```log
fixture-project/
├── docs/
│   ├── 01-introduction.md
│   ├── 02-installation.md
│   └── guides/
│       └── quickstart.md
└── README.md
```

**Requirements**:

- At least 3-5 markdown files across nested directories
- Mix of file sizes (<1KB to <10KB)
- Representative of typical documentation structure
- No special edge cases (no symlinks, no binary files, no permission issues)

#### 3.2.2. User Story 2 Fixture (Dry-Run Test Data)

**Purpose**: Test dry-run and finalize workflow.

**Structure**: Same as User Story 1 fixture.

**Additional Requirements**:

- Files with known content (for fingerprint validation)
- Ability to modify files between dry-run and finalize (for change detection tests)
- Clear timestamps for validation

#### 3.2.3. User Story 3 Fixture (Interrupted Run Test Data)

**Purpose**: Test resume functionality and run management.

**Structure**: Same as User Story 1 fixture.

**Additional Requirements**:

- Sufficient files to allow interruption/resume simulation (10-20 files)
- Database state with interrupted runs (for resume tests)
- Multiple run IDs (for cleanup tests)

#### 3.2.4. SC-001 Performance Fixture ("Representative Project")

**Purpose**: Validate performance success criteria (5× speedup on repeat runs).

**Structure**:

- At least 50 markdown/text files across multiple nested directories (e.g., `docs/`, `guides/`, `api-docs/`)
- Mix of file sizes (small <1KB to medium <100KB)
- Common documentation assets (images, diagrams referenced by docs)
- Representative of typical documentation structure

**Usage**: First run establishes baseline; second run with unchanged inputs validates 5× speedup.

#### 3.2.5. Edge Case Fixtures

**For each edge case scenario** (see Edge Cases section):

- Test fixtures MUST simulate the specific edge case condition
- Examples: empty directories, symlinks, binary files, permission issues, concurrent runs, etc.
- Fixtures MUST be deterministic and reproducible

### 3.3. Test Data Requirements

**Independence**: Each test scenario MUST use its own test data/fixtures to ensure test independence (Constitution §Testing Standards).

**Deterministic Inputs**: All test inputs MUST be deterministic and reproducible. Avoid random data or timestamps that change between runs (use fixed timestamps in fixtures when needed).

**Mock Requirements**: External commands (pandoc, sqlite3, curl) SHOULD be mockable for unit tests. Integration tests use real commands.

**Cleanup**: All tests MUST clean up temporary files, directories, and database state after execution.

### 3.4. Test Coverage Requirements

**Minimum Coverage**: 50% code coverage target overall (Constitution §II).

**Utility Module Coverage**: 70% code coverage target for utility modules (`src/utilities.sh`, etc.).

**Coverage Tracking**: Use `When call` pattern in ShellSpec for coverage-trackable tests. Use `When run` only when subprocess isolation is required (mocking, exit codes).

**Coverage Limitations**: Tests using `When run` will show 0% coverage due to kcov subprocess limitation. This is acceptable when subprocess isolation is required.

---

### 3.5. Edge Cases

The system MUST handle edge cases with explicit error messages, appropriate exit codes, and actionable recovery guidance:

- **Source directory does not exist or is unreadable**: Display error message to stderr, exit code 1, suggest checking path and permissions.
- **Target directory is not writable**: Display error message to stderr, exit code 1, suggest checking permissions or specifying alternative target.
- **Unsupported output type provided**: Display error message to stderr listing supported types (from pandoc), exit code 2 (invalid usage), suggest valid alternatives.
- **Interrupted run (process killed) and later resumption**: Run status marked as `interrupted` in database; on resume, validate fingerprint and continue from last checkpoint with clear progress indication.
- **Cached outputs missing or manually deleted**: Detect mismatch between cache entry and filesystem; regenerate affected artifacts and update cache, log warning to stderr.
- **Inputs change between dry-run and finalize**: Validate fingerprint mismatch; fail finalization with exit code 1, display actionable explanation of what changed (e.g., "Source file X modified, run Y deleted").
- **Concurrent runs**: Multiple runs executing simultaneously MUST be allowed; each gets its own run ID and output directory. SQLite WAL mode handles database coordination automatically.
- **fzf not installed or unavailable**: If `fzf` is not installed or not available in PATH, the system MUST silently fall back to using the current working directory as the default source directory. No error message or warning is required.
- **sqlite-ulid extension download failure or unavailable**: If the `sqlite-ulid` extension cannot be downloaded (network issues, unsupported platform), installed (permission issues), or loaded (corrupted file), the system MUST fall back to an alternative ULID generation method (e.g., Bash-based) and continue operation. The system MAY log a warning to stderr indicating the fallback is being used, but MUST NOT fail or prevent operation.

## 4. Requirements *(mandatory)*

### 4.1. Functional Requirements

- **FR-001**: The system MUST provide a primary CLI entrypoint named **`pndcgn`** for users to generate documentation outputs.
- **FR-002**: The system MUST support an optional source directory argument; if omitted, it MUST default to the current working directory.
  - When running without arguments, the system MUST use the current working directory as the source directory.
  - If `fzf` is installed and available in PATH, and SOURCE_DIR is not provided, the system MAY offer an interactive folder selection interface using `fzf` to allow the user to choose a source directory from available subdirectories.
  - The `fzf` interface MUST only display directories (folders), not files.
  - If `fzf` is not available or the user cancels the selection, the system MUST fall back to using the current working directory as the default source directory.
  - The `fzf` integration MUST be optional and MUST NOT be required for normal operation.
- **FR-003**: The system MUST support an optional target directory argument representing the *output parent directory*; if omitted, it MUST default to the current working directory.
- **FR-004**: The system MUST support an output type option (`--type`) that controls the output format; if omitted, it MUST default to `pdf`.
  - The system MUST support all output types supported by pandoc (e.g., pdf, html, epub, docx, odt, rtf, and others).
  - The system MUST validate that the requested output type is supported by the installed pandoc version and MUST fail with exit code 2 (invalid usage) if an unsupported type is provided.
  - The system SHOULD support accessible output formats (HTML with semantic markup, EPUB with proper structure) when accessibility is a requirement.
  - PDF accessibility depends on pandoc and LaTeX configuration; the tool does not enforce PDF accessibility standards but supports formats that enable accessibility.
- **FR-004A**: The system MUST support configurable include patterns for determining which inputs are eligible for processing.
  - Include patterns MAY be configured via an optional TOML config file named `pndcgn.toml` (see contract: `contracts/toml-config.md`).
  - TOML config file discovery MUST follow this hierarchy (first found wins): `${XDG_CONFIG_HOME:-${HOME}/.config}/pndcgn/pndcgn.toml`, then source directory root `pndcgn.toml`. Source directory config overrides XDG config if both exist.
  - If no TOML config file is found, the system MUST use sensible defaults (include: `docs/` directory, `doc-assets/` directory, plus all text-based files).
  - For defaults, when both patterns and extensions are defined, a file is included if it matches ANY pattern OR ANY extension (OR logic, not AND).
  - For user-provided TOML config, if both patterns and extensions are specified, patterns take precedence over extensions (see contract precedence rules).
  - Exclude patterns are configured via `.pndcgnignore` file (see FR-004B).
- **FR-004B**: The system MUST support an ignore file named `.pndcgnignore` for exclude patterns.
  - The `.pndcgnignore` file MUST be discovered relative to the source directory root.
  - If `.pndcgnignore` does not exist in the source directory root, the system MUST auto-create it on the first non-help run.
  - When auto-creating, the system MUST seed it with default content derived from a project's `.gitignore` rules (when present).
    - If multiple `.gitignore` files apply to the source directory, it MUST merge them closest-first, matching git's ignore stacking behavior.
    - If no applicable `.gitignore` rules exist, it MUST seed from a comprehensive built-in default that includes `.pndcgn` plus common development artifacts (build directories, cache directories, log files, temporary files, dependency directories like `node_modules/` and `vendor/`, version control directories like `.git/`, OS-specific files, etc.).
  - After `.pndcgnignore` exists, the system MUST NOT modify it automatically, even if `.gitignore` changes.
  - The system MUST provide an explicit, user-invoked action to re-seed `.pndcgnignore` from current ignore rules (via `--reseed` flag).
  - The default ignore content MUST include the output directory name `.pndcgn` so generated outputs are ignored by default.

- **FR-005**: For each invocation that performs generation (non-help), the system MUST create a new, uniquely identified **run** and associate all generated outputs to that run.
  - The system MUST allow concurrent runs (multiple invocations running simultaneously) and MUST use SQLite WAL mode for safe concurrent database access.
  - Each concurrent run MUST receive its own unique run ID and output directory; database-level locking handles coordination automatically.
- **FR-006**: The system MUST place outputs for a run into a deterministic run directory under the target directory, and that directory name MUST include both the selected output type and the run identifier.
  - Default structure: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.

- **FR-007**: The system MUST generate a run index artifact that enables a user to navigate to the generated outputs for that run.
  - The index MUST be a Markdown file named `_index.md` placed in the run output directory.
  - The index MUST include navigation links to all generated outputs and run statistics (counts, timing, cache efficiency).
  - The index SHOULD include a Mermaid diagram showing the document structure hierarchy (if Mermaid is supported by the viewing environment).
  - The index MUST provide alternative text-based navigation (hierarchical list) for environments that do not support Mermaid diagrams.
- **FR-008**: The system MUST generate outputs using a stable, human-browsable naming scheme that preserves project hierarchy ordering (e.g., Dewey Decimal-style prefixes).
  - File names MUST be readable and descriptive (e.g., `100-introduction.pdf`, `200.010-installation.pdf`).
  - File names MUST use lowercase with hyphens for readability and cross-platform compatibility.
  - File names MUST avoid special characters that may cause issues in file systems or URLs.
- **FR-009**: The system MUST detect whether individual inputs are unchanged since the last successful generation and MUST avoid regenerating unchanged outputs.
  - Fingerprint computation MUST use the format `{size}:{mtime}:{sha256_first_64KB}` (size in bytes, modification time as Unix timestamp, SHA256 hash of first 64KB of file content).
  - This enables O(1) fingerprint computation while maintaining sufficient accuracy for change detection.
- **FR-010**: When inputs are unchanged, the system MUST complete a subsequent run significantly faster than a first-time run and MUST report how much work was skipped vs performed.
  - Progress reporting MUST include a human-readable summary written to stdout with counts (total/processed/skipped/failed), timing information, and cache efficiency metrics.
  - The summary format MUST be: `Processed: X | Skipped: Y | Failed: Z | Duration: <time> | Cache efficiency: <percentage>%`
  - Detailed statistics MUST be stored in the database and accessible via SQL queries for programmatic access.
- **FR-011**: The system MUST support resuming an interrupted run by run identifier, and MUST skip work already completed for that run.
  - Progress indication during resume MUST display: "Resuming from X/Y files" format showing how many files were already processed.
- **FR-012**: The system MUST support a dry-run mode that produces no output artifacts and clearly communicates what would be generated.
  - Dry-run MUST print a run ID that can be used with `--finalize` to execute the plan.
  - Dry-run MUST indicate the number of files that would be processed and the output directory that would be created.
  - Dry-run MUST list any files that would be skipped due to cache hits.
- **FR-013**: The system MUST support finalizing a previously created dry-run by run identifier.
- **FR-014**: The system MUST ensure dry-run finalization is only allowed when the relevant inputs and configuration are unchanged since the dry-run; otherwise it MUST fail with a clear explanation.
  - Run fingerprint MUST be computed as a combined fingerprint of all input file fingerprints plus configuration state (output type, source/target paths, ignore rules content).
  - Fingerprint validation MUST compare the current run fingerprint against the stored fingerprint from the dry-run or interrupted run.
  - The explanation MUST specify what changed (e.g., "Source file X modified", "Configuration file changed", "Run Y deleted") and suggest remediation (e.g., "Create a new dry-run to proceed").
- **FR-015**: The system MUST provide clear prerequisite validation and error messages for missing required tooling, and MUST still allow `--help`/usage output even if generation prerequisites are not installed.
  - Error messages MUST be clear, readable as plain text, and include actionable recovery guidance.
  - Error messages MUST specify which prerequisite is missing and suggest installation commands when applicable.
- **FR-016**: The system MUST provide safe handling for destructive operations (e.g., deleting outputs or clearing cached state) by requiring explicit user confirmation.
  - The `--clean <RUN_ID> [RUN_ID...]` command MUST remove outputs for one or more specified run IDs and MUST require confirmation before deletion.
  - The `--drop` command MUST clear all cache/state and MUST require confirmation before deletion.
  - Both `--clean` and `--drop` MUST warn the user if fingerprint validation fails or if output paths contain non-pndcgn artifacts before proceeding with deletion.
  - Confirmation mechanism MUST use interactive prompts (y/yes/n/no) when stdin is a TTY, or require `--yes` flag when non-interactive.
  - Confirmation prompts MUST clearly describe what will be deleted and the impact of the operation.
- **FR-017**: All user-facing names and help text MUST consistently use the product name **pndcgn**.
- **FR-018**: The system MUST use globally unique, lexicographically sortable run identifiers so that runs can be naturally ordered by creation time.
  - The system SHOULD use the `sqlite-ulid` extension's `ulid()` function for ULID generation when available.
  - If the `sqlite-ulid` extension cannot be downloaded, installed, or loaded, the system MUST fall back to an alternative ULID generation method (e.g., Bash-based implementation) to ensure the tool remains functional.
  - The fallback method MUST produce ULIDs with the same format and properties (26 characters, lexicographically sortable, timestamp-embedded) as the extension-based method.
- **FR-019**: The system MUST handle all error conditions and edge cases with explicit error messages written to stderr, appropriate exit codes (0=success, 1=runtime error, 2=invalid usage), and actionable recovery guidance when applicable.
  - Error messages MUST include: error type prefix (e.g., "ERROR:", "WARN:"), context (file/path/run ID), and actionable suggestion.
  - Error messages MUST be readable as plain text (color codes are enhancement, not requirement).
  - Recovery guidance MUST suggest specific steps the user can take to resolve the issue.

### 4.2. Key Entities *(include if feature involves data)*

- **Run**: A single execution instance with a unique identifier, configuration (source/target/type), status, and summary statistics.
- **Run Output Set**: The collection of artifacts produced by a run (generated documents plus index/navigation artifact).
- **Input Source**: A file or directory contributing content to outputs (including any referenced/embedded content).
- **Fingerprint**: A reproducible representation of the relevant input state used to decide whether outputs can be reused.
  - Format: `{size}:{mtime}:{sha256_first_64KB}` where size is in bytes, mtime is Unix timestamp, and sha256_first_64KB is SHA256 hash of the first 64KB of file content.
  - This format enables O(1) fingerprint computation (only first 64KB hashed) while maintaining sufficient accuracy for change detection.
- **Cache Entry**: A record linking an input fingerprint (and output type) to an existing generated output.

## 5. Success Criteria *(mandatory)*

### 5.1. Measurable Outcomes

- **SC-001**: For a representative project, a repeat run with no input changes completes at least **5× faster** than the initial run and reports skipped vs processed items.
  - **Representative project definition**: A project containing at least 50 markdown/text documentation files across multiple nested directories (e.g., docs/, guides/, api-docs/), with a mix of file sizes (ranging from small <1KB to medium-sized files <100KB), representing a typical documentation structure. The project should include common documentation assets (images, diagrams) that would be referenced by the documentation files.
- **SC-002**: **100%** of dry-run finalizations with unchanged inputs succeed and produce outputs matching the dry-run plan.
- **SC-003**: **100%** of dry-run finalizations with changed inputs fail safely and produce an actionable explanation of the mismatch.
- **SC-004**: In usability testing with a new user, at least **90%** can locate and open a specific generated document using the run index in under **60 seconds**.

## 6. Assumptions

- Users run the tool locally against a directory they can read, and write outputs to a directory they have permission to modify.
- The primary supported use case is converting documentation sources into a navigable output set for sharing and review.
- Output formats beyond PDF are supported conceptually; exact formatting differences are treated as output-type variations rather than separate products.

## 7. Out of Scope

- Implementing new document conversion engines beyond the tool’s existing conversion pipeline.
- Adding remote storage/upload features (outputs are produced on the local filesystem).

---

## 8. Non-Functional Requirements *(phased delivery)*

Requirements are tagged with delivery phase:

- **[P1-MVP]**: Critical - Core reliability, crash safety, data integrity
- **[P2]**: High - Common edge cases, error handling, UX
- **[P3]**: Medium - Polish, edge cases, robustness
- **[P4+]**: Low - Nice-to-have, future enhancements

### 8.1. NFR-SEC: Security Requirements

#### 8.1.1. File System Security

- **NFR-SEC-001** [P2]: The system MUST validate that source directory is readable before processing.
- **NFR-SEC-002** [P2]: The system MUST validate that target directory is writable before processing.
- **NFR-SEC-003** [P2]: The system MUST normalize paths to prevent directory traversal attacks (resolve `..`, `.`, symlinks).
- **NFR-SEC-004** [P2]: The system MUST validate that resolved paths are within allowed source/target directories.
- **NFR-SEC-005** [P2]: The system MUST handle paths with special characters safely (no shell injection).

#### 8.1.2. Input Validation Security

- **NFR-SEC-006** [P2]: The system MUST validate run identifier format (ULID: 26 characters, alphanumeric).
- **NFR-SEC-007** [P2]: The system MUST use parameterized SQL queries to prevent SQL injection.
- **NFR-SEC-008** [P2]: The system MUST sanitize all user inputs before use in file operations.

#### 8.1.3. State Management Security

- **NFR-SEC-009** [P2]: SQLite database file MUST be created with permissions 0600 (user read/write only).
- **NFR-SEC-010** [P2]: Database MUST be stored in XDG-compliant state directory (user-owned, not world-readable).
- **NFR-SEC-011** [P2]: Database access MUST be restricted to the user who created it (permissions enforcement).

#### 8.1.4. Configuration Security

- **NFR-SEC-012** [P2]: Auto-created `.pndcgnignore` file MUST use safe default permissions (user read/write).
- **NFR-SEC-013** [P2]: Ignore pattern parsing MUST prevent malicious patterns that could cause denial of service.
- **NFR-SEC-014** [P2]: Configuration file validation MUST reject malformed patterns gracefully (log warning, use defaults).

#### 8.1.5. Destructive Operations Security

- **NFR-SEC-015** [P2]: All destructive operations MUST require explicit user confirmation (interactive prompt or `--yes` flag).
- **NFR-SEC-016** [P2]: Destructive operations MUST validate fingerprint before deletion to prevent accidental data loss.
- **NFR-SEC-017** [P2]: Destructive operations MUST warn if output paths contain non-pndcgn artifacts.

#### 8.1.6. Data Privacy

- **NFR-SEC-018** [P2]: Database MUST NOT store sensitive file contents (only fingerprints and metadata).
- **NFR-SEC-019** [P2]: Run identifiers (ULIDs) MUST NOT contain sensitive information (timestamp-embedded, no user data).
- **NFR-SEC-020** [P2]: Fingerprints MUST NOT reveal full file contents (only first 64KB hash).
- **NFR-SEC-021** [P2]: Source paths stored in database MAY reveal directory structure (user-controlled, not sensitive by default).

#### 8.1.7. Logging & Information Disclosure Security

- **NFR-SEC-022** [P2]: Error messages MUST NOT include sensitive file contents or credentials.
- **NFR-SEC-023** [P2]: Verbose/debug logging MUST be opt-in and MUST NOT log sensitive data by default.
- **NFR-SEC-024** [P2]: Console output MUST NOT expose sensitive information (paths are acceptable, file contents are not).
- **NFR-SEC-025** [P2]: Log files (if any) MUST be stored with safe permissions (user read/write only).

#### 8.1.8. Threat Model Coverage

- **NFR-SEC-026** [P2]: The system MUST prevent path traversal attacks via path normalization and validation.
- **NFR-SEC-027** [P2]: The system MUST handle symlink attacks safely (follow symlinks, detect circular references).
- **NFR-SEC-028** [P2]: The system MUST prevent SQL injection via parameterized queries.
- **NFR-SEC-029** [P2]: The system MUST prevent command injection via safe path handling and input validation.
- **NFR-SEC-030** [P2]: The system MUST handle file system race conditions (TOCTOU) via atomic operations where possible.

### 8.2. NFR-CLI: CLI User Experience

#### 8.2.1. Accessibility

- **NFR-CLI-ACCESS-001** [P2]: The CLI interface MUST be keyboard-only accessible (no mouse/touch dependencies).
- **NFR-CLI-ACCESS-002** [P2]: All CLI output MUST be text-based (no binary-only output formats).
- **NFR-CLI-ACCESS-003** [P2]: Error messages MUST be readable as plain text without color codes (color is enhancement, not requirement).
- **NFR-CLI-ACCESS-004** [P2]: Help text MUST be readable as plain text and accessible via `--help` flag.
- **NFR-CLI-ACCESS-005** [P2]: Progress indicators MUST provide text-based status updates in addition to visual animations.

#### 8.2.2. Help & Version Output

- **NFR-CLI-001** [P2]: The system MUST provide `--help` output with structured sections: synopsis, description, options, examples, exit codes.
- **NFR-CLI-002** [P2]: The system MUST provide `--version` output displaying the current version number.
- **NFR-CLI-003** [P2]: Help text MUST show default values for all options.
- **NFR-CLI-004** [P2]: Help text MUST include usage examples demonstrating common workflows.
- **NFR-CLI-005** [P2]: Help text MUST list supported output types.
- **NFR-CLI-006** [P2]: Help text MUST mention configuration file locations (TOML and .pndcgnignore).
- **NFR-CLI-007** [P2]: Help text MUST describe exit codes (0, 1, 2).
- **NFR-CLI-008** [P3]: Help text SHOULD group related flags logically.
- **NFR-CLI-009** [P4+]: Man page documentation MAY be provided for extended help.

#### 8.2.3. Output Modes

- **NFR-CLI-010** [P3]: The system SHOULD support `--quiet` mode that suppresses non-error output.
- **NFR-CLI-011** [P2]: The system MUST support `--verbose` mode that provides detailed progress information.
- **NFR-CLI-012** [P3]: The system MAY support stdin/pipe input for scripting scenarios.

#### 8.2.4. Terminal Behavior

- **NFR-CLI-013** [P1-MVP]: When stdout is not a TTY (piped/redirected), the system MUST disable interactive features (spinners, colors, prompts) and output machine-parseable text.
- **NFR-CLI-014** [P1-MVP]: The system MUST support the `NO_COLOR` environment variable to disable color output per the no-color.org standard.
- **NFR-CLI-015** [P2]: The system MUST use ANSI color codes for visual distinction (errors=red, warnings=yellow, success=green, info=default).
- **NFR-CLI-016** [P3]: The system SHOULD handle `TERM` environment variable to detect terminal capabilities.
- **NFR-CLI-017** [P3]: The system SHOULD wrap long paths/names appropriately for narrow terminals.
- **NFR-CLI-018** [P4+]: The system MAY support screen reader compatibility via structured output.
- **NFR-CLI-019** [P4+]: Color choices SHOULD be colorblind-friendly (avoid red/green only distinctions).

#### 8.2.5. Run ID Display

- **NFR-CLI-020** [P2]: Run IDs MUST be displayed in a copy-paste friendly format (single line, no surrounding punctuation).
- **NFR-CLI-021** [P2]: When a run ID is needed for subsequent commands (dry-run, resume), the system MUST clearly indicate how to use it.

#### 8.2.6. Timing & Duration

- **NFR-CLI-022** [P2]: Duration output MUST use human-readable format: milliseconds for <1s, seconds with 1 decimal for <60s, minutes:seconds for longer.
- **NFR-CLI-023** [P3]: Byte sizes MUST use human-readable format (KB, MB, GB) with appropriate precision.

#### 8.2.7. Confirmation Prompts

- **NFR-CLI-024** [P2]: Confirmation prompts MUST accept: y, yes, Y, YES (affirmative) and n, no, N, NO (negative).
- **NFR-CLI-025** [P2]: Invalid confirmation responses MUST re-prompt (up to 3 times) then abort with exit code 2.
- **NFR-CLI-026** [P2]: The system SHOULD support `--yes` flag to bypass confirmation prompts for automation.
- **NFR-CLI-027** [P1-MVP]: When stdin is not a TTY, destructive operations MUST require `--yes` flag or fail with exit code 2.
- **NFR-CLI-028** [P3]: Confirmation prompts SHOULD NOT have a timeout (wait indefinitely for user input).

#### 8.2.8. Progress Reporting

- **NFR-CLI-029** [P3]: Progress indicators SHOULD use spinner animation for indeterminate progress.
- **NFR-CLI-030** [P3]: Progress SHOULD display file count format: `Processing: X/Y files (Z%)`.
- **NFR-CLI-031** [P3]: Progress update frequency SHOULD be at least once per second during active processing.
- **NFR-CLI-032** [P3]: Progress during cache lookup SHOULD indicate "Checking cache..." phase.
- **NFR-CLI-033** [P4+]: ETA display MAY be provided for long-running operations.

#### 8.2.9. Final Summary Output

- **NFR-CLI-034** [P2]: Final summary MUST include: total files, processed, skipped, failed, duration, cache hit rate.
- **NFR-CLI-035** [P3]: Statistics output MUST use consistent column alignment.
- **NFR-CLI-036** [P3]: Cache statistics MUST show hits, misses, and efficiency percentage.

#### 8.2.10. Error Messages

- **NFR-CLI-037** [P2]: Error messages MUST include: error type prefix, context (file/path), actionable suggestion.
- **NFR-CLI-038** [P2]: Error messages for invalid run IDs MUST indicate correct format.
- **NFR-CLI-039** [P2]: Error messages for non-existent run IDs MUST suggest listing available runs.
- **NFR-CLI-040** [P3]: Debug information SHOULD be available via `--verbose` or environment variable.
- **NFR-CLI-041** [P4+]: Localization/i18n for error messages is out of scope for initial release.

#### 8.2.11. fzf Integration

- **NFR-CLI-042** [P3]: fzf interface SHOULD display directories sorted alphabetically.
- **NFR-CLI-043** [P3]: fzf SHOULD traverse up to 3 levels deep by default.
- **NFR-CLI-044** [P3]: fzf SHOULD exclude hidden directories (starting with `.`).
- **NFR-CLI-045** [P3]: fzf cancellation (Ctrl+C, Esc) MUST fall back to current working directory.
- **NFR-CLI-046** [P3]: fzf result SHOULD display relative path from current directory.
- **NFR-CLI-047** [P4+]: fzf keybindings and preview options are implementation details.

#### 8.2.12. Keyboard Interrupt

- **NFR-CLI-048** [P1-MVP]: Ctrl+C (SIGINT) MUST trigger graceful shutdown: stop processing, save checkpoint, report partial progress.
- **NFR-CLI-049** [P2]: Interrupted state MUST be clearly communicated with instructions for resuming.

### 8.3. NFR-CACHE: Caching & State Management

#### 8.3.1. Fingerprint Computation

- **NFR-CACHE-001** [P1-MVP]: Files smaller than 64KB MUST hash the entire file content.
- **NFR-CACHE-002** [P1-MVP]: Empty files (0 bytes) MUST have fingerprint format `0:{mtime}:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (SHA256 of empty string).
- **NFR-CACHE-003** [P1-MVP]: mtime precision MUST be seconds (Unix timestamp, integer).
- **NFR-CACHE-004** [P3]: mtime MUST be captured in UTC (no timezone conversion).
- **NFR-CACHE-005** [P2]: SHA256 implementation MUST use `shasum -a 256` or `openssl dgst -sha256` (whichever available).
- **NFR-CACHE-006** [P3]: Fingerprint delimiter (colon) is safe since size/mtime are numeric and hash is hex.
- **NFR-CACHE-007** [P1-MVP]: Input file fingerprints in combined run fingerprint MUST be sorted by relative path (lexicographic, case-sensitive).
- **NFR-CACHE-008** [P1-MVP]: Output artifacts in combined hash MUST be sorted by relative path (lexicographic, case-sensitive).
- **NFR-CACHE-009** [P2]: TOML config file content MUST be included in run fingerprint for change detection.
- **NFR-CACHE-010** [P3]: Fingerprint format version SHOULD be embedded (e.g., `v1:{size}:{mtime}:{hash}`) for future migration.

#### 8.3.2. Cache Behavior

- **NFR-CACHE-011** [P2]: When source file is deleted, corresponding cache entries MUST be invalidated on next run.
- **NFR-CACHE-012** [P2]: When source file is renamed, it MUST be treated as delete + create (old cache invalid, new cache miss).
- **NFR-CACHE-013** [P2]: When source file is moved, it MUST be treated as delete + create.
- **NFR-CACHE-014** [P2]: When output type changes for same source, cache lookup MUST miss (cache keyed by source+type).
- **NFR-CACHE-015** [P3]: Cache entry expiration/TTL is NOT required (entries valid until invalidated).
- **NFR-CACHE-016** [P3]: Cache size limit is NOT required (no automatic eviction).
- **NFR-CACHE-017** [P4+]: Cache warming/preloading is out of scope.
- **NFR-CACHE-018** [P3]: Cascading invalidation for dependencies is NOT supported (each file independent).
- **NFR-CACHE-019** [P3]: Partial cache invalidation (single entry) SHOULD be supported via internal API.

#### 8.3.3. Database State

- **NFR-CACHE-020** [P2]: Database schema version MUST be stored in a metadata table.
- **NFR-CACHE-021** [P2]: Schema migrations MUST be applied automatically on startup if version mismatch detected.
- **NFR-CACHE-022** [P1-MVP]: Database file MUST be created with permissions 0600 (user read/write only).
- **NFR-CACHE-023** [P1-MVP]: If database file is corrupted (SQLite integrity check fails), the system MUST log error, rename corrupted file with `.corrupted.{timestamp}` suffix, and create fresh database.
- **NFR-CACHE-024** [P3]: Database backup/recovery is NOT automatically provided (user responsibility).
- **NFR-CACHE-025** [P3]: Database connection pooling is NOT required (single connection per process).
- **NFR-CACHE-026** [P3]: Database transactions SHOULD wrap entire file processing (commit on success, rollback on failure).
- **NFR-CACHE-027** [P2]: Run timestamps MUST be stored as Unix timestamps (integer seconds).
- **NFR-CACHE-028** [P2]: Run duration MUST be calculated as (end_timestamp - start_timestamp) in seconds.

#### 8.3.4. Run State Machine

- **NFR-CACHE-029** [P1-MVP]: Run status transitions MUST follow: `created` → `running` → (`complete` | `failed` | `interrupted`).
- **NFR-CACHE-030** [P1-MVP]: Dry-run status MUST be `dry-run` (distinct from `created`).
- **NFR-CACHE-031** [P1-MVP]: On startup, if any run has status `running` from a previous session, it MUST be marked `interrupted`.
- **NFR-CACHE-032** [P1-MVP]: Checkpoint corruption (unreadable/invalid JSON) MUST mark run as `failed` and log error.

#### 8.3.5. Resume Behavior

- **NFR-CACHE-033** [P2]: Resuming a `complete` run MUST fail with error "Run already complete".
- **NFR-CACHE-034** [P2]: Resuming a `failed` run MUST fail with error "Run failed; start new run instead".
- **NFR-CACHE-035** [P2]: Resuming a `dry-run` MUST fail with error "Cannot resume dry-run; use --finalize instead".
- **NFR-CACHE-036** [P2]: Resume with deleted source files MUST skip those files and log warning.
- **NFR-CACHE-037** [P2]: Resume with added source files MUST process new files in addition to remaining files.
- **NFR-CACHE-038** [P2]: Resume with changed config MUST fail fingerprint validation and require new run.
- **NFR-CACHE-039** [P2]: Resume with changed output type MUST fail fingerprint validation.
- **NFR-CACHE-040** [P2]: Partial progress display on resume MUST show "Resuming from X/Y files".

#### 8.3.6. Dry-Run/Finalize

- **NFR-CACHE-041** [P2]: Dry-runs SHOULD NOT expire (valid until source changes).
- **NFR-CACHE-042** [P2]: Multiple pending dry-runs MUST be allowed (each with unique ID).
- **NFR-CACHE-043** [P2]: Finalizing already-finalized run MUST fail with error "Run already finalized".
- **NFR-CACHE-044** [P2]: Finalizing non-existent run ID MUST fail with error "Run not found: {ID}".
- **NFR-CACHE-045** [P2]: Config changes between dry-run and finalize MUST fail fingerprint validation.

#### 8.3.7. ULID Generation

- **NFR-CACHE-046** [P2]: sqlite-ulid extension version SHOULD be 0.2.1 or compatible.
- **NFR-CACHE-047** [P3]: Bash fallback ULID MUST use `/dev/urandom` for randomness.
- **NFR-CACHE-048** [P3]: ULID generation rate limiting is NOT required (collisions statistically impossible).
- **NFR-CACHE-049** [P3]: ULID collision handling is NOT required (rely on statistical uniqueness).

#### 8.3.8. Cache Metrics

- **NFR-CACHE-050** [P3]: Cache statistics MUST display: "Cache: X hits, Y misses (Z% efficiency)".
- **NFR-CACHE-051** [P4+]: Historical cache metrics are out of scope.
- **NFR-CACHE-052** [P3]: Cache efficiency threshold for success criteria is informational only (no hard requirement).

#### 8.3.9. Cleanup Operations

- **NFR-CACHE-053** [P2]: Cleaning non-existent run ID MUST fail with error "Run not found: {ID}" and exit code 1.
- **NFR-CACHE-054** [P3]: Partial cleanup failure (some runs fail) MUST report each failure and continue with remaining.
- **NFR-CACHE-055** [P3]: Cleanup confirmation MUST show: "Delete run {ID} ({N} files, {size})? [y/N]".
- **NFR-CACHE-056** [P3]: Cleanup progress SHOULD show "Deleting: X/Y runs".
- **NFR-CACHE-057** [P3]: Cleanup interruption MUST leave remaining runs intact (atomic per-run deletion).
- **NFR-CACHE-058** [P4+]: Cleanup audit trail/logging is out of scope.
- **NFR-CACHE-059** [P3]: Orphaned cache entries (output missing) SHOULD be cleaned during normal runs.

### 8.4. NFR-EDGE: Extended Edge Cases

#### 8.4.1. Source Directory

- **NFR-EDGE-001** [P2]: Empty source directory (no files) MUST produce empty run with warning "No files matched include patterns".
- **NFR-EDGE-002** [P2]: Source directory with only ignored files MUST produce empty run with same warning.
- **NFR-EDGE-003** [P2]: SOURCE_DIR argument that is a file (not directory) MUST fail with error "Not a directory: {path}" and exit code 2.
- **NFR-EDGE-004** [P3]: Trailing slashes on source path MUST be normalized (removed).
- **NFR-EDGE-005** [P2]: Source paths with spaces MUST be handled correctly (quote in shell, no special handling in tool).
- **NFR-EDGE-006** [P3]: Source paths with special characters (unicode, etc.) MUST be handled correctly.
- **NFR-EDGE-007** [P2]: Symbolic links in source directory MUST be followed (resolve to target).
- **NFR-EDGE-008** [P2]: Broken symbolic links MUST be skipped with warning "Broken symlink: {path}".
- **NFR-EDGE-009** [P2]: Circular symbolic links MUST be detected and skipped with warning "Circular symlink detected: {path}".
- **NFR-EDGE-010** [P3]: Network-mounted source directories MUST work (no special handling, may be slower).
- **NFR-EDGE-011** [P3]: Read-only source filesystem MUST work (only reads, no writes to source).

#### 8.4.2. Target Directory

- **NFR-EDGE-012** [P2]: Non-existent target directory MUST be created automatically (including parent directories).
- **NFR-EDGE-013** [P2]: Target directory creation failure MUST report error with specific reason (permissions, disk full).
- **NFR-EDGE-014** [P2]: Target paths with spaces MUST be handled correctly.
- **NFR-EDGE-015** [P2]: Target directory same as source MUST be allowed (outputs go to `.pndcgn/` subdirectory).
- **NFR-EDGE-016** [P2]: Target directory inside source MUST be allowed (but outputs auto-ignored via `.pndcgn` pattern).
- **NFR-EDGE-017** [P3]: Target on different filesystem MUST work (no special handling).
- **NFR-EDGE-018** [P1-MVP]: Disk full during output write MUST fail gracefully, mark run as `failed`, and report space needed.
- **NFR-EDGE-019** [P2]: Existing `.pndcgn` directory with conflicts MUST NOT be modified; new runs create new subdirectories.

#### 8.4.3. Input Files

- **NFR-EDGE-020** [P2]: Empty input files (0 bytes) MUST be processed (may produce empty/minimal output).
- **NFR-EDGE-021** [P2]: Binary files matching include patterns MUST be skipped with warning "Binary file skipped: {path}".
- **NFR-EDGE-022** [P3]: Very large files (>100MB) SHOULD trigger warning "Large file may slow processing: {path}".
- **NFR-EDGE-023** [P2]: Files with no read permission MUST be skipped with warning "Permission denied: {path}".
- **NFR-EDGE-024** [P1-MVP]: Files that change during processing MUST be detected via fingerprint mismatch at write time; if changed, skip and warn.
- **NFR-EDGE-025** [P3]: Files with unusual encodings MUST be passed to pandoc as-is (pandoc handles encoding).
- **NFR-EDGE-026** [P3]: Files with BOM markers MUST be handled (pass to pandoc as-is).
- **NFR-EDGE-027** [P3]: Files with no extension MUST be processed if they match include patterns.
- **NFR-EDGE-028** [P3]: Hidden files (dot-files) MUST be processed if they match include patterns and not excluded.
- **NFR-EDGE-029** [P3]: Files with very long names (>255 chars) MUST fail with clear error if filesystem rejects.
- **NFR-EDGE-030** [P3]: Files with newlines in names MUST be handled correctly (rare but valid on some filesystems).
- **NFR-EDGE-031** [P3]: Maximum path length MUST respect OS limits (PATH_MAX); fail with clear error if exceeded.

#### 8.4.4. Output Type

- **NFR-EDGE-032** [P2]: Output type matching MUST be case-insensitive (PDF, pdf, Pdf all valid).
- **NFR-EDGE-033** [P2]: Output types requiring external tools (e.g., pdflatex for PDF) MUST check prerequisites and report missing tools.

#### 8.4.5. Concurrent Operations

- **NFR-EDGE-034** [P2]: Two concurrent runs processing the same source file MUST both succeed (no file locking on source).
- **NFR-EDGE-035** [P2]: Concurrent runs with different output types MUST work independently.
- **NFR-EDGE-036** [P2]: Database locking timeout MUST be 30 seconds; if exceeded, fail with "Database busy, retry later".
- **NFR-EDGE-037** [P2]: Database lock acquisition failure MUST fail with clear error (not hang indefinitely).
- **NFR-EDGE-038** [P3]: Concurrent cleanup operations MUST be serialized via database locking.
- **NFR-EDGE-039** [P3]: Concurrent resume operations on same run MUST fail second attempt with "Run already being processed".
- **NFR-EDGE-040** [P2]: Concurrent runs MUST NOT create conflicting output directories (ULID uniqueness guarantees this).

#### 8.4.6. Signal Handling

- **NFR-EDGE-041** [P1-MVP]: SIGINT (Ctrl+C) MUST trigger graceful shutdown: finish current file, checkpoint, mark interrupted.
- **NFR-EDGE-042** [P1-MVP]: SIGTERM MUST trigger same graceful shutdown as SIGINT.
- **NFR-EDGE-043** [P1-MVP]: SIGKILL cannot be caught; database WAL ensures consistency on recovery.
- **NFR-EDGE-044** [P2]: SIGHUP MUST be ignored (allow terminal disconnect without stopping).
- **NFR-EDGE-045** [P1-MVP]: Trap handlers MUST be installed for INT, TERM signals on startup.
- **NFR-EDGE-046** [P1-MVP]: Interrupt during database write MUST NOT corrupt database (SQLite WAL handles this).
- **NFR-EDGE-047** [P1-MVP]: Interrupt during file write MUST leave partial file (cleaned up on resume/next run).
- **NFR-EDGE-048** [P1-MVP]: Database state after unexpected termination MUST be recoverable (WAL replay).
- **NFR-EDGE-049** [P2]: Partial outputs on interruption MUST be tracked and re-processed on resume.

#### 8.4.7. Resume Edge Cases

- **NFR-EDGE-050** [P2]: Resume run ID that doesn't exist MUST fail with "Run not found: {ID}".
- **NFR-EDGE-051** [P2]: Resume with partial outputs corrupted MUST re-process those files.

#### 8.4.8. Finalize Edge Cases

- **NFR-EDGE-052** [P2]: Finalize with source permissions changed MUST fail fingerprint validation.
- **NFR-EDGE-053** [P2]: Finalize with target unavailable MUST fail with clear error.

#### 8.4.9. External Dependencies

- **NFR-EDGE-054** [P2]: sqlite3 not installed MUST fail with clear error "sqlite3 required but not found".
- **NFR-EDGE-055** [P2]: curl not available for extension download MUST fall back to Bash ULID silently.
- **NFR-EDGE-056** [P2]: Pandoc crash during conversion MUST fail that file, continue with others, mark run partial.
- **NFR-EDGE-057** [P2]: Pandoc invalid output MUST fail that file with warning, continue with others.
- **NFR-EDGE-058** [P3]: Pandoc version incompatibility SHOULD be detected and warned (not enforced).
- **NFR-EDGE-059** [P2]: Missing LaTeX packages for PDF MUST fail with pandoc's error message (pass through).
- **NFR-EDGE-060** [P2]: Network unavailable during extension download MUST fall back to Bash ULID.

#### 8.4.10. Configuration Edge Cases

- **NFR-EDGE-061** [P2]: Malformed .pndcgnignore MUST log warning and treat as empty (include all).
- **NFR-EDGE-062** [P2]: Conflicting ignore patterns MUST apply last-match-wins (gitignore semantics).
- **NFR-EDGE-063** [P2]: Unreadable config file MUST log warning and use defaults.
- **NFR-EDGE-064** [P2]: Invalid XDG_CONFIG_HOME MUST fall back to `~/.config`.
- **NFR-EDGE-065** [P3]: Circular include patterns (impossible with glob) are not applicable.
- **NFR-EDGE-066** [P3]: Overly permissive patterns (match everything) MUST work (user's choice).
- **NFR-EDGE-067** [P3]: Overly restrictive patterns (match nothing) MUST produce empty run with warning.

#### 8.4.11. Cleanup Edge Cases

- **NFR-EDGE-068** [P2]: --clean targeting active run MUST fail with "Run in progress, cannot clean".
- **NFR-EDGE-069** [P2]: --drop failure midway MUST report what was deleted and what failed.
- **NFR-EDGE-070** [P2]: Database deletion failure MUST report error and continue with filesystem cleanup.
- **NFR-EDGE-071** [P2]: Filesystem deletion failure MUST report error with path and reason.
- **NFR-EDGE-072** [P2]: Cleanup with insufficient permissions MUST fail with clear permission error.

#### 8.4.12. Resource Exhaustion

- **NFR-EDGE-073** [P1-MVP]: Memory exhaustion MUST fail gracefully (Bash will report error).
- **NFR-EDGE-074** [P1-MVP]: Disk full MUST fail with "No space left on device" and exit code 1.
- **NFR-EDGE-075** [P3]: File descriptor limit MUST fail with clear error if reached.
- **NFR-EDGE-076** [P3]: Processing thousands of files MUST work (no artificial limits); performance may degrade.
- **NFR-EDGE-077** [P3]: Maximum supported file count is limited only by filesystem and memory.
- **NFR-EDGE-078** [P3]: Maximum supported total size is limited only by disk space.
- **NFR-EDGE-079** [P3]: Timeout for long-running operations is NOT enforced (user can interrupt).
- **NFR-EDGE-080** [P3]: Graceful degradation under resource pressure relies on OS behavior.

### 8.5. NFR-TOML: TOML Configuration

#### 8.5.1. File Discovery

- **NFR-TOML-001** [P2]: Config file symlinks MUST be followed (resolve to target).
- **NFR-TOML-002** [P2]: XDG_CONFIG_HOME with spaces MUST be handled correctly.
- **NFR-TOML-003** [P2]: Config path with special characters MUST be handled correctly.
- **NFR-TOML-004** [P2]: Config file permissions SHOULD be readable by user (no enforcement).
- **NFR-TOML-005** [P2]: Config file that is a directory MUST fail with "Config path is directory: {path}".
- **NFR-TOML-006** [P1-MVP]: Config file content MUST be included in run fingerprint.

#### 8.5.2. Pattern Syntax

- **NFR-TOML-007** [P2]: Glob patterns MUST support `*` (any characters except `/`) and `**` (any characters including `/`).
- **NFR-TOML-008** [P2]: Glob patterns MUST support `?` (single character except `/`).
- **NFR-TOML-009** [P2]: Glob patterns MUST support character classes `[abc]` and `[a-z]`.
- **NFR-TOML-010** [P2]: Glob patterns MUST support negation in character classes `[!abc]`.
- **NFR-TOML-011** [P3]: Glob patterns SHOULD support brace expansion `{a,b,c}`.
- **NFR-TOML-012** [P2]: Patterns MUST be relative to source directory root (no leading `/` interpretation).
- **NFR-TOML-013** [P2]: Patterns starting with `/` MUST be treated as relative (strip leading `/`).
- **NFR-TOML-014** [P2]: Patterns ending with `/` MUST match directories only.
- **NFR-TOML-015** [P2]: Pattern matching MUST be case-sensitive (Unix filesystem default).
- **NFR-TOML-016** [P3]: Escaping special characters MUST use backslash (e.g., `\*` matches literal `*`).

#### 8.5.3. Extension Syntax

- **NFR-TOML-017** [P2]: Extension matching MUST be case-insensitive (md, MD, Md all match).
- **NFR-TOML-018** [P2]: Compound extensions (`.tar.gz`) MUST match full compound (extension = `tar.gz`).
- **NFR-TOML-019** [P3]: Empty extension string MUST be ignored with warning.
- **NFR-TOML-020** [P3]: Extension with spaces MUST be ignored with warning.
- **NFR-TOML-021** [P3]: Maximum extension length is NOT enforced.
- **NFR-TOML-022** [P3]: Numeric-only extensions MUST be allowed (e.g., `1`, `123`).

#### 8.5.4. TOML Parsing

- **NFR-TOML-023** [P2]: Multi-line arrays MUST be supported per TOML 1.0.
- **NFR-TOML-024** [P2]: Inline arrays MUST be supported per TOML 1.0.
- **NFR-TOML-025** [P2]: Quoted strings in arrays MUST be supported (single and double quotes).
- **NFR-TOML-026** [P3]: Escape sequences in strings MUST be supported per TOML 1.0.
- **NFR-TOML-027** [P2]: Comments (`#`) MUST be ignored per TOML 1.0.
- **NFR-TOML-028** [P3]: Trailing commas in arrays are NOT valid TOML; parser will reject.
- **NFR-TOML-029** [P3]: Whitespace handling MUST follow TOML 1.0 (trim around `=`).
- **NFR-TOML-030** [P2]: Duplicate keys MUST use last value (TOML 1.0 allows this).
- **NFR-TOML-031** [P3]: Nested tables beyond `[include.types]` are ignored (forward compatibility).
- **NFR-TOML-032** [P3]: Array of tables syntax is NOT used; ignore if present.

#### 8.5.5. Error Handling

- **NFR-TOML-033** [P2]: Parse error warnings MUST include line number: "Config warning: {file}:{line}: {message}".
- **NFR-TOML-034** [P2]: Syntax errors in patterns MUST be warned and pattern skipped.
- **NFR-TOML-035** [P2]: Unreadable config file error MUST include permission details.
- **NFR-TOML-036** [P3]: Binary content in config file MUST be detected and treated as malformed.
- **NFR-TOML-037** [P3]: Non-UTF8 encoding MUST be warned and file treated as malformed.

#### 8.5.6. Validation

- **NFR-TOML-038** [P3]: Validation error format MUST be: "Invalid pattern '{pattern}': {reason}".
- **NFR-TOML-039** [P3]: Patterns matching nothing MUST produce warning (not error).
- **NFR-TOML-040** [P3]: Patterns matching everything MUST be allowed (user's choice).
- **NFR-TOML-041** [P3]: Validation against actual filesystem is NOT performed (patterns are evaluated at runtime).
- **NFR-TOML-042** [P3]: Path traversal (`../`) in patterns MUST be rejected with error.
- **NFR-TOML-043** [P2]: Absolute paths in patterns MUST be rejected with error.

#### 8.5.7. Pattern Precedence

- **NFR-TOML-044** [P1-MVP]: Evaluation order MUST be: include patterns first, then exclude patterns (.pndcgnignore).
- **NFR-TOML-045** [P1-MVP]: Include patterns and .pndcgnignore interact as: file must match include AND not match exclude.
- **NFR-TOML-046** [P2]: Within pattern array, all patterns are OR'd (match any).
- **NFR-TOML-047** [P3]: Overlapping patterns are allowed (first match or any match, same result).
- **NFR-TOML-047A** [P1-MVP]: For default configuration, patterns and extensions use OR logic: file is included if it matches ANY pattern OR ANY extension.
- **NFR-TOML-047B** [P1-MVP]: For user-provided TOML config, if both patterns and extensions are specified, patterns take precedence (extensions ignored).

#### 8.5.8. Integration

- **NFR-TOML-048** [P1-MVP]: Config changes between dry-run and finalize MUST fail fingerprint validation.
- **NFR-TOML-049** [P1-MVP]: Config changes during resume MUST fail fingerprint validation.
- **NFR-TOML-050** [P3]: --type option does NOT interact with config (config is for file discovery only).
- **NFR-TOML-051** [P3]: Config change detection uses content hash, not mtime.

#### 8.5.9. Edge Cases

- **NFR-TOML-052** [P3]: Config file larger than 1MB MUST be rejected with warning (likely error).
- **NFR-TOML-053** [P2]: Unset HOME environment variable MUST fail with "HOME not set".
- **NFR-TOML-054** [P2]: XDG_CONFIG_HOME pointing to non-existent path MUST skip (fall back to source dir).
- **NFR-TOML-055** [P3]: Config with only comments MUST be treated as empty (use defaults).
- **NFR-TOML-056** [P3]: Config with only whitespace MUST be treated as empty (use defaults).
- **NFR-TOML-057** [P3]: Pattern recursion depth (via `**`) is limited by filesystem depth.
- **NFR-TOML-058** [P3]: Unicode in patterns MUST be supported (UTF-8).
- **NFR-TOML-059** [P3]: Unicode in extensions MUST be supported (UTF-8).

#### 8.5.10. Documentation

- **NFR-TOML-060** [P3]: Default pattern rationale MUST be documented in contract.
- **NFR-TOML-061** [P3]: Defaults can be restored by deleting config file (no `--reset-config` needed).
- **NFR-TOML-062** [P4+]: Migration examples from defaults MAY be added to documentation.
- **NFR-TOML-063** [P4+]: Troubleshooting examples MAY be added to documentation.

---
