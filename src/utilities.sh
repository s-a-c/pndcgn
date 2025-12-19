#!/usr/bin/env bash
#
# pndcgn Utilities Module
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Helper functions for path resolution, logging, ULID generation,
# and prerequisite validation.
#
# Usage:
#   As library:    source src/utilities.sh
#   As executable: src/utilities.sh <function_name> [args...]
#
# Examples:
#   src/utilities.sh log_info "Hello world"
#   src/utilities.sh get_state_dir
#   src/utilities.sh check_prerequisites

set -euo pipefail

# --- Determine Script Location ---
# Works whether sourced or executed directly
# Only set if not already set (allows re-sourcing)
if [[ -z "${UTILITIES_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        UTILITIES_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
    readonly UTILITIES_DIR
fi

# Source constants (only if not already loaded)
# shellcheck source=./constants.sh
if [[ -z "${PNDCGN_VERSION:-}" ]]; then
    . "${UTILITIES_DIR}/constants.sh"
fi

# --- XDG Base Directory Support ---
# Get XDG state directory, falling back to ~/.local/state/pndcgn
# Handles HOME unset (NFR-TOML-053)
pndcgn_get_state_dir() {
    local home_dir="${HOME:-}"
        if [[ -z "${home_dir}" ]]; then
        pndcgn_log_error "HOME environment variable is not set"
        pndcgn_log_info "Please set HOME or XDG_STATE_HOME environment variable"
        return 1
    fi

        local state_dir="${XDG_STATE_HOME:-${home_dir}/.local/state}/pndcgn"
        mkdir -p "${state_dir}" 2>/dev/null || {
                pndcgn_log_error "Cannot create state directory: ${state_dir}"
        return 1
    }
        printf "%s" "${state_dir}"
}

# Get XDG config directory, falling back to ~/.config/pndcgn
# Handles HOME unset (NFR-TOML-053) and XDG_CONFIG_HOME with spaces (NFR-TOML-002-003)
pndcgn_get_config_dir() {
    local home_dir="${HOME:-}"
        if [[ -z "${home_dir}" ]]; then
        pndcgn_log_error "HOME environment variable is not set"
        pndcgn_log_info "Please set HOME or XDG_CONFIG_HOME environment variable"
        return 1
    fi

        local config_dir="${XDG_CONFIG_HOME:-${home_dir}/.config}/pndcgn"
    # Handle spaces in path by ensuring proper quoting in caller
        mkdir -p "${config_dir}" 2>/dev/null || {
                pndcgn_log_error "Cannot create config directory: ${config_dir}"
        return 1
    }
        printf "%s" "${config_dir}"
}

# --- Screen Reader Detection (NFR-CLI-018) ---
# Detect if running in a screen reader environment
pndcgn_is_screen_reader() {
    # Check for common screen reader environment variables
    [[ -n "${SCREENREADER:-}" ]] || \
    [[ -n "${ACCESSIBILITY_ENABLED:-}" ]] || \
    [[ "${TERM:-}" == "screenreader" ]] || \
    [[ "${TERM:-}" == "braille" ]] || \
    # Check for common screen reader processes
    pgrep -x "orca\|nvda\|jaws\|voiceover" >/dev/null 2>&1
}

# --- Structured Output for Screen Readers (NFR-CLI-018) ---
# Emit structured output that screen readers can parse
pndcgn_log_structured() {
    local level="$1"  # info, error, warn, success
    shift
    local message="$*"

    # shellcheck disable=SC2310
    if pndcgn_is_screen_reader; then
        # Structured format: [LEVEL] message
        local upper_level
        upper_level=${level^^}
        printf "[%s] %s\n" "${upper_level}" "${message}" >&2
    else
        # Regular formatted output
        case "${level}" in
            info)
                printf "${B_GREEN}INFO:${RESET} %s\n" "${message}" >&2
                ;;
            error)
                printf "${B_RED}ERROR:${RESET} %s\n" "${message}" >&2
                ;;
            warn)
                printf "${B_YELLOW}WARN:${RESET} %s\n" "${message}" >&2
                ;;
            success)
                printf "${B_SUCCESS}SUCCESS:${RESET} %s\n" "${message}" >&2
                ;;
            *)
                printf "${B_RED}ERROR:${RESET} %s\n" "Unknown log level: ${level}" >&2
                ;;
        esac
    fi
}

# --- Logging Functions ---
# Check if quiet mode is enabled (NFR-CLI-010)
pndcgn_is_quiet() {
    [[ "${PNDCGN_QUIET:-false}" == "true" ]]
}

pndcgn_log_info() {
    # shellcheck disable=SC2310
    if ! pndcgn_is_quiet; then
        pndcgn_log_structured "info" "$@"
    fi
}

pndcgn_log_error() {
    # Errors always shown, even in quiet mode
    pndcgn_log_structured "error" "$@"
}

pndcgn_log_warn() {
    # shellcheck disable=SC2310
    if ! pndcgn_is_quiet; then
        pndcgn_log_structured "warn" "$@"
    fi
}

# Verbose logging (only if verbose mode enabled)
pndcgn_log_verbose() {
    # shellcheck disable=SC2310
    if [[ "${PNDCGN_VERBOSE:-false}" == "true" ]] && ! pndcgn_is_quiet; then
        printf "${DIM}DEBUG:${RESET} %s\n" "$*" >&2
    fi
}

# --- Run ID Display Format (NFR-CLI-020-021) ---
# Format run ID for user display
pndcgn_format_run_id() {
    local run_id="$1"
    # Run IDs are ULID format (26 chars), display as-is
        printf "%s" "${run_id}"
}

