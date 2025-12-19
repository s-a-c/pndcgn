#!/usr/bin/env bash
#
# pndcgn Processing Module
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: File discovery, fingerprinting, conversion, and output generation.

set -euo pipefail

# Source dependencies
. "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
. "$(dirname "${BASH_SOURCE[0]}")/utilities.sh"

# --- File Discovery ---
# Discover files respecting include/exclude patterns with proper evaluation order (NFR-TOML-044-045)
# Evaluation order: include patterns first, then exclude patterns (.pndcgnignore)
# File must match include (if any) AND not match exclude
pndcgn_discover_files() {
    local source_root="$1"
    local ignore_file="${2:-}"

    # Discover ignore file if not provided
    if [[ -z "$ignore_file" ]]; then
        ignore_file=$(pndcgn_discover_ignore_file "$source_root" || printf "")
    fi

    # Discover config file for include patterns
    local config_file
    config_file=$(pndcgn_discover_config_file "$source_root" 2>/dev/null || printf "")

    # Parse include patterns from TOML config (if available)
    local include_patterns=()
    if [[ -n "$config_file" ]] && [[ -f "$config_file" ]]; then
        local patterns_str
        patterns_str=$(pndcgn_parse_toml_patterns "$config_file" 2>/dev/null || printf "")
        if [[ -n "$patterns_str" ]]; then
            # Convert space-separated string to array
            read -r -a include_patterns <<< "$patterns_str"
        fi
    fi

    # Initialize allowed extensions from config or use defaults
    local allowed_extensions=()
    if [[ -n "$config_file" ]] && [[ -f "$config_file" ]]; then
        local extensions_str
        extensions_str=$(pndcgn_parse_toml_extensions "$config_file" 2>/dev/null || printf "")
        if [[ -n "$extensions_str" ]]; then
            # Convert space-separated string to array
            read -r -a allowed_extensions <<< "$extensions_str"
        fi
    fi
    # Default extensions if not specified in config (NFR-TOML-060)
    if [[ ${#allowed_extensions[@]} -eq 0 ]]; then
        allowed_extensions=(md markdown txt rst org html htm tex)
    fi

    local files=()
    local file

    # Find all markdown and text files (NFR-EDGE-007-009: symlink handling)
    while IFS= read -r -d '' file; do
        # Skip empty file paths
        if [[ -z "$file" ]]; then
            continue
        fi

        # Skip broken symlinks (NFR-EDGE-008)
        if [[ -L "$file" ]] && [[ ! -e "$file" ]]; then
            continue
        fi

        # Follow symlinks (NFR-EDGE-007) - resolve to actual file
        if [[ -L "$file" ]]; then
            local resolved_file
                        resolved_file=$(readlink -f "$file" 2>/dev/null || readlink "$file" 2>/dev/null || printf "%s" "$file")
            # Check for circular symlinks (NFR-EDGE-009)
            if [[ "$resolved_file" == "$file" ]] || [[ -z "$resolved_file" ]]; then
                continue  # Circular or invalid symlink
            fi
            file="$resolved_file"
        fi

        # Get base name for extension and system file checks
        local base_name="${file##*/}"

        # Skip system files that should never be processed (e.g., .pndcgnignore, .pndcgn)
        # Check base name first (most efficient) - this must come before extension checks
        if [[ "$base_name" == ".pndcgnignore" ]] || \
           [[ "$base_name" == ".pndcgn" ]] || \
           [[ "$file" == *"/.pndcgn/"* ]]; then
            continue
        fi
        # Skip ignore file itself if provided (check both absolute and relative paths)
        if [[ -n "$ignore_file" ]]; then
            # Normalize paths for comparison (handle both absolute and relative)
            local file_normalized="$file"
            local ignore_file_normalized="$ignore_file"
            # Remove trailing slashes if any
            file_normalized="${file_normalized%/}"
            ignore_file_normalized="${ignore_file_normalized%/}"
            # Compare normalized paths
            if [[ "$file_normalized" == "$ignore_file_normalized" ]] || \
               [[ "$file" == "$ignore_file" ]] || \
               [[ "${file_normalized##*/}" == "${ignore_file_normalized##*/}" ]] && [[ "${ignore_file_normalized##*/}" == ".pndcgnignore" ]]; then
                continue
            fi
        fi

        # Check file extension against allowed extensions (case-insensitive - NFR-TOML-017)
        # Support compound extensions (NFR-TOML-018: e.g., .md.txt, .markdown.bak)
        local file_ext
        # Try compound extensions first (longest match)
        ext_match=false
        for allowed_ext in "${allowed_extensions[@]}"; do
            # Check if file ends with .{allowed_ext} (case-insensitive)
            if [[ "${base_name,,}" == *".${allowed_ext,,}" ]]; then
                ext_match=true
                break
            fi
        done
        # If no compound match, try simple extension
        if [[ "$ext_match" != "true" ]]; then
            file_ext=$(printf "%s" "${file##*.}" | tr '[:upper:]' '[:lower:]')
            for allowed_ext in "${allowed_extensions[@]}"; do
                if [[ "$file_ext" == "$allowed_ext" ]]; then
                    ext_match=true
                    break
                fi
            done
        fi

        if [[ "$ext_match" != "true" ]]; then
            continue
        fi

        # Step 1: Apply include patterns first (NFR-TOML-044, NFR-TOML-046: OR evaluation)
        # If include patterns exist, file must match at least one (OR logic)
        if [[ ${#include_patterns[@]} -gt 0 ]]; then
            local matches_include=false
            local pattern
            # Get relative path from source_root
                        local rel_path="${file#"$source_root"/}"
            # Ensure source_root is removed (handle trailing slash)
            rel_path="${rel_path#/}"

            # Evaluate patterns with OR logic (NFR-TOML-046: match any pattern)
            for pattern in "${include_patterns[@]}"; do
                # Remove leading ! if present (exclude marker in pattern)
                local clean_pattern="${pattern#!}"
                # Remove leading/trailing whitespace
                clean_pattern="${clean_pattern#"${clean_pattern%%[![:space:]]*}"}"
                clean_pattern="${clean_pattern%"${clean_pattern##*[![:space:]]}"}"

                # Reject absolute path patterns (NFR-TOML-043)
                if [[ "$clean_pattern" == /* ]]; then
                    pndcgn_log_warn "Absolute path pattern rejected (use relative paths): $clean_pattern"
                    continue
                fi

                # Reject path traversal patterns (NFR-TOML-042)
                if [[ "$clean_pattern" == *../* ]] || [[ "$clean_pattern" == ../* ]]; then
                    pndcgn_log_warn "Path traversal pattern rejected: $clean_pattern"
                    continue
                fi

                # Handle brace expansion (NFR-TOML-011: {a,b,c} -> (a|b|c))
                if [[ "$clean_pattern" == *\{*\}* ]]; then
                    # Expand brace patterns: {a,b} -> (a|b) for glob matching
                    local expanded_pattern="$clean_pattern"
                    # Simple brace expansion: {a,b} -> (a|b)
                    if [[ "$expanded_pattern" =~ \{([^}]+)\} ]]; then
                        local brace_content="${BASH_REMATCH[1]}"
                        local expanded_alternatives
                        expanded_alternatives=$(printf "%s" "$brace_content" | tr ',' '|')
                        expanded_pattern="${expanded_pattern/\{$brace_content\}/\($expanded_alternatives\)}"
                        clean_pattern="$expanded_pattern"
                    fi
                fi

                # Handle pattern escaping (NFR-TOML-016: backslash escaping)
                # Preserve backslash-escaped characters (remove backslash, keep character)
                clean_pattern=$(printf "%s" "$clean_pattern" | sed 's/\\\(.\)/\1/g')

                # Convert ** to * for bash glob matching (simplified)
                # For proper ** matching, we'd need more complex logic, but this handles common cases
                local bash_pattern="${clean_pattern//\*\*/*}"

                # Simple glob matching (relative to source_root) - case-sensitive by default (NFR-TOML-015)
                # shellcheck disable=SC2053
                if [[ "$rel_path" == $bash_pattern ]] || [[ "$rel_path" == */$bash_pattern ]] || [[ "$rel_path" == $bash_pattern/* ]] || [[ "$file" == */$bash_pattern ]]; then
                    matches_include=true
                    break
                fi
                # Also try matching with ** as recursive (match any subdirectory)
                if [[ "$clean_pattern" == *\*\** ]]; then
                    local prefix="${clean_pattern%%\*\**}"
                    local suffix="${clean_pattern#*\*\*}"
                    # Check if rel_path starts with prefix and ends with suffix
                    if [[ "$rel_path" == $prefix* ]] && [[ "$rel_path" == *$suffix ]]; then
                        matches_include=true
                        break
                    fi
                fi
            done
            # Skip if doesn't match any include pattern
            if [[ "$matches_include" == "false" ]]; then
                continue
            fi
        fi

        # Step 2: Apply exclude patterns (.pndcgnignore) (NFR-TOML-045)
        # File must not match exclude patterns
        if [[ -n "$ignore_file" ]] && pndcgn_path_matches_ignore "$file" "$ignore_file"; then
            continue
        fi

        # File passed both include and exclude filters
        files+=("$file")
    done < <(find "$source_root" -type f -print0 2>/dev/null)

    # Output files (one per line for easy parsing)
    # Only output if there are files (avoid empty line for empty array)
    if [[ ${#files[@]} -gt 0 ]]; then
        printf "%s\n" "${files[@]}"
    fi
}

# --- Fingerprint Computation ---
# Compute input file fingerprint: {size}:{mtime}:{sha256_first_64KB}
pndcgn_compute_fingerprint() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    local size
    local mtime
    local sha256_hash

    # Get file size
    size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || printf "0")

    # Get modification time (integer seconds precision, UTC normalized - NFR-CACHE-004)
    # Use UTC to ensure consistency across timezones
    if command -v gdate >/dev/null 2>&1; then
        # Use gdate if available (GNU date) for UTC conversion
        mtime=$(gdate -r "$file_path" +%s 2>/dev/null || stat -f%m "$file_path" 2>/dev/null || stat -c%Y "$file_path" 2>/dev/null || printf "0")
    else
        mtime=$(stat -f%m "$file_path" 2>/dev/null || stat -c%Y "$file_path" 2>/dev/null || printf "0")
    fi
    # Ensure integer (remove any decimal if present)
    mtime=${mtime%.*}

    # Detect SHA256 implementation (NFR-CACHE-005)
    local sha256_cmd=""
    if command -v shasum >/dev/null 2>&1; then
        sha256_cmd="shasum -a 256"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256_cmd="sha256sum"
    fi

    # Compute SHA256 hash
    # For files <64KB: hash full content (NFR-CACHE-001)
    # For files >=64KB: hash first 64KB only
    # For empty files (0 bytes): hash empty string (NFR-CACHE-002)
    if [[ "$size" -eq 0 ]]; then
        # Empty file: SHA256 of empty string
        if [[ -n "$sha256_cmd" ]]; then
            sha256_hash=$(printf "" | $sha256_cmd | cut -d' ' -f1)
        else
            sha256_hash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"  # SHA256 of empty string
        fi
    elif [[ "$size" -lt 65536 ]]; then
        # File <64KB: hash full content
        if [[ -n "$sha256_cmd" ]]; then
            sha256_hash=$(cat "$file_path" | $sha256_cmd | cut -d' ' -f1)
        else
            # Fallback: use file size + mtime as fingerprint
            sha256_hash=$(printf "%s:%s" "$size" "$mtime" | shasum -a 256 2>/dev/null | cut -d' ' -f1 || printf "%s-%s" "$size" "$mtime")
        fi
    else
        # File >=64KB: hash first 64KB only
        if [[ -n "$sha256_cmd" ]]; then
            sha256_hash=$(head -c 65536 "$file_path" | $sha256_cmd | cut -d' ' -f1)
        else
            # Fallback: use file size + mtime as fingerprint
            sha256_hash=$(printf "%s:%s" "$size" "$mtime" | shasum -a 256 2>/dev/null | cut -d' ' -f1 || printf "%s-%s" "$size" "$mtime")
        fi
    fi

    # Include fingerprint version in output (NFR-CACHE-010: version embedding)
    # Format: v1:{size}:{mtime}:{sha256_hash}
    # Note: Version prefix allows future migration if fingerprint format changes
    printf "v1:%s:%s:%s" "$size" "$mtime" "$sha256_hash"
}

# --- Output Fingerprint Computation ---
# Compute output fingerprint: {total_size}:{artifact_count}:{sha256_of_all_content}
pndcgn_compute_output_fingerprint() {
    local output_dir="$1"

    if [[ ! -d "$output_dir" ]]; then
        return 1
    fi

    local total_size=0
    local artifact_count=0
    local content_hash=""

    # Collect all artifacts, sort by path for determinism
    local artifacts=()
    while IFS= read -r -d '' artifact; do
        artifacts+=("$artifact")
    done < <(find "$output_dir" -type f -print0 2>/dev/null | sort -z)

    artifact_count=${#artifacts[@]}

    # Compute total size and content hash
    local artifact
    local content=""
    for artifact in "${artifacts[@]}"; do
        if [[ -f "$artifact" ]]; then
            local size
            size=$(stat -f%z "$artifact" 2>/dev/null || stat -c%s "$artifact" 2>/dev/null || printf "0")
            total_size=$((total_size + size))

            # Append artifact content to hash input
            content="${content}$(cat "$artifact")"
        fi
    done

    # Compute SHA256 of all content
    if command -v shasum >/dev/null 2>&1; then
        content_hash=$(printf "%s" "$content" | shasum -a 256 | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        content_hash=$(printf "%s" "$content" | sha256sum | cut -d' ' -f1)
    else
        content_hash=$(printf "%s-%s" "$total_size" "$artifact_count")
    fi

    printf "%s:%s:%s" "$total_size" "$artifact_count" "$content_hash"
}

# --- Pandoc Conversion ---
# Convert file using pandoc (NFR-EDGE-056-057: crash handling)
pndcgn_convert_file() {
    local source_file="$1"
    local output_file="$2"
    local output_type="${3:-pdf}"

    if [[ ! -f "$source_file" ]]; then
        pndcgn_log_error "Source file not found: $source_file"
        return 1
    fi

    # Handle empty files (NFR-EDGE-020)
    if [[ ! -s "$source_file" ]]; then
        pndcgn_log_warn "Skipping empty file: $source_file"
        # Create empty output file
        touch "$output_file"
        return 0
    fi

    # Check for large files (NFR-EDGE-022: >100MB warning)
    local file_size
    file_size=$(stat -f%z "$source_file" 2>/dev/null || stat -c%s "$source_file" 2>/dev/null || printf "0")
    if [[ "$file_size" -gt 104857600 ]]; then  # 100MB in bytes
        pndcgn_log_warn "Large file may slow processing: $source_file ($(pndcgn_format_bytes "$file_size"))"
    fi

    # Check for binary files (NFR-EDGE-021)
    if ! file "$source_file" 2>/dev/null | grep -qiE "(text|ascii|utf-8|markdown)"; then
        # Simple heuristic: check for null bytes
        if head -c 1024 "$source_file" 2>/dev/null | grep -q $'\x00'; then
            pndcgn_log_warn "Skipping binary file: $source_file"
            return 1
        fi
    fi

    # Handle unusual encodings (NFR-EDGE-025-026: passthrough to pandoc)
    # Pandoc handles encoding detection automatically, so we pass files as-is

    # Check file permissions (NFR-EDGE-023)
    if [[ ! -r "$source_file" ]]; then
        pndcgn_log_warn "Skipping unreadable file: $source_file"
        pndcgn_log_info "Check file permissions: chmod +r '$source_file'"
        return 1
    fi

    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"

    # Run pandoc conversion with error handling (NFR-EDGE-056-057)
    # Pass files with unusual encodings/BOM as-is (NFR-EDGE-025-026: pandoc handles encoding)
    local pandoc_output
    pandoc_output=$(pandoc "$source_file" -o "$output_file" -t "$output_type" 2>&1)
    local pandoc_exit=$?

    if [[ $pandoc_exit -ne 0 ]]; then
        pndcgn_log_error "Pandoc conversion failed: $source_file -> $output_file"
        if [[ -n "$pandoc_output" ]]; then
            pndcgn_log_error "Pandoc error: $pandoc_output"
            # Output error to stderr for caller to capture
            printf "%s\n" "$pandoc_output" >&2
        fi
        # Clean up partial output
        [[ -f "$output_file" ]] && rm -f "$output_file"
        return 1
    fi

    return 0
}

# --- Output Directory Creation ---
# Create run output directory: ${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/
pndcgn_create_output_directory() {
    local target_dir="$1"
    local output_type="$2"
    local run_id="$3"

    local output_dir="$target_dir/.pndcgn/$output_type-$run_id"

    mkdir -p "$output_dir"

    printf "%s" "$output_dir"
}

# Generate prefixed output filename for multi-directory runs
# Args: source_prefix, original_filename, output_type
# Returns: formatted filename
# Format: {prefix}--{original_name}.{ext} for multi-dir, {original_name}.{ext} for single dir
pndcgn_generate_prefixed_filename() {
    local source_prefix="$1"
    local original_name="$2"
    local output_type="${3:-pdf}"

    # If prefix is empty, return simple filename (single directory, backward compatibility)
    if [[ -z "$source_prefix" ]]; then
        printf "%s.%s" "$original_name" "$output_type"
        return 0
    fi

    # Multi-directory: use prefix--name format
    printf "%s--%s.%s" "$source_prefix" "$original_name" "$output_type"
}

# --- Dewey Decimal Naming Scheme ---
# Generate Dewey Decimal-style prefix for file organization
pndcgn_dewey_prefix() {
    local file_path="$1"
    local source_root="$2"

    # Get relative path from source root
        local rel_path="${file_path#"$source_root"/}"

    # Extract directory components
        local dir_path
    dir_path=$(dirname "$rel_path")

    # Generate Dewey Decimal prefix from directory structure
    # Format: 001.002.003 (one number per directory level)
    local prefix=""
    local level=1

    IFS='/' read -ra dirs <<< "$dir_path"
    for dir in "${dirs[@]}"; do
        if [[ -n "$dir" ]] && [[ "$dir" != "." ]]; then
            # Convert directory name to number (simplified: use hash)
            local dir_num
            dir_num=$(printf "%s" "$dir" | shasum -a 256 2>/dev/null | cut -c1-3 | tr '[:lower:]' '[:upper:]' | sed 's/[^0-9]//g' || printf "%03d" "$level")
            # Ensure dir_num is numeric, default to level if empty
            if [[ -z "$dir_num" ]] || [[ ! "$dir_num" =~ ^[0-9]+$ ]]; then
                dir_num="$level"
            fi
            # Ensure 3-digit format (handle empty string case)
            if [[ "$dir_num" =~ ^[0-9]+$ ]]; then
                dir_num=$(printf "%03d" "$((10#$dir_num % 1000))")
            else
                dir_num=$(printf "%03d" "$level")
            fi
            prefix="${prefix}${prefix:+.}$dir_num"
            level=$((level + 1))
        fi
    done

    # Default prefix if empty (root-level file)
    [[ -z "$prefix" ]] && prefix="000"

    printf "%s" "$prefix"
}

# --- Index Generation ---
# Generate run index (_index.md) with navigation and statistics
pndcgn_generate_index() {
    local output_dir="$1"
    local run_id="$2"
    local stats_json="${3:-{}}"

    local index_file="$output_dir/_index.md"

    # Parse stats from JSON
    local total_files=0
    local processed_files=0
    local skipped_files=0
    local failed_files=0

    # Extract stats from JSON (simplified parsing)
    local total_files=0
    local processed_files=0
    local skipped_files=0
    local failed_files=0

    if [[ -n "$stats_json" ]] && [[ "$stats_json" != "{}" ]]; then
        if command -v jq >/dev/null 2>&1; then
            total_files=$(printf "%s" "$stats_json" | jq -r '.total // 0' 2>/dev/null || printf "0")
            processed_files=$(printf "%s" "$stats_json" | jq -r '.processed // 0' 2>/dev/null || printf "0")
            skipped_files=$(printf "%s" "$stats_json" | jq -r '.skipped // 0' 2>/dev/null || printf "0")
            failed_files=$(printf "%s" "$stats_json" | jq -r '.failed // 0' 2>/dev/null || printf "0")
        else
            # Fallback: simple grep-based extraction
            local total_match
            total_match=$(printf "%s" "$stats_json" | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || true)
            [[ -n "$total_match" ]] && total_files="$total_match"

            local processed_match
            processed_match=$(printf "%s" "$stats_json" | grep -o '"processed":[0-9]*' | grep -o '[0-9]*' || true)
            [[ -n "$processed_match" ]] && processed_files="$processed_match"

            local skipped_match
            skipped_match=$(printf "%s" "$stats_json" | grep -o '"skipped":[0-9]*' | grep -o '[0-9]*' || true)
            [[ -n "$skipped_match" ]] && skipped_files="$skipped_match"

            local failed_match
            failed_match=$(printf "%s" "$stats_json" | grep -o '"failed":[0-9]*' | grep -o '[0-9]*' || true)
            [[ -n "$failed_match" ]] && failed_files="$failed_match"
        fi
    fi

    # Get cache efficiency if available
    local cache_efficiency="N/A"
    # Ensure variables are numeric and default to 0
    skipped_files="${skipped_files:-0}"
    total_files="${total_files:-0}"
    # Convert to integers, defaulting to 0 if not numeric
    if [[ ! "$skipped_files" =~ ^[0-9]+$ ]]; then
        skipped_files=0
    fi
    if [[ ! "$total_files" =~ ^[0-9]+$ ]]; then
        total_files=0
    fi
    if [[ "$skipped_files" -gt 0 ]] && [[ "$total_files" -gt 0 ]]; then
        local efficiency_percent
        efficiency_percent=$((skipped_files * 100 / total_files))
        cache_efficiency="${efficiency_percent}%"
    fi

    # Generate index content
    cat > "$index_file" <<EOF
# pndcgn Run Index

**Run ID**: \`$run_id\`
**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Statistics

- **Total files discovered**: $total_files
- **Files processed**: $processed_files
- **Files skipped (cached)**: $skipped_files
- **Files failed**: $failed_files
- **Cache efficiency**: $cache_efficiency

## Generated Artifacts

EOF

    # List all generated artifacts
    find "$output_dir" -type f \( -name "*.pdf" -o -name "*.html" -o -name "*.epub" \) | sort | while read -r artifact; do
                local rel_path="${artifact#"$output_dir"/}"
        local basename
        basename="${artifact##*/}"
        # Use printf with explicit format to avoid option parsing issues
        printf -- "- [%s](%s)\n" "$basename" "$rel_path" >> "$index_file"
    done

    printf "\n---\n" >> "$index_file"
    printf "*Generated by pndcgn v%s*\n" "$PNDCGN_VERSION" >> "$index_file"
}

# --- Run Fingerprint Computation ---
# Compute combined fingerprint of all input files + config state
# Format: SHA256 of (sorted input fingerprints + config state + ignore file + config file)
pndcgn_compute_run_fingerprint() {
    local source_root="$1"
    local ignore_file="$2"
    local output_type="$3"
    local target_root="$4"

    # Discover all files
    local files
    mapfile -t files < <(pndcgn_discover_files "$source_root" "$ignore_file")

    # Compute fingerprint for each file and sort (deterministic ordering by path)
    local fingerprints=()
    for file in "${files[@]}"; do
        local fp
        fp=$(pndcgn_compute_fingerprint "$file")
        fingerprints+=("$fp")
    done

    # Sort fingerprints by file path for determinism (NFR-CACHE-007, NFR-CACHE-008)
    local old_ifs="${IFS:-}"
    IFS=$'\n'
    # Create array of "path|fingerprint" for sorting
    local path_fps=()
    local i=0
    for file in "${files[@]}"; do
        path_fps+=("$file|${fingerprints[$i]}")
        i=$((i + 1))
    done
    mapfile -t sorted_path_fps < <(printf '%s\n' "${path_fps[@]}" | sort -t'|' -k1)
    IFS="$old_ifs"

    # Extract sorted fingerprints
    fingerprints=()
    for path_fp in "${sorted_path_fps[@]}"; do
        fingerprints+=("${path_fp#*|}")
    done

    # Include config file content in fingerprint (NFR-TOML-006)
    local config_file
    config_file=$(pndcgn_discover_config_file "$source_root" 2>/dev/null || printf "")
    local config_hash="no-config"
    if [[ -n "$config_file" ]] && [[ -f "$config_file" ]]; then
        config_hash=$(cat "$config_file" 2>/dev/null | shasum -a 256 2>/dev/null | cut -d' ' -f1 || printf "no-config")
    fi

    # Combine with config state
    local config_state
    config_state=$(printf "%s\n%s\n%s\n%s\n%s" \
        "$output_type" \
        "$source_root" \
        "$target_root" \
        "$(cat "$ignore_file" 2>/dev/null | shasum -a 256 2>/dev/null | cut -d' ' -f1 || printf "no-ignore")" \
        "$config_hash")

    # Combine all fingerprints and config
    local combined
    local fingerprints_str=""
    if [[ ${#fingerprints[@]} -gt 0 ]]; then
        # Build fingerprints string safely
        for fp in "${fingerprints[@]}"; do
            if [[ -n "$fp" ]]; then
                fingerprints_str="${fingerprints_str}${fingerprints_str:+$'\n'}$fp"
            fi
        done
    fi
    if [[ -n "$fingerprints_str" ]]; then
        combined="${fingerprints_str}"$'\n'"${config_state}"
    else
        combined="$config_state"
    fi

    # Compute final SHA256
    local run_fingerprint
    if command -v shasum >/dev/null 2>&1; then
        run_fingerprint=$(printf "%s" "$combined" | shasum -a 256 | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        run_fingerprint=$(printf "%s" "$combined" | sha256sum | cut -d' ' -f1)
    else
        # Fallback: use simple hash
        run_fingerprint=$(printf "%s" "$combined" | wc -c | tr -d ' ')
    fi

    printf "%s" "$run_fingerprint"
}

# --- Fingerprint Validation ---
# Validate that current fingerprint matches stored fingerprint
pndcgn_validate_fingerprint() {
    local current_fingerprint="$1"
    local stored_fingerprint="$2"

    if [[ -z "$stored_fingerprint" ]]; then
        pndcgn_log_error "No stored fingerprint found for this run"
        return 1
    fi

    if [[ "$current_fingerprint" != "$stored_fingerprint" ]]; then
        pndcgn_log_error "Fingerprint mismatch detected"
        pndcgn_log_info "Stored:   ${stored_fingerprint:0:16}..."
        pndcgn_log_info "Current:  ${current_fingerprint:0:16}..."
        pndcgn_log_info "This indicates that source files or configuration have changed since the dry-run"
        pndcgn_log_info "Please create a new run or ensure inputs are unchanged"
        return 1
    fi

    return 0
}
