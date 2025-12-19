#!/usr/bin/env bash
# Reorganize test results into date-stamped folders (YYYY-MM-DD)
#
# This script reorganizes existing files in tests.results/{reports,logs,coverage}
# into date-stamped subdirectories.

set -euo pipefail

RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="${RESULTS_DIR}/reports"
LOGS_DIR="${RESULTS_DIR}/logs"
COVERAGE_DIR="${RESULTS_DIR}/coverage"

# Extract date from filename (format: name-YYYYMMDD-HHMMSS.ext)
# Returns: YYYY-MM-DD or empty string if no match
extract_date_from_filename() {
    local filename="$1"
    local basename="${filename##*/}"

    # Try to match timestamp pattern: YYYYMMDD-HHMMSS
    if [[ "${basename}" =~ ([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{6}) ]]; then
        local year="${BASH_REMATCH[1]}"
        local month="${BASH_REMATCH[2]}"
        local day="${BASH_REMATCH[3]}"
        printf "%s-%s-%s" "${year}" "${month}" "${day}"
        return 0
    fi

    # Fallback: try to get modification date
    if [[ -f "${filename}" ]]; then
        # Get file modification date (YYYY-MM-DD)
        if command -v stat >/dev/null 2>&1; then
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS stat
                stat -f "%Sm" -t "%Y-%m-%d" "${filename}" 2>/dev/null || printf ""
            else
                # Linux stat
                stat -c "%y" "${filename}" 2>/dev/null | cut -d' ' -f1 || printf ""
            fi
        else
            # Fallback to date command
            date -r "${filename}" +%Y-%m-%d 2>/dev/null || printf ""
        fi
        return 0
    fi

    printf ""
    return 0
}

# Reorganize files in a directory
reorganize_directory() {
    local dir="$1"
    local dir_type="$2"  # "reports", "logs", or "coverage"

    if [[ ! -d "${dir}" ]]; then
        echo "Directory does not exist: ${dir}"
        return 0
    fi

    local file_count=0
    local moved_count=0
    local skipped_count=0

    echo "Processing ${dir_type}/..."

    # Process files (not directories)
    local files_found=0
    while IFS= read -r -d '' file; do
        files_found=1
        ((file_count++)) || true
        local basename="${file##*/}"

        # Extract date from filename
        local date_folder
        date_folder=$(extract_date_from_filename "${file}" || true)

        if [[ -z "${date_folder}" ]]; then
            echo "  ⚠️  Could not extract date from: ${basename} (skipping)"
            ((skipped_count++)) || true
            continue
        fi

        # Create date-stamped subdirectory
        local target_dir="${dir}/${date_folder}"
        mkdir -p "${target_dir}"

        # Move file to date-stamped folder
        local target_file="${target_dir}/${basename}"
        if [[ -f "${target_file}" ]]; then
            echo "  ⚠️  File already exists: ${target_file} (skipping)"
            ((skipped_count++)) || true
            continue
        fi

        mv "${file}" "${target_file}"
        echo "  ✓ Moved: ${basename} → ${date_folder}/"
        ((moved_count++)) || true

    done < <(find "${dir}" -maxdepth 1 -type f -print0 2>/dev/null || true) || true

    if [[ ${files_found} -eq 0 ]]; then
        echo "  (no files to process)"
    fi

    # Handle coverage subdirectories specially (they may contain nested files)
    if [[ "${dir_type}" == "coverage" ]]; then
        # Move subdirectories that look like date-stamped already
        while IFS= read -r -d '' subdir; do
            local subdir_basename="${subdir##*/}"

            # Skip if already a date-stamped folder (YYYY-MM-DD format)
            if [[ "${subdir_basename}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                continue
            fi

            # Try to determine date from subdirectory name or contents
            local date_folder
            date_folder=$(extract_date_from_filename "${subdir_basename}")

            # If no date in name, try to get from first file in subdirectory
            if [[ -z "${date_folder}" ]]; then
                local first_file
                first_file=$(find "${subdir}" -type f | head -1)
                if [[ -n "${first_file}" ]]; then
                    date_folder=$(extract_date_from_filename "${first_file}")
                fi
            fi

            # If still no date, use modification date of subdirectory
            if [[ -z "${date_folder}" ]] && [[ -d "${subdir}" ]]; then
                if command -v stat >/dev/null 2>&1; then
                    if [[ "$(uname)" == "Darwin" ]]; then
                        date_folder=$(stat -f "%Sm" -t "%Y-%m-%d" "${subdir}" 2>/dev/null || printf "")
                    else
                        date_folder=$(stat -c "%y" "${subdir}" 2>/dev/null | cut -d' ' -f1 || printf "")
                    fi
                fi
            fi

            if [[ -z "${date_folder}" ]]; then
                echo "  ⚠️  Could not determine date for subdirectory: ${subdir_basename} (skipping)"
                ((skipped_count++))
                continue
            fi

            # Create date-stamped subdirectory
            local target_dir="${dir}/${date_folder}"
            mkdir -p "${target_dir}"

            # Move subdirectory into date-stamped folder
            local target_subdir="${target_dir}/${subdir_basename}"
            if [[ -d "${target_subdir}" ]]; then
                echo "  ⚠️  Subdirectory already exists: ${target_subdir} (skipping)"
                ((skipped_count++))
                continue
            fi

            mv "${subdir}" "${target_subdir}"
            echo "  ✓ Moved subdirectory: ${subdir_basename} → ${date_folder}/"
            ((moved_count++))

        done < <(find "${dir}" -maxdepth 1 -type d ! -path "${dir}" -print0 2>/dev/null || true)
    fi

    echo "  Summary: ${moved_count} moved, ${skipped_count} skipped (${file_count} files processed)"
    echo ""
}

# Main
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Reorganizing test results into date-stamped folders (YYYY-MM-DD)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    reorganize_directory "${REPORTS_DIR}" "reports"
    reorganize_directory "${LOGS_DIR}" "logs"
    reorganize_directory "${COVERAGE_DIR}" "coverage"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Reorganization complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
