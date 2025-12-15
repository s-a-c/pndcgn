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
- **FR-004A**: The system MUST support configurable include patterns for determining which inputs are eligible for processing.
  - Include patterns MAY be configured via an optional TOML config file named `pndcgn.toml` (see contract: `contracts/toml-config.md`).
  - TOML config file discovery MUST follow this hierarchy (first found wins): `${XDG_CONFIG_HOME:-${HOME}/.config}/pndcgn/pndcgn.toml`, then source directory root `pndcgn.toml`. Source directory config overrides XDG config if both exist.
  - If no TOML config file is found, the system MUST use sensible defaults (include: `docs/` directory, `doc-assets/` directory, plus all text-based files).
  - Exclude patterns are configured via `.pndcgnignore` file (see FR-004B).
- **FR-004B**: The system MUST support an ignore file named `.pndcgnignore` for exclude patterns.
  - The `.pndcgnignore` file MUST be discovered relative to the source directory root.
  - If `.pndcgnignore` does not exist in the source directory root, the system MUST auto-create it on the first non-help run.
  - When auto-creating, the system MUST seed it with default content derived from a project's `.gitignore` rules (when present).
    - If multiple `.gitignore` files apply to the source directory, it MUST merge them closest-first, matching git's ignore stacking behavior.
    - If no applicable `.gitignore` rules exist, it MUST seed from a reasonable built-in default.
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

---

## Non-Functional Requirements *(phased delivery)*

Requirements are tagged with delivery phase:
- **[P1-MVP]**: Critical - Core reliability, crash safety, data integrity
- **[P2]**: High - Common edge cases, error handling, UX
- **[P3]**: Medium - Polish, edge cases, robustness
- **[P4+]**: Low - Nice-to-have, future enhancements

### NFR-CLI: CLI User Experience

#### Help & Version Output

- **NFR-CLI-001** [P2]: The system MUST provide `--help` output with structured sections: synopsis, description, options, examples, exit codes.
- **NFR-CLI-002** [P2]: The system MUST provide `--version` output displaying the current version number.
- **NFR-CLI-003** [P2]: Help text MUST show default values for all options.
- **NFR-CLI-004** [P2]: Help text MUST include usage examples demonstrating common workflows.
- **NFR-CLI-005** [P2]: Help text MUST list supported output types.
- **NFR-CLI-006** [P2]: Help text MUST mention configuration file locations (TOML and .pndcgnignore).
- **NFR-CLI-007** [P2]: Help text MUST describe exit codes (0, 1, 2).
- **NFR-CLI-008** [P3]: Help text SHOULD group related flags logically.
- **NFR-CLI-009** [P4+]: Man page documentation MAY be provided for extended help.

#### Output Modes

- **NFR-CLI-010** [P3]: The system SHOULD support `--quiet` mode that suppresses non-error output.
- **NFR-CLI-011** [P2]: The system MUST support `--verbose` mode that provides detailed progress information.
- **NFR-CLI-012** [P3]: The system MAY support stdin/pipe input for scripting scenarios.

#### Terminal Behavior

- **NFR-CLI-013** [P1-MVP]: When stdout is not a TTY (piped/redirected), the system MUST disable interactive features (spinners, colors, prompts) and output machine-parseable text.
- **NFR-CLI-014** [P1-MVP]: The system MUST support the `NO_COLOR` environment variable to disable color output per the no-color.org standard.
- **NFR-CLI-015** [P2]: The system MUST use ANSI color codes for visual distinction (errors=red, warnings=yellow, success=green, info=default).
- **NFR-CLI-016** [P3]: The system SHOULD handle `TERM` environment variable to detect terminal capabilities.
- **NFR-CLI-017** [P3]: The system SHOULD wrap long paths/names appropriately for narrow terminals.
- **NFR-CLI-018** [P4+]: The system MAY support screen reader compatibility via structured output.
- **NFR-CLI-019** [P4+]: Color choices SHOULD be colorblind-friendly (avoid red/green only distinctions).

#### Run ID Display

- **NFR-CLI-020** [P2]: Run IDs MUST be displayed in a copy-paste friendly format (single line, no surrounding punctuation).
- **NFR-CLI-021** [P2]: When a run ID is needed for subsequent commands (dry-run, resume), the system MUST clearly indicate how to use it.

