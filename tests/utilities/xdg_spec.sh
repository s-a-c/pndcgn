#!/usr/bin/env shellspec
#
# pndcgn XDG Directory Support Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for XDG Base Directory support functions
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "XDG Directory Support"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "XDG directory support"
        It "creates XDG state directory"
            mkdir -p test_xdg
            export XDG_STATE_HOME="$PWD/test_xdg"

            When call pndcgn_get_state_dir
            The output should match pattern "*pndcgn"
            The status should be success

            rm -rf test_xdg
            unset XDG_STATE_HOME
        End

        It "creates XDG config directory"
            mkdir -p test_xdg
            export XDG_CONFIG_HOME="$PWD/test_xdg"

            When call pndcgn_get_config_dir
            The output should match pattern "*pndcgn"
            The status should be success

            rm -rf test_xdg
            unset XDG_CONFIG_HOME
        End
    End
End
