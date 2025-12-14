# Feature Specification: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Feature Branch**: `001-sync-docs-spec`
**Created**: 2025-12-14
**Status**: Draft
**Input**: User description: "incorporate @docs , @.scratch/project-restoration/020-implementation-adjustments.md , @.scratch/project-restoration/021-additional-notes.md"

## Clarifications

### Session 2025-12-14

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

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate documentation outputs for a project (Priority: P1)

As a documentation maintainer, I want to run **pndcgn** against a project directory so that I receive a navigable set of generated documentation artifacts (default: PDF) that are easy to browse and share.

**Why this priority**: This is the core user value—turning a project’s documentation sources into an organized output set.

**Independent Test**: Can be fully tested by running the tool against a small fixture project and confirming the expected output directory and index are produced.

**Acceptance Scenarios**:

1. **Given** a directory containing documentation sources, **When** I run the tool with default inputs, **Then** it generates output in a new run directory under my current working directory.
2. **Given** a directory containing documentation sources, **When** I request a specific output format and a specific output location, **Then** it generates outputs under that location and produces a navigable index for the run.

---

### User Story 2 - Preview a run and finalize safely (Priority: P2)

As a documentation maintainer, I want to perform a **dry-run** to understand what will be generated, and then **finalize** that same plan later, so that I can avoid surprises while still having a fast, repeatable workflow.

**Why this priority**: Dry-run/finalize reduces risk for large repos and supports cautious workflows.

**Independent Test**: Can be tested by performing a dry-run, recording the run identifier, changing nothing, then finalizing and verifying outputs are produced.

**Acceptance Scenarios**:

1. **Given** a directory of documentation sources, **When** I run the tool in dry-run mode, **Then** no output artifacts are created and the tool prints a run identifier that can be used to finalize later.
2. **Given** a previous dry-run identifier and unchanged inputs, **When** I finalize that dry-run, **Then** the tool produces the same set of outputs that the dry-run described.
3. **Given** a previous dry-run identifier and inputs that have changed since that dry-run, **When** I attempt to finalize, **Then** the tool refuses to finalize and explains what changed.

---

### User Story 3 - Manage runs and understand results (Priority: P3)

As a documentation maintainer, I want to resume interrupted runs, clean up old runs, and review run statistics, so that the tool stays reliable over time and I can understand what happened during generation.

**Why this priority**: Run management and reporting turn the tool from “one-off script” into something teams can trust and operate.

**Independent Test**: Can be tested by interrupting a run, resuming it, and validating that already-generated outputs are not repeated.

**Acceptance Scenarios**:

1. **Given** a previously started run that did not complete, **When** I resume it by run identifier, **Then** it continues work and does not repeat already-completed work.
2. **Given** completed runs, **When** I request cleanup, **Then** the tool removes only the specified run outputs and does not affect unrelated data without explicit confirmation.
3. **Given** a completed run, **When** I review run statistics, **Then** I can see a human-readable summary (counts, timing, cache efficiency) and can query detailed statistics from the database.

---

### Edge Cases

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

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a primary CLI entrypoint named **`pndcgn`** for users to generate documentation outputs.
- **FR-002**: The system MUST support an optional source directory argument; if omitted, it MUST default to the current working directory.
  - If `fzf` is installed and available in PATH, and SOURCE_DIR is not provided, the system MAY offer an interactive folder selection interface using `fzf` to allow the user to choose a source directory from available subdirectories.
  - The `fzf` interface MUST only display directories (folders), not files.
  - If `fzf` is not available or the user cancels the selection, the system MUST fall back to using the current working directory as the default source directory.
  - The `fzf` integration MUST be optional and MUST NOT be required for normal operation.
