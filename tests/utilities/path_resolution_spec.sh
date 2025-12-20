#!/usr/bin/env shellspec
#
# pndcgn Path Resolution Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for path resolution functions
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "Path Resolution"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "path resolution"
        It "resolves absolute paths"
            When call pndcgn_resolve_path "/tmp/test"
            The output should eq "/tmp/test"
            The status should be success
        End

        It "resolves relative paths"
            mkdir -p test_dir
            cd test_dir
            When call pndcgn_resolve_path "."
            The output should match pattern "*test_dir*"
            The status should be success
            cd ..
            rm -rf test_dir
        End

        It "defaults to current directory for empty path"
            When call pndcgn_resolve_path ""
            The output should not eq ""
            The status should be success
        End
    End
End
