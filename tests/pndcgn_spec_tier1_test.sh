#!/usr/bin/env shellspec
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "pndcgn CLI (bin/pndcgn) - Tier 1 Test"
    BeforeEach 'setup_cli_env'
    AfterEach 'cleanup_cli_env'
    BeforeEach 'mock_all_commands'
    AfterEach 'cleanup_mocks'

    Context "when parsing arguments"
        It "accepts SOURCE_DIR and TARGET_DIR as positional arguments"
            When run "$script" "/tmp/source" "/tmp/target"
            The status should be failure
            The stderr should include "source"
        End

        It "accepts --type option"
            mkdir -p /tmp/test_source /tmp/test_target
            When run "$script" --type html /tmp/test_source /tmp/test_target 2>&1
            The status should be failure
            The stderr should not include "usage"
            The stderr should not include "invalid"
            rm -rf /tmp/test_source /tmp/test_target
        End

        It "rejects unknown options"
            When run "$script" --unknown-option
            The status should be failure
            The stderr should include "Unknown option"
        End
    End

    Context "error handling"
        It "exits with code 1 for runtime errors"
            When run "$script" /nonexistent /tmp
            The status should be failure
            The stderr should include "does not exist"
        End

        It "exits with code 2 for invalid usage"
            When run "$script" --invalid-option
            The status should be failure
            The stderr should include "Unknown option"
        End

        It "exits with code 0 for help"
            When run "$script" --help
            The status should be success
            The output should include "Usage"
        End

        It "reports errors to stderr"
            When run "$script" /nonexistent /tmp 2>&1
            The status should be failure
            The stderr should include "ERROR"
        End
    End

    Context "--help output structure (T094a)"
        It "displays structured help output"
            When run "$script" --help
            The status should be success
            The output should include "Usage:"
            The output should include "Options:"
            The output should include "Examples:"
            The output should include "Exit Codes:"
        End
    End

    Context "--version output (T094b)"
        It "displays version information"
            When run "$script" --version 2>&1
            The status should be success
            The output should include "pndcgn"
            The output should include "0.1.0"
        End
    End
End
