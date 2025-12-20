# CLI Interface Contract: Multi-Directory Selection

**Feature**: 002-multi-dir-select
**Date**: 2925-12-18

---

<details><summary>Table of Contents</summary>>

- [CLI Interface Contract: Multi-Directory Selection](#cli-interface-contract-multi-directory-selection)
  - [1. Command Syntax](#1-command-syntax)
    - [1.1. Positional Arguments](#11-positional-arguments)
    - [1.2. Options (Extended)](#12-options-extended)
  - [2. Usage Examples](#2-usage-examples)
    - [2.1. Single Directory (Backward Compatible)](#21-single-directory-backward-compatible)
    - [2.2. Multiple Directories (New)](#22-multiple-directories-new)
    - [2.3. Edge Cases](#23-edge-cases)
  - [3. Exit Codes](#3-exit-codes)
  - [4. Output Format](#4-output-format)
    - [4.1. Standard Output](#41-standard-output)
    - [4.2. Standard Error](#42-standard-error)
  - [5. fzf Multi-Select Behavior](#5-fzf-multi-select-behavior)
    - [5.1. Invocation](#51-invocation)
    - [5.2. Selection Flow](#52-selection-flow)
    - [5.3. Output](#53-output)
  - [6. Fallback Selection (fzf Unavailable)](#6-fallback-selection-fzf-unavailable)
    - [6.1. Invocation](#61-invocation)
    - [6.2. Selection Flow](#62-selection-flow)
    - [6.3. Output](#63-output)
  - [7. Configuration Integration](#7-configuration-integration)
    - [7.1. pndcgn.toml](#71-pndcgntoml)
    - [7.2. Precedence](#72-precedence)
  - [8. Function Signatures](#8-function-signatures)
    - [8.1. New Functions](#81-new-functions)
    - [8.2. Modified Functions](#82-modified-functions)

</details>

---

## 1. Command Syntax

```text
pndcgn [OPTIONS] [SOURCE_DIR...] [TARGET_DIR]
```

### 1.1. Positional Arguments

| Position | Name | Required | Description |
|----------|------|----------|-------------|
| 1..N-1 | SOURCE_DIR | No* | Source directories to process |
| N | TARGET_DIR | No | Output directory |

*If no SOURCE_DIR provided, fzf multi-select is invoked (or falls back to current directory).

### 1.2. Options (Extended)

| Option | Short | Argument | Description |
|--------|-------|----------|-------------|
| `--type` | `-t` | TYPE | Output format: pdf, html, epub (default: pdf) |
| `--force` | `-f` | - | Bypass cache, regenerate all |
| `--dry-run` | `-n` | - | Preview without generating output |
| `--finalize` | - | RUN_ID | Complete a dry-run |
| `--resume` | `-r` | RUN_ID | Resume interrupted run |
| `--clean` | - | RUN_ID | Remove run artifacts |
| `--reseed` | - | - | Regenerate .pndcgnignore |
| `--verbose` | `-v` | - | Enable verbose output |
| `--yes` | `-y` | - | Non-interactive mode |
| `--help` | `-h` | - | Show help |
| `--version` | `-V` | - | Show version |

---

## 2. Usage Examples

### 2.1. Single Directory (Backward Compatible)

```bash
# Explicit source and target
pndcgn ./docs ./output

# Source only (target defaults to current dir)
pndcgn ./docs

# No args (fzf selection, single select still works)
pndcgn
```

### 2.2. Multiple Directories (New)

```bash
# Multiple sources via CLI
pndcgn ./docs ./notes ./specs ./output

# Multiple sources with options
pndcgn --type html ./docs ./notes ./output

# fzf multi-select (Tab to select multiple)
pndcgn  # launches fzf with multi-select enabled
```

### 2.3. Edge Cases

```bash
# Too many directories (error)
pndcgn dir1 dir2 ... dir17 output
# ERROR: Too many source directories (max: 16, got: 17)

# Over configured limit (error)
# With max_source_dirs = 4 in pndcgn.toml
pndcgn dir1 dir2 dir3 dir4 dir5 output
# ERROR: Too many source directories (max: 4, got: 5)

# Duplicate directories (deduplicated)
pndcgn ./docs ./docs ./output
# WARN: Duplicate directory removed: ./docs
# Processes ./docs once
```

---

## 3. Exit Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Operation completed successfully |
| 1 | ERROR | Runtime error (unreadable dir, conversion failure) |
| 2 | USAGE | Invalid usage (unknown option, too many dirs) |

---

## 4. Output Format

### 4.1. Standard Output

```text
Run ID: 01ABC123DEF456...

Processing 3 directories:
  [1/3] ./docs (12 files)
  [2/3] ./notes (5 files)
  [3/3] ./specs (8 files)

[============================] 100% (25/25 files)

✓ Run complete: 01ABC123DEF456...
  Output: ./output/.pndcgn/pdf-01ABC123DEF456.../
  Files: 25 processed, 0 skipped, 0 failed
  Time: 12.3s
```

### 4.2. Standard Error

```text
INFO: Discovering files in: ./docs
INFO: Discovering files in: ./notes
INFO: Discovering files in: ./specs
INFO: Found 25 files to process
WARN: Duplicate directory removed: ./docs
ERROR: Directory not readable: ./secret
```

---

## 5. fzf Multi-Select Behavior

### 5.1. Invocation

When no SOURCE_DIR arguments provided:

```bash
find . -type d -not -path '*/\.*' 2>/dev/null | \
    fzf --multi="$max_source_dirs" \
        --height 40% \
        --border \
        --header="Select source directories (Tab=select, Enter=confirm, max=$max_source_dirs)" \
        --preview='ls -la {}'
```

### 5.2. Selection Flow

1. User sees directory list
2. Tab key toggles selection (selected items marked with `>`)
3. Header shows: `Select source directories (Tab=select, Enter=confirm, max=4)`
4. When max reached, further Tab presses are ignored (fzf built-in behavior)
5. Enter confirms selection
6. ESC cancels (falls back to current directory)

### 5.3. Output

Selected directories returned as newline-separated list:

```text
./docs
./notes
./specs
```

---

## 6. Fallback Selection (fzf Unavailable)

When fzf is not installed or fails to launch, the system falls back to a numbered list prompt.

### 6.1. Invocation

```bash
# Display numbered directory list
[1] ./docs
[2] ./notes
[3] ./specs
[4] ./src
...

Enter directory numbers (comma-separated, max 4): 1,2,3
```

### 6.2. Selection Flow

1. Directories listed with sequential numbers (max 50 shown)
2. User enters comma-separated numbers (e.g., "1,3,5")
3. Invalid numbers silently ignored
4. If more than max selected, first N used with warning
5. Empty input falls back to current directory

### 6.3. Output

Same as fzf: newline-separated list of selected directories.

---

## 7. Configuration Integration

### 7.1. pndcgn.toml

```toml
[source]
max_source_dirs = 4  # Default limit for multi-select
```

### 7.2. Precedence

1. CLI argument count validated against limit
2. fzf `--multi=N` uses configured limit
3. If config value > 16, capped with warning
4. If config value < 1, use default (4) with warning

---

## 8. Function Signatures

### 8.1. New Functions

```bash
# Select multiple directories via fzf (or fallback to numbered list)
# Returns: newline-separated list of selected directories
# Exit: 0 on selection, 1 on cancel/error
pndcgn_select_source_dirs() -> string[]

# Fallback selection when fzf unavailable
# Args: max_dirs
# Returns: newline-separated list of selected directories
# Exit: 0 on selection, 1 on cancel/error
pndcgn_select_source_dirs_fallback(max_dirs) -> string[]

# Compute abbreviated prefixes for directory list
# Args: directory paths (variadic)
# Returns: newline-separated list of prefixes (same order as input)
pndcgn_compute_abbreviated_prefixes(dirs...) -> string[]

# Generate prefixed output filename
# Args: source_prefix, original_filename, output_type
# Returns: formatted filename
pndcgn_generate_prefixed_filename(prefix, name, type) -> string

# Parse max_source_dirs from TOML config
# Args: config_file_path
# Returns: integer (1-16), defaults to 4
pndcgn_parse_toml_max_source_dirs(config_path) -> int

# Validate source directory count against limit
# Args: count, limit
# Exit: 0 if valid, 2 if exceeded (with error message)
pndcgn_validate_source_count(count, limit) -> void

# Remove overlapping directories (subdirectories of other selected dirs)
# Args: directory paths (variadic)
# Returns: newline-separated list of non-overlapping directories
# Side effect: Logs INFO for each excluded subdirectory
pndcgn_remove_overlapping_dirs(dirs...) -> string[]
```

### 8.2. Modified Functions

```bash
# Extended to return multiple directories
# Old: pndcgn_select_source_dir() -> string (single)
# New: pndcgn_select_source_dirs() -> string[] (multiple, newline-separated)

# Extended to accept multiple source directories
# Old: pndcgn_db_create_run(source, target, type, dry_run)
# New: pndcgn_db_create_run(source_dirs_json, target, type, dry_run)
```

---
