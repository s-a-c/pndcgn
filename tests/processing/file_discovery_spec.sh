#!/usr/bin/env shellspec
#
# pndcgn File Discovery Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for file discovery functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "File Discovery"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014e: File discovery respecting .pndcgnignore patterns
    Context "file discovery"
        It "discovers markdown files in source directory"
            mkdir -p test_source
            echo "# Test" > test_source/file1.md
            echo "# Test" > test_source/file2.txt

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "file1.md"
            The status should be success

            rm -rf test_source
        End

        It "respects .pndcgnignore patterns"
            mkdir -p test_source
            echo "# Test" > test_source/file1.md
            echo "# Test" > test_source/ignored.md
            echo "ignored.md" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source' '$PWD/test_source/.pndcgnignore'"
            The output should include "file1.md"
            The output should not include "ignored.md"
            The status should be success

            rm -rf test_source
        End

        It "discovers multiple supported formats"
            mkdir -p test_source
            touch test_source/file.md test_source/file.markdown test_source/file.txt test_source/file.rst

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "file.md"
            The output should include "file.markdown"
            The output should include "file.txt"
            The output should include "file.rst"

            rm -rf test_source
        End
    End
End
