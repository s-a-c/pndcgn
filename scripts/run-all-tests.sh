#!/usr/bin/env bash
#
# Run All Test Suites
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run all test suites (unit, feature, integration)
#
# Usage:
#   ./scripts/run-all-tests.sh [--coverage] [--skip-integration]
#   ./scripts/run-all-tests.sh --coverage

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# --- Main ---

main() {
    local use_coverage=false
    local skip_integration=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --coverage|-c)
                use_coverage=true
                shift
                ;;
            --skip-integration|-s)
                skip_integration=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Usage: $0 [--coverage] [--skip-integration]"
                exit 1
                ;;
        esac
    done

    check_prerequisites || exit 1
    ensure_results_dirs

    print_info "Running all test suites..."
    echo ""

    local timestamp
    timestamp=$(get_timestamp)
    local overall_exit=0

    # Run unit tests
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Suite 1/3: Unit Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ "${use_coverage}" == "true" ]]; then
        "${SCRIPT_DIR}/run-unit-tests.sh" --coverage || overall_exit=$?
    else
        "${SCRIPT_DIR}/run-unit-tests.sh" || overall_exit=$?
    fi
    echo ""

    # Run feature tests
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Suite 2/3: Feature Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ "${use_coverage}" == "true" ]]; then
        "${SCRIPT_DIR}/run-feature-tests.sh" --coverage || overall_exit=$?
    else
        "${SCRIPT_DIR}/run-feature-tests.sh" || overall_exit=$?
    fi
    echo ""

    # Run integration tests (unless skipped)
    if [[ "${skip_integration}" != "true" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "Suite 3/3: Integration Tests"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [[ "${use_coverage}" == "true" ]]; then
            "${SCRIPT_DIR}/run-integration-tests.sh" --coverage || overall_exit=$?
        else
            "${SCRIPT_DIR}/run-integration-tests.sh" || overall_exit=$?
        fi
        echo ""
    else
        print_warning "Skipping integration tests (--skip-integration)"
        echo ""
    fi

    # Final summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ${overall_exit} -eq 0 ]]; then
        print_success "All test suites completed successfully"
    else
        print_error "Some test suites failed"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    local date_folder
    date_folder=$(get_date_folder "${timestamp}")
    print_info "Results: ${RESULTS_DIR}"
    print_info "Date folder: ${date_folder}"
    print_info "Logs: $(get_logs_dir "${date_folder}")"
    print_info "Reports: $(get_reports_dir "${date_folder}")"
    local coverage_date_dir
    coverage_date_dir=$(get_coverage_dir "${date_folder}")
    if [[ "${use_coverage}" == "true" ]] && [[ -d "${coverage_date_dir}" ]] && [[ -n "$(ls -A "${coverage_date_dir}" 2>/dev/null)" ]]; then
        print_info "Coverage: ${coverage_date_dir}/index.html"
    fi

    exit ${overall_exit}
}

main "$@"
