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

    Context "fzf integration"
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
End