- **FR-003**: The system MUST support an optional target directory argument representing the *output parent directory*; if omitted, it MUST default to the current working directory.
- **FR-004**: The system MUST support an output type option (`--type`) that controls the output format; if omitted, it MUST default to `pdf`.
  - The system MUST support all output types supported by pandoc (e.g., pdf, html, epub, docx, odt, rtf, and others).
  - The system MUST validate that the requested output type is supported by the installed pandoc version and MUST fail with exit code 2 (invalid usage) if an unsupported type is provided.
- **FR-004A**: The system MUST support configurable include/exclude patterns for determining which inputs are eligible for processing.
  - Exclude patterns MUST be configured via `.pndcgnignore` file (see FR-004B).
  - Include patterns MAY be configured via an optional TOML config file named `pndcgn.toml`.
  - TOML config file discovery MUST follow this hierarchy (first found wins): `${XDG_CONFIG_HOME:-${HOME}/.config}/pndcgn/pndcgn.toml`, then source directory root `pndcgn.toml`. Source directory config overrides XDG config if both exist.
  - If no TOML config file is found, the system MUST use sensible defaults (include: `docs/` directory, `doc-assets/` directory, plus all text-based files; exclude: patterns from `.pndcgnignore`).
- **FR-004B**: The system MUST support an ignore file named `.pndcgnignore`.
  - The `.pndcgnignore` file MUST be discovered relative to the source directory root.
  - If `.pndcgnignore` does not exist in the source directory root, the system MUST auto-create it on the first non-help run.
  - When auto-creating, the system MUST seed it with default content derived from a project’s `.gitignore` rules (when present).
    - If multiple `.gitignore` files apply to the source directory, it MUST merge them closest-first, matching git’s ignore stacking behavior.
    - If no applicable `.gitignore` rules exist, it MUST seed from a reasonable built-in default.
  - After `.pndcgnignore` exists, the system MUST NOT modify it automatically, even if `.gitignore` changes.
  - The system MUST provide an explicit, user-invoked action to re-seed `.pndcgnignore` from current ignore rules.
  - The default ignore content MUST include the output directory name `.pndcgn` so generated outputs are ignored by default.

- **FR-005**: For each invocation that performs generation (non-help), the system MUST create a new, uniquely identified **run** and associate all generated outputs to that run.
  - The system MUST allow concurrent runs (multiple invocations running simultaneously) and MUST use SQLite WAL mode for safe concurrent database access.
  - Each concurrent run MUST receive its own unique run ID and output directory; database-level locking handles coordination automatically.
