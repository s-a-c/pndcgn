#!/usr/bin/env bash
#
# Performance Validation Script for SC-004
#
# Validates that N-directory processing time ≤ N×single + 10% overhead
#
# Usage: ./scripts/validate-performance-sc004.sh [N] [test_dir]
#
# Args:
#   N: Number of directories to test (default: 4)
#   test_dir: Temporary directory for test files (default: /tmp/pndcgn-perf-test)
#
# Exit codes:
#   0: Performance requirement met
#   1: Performance requirement not met
#   2: Test setup failure

set -euo pipefail

# Source project modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. "${PROJECT_ROOT}/src/constants.sh"
. "${PROJECT_ROOT}/src/utilities.sh"
. "${PROJECT_ROOT}/src/processing.sh"

# Configuration
N="${1:-4}"
TEST_DIR="${2:-/tmp/pndcgn-perf-test-$$}"
OUTPUT_DIR="${TEST_DIR}/output"

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Setup test directories
setup_test_dirs() {
    mkdir -p "$OUTPUT_DIR"
    for i in $(seq 1 "$N"); do
        local dir="${TEST_DIR}/dir${i}"
        mkdir -p "$dir"
        # Create identical test files in each directory
        echo "# Test Document 1" > "${dir}/file1.md"
        echo "# Test Document 2" > "${dir}/file2.md"
    done
}

# Measure single directory processing time
measure_single_dir_time() {
    local dir="${TEST_DIR}/dir1"
    local start end duration

    start=$(date +%s.%N)
    # Simulate processing: discover files
    pndcgn_discover_files "$dir" "" >/dev/null 2>&1
    end=$(date +%s.%N)

    duration=$(echo "$end - $start" | bc)
    printf "%s" "$duration"
}

# Measure N-directory processing time
measure_multi_dir_time() {
    local start end duration

    start=$(date +%s.%N)
    # Simulate processing: discover files from all N directories
    for i in $(seq 1 "$N"); do
        local dir="${TEST_DIR}/dir${i}"
        pndcgn_discover_files "$dir" "" >/dev/null 2>&1
    done
    end=$(date +%s.%N)

    duration=$(echo "$end - $start" | bc)
    printf "%s" "$duration"
}

# Main validation
main() {
    echo "Performance Validation for SC-004 (N=$N directories)"
    echo "=================================================="

    # Setup
    echo "Setting up test directories..."
    setup_test_dirs || { echo "ERROR: Failed to setup test directories" >&2; exit 2; }

    # Measure single directory time
    echo "Measuring single directory processing time..."
    local single_time
    single_time=$(measure_single_dir_time)
    echo "  Single directory time: ${single_time}s"

    # Measure N-directory time
    echo "Measuring N=$N directory processing time..."
    local multi_time
    multi_time=$(measure_multi_dir_time)
    echo "  Multi-directory time: ${multi_time}s"

    # Calculate expected maximum (N×single + 10% overhead)
    local expected_max
    expected_max=$(echo "scale=6; $single_time * $N * 1.10" | bc)
    echo "  Expected maximum (N×single + 10%): ${expected_max}s"

    # Verify requirement
    local comparison
    comparison=$(echo "$multi_time <= $expected_max" | bc)

    if [[ "$comparison" == "1" ]]; then
        echo ""
        echo "✓ PASS: Multi-directory time (${multi_time}s) ≤ N×single + 10% (${expected_max}s)"
        echo "  Performance requirement SC-004 met"
        exit 0
    else
        echo ""
        echo "✗ FAIL: Multi-directory time (${multi_time}s) > N×single + 10% (${expected_max}s)"
        echo "  Performance requirement SC-004 not met"
        local overhead_pct
        overhead_pct=$(echo "scale=2; (($multi_time / ($single_time * $N)) - 1) * 100" | bc)
        echo "  Actual overhead: ${overhead_pct}%"
        exit 1
    fi
}

main "$@"
