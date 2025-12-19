#!/usr/bin/env bash
# Generate markdown test reports from log files
# Supports both date-stamped folders (YYYY-MM-DD) and flat structure (backward compatibility)

set -euo pipefail

RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${RESULTS_DIR}/logs"
REPORTS_DIR="${RESULTS_DIR}/reports"

# Ensure directories exist
mkdir -p "${LOGS_DIR}" "${REPORTS_DIR}"

# Process a log file and generate report
process_log_file() {
    local log_file="$1"
    local reports_target_dir="$2"

    if [[ ! -f "${log_file}" ]]; then
        return 0
    fi

    # Extract test name and timestamp from filename
    # Format: testname-YYYYMMDD-HHMMSS.log
    local base_name="${log_file##*/}"
    base_name="${base_name%.log}"

    # Handle format: testname-YYYYMMDD-HHMMSS
    # Try to match timestamp pattern at the end
    local test_name
    local timestamp
    if [[ "${base_name}" =~ ^(.+)-([0-9]{8}-[0-9]{6})$ ]]; then
        test_name="${BASH_REMATCH[1]}"
        timestamp="${BASH_REMATCH[2]}"
    else
        # Fallback: split on last dash
        test_name="${base_name%-*}"
        timestamp="${base_name##*-}"
    fi

    # Parse timestamp for human-readable format
    local year month day hour min sec readable_date
    if [[ "${timestamp}" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
        year="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        day="${BASH_REMATCH[3]}"
        hour="${BASH_REMATCH[4]}"
        min="${BASH_REMATCH[5]}"
        sec="${BASH_REMATCH[6]}"
        readable_date="${year}-${month}-${day} ${hour}:${min}:${sec}"
    else
        readable_date="${timestamp}"
    fi

    # Extract summary statistics
    local examples failures warnings
    examples=$(grep -oE '[0-9]+ examples' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")
    failures=$(grep -oE '[0-9]+ failures' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")
    warnings=$(grep -oE '[0-9]+ warnings' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")

    # Extract failed test descriptions (clean, human-readable)
    # ShellSpec formats:
    #   1. "    test description (FAILED - N)"
    #   2. "shellspec file:line # N) Full description FAILED"
    local failed_tests
    failed_tests=$(grep -E "FAILED" "${log_file}" | \
        sed -E 's/\x1b\[[0-9;]*m//g' | \
        sed -E 's/.*# [0-9]+\)\s*([^W]*?)\s*FAILED.*/\1/' | \
        sed -E 's/.*\(FAILED - [0-9]+\)\s*//' | \
        sed -E 's/\s*FAILED.*$//' | \
        sed -E 's/^shellspec [^ ]+:[0-9]+\s*//' | \
        sed -E 's/^[[:space:]]+//' | \
        sed -E 's/[[:space:]]+$//' | \
        grep -vE '^[0-9]+$' | \
        grep -vE '^$' | \
        sort -u | \
        head -50 || echo "")

    # Extract warned test descriptions (clean, human-readable)
    # ShellSpec formats:
    #   1. "    test description (WARNED - N)"
    #   2. "shellspec file:line # N) Full description WARNED"
    local warned_tests
    warned_tests=$(grep -E "WARNED" "${log_file}" | \
        sed -E 's/\x1b\[[0-9;]*m//g' | \
        sed -E 's/.*# [0-9]+\)\s*([^W]*?)\s*WARNED.*/\1/' | \
        sed -E 's/.*\(WARNED - [0-9]+\)\s*//' | \
        sed -E 's/\s*WARNED.*$//' | \
        sed -E 's/^shellspec [^ ]+:[0-9]+\s*//' | \
        sed -E 's/^[[:space:]]+//' | \
        sed -E 's/[[:space:]]+$//' | \
        grep -vE '^[0-9]+$' | \
        grep -vE '^$' | \
        sort -u | \
        head -50 || echo "")

    # Generate markdown report in target reports directory
    local md_file="${reports_target_dir}/${base_name}.md"
    mkdir -p "${reports_target_dir}"

    {
        cat <<EOF
# Test Results Report: ${test_name}

**Test File**: \`tests/${test_name}.sh\`
**Execution Time**: ${readable_date}
**Timestamp**: ${timestamp}

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Examples** | ${examples} |
| **Failures** | ${failures} |
| **Warnings** | ${warnings} |
| **Success Rate** | $(if [[ "${examples}" -gt 0 ]]; then printf "%.1f%%" "$(echo "scale=1; (${examples} - ${failures}) * 100 / ${examples}" | bc)" || true; else echo "N/A"; fi) |

### Status
EOF

        if [[ "${failures}" -eq 0 ]] && [[ "${warnings}" -eq 0 ]]; then
            echo "✅ **All tests passed**"
        elif [[ "${failures}" -eq 0 ]]; then
            echo "⚠️  **All tests passed with warnings**"
        else
            echo "❌ **Some tests failed**"
        fi

        if [[ -n "${failed_tests}" ]]; then
            echo ""
            echo "## Failed Tests"
            echo ""
            echo "${failed_tests}" | while IFS= read -r test || [[ -n "${test}" ]]; do
                # Trim leading/trailing whitespace
                test=$(printf '%s' "${test}" | sed -E 's/^[[:space:]]+//' | sed -E 's/[[:space:]]+$//')
                if [[ -n "${test}" ]]; then
                    echo "- **${test}**"
                fi
            done
        fi

        if [[ -n "${warned_tests}" ]]; then
            echo ""
            echo "## Warnings"
            echo ""
            echo "${warned_tests}" | while IFS= read -r test || [[ -n "${test}" ]]; do
                # Trim leading/trailing whitespace
                test=$(printf '%s' "${test}" | sed -E 's/^[[:space:]]+//' | sed -E 's/[[:space:]]+$//')
                if [[ -n "${test}" ]]; then
                    echo "- **${test}**"
                fi
            done
        fi

        echo ""
        echo "---"
        echo ""
        echo "<details>"
        echo "<summary><strong>Full Test Log</strong></summary>"
        echo ""
        echo '```log'
        cat "${log_file}"
        echo '```'
        echo ""
        echo "</details>"

    } > "${md_file}"

    echo "Generated: ${md_file}"

    # Remove log file after successful report generation (full log is included in report)
    rm -f "${log_file}"
    echo "  Removed: ${log_file}"
}

# Main processing
main() {
    # Process date-stamped log directories (new structure)
    for log_date_dir in "${LOGS_DIR}"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]; do
        if [[ ! -d "${log_date_dir}" ]]; then
            continue
        fi

        # Extract date folder name (YYYY-MM-DD)
        local date_folder
        date_folder=$(basename "${log_date_dir}")

        # Create corresponding reports date directory
        local reports_date_dir="${REPORTS_DIR}/${date_folder}"

        echo "Processing logs in ${date_folder}/..."

        # Process all log files in this date directory
        while IFS= read -r -d '' log_file; do
            process_log_file "${log_file}" "${reports_date_dir}"
        done < <(find "${log_date_dir}" -maxdepth 1 -type f -name "*.log" -print0 2>/dev/null)

        echo ""
    done

    # Process log files directly in LOGS_DIR (backward compatibility - files without date folders)
    if [[ -d "${LOGS_DIR}" ]]; then
        while IFS= read -r -d '' log_file; do
            # Extract date from filename to determine target reports directory
            local base_name="${log_file##*/}"
            base_name="${base_name%.log}"

            local date_folder="${REPORTS_DIR}"  # Default to root reports dir
            if [[ "${base_name}" =~ ^(.+)-([0-9]{8}-[0-9]{6})$ ]]; then
                local timestamp="${BASH_REMATCH[2]}"
                if [[ "${timestamp}" =~ ^([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
                    local year="${BASH_REMATCH[1]}"
                    local month="${BASH_REMATCH[2]}"
                    local day="${BASH_REMATCH[3]}"
                    date_folder="${REPORTS_DIR}/${year}-${month}-${day}"
                fi
            fi

            process_log_file "${log_file}" "${date_folder}"
        done < <(find "${LOGS_DIR}" -maxdepth 1 -type f -name "*.log" -print0 2>/dev/null)
    fi

    echo ""
    echo "All reports generated successfully."
    echo "Reports saved to: ${REPORTS_DIR} (organized by date: YYYY-MM-DD/)"
}

main "$@"