- **FR-006**: The system MUST place outputs for a run into a deterministic run directory under the target directory, and that directory name MUST include both the selected output type and the run identifier.
  - Default structure: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`.

- **FR-007**: The system MUST generate a run index artifact that enables a user to navigate to the generated outputs for that run.
  - The index MUST be a Markdown file named `_index.md` placed in the run output directory.
  - The index MUST include navigation links to all generated outputs and run statistics (counts, timing, cache efficiency).
- **FR-008**: The system MUST generate outputs using a stable, human-browsable naming scheme that preserves project hierarchy ordering (e.g., Dewey Decimal-style prefixes).
- **FR-009**: The system MUST detect whether individual inputs are unchanged since the last successful generation and MUST avoid regenerating unchanged outputs.
  - Fingerprint computation MUST use the format `{size}:{mtime}:{sha256_first_64KB}` (size in bytes, modification time as Unix timestamp, SHA256 hash of first 64KB of file content).
  - This enables O(1) fingerprint computation while maintaining sufficient accuracy for change detection.
- **FR-010**: When inputs are unchanged, the system MUST complete a subsequent run significantly faster than a first-time run and MUST report how much work was skipped vs performed.
  - Progress reporting MUST include a human-readable summary written to stdout with counts (total/processed/skipped/failed), timing information, and cache efficiency metrics.
  - Detailed statistics MUST be stored in the database and accessible via SQL queries for programmatic access.
- **FR-011**: The system MUST support resuming an interrupted run by run identifier, and MUST skip work already completed for that run.
- **FR-012**: The system MUST support a dry-run mode that produces no output artifacts and clearly communicates what would be generated.
- **FR-013**: The system MUST support finalizing a previously created dry-run by run identifier.
- **FR-014**: The system MUST ensure dry-run finalization is only allowed when the relevant inputs and configuration are unchanged since the dry-run; otherwise it MUST fail with a clear explanation.
  - Run fingerprint MUST be computed as a combined fingerprint of all input file fingerprints plus configuration state (output type, source/target paths, ignore rules content).
  - Fingerprint validation MUST compare the current run fingerprint against the stored fingerprint from the dry-run or interrupted run.
- **FR-015**: The system MUST provide clear prerequisite validation and error messages for missing required tooling, and MUST still allow `--help`/usage output even if generation prerequisites are not installed.
- **FR-016**: The system MUST provide safe handling for destructive operations (e.g., deleting outputs or clearing cached state) by requiring explicit user confirmation.
  - The `--clean <RUN_ID> [RUN_ID...]` command MUST remove outputs for one or more specified run IDs and MUST require confirmation before deletion.
  - The `--drop` command MUST clear all cache/state and MUST require confirmation before deletion.
  - Both `--clean` and `--drop` MUST warn the user if fingerprint validation fails or if output paths contain non-pndcgn artifacts before proceeding with deletion.
- **FR-017**: All user-facing names and help text MUST consistently use the product name **pndcgn**.
- **FR-018**: The system MUST use globally unique, lexicographically sortable run identifiers so that runs can be naturally ordered by creation time.
  - The system SHOULD use the `sqlite-ulid` extension's `ulid()` function for ULID generation when available.
  - If the `sqlite-ulid` extension cannot be downloaded, installed, or loaded, the system MUST fall back to an alternative ULID generation method (e.g., Bash-based implementation) to ensure the tool remains functional.
  - The fallback method MUST produce ULIDs with the same format and properties (26 characters, lexicographically sortable, timestamp-embedded) as the extension-based method.
- **FR-019**: The system MUST handle all error conditions and edge cases with explicit error messages written to stderr, appropriate exit codes (0=success, 1=runtime error, 2=invalid usage), and actionable recovery guidance when applicable.

### Key Entities *(include if feature involves data)*

- **Run**: A single execution instance with a unique identifier, configuration (source/target/type), status, and summary statistics.
- **Run Output Set**: The collection of artifacts produced by a run (generated documents plus index/navigation artifact).
- **Input Source**: A file or directory contributing content to outputs (including any referenced/embedded content).
- **Fingerprint**: A reproducible representation of the relevant input state used to decide whether outputs can be reused.
  - Format: `{size}:{mtime}:{sha256_first_64KB}` where size is in bytes, mtime is Unix timestamp, and sha256_first_64KB is SHA256 hash of the first 64KB of file content.
  - This format enables O(1) fingerprint computation (only first 64KB hashed) while maintaining sufficient accuracy for change detection.
- **Cache Entry**: A record linking an input fingerprint (and output type) to an existing generated output.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a representative project, a repeat run with no input changes completes at least **5× faster** than the initial run and reports skipped vs processed items.
- **SC-002**: **100%** of dry-run finalizations with unchanged inputs succeed and produce outputs matching the dry-run plan.
- **SC-003**: **100%** of dry-run finalizations with changed inputs fail safely and produce an actionable explanation of the mismatch.
- **SC-004**: In usability testing with a new user, at least **90%** can locate and open a specific generated document using the run index in under **60 seconds**.

## Assumptions

- Users run the tool locally against a directory they can read, and write outputs to a directory they have permission to modify.
- The primary supported use case is converting documentation sources into a navigable output set for sharing and review.
- Output formats beyond PDF are supported conceptually; exact formatting differences are treated as output-type variations rather than separate products.

## Out of Scope

- Implementing new document conversion engines beyond the tool’s existing conversion pipeline.
- Adding remote storage/upload features (outputs are produced on the local filesystem).