#### Timing & Duration

- **NFR-CLI-022** [P2]: Duration output MUST use human-readable format: milliseconds for <1s, seconds with 1 decimal for <60s, minutes:seconds for longer.
- **NFR-CLI-023** [P3]: Byte sizes MUST use human-readable format (KB, MB, GB) with appropriate precision.

#### Confirmation Prompts

- **NFR-CLI-024** [P2]: Confirmation prompts MUST accept: y, yes, Y, YES (affirmative) and n, no, N, NO (negative).
- **NFR-CLI-025** [P2]: Invalid confirmation responses MUST re-prompt (up to 3 times) then abort with exit code 2.
- **NFR-CLI-026** [P2]: The system SHOULD support `--yes` flag to bypass confirmation prompts for automation.
- **NFR-CLI-027** [P1-MVP]: When stdin is not a TTY, destructive operations MUST require `--yes` flag or fail with exit code 2.
- **NFR-CLI-028** [P3]: Confirmation prompts SHOULD NOT have a timeout (wait indefinitely for user input).

#### Progress Reporting

- **NFR-CLI-029** [P3]: Progress indicators SHOULD use spinner animation for indeterminate progress.
- **NFR-CLI-030** [P3]: Progress SHOULD display file count format: `Processing: X/Y files (Z%)`.
- **NFR-CLI-031** [P3]: Progress update frequency SHOULD be at least once per second during active processing.
- **NFR-CLI-032** [P3]: Progress during cache lookup SHOULD indicate "Checking cache..." phase.
- **NFR-CLI-033** [P4+]: ETA display MAY be provided for long-running operations.

#### Final Summary Output

- **NFR-CLI-034** [P2]: Final summary MUST include: total files, processed, skipped, failed, duration, cache hit rate.
- **NFR-CLI-035** [P3]: Statistics output MUST use consistent column alignment.
- **NFR-CLI-036** [P3]: Cache statistics MUST show hits, misses, and efficiency percentage.

#### Error Messages

- **NFR-CLI-037** [P2]: Error messages MUST include: error type prefix, context (file/path), actionable suggestion.
- **NFR-CLI-038** [P2]: Error messages for invalid run IDs MUST indicate correct format.
- **NFR-CLI-039** [P2]: Error messages for non-existent run IDs MUST suggest listing available runs.
- **NFR-CLI-040** [P3]: Debug information SHOULD be available via `--verbose` or environment variable.
- **NFR-CLI-041** [P4+]: Localization/i18n for error messages is out of scope for initial release.

#### fzf Integration

- **NFR-CLI-042** [P3]: fzf interface SHOULD display directories sorted alphabetically.
- **NFR-CLI-043** [P3]: fzf SHOULD traverse up to 3 levels deep by default.
- **NFR-CLI-044** [P3]: fzf SHOULD exclude hidden directories (starting with `.`).
- **NFR-CLI-045** [P3]: fzf cancellation (Ctrl+C, Esc) MUST fall back to current working directory.
- **NFR-CLI-046** [P3]: fzf result SHOULD display relative path from current directory.
- **NFR-CLI-047** [P4+]: fzf keybindings and preview options are implementation details.

#### Keyboard Interrupt

- **NFR-CLI-048** [P1-MVP]: Ctrl+C (SIGINT) MUST trigger graceful shutdown: stop processing, save checkpoint, report partial progress.
- **NFR-CLI-049** [P2]: Interrupted state MUST be clearly communicated with instructions for resuming.

### NFR-CACHE: Caching & State Management

#### Fingerprint Computation

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

#### Cache Behavior

- **NFR-CACHE-011** [P2]: When source file is deleted, corresponding cache entries MUST be invalidated on next run.
- **NFR-CACHE-012** [P2]: When source file is renamed, it MUST be treated as delete + create (old cache invalid, new cache miss).
- **NFR-CACHE-013** [P2]: When source file is moved, it MUST be treated as delete + create.
- **NFR-CACHE-014** [P2]: When output type changes for same source, cache lookup MUST miss (cache keyed by source+type).
- **NFR-CACHE-015** [P3]: Cache entry expiration/TTL is NOT required (entries valid until invalidated).
- **NFR-CACHE-016** [P3]: Cache size limit is NOT required (no automatic eviction).
- **NFR-CACHE-017** [P4+]: Cache warming/preloading is out of scope.
- **NFR-CACHE-018** [P3]: Cascading invalidation for dependencies is NOT supported (each file independent).
- **NFR-CACHE-019** [P3]: Partial cache invalidation (single entry) SHOULD be supported via internal API.

