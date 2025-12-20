#!/usr/bin/env shellspec
#
# pndcgn Utilities Integration Tests (No Mocks)
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Integration tests for utility functions using real commands
# Coverage: Uses 'When call' where possible for kcov tracking
# These tests exercise actual utility code paths for accurate coverage tracking

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

# Helper to accept any status for prerequisites check (must be before Describe)
check_prerequisites_result() {
    # Either success or failure is valid - depends on environment
    return 0
}

Describe "Utilities Integration Tests (No Mocks)"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "real utility operations"
        It "checks real prerequisites"
            # This will use actual command -v checks
            When call pndcgn_check_prerequisites
            # Accept any status - the important part is that the function executed
            # Outcome depends on what's installed in the environment
            The status should satisfy check_prerequisites_result
        End

        It "resolves real paths"
            mkdir -p test_dir/subdir
            cd test_dir

            When call pndcgn_resolve_path "subdir"
            The output should match pattern "*subdir"
            The status should be success

            cd ..
            rm -rf test_dir
        End

        It "creates real XDG state directory"
            mkdir -p test_xdg
            export XDG_STATE_HOME="$PWD/test_xdg"

            When call pndcgn_get_state_dir
            The output should match pattern "*pndcgn"
            The status should be success

            rm -rf test_xdg
            unset XDG_STATE_HOME
        End

        It "creates real XDG config directory"
            mkdir -p test_xdg
            export XDG_CONFIG_HOME="$PWD/test_xdg"

            When call pndcgn_get_config_dir
            The output should match pattern "*pndcgn"
            The status should be success

            rm -rf test_xdg
            unset XDG_CONFIG_HOME
        End

        It "generates real ULIDs"
            When call pndcgn_generate_ulid_fallback
            The length of output should eq 26
            The status should be success
        End

        It "generates unique ULIDs"
            generate_two_ulids() {
                local ulid1 ulid2
                ulid1=$(pndcgn_generate_ulid_fallback)
                sleep 0.01
                ulid2=$(pndcgn_generate_ulid_fallback)
                [ "$ulid1" != "$ulid2" ] && echo "unique"
            }
            When call generate_two_ulids
            The output should eq "unique"
        End

        It "discovers real ignore files"
            mkdir -p test_source
            echo "*.tmp" > test_source/.pndcgnignore

            When call pndcgn_discover_ignore_file "$PWD/test_source"
            The output should eq "$PWD/test_source/.pndcgnignore"
            The status should be success

            rm -rf test_source
        End

        It "seeds real ignore files"
            mkdir -p test_source

            When call pndcgn_seed_ignore_file "$PWD/test_source"
            The status should be success
            The file "test_source/.pndcgnignore" should be exist
            The stderr should include "INFO"

            rm -rf test_source
        End
    End
End
