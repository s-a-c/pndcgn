#!/usr/bin/env bash
#
# pndcgn Test Helper
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Test helper for pndcgn tool.
# Sets up clean test environment, provides mocking capabilities,
# and sources shared constants.

set -euo pipefail

# --- Shared Constants ---
# Source constants from project root (where shellspec runs from)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"

# --- Test Environment Setup ---

# Creates a temporary directory for tests and sets the script path.
setup_test_env() {
    local temp_dir
    if ! temp_dir=$(mktemp -d); then
        printf "FATAL: Failed to create temporary directory for tests.\n" >&2
        exit 1
    fi

    # Set the path to the main script for use in tests
    # PWD is project root when shellspec runs
    readonly script="${SHELLSPEC_PROJECT_ROOT:-$PWD}/bin/pndcgn"

    # Move into temporary directory for test isolation
    cd "$temp_dir" || exit 1

    # Export for use in tests
    export temp_dir script
}

# Removes the temporary directory and mock functions.
cleanup_test_env() {
    cd - >/dev/null || true
    if [[ -n "${temp_dir:-}" ]] && [[ -d "${temp_dir:-}" ]]; then
        rm -rf "$temp_dir"
    fi
}

# --- Mocking Framework ---

# Mocks external commands used by pndcgn
mock_all_commands() {
    local commands_to_mock=("pandoc" "sqlite3" "curl" "fzf" "git")

    for cmd in "${commands_to_mock[@]}"; do
        eval "$cmd() { printf '%s called with: %s\\n' '$cmd' \"\$*\"; }"
        export -f "$cmd"
    done
}

# Cleans up all mocks
cleanup_mocks() {
    local commands_to_mock=("pandoc" "sqlite3" "curl" "fzf" "git" "mkdir" "rm" "sha256sum" "shasum")

    for cmd in "${commands_to_mock[@]}"; do
        unset -f "$cmd" &>/dev/null || true
    done
}

# Helper: sqlite3 mock that reads from stdin (for heredoc usage)
# Usage in tests: Override this function with test-specific logic
mock_sqlite3_heredoc() {
    local db_file="${1:-}"
    # Read query from stdin (heredoc)
    local query
    query=$(cat)

    # Default: return empty for unknown queries
    case "$db_file" in
        *pndcgn.db)
            # Test-specific mocks should override this
            return 0
            ;;
    esac
}
