#!/usr/bin/env shellspec
#
# pndcgn Dewey Decimal Naming Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for Dewey Decimal naming functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Dewey Decimal Naming"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014j: Dewey Decimal naming scheme
    Context "Dewey Decimal naming"
        It "generates Dewey Decimal prefix for file"
            mkdir -p test_source/subdir
            touch test_source/subdir/file.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_dewey_prefix '$PWD/test_source/subdir/file.md' '$PWD/test_source'"
            The output should match pattern "[0-9][0-9][0-9]"  # Format: 001 (or 001.002 for nested)
            The status should be success

            rm -rf test_source
        End

        It "generates prefix for root-level file"
            mkdir -p test_source
            touch test_source/file.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_dewey_prefix '$PWD/test_source/file.md' '$PWD/test_source'"
            The output should eq "000"
            The status should be success

            rm -rf test_source
        End
    End
End
