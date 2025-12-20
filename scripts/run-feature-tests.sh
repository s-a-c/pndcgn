#!/usr/bin/env bash
#
# Run Feature Test Suite
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run feature/integration tests for CLI and end-to-end scenarios
#
# Usage:
#   ./scripts/run-feature-tests.sh [--coverage]
#   ./scripts/run-feature-tests.sh --coverage

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# --- Main ---

main() {
    local use_coverage=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --coverage|-c)
                use_coverage=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Usage: $0 [--coverage]"
                exit 1
                ;;
        esac
    done

    check_prerequisites || exit 1
    ensure_results_dirs

    print_info "Running feature test suite..."
    echo ""

    # Feature test files (CLI, end-to-end, performance, usability)
    local test_files=(
        "${TESTS_DIR}/pndcgn_spec.sh"
        "${TESTS_DIR}/performance_spec.sh"
        "${TESTS_DIR}/usability_spec.sh"
    )

    # Filter to only existing files
    local existing_files=()
    for file in "${test_files[@]}"; do
        if [[ -f "${file}" ]]; then
            existing_files+=("${file}")
        fi
    done

    if [[ ${#existing_files[@]} -eq 0 ]]; then
        print_error "No feature test files found"
        exit 1
    fi

    print_info "Found ${#existing_files[@]} feature test file(s)"
    echo ""

    local timestamp
    timestamp=$(get_timestamp)
    local date_folder
    date_folder=$(get_date_folder "${timestamp}")
    local logs_date_dir
    logs_date_dir=$(get_logs_dir "${date_folder}")
    local log_file="${logs_date_dir}/feature-tests-${timestamp}.log"

    # Run tests
    if [[ "${use_coverage}" == "true" ]]; then
        print_info "Running with coverage..."
        if run_shellspec_with_coverage "${existing_files[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Feature tests (with coverage)" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Feature tests (with coverage)" "${timestamp}"
            exit ${exit_code}
        fi
    else
        if run_shellspec "${existing_files[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Feature tests" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Feature tests" "${timestamp}"
            exit ${exit_code}
        fi
    fi
}

main "$@"