#### Database State

- **NFR-CACHE-020** [P2]: Database schema version MUST be stored in a metadata table.
- **NFR-CACHE-021** [P2]: Schema migrations MUST be applied automatically on startup if version mismatch detected.
- **NFR-CACHE-022** [P1-MVP]: Database file MUST be created with permissions 0600 (user read/write only).
- **NFR-CACHE-023** [P1-MVP]: If database file is corrupted (SQLite integrity check fails), the system MUST log error, rename corrupted file with `.corrupted.{timestamp}` suffix, and create fresh database.
- **NFR-CACHE-024** [P3]: Database backup/recovery is NOT automatically provided (user responsibility).
- **NFR-CACHE-025** [P3]: Database connection pooling is NOT required (single connection per process).
- **NFR-CACHE-026** [P3]: Database transactions SHOULD wrap entire file processing (commit on success, rollback on failure).
- **NFR-CACHE-027** [P2]: Run timestamps MUST be stored as Unix timestamps (integer seconds).
- **NFR-CACHE-028** [P2]: Run duration MUST be calculated as (end_timestamp - start_timestamp) in seconds.

#### Run State Machine

- **NFR-CACHE-029** [P1-MVP]: Run status transitions MUST follow: `created` → `running` → (`complete` | `failed` | `interrupted`).
- **NFR-CACHE-030** [P1-MVP]: Dry-run status MUST be `dry-run` (distinct from `created`).
- **NFR-CACHE-031** [P1-MVP]: On startup, if any run has status `running` from a previous session, it MUST be marked `interrupted`.
- **NFR-CACHE-032** [P1-MVP]: Checkpoint corruption (unreadable/invalid JSON) MUST mark run as `failed` and log error.

#### Resume Behavior

- **NFR-CACHE-033** [P2]: Resuming a `complete` run MUST fail with error "Run already complete".
- **NFR-CACHE-034** [P2]: Resuming a `failed` run MUST fail with error "Run failed; start new run instead".
- **NFR-CACHE-035** [P2]: Resuming a `dry-run` MUST fail with error "Cannot resume dry-run; use --finalize instead".
- **NFR-CACHE-036** [P2]: Resume with deleted source files MUST skip those files and log warning.
- **NFR-CACHE-037** [P2]: Resume with added source files MUST process new files in addition to remaining files.
- **NFR-CACHE-038** [P2]: Resume with changed config MUST fail fingerprint validation and require new run.
- **NFR-CACHE-039** [P2]: Resume with changed output type MUST fail fingerprint validation.
- **NFR-CACHE-040** [P2]: Partial progress display on resume MUST show "Resuming from X/Y files".

#### Dry-Run/Finalize

- **NFR-CACHE-041** [P2]: Dry-runs SHOULD NOT expire (valid until source changes).
- **NFR-CACHE-042** [P2]: Multiple pending dry-runs MUST be allowed (each with unique ID).
- **NFR-CACHE-043** [P2]: Finalizing already-finalized run MUST fail with error "Run already finalized".
- **NFR-CACHE-044** [P2]: Finalizing non-existent run ID MUST fail with error "Run not found: {ID}".
- **NFR-CACHE-045** [P2]: Config changes between dry-run and finalize MUST fail fingerprint validation.

#### ULID Generation

- **NFR-CACHE-046** [P2]: sqlite-ulid extension version SHOULD be 0.2.1 or compatible.
- **NFR-CACHE-047** [P3]: Bash fallback ULID MUST use `/dev/urandom` for randomness.
- **NFR-CACHE-048** [P3]: ULID generation rate limiting is NOT required (collisions statistically impossible).
- **NFR-CACHE-049** [P3]: ULID collision handling is NOT required (rely on statistical uniqueness).

#### Cache Metrics

- **NFR-CACHE-050** [P3]: Cache statistics MUST display: "Cache: X hits, Y misses (Z% efficiency)".
- **NFR-CACHE-051** [P4+]: Historical cache metrics are out of scope.
- **NFR-CACHE-052** [P3]: Cache efficiency threshold for success criteria is informational only (no hard requirement).

