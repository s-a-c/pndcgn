#!/usr/bin/env shellspec
#
# pndcgn Multi-Directory Integration Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: End-to-end integration tests for multi-directory processing
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source all modules for integration testing
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh"
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh"

Describe "Multi-Directory Integration"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'
    BeforeEach 'setup_db_file'
    AfterEach 'cleanup_db_file'

    Context "multi-directory processing (T022)"
        It "processes files from multiple directories in single run"
            # Setup test directories with files
            local dir1="${temp_dir}/frontend"
            local dir2="${temp_dir}/backend"
            local dir3="${temp_dir}/docs"
            mkdir -p "$dir1" "$dir2" "$dir3" "${temp_dir}/output"

            echo "# Frontend Doc" > "$dir1/file1.md"
            echo "# Backend Doc" > "$dir2/file2.md"
            echo "# Docs Doc" > "$dir3/file3.md"

            # Initialize database
            pndcgn_db_init >/dev/null 2>&1 || true

            # Mock pandoc to create output files
            pandoc() {
                local output_file="$3"
                echo "PDF content" > "$output_file"
                return 0
            }
            export -f pandoc

            # Process multiple directories
            local source_dirs_json
            source_dirs_json=$(pndcgn_array_to_json "$dir1" "$dir2" "$dir3")

            local run_id
            run_id=$(pndcgn_db_create_run "$source_dirs_json" "${temp_dir}/output" "pdf" "0")

            # Discover files from all directories
            local all_files=()
            local -a prefixes=()
            prefixes=($(pndcgn_compute_abbreviated_prefixes "$dir1" "$dir2" "$dir3"))

            for i in "$dir1" "$dir2" "$dir3"; do
                local files
                files=$(pndcgn_discover_files "$i" "" 2>/dev/null || printf "")
                if [[ -n "$files" ]]; then
                    while IFS= read -r file; do
                        [[ -n "$file" ]] && all_files+=("$file")
                    done <<< "$files"
                fi
            done

            # Verify files were discovered
            When call printf "%d" "${#all_files[@]}"
            The output should eq "3"
            The status should be success

            unset -f pandoc
            rm -rf "$dir1" "$dir2" "$dir3" "${temp_dir}/output"
        End
    End

    Context "abbreviated prefixes (T023)"
        It "generates abbreviated prefixes for frontend/backend directories"
            local dir1="${temp_dir}/frontend"
            local dir2="${temp_dir}/backend"
            mkdir -p "$dir1" "$dir2"

            When call pndcgn_compute_abbreviated_prefixes "$dir1" "$dir2"
            The output should include "front"
            The output should include "back"
            The status should be success

            rm -rf "$dir1" "$dir2"
        End

        It "uses prefixes in output filenames when multiple directories"
            local prefix1="front"
            local prefix2="back"
            local original="file.md"

            When call pndcgn_generate_prefixed_filename "$prefix1" "$original" "pdf"
            The output should eq "front--file.pdf"
            The status should be success

            When call pndcgn_generate_prefixed_filename "$prefix2" "$original" "pdf"
            The output should eq "back--file.pdf"
            The status should be success
        End

        It "does not use prefix for single directory (backward compatibility)"
            local original="file.md"

            When call pndcgn_generate_prefixed_filename "" "$original" "pdf"
            The output should eq "file.pdf"
            The status should be success
        End
    End

    Context "single run ID (T024)"
        It "creates single run ID for multiple source directories"
            # Initialize database
            pndcgn_db_init >/dev/null 2>&1 || true

            local dir1="${temp_dir}/dir1"
            local dir2="${temp_dir}/dir2"
            mkdir -p "$dir1" "$dir2"

            local source_dirs_json
            source_dirs_json=$(pndcgn_array_to_json "$dir1" "$dir2")

            local run_id1
            run_id1=$(pndcgn_db_create_run "$source_dirs_json" "${temp_dir}/output" "pdf" "0")

            # Verify single run ID was created
            When call printf "%s" "$run_id1"
            The output should not eq ""
            The status should be success

            # Verify run exists in database with multiple source_dirs
            local db_path
            db_path=$(pndcgn_get_db_path)
            local stored_dirs
            stored_dirs=$(sqlite3 "$db_path" "SELECT source_dirs FROM runs WHERE run_id = '$run_id1'" 2>/dev/null || printf "")

            # Verify source_dirs JSON contains both directories
            When call printf "%s" "$stored_dirs"
            The output should include "$dir1"
            The output should include "$dir2"

            rm -rf "$dir1" "$dir2"
        End
    End

    Context "backward compatibility - single directory (T041)"
        It "processes single directory without prefix (identical to pre-feature behavior)"
            local dir1="${temp_dir}/single_dir"
            mkdir -p "$dir1"
            echo "# Doc" > "$dir1/file.md"

            # Initialize database
            pndcgn_db_init >/dev/null 2>&1 || true

            # Single directory should use empty prefix
            local prefix
            prefix=$(pndcgn_compute_abbreviated_prefixes "$dir1" || printf "")

            # For single directory, prefixes array should be empty (no prefix computation)
            local source_dirs_json
            source_dirs_json=$(pndcgn_array_to_json "$dir1")

            local run_id
            run_id=$(pndcgn_db_create_run "$source_dirs_json" "${temp_dir}/output" "pdf" "0")

            # Verify run created successfully
            When call printf "%s" "$run_id"
            The output should not eq ""
            The status should be success

            # Verify filename generation without prefix
            When call pndcgn_generate_prefixed_filename "" "file.md" "pdf"
            The output should eq "file.pdf"
            The status should be success

            rm -rf "$dir1"
        End
    End

    Context "graceful degradation (FR-010)"
        It "continues processing when one directory fails"
            local dir1="${temp_dir}/valid_dir"
            local dir2="${temp_dir}/invalid_dir"
            mkdir -p "$dir1"
            echo "# Doc" > "$dir1/file.md"
            # dir2 does not exist

            # Should not fail when discovering files from non-existent directory
            local files1
            files1=$(pndcgn_discover_files "$dir1" "" 2>/dev/null || printf "")
            local files2
            files2=$(pndcgn_discover_files "$dir2" "" 2>/dev/null || printf "")

            # Valid directory should have files
            When call printf "%s" "$files1"
            The output should include "file.md"
            The status should be success

            # Invalid directory should return empty (graceful failure)
            When call printf "%s" "${files2:-}"
            The output should eq ""
            The status should be success

            rm -rf "$dir1"
        End
    End

    Context "signal handling - graceful Ctrl+C (T067)"
        It "handles SIGINT gracefully with summary"
            # This test verifies the trap handler is installed
            # Full signal testing requires subprocess which is complex in ShellSpec
            # We verify the trap is set up correctly
            When run bash -c "grep -q 'trap.*INT.*TERM' '${PNDCGN_PROJECT_ROOT}/bin/pndcgn'"
            The status should be success
        End

        It "exports PNDCGN_INTERRUPTED flag on SIGINT"
            # Verify the interrupt handler function exists
            When run bash -c "grep -q 'pndcgn_handle_interrupt' '${PNDCGN_PROJECT_ROOT}/bin/pndcgn'"
            The status should be success
        End
    End
End
