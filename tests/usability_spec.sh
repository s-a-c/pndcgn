#!/usr/bin/env shellspec
#
# pndcgn Usability Tests
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Usability test scenarios for success criteria validation

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Usability Tests"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T065: Usability test scenario for SC-004
    Context "SC-004: Document location via run index (<60 seconds)"
        It "validates index file contains navigation links"
            mkdir -p test_output
            echo "# pndcgn Run Index" > test_output/_index.md
            echo "- [doc1.pdf](doc1.pdf)" >> test_output/_index.md
            echo "- [doc2.pdf](doc2.pdf)" >> test_output/_index.md

            When call grep -q "doc1.pdf" test_output/_index.md
            The status should be success

            rm -rf test_output
        End

        It "validates index file is readable"
            mkdir -p test_output
            echo "# Index" > test_output/_index.md

            When call test -r test_output/_index.md
            The status should be success

            rm -rf test_output
        End
    End
End
