#!/usr/bin/env bash
#
# Common Functions Library for Test Scripts
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Shared functions and constants for test execution scripts

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly TESTS_DIR="${PROJECT_ROOT}/tests"
readonly RESULTS_DIR="${PROJECT_ROOT}/tests.results"
readonly COVERAGE_DIR="${RESULTS_DIR}/coverage"
readonly REPORTS_DIR="${RESULTS_DIR}/reports"
readonly LOGS_DIR="${RESULTS_DIR}/logs"

# ShellSpec configuration
readonly SHELLSPEC_CONFIG="${PROJECT_ROOT}/.shellspec"
readonly SHELLSPEC_CMD="shellspec"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Utility Functions ---

# Print colored message
print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    local missing=0

    if ! command_exists "${SHELLSPEC_CMD}"; then
        print_error "shellspec not found. Install with: brew install shellspec"
        missing=$((missing + 1))
    fi

    if [[ $missing -gt 0 ]]; then
        print_error "Missing ${missing} prerequisite(s). Please install and try again."
        return 1
    fi

    return 0
}

# Ensure results directories exist (including date-stamped subdirectories)
ensure_results_dirs() {
    local date_folder
    date_folder=$(get_date_folder)

    # Create base directories
    mkdir -p "${RESULTS_DIR}" "${COVERAGE_DIR}" "${REPORTS_DIR}" "${LOGS_DIR}"

    # Create date-stamped subdirectories
    mkdir -p "$(get_reports_dir "${date_folder}")"
    mkdir -p "$(get_logs_dir "${date_folder}")"
    mkdir -p "$(get_coverage_dir "${date_folder}")"
}

# Generate timestamp (YYYYMMDD-HHMMSS)
get_timestamp() {
    date +%Y%m%d-%H%M%S
}

# Get date folder (YYYY-MM-DD) from timestamp or current date
get_date_folder() {
    local timestamp="${1:-}"
    if [[ -n "${timestamp}" ]] && [[ "${timestamp}" =~ ^([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        # Extract date from timestamp (YYYYMMDD-HHMMSS)
        local year="${BASH_REMATCH[1]}"
        local month="${BASH_REMATCH[2]}"
        local day="${BASH_REMATCH[3]}"
        printf "%s-%s-%s" "${year}" "${month}" "${day}"
    else
        # Use current date
        date +%Y-%m-%d
    fi
}

# Get date-stamped results directories
get_reports_dir() {
    local date_folder="${1:-$(get_date_folder)}"
    printf "%s/%s" "${REPORTS_DIR}" "${date_folder}"
}

get_logs_dir() {
    local date_folder="${1:-$(get_date_folder)}"
    printf "%s/%s" "${LOGS_DIR}" "${date_folder}"
}

get_coverage_dir() {
    local date_folder="${1:-$(get_date_folder)}"
    printf "%s/%s" "${COVERAGE_DIR}" "${date_folder}"
}

# Clean old results (optional)
clean_results() {
    local days="${1:-7}"
    print_info "Cleaning results older than ${days} days..."
    find "${RESULTS_DIR}" -type f -mtime +${days} -delete 2>/dev/null || true
    print_success "Cleanup complete"
}

# Format test file path
format_test_path() {
    local test_file="$1"
    # If relative path, make it relative to tests directory
    if [[ "${test_file}" != /* ]]; then
        if [[ "${test_file}" != tests/* ]]; then
            echo "tests/${test_file}"
        else
            echo "${test_file}"
        fi
    else
        echo "${test_file}"
    fi
}

# Validate test file exists
validate_test_file() {
    local test_file="$1"
    local full_path="${PROJECT_ROOT}/$(format_test_path "${test_file}")"

    if [[ ! -f "${full_path}" ]]; then
        print_error "Test file not found: ${full_path}"
        return 1
    fi

    echo "${full_path}"
}

# Run shellspec with common options
run_shellspec() {
    local test_path="$1"
    shift
    local extra_args=("$@")

    local args=(
        "--shell" "bash"
        "--color"
        "--format" "documentation"
    )

    # Add extra args if provided
    if [[ ${#extra_args[@]} -gt 0 ]]; then
        args+=("${extra_args[@]}")
    fi

    "${SHELLSPEC_CMD}" "${args[@]}" "${test_path}"
}

# Run shellspec with coverage
run_shellspec_with_coverage() {
    local test_path="$1"
    shift
    local extra_args=("$@")

    # Get date-stamped coverage directory
    local date_folder
    date_folder=$(get_date_folder)
    local coverage_date_dir
    coverage_date_dir=$(get_coverage_dir "${date_folder}")
    mkdir -p "${coverage_date_dir}"

    local args=(
        "--kcov"
        "--kcov-dir" "${coverage_date_dir}"
        "--shell" "bash"
        "--color"
        "--format" "documentation"
    )

    # Add extra args if provided
    if [[ ${#extra_args[@]} -gt 0 ]]; then
        args+=("${extra_args[@]}")
    fi

    "${SHELLSPEC_CMD}" "${args[@]}" "${test_path}"
}

# Generate test report
generate_report() {
    local log_file="$1"
    if [[ -f "${PROJECT_ROOT}/tests.results/generate-reports.sh" ]]; then
        print_info "Generating report from ${log_file}..."
        "${PROJECT_ROOT}/tests.results/generate-reports.sh" >/dev/null 2>&1 || true
    fi
}

# Print summary
print_summary() {
    local exit_code="$1"
    local test_type="$2"
    local timestamp="$3"

    local date_folder
    date_folder=$(get_date_folder "${timestamp}")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ${exit_code} -eq 0 ]]; then
        print_success "${test_type} completed successfully"
    else
        print_error "${test_type} completed with failures"
    fi
    echo ""
    print_info "Results: ${RESULTS_DIR}"
    print_info "Date folder: ${date_folder}"
    print_info "Logs: $(get_logs_dir "${date_folder}")"
    print_info "Reports: $(get_reports_dir "${date_folder}")"
    local coverage_date_dir
    coverage_date_dir=$(get_coverage_dir "${date_folder}")
    if [[ -d "${coverage_date_dir}" ]] && [[ -n "$(ls -A "${coverage_date_dir}" 2>/dev/null)" ]]; then
        print_info "Coverage: ${coverage_date_dir}/index.html"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return ${exit_code}
}
