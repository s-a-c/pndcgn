#!/usr/bin/env bash
#
# Run Unit Test Suite
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run all unit tests (modular test files with mocks)
#
# Usage:
#   ./scripts/run-unit-tests.sh [--coverage]
#   ./scripts/run-unit-tests.sh --coverage

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

    print_info "Running unit test suite..."
    echo ""

    # Unit test directories (modular files with mocks)
    local test_dirs=(
        "${TESTS_DIR}/utilities"
        "${TESTS_DIR}/database"
        "${TESTS_DIR}/processing"
    )

    # Also include standalone unit test files
    local test_files=(
        "${TESTS_DIR}/constants_spec.sh"
        "${TESTS_DIR}/config_spec.sh"
    )

    local timestamp
    timestamp=$(get_timestamp)
    local date_folder
    date_folder=$(get_date_folder "${timestamp}")
    local logs_date_dir
    logs_date_dir=$(get_logs_dir "${date_folder}")
    local log_file="${logs_date_dir}/unit-tests-${timestamp}.log"

    # Build test paths
    local test_paths=()
    for dir in "${test_dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            test_paths+=("${dir}")
        fi
    done
    for file in "${test_files[@]}"; do
        if [[ -f "${file}" ]]; then
            test_paths+=("${file}")
        fi
    done

    if [[ ${#test_paths[@]} -eq 0 ]]; then
        print_error "No unit test files found"
        exit 1
    fi

    print_info "Found ${#test_paths[@]} test path(s)"
    echo ""

    # Run tests
    local cmd_args=()
    if [[ "${use_coverage}" == "true" ]]; then
        print_info "Running with coverage..."
        if run_shellspec_with_coverage "${test_paths[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Unit tests (with coverage)" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Unit tests (with coverage)" "${timestamp}"
            exit ${exit_code}
        fi
    else
        if run_shellspec "${test_paths[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Unit tests" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Unit tests" "${timestamp}"
            exit ${exit_code}
        fi
    fi
}

main "$@"