#### Cleanup Operations

- **NFR-CACHE-053** [P2]: Cleaning non-existent run ID MUST fail with error "Run not found: {ID}" and exit code 1.
- **NFR-CACHE-054** [P3]: Partial cleanup failure (some runs fail) MUST report each failure and continue with remaining.
- **NFR-CACHE-055** [P3]: Cleanup confirmation MUST show: "Delete run {ID} ({N} files, {size})? [y/N]".
- **NFR-CACHE-056** [P3]: Cleanup progress SHOULD show "Deleting: X/Y runs".
- **NFR-CACHE-057** [P3]: Cleanup interruption MUST leave remaining runs intact (atomic per-run deletion).
- **NFR-CACHE-058** [P4+]: Cleanup audit trail/logging is out of scope.
- **NFR-CACHE-059** [P3]: Orphaned cache entries (output missing) SHOULD be cleaned during normal runs.

### NFR-EDGE: Extended Edge Cases

#### Source Directory

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

#### Target Directory

- **NFR-EDGE-012** [P2]: Non-existent target directory MUST be created automatically (including parent directories).
- **NFR-EDGE-013** [P2]: Target directory creation failure MUST report error with specific reason (permissions, disk full).
- **NFR-EDGE-014** [P2]: Target paths with spaces MUST be handled correctly.
- **NFR-EDGE-015** [P2]: Target directory same as source MUST be allowed (outputs go to `.pndcgn/` subdirectory).
- **NFR-EDGE-016** [P2]: Target directory inside source MUST be allowed (but outputs auto-ignored via `.pndcgn` pattern).
- **NFR-EDGE-017** [P3]: Target on different filesystem MUST work (no special handling).
- **NFR-EDGE-018** [P1-MVP]: Disk full during output write MUST fail gracefully, mark run as `failed`, and report space needed.
- **NFR-EDGE-019** [P2]: Existing `.pndcgn` directory with conflicts MUST NOT be modified; new runs create new subdirectories.

#### Input Files

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

#### Output Type

- **NFR-EDGE-032** [P2]: Output type matching MUST be case-insensitive (PDF, pdf, Pdf all valid).
- **NFR-EDGE-033** [P2]: Output types requiring external tools (e.g., pdflatex for PDF) MUST check prerequisites and report missing tools.

#### Concurrent Operations

- **NFR-EDGE-034** [P2]: Two concurrent runs processing the same source file MUST both succeed (no file locking on source).
- **NFR-EDGE-035** [P2]: Concurrent runs with different output types MUST work independently.
- **NFR-EDGE-036** [P2]: Database locking timeout MUST be 30 seconds; if exceeded, fail with "Database busy, retry later".
- **NFR-EDGE-037** [P2]: Database lock acquisition failure MUST fail with clear error (not hang indefinitely).
- **NFR-EDGE-038** [P3]: Concurrent cleanup operations MUST be serialized via database locking.
- **NFR-EDGE-039** [P3]: Concurrent resume operations on same run MUST fail second attempt with "Run already being processed".
- **NFR-EDGE-040** [P2]: Concurrent runs MUST NOT create conflicting output directories (ULID uniqueness guarantees this).

#### Signal Handling

- **NFR-EDGE-041** [P1-MVP]: SIGINT (Ctrl+C) MUST trigger graceful shutdown: finish current file, checkpoint, mark interrupted.
- **NFR-EDGE-042** [P1-MVP]: SIGTERM MUST trigger same graceful shutdown as SIGINT.
- **NFR-EDGE-043** [P1-MVP]: SIGKILL cannot be caught; database WAL ensures consistency on recovery.
- **NFR-EDGE-044** [P2]: SIGHUP MUST be ignored (allow terminal disconnect without stopping).
- **NFR-EDGE-045** [P1-MVP]: Trap handlers MUST be installed for INT, TERM signals on startup.
- **NFR-EDGE-046** [P1-MVP]: Interrupt during database write MUST NOT corrupt database (SQLite WAL handles this).
- **NFR-EDGE-047** [P1-MVP]: Interrupt during file write MUST leave partial file (cleaned up on resume/next run).
- **NFR-EDGE-048** [P1-MVP]: Database state after unexpected termination MUST be recoverable (WAL replay).
- **NFR-EDGE-049** [P2]: Partial outputs on interruption MUST be tracked and re-processed on resume.

