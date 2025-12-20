#!/usr/bin/env shellspec
#
# pndcgn Logging Functions Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for logging functions (info, error, warn)
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "Logging Functions"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "logging functions"
        It "logs info messages"
            When call pndcgn_log_info "Test message"
            The stderr should include "INFO"
            The stderr should include "Test message"
            The status should be success
        End

        It "logs error messages"
            When call pndcgn_log_error "Error message"
            The stderr should include "ERROR"
            The stderr should include "Error message"
            The status should be success
        End

        It "logs warning messages"
            When call pndcgn_log_warn "Warning message"
            The stderr should include "WARN"
            The stderr should include "Warning message"
            The status should be success
        End
    End
End
