#!/usr/bin/env bash
# Generate markdown test reports from log files

set -euo pipefail

RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${RESULTS_DIR}/logs"
REPORTS_DIR="${RESULTS_DIR}/reports"

# Ensure directories exist
mkdir -p "${LOGS_DIR}" "${REPORTS_DIR}"

cd "${LOGS_DIR}"

for log_file in *.log; do
    if [[ ! -f "${log_file}" ]]; then
        continue
    fi

    # Extract test name and timestamp from filename
    # Format: testname-YYYYMMDD-HHMMSS.log
    base_name="${log_file%.log}"

    # Handle format: testname-YYYYMMDD-HHMMSS
    # Try to match timestamp pattern at the end
    if [[ "${base_name}" =~ ^(.+)-([0-9]{8}-[0-9]{6})$ ]]; then
        test_name="${BASH_REMATCH[1]}"
        timestamp="${BASH_REMATCH[2]}"
    else
        # Fallback: split on last dash
        test_name="${base_name%-*}"
        timestamp="${base_name##*-}"
    fi

    # Parse timestamp for human-readable format
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
    examples=$(grep -oE '[0-9]+ examples' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")
    failures=$(grep -oE '[0-9]+ failures' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")
    warnings=$(grep -oE '[0-9]+ warnings' "${log_file}" | tail -1 | grep -oE '[0-9]+' || echo "0")

    # Extract failed test descriptions (clean, human-readable)
    # ShellSpec formats:
    #   1. "    test description (FAILED - N)"
    #   2. "shellspec file:line # N) Full description FAILED"
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

    # Generate markdown report
    md_file="${REPORTS_DIR}/${log_file%.log}.md"

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
done

echo ""
echo "All reports generated successfully."
echo "Reports saved to: ${REPORTS_DIR}"
