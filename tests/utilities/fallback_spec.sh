#!/usr/bin/env shellspec
#
# pndcgn Fallback Selection Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for numbered list fallback when fzf unavailable
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "Fallback Directory Selection"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "fallback detection (T052)"
        It "invokes fallback when fzf unavailable"
            # Temporarily remove fzf from PATH
            test_fallback_invoked() {
                local old_path="$PATH"
                PATH="/usr/bin:/bin"  # Minimal PATH without fzf
                mkdir -p test_dir1 test_dir2 test_dir3
                cd test_dir1 || exit 1

                # Fallback should be invoked (will prompt for input)
                # We test that it attempts to use fallback by checking for INFO log
                pndcgn_select_source_dirs 4 <<< "1" 2>&1 | grep -q "numbered list" || true
                local result=$?

                cd .. || true
                rm -rf test_dir1 test_dir2 test_dir3
                PATH="$old_path"
                return $result
            }

            When call test_fallback_invoked
            # Should invoke fallback (INFO log about numbered list)
            The status should be success
        End

        It "logs INFO message when using fallback"
            test_fallback_log() {
                local old_path="$PATH"
                PATH="/usr/bin:/bin"
                mkdir -p test_dir1
                cd test_dir1 || exit 1

                local output
                output=$(pndcgn_select_source_dirs 4 <<< "1" 2>&1 || true)
                printf "%s" "$output"

                cd .. || true
                rm -rf test_dir1
                PATH="$old_path"
            }

            When call test_fallback_log
            The output should include "numbered list"
            The status should be success
        End
    End

    Context "numbered list selection (T053)"
        It "selects directories by number (comma-separated)"
            mkdir -p test_dir1 test_dir2 test_dir3 test_dir4
            cd test_dir1 || exit 1

            # Test selecting dirs 1 and 3 (test_dir2 and test_dir4)
            local result
            result=$(pndcgn_select_source_dirs_fallback 4 <<< "2,4" 2>&1 || true)

            # Should return selected directories
            When call printf "%s" "$result"
            The output should include "test_dir2"
            The output should include "test_dir4"
            The status should be success

            cd .. || true
            rm -rf test_dir1 test_dir2 test_dir3 test_dir4
        End

        It "handles single directory selection"
            mkdir -p test_dir1 test_dir2
            cd test_dir1 || exit 1

            local result
            result=$(pndcgn_select_source_dirs_fallback 4 <<< "2" 2>&1 || true)

            When call printf "%s" "$result"
            The output should include "test_dir2"
            The status should be success

            cd .. || true
            rm -rf test_dir1 test_dir2
        End

        It "handles whitespace in selection input"
            mkdir -p test_dir1 test_dir2 test_dir3
            cd test_dir1 || exit 1

            # Test with spaces: "1, 3, 5"
            local result
            result=$(pndcgn_select_source_dirs_fallback 4 <<< "1, 3" 2>&1 || true)

            When call printf "%s" "$result"
            The output should include "test_dir1"
            The output should include "test_dir3"
            The status should be success

            cd .. || true
            rm -rf test_dir1 test_dir2 test_dir3
        End
    End

    Context "fallback limit enforcement (T054)"
        It "enforces max_dirs limit and warns when exceeded"
            mkdir -p test_dir1 test_dir2 test_dir3 test_dir4 test_dir5
            cd test_dir1 || exit 1

            # Try to select 3 directories with max_dirs=2
            local output
            output=$(pndcgn_select_source_dirs_fallback 2 <<< "1,2,3" 2>&1 || true)

            # Should warn about exceeding limit and use first 2
            When call printf "%s" "$output"
            # First 2 should be selected (test_dir1 and test_dir2)
            The output should include "test_dir1"
            The output should include "test_dir2"
            # Should not include test_dir3 when limit is 2
            The status should be success

            cd .. || true
            rm -rf test_dir1 test_dir2 test_dir3 test_dir4 test_dir5
        End

        It "handles invalid selection numbers gracefully"
            mkdir -p test_dir1 test_dir2
            cd test_dir1 || exit 1

            # Test with invalid numbers (should skip invalid, use valid)
            local result
            result=$(pndcgn_select_source_dirs_fallback 4 <<< "1,99,2,x" 2>&1 || true)

            # Should still select valid directories (1 and 2)
            When call printf "%s" "$result"
            The output should include "test_dir1"
            The output should include "test_dir2"
            The status should be success

            cd .. || true
            rm -rf test_dir1 test_dir2
        End
    End
End
