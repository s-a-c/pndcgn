# Feature Specification: Multi-Directory Selection via fzf

**Feature Branch**: `002-multi-dir-select`
**Created**: 2025-12-18
**Status**: Draft
**Input**: User description: "improve pndcgn to allow multiple directories to be selected from fzf. the number of selected directories allowed should be configurable, up to a maximum of 16"

---

<details><summary>Table of Contents</summary>

- [Feature Specification: Multi-Directory Selection via fzf](#feature-specification-multi-directory-selection-via-fzf)
  - [1. Clarifications](#1-clarifications)
    - [1.1. Session 2025-12-18](#11-session-2025-12-18)
  - [2. User Scenarios \& Testing *(mandatory)*](#2-user-scenarios--testing-mandatory)
    - [2.1. User Story 1 - Select Multiple Source Directories (Priority: P1)](#21-user-story-1---select-multiple-source-directories-priority-p1)
    - [2.2. User Story 2 - Configure Maximum Selection Limit (Priority: P2)](#22-user-story-2---configure-maximum-selection-limit-priority-p2)
    - [2.3. User Story 3 - Single Directory Selection Backward Compatibility (Priority: P3)](#23-user-story-3---single-directory-selection-backward-compatibility-priority-p3)
    - [2.4. User Story 4 - CLI Multi-Directory Support (Priority: P2)](#24-user-story-4---cli-multi-directory-support-priority-p2)
    - [2.5. Derived Feature - fzf Fallback (from FR-016)](#25-derived-feature---fzf-fallback-from-fr-016)
    - [2.6. Edge Cases](#26-edge-cases)
  - [3. Requirements *(mandatory)*](#3-requirements-mandatory)
    - [3.1. Functional Requirements](#31-functional-requirements)
    - [3.2. Key Entities](#32-key-entities)
  - [4. Success Criteria *(mandatory)*](#4-success-criteria-mandatory)
    - [4.1. Measurable Outcomes](#41-measurable-outcomes)
  - [5. Assumptions](#5-assumptions)

</details>

---

## 1. Clarifications

### 1.1. Session 2025-12-18

- Q: How should output files be organized when processing multiple source directories? → A: Flat structure with abbreviated source prefix in filename (e.g., `proj--file.pdf`, `docs--file.pdf`). Prefix is abbreviated to shortest unique form within the run to prevent overlong filenames. Algorithm: character-by-character comparison of directory basenames from start until unique (see research.md §2 for full algorithm).
- Q: Should users be able to pass multiple source directories directly via command line arguments? → A: Yes, support multiple paths as positional args (e.g., `pndcgn dir1 dir2 dir3 target/`)
- Q: What should happen when fzf is not installed or fails to launch? → A: Fallback to simple numbered list prompt (select by entering numbers)
- Q: What logging/observability approach should multi-directory operations use? → A: Follow existing pndcgn logging conventions (INFO/WARN/ERROR to stderr)
- Q: How should overlapping directories (subdirectory of another selected directory) be handled? → A: Detect overlap, exclude subdirectory automatically with INFO message
- Q: What happens when ALL selected directories are unreadable or fail? → A: Exit with error code 1 and clear error message
- Q: How should symbolic links (symlinks) be handled for directory selection? → A: Resolve symlinks to real paths before deduplication and overlap detection
- Q: How should invalid input in the fallback numbered list prompt be handled? → A: Show invalid entries and offer user choice: press 'c' to continue with valid selections only, or 'r' to re-prompt and correct selection
- Q: How should long-running multi-directory operations handle cancellation? → A: Support Ctrl+C with graceful cleanup (complete current file, then stop)
- Q: How should CLI multi-source disambiguate target directory? → A: Support both `--output`/`-o` flag AND `--` separator (e.g., `pndcgn src1 src2 -o target` or `pndcgn src1 src2 -- target`)

## 2. User Scenarios & Testing *(mandatory)*

### 2.1. User Story 1 - Select Multiple Source Directories (Priority: P1)

As a user with documents spread across multiple directories, I want to select several source directories at once using fzf so that I can process all of them in a single pndcgn run without running the command multiple times.

**Why this priority**: This is the core feature - without multi-select capability, the feature has no value. Users with organized document structures (e.g., separate folders for different projects or topics) need this to efficiently batch-process their documents.

**Independent Test**: Can be fully tested by launching pndcgn without arguments, using fzf multi-select (Tab key) to choose 2-3 directories, and verifying all selected directories are processed.

**Acceptance Scenarios**:

1. **Given** fzf is available and user launches pndcgn without source directory argument, **When** user uses Tab key to select multiple directories in fzf and presses Enter, **Then** all selected directories are processed in sequence
2. **Given** user has selected 3 directories via fzf, **When** processing begins, **Then** files from all 3 directories are discovered and converted
3. **Given** user selects directories via fzf, **When** the run completes, **Then** a single run ID is assigned covering all source directories
4. **Given** user selects directories `projects/frontend` and `projects/backend`, **When** processing completes, **Then** output files use abbreviated unique prefixes in format `{prefix}--{filename}` (e.g., `front--app.pdf`, `back--server.pdf`)

---

### 2.2. User Story 2 - Configure Maximum Selection Limit (Priority: P2)

As a power user, I want to configure the maximum number of directories I can select so that I can balance between flexibility and preventing accidental over-selection.

**Why this priority**: Configuration adds flexibility but the feature works with a sensible default. This allows customization without being essential for basic functionality.

**Independent Test**: Can be tested by setting a configuration value (e.g., `max_source_dirs = 5`), launching fzf selection, and verifying that only up to 5 directories can be selected.

**Acceptance Scenarios**:

1. **Given** user has configured `max_source_dirs = 5` in pndcgn.toml, **When** user attempts to select 6 directories in fzf, **Then** fzf prevents the 6th selection (fzf `--multi=5` flag enforces limit at selection time)
2. **Given** no configuration is set, **When** user selects directories, **Then** the default limit of 4 directories applies
3. **Given** user sets `max_source_dirs = 20` (above maximum), **When** pndcgn runs, **Then** the limit is capped at 16 with a warning message

---

### 2.3. User Story 3 - Single Directory Selection Backward Compatibility (Priority: P3)

As an existing user, I want the current single-directory selection behavior to continue working so that my existing workflows are not disrupted.

**Why this priority**: Backward compatibility ensures existing users aren't surprised by changed behavior. Single selection should remain the simplest path.

**Independent Test**: Can be tested by selecting only one directory via fzf (pressing Enter without Tab) and verifying it works exactly as before.

**Acceptance Scenarios**:

1. **Given** user launches fzf selection, **When** user selects a single directory and presses Enter (without using Tab), **Then** behavior is identical to current single-select mode (no abbreviated source prefix added to filenames)
2. **Given** user provides source directory as command-line argument, **When** pndcgn runs, **Then** fzf is not invoked and single directory is processed (existing behavior)

---

### 2.4. User Story 4 - CLI Multi-Directory Support (Priority: P2)

As a user who wants to script or automate pndcgn, I want to pass multiple source directories via command line arguments so that I can batch-process directories without interactive fzf selection.

**Why this priority**: Enables automation and CI/CD use cases. Important for power users but not essential for basic interactive usage.

**Independent Test**: Can be tested by running `pndcgn dir1 dir2 dir3 target/` and verifying all three source directories are processed.

**Acceptance Scenarios**:

1. **Given** user runs `pndcgn src1/ src2/ src3/ -o output/` or `pndcgn src1/ src2/ src3/ -- output/`, **When** processing completes, **Then** files from all three source directories are converted to the output directory
2. **Given** user passes more directories than the configured limit, **When** pndcgn runs, **Then** an error is displayed and processing does not start
3. **Given** user passes directories via CLI, **When** processing completes, **Then** output files use abbreviated unique prefixes just like fzf multi-select

---

### 2.5. Derived Feature - fzf Fallback (from FR-016)

When fzf is not installed or fails to launch, the system provides a fallback mechanism to maintain functionality.

**Behavior**: System falls back to a numbered list prompt, displaying directories with numbers and allowing selection by entering comma-separated numbers (e.g., "1,3,5").

**Invalid Input Handling**: When user enters invalid input (e.g., "abc", "1,x,3", numbers out of range), system shows which entries are invalid and offers user a choice: continue with valid selections only, or re-prompt to correct the selection.

**Note**: This is a derived feature from FR-016, not a user story. It enables graceful degradation when the primary selection mechanism (fzf) is unavailable.

---

### 2.6. Edge Cases

- What happens when user selects 0 directories (presses ESC or Enter with nothing selected)?
  - System falls back to current directory with a warning, matching current behavior
- What happens when one of the selected directories is unreadable?
  - System logs a warning for that directory and continues processing the remaining directories
- What happens when a directory becomes unreadable during processing (mid-processing state change)?
  - System logs a warning for that directory and continues processing the remaining directories (same as initial unreadable state - graceful degradation applies throughout processing)
- What happens when ALL selected directories are unreadable or fail?
  - System exits with error code 1 and a clear error message indicating no directories could be processed
- What happens when selected directories overlap (one is a subdirectory of another)?
  - System detects the overlap and automatically excludes the subdirectory, logging an INFO message explaining the exclusion
- What happens when the configured limit is set to 0 or negative?
  - System treats it as invalid and uses the default limit with a warning
- What happens when user selects the same directory multiple times?
  - System deduplicates the selection and processes it once
- How are symbolic links handled?
  - System resolves symlinks to real paths before deduplication and overlap detection, ensuring the same physical directory is not processed twice even if selected via different symlink paths
- What happens when two files from different directories have the same name?
  - Output files are distinguished by their abbreviated source directory prefix (e.g., `proj--file.pdf`, `docs--file.pdf`)
- What happens when directory names share common prefixes (e.g., `project-a`, `project-b`)?
  - System computes shortest unique abbreviation for each (e.g., `a--file.pdf`, `b--file.pdf` or `proj-a--file.pdf`, `proj-b--file.pdf`)

---

## 3. Requirements *(mandatory)*

### 3.1. Functional Requirements

- **FR-001**: System MUST allow users to select multiple directories using fzf's multi-select feature (Tab key)
- **FR-002**: System MUST process all selected directories in a single run, producing one combined output
- **FR-003**: System MUST enforce a configurable maximum selection limit, defaulting to 4 directories
- **FR-004**: System MUST cap the configurable limit at an absolute maximum of 16 directories
- **FR-005**: System MUST support configuration via `max_source_dirs` setting in pndcgn.toml under `[source]` section
- **FR-006**: System MUST maintain backward compatibility with single-directory selection (no Tab usage, no prefix)
- **FR-007**: System MUST deduplicate selected directories before processing
- **FR-008**: System MUST warn users when configured limit exceeds the absolute maximum (16). Warning format: `"max_source_dirs=$value exceeds maximum (16), capping at 16"` (logged as WARN to stderr)
- **FR-009**: System MUST display the number of selected directories in the fzf header/prompt
- **FR-010**: System MUST continue processing remaining directories if one directory fails (graceful degradation)
- **FR-011**: System MUST prefix output filenames with abbreviated source directory name when multiple directories are selected
- **FR-012**: System MUST compute the shortest unique prefix for each source directory within a run to prevent overlong filenames
- **FR-013**: System MUST NOT add abbreviated source prefix to filenames when only a single directory is processed (backward compatibility)
- **FR-014**: System MUST accept multiple source directories as positional CLI arguments with explicit target specification via `--output`/`-o` flag OR `--` separator (e.g., `pndcgn src1 src2 -o target/` or `pndcgn src1 src2 -- target/`)
- **FR-015**: System MUST reject CLI invocations that exceed the configured directory limit with a clear error message
- **FR-016**: System MUST fallback to a numbered list prompt when fzf is unavailable, allowing users to select directories by entering numbers
- **FR-017**: System MUST use existing pndcgn logging conventions (INFO/WARN/ERROR to stderr) for all multi-directory operations
- **FR-018**: System MUST detect overlapping directories (where one is a subdirectory of another) and automatically exclude the subdirectory with an INFO message. Message format: `"Excluding subdirectory: $subdir (contained in $parent_dir)"` (logged as INFO to stderr)
- **FR-019**: System MUST handle Ctrl+C gracefully during multi-directory processing by completing the current file conversion, then stopping with a summary of completed work

---

### 3.2. Key Entities

- **Source Directory List**: An ordered collection of 1-16 directory paths selected by the user for processing
- **Selection Limit Configuration**: A numeric setting (1-16) controlling maximum directories selectable, stored in pndcgn.toml
- **Run**: Extended to track multiple source directories instead of a single source path
- **Output Filename**: For multi-directory runs, format is `{abbreviated_source_prefix}--{original_filename}.{ext}`
- **Abbreviated Prefix**: Shortest unique substring of source directory name that distinguishes it from other selected directories in the same run

---

## 4. Success Criteria *(mandatory)*

### 4.1. Measurable Outcomes

- **SC-001**: Users can select and process up to 16 directories in a single command invocation
- **SC-002**: Configuration changes to `max_source_dirs` take effect without application restart
- **SC-003**: Single-directory workflows complete with no change in user experience or performance
- **SC-004**: Processing time for N directories scales linearly (no more than N× single-directory time plus 10% overhead)
- **SC-005**: Users can identify which source directory each output file originated from via abbreviated filename prefix and run index
- **SC-006**: Output filename prefixes are no longer than necessary to maintain uniqueness within the run

---

## 5. Assumptions

- fzf version supports multi-select mode (--multi flag) - this is a standard fzf feature available in all recent versions
- Users are familiar with fzf's Tab key for multi-select (standard fzf behavior)
- The default limit of 4 directories balances flexibility with preventing accidental mass-selection
- The absolute maximum of 16 directories prevents performance issues and user confusion
- Each selected directory is processed independently (no cross-directory file merging)
- Source directory names are filesystem-safe and can be used in output filenames (special characters will be sanitized)
- For CLI multi-source, target directory must be explicitly specified via `--output`/`-o` flag or `--` separator to avoid ambiguity
- Memory and resource usage scales linearly with number of directories (processing 16 directories requires ~16× single-directory memory, within reasonable limits for typical document sizes)

---
