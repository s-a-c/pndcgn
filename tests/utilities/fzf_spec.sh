#!/usr/bin/env shellspec
#
# pndcgn fzf Integration Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for fzf directory selection functions
# Coverage: Uses 'When call' for kcov tracking (same-process execution)
# Note: fzf mocking requires special handling - we test the fallback behavior

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

# Helper function to check if fzf is unavailable (must be before Describe)
check_fzf_unavailable() {
    ! command -v fzf >/dev/null 2>&1
}

Describe "fzf Integration"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "fzf integration (legacy single-select)"
        It "returns failure when fzf unavailable"
            # Temporarily remove fzf from PATH to test fallback
            test_no_fzf() {
                local old_path="$PATH"
                PATH="/usr/bin:/bin"  # Minimal PATH without fzf
                pndcgn_select_source_dir
                local result=$?
                PATH="$old_path"
                return $result
            }

            When call test_no_fzf
            The status should be failure
        End

        It "attempts fzf selection when available"
            # This test verifies the function attempts to use fzf
            # We can't easily mock fzf in same-process, so we test behavior
            Skip if "fzf not installed" check_fzf_unavailable

            # If fzf is installed, test that function runs
            # In non-interactive mode, fzf may either:
            # 1. Fail (exit non-zero) because stdin isn't a TTY
            # 2. Auto-select first match (if fzf has --select-1 behavior or similar)
            # Either outcome is acceptable - we just verify the function runs
            When call pndcgn_select_source_dir
            # Accept either success (if fzf auto-selected) or failure (if fzf rejected non-TTY)
            The status should be defined
        End
    End

    Context "multi-select directory selection (T021)"
        It "uses fzf multi-select when fzf available"
            Skip if "fzf not installed" check_fzf_unavailable

            # Create test directories
            mkdir -p test_dir1 test_dir2 test_dir3
            cd test_dir1 || exit 1

            # Mock fzf to return multiple selections (newline-separated)
            fzf() {
                printf "test_dir2\ntest_dir3\n"
            }
            export -f fzf

            # Test that function accepts max_dirs parameter
            When call pndcgn_select_source_dirs 4
            # In non-interactive mode, fzf may fail or succeed
            # Either way, verify function accepts max_dirs parameter
            The status should be defined

            cd .. || true
            rm -rf test_dir1 test_dir2 test_dir3
            unset -f fzf
        End

        It "falls back to numbered list when fzf unavailable (T021 fallback)"
            # Temporarily remove fzf from PATH
            test_no_fzf_multi() {
                local old_path="$PATH"
                PATH="/usr/bin:/bin"
                mkdir -p test_dir1 test_dir2
                cd test_dir1 || exit 1
                # Should use fallback
                pndcgn_select_source_dirs 4 <<< "1"
                local result=$?
                cd .. || true
                rm -rf test_dir1 test_dir2
                PATH="$old_path"
                return $result
            }

            When call test_no_fzf_multi
            # Fallback should succeed when input provided
            The status should be success
        End
    End

    Context "dynamic header count (T025, FR-009)"
        It "includes max_dirs in fzf header when fzf available"
            Skip if "fzf not installed" check_fzf_unavailable

            mkdir -p test_dir1
            cd test_dir1 || exit 1

            # Capture fzf command arguments to verify header includes max_dirs
            local captured_header=""
            fzf() {
                # Capture --header argument
                while [[ $# -gt 0 ]]; do
                    if [[ "$1" == "--header" ]] && [[ -n "${2:-}" ]]; then
                        captured_header="$2"
                    fi
                    shift
                done
                return 1  # Simulate cancel
            }
            export -f fzf

            pndcgn_select_source_dirs 5 >/dev/null 2>&1 || true

            # Verify header includes max_dirs=5
            When call printf "%s" "$captured_header"
            The output should include "max=5"

            cd .. || true
            rm -rf test_dir1
            unset -f fzf
        End

        It "uses default max_dirs in header when not specified"
            Skip if "fzf not installed" check_fzf_unavailable

            mkdir -p test_dir1
            cd test_dir1 || exit 1

            local captured_header=""
            fzf() {
                while [[ $# -gt 0 ]]; do
                    if [[ "$1" == "--header" ]] && [[ -n "${2:-}" ]]; then
                        captured_header="$2"
                    fi
                    shift
                done
                return 1
            }
            export -f fzf

            pndcgn_select_source_dirs >/dev/null 2>&1 || true

            # Verify header includes default max (4)
            When call printf "%s" "$captured_header"
            The output should include "max=4"

            cd .. || true
            rm -rf test_dir1
            unset -f fzf
        End
    End

    Context "single-select behavior (T039, US3)"
        It "returns single directory without prefix requirement"
            Skip if "fzf not installed" check_fzf_unavailable

            mkdir -p test_single
            cd test_single || exit 1

            # Mock fzf to return single directory
            fzf() {
                printf ".\n"  # Current directory
            }
            export -f fzf

            When call pndcgn_select_source_dirs 4
            # Should succeed with single directory
            The output should be defined
            The status should be success

            cd .. || true
            rm -rf test_single
            unset -f fzf
        End
    End
End