#### Resume Edge Cases

- **NFR-EDGE-050** [P2]: Resume run ID that doesn't exist MUST fail with "Run not found: {ID}".
- **NFR-EDGE-051** [P2]: Resume with partial outputs corrupted MUST re-process those files.

#### Finalize Edge Cases

- **NFR-EDGE-052** [P2]: Finalize with source permissions changed MUST fail fingerprint validation.
- **NFR-EDGE-053** [P2]: Finalize with target unavailable MUST fail with clear error.

#### External Dependencies

- **NFR-EDGE-054** [P2]: sqlite3 not installed MUST fail with clear error "sqlite3 required but not found".
- **NFR-EDGE-055** [P2]: curl not available for extension download MUST fall back to Bash ULID silently.
- **NFR-EDGE-056** [P2]: Pandoc crash during conversion MUST fail that file, continue with others, mark run partial.
- **NFR-EDGE-057** [P2]: Pandoc invalid output MUST fail that file with warning, continue with others.
- **NFR-EDGE-058** [P3]: Pandoc version incompatibility SHOULD be detected and warned (not enforced).
- **NFR-EDGE-059** [P2]: Missing LaTeX packages for PDF MUST fail with pandoc's error message (pass through).
- **NFR-EDGE-060** [P2]: Network unavailable during extension download MUST fall back to Bash ULID.

#### Configuration Edge Cases

