#!/usr/bin/env bash
#
# Run Tests with Coverage
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run all tests with kcov coverage reporting
#
# Usage:
#   ./scripts/run-coverage.sh [suite]
#   ./scripts/run-coverage.sh unit
#   ./scripts/run-coverage.sh all
#   ./scripts/run-coverage.sh  # runs all

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# --- Main ---

main() {
    local suite="${1:-all}"

    check_prerequisites || exit 1

    # Check for kcov
    if ! command_exists kcov; then
        print_error "kcov not found. Install with: brew install kcov"
        print_warning "Note: kcov has ptrace limitations on macOS. Consider using Docker or CI."
        exit 1
    fi

    ensure_results_dirs

    print_info "Running tests with coverage (suite: ${suite})..."
    print_warning "Note: Coverage works best on Linux. Use Docker or CI for accurate results."
    echo ""

    case "${suite}" in
        unit|utilities|database|processing)
            "${SCRIPT_DIR}/run-unit-tests.sh" --coverage
            ;;
        feature|features)
            "${SCRIPT_DIR}/run-feature-tests.sh" --coverage
            ;;
        integration)
            "${SCRIPT_DIR}/run-integration-tests.sh" --coverage
            ;;
        all)
            "${SCRIPT_DIR}/run-all-tests.sh" --coverage
            ;;
        *)
            print_error "Unknown suite: ${suite}"
            echo ""
            echo "Available suites:"
            echo "  unit        - Unit tests (utilities, database, processing)"
            echo "  feature     - Feature tests (CLI, performance, usability)"
            echo "  integration - Integration tests (no mocks)"
            echo "  all         - All test suites (default)"
            exit 1
            ;;
    esac

    # Open coverage report if available
    local coverage_index="${COVERAGE_DIR}/index.html"
    if [[ -f "${coverage_index}" ]]; then
        echo ""
        print_success "Coverage report generated: ${coverage_index}"
        print_info "Open with: open ${coverage_index}"
    else
        print_warning "Coverage report not generated. Check logs for errors."
    fi
}

main "$@"
