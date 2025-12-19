#!/usr/bin/env bash
#
# Local CI/CD Workflow
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Run local CI/CD workflow (lint, test, coverage, reports)
#
# Usage:
#   ./scripts/local-ci.sh [--skip-lint] [--skip-coverage] [--clean]
#   ./scripts/local-ci.sh --clean

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# --- Linting Functions ---

run_shellcheck() {
    print_info "Running ShellCheck..."
    if command_exists shellcheck; then
        local files=(
            "${PROJECT_ROOT}/bin/pndcgn"
            "${PROJECT_ROOT}/src"/*.sh
            "${PROJECT_ROOT}/scripts"/*.sh
        )
        local errors=0
        for file in "${files[@]}"; do
            if [[ -f "${file}" ]]; then
                if ! shellcheck "${file}"; then
                    errors=$((errors + 1))
                fi
            fi
        done
        if [[ ${errors} -eq 0 ]]; then
            print_success "ShellCheck passed"
            return 0
        else
            print_error "ShellCheck found ${errors} file(s) with issues"
            return 1
        fi
    else
        print_warning "shellcheck not found. Install with: brew install shellcheck"
        return 0
    fi
}

# --- Main CI Workflow ---

main() {
    local skip_lint=false
    local skip_coverage=false
    local clean_first=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-lint)
                skip_lint=true
                shift
                ;;
            --skip-coverage)
                skip_coverage=true
                shift
                ;;
            --clean)
                clean_first=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Usage: $0 [--skip-lint] [--skip-coverage] [--clean]"
                exit 1
                ;;
        esac
    done

    check_prerequisites || exit 1
    ensure_results_dirs

    local overall_exit=0
    local timestamp
    timestamp=$(get_timestamp)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Local CI/CD Workflow - ${timestamp}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Clean old results if requested
    if [[ "${clean_first}" == "true" ]]; then
        print_info "Cleaning old results..."
        rm -rf "${RESULTS_DIR}"/*
        ensure_results_dirs
        print_success "Cleanup complete"
        echo ""
    fi

    # Step 1: Linting
    if [[ "${skip_lint}" != "true" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "Step 1/4: Linting"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! run_shellcheck; then
            overall_exit=1
        fi
        echo ""
    else
        print_warning "Skipping linting (--skip-lint)"
        echo ""
    fi

    # Step 2: Unit Tests
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Step 2/4: Unit Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if ! "${SCRIPT_DIR}/run-unit-tests.sh"; then
        overall_exit=1
    fi
    echo ""

    # Step 3: Feature Tests
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Step 3/4: Feature Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if ! "${SCRIPT_DIR}/run-feature-tests.sh"; then
        overall_exit=1
    fi
    echo ""

    # Step 4: Integration Tests
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Step 4/4: Integration Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if ! "${SCRIPT_DIR}/run-integration-tests.sh"; then
        overall_exit=1
    fi
    echo ""

    # Coverage (optional)
    if [[ "${skip_coverage}" != "true" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "Coverage: Running with kcov..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if command_exists kcov; then
            if ! "${SCRIPT_DIR}/run-coverage.sh" all; then
                print_warning "Coverage run had issues (may be macOS ptrace limitation)"
            fi
        else
            print_warning "kcov not found. Skipping coverage."
        fi
        echo ""
    else
        print_warning "Skipping coverage (--skip-coverage)"
        echo ""
    fi

    # Final summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ${overall_exit} -eq 0 ]]; then
        print_success "Local CI/CD workflow completed successfully"
    else
        print_error "Local CI/CD workflow completed with failures"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    local date_folder
    date_folder=$(get_date_folder)
    print_info "Results: ${RESULTS_DIR}"
    print_info "Date folder: ${date_folder}"
    print_info "Logs: $(get_logs_dir "${date_folder}")"
    print_info "Reports: $(get_reports_dir "${date_folder}")"
    local coverage_date_dir
    coverage_date_dir=$(get_coverage_dir "${date_folder}")
    if [[ -d "${coverage_date_dir}" ]] && [[ -n "$(ls -A "${coverage_date_dir}" 2>/dev/null)" ]]; then
        print_info "Coverage: ${coverage_date_dir}/index.html"
    fi
    echo ""

    exit ${overall_exit}
}

main "$@"