- **NFR-EDGE-061** [P2]: Malformed .pndcgnignore MUST log warning and treat as empty (include all).
- **NFR-EDGE-062** [P2]: Conflicting ignore patterns MUST apply last-match-wins (gitignore semantics).
- **NFR-EDGE-063** [P2]: Unreadable config file MUST log warning and use defaults.
- **NFR-EDGE-064** [P2]: Invalid XDG_CONFIG_HOME MUST fall back to `~/.config`.
- **NFR-EDGE-065** [P3]: Circular include patterns (impossible with glob) are not applicable.
- **NFR-EDGE-066** [P3]: Overly permissive patterns (match everything) MUST work (user's choice).
- **NFR-EDGE-067** [P3]: Overly restrictive patterns (match nothing) MUST produce empty run with warning.

#### Cleanup Edge Cases

- **NFR-EDGE-068** [P2]: --clean targeting active run MUST fail with "Run in progress, cannot clean".
- **NFR-EDGE-069** [P2]: --drop failure midway MUST report what was deleted and what failed.
- **NFR-EDGE-070** [P2]: Database deletion failure MUST report error and continue with filesystem cleanup.
- **NFR-EDGE-071** [P2]: Filesystem deletion failure MUST report error with path and reason.
- **NFR-EDGE-072** [P2]: Cleanup with insufficient permissions MUST fail with clear permission error.

#### Resource Exhaustion

- **NFR-EDGE-073** [P1-MVP]: Memory exhaustion MUST fail gracefully (Bash will report error).
- **NFR-EDGE-074** [P1-MVP]: Disk full MUST fail with "No space left on device" and exit code 1.
- **NFR-EDGE-075** [P3]: File descriptor limit MUST fail with clear error if reached.
- **NFR-EDGE-076** [P3]: Processing thousands of files MUST work (no artificial limits); performance may degrade.
- **NFR-EDGE-077** [P3]: Maximum supported file count is limited only by filesystem and memory.
- **NFR-EDGE-078** [P3]: Maximum supported total size is limited only by disk space.
- **NFR-EDGE-079** [P3]: Timeout for long-running operations is NOT enforced (user can interrupt).
- **NFR-EDGE-080** [P3]: Graceful degradation under resource pressure relies on OS behavior.

### NFR-TOML: TOML Configuration

#### File Discovery

- **NFR-TOML-001** [P2]: Config file symlinks MUST be followed (resolve to target).
- **NFR-TOML-002** [P2]: XDG_CONFIG_HOME with spaces MUST be handled correctly.
- **NFR-TOML-003** [P2]: Config path with special characters MUST be handled correctly.
- **NFR-TOML-004** [P2]: Config file permissions SHOULD be readable by user (no enforcement).
- **NFR-TOML-005** [P2]: Config file that is a directory MUST fail with "Config path is directory: {path}".
- **NFR-TOML-006** [P1-MVP]: Config file content MUST be included in run fingerprint.

#### Pattern Syntax

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

#### Extension Syntax

- **NFR-TOML-017** [P2]: Extension matching MUST be case-insensitive (md, MD, Md all match).
- **NFR-TOML-018** [P2]: Compound extensions (`.tar.gz`) MUST match full compound (extension = `tar.gz`).
- **NFR-TOML-019** [P3]: Empty extension string MUST be ignored with warning.
- **NFR-TOML-020** [P3]: Extension with spaces MUST be ignored with warning.
- **NFR-TOML-021** [P3]: Maximum extension length is NOT enforced.
- **NFR-TOML-022** [P3]: Numeric-only extensions MUST be allowed (e.g., `1`, `123`).

#### TOML Parsing

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

#### Error Handling

- **NFR-TOML-033** [P2]: Parse error warnings MUST include line number: "Config warning: {file}:{line}: {message}".
- **NFR-TOML-034** [P2]: Syntax errors in patterns MUST be warned and pattern skipped.
- **NFR-TOML-035** [P2]: Unreadable config file error MUST include permission details.
- **NFR-TOML-036** [P3]: Binary content in config file MUST be detected and treated as malformed.
- **NFR-TOML-037** [P3]: Non-UTF8 encoding MUST be warned and file treated as malformed.

#### Validation

- **NFR-TOML-038** [P3]: Validation error format MUST be: "Invalid pattern '{pattern}': {reason}".
- **NFR-TOML-039** [P3]: Patterns matching nothing MUST produce warning (not error).
- **NFR-TOML-040** [P3]: Patterns matching everything MUST be allowed (user's choice).
- **NFR-TOML-041** [P3]: Validation against actual filesystem is NOT performed (patterns are evaluated at runtime).
- **NFR-TOML-042** [P3]: Path traversal (`../`) in patterns MUST be rejected with error.
- **NFR-TOML-043** [P2]: Absolute paths in patterns MUST be rejected with error.

#### Pattern Precedence

- **NFR-TOML-044** [P1-MVP]: Evaluation order MUST be: include patterns first, then exclude patterns (.pndcgnignore).
- **NFR-TOML-045** [P1-MVP]: Include patterns and .pndcgnignore interact as: file must match include AND not match exclude.
- **NFR-TOML-046** [P2]: Within pattern array, all patterns are OR'd (match any).
- **NFR-TOML-047** [P3]: Overlapping patterns are allowed (first match or any match, same result).

#### Integration

- **NFR-TOML-048** [P1-MVP]: Config changes between dry-run and finalize MUST fail fingerprint validation.
- **NFR-TOML-049** [P1-MVP]: Config changes during resume MUST fail fingerprint validation.
- **NFR-TOML-050** [P3]: --type option does NOT interact with config (config is for file discovery only).
- **NFR-TOML-051** [P3]: Config change detection uses content hash, not mtime.

#### Edge Cases

- **NFR-TOML-052** [P3]: Config file larger than 1MB MUST be rejected with warning (likely error).
- **NFR-TOML-053** [P2]: Unset HOME environment variable MUST fail with "HOME not set".
- **NFR-TOML-054** [P2]: XDG_CONFIG_HOME pointing to non-existent path MUST skip (fall back to source dir).
- **NFR-TOML-055** [P3]: Config with only comments MUST be treated as empty (use defaults).
- **NFR-TOML-056** [P3]: Config with only whitespace MUST be treated as empty (use defaults).
- **NFR-TOML-057** [P3]: Pattern recursion depth (via `**`) is limited by filesystem depth.
- **NFR-TOML-058** [P3]: Unicode in patterns MUST be supported (UTF-8).
- **NFR-TOML-059** [P3]: Unicode in extensions MUST be supported (UTF-8).

#### Documentation

- **NFR-TOML-060** [P3]: Default pattern rationale MUST be documented in contract.
- **NFR-TOML-061** [P3]: Defaults can be restored by deleting config file (no `--reset-config` needed).
- **NFR-TOML-062** [P4+]: Migration examples from defaults MAY be added to documentation.
- **NFR-TOML-063** [P4+]: Troubleshooting examples MAY be added to documentation.