# --- Duration Formatting (NFR-CLI-022) ---
# Format duration in human-readable format
pndcgn_format_duration() {
    local seconds="$1"

    if [[ "${seconds}" -lt 60 ]]; then
        printf "%ds" "${seconds}"
    elif [[ "${seconds}" -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local remaining_seconds=$((seconds % 60))
        if [[ ${remaining_seconds} -eq 0 ]]; then
            printf "%dm" "${minutes}"
        else
            printf "%dm %ds" "${minutes}" "${remaining_seconds}"
        fi
    else
        local hours=$((seconds / 3600))
        local remaining_minutes=$(((seconds % 3600) / 60))
        local remaining_seconds=$((seconds % 60))
        if [[ ${remaining_minutes} -eq 0 ]] && [[ ${remaining_seconds} -eq 0 ]]; then
            printf "%dh" "${hours}"
        elif [[ ${remaining_seconds} -eq 0 ]]; then
            printf "%dh %dm" "${hours}" "${remaining_minutes}"
        else
            printf "%dh %dm %ds" "${hours}" "${remaining_minutes}" "${remaining_seconds}"
        fi
    fi
}

# --- ETA Calculation (NFR-CLI-033) ---
# Calculate estimated time remaining based on progress
# Arguments: current_count, total_count, elapsed_seconds
pndcgn_calculate_eta() {
    local current="$1"
    local total="$2"
    local elapsed="$3"

    # Need at least some progress to calculate ETA
        if [[ "${current}" -eq 0 ]] || [[ "${elapsed}" -eq 0 ]]; then
        printf "calculating..."
        return 0
    fi

    # Calculate average time per item
    local avg_time_per_item
    avg_time_per_item=$((elapsed * 1000 / current))  # Use milliseconds for precision

    # Calculate remaining items
    local remaining
    remaining=$((total - current))

    # Calculate ETA in seconds
    local eta_seconds
    eta_seconds=$((avg_time_per_item * remaining / 1000))

    # Format ETA
        if [[ "${eta_seconds}" -lt 60 ]]; then
                printf "%ds" "${eta_seconds}"
        elif [[ "${eta_seconds}" -lt 3600 ]]; then
        local minutes=$((eta_seconds / 60))
                    printf "%dm" "${minutes}"
    else
        local hours=$((eta_seconds / 3600))
        local minutes=$(((eta_seconds % 3600) / 60))
        if [[ $minutes -eq 0 ]]; then
                        printf "%dh" "${hours}"
        else
            printf "%dh %dm" "$hours" "$minutes"
        fi
    fi
}

# --- Byte Size Formatting (NFR-CLI-023) ---
# Format byte size in human-readable format (KB, MB, GB, etc.)
pndcgn_format_bytes() {
    local bytes="$1"

        if [[ "${bytes}" -lt 1024 ]]; then
                printf "%dB" "${bytes}"
        elif [[ "${bytes}" -lt 1048576 ]]; then
        local kb=$((bytes / 1024))
                printf "%dKB" "${kb}"
        elif [[ "${bytes}" -lt 1073741824 ]]; then
        local mb=$((bytes / 1048576))
                printf "%dMB" "${mb}"
    else
        local gb=$((bytes / 1073741824))
                printf "%dGB" "${gb}"
    fi
}

# --- Confirmation Prompt (NFR-CLI-024-025) ---
# Prompt user for confirmation with valid responses
pndcgn_confirm() {
    local prompt="$1"
    local default="${2:-no}"  # Default to "no" if not provided

    # Check if non-interactive
        # shellcheck disable=SC2310
    if ! pndcgn_is_interactive; then
        return 1  # Non-interactive, default to no
    fi

    # Build prompt with default
    local full_prompt
        if [[ "${default}" == "yes" ]]; then
        full_prompt="${prompt} [Y/n]: "
    else
        full_prompt="${prompt} [y/N]: "
    fi

        printf "%s" "${full_prompt}" >&2
    read -r response

    # Normalize response
        response=$(printf "%s" "${response}" | tr '[:upper:]' '[:lower:]')

    # Handle empty response (use default)
        if [[ -z "${response}" ]]; then
                [[ "${default}" == "yes" ]]
        return $?
    fi

    # Check for valid responses
        case "${response}" in
        y|yes)
            return 0
            ;;
        n|no)
            return 1
            ;;
        *)
            # Invalid response, use default
                    [[ "${default}" == "yes" ]]
            return $?
            ;;
    esac
}

