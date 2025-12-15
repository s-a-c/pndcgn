#!/usr/bin/env shellspec
#
# pndcgn Output Directory Creation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for output directory creation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Output Directory Creation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014k: Run output directory creation
    Context "output directory creation"
        It "creates output directory with correct format"
            mkdir -p test_target

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'"
            The output should match pattern "*/.pndcgn/pdf-test-run-id"
            The status should be success
            local output_dir
            output_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'")
            The directory "$output_dir" should be exist

            rm -rf test_target
        End

        It "creates nested directory structure"
            mkdir -p test_target

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'html' 'run123'"
            local output_dir
            output_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'html' 'run123'")
            The directory "$output_dir" should be exist

            rm -rf test_target
        End
    End
End
