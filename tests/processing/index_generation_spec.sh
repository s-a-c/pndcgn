#!/usr/bin/env shellspec
#
# pndcgn Index Generation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for index generation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Index Generation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014l: Run index generation (_index.md format)
    Context "index generation"
        It "generates _index.md file"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'test-run-id' '{\"total\":1,\"processed\":1}'"
            The status should be success
            The file "test_output/_index.md" should be exist
            The contents of file "test_output/_index.md" should include "test-run-id"
            The contents of file "test_output/_index.md" should include "Run Index"

            rm -rf test_output
        End

        It "includes statistics in index"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'run-id' '{\"total\":5,\"processed\":3,\"skipped\":2}'"
            The contents of file "test_output/_index.md" should include "Statistics"

            rm -rf test_output
        End

        It "lists generated artifacts"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf
            echo "content" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'run-id' '{}'"
            The contents of file "test_output/_index.md" should include "file1.pdf"
            The contents of file "test_output/_index.md" should include "file2.pdf"

            rm -rf test_output
        End
    End
End
