#!/usr/bin/env bash
#
# Run Integration Test Suite
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run integration tests without mocks (real implementations)
#
# Usage:
#   ./scripts/run-integration-tests.sh [--coverage]
#   ./scripts/run-integration-tests.sh --coverage

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

    print_info "Running integration test suite (no mocks)..."
    echo ""

    # Integration test directory
    local integration_dir="${TESTS_DIR}/integration"

    if [[ ! -d "${integration_dir}" ]]; then
        print_error "Integration test directory not found: ${integration_dir}"
        exit 1
    fi

    local test_files
    test_files=$(find "${integration_dir}" -name "*_spec.sh" -type f 2>/dev/null || true)

    if [[ -z "${test_files}" ]]; then
        print_error "No integration test files found in ${integration_dir}"
        exit 1
    fi

    local file_count
    file_count=$(echo "${test_files}" | wc -l | tr -d ' ')
    print_info "Found ${file_count} integration test file(s)"
    echo ""

    local timestamp
    timestamp=$(get_timestamp)
    local date_folder
    date_folder=$(get_date_folder "${timestamp}")
    local logs_date_dir
    logs_date_dir=$(get_logs_dir "${date_folder}")
    local log_file="${logs_date_dir}/integration-tests-${timestamp}.log"

    # Convert to array
    local test_paths=()
    while IFS= read -r file; do
        [[ -n "${file}" ]] && test_paths+=("${file}")
    done <<< "${test_files}"

    # Run tests
    if [[ "${use_coverage}" == "true" ]]; then
        print_info "Running with coverage..."
        print_warning "Note: Coverage works best on Linux (Docker or CI)"
        if run_shellspec_with_coverage "${test_paths[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Integration tests (with coverage)" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Integration tests (with coverage)" "${timestamp}"
            exit ${exit_code}
        fi
    else
        if run_shellspec "${test_paths[@]}" 2>&1 | tee "${log_file}"; then
            generate_report "${log_file}"
            print_summary 0 "Integration tests" "${timestamp}"
        else
            local exit_code=$?
            generate_report "${log_file}"
            print_summary ${exit_code} "Integration tests" "${timestamp}"
            exit ${exit_code}
        fi
    fi
}

main "$@"
