#!/usr/bin/env bash
#
# Run Individual Test
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run a single test file or specific test block
#
# Usage:
#   ./scripts/run-test.sh <test-file> [line-number]
#   ./scripts/run-test.sh tests/utilities/logging_spec.sh
#   ./scripts/run-test.sh tests/pndcgn_spec.sh 25
#   ./scripts/run-test.sh utilities/logging_spec.sh

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# --- Main ---

main() {
    local test_file="${1:-}"
    local line_number="${2:-}"

    if [[ -z "${test_file}" ]]; then
        print_error "Usage: $0 <test-file> [line-number]"
        echo ""
        echo "Examples:"
        echo "  $0 tests/utilities/logging_spec.sh"
        echo "  $0 tests/pndcgn_spec.sh 25"
        echo "  $0 utilities/logging_spec.sh"
        exit 1
    fi

    check_prerequisites || exit 1
    ensure_results_dirs

    local full_path
    if ! full_path=$(validate_test_file "${test_file}"); then
        exit 1
    fi

    local test_name
    test_name=$(basename "${full_path}" .sh)

    # Build test path with optional line number
    local test_path="${full_path}"
    if [[ -n "${line_number}" ]]; then
        test_path="${full_path}:${line_number}"
        print_info "Running test at line ${line_number} in ${test_name}"
    else
        print_info "Running test file: ${test_name}"
    fi

    local timestamp
    timestamp=$(get_timestamp)
    local date_folder
    date_folder=$(get_date_folder "${timestamp}")
    local logs_date_dir
    logs_date_dir=$(get_logs_dir "${date_folder}")
    local log_file="${logs_date_dir}/${test_name}-${timestamp}.log"

    # Run test
    print_info "Executing: ${SHELLSPEC_CMD} ${test_path}"
    echo ""

    if run_shellspec "${test_path}" 2>&1 | tee "${log_file}"; then
        generate_report "${log_file}"
        print_summary 0 "${test_name}" "${timestamp}"
    else
        local exit_code=$?
        generate_report "${log_file}"
        print_summary ${exit_code} "${test_name}" "${timestamp}"
        exit ${exit_code}
    fi
}

main "$@"
