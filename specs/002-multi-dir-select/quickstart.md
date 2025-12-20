# Quickstart: Multi-Directory Selection Implementation

**Feature**: 002-multi-dir-select
**Date**: 2925-12-18

---

<details><summary>Table of Contents</summary>

- [Quickstart: Multi-Directory Selection Implementation](#quickstart-multi-directory-selection-implementation)
  - [1. Overview](#1-overview)
  - [2. Prerequisites](#2-prerequisites)
  - [3. Implementation Order](#3-implementation-order)
    - [3.1. Phase 1: Core Infrastructure (P1 - Must Have)](#31-phase-1-core-infrastructure-p1---must-have)
      - [3.1.1. Step 1.1: Add Constants](#311-step-11-add-constants)
      - [3.1.2. Step 1.2: Extend TOML Parsing](#312-step-12-extend-toml-parsing)
      - [3.1.3. Step 1.3: Implement Multi-Select fzf (with Fallback)](#313-step-13-implement-multi-select-fzf-with-fallback)
      - [3.1.4. Step 1.4: Implement Abbreviated Prefix Algorithm](#314-step-14-implement-abbreviated-prefix-algorithm)
    - [3.2. Phase 2: Database Schema (P1 - Must Have)](#32-phase-2-database-schema-p1---must-have)
      - [3.2.1. Step 2.1: Extend Run Schema](#321-step-21-extend-run-schema)
      - [3.2.2. Step 2.2: Update Run Creation](#322-step-22-update-run-creation)
    - [3.3. Phase 3: CLI Integration (P1 - Must Have)](#33-phase-3-cli-integration-p1---must-have)
      - [3.3.1. Step 3.1: Update Argument Parsing](#331-step-31-update-argument-parsing)
    - [3.4. Phase 4: Output Filename Prefixing (P1 - Must Have)](#34-phase-4-output-filename-prefixing-p1---must-have)
      - [3.4.1. Step 4.1: Integrate Prefix Generation](#341-step-41-integrate-prefix-generation)
  - [4. Testing Strategy](#4-testing-strategy)
    - [4.1. Unit Tests](#41-unit-tests)
    - [4.2. Integration Tests](#42-integration-tests)
    - [4.3. Acceptance Tests](#43-acceptance-tests)
  - [5. Rollback Plan](#5-rollback-plan)

</details>

---

## 1. Overview

This guide provides step-by-step implementation instructions for adding multi-directory selection to pndcgn.

---

## 2. Prerequisites

- Existing pndcgn codebase with passing tests
- fzf installed (version 0.27+ for `--multi=N` support)
- SQLite 3.38+ (for JSON functions)

---

## 3. Implementation Order

### 3.1. Phase 1: Core Infrastructure (P1 - Must Have)

#### 3.1.1. Step 1.1: Add Constants

**File**: `src/constants.sh`

```bash
# Multi-directory selection limits
readonly PNDCGN_DEFAULT_MAX_SOURCE_DIRS=4
readonly PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS=16
```

#### 3.1.2. Step 1.2: Extend TOML Parsing

**File**: `src/utilities.sh`

Add function to parse `max_source_dirs` from config:

```bash
pndcgn_parse_toml_max_source_dirs() {
    local config_file="${1:-}"
    local default="${PNDCGN_DEFAULT_MAX_SOURCE_DIRS}"
    local max="${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS}"

    if [[ -z "$config_file" ]] || [[ ! -f "$config_file" ]]; then
        printf "%d" "$default"
        return 0
    fi

    local value
    value=$(awk -F'=' '/^\[source\]/,/^\[/ { if ($1 ~ /max_source_dirs/) { gsub(/[[:space:]]/, "", $2); print $2 } }' "$config_file")

    if [[ -z "$value" ]] || ! [[ "$value" =~ ^[0-9]+$ ]]; then
        printf "%d" "$default"
        return 0
    fi

    if [[ "$value" -lt 1 ]]; then
        pndcgn_log_warn "Invalid max_source_dirs ($value), using default ($default)"
        printf "%d" "$default"
        return 0
    fi

    if [[ "$value" -gt "$max" ]]; then
        pndcgn_log_warn "max_source_dirs ($value) exceeds maximum ($max), capping"
        printf "%d" "$max"
        return 0
    fi

    printf "%d" "$value"
}
```

#### 3.1.3. Step 1.3: Implement Multi-Select fzf (with Fallback)

**File**: `src/utilities.sh`

Replace `pndcgn_select_source_dir` with `pndcgn_select_source_dirs`:

```bash
pndcgn_select_source_dirs() {
    local max_dirs="${1:-$PNDCGN_DEFAULT_MAX_SOURCE_DIRS}"

    local selected
    if command -v fzf >/dev/null 2>&1; then
        # Use fzf if available
        selected=$(find . -type d -not -path '*/\.*' 2>/dev/null | \
            fzf --multi="$max_dirs" \
                --height 40% \
                --border \
                --header="Select source directories (Tab=select, Enter=confirm, max=$max_dirs)" \
                --preview='ls -la {}' 2>/dev/null)
    else
        # Fallback to numbered list prompt
        pndcgn_log_info "fzf not available, using numbered list selection"
        selected=$(pndcgn_select_source_dirs_fallback "$max_dirs")
    fi

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Resolve to absolute paths and deduplicate
    local -a dirs=()
    local -A seen=()
    while IFS= read -r dir; do
        local abs_dir
        abs_dir=$(cd "$dir" && pwd)
        if [[ -z "${seen[$abs_dir]:-}" ]]; then
            seen[$abs_dir]=1
            dirs+=("$abs_dir")
        else
            pndcgn_log_warn "Duplicate directory removed: $dir"
        fi
    done <<< "$selected"

    # Remove overlapping directories
    mapfile -t dirs < <(pndcgn_remove_overlapping_dirs "${dirs[@]}")

    printf '%s\n' "${dirs[@]}"
}

# Fallback selection when fzf is unavailable
pndcgn_select_source_dirs_fallback() {
    local max_dirs="$1"
    local -a all_dirs=()

    # List directories with numbers
    local i=1
    while IFS= read -r dir; do
        printf "[%d] %s\n" "$i" "$dir" >&2
        all_dirs+=("$dir")
        ((i++))
    done < <(find . -type d -not -path '*/\.*' 2>/dev/null | head -50)

    printf "\nEnter directory numbers (comma-separated, max %d): " "$max_dirs" >&2
    read -r selection

    # Parse selection (e.g., "1,3,5")
    local -a selected=()
    IFS=',' read -ra nums <<< "$selection"
    for num in "${nums[@]}"; do
        num=$(printf '%s' "$num" | tr -d '[:space:]')
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#all_dirs[@]} ]]; then
            selected+=("${all_dirs[$((num-1))]}")
        fi
    done

    if [[ ${#selected[@]} -gt $max_dirs ]]; then
        pndcgn_log_warn "Too many selections (max: $max_dirs), using first $max_dirs"
        selected=("${selected[@]:0:$max_dirs}")
    fi

    printf '%s\n' "${selected[@]}"
}

# Remove overlapping directories (subdirectories of other selected dirs)
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

#### 3.1.4. Step 1.4: Implement Abbreviated Prefix Algorithm

**File**: `src/utilities.sh`

```bash
pndcgn_compute_abbreviated_prefixes() {
    local -a dirs=("$@")
    local -a basenames=()
    local -a prefixes=()

    # Extract basenames
    for dir in "${dirs[@]}"; do
        basenames+=("${dir##*/}")
    done

    # Compute shortest unique prefix for each
    for i in "${!basenames[@]}"; do
        local name="${basenames[$i]}"
        local prefix_len=1
        local unique=false

        while [[ "$unique" == "false" ]] && [[ $prefix_len -le ${#name} ]]; do
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

        # Handle identical basenames - use parent dir
        if [[ "$unique" == "false" ]]; then
            local parent
            parent=$(dirname "${dirs[$i]}")
            parent="${parent##*/}"
            prefixes+=("${parent}-${name}")
        else
            prefixes+=("${name:0:$prefix_len}")
        fi
    done

    printf '%s\n' "${prefixes[@]}"
}

pndcgn_generate_prefixed_filename() {
    local prefix="$1"
    local original_name="$2"
    local output_type="$3"

    # Remove extension from original name
    local base_name="${original_name%.*}"

    # Sanitize prefix (replace non-alphanumeric with hyphen)
    local safe_prefix
    safe_prefix=$(printf '%s' "$prefix" | tr -c '[:alnum:]' '-' | tr -s '-')

    if [[ -n "$safe_prefix" ]]; then
        printf '%s--%s.%s' "$safe_prefix" "$base_name" "$output_type"
    else
        printf '%s.%s' "$base_name" "$output_type"
    fi
}
```

### 3.2. Phase 2: Database Schema (P1 - Must Have)

#### 3.2.1. Step 2.1: Extend Run Schema

**File**: `src/database.sh`

Update `pndcgn_db_init` to include migration:

```bash
# Add to schema creation/migration
sqlite3 "$db_file" <<'SQL'
-- Add source_dirs column if not exists
ALTER TABLE runs ADD COLUMN source_dirs TEXT;
SQL

# Ignore error if column already exists
```

#### 3.2.2. Step 2.2: Update Run Creation

**File**: `src/database.sh`

Modify `pndcgn_db_create_run`:

```bash
pndcgn_db_create_run() {
    local source_dirs_json="$1"  # JSON array of directories
    local target_path="$2"
    local output_type="$3"
    local is_dry_run="$4"

    # Extract first directory for backward compat
    local source_path
    source_path=$(printf '%s' "$source_dirs_json" | jq -r '.[0]')

    # ... rest of implementation

    sqlite3 "$db_file" <<SQL
INSERT INTO runs (run_id, source_path, source_dirs, target_path, output_type, is_dry_run, status, created_at)
VALUES ('$run_id', '$source_path', '$source_dirs_json', '$target_path', '$output_type', $is_dry_run, 'running', datetime('now'));
SQL
}
```

### 3.3. Phase 3: CLI Integration (P1 - Must Have)

#### 3.3.1. Step 3.1: Update Argument Parsing

**File**: `bin/pndcgn`

```bash
# Collect positional arguments
local -a positional_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type|-t) output_type="$2"; shift 2 ;;
        --force|-f) force=true; shift ;;
        # ... other options
        -*)
            pndcgn_fail "Unknown option: $1"
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done

# Parse source and target directories
local -a source_dirs=()
local target_dir=""

if [[ ${#positional_args[@]} -eq 0 ]]; then
    # No args - use fzf multi-select
    local max_dirs
    max_dirs=$(pndcgn_parse_toml_max_source_dirs "$config_file")
    mapfile -t source_dirs < <(pndcgn_select_source_dirs "$max_dirs")
    target_dir="."
elif [[ ${#positional_args[@]} -eq 1 ]]; then
    # Single arg - source only, target = current dir
    source_dirs=("${positional_args[0]}")
    target_dir="."
else
    # Multiple args - last is target, rest are sources
    target_dir="${positional_args[-1]}"
    source_dirs=("${positional_args[@]:0:${#positional_args[@]}-1}")
fi

# Validate count
local max_dirs
max_dirs=$(pndcgn_parse_toml_max_source_dirs "$config_file")
if [[ ${#source_dirs[@]} -gt $max_dirs ]]; then
    pndcgn_fail "Too many source directories (max: $max_dirs, got: ${#source_dirs[@]})"
fi
```

### 3.4. Phase 4: Output Filename Prefixing (P1 - Must Have)

#### 3.4.1. Step 4.1: Integrate Prefix Generation

**File**: `bin/pndcgn` (processing loop)

```bash
# Compute prefixes if multiple directories
local -a prefixes=()
if [[ ${#source_dirs[@]} -gt 1 ]]; then
    mapfile -t prefixes < <(pndcgn_compute_abbreviated_prefixes "${source_dirs[@]}")
fi

# In processing loop
for i in "${!source_dirs[@]}"; do
    local source_dir="${source_dirs[$i]}"
    local prefix=""
    [[ ${#source_dirs[@]} -gt 1 ]] && prefix="${prefixes[$i]}"

    # Discover files in this directory
    mapfile -t files < <(pndcgn_discover_files "$source_dir" "$ignore_file")

    for file in "${files[@]}"; do
        local output_name
        output_name=$(pndcgn_generate_prefixed_filename "$prefix" "${file##*/}" "$output_type")
        # ... process file
    done
done
```

---

## 4. Testing Strategy

### 4.1. Unit Tests

1. `pndcgn_parse_toml_max_source_dirs` - config parsing edge cases
2. `pndcgn_compute_abbreviated_prefixes` - prefix algorithm correctness
3. `pndcgn_generate_prefixed_filename` - filename formatting
4. `pndcgn_select_source_dirs` - fzf integration (mock fzf)
5. `pndcgn_select_source_dirs_fallback` - numbered list fallback
6. `pndcgn_remove_overlapping_dirs` - subdirectory detection and exclusion

### 4.2. Integration Tests

1. Multi-directory CLI invocation
2. fzf multi-select flow (requires TTY mock)
3. Database schema migration
4. End-to-end multi-directory processing

### 4.3. Acceptance Tests

Map to spec acceptance scenarios:
- US1.1-US1.4: Multi-directory selection via fzf
- US2.1-US2.3: Configuration limit enforcement
- US3.1-US3.2: Backward compatibility
- US4.1-US4.3: CLI multi-directory support

---

## 5. Rollback Plan

1. Schema change is additive (new column) - no rollback needed
2. New functions can be removed without breaking existing code
3. CLI changes are backward compatible - single arg still works
4. If issues arise, revert to single-directory mode by ignoring `source_dirs` column

---
