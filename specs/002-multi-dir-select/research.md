# Research: Multi-Directory Selection

**Feature**: 002-multi-dir-select
**Date**: 2925-12-18

---

<details><summary>Table of Contents</summary>

- [Research: Multi-Directory Selection](#research-multi-directory-selection)
  - [1. fzf Multi-Select API](#1-fzf-multi-select-api)
    - [1.1. Decision](#11-decision)
    - [1.2. Rationale](#12-rationale)
    - [1.3. Alternatives Considered](#13-alternatives-considered)
    - [1.4. Implementation Notes](#14-implementation-notes)
  - [2. Shortest Unique Prefix Algorithm](#2-shortest-unique-prefix-algorithm)
    - [2.1. Decision](#21-decision)
    - [2.2. Rationale](#22-rationale)
    - [2.3. Alternatives Considered](#23-alternatives-considered)
    - [2.4. Algorithm](#24-algorithm)
  - [3. SQLite JSON Storage for Multi-Source](#3-sqlite-json-storage-for-multi-source)
    - [3.1. Decision](#31-decision)
    - [3.2. Rationale](#32-rationale)
    - [3.3. Alternatives Considered](#33-alternatives-considered)
    - [3.4. Schema Change](#34-schema-change)
  - [4. CLI Argument Parsing Pattern](#4-cli-argument-parsing-pattern)
    - [4.1. Decision](#41-decision)
    - [4.2. Rationale](#42-rationale)
    - [4.3. Alternatives Considered](#43-alternatives-considered)
    - [4.4. Implementation Notes](#44-implementation-notes)
  - [5. fzf Unavailability Fallback](#5-fzf-unavailability-fallback)
    - [5.1. Decision](#51-decision)
    - [5.2. Rationale](#52-rationale)
    - [5.3. Alternatives Considered](#53-alternatives-considered)
    - [5.4. Implementation Notes](#54-implementation-notes)
  - [6. Overlapping Directory Detection](#6-overlapping-directory-detection)
    - [6.1. Decision](#61-decision)
    - [6.2. Rationale](#62-rationale)
    - [6.3. Alternatives Considered](#63-alternatives-considered)
    - [6.4. Implementation Notes](#64-implementation-notes)
  - [7. Summary](#7-summary)

</details>

---

## 1. fzf Multi-Select API

### 1.1. Decision

Use fzf's `--multi` flag with optional `-m N` limit parameter.

### 1.2. Rationale

- `--multi` enables Tab-based multi-selection (standard fzf behavior)
- `--multi=N` or `-m N` limits maximum selections (supported in fzf 0.27+)
- Selection count can be displayed in header via `--header` with dynamic update
- Exit code 0 on selection, 1 on cancel (ESC), 130 on interrupt

### 1.3. Alternatives Considered

- **Custom selection loop**: Rejected - reinvents fzf functionality, more code to maintain
- **Multiple fzf invocations**: Rejected - poor UX, no simultaneous view of options

### 1.4. Implementation Notes

```bash
# Multi-select with limit
find . -type d -not -path '*/\.*' | \
    fzf --multi="$max_dirs" \
        --height 40% \
        --border \
        --header="Select source directories (Tab to select, max $max_dirs)"
```

---

## 2. Shortest Unique Prefix Algorithm

### 2.1. Decision

Compute shortest distinguishing prefix by comparing directory basenames character-by-character.

### 2.2. Rationale

- Simple algorithm: O(n²) comparison is acceptable for max 16 directories
- Start with first character, extend until all prefixes unique
- Handle edge cases: identical basenames use full path component

### 2.3. Alternatives Considered

- **Trie-based algorithm**: Rejected - overkill for ≤16 items, adds complexity
- **Hash-based prefixes**: Rejected - not human-readable
- **Full directory name always**: Rejected - creates overlong filenames

### 2.4. Algorithm

```bash
pndcgn_compute_abbreviated_prefixes() {
    local -a dirs=("$@")
    local -a basenames=()
    local -a prefixes=()

    # Extract basenames
    for dir in "${dirs[@]}"; do
        basenames+=("${dir##*/}")
    done

    # For each basename, find shortest unique prefix
    for i in "${!basenames[@]}"; do
        local name="${basenames[$i]}"
        local prefix_len=1
        local unique=false

        while [[ $unique == false ]] && [[ $prefix_len -le ${#name} ]]; do
            local candidate="${name:0:$prefix_len}"
            unique=true

            for j in "${!basenames[@]}"; do
                [[ $i -eq $j ]] && continue
                local other="${basenames[$j]}"
                if [[ "${other:0:$prefix_len}" == "$candidate" ]]; then
                    unique=false
                    ((prefix_len++))
                    break
                fi
            done
        done

        prefixes+=("${name:0:$prefix_len}")
    done

    printf '%s\n' "${prefixes[@]}"
}
```

---

## 3. SQLite JSON Storage for Multi-Source

### 3.1. Decision

Store source directories as JSON array in `source_dirs` column, keep `source_path` for backward compatibility.

### 3.2. Rationale

- SQLite 3.38+ has native JSON functions (`json_array`, `json_extract`)
- Backward compatible: single-dir runs populate both columns
- Query flexibility: can extract individual paths or iterate

### 3.3. Alternatives Considered

- **Separate junction table**: Rejected - overcomplicated for max 16 entries
- **Comma-separated string**: Rejected - parsing issues with paths containing commas
- **Multiple rows per run**: Rejected - breaks run_id uniqueness semantics

### 3.4. Schema Change

```sql
-- Add new column (nullable for backward compat)
-- Note: SQLite doesn't have a native JSON column type - JSON data is stored as TEXT.
-- SQLite 3.38+ provides JSON functions (json_array, json_extract) that operate on TEXT
-- columns containing valid JSON. The source_dirs column stores a JSON array string.
ALTER TABLE runs ADD COLUMN source_dirs TEXT;  -- Stores JSON array as TEXT

-- Migration: populate from existing source_path
UPDATE runs SET source_dirs = json_array(source_path) WHERE source_dirs IS NULL;

-- New runs with multiple sources
INSERT INTO runs (run_id, source_path, source_dirs, target_path, output_type, is_dry_run)
VALUES (?, ?, json_array(?, ?, ?), ?, ?, ?);
-- source_path = first directory (for backward compat queries)
-- source_dirs = JSON array of all directories (stored as TEXT, queryable with json_extract)
```

---

## 4. CLI Argument Parsing Pattern

### 4.1. Decision

Last positional argument is target directory; all preceding positional arguments are source directories.

### 4.2. Rationale

- Consistent with common Unix tools (cp, mv, rsync)
- Unambiguous: `pndcgn src1 src2 src3 target/`
- Backward compatible: `pndcgn src target` still works

### 4.3. Alternatives Considered

- **Named flags**: `--source dir1 --source dir2 --target dir3` - Rejected, verbose
- **Separator token**: `pndcgn src1 src2 -- target` - Rejected, non-standard
- **Config file only**: Rejected - not scriptable

### 4.4. Implementation Notes

```bash
# Parse positional arguments
local -a positional_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --type|--force|...) # handle flags
            ;;
        *)
            positional_args+=("$1")
            ;;
    esac
    shift
done

# Interpret positional args
local target_dir="${positional_args[-1]}"
local -a source_dirs=("${positional_args[@]:0:${#positional_args[@]}-1}")

# Validate
if [[ ${#source_dirs[@]} -eq 0 ]]; then
    # No source dirs provided - use fzf or current directory
    source_dirs=("$(pndcgn_select_source_dirs)")
fi

if [[ ${#source_dirs[@]} -gt $max_source_dirs ]]; then
    pndcgn_fail "Too many source directories (max: $max_source_dirs)"
fi
```

---

## 5. fzf Unavailability Fallback

### 5.1. Decision

When fzf is not installed or fails to launch, fall back to a simple numbered list prompt.

### 5.2. Rationale

- Maintains functionality without requiring fzf as a hard dependency
- Aligns with Unix philosophy of graceful degradation
- Simple implementation using basic Bash read/select
- Users can still select multiple directories by entering comma-separated numbers

### 5.3. Alternatives Considered

- **Hard fail with error**: Rejected - poor UX, forces fzf installation
- **Fallback to current directory only**: Rejected - loses multi-select capability
- **Require `--source` flags**: Rejected - verbose, non-standard

### 5.4. Implementation Notes

```bash
pndcgn_select_source_dirs_fallback() {
    local max_dirs="$1"
    local -a dirs=()

    # List directories with numbers
    local i=1
    while IFS= read -r dir; do
        printf "[%d] %s\n" "$i" "$dir" >&2
        dirs+=("$dir")
        ((i++))
    done < <(find . -type d -not -path '*/\.*' 2>/dev/null | head -50)

    printf "\nEnter directory numbers (comma-separated, max %d): " "$max_dirs" >&2
    read -r selection

    # Parse selection (e.g., "1,3,5")
    local -a selected=()
    IFS=',' read -ra nums <<< "$selection"
    for num in "${nums[@]}"; do
        num=$(printf '%s' "$num" | tr -d '[:space:]')
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#dirs[@]} ]]; then
            selected+=("${dirs[$((num-1))]}")
        fi
    done

    if [[ ${#selected[@]} -gt $max_dirs ]]; then
        pndcgn_log_warn "Too many selections (max: $max_dirs), using first $max_dirs"
        selected=("${selected[@]:0:$max_dirs}")
    fi

    printf '%s\n' "${selected[@]}"
}
```

---

## 6. Overlapping Directory Detection

### 6.1. Decision

Detect when one selected directory is a subdirectory of another and automatically exclude the subdirectory with an INFO message.

### 6.2. Rationale

- Prevents duplicate file processing
- Most intuitive behavior for users who didn't realize the overlap
- Cleaner than prompting user to resolve manually
- INFO (not WARN) because it's a helpful automatic correction, not a problem

### 6.3. Alternatives Considered

- **Process both, deduplicate files**: Rejected - wastes processing time, complex logic
- **Prompt user to confirm**: Rejected - interrupts workflow
- **Error and require user fix**: Rejected - too strict for accidental overlap

### 6.4. Implementation Notes

```bash
pndcgn_remove_overlapping_dirs() {
    local -a dirs=("$@")
    local -a result=()

    for i in "${!dirs[@]}"; do
        local dir="${dirs[$i]}"
        local is_subdir=false

        for j in "${!dirs[@]}"; do
            [[ $i -eq $j ]] && continue
            local other="${dirs[$j]}"

            # Check if dir is subdirectory of other
            if [[ "$dir" == "$other"/* ]]; then
                pndcgn_log_info "Excluding subdirectory: $dir (contained in $other)"
                is_subdir=true
                break
            fi
        done

        [[ "$is_subdir" == "false" ]] && result+=("$dir")
    done

    printf '%s\n' "${result[@]}"
}
```

---

## 7. Summary

| Topic | Decision | Key Benefit |
|-------|----------|-------------|
| fzf multi-select | `--multi=N` flag | Native limit enforcement |
| Prefix algorithm | Character-by-character comparison | Simple, human-readable |
| SQLite storage | JSON array column | Flexible, backward compatible |
| CLI parsing | Last arg = target | Unix convention, unambiguous |
| fzf fallback | Numbered list prompt | Graceful degradation |
| Overlapping dirs | Auto-exclude subdirectory | Prevents duplicates |

---
