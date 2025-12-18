#!/usr/bin/env bash
#
# pndcgn Test Helper
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Test helper for pndcgn tool.
# Sets up clean test environment, provides mocking capabilities,
# and sources shared constants.

set -uo pipefail
# Note: -e removed to prevent test aborts when scripts exit with non-zero status
# Tests should check status explicitly using ShellSpec assertions

# --- Shared Constants ---
# Determine project root once and reuse it in all tests.
if [[ -z "${PNDCGN_PROJECT_ROOT:-}" ]]; then
    if [[ -n "${SHELLSPEC_PROJECT_ROOT:-}" ]]; then
        PNDCGN_PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT}"
    else
        # Fallback: spec_helper.sh lives in tests/, so go one level up.
        PNDCGN_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    readonly PNDCGN_PROJECT_ROOT
fi

# Source constants from project root (where shellspec runs from)
. "${PNDCGN_PROJECT_ROOT}/src/constants.sh"

# --- Test Environment Setup ---

# Creates a temporary directory for tests and sets the script path.
setup_test_env() {
    # Don't use 'local' here - we need to export these variables
    temp_dir=$(mktemp -d) || {
        printf "FATAL: Foundry Test Helper: failed to create temporary directory.\n" >&2
        return 1
    }

    # Set the path to the main script for use in tests
    # PWD is project root when shellspec runs
    # Use regular variable, not readonly, to allow multiple calls
    script="${PNDCGN_PROJECT_ROOT}/bin/pndcgn"

    # Don't change directory - keep working directory as project root
    # Tests should use $temp_dir for creating test files/directories
    # This avoids ShellSpec directory tracking issues
    # Export for use in tests
    export temp_dir script
}

# Removes the temporary directory and mock functions.
cleanup_test_env() {
    # Ensure we're in a safe directory before cleanup
    # Try to return to project root to avoid ShellSpec directory tracking issues
    local safe_dir="${SHELLSPEC_PROJECT_ROOT:-${PNDCGN_PROJECT_ROOT:-/}}"
    if [[ -d "$safe_dir" ]]; then
        cd "$safe_dir" >/dev/null 2>&1 || true
    fi

    # Clean up temp directory if it exists (use ${temp_dir:-} to handle unbound)
    local cleanup_dir="${temp_dir:-}"
    if [[ -n "$cleanup_dir" ]] && [[ -d "$cleanup_dir" ]]; then
        rm -rf "$cleanup_dir" 2>/dev/null || true
    fi

    # Unset variables (safe even if they don't exist)
    unset temp_dir script 2>/dev/null || true
}

# --- Mocking Framework ---

# DEPRECATED: mock_all_commands - Do not use in new tests
# This function is deprecated because:
# 1. It interferes with prerequisite checks (command -v)
# 2. Tests should define specific mocks only where needed
# 3. Real commands (pandoc, curl, etc.) can often be used in tests
# Individual tests should define their own mocks (e.g., pandoc() { ... }) as needed
# NOTE: sqlite3 is intentionally NOT mocked so database and CLI tests
# can exercise real SQLite behavior. Specs that need to simulate DB errors
# should define a local sqlite3() in that example/context only.
mock_all_commands() {
    local commands_to_mock=("pandoc" "curl" "fzf" "git")

    for cmd in "${commands_to_mock[@]}"; do
        eval "$cmd() { printf '%s called with: %s\\n' '$cmd' \"$*\"; }" || true
        # shellcheck disable=SC2163
        export -f "$cmd" || true
    done
}

# Cleans up all mocks
cleanup_mocks() {
    local commands_to_mock=("pandoc" "curl" "fzf" "git" "mkdir" "rm" "sha256sum" "shasum")

    for cmd in "${commands_to_mock[@]}"; do
        unset -f "$cmd" &>/dev/null || true
    done
}

# --- Per-test Database Helpers (file-backed) ---
# Use a fresh XDG_STATE_HOME per example when testing real database behavior.

setup_db_file() {
    local state_dir
    state_dir=$(mktemp -d)
    export XDG_STATE_HOME="$state_dir"
    export PNDCGN_QUIET=true
}

cleanup_db_file() {
    if [[ -n "${XDG_STATE_HOME:-}" ]] && [[ -d "$XDG_STATE_HOME" ]]; then
        rm -rf "$XDG_STATE_HOME"
    fi
    unset XDG_STATE_HOME PNDCGN_QUIET
}

# --- CLI Environment Helpers ---
# For CLI specs we want a fresh temp directory and a dedicated state directory
# per example, but we let the CLI itself spawn its own subprocess and talk to
# the real sqlite3 binary.

setup_cli_env() {
    setup_test_env || return 1
    # Ensure temp_dir is set before using it
    if [[ -z "${temp_dir:-}" ]]; then
        printf "ERROR: temp_dir not set by setup_test_env\n" >&2
        return 1
    fi
    export XDG_STATE_HOME="$temp_dir/state"
    mkdir -p "$XDG_STATE_HOME" || return 1
    export PNDCGN_QUIET=true
}

cleanup_cli_env() {
    cleanup_test_env
    unset XDG_STATE_HOME PNDCGN_QUIET
}

# --- CLI Database Seeding Helpers ---
# Seed the database with a run before running CLI tests.
# This allows CLI tests to use real database instead of mocks.

seed_db_with_run() {
    local source_root="${1:-/tmp/source}"
    local target_root="${2:-/tmp/target}"
    local output_type="${3:-pdf}"
    local dry_run="${4:-0}"

    # Suppress errors to avoid aborting tests
    set +e
    source "${PNDCGN_PROJECT_ROOT}/src/database.sh" 2>/dev/null || true
    pndcgn_db_init >/dev/null 2>&1 || true
    pndcgn_db_create_run "$source_root" "$target_root" "$output_type" "$dry_run" >/dev/null 2>&1 || true
    set -e
}