# --- Path Resolution ---
# Resolve absolute path, handling relative paths
pndcgn_resolve_path() {
    local path="$1"
    if [[ -z "$path" ]]; then
        pwd
    elif [[ "$path" == /* ]]; then
        printf "%s" "$path"
    elif [[ "$path" == "." ]]; then
        pwd
    else
        local dir_part
        dir_part=$(dirname "$path")
        local base_part
        base_part=$(basename "$path")
        if [[ "$dir_part" == "." ]]; then
            printf "%s/%s" "$(pwd)" "$base_part"
        else
            printf "%s/%s" "$(cd "$dir_part" && pwd)" "$base_part"
        fi
    fi
}

# --- Interactive Mode Detection ---
# Check if stdout is a TTY (interactive mode)
# Returns 0 (true) if interactive, 1 (false) if non-interactive
pndcgn_is_interactive() {
    if [[ -t 1 ]]; then
        return 0  # stdout is a TTY
    else
        return 1  # stdout is not a TTY (piped/redirected)
    fi
}

# --- Terminal Type Detection (NFR-CLI-016) ---
# Check TERM environment variable and adjust output accordingly
pndcgn_check_term() {
    local term="${TERM:-}"

    # If TERM is unset or set to "dumb", disable colors and animations
    if [[ -z "$term" ]] || [[ "$term" == "dumb" ]]; then
        export PNDCGN_NO_COLOR=true
        export PNDCGN_NO_ANIMATION=true
        return 1  # Terminal doesn't support advanced features
    fi

    # Check for color support based on TERM
    case "$term" in
        xterm*|screen*|tmux*|rxvt*|linux*|vt100*|ansi*)
            # These terminals support colors
            return 0
            ;;
        *)
            # Unknown terminal, assume basic support
            return 0
            ;;
    esac
}

# --- Progress Spinner (NFR-CLI-029-032) ---
# Simple spinner for indeterminate progress
pndcgn_spinner_start() {
    local message="${1:-Processing...}"

    # Check if animations are disabled
    if [[ "${PNDCGN_NO_ANIMATION:-false}" == "true" ]] || ! pndcgn_is_interactive; then
        printf "%s\n" "$message" >&2
        return 0
    fi

    # Store spinner state
    export PNDCGN_SPINNER_ACTIVE=true
    export PNDCGN_SPINNER_MESSAGE="$message"
    export PNDCGN_SPINNER_PID=""

    # Start spinner in background
    (
        local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while [[ "${PNDCGN_SPINNER_ACTIVE:-false}" == "true" ]]; do
            printf "\r${DIM}%s${RESET} %s" "${spinner_chars:$((i % ${#spinner_chars})):1}" "$message" >&2
            i=$((i + 1))
            sleep 0.1
        done
    ) &
    export PNDCGN_SPINNER_PID=$!
}

pndcgn_spinner_stop() {
    if [[ "${PNDCGN_SPINNER_ACTIVE:-false}" == "true" ]]; then
        export PNDCGN_SPINNER_ACTIVE=false
        if [[ -n "${PNDCGN_SPINNER_PID:-}" ]]; then
            kill "${PNDCGN_SPINNER_PID}" 2>/dev/null || true
            wait "${PNDCGN_SPINNER_PID}" 2>/dev/null || true
        fi
        printf "\r\033[K" >&2  # Clear line
    fi
}

# --- Prerequisite Validation ---
pndcgn_check_prerequisites() {
    local missing=()
    local cmd

    for cmd in pandoc sqlite3 curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        pndcgn_log_error "Missing required prerequisites: ${missing[*]}"
        pndcgn_log_info "Please install: ${missing[*]}"
        pndcgn_log_info "Installation suggestions:"
        for cmd in "${missing[@]}"; do
            case "$cmd" in
                pandoc)
                    pndcgn_log_info "  - pandoc: brew install pandoc (macOS) or apt-get install pandoc (Linux)"
                    ;;
                sqlite3)
                    pndcgn_log_info "  - sqlite3: brew install sqlite (macOS) or apt-get install sqlite3 (Linux)"
                    ;;
                curl)
                    pndcgn_log_info "  - curl: Usually pre-installed, or brew install curl / apt-get install curl"
                    ;;
            esac
        done
        return 1
    fi

    # Check pandoc version (NFR-EDGE-058: version incompatibility detection)
    if command -v pandoc >/dev/null 2>&1; then
        local pandoc_version
        pandoc_version=$(pandoc --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || printf "")
        if [[ -n "$pandoc_version" ]]; then
            local major_version
            major_version=$(printf "%s" "$pandoc_version" | cut -d. -f1)
            if [[ "$major_version" -lt 2 ]]; then
                pndcgn_log_warn "Pandoc version $pandoc_version detected. Version 2.0+ recommended for best compatibility."
            fi
        fi
    fi

    return 0
}

# --- ULID Generation Fallback (Bash implementation) ---
# Generates ULID when sqlite-ulid extension is unavailable
# Format: 26 characters, lexicographically sortable, timestamp-embedded
pndcgn_generate_ulid_fallback() {
    # ULID format: 10 chars timestamp + 16 chars randomness
    # Timestamp: milliseconds since Unix epoch (base32 encoded)
    # Random: 80 bits of randomness (base32 encoded)

    local timestamp_ms
    local ulid=""

    # Get timestamp in milliseconds
    if command -v gdate >/dev/null 2>&1; then
        timestamp_ms=$(gdate +%s%3N)
    else
        # Fallback: use seconds and append 000
        timestamp_ms=$(date +%s)000
    fi

    # Base32 alphabet (Crockford's base32, ULID-compatible)
    local base32_chars="0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    # Encode timestamp (10 chars)
    local ts="$timestamp_ms"
    while [[ ${#ulid} -lt 10 ]]; do
        local remainder=$((ts % 32))
        ulid="${base32_chars:$remainder:1}$ulid"
        ts=$((ts / 32))
    done

    # Generate random part (16 chars)
    local random_bytes
    if command -v openssl >/dev/null 2>&1; then
        random_bytes=$(openssl rand -hex 10)
    elif [[ -r /dev/urandom ]]; then
        random_bytes=$(od -An -N10 -tx1 /dev/urandom | tr -d ' \n')
    else
        # Fallback: use $RANDOM (less secure but functional)
        random_bytes=$(printf "%08x%08x" $RANDOM $RANDOM)
    fi

    # Convert hex to base32 (simplified - use first 16 chars of base32 encoding)
    local i=0
    while [[ $i -lt 16 ]]; do
        local byte_val=$((0x${random_bytes:$((i*2)):2}))
        local idx=$((byte_val % 32))
        ulid="${ulid}${base32_chars:$idx:1}"
        i=$((i + 1))
    done

    printf "%s" "$ulid"
}

# --- sqlite-ulid Extension Installation ---
# Downloads and installs sqlite-ulid extension for the current platform
pndcgn_install_ulid() {
    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local lib_dir="$script_dir/../lib"
    mkdir -p "$lib_dir"

    local platform
    local extension_url
    local extension_file

    # Detect platform
    case "$(uname -s)" in
        Darwin)
            platform="darwin"
            extension_file="ulid0.dylib"
            ;;
        Linux)
            platform="linux"
            extension_file="ulid0.so"
            ;;
        *)
            pndcgn_log_warn "Unsupported platform: $(uname -s). Using Bash fallback."
            return 1
            ;;
    esac

    # Detect architecture
    local arch
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            pndcgn_log_warn "Unsupported architecture: $(uname -m). Using Bash fallback."
            return 1
            ;;
    esac

    # Construct download URL (sqlite-ulid v0.2.1)
    extension_url="https://github.com/asg017/sqlite-ulid/releases/download/v0.2.1/ulid0-${platform}-${arch}.so"

    local target_file="$lib_dir/$extension_file"

    # Check if already installed
    if [[ -f "$target_file" ]]; then
        pndcgn_log_info "sqlite-ulid extension already installed: $target_file"
        printf "%s" "$target_file"
        return 0
    fi

    # Download extension
    pndcgn_log_info "Downloading sqlite-ulid extension..."
    if ! curl -Lf -o "$target_file" "$extension_url" 2>/dev/null; then
        pndcgn_log_warn "Failed to download sqlite-ulid extension. Using Bash fallback."
        rm -f "$target_file"
        return 1
    fi

    # Verify download
    if [[ ! -f "$target_file" ]] || [[ ! -s "$target_file" ]]; then
        pndcgn_log_warn "Downloaded file is invalid. Using Bash fallback."
        rm -f "$target_file"
        return 1
    fi

    pndcgn_log_info "sqlite-ulid extension installed: $target_file"
    printf "%s" "$target_file"
    return 0
}

# --- .pndcgnignore Management ---
# Discover .pndcgnignore file relative to source root
pndcgn_discover_ignore_file() {
    local source_root="$1"
    local ignore_file="$source_root/.pndcgnignore"

    if [[ -f "$ignore_file" ]]; then
        printf "%s" "$ignore_file"
        return 0
    fi

    return 1
}

# Seed .pndcgnignore from .gitignore using git-like stacking
pndcgn_seed_ignore_file() {
    local source_root="$1"
    local ignore_file="$source_root/.pndcgnignore"

    # Don't overwrite existing file
    if [[ -f "$ignore_file" ]]; then
        pndcgn_log_warn ".pndcgnignore already exists. Use --reseed to regenerate."
        return 0
    fi

    local ignore_content=""
    local seeded_from_gitignore=false

    # Collect .gitignore files manually (closest-first stacking)
    # This respects git's ignore stacking behavior by reading files directly
    local current_dir="$source_root"
    local gitignore_files=()

    # Walk up directory tree collecting .gitignore files
    while [[ "$current_dir" != "/" ]] && [[ "$current_dir" != "$HOME" ]]; do
        if [[ -f "$current_dir/.gitignore" ]]; then
            gitignore_files+=("$current_dir/.gitignore")
        fi
        current_dir=$(dirname "$current_dir")
    done

    # Reverse to get closest-first order
    local i
    for ((i=${#gitignore_files[@]}-1; i>=0; i--)); do
        if [[ -f "${gitignore_files[$i]}" ]]; then
            ignore_content="${ignore_content}${ignore_content:+$'\n'}$(cat "${gitignore_files[$i]}")"
            seeded_from_gitignore=true
        fi
    done

    # Ensure .pndcgn and .pndcgnignore are always ignored
    if [[ "$ignore_content" != *".pndcgn"* ]]; then
        ignore_content=".pndcgn${ignore_content:+$'\n'}$ignore_content"
    fi
    if [[ "$ignore_content" != *".pndcgnignore"* ]]; then
        ignore_content=".pndcgnignore${ignore_content:+$'\n'}$ignore_content"
    fi

    # Write ignore file
    printf "%s\n" "$ignore_content" > "$ignore_file"

    if [[ "$seeded_from_gitignore" == "true" ]]; then
        pndcgn_log_info "Created .pndcgnignore from .gitignore patterns"
    else
        pndcgn_log_info "Created .pndcgnignore with default patterns"
    fi

    return 0
}

# Check if a path matches ignore patterns (simplified gitignore-style matching)
# Handles malformed files gracefully (NFR-EDGE-061)
pndcgn_path_matches_ignore() {
    local path="$1"
    local ignore_file="$2"

    if [[ ! -f "$ignore_file" ]]; then
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$ignore_file" ]]; then
        pndcgn_log_warn "Cannot read ignore file: $ignore_file"
        return 1
    fi

    # Simple pattern matching (basic glob support)
    # For full gitignore semantics, consider using git check-ignore
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        # Skip comments and empty lines
        [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pattern// }" ]] && continue

        # Remove leading/trailing whitespace
        pattern="${pattern#"${pattern%%[![:space:]]*}"}"
        pattern="${pattern%"${pattern##*[![:space:]]}"}"

        # Simple glob matching (intentional glob expansion)
        # Check full path, basename, and path ending with pattern
                local basename_pattern="${path##*/}"
        # Try exact basename match first (quoted), then glob patterns (unquoted)
        # shellcheck disable=SC2053
        if [[ "$basename_pattern" == "$pattern" ]] || [[ "$path" == $pattern ]] || [[ "$path" == */$pattern ]] || [[ "$path" == $pattern/* ]] || [[ "$basename_pattern" == $pattern ]]; then
            return 0
        fi
    done < "$ignore_file" || {
        # Error reading file - return 1 (no match) to allow processing to continue
        return 1
    }

    return 1
}

# --- TOML Configuration File Management ---
# Discover pndcgn.toml config file (source directory first, then XDG config)
# Source directory config takes precedence when both exist (per contract)
# Returns: config file path if found, empty string if not found
# Handles symlinks (NFR-TOML-001) and XDG paths with spaces (NFR-TOML-002-003)
pndcgn_discover_config_file() {
    local source_dir="${1:-}"
    local xdg_config_dir
    local xdg_config_file
    local source_config_file

    # Check source directory config first (takes precedence)
    if [[ -n "$source_dir" ]] && [[ -d "$source_dir" ]]; then
        source_config_file="$source_dir/pndcgn.toml"
        # Follow symlinks (NFR-TOML-001)
        if [[ -L "$source_config_file" ]] || [[ -f "$source_config_file" ]]; then
            local resolved_file
                        resolved_file=$(readlink -f "$source_config_file" 2>/dev/null || readlink "$source_config_file" 2>/dev/null || printf "%s" "$source_config_file")
            if [[ -f "$resolved_file" ]]; then
                printf "%s" "$resolved_file"
                return 0
            fi
        fi
    fi

    # Fall back to XDG config directory (handles spaces in path - NFR-TOML-002-003)
    xdg_config_dir=$(pndcgn_get_config_dir 2>/dev/null || printf "")
    if [[ -n "$xdg_config_dir" ]]; then
        xdg_config_file="$xdg_config_dir/pndcgn.toml"
        if [[ -f "$xdg_config_file" ]]; then
            printf "%s" "$xdg_config_file"
            return 0
        fi
    fi

    # No config file found - return success with empty output
    return 0
}

# Parse TOML patterns array from [include] section
# Returns: space-separated list of patterns
# Handles multi-line arrays (NFR-TOML-023-024), comments (NFR-TOML-027),
# duplicate keys (NFR-TOML-030), and parse errors (NFR-TOML-033-034)
pndcgn_parse_toml_patterns() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # Check config file size limit (NFR-TOML-052: 1MB limit)
    local config_size
    config_size=$(stat -f%z "$config_file" 2>/dev/null || stat -c%s "$config_file" 2>/dev/null || printf "0")
    if [[ "$config_size" -gt 1048576 ]]; then  # 1MB in bytes
        pndcgn_log_warn "Config file exceeds 1MB limit: $config_file ($(pndcgn_format_bytes "$config_size"))"
        pndcgn_log_warn "Parsing may be slow or incomplete"
    fi

    # AWK-based parsing for [include] patterns array
    # Handles both multi-line and inline array syntax (NFR-TOML-023-024)
    # Comments are already handled (lines starting with #) (NFR-TOML-027)
    # TOML escape sequences (NFR-TOML-026: basic handling - unescape common sequences)
    awk -f - "$config_file" <<'AWK_SCRIPT'
        BEGIN { in_include = 0; in_array = 0; patterns = ""; line_num = 0 }
        { line_num++ }
        # Skip comments (NFR-TOML-027)
        /^[[:space:]]*#/ { next }
        /^\[include\]/ { in_include = 1; next }
        /^\[/ { in_include = 0; in_array = 0 }

        # Helper function to unescape TOML escape sequences (NFR-TOML-026)
        function unescape_toml(str) {
            gsub(/\\n/, "\n", str)
            gsub(/\\t/, "\t", str)
            gsub(/\\r/, "\r", str)
            gsub(/\\"/, "\"", str)
            gsub(/\\\\/, "\\", str)
            return str
        }
        in_include && /^patterns[[:space:]]*=[[:space:]]*\[/ {
            # Found patterns = [ ... ]
            in_array = 1
            # Extract content after the opening [
            line = $0
            sub(/^[^[]*\[/, "", line)
            # Check if array closes on same line
            if (line ~ /\].*$/) {
                sub(/\].*$/, "", line)
                in_array = 0
            }
            # Process this line's content
            if (length(line) > 0) {
                # Unescape TOML escape sequences (NFR-TOML-026)
                line = unescape_toml(line)
                gsub(/[",]/, " ", line)
                gsub(/\x27/, " ", line)
                gsub(/^[ \t]+|[ \t]+$/, "", line)
                if (length(line) > 0) patterns = patterns " " line
            }
            next
        }
        in_include && in_array {
            # Continuation of array (multi-line)
            line = $0
            # Check if array closes on this line
            if (line ~ /\].*$/) {
                sub(/\].*$/, "", line)
                in_array = 0
            }
            # Remove quotes and commas, unescape TOML sequences (NFR-TOML-026)
            line = unescape_toml(line)
            gsub(/[",]/, " ", line)
            gsub(/\x27/, " ", line)
            gsub(/^[ \t]+|[ \t]+$/, "", line)
            if (length(line) > 0) patterns = patterns " " line
        }
        END {
            gsub(/^[ \t]+|[ \t]+$/, "", patterns)
            if (length(patterns) > 0) print patterns
            # Note: Duplicate key handling (NFR-TOML-030) - last occurrence wins (AWK behavior)
            # Parse error reporting (NFR-TOML-033-034) - AWK will fail on syntax errors
        }
AWK_SCRIPT
    local awk_exit=$?
    if [[ $awk_exit -ne 0 ]]; then
        # Parse error occurred (NFR-TOML-033-034, NFR-TOML-038-040: validation error format)
        pndcgn_log_warn "TOML parse error in $config_file (check syntax)"
        pndcgn_log_info "Error format: Config warning: $config_file: parse error"
        return 1
    fi
}

# Parse TOML extensions array from [include.types] section
# Returns: space-separated list of extensions
pndcgn_parse_toml_extensions() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # AWK-based parsing for [include.types] extensions array
    # Handles both multi-line and inline array syntax
    awk -f - "$config_file" <<'AWK_SCRIPT'
        BEGIN { in_types = 0; in_array = 0; extensions = "" }
        /^\[include\.types\]/ { in_types = 1; next }
        /^\[/ { in_types = 0; in_array = 0 }
        in_types && /^extensions[[:space:]]*=[[:space:]]*\[/ {
            # Found extensions = [ ... ]
            in_array = 1
            # Extract content after the opening [
            line = $0
            sub(/^[^[]*\[/, "", line)
            # Check if array closes on same line
            if (line ~ /\].*$/) {
                sub(/\].*$/, "", line)
                in_array = 0
            }
            # Process this line's content
            if (length(line) > 0) {
                gsub(/[",]/, " ", line)
                gsub(/\x27/, " ", line)
                gsub(/^[ \t]+|[ \t]+$/, "", line)
                if (length(line) > 0) extensions = extensions " " line
            }
            next
        }
        in_types && in_array {
            # Continuation of array (multi-line)
            line = $0
            # Check if array closes on this line
            if (line ~ /\].*$/) {
                sub(/\].*$/, "", line)
                in_array = 0
            }
            # Remove quotes and commas
            gsub(/[",]/, " ", line)
            gsub(/\x27/, " ", line)
            gsub(/^[ \t]+|[ \t]+$/, "", line)
            if (length(line) > 0) extensions = extensions " " line
        }
        END {
            gsub(/^[ \t]+|[ \t]+$/, "", extensions)
            if (length(extensions) > 0) print extensions
        }
AWK_SCRIPT
}

# Parse max_source_dirs from [source] section in pndcgn.toml
# Returns: integer value (1-16), defaults to 4 if not configured
# Args: config_file_path
# Exit: 0 on success (or config missing), 1 on parse error
# Side effects: Logs WARN to stderr if invalid value found
pndcgn_parse_toml_max_source_dirs() {
    local config_file="$1"

    # If config file doesn't exist, return default
    if [[ ! -f "$config_file" ]]; then
        printf "%d" "${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        return 0
    fi

    # Extract max_source_dirs from [source] section using AWK
    local value
    value=$(awk -f - "$config_file" <<'AWK_SCRIPT'
        BEGIN { in_source = 0; value = "" }
        # Skip comments
        /^[[:space:]]*#/ { next }
        # Track [source] section
        /^\[source\]/ { in_source = 1; next }
        /^\[/ { in_source = 0; next }
        # Extract max_source_dirs value in [source] section
        in_source && /^[[:space:]]*max_source_dirs[[:space:]]*=[[:space:]]*/ {
            # Extract value after =
            sub(/^[^=]*=[[:space:]]*/, "", $0)
            # Remove quotes if present
            gsub(/^["'\'']|["'\'']$/, "", $0)
            # Trim whitespace
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            value = $0
            # Last occurrence wins (AWK behavior)
        }
        END {
            if (length(value) > 0) print value
        }
AWK_SCRIPT
    )

    # If not found in config, return default
    if [[ -z "$value" ]]; then
        printf "%d" "${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        return 0
    fi

    # Validate and normalize value
    # Check if it's a valid integer
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        pndcgn_log_warn "Invalid max_source_dirs value in $config_file: '$value' (not an integer), using default ${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        printf "%d" "${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        return 0
    fi

    # Convert to integer for comparison
    local int_value=$((value))

    # Validate range: < 1 → use default
    if [[ $int_value -lt 1 ]]; then
        pndcgn_log_warn "Invalid max_source_dirs value in $config_file: $int_value (< 1), using default ${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        printf "%d" "${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        return 0
    fi

    # Validate range: > 16 → cap at 16 with warning
    if [[ $int_value -gt "${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS:-16}" ]]; then
        pndcgn_log_warn "max_source_dirs=$int_value exceeds maximum (${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS:-16}), capping at ${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS:-16}"
        printf "%d" "${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS:-16}"
        return 0
    fi

    # Valid value, return it
    printf "%d" "$int_value"
    return 0
}

# Compute abbreviated prefixes for directory list
# Args: directory paths (variadic, 1 or more)
# Returns: newline-separated list of prefixes (same order as input)
# Algorithm: character-by-character comparison to find shortest unique prefix
# Handles identical basenames by using parent directory name
pndcgn_compute_abbreviated_prefixes() {
    local -a dirs=("$@")

    if [[ ${#dirs[@]} -eq 0 ]]; then
        return 0
    fi

    local -a basenames=()
    local -a dirnames=()  # Parent directory names for disambiguation
    local -a prefixes=()

    # Extract basenames and parent directory names
    for dir in "${dirs[@]}"; do
        local basename="${dir##*/}"
        basenames+=("$basename")

        # Get parent directory name (second-to-last path component)
        local parent_dir="${dir%/*}"
        if [[ "$parent_dir" == "$dir" ]]; then
            # No parent (root or single component)
            dirnames+=("")
        else
            dirnames+=("${parent_dir##*/}")
        fi
    done

    # For each basename, find shortest unique prefix
    for i in "${!basenames[@]}"; do
        local name="${basenames[$i]}"
        local prefix_len=1
        local unique=false

        # Try to find unique prefix by comparing characters
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

        local prefix="${name:0:$prefix_len}"

        # If we still don't have uniqueness at full length, use parent directory
        if [[ $unique == false ]] || [[ $prefix_len -gt ${#name} ]]; then
            local parent="${dirnames[$i]}"
            if [[ -n "$parent" ]]; then
                # Use parent directory name as prefix component
                # Sanitize parent name (replace non-alphanumeric with hyphens)
                local sanitized_parent
                sanitized_parent=$(printf "%s" "$parent" | sed 's/[^[:alnum:]]/-/g')
                prefix="${sanitized_parent}-${name}"
            else
                # No parent, use full basename
                prefix="$name"
            fi
        fi

        # Sanitize prefix: replace non-alphanumeric chars with hyphens
        prefix=$(printf "%s" "$prefix" | sed 's/[^[:alnum:]]/-/g')

        prefixes+=("$prefix")
    done

    printf '%s\n' "${prefixes[@]}"
}

# Remove overlapping directories (subdirectories of other selected directories)
# Args: directory paths (variadic, 1 or more, should be absolute paths)
# Returns: newline-separated list of non-overlapping directories
# Side effect: Logs INFO message to stderr for each excluded subdirectory
# Algorithm: Check if any directory is a subdirectory (path prefix match) of another
pndcgn_remove_overlapping_dirs() {
    local -a dirs=("$@")

    if [[ ${#dirs[@]} -eq 0 ]]; then
        return 0
    fi

    local -a result=()

    # For each directory, check if it's a subdirectory of any other
    for i in "${!dirs[@]}"; do
        local dir="${dirs[$i]}"
        local is_subdir=false

        # Normalize path (remove trailing slash if present)
        dir="${dir%/}"

        for j in "${!dirs[@]}"; do
            [[ $i -eq $j ]] && continue
            local other="${dirs[$j]}"
            other="${other%/}"  # Normalize

            # Check if dir is subdirectory of other (path prefix match)
            # Example: /path/to/projects/frontend is subdirectory of /path/to/projects
            if [[ "$dir" == "$other"/* ]]; then
                pndcgn_log_info "Excluding subdirectory: $dir (contained in $other)"
                is_subdir=true
                break
            fi
        done

        # If not a subdirectory, include in result
        if [[ "$is_subdir" == "false" ]]; then
            result+=("$dir")
        fi
    done

    printf '%s\n' "${result[@]}"
}

# Validate source directory count against configured limit
# Args: count (number of source directories), limit (maximum allowed)
# Exit: 0 if valid, 2 if exceeded (with error message to stderr)
# Side effects: Logs error message to stderr if count exceeds limit
pndcgn_validate_source_count() {
    local count="$1"
    local limit="$2"

    # Convert to integers for comparison
    local int_count=$((count))
    local int_limit=$((limit))

    if [[ $int_count -gt $int_limit ]]; then
        pndcgn_log_error "Too many source directories (max: $int_limit, got: $int_count)"
        return 2
    fi

    return 0
}

# Convert bash array to JSON array string
# Args: array elements (variadic)
# Returns: JSON array string (e.g., '["/path/to/dir1", "/path/to/dir2"]')
# Usage: json_array=$(pndcgn_array_to_json "${dirs[@]}")
pndcgn_array_to_json() {
    local -a items=("$@")

    if [[ ${#items[@]} -eq 0 ]]; then
        printf "[]"
        return 0
    fi

    # Use jq if available (more reliable)
    if command -v jq >/dev/null 2>&1; then
        printf '%s\n' "${items[@]}" | jq -R '.' | jq -s '.'
        return 0
    fi

    # Fallback: manual JSON construction
    local json="["
    local first=true
    for item in "${items[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json="${json},"
        fi
        # Escape quotes and backslashes, wrap in quotes
        local escaped_item
        escaped_item=$(printf "%s" "$item" | sed 's/\\/\\\\/g; s/"/\\"/g')
        json="${json}\"${escaped_item}\""
    done
    json="${json}]"

    printf "%s" "$json"
}

# --- Run Output Directory Deletion ---
# Delete run output directory safely
pndcgn_delete_output_directory() {
    local target_dir="$1"
    local output_type="$2"
    local run_id="$3"

    local output_dir="$target_dir/.pndcgn/$output_type-$run_id"

    if [[ ! -d "$output_dir" ]]; then
        pndcgn_log_warn "Output directory does not exist: $output_dir"
        return 0
    fi

    # Verify it's a pndcgn directory (contains _index.md)
    if [[ ! -f "$output_dir/_index.md" ]]; then
        pndcgn_log_warn "Directory does not appear to be a pndcgn output: $output_dir"
        pndcgn_log_warn "Skipping deletion for safety"
        return 1
    fi

    # Delete the directory
    if rm -rf "$output_dir"; then
        pndcgn_log_info "Deleted output directory: $output_dir"
        return 0
    else
        pndcgn_log_error "Failed to delete output directory: $output_dir"
        return 1
    fi
}

# --- Output Type Validation ---
# Validate output type against pandoc's supported formats
pndcgn_validate_output_type() {
    local output_type="$1"

    # Common pandoc output formats
    local supported_formats=(
        "pdf" "html" "epub" "docx" "odt" "rtf" "tex" "latex"
        "markdown" "gfm" "commonmark" "rst" "asciidoc" "docbook"
        "opendocument" "opml" "org" "texinfo" "textile" "slideous"
        "slidy" "dzslides" "revealjs" "s5" "pptx" "beamer"
    )

    for format in "${supported_formats[@]}"; do
        if [[ "$output_type" == "$format" ]]; then
            return 0
        fi
    done

    pndcgn_log_error "Unsupported output type: $output_type"
    pndcgn_log_info "Supported types: ${supported_formats[*]}"
    return 1
}

# --- fzf Integration ---
# Interactive directory selection using fzf (if available)
# Legacy function for backward compatibility - use pndcgn_select_source_dirs() instead
pndcgn_select_source_dir() {
    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        return 1
    fi

    # Find all directories starting from current directory
    local selected_dir
    selected_dir=$(find . -type d -not -path '*/\.*' 2>/dev/null | \
        fzf --height 40% --border --header="Select source directory (ESC to cancel)" \
        --preview='ls -la {}' 2>/dev/null)

    if [[ -n "$selected_dir" ]] && [[ -d "$selected_dir" ]]; then
        # Resolve to absolute path
        printf "%s" "$(cd "$selected_dir" && pwd)"
        return 0
    fi

    return 1
}

# Select multiple source directories via fzf (or fallback to numbered list)
# Args: max_dirs (optional, defaults to PNDCGN_DEFAULT_MAX_SOURCE_DIRS)
# Returns: newline-separated list of selected directories (absolute paths)
# Exit: 0 on selection, 1 on cancel/error
# Side effects: Logs WARN for duplicates, INFO for excluded subdirectories
# Uses fzf --multi flag with limit, falls back to numbered list if fzf unavailable
pndcgn_select_source_dirs() {
    local max_dirs="${1:-${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}}"

    # Validate max_dirs is within range
    if [[ $max_dirs -lt 1 ]] || [[ $max_dirs -gt "${PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS:-16}" ]]; then
        pndcgn_log_warn "max_dirs=$max_dirs out of range, using default ${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
        max_dirs="${PNDCGN_DEFAULT_MAX_SOURCE_DIRS:-4}"
    fi

    local selected
    if command -v fzf >/dev/null 2>&1; then
        # Use fzf if available with multi-select
        # --multi=$max_dirs limits selection count, header shows current selection
        selected=$(find . -type d -not -path '*/\.*' 2>/dev/null | \
            fzf --multi="$max_dirs" \
                --height 40% \
                --border \
                --header="Select source directories (Tab=select, Enter=confirm, max=$max_dirs)" \
                --preview='ls -la {}' 2>/dev/null)

        # fzf returns empty on cancel (ESC) or error
        if [[ -z "$selected" ]]; then
            return 1
        fi
    else
        # Fallback to numbered list prompt
        pndcgn_log_info "fzf not available, using numbered list selection"
        selected=$(pndcgn_select_source_dirs_fallback "$max_dirs")
        if [[ -z "$selected" ]]; then
            return 1
        fi
    fi

    # Process selected directories: resolve to absolute paths, deduplicate, remove overlaps
    local -a dirs=()
    local -A seen=()

    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue

        # Resolve to absolute path
        if [[ ! -d "$dir" ]]; then
            pndcgn_log_warn "Directory not found, skipping: $dir"
            continue
        fi

        local abs_dir
        abs_dir=$(cd "$dir" && pwd) || continue

        # Deduplicate
        if [[ -n "${seen[$abs_dir]:-}" ]]; then
            pndcgn_log_warn "Duplicate directory removed: $dir"
            continue
        fi
        seen[$abs_dir]=1
        dirs+=("$abs_dir")
    done <<< "$selected"

    # Remove overlapping directories (subdirectories)
    if [[ ${#dirs[@]} -gt 1 ]]; then
        local non_overlapping
        non_overlapping=$(pndcgn_remove_overlapping_dirs "${dirs[@]}")
        mapfile -t dirs <<< "$non_overlapping"
    fi

    # Output selected directories (newline-separated)
    if [[ ${#dirs[@]} -eq 0 ]]; then
        return 1
    fi

    printf '%s\n' "${dirs[@]}"
    return 0
}

# Fallback selection when fzf is unavailable
# Args: max_dirs (maximum number of directories to select)
# Returns: newline-separated list of selected directories (relative paths)
# Exit: 0 on selection, 1 on cancel/error
# Side effects: Prompts user via stdin/stdout, logs warnings for invalid input
pndcgn_select_source_dirs_fallback() {
    local max_dirs="$1"
    local -a all_dirs=()

    # List directories with numbers (max 50 shown)
    local i=1
    while IFS= read -r dir; do
        printf "[%d] %s\n" "$i" "$dir" >&2
        all_dirs+=("$dir")
        ((i++))
        if [[ $i -gt 50 ]]; then
            break
        fi
    done < <(find . -type d -not -path '*/\.*' 2>/dev/null | sort)

    if [[ ${#all_dirs[@]} -eq 0 ]]; then
        pndcgn_log_warn "No directories found"
        return 1
    fi

    printf "\nEnter directory numbers (comma-separated, max %d): " "$max_dirs" >&2
    read -r selection || return 1

    # Parse selection (e.g., "1,3,5" or "1, x, 3")
    local -a selected=()
    local -a invalid_entries=()
    IFS=',' read -ra nums <<< "$selection"

    for num in "${nums[@]}"; do
        # Trim whitespace
        num=$(printf '%s' "$num" | tr -d '[:space:]')

        # Validate number
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#all_dirs[@]} ]]; then
            selected+=("${all_dirs[$((num-1))]}")
        elif [[ -n "$num" ]]; then
            invalid_entries+=("$num")
        fi
    done

    # Handle invalid entries
    if [[ ${#invalid_entries[@]} -gt 0 ]]; then
        pndcgn_log_warn "Invalid entries: ${invalid_entries[*]}"
        printf "Press 'c' to continue with valid selections only, or 'r' to re-prompt: " >&2
        read -r choice
        case "$choice" in
            r|R)
                # Re-prompt
                return 1  # Caller should retry
                ;;
            c|C|"")
                # Continue with valid selections
                ;;
            *)
                # Treat any other input as continue
                ;;
        esac
    fi

    # Check selection count against max
    if [[ ${#selected[@]} -gt $max_dirs ]]; then
        pndcgn_log_warn "Too many selections (max: $max_dirs, got: ${#selected[@]}), using first $max_dirs"
        selected=("${selected[@]:0:$max_dirs}")
    fi

    # Empty selection cancels
    if [[ ${#selected[@]} -eq 0 ]]; then
        return 1
    fi

    # Output selected directories
    printf '%s\n' "${selected[@]}"
    return 0
}

# ============================================================================
# SELF-EXECUTION DISPATCHER
# ============================================================================

# Only run dispatcher if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    _pndcgn_utilities_dispatch() {
        local cmd="${1:-help}"
        shift || true

        case "$cmd" in
            # Logging functions
            log_info|log-info)       pndcgn_log_info "$@" ;;
            log_error|log-error)     pndcgn_log_error "$@" ;;
            log_warn|log-warn)       pndcgn_log_warn "$@" ;;

            # XDG directories
            get_state_dir|state-dir)   pndcgn_get_state_dir ;;
            get_config_dir|config-dir) pndcgn_get_config_dir ;;

            # Path utilities
            resolve_path|resolve)    pndcgn_resolve_path "$@" ;;

            # Prerequisites
            check_prerequisites|check) pndcgn_check_prerequisites ;;

            # Interactive mode
            is_interactive|is-interactive) pndcgn_is_interactive ;;

            # ULID
            generate_ulid|ulid)      pndcgn_generate_ulid_fallback ;;

            # Ignore file management
            discover_ignore_file|discover-ignore)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 discover_ignore_file <source_root>"
                    return 2
                fi
                pndcgn_discover_ignore_file "$1"
                ;;

            seed_ignore_file|seed-ignore)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 seed_ignore_file <source_root>"
                    return 2
                fi
                pndcgn_seed_ignore_file "$1"
                ;;

            path_matches_ignore|matches-ignore)
                if [[ $# -lt 2 ]]; then
                    pndcgn_log_error "Usage: $0 path_matches_ignore <path> <ignore_file>"
                    return 2
                fi
                pndcgn_path_matches_ignore "$1" "$2"
                ;;

            # TOML config management
            discover_config_file|discover-config)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 discover_config_file <source_dir>"
                    return 2
                fi
                pndcgn_discover_config_file "$1"
                ;;

            parse_toml_patterns|parse-patterns)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 parse_toml_patterns <config_file>"
                    return 2
                fi
                pndcgn_parse_toml_patterns "$1"
                ;;

            parse_toml_extensions|parse-extensions)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 parse_toml_extensions <config_file>"
                    return 2
                fi
                pndcgn_parse_toml_extensions "$1"
                ;;

            # Output directory management
            delete_output_directory|delete-output)
                if [[ $# -lt 3 ]]; then
                    pndcgn_log_error "Usage: $0 delete_output_directory <target_dir> <output_type> <run_id>"
                    return 2
                fi
                pndcgn_delete_output_directory "$1" "$2" "$3"
                ;;

            # Output type validation
            validate_output_type|validate-type)
                if [[ $# -lt 1 ]]; then
                    pndcgn_log_error "Usage: $0 validate_output_type <output_type>"
                    return 2
                fi
                pndcgn_validate_output_type "$1"
                ;;

            # fzf integration
            select_source_dir|select-dir) pndcgn_select_source_dir ;;

            # ULID extension installation
            install_ulid|install-ulid) pndcgn_install_ulid ;;

            # Help
            help|-h|--help)
                cat <<'HELP'
pndcgn utilities module - Direct execution mode

Usage: src/utilities.sh <command> [args...]

Commands:
  log_info <message>              Log info message to stderr
  log_error <message>             Log error message to stderr
  log_warn <message>              Log warning message to stderr
  get_state_dir                   Print XDG state directory path
  get_config_dir                  Print XDG config directory path
  resolve_path <path>             Resolve path to absolute
  check_prerequisites             Check required commands exist
  generate_ulid                   Generate ULID fallback
  discover_ignore_file <root>     Discover .pndcgnignore file
  seed_ignore_file <root>        Seed .pndcgnignore from .gitignore
  path_matches_ignore <p> <f>    Check if path matches ignore patterns
  discover_config_file <dir>      Discover pndcgn.toml config file
  parse_toml_patterns <file>      Parse [include] patterns from TOML
  parse_toml_extensions <file>    Parse [include.types] extensions from TOML
  delete_output_directory <t> <o> <r>  Delete run output directory
  validate_output_type <type>     Validate output type
  select_source_dir               Interactive directory selection (fzf)
  install_ulid                    Install sqlite-ulid extension
  help                            Show this help

Examples:
  src/utilities.sh log_info "Processing started"
  src/utilities.sh get_state_dir
  src/utilities.sh check_prerequisites && echo "All good"
  src/utilities.sh resolve_path "./docs"
HELP
                ;;

            *)
                pndcgn_log_error "Unknown command: $cmd"
                echo "Run '$0 help' for usage" >&2
                return 2
                ;;
        esac
    }

    _pndcgn_utilities_dispatch "$@"
fi
