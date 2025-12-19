# Requirements Specification

Compliant with [AGENTS.md](../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

## Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Requirements Methodology](#2-requirements-methodology)
- [3. User Stories](#3-user-stories)
  - [3.1. Installation and Setup](#31-installation-and-setup)
  - [3.2. PDF Generation](#32-pdf-generation)
  - [3.3. Caching and Performance](#33-caching-and-performance)
  - [3.4. CLI Operations](#34-cli-operations)
  - [3.5. Output and Reporting](#35-output-and-reporting)
  - [3.6. Run Management](#36-run-management)
- [4. Traceability Matrix](#4-traceability-matrix)
- [5. Navigation](#5-navigation)

</details>

## 1. Introduction

This document specifies requirements for the **pndcgn** tool using Behavior-Driven Development (BDD) methodology. Requirements are expressed as user stories with clear acceptance criteria, examples of desired behavior, and examples of undesired behavior.

**Purpose**: Define what the system must do from the user's perspective, providing a foundation for system tests and implementation.

**Audience**: Developers, testers, and stakeholders who need to understand system requirements and validate behavior.

## 2. Requirements Methodology

### 2.1. Story Format

All requirements follow the standard BDD user story format:

```log
As a [role]
I want [feature]
So that [benefit]
```

Each story includes:
- **Story ID**: Unique identifier (REQ-XXX)
- **Acceptance Criteria**: Specific, testable conditions
- **Desired Behavior**: Examples of correct system behavior
- **Undesired Behavior**: Examples of incorrect behavior to prevent

### 2.2. Testing Approach

- System tests validate requirements → [100-system-test-plan.md](100-system-test-plan.md)
- Feature/unit tests validate implementation → [120-feature-unit-test-plan.md](120-feature-unit-test-plan.md)
- Tests use shellspec framework with Given-When-Then format

## 3. User Stories

### 3.1. Installation and Setup

#### REQ-001: Prerequisites Verification

**Story**:
```
As a user
I want the tool to verify all prerequisites before running
So that I get clear error messages if something is missing
```

**Acceptance Criteria**:
- Tool checks for pandoc, sqlite3, uv before execution
- Clear error message identifies missing prerequisite
- Exit code 1 if prerequisites missing
- Succeeds silently if all prerequisites present

**Desired Behavior**:
- `pndcgn --help` shows usage even if prerequisites missing
- `pndcgn` checks prerequisites and reports: "ERROR: Prerequisite not found: 'pandoc'"
- Error message suggests installation method

**Undesired Behavior**:
- Tool crashes with cryptic error when pandoc missing
- Tool partially executes before discovering missing dependency
- Generic "command not found" without helpful context

#### REQ-002: Configuration Initialization

**Story**:
```
As a user
I want to generate a default configuration file
So that I can customize tool behavior without editing code
```

**Acceptance Criteria**:
- `pndcgn --init` creates `pndcgn.toml` (or config file name TBD)
- Configuration file includes sensible defaults
- Tool exits after creating config
- Error if config file already exists

**Desired Behavior**:
- `pndcgn --init` creates config with output_root, default format
- Confirmation message: "Created default configuration at: pndcgn.toml"
- Existing config not overwritten without confirmation

**Undesired Behavior**:
- Config creation fails silently
- Existing config overwritten without warning
- Invalid TOML syntax in generated file

### 3.2. PDF Generation

#### REQ-003: Basic PDF Generation

**Story**:
```
As a documentation maintainer
I want to generate PDFs from project source files
So that I have consolidated, professional documentation
```

**Acceptance Criteria**:
- Tool traverses project directories
- Processes markdown, code, and diagram files
- Generates PDFs with Dewey Decimal naming
- Creates master index with hyperlinks

**Desired Behavior**:
- `pndcgn` generates PDFs in structured output directory
- PDFs named: `100-laravel.pdf`, `100.010-tad.pdf`
- `_index.md` contains Mermaid diagram and PDF links
- Progress indicators show processing status

**Undesired Behavior**:
- PDFs generated with random or inconsistent naming
- No progress feedback during long operations
- Incomplete generation without error message

#### REQ-004: Multi-Format Support

**Story**:
```
As a documentation maintainer
I want to specify output format
So that I can generate HTML, EPUB, or other formats
```

**Acceptance Criteria**:
- `--type` argument specifies output format
- PDF is default format
- Output directory reflects format: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- Filter chain adapts to output format

**Desired Behavior**:
- `pndcgn` defaults to PDF output
- `pndcgn --type html` generates HTML files
- Future: `--type epub`, `--type markdown`

**Undesired Behavior**:
- Invalid format type causes crash
- PDF-specific logic runs for HTML output
- Format not reflected in output path

### 3.3. Caching and Performance

#### REQ-005: Intelligent Caching

**Story**:
```
As a documentation maintainer
I want the tool to cache unchanged content
So that regeneration is fast
```

**Acceptance Criteria**:
- SQLite database stores file hashes
- Unchanged files not reprocessed
- Cache hit/miss ratio tracked
- Subsequent runs dramatically faster

**Desired Behavior**:
- First run: processes all files, caches results
- Second run (no changes): skips processing, uses cache
- Output shows: "Skipping (cached): 100-laravel.pdf"
- Stats show cache efficiency

**Undesired Behavior**:
- Every run reprocesses all files
- Cache never invalidated when files change
- Stale content in generated PDFs

#### REQ-006: Dependency Tracking

**Story**:
```
As a documentation maintainer
I want automatic dependency tracking
So that changing a diagram regenerates dependent PDFs
```

**Acceptance Criteria**:
- Database tracks file dependencies
- Change in included file triggers regeneration
- Diagram changes trigger dependent PDF regeneration

**Desired Behavior**:
- Markdown file includes PlantUML diagram
- Diagram changes → markdown PDF regenerated
- Direct markdown changes also trigger regeneration

**Undesired Behavior**:
- Diagram updated but dependent PDF not regenerated
- All PDFs regenerated when one diagram changes

### 3.4. CLI Operations

#### REQ-007: Force Regeneration

**Story**:
```
As a documentation maintainer
I want to force complete regeneration
So that I can ensure a clean rebuild
```

**Acceptance Criteria**:
- `--force` flag ignores cache
- All PDFs regenerated regardless of changes
- Cache updated with new results

**Desired Behavior**:
- `pndcgn --force` regenerates all PDFs
- Progress shows all items processing (none skipped)
- New run ID created

**Undesired Behavior**:
- Force flag partially ignored
- Cache cleared but not rebuilt
- Unexpected cache corruption

#### REQ-008: Dry Run Preview

**Story**:
```
As a documentation maintainer
I want to preview what would be generated
So that I can verify before actual generation
```

**Acceptance Criteria**:
- `--dry-run` shows what would be processed
- No actual PDFs generated
- Run ID and fingerprint provided
- Can finalize dry-run later

**Desired Behavior**:
- `pndcgn --dry-run` shows processing plan
- Output: "Would process: docs/architecture"
- Provides run ID for later finalization

**Undesired Behavior**:
- Dry-run actually generates files
- No useful preview information
- Cannot finalize dry-run

#### REQ-009: Clean Specific Runs

**Story**:
```
As a documentation maintainer
I want to remove specific run outputs
So that I can clean up space
```

**Acceptance Criteria**:
- `--clean RUN_ID [RUN_ID...]` removes specified runs
- Confirmation required before deletion
- Database records updated
- Multiple run IDs supported

**Desired Behavior**:
- `pndcgn --clean 01JEMH3F...` prompts for confirmation
- After confirmation: deletes output directory
- Database marked as cleaned

**Undesired Behavior**:
- Deletion without confirmation
- Wrong run deleted
- Database inconsistency after deletion

#### REQ-010: Drop All Outputs

**Story**:
```
As a documentation maintainer
I want to clear all outputs and cache
So that I can start fresh
```

**Acceptance Criteria**:

#### REQ-011: Interactive Source Selection (fzf)

**Story**:
```
As a documentation maintainer
I want to interactively select a source directory when I don't specify one
So that I can quickly choose from available folders without typing paths
```

**Acceptance Criteria**:
- If `fzf` is installed and SOURCE_DIR is not provided, offer interactive folder selection
- Only directories (folders) are displayed, not files
- User can cancel selection (falls back to current directory)
- If `fzf` is not installed, silently fall back to current directory (no error)
- Integration is optional and does not affect normal operation

**Desired Behavior**:
- `pndcgn` (no arguments) opens `fzf` with directory list if `fzf` installed
- User selects directory from fuzzy finder interface
- Selected directory used as SOURCE_DIR
- If `fzf` not installed, uses current directory without error

**Undesired Behavior**:
- Error message when `fzf` not installed
- Files shown in selection interface
- Tool fails if `fzf` unavailable
- Selection required even when SOURCE_DIR provided

**Acceptance Criteria**:
- `--drop` removes all output directories and cache
- Confirmation required
- Fresh state after completion

**Desired Behavior**:
- `pndcgn --drop` prompts: "Delete all outputs? (y/N)"
- After confirmation: removes output parent and state directory
- Confirmation message: "All outputs cleared"

**Undesired Behavior**:
- Deletion without confirmation
- Partial deletion leaving inconsistent state
- Source files accidentally deleted

#### REQ-011: Interactive Source Selection (fzf)

**Story**:
```
As a documentation maintainer
I want to interactively select a source directory when I don't specify one
So that I can quickly choose from available folders without typing paths
```

**Acceptance Criteria**:
- If `fzf` is installed and SOURCE_DIR is not provided, offer interactive folder selection
- Only directories (folders) are displayed, not files
- User can cancel selection (falls back to current directory)
- If `fzf` is not installed, silently fall back to current directory (no error)
- Integration is optional and does not affect normal operation

**Desired Behavior**:
- `pndcgn` (no arguments) opens `fzf` with directory list if `fzf` installed
- User selects directory from fuzzy finder interface
- Selected directory used as SOURCE_DIR
- If `fzf` not installed, uses current directory without error

**Undesired Behavior**:
- Error message when `fzf` not installed
- Files shown in selection interface
- Tool fails if `fzf` unavailable
- Selection required even when SOURCE_DIR provided

### 3.5. Output and Reporting

#### REQ-012: Progress Indicators

**Story**:
```
As a documentation maintainer
I want clear progress feedback
So that I know the tool is working and how long to wait
```

**Acceptance Criteria**:
- Animated spinner shows activity
- Overall progress with percentage
- Per-folder progress during processing
- Clear completion message

**Desired Behavior**:
- Output shows: `[—] Overall Progress: 42/100 (42%)`
- Spinner animates through: —, \, |, /
- Color-coded status messages

**Undesired Behavior**:
- Silent execution with no feedback
- Progress stuck or incorrect
- Spinner floods console

#### REQ-013: Statistics Reporting

**Story**:
```
As a documentation maintainer
I want statistics about the generation run
So that I can understand performance and coverage
```

**Acceptance Criteria**:
- Run duration tracked
- Files processed by type
- Cache efficiency reported
- Statistics in index file

**Desired Behavior**:
- Index shows: runtime, files processed, cache hits
- Per-run statistics stored in database
- Can query historical runs

**Undesired Behavior**:
- No statistics provided
- Inaccurate counts
- Statistics not persisted

### 3.6. Run Management

#### REQ-014: Run Resumption

**Story**:
```
As a documentation maintainer
I want to resume an interrupted run
So that I don't lose progress from crashes
```

**Acceptance Criteria**:
- `--resume` continues from last checkpoint
- Detects incomplete runs automatically
- Prompts to resume or start new
- Fingerprint validation ensures consistency

**Desired Behavior**:
- Tool interrupted → next run detects incomplete
- Prompt: "Resume incomplete run? (y/N)"
- If resumed: continues from last processed directory

**Undesired Behavior**:
- Always starts from beginning
- No detection of incomplete runs
- Resume uses stale data

#### REQ-015: Fingerprinting

**Story**:
```
As a documentation maintainer
I want state validation through fingerprinting
So that resumption is safe and consistent
```

**Acceptance Criteria**:
- Input fingerprint calculated from source files
- Config fingerprint from tool settings
- Combined fingerprint stored with run
- Fingerprint mismatch prevents invalid resumption

**Desired Behavior**:
- Fingerprint calculated at run start
- Stored in database with run
- Resume validates fingerprint matches
- Mismatch: "ERROR: Fingerprint mismatch. Source files changed."

**Undesired Behavior**:
- No fingerprint validation
- Resume with changed sources
- Inconsistent output

#### REQ-016: Dry-Run Finalization

**Story**:
```
As a documentation maintainer
I want to finalize a previous dry-run
So that I can review before committing to generation
```

**Acceptance Criteria**:
- `--finalize RUN_ID` converts dry-run to actual
- Fingerprint validation ensures consistency
- Error if fingerprint changed
- Actual generation proceeds if valid

**Desired Behavior**:
- `pndcgn --dry-run` provides run ID
- Later: `pndcgn --finalize 01JEMH3F...`
- If fingerprint matches: generation proceeds
- If not: error with explanation

**Undesired Behavior**:
- Finalize without fingerprint check
- Cannot finalize dry-runs
- Finalize uses stale plan

### 3.7. Multi-Directory Selection

#### REQ-017: Multiple Directory Selection via fzf

**Story**:
```
As a user with documents spread across multiple directories
I want to select several source directories at once using fzf
So that I can process all of them in a single pndcgn run without running the command multiple times
```

**Acceptance Criteria**:
- fzf multi-select allows selecting multiple directories using Tab key
- All selected directories processed in a single run
- Single run ID assigned covering all source directories
- Output files use abbreviated unique prefixes when multiple directories selected

**Desired Behavior**:
- `pndcgn` (no args) launches fzf with multi-select enabled
- Tab key toggles directory selection
- Enter confirms selection and processing begins
- All selected directories processed sequentially
- Output files: `front--app.pdf`, `back--server.pdf` (abbreviated prefixes)

**Undesired Behavior**:
- Only single directory selectable
- Each directory requires separate pndcgn invocation
- No way to distinguish source directory in output filenames
- Multiple run IDs for single logical operation

#### REQ-018: Configurable Selection Limit

**Story**:
```
As a power user
I want to configure the maximum number of directories I can select
So that I can balance between flexibility and preventing accidental over-selection
```

**Acceptance Criteria**:
- `max_source_dirs` setting in pndcgn.toml under `[source]` section
- Default limit of 4 directories when config not set
- Absolute maximum of 16 directories (hard cap)
- Warning when configured limit exceeds maximum

**Desired Behavior**:
- Config: `[source]\nmax_source_dirs = 5`
- fzf prevents selection beyond configured limit
- Error message if CLI args exceed limit
- Warning: "max_source_dirs=20 exceeds maximum (16), capping at 16"

**Undesired Behavior**:
- No way to configure limit
- Limit too low or too high by default
- No validation of configured limit
- Silent failure when limit exceeded

#### REQ-019: Backward Compatibility for Single Directory

**Story**:
```
As an existing user
I want the current single-directory selection behavior to continue working
So that my existing workflows are not disrupted
```

**Acceptance Criteria**:
- Single directory selection (no Tab) works exactly as before
- No abbreviated source prefix added for single directory
- CLI single directory argument works without changes
- fzf single-select behavior unchanged

**Desired Behavior**:
- `pndcgn ./docs` works as before (single directory, no prefix)
- fzf Enter without Tab selects single directory, no prefix
- Existing scripts and workflows continue to work
- Output format identical for single-directory runs

**Undesired Behavior**:
- Single directory workflows broken
- Unexpected prefixes added to single-directory output
- CLI behavior changed for single directory
- Existing automation scripts fail

#### REQ-020: Directory Deduplication

**Story**:
```
As a user
I want duplicate directory selections to be automatically removed
So that I don't accidentally process the same directory twice
```

**Acceptance Criteria**:
- Duplicate directories detected and removed before processing
- Warning message logged for each duplicate removed
- Processing continues with deduplicated list
- Absolute paths used for comparison (resolves `./dir` vs `dir`)

**Desired Behavior**:
- Selecting `./docs` and `docs` processes once
- WARN: "Duplicate directory removed: ./docs"
- Processing uses first occurrence
- Symlinks resolved before deduplication

**Undesired Behavior**:
- Same directory processed multiple times
- No warning about duplicates
- Duplicate detection fails for equivalent paths
- Wasteful duplicate processing

#### REQ-021: Overlapping Directory Detection

**Story**:
```
As a user
I want subdirectories of selected directories to be automatically excluded
So that I don't accidentally process files twice
```

**Acceptance Criteria**:
- System detects when one selected directory is subdirectory of another
- Subdirectory automatically excluded with INFO message
- Processing continues with non-overlapping directories
- Symlinks resolved before overlap detection

**Desired Behavior**:
- Selecting `./projects` and `./projects/frontend` excludes `frontend`
- INFO: "Excluding subdirectory: ./projects/frontend (contained in ./projects)"
- Only parent directory processed
- No duplicate file processing

**Undesired Behavior**:
- Subdirectories processed separately from parents
- Files processed multiple times
- No detection of directory overlap
- User must manually avoid selecting subdirectories

#### REQ-022: Abbreviated Source Prefixes

**Story**:
```
As a user processing multiple directories
I want output filenames to include abbreviated source directory prefixes
So that I can identify which source directory each file originated from
```

**Acceptance Criteria**:
- Output filenames use format `{prefix}--{filename}.{ext}` for multi-directory runs
- Prefix is shortest unique abbreviation of directory basename
- Prefix computation handles identical basenames using parent directory
- No prefix added for single-directory runs (backward compatibility)

**Desired Behavior**:
- Directories: `projects/frontend`, `projects/backend` → prefixes: `front--`, `back--`
- Output: `front--readme.pdf`, `back--readme.pdf`
- Identical basenames use parent: `a/docs` and `b/docs` → `a-docs--`, `b-docs--`
- Single directory: `readme.pdf` (no prefix)

**Undesired Behavior**:
- All files have same name, cannot distinguish source
- Prefixes too long (full directory path)
- No prefix computation, random or hash-based prefixes
- Prefixes added even for single directory

#### REQ-023: CLI Multi-Directory Support

**Story**:
```
As a user who wants to script or automate pndcgn
I want to pass multiple source directories via command line arguments
So that I can batch-process directories without interactive fzf selection
```

**Acceptance Criteria**:
- Multiple source directories accepted as positional arguments
- Explicit target directory via `--output`/`-o` flag OR `--` separator
- All source directories processed in single run
- Same abbreviated prefix behavior as fzf selection

**Desired Behavior**:
- `pndcgn src1/ src2/ src3/ -o output/` processes all three
- `pndcgn src1/ src2/ -- output/` alternative syntax
- All three directories processed sequentially
- Output files use abbreviated prefixes

**Undesired Behavior**:
- Cannot specify multiple directories via CLI
- Ambiguous which argument is target directory
- Each directory requires separate command
- CLI behavior differs from fzf selection

#### REQ-024: Selection Limit Enforcement

**Story**:
```
As a user
I want the system to enforce configured selection limits
So that I don't accidentally select too many directories
```

**Acceptance Criteria**:
- fzf prevents selection beyond configured limit
- CLI arguments exceeding limit rejected with error
- Error message shows limit and actual count
- Exit code 2 (USAGE error) for limit exceeded

**Desired Behavior**:
- fzf: 6th selection prevented when limit=5
- CLI: `pndcgn dir1 ... dir17 output/` → "ERROR: Too many source directories (max: 16, got: 17)"
- Exit code 2
- Processing does not start

**Undesired Behavior**:
- No limit enforcement
- Silent truncation of selections
- Generic error message
- Processing starts then fails

#### REQ-025: fzf Fallback for Unavailability

**Story**:
```
As a user on a system without fzf
I want a fallback selection mechanism
So that I can still use multi-directory selection
```

**Acceptance Criteria**:
- System detects when fzf unavailable
- Falls back to numbered list prompt
- User selects by entering comma-separated numbers
- Invalid input handled gracefully with user choice to continue or re-prompt

**Desired Behavior**:
- fzf unavailable → numbered list displayed
- Prompt: "Enter directory numbers (comma-separated, max 4): "
- User enters "1,3,5" → directories 1, 3, 5 selected
- Invalid entries shown, user chooses continue or re-prompt

**Undesired Behavior**:
- System fails when fzf unavailable
- No fallback mechanism
- Cryptic error message
- Multi-directory selection unavailable without fzf

#### REQ-026: Graceful Degradation on Directory Failure

**Story**:
```
As a user
I want processing to continue if one directory fails
So that I don't lose progress from a single problematic directory
```

**Acceptance Criteria**:
- System continues processing remaining directories if one fails
- Warning logged for failed directory
- Other directories processed successfully
- Final summary reports success/failure per directory

**Desired Behavior**:
- Directory `./secret` unreadable → WARN logged
- Processing continues with other directories
- Final summary: "3/4 directories processed successfully"
- Exit code 1 only if ALL directories fail

**Undesired Behavior**:
- Single failure stops entire run
- No indication which directory failed
- Partial processing not reported
- All-or-nothing behavior

#### REQ-027: Zero Directory Selection Handling

**Story**:
```
As a user
I want clear behavior when no directories are selected
So that I understand what will happen
```

**Acceptance Criteria**:
- ESC or Enter with nothing selected falls back to current directory
- Warning message indicates fallback behavior
- Matches existing single-directory behavior
- Processing proceeds with current directory

**Desired Behavior**:
- ESC pressed in fzf → falls back to current directory
- WARN: "No directories selected, using current directory"
- Processing proceeds with `./`
- Behavior matches existing single-directory mode

**Undesired Behavior**:
- System exits with error
- Unclear what happens with zero selection
- Unexpected behavior change
- No indication of fallback

#### REQ-028: fzf Header Display

**Story**:
```
As a user using fzf
I want to see the selection limit in the fzf header
So that I know how many directories I can select
```

**Acceptance Criteria**:
- fzf header displays maximum selection count
- Header format: "Select source directories (Tab=select, Enter=confirm, max=4)"
- Header updates dynamically with configured limit
- Clear indication of selection state

**Desired Behavior**:
- Header shows: "Select source directories (Tab=select, Enter=confirm, max=4)"
- Dynamic limit from config
- Clear instructions for user
- Visible throughout selection process

**Undesired Behavior**:
- No header or limit indication
- Static header not reflecting config
- Unclear how to select multiple
- No user guidance

#### REQ-029: Logging Conventions

**Story**:
```
As a user
I want consistent logging for multi-directory operations
So that I can understand what's happening
```

**Acceptance Criteria**:
- Uses existing pndcgn logging conventions (INFO/WARN/ERROR to stderr)
- Log messages follow existing format
- Per-directory status logged during processing
- Final summary includes per-directory breakdown

**Desired Behavior**:
- INFO: "Discovering files in: ./docs"
- WARN: "Duplicate directory removed: ./docs"
- ERROR: "Directory not readable: ./secret"
- Consistent format across all operations

**Undesired Behavior**:
- Inconsistent log formats
- Mix of stdout and stderr
- No per-directory status
- Confusing log messages

#### REQ-030: Symbolic Link Resolution

**Story**:
```
As a user using symbolic links
I want symlinks resolved before directory operations
So that I don't process the same directory twice via different paths
```

**Acceptance Criteria**:
- Symlinks resolved to real paths before deduplication
- Symlinks resolved before overlap detection
- Same physical directory not processed twice
- Resolution happens transparently

**Desired Behavior**:
- `./link` → `/real/path` resolved before processing
- `./link` and `/real/path` deduplicated correctly
- Overlap detection uses real paths
- User sees original symlink in logs/messages

**Undesired Behavior**:
- Symlink treated as separate directory
- Same directory processed multiple times
- Deduplication fails for symlinks
- Overlap detection fails

#### REQ-031: Configuration Limit Validation

**Story**:
```
As a user configuring max_source_dirs
I want invalid values handled gracefully
So that misconfiguration doesn't break the system
```

**Acceptance Criteria**:
- Values < 1 treated as invalid, use default (4) with warning
- Values > 16 capped at 16 with warning
- Non-integer values use default with warning
- Missing `[source]` section uses default silently

**Desired Behavior**:
- `max_source_dirs = 0` → WARN, uses default 4
- `max_source_dirs = 20` → WARN, caps at 16
- `max_source_dirs = "five"` → WARN, uses default 4
- No config → uses default 4 silently

**Undesired Behavior**:
- Invalid config crashes system
- Silent failure with invalid values
- No warning for misconfiguration
- System unusable with bad config

#### REQ-032: Config Change Without Restart

**Story**:
```
As a user
I want configuration changes to take effect without restarting the application
So that I can adjust settings quickly
```

**Acceptance Criteria**:
- Configuration read at startup of each pndcgn invocation
- Changes to pndcgn.toml take effect on next run
- No need to restart shell or background process
- Dynamic configuration loading

**Desired Behavior**:
- Edit `pndcgn.toml`, change `max_source_dirs = 8`
- Next `pndcgn` run uses new limit
- No restart required
- Configuration always fresh

**Undesired Behavior**:
- Requires application restart
- Cached configuration
- Changes not picked up
- Confusing behavior

#### REQ-033: All Directories Fail Handling

**Story**:
```
As a user
I want clear error handling when all selected directories fail
So that I understand what went wrong
```

**Acceptance Criteria**:
- Exit with error code 1 when ALL directories unreadable/fail
- Clear error message indicates no directories could be processed
- Different from single directory failure (which continues processing)
- User understands complete failure

**Desired Behavior**:
- All 3 directories unreadable → exit 1
- ERROR: "All selected directories are unreadable. No directories could be processed."
- Clear indication of complete failure
- Exit code 1 for runtime error

**Undesired Behavior**:
- Silent failure
- Unclear error message
- Exit code 0 (success) when all fail
- No indication of problem

#### REQ-034: Ctrl+C Graceful Handling

**Story**:
```
As a user processing many directories
I want Ctrl+C to complete current file conversion before stopping
So that I don't lose work in progress
```

**Acceptance Criteria**:
- SIGINT/SIGTERM trapped during multi-directory processing
- Current file conversion completes before stopping
- Summary of completed work logged
- Exit code 130 (interrupted)

**Desired Behavior**:
- Ctrl+C during processing → current file completes
- INFO: "Interrupted. Completed: 2/3 directories, 15/25 files"
- Clean exit with code 130
- Partial progress preserved

**Undesired Behavior**:
- Immediate exit, losing current file
- Corrupted output files
- No summary of progress
- Exit code unclear

#### REQ-035: Fallback Invalid Input Handling

**Story**:
```
As a user using the numbered list fallback
I want invalid input handled gracefully
So that I can correct mistakes without restarting
```

**Acceptance Criteria**:
- Invalid input (non-numeric, out of range) identified and shown
- User choice: continue with valid selections or re-prompt
- Keyboard shortcuts: 'c' to continue, 'r' to re-prompt
- Clear indication of which entries are invalid

**Desired Behavior**:
- User enters "1,abc,3,99" → "Invalid entries: abc (not a number), 99 (out of range)"
- Prompt: "Press 'c' to continue with valid selections (1,3) or 'r' to re-prompt"
- 'c' → proceeds with valid selections
- 'r' → re-displays numbered list

**Undesired Behavior**:
- System fails on invalid input
- Silent ignoring of invalid entries
- No way to correct mistakes
- Unclear what's invalid

## 4. Traceability Matrix

| Story ID | Title | System Test |
|----------|-------|-------------|
| REQ-001 | Prerequisites Verification | TEST-001 |
| REQ-002 | Configuration Initialization | TEST-002 |
| REQ-003 | Basic PDF Generation | TEST-003 |
| REQ-004 | Multi-Format Support | TEST-004 |
| REQ-005 | Intelligent Caching | TEST-005 |
| REQ-006 | Dependency Tracking | TEST-006 |
| REQ-007 | Force Regeneration | TEST-007 |
| REQ-008 | Dry Run Preview | TEST-008 |
| REQ-009 | Clean Specific Runs | TEST-009 |
| REQ-010 | Drop All Outputs | TEST-010 |
| REQ-011 | Interactive Source Selection (fzf) | TEST-011 |
| REQ-012 | Progress Indicators | TEST-012 |
| REQ-013 | Statistics Reporting | TEST-013 |
| REQ-014 | Run Resumption | TEST-014 |
| REQ-015 | Fingerprinting | TEST-015 |
| REQ-016 | Dry-Run Finalization | TEST-016 |
| REQ-017 | Multiple Directory Selection via fzf | TEST-017 |
| REQ-018 | Configurable Selection Limit | TEST-018 |
| REQ-019 | Backward Compatibility for Single Directory | TEST-019 |
| REQ-020 | Directory Deduplication | TEST-020 |
| REQ-021 | Overlapping Directory Detection | TEST-021 |
| REQ-022 | Abbreviated Source Prefixes | TEST-022 |
| REQ-023 | CLI Multi-Directory Support | TEST-023 |
| REQ-024 | Selection Limit Enforcement | TEST-024 |
| REQ-025 | fzf Fallback for Unavailability | TEST-025 |
| REQ-026 | Graceful Degradation on Directory Failure | TEST-026 |
| REQ-027 | Zero Directory Selection Handling | TEST-027 |
| REQ-028 | fzf Header Display | TEST-028 |
| REQ-029 | Logging Conventions | TEST-029 |
| REQ-030 | Symbolic Link Resolution | TEST-030 |
| REQ-031 | Configuration Limit Validation | TEST-031 |
| REQ-032 | Config Change Without Restart | TEST-032 |
| REQ-033 | All Directories Fail Handling | TEST-033 |
| REQ-034 | Ctrl+C Graceful Handling | TEST-034 |
| REQ-035 | Fallback Invalid Input Handling | TEST-035 |

**Note**: Test IDs map to shellspec tests in [100-system-test-plan.md](100-system-test-plan.md)

## 5. Navigation

[← Overview](010-overview.md) | [↑ Top](#requirements-specification) | [Next: Installation →](030-installation.md)
