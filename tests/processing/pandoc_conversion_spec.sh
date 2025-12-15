#!/usr/bin/env shellspec
#
# pndcgn Pandoc Conversion Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for pandoc conversion functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Pandoc Conversion"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014i: Pandoc conversion function
    Context "pandoc conversion"
        It "converts file using pandoc"
            mkdir -p test_source test_output
            echo "# Test" > test_source/test.md

            pandoc() {
                # pandoc syntax: pandoc input -o output -t type
                # So $1=input, $2=-o, $3=output, $4=-t, $5=type
                local output_file="$3"
                echo "PDF content" > "$output_file"
            }
            export -f pandoc

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_convert_file '$PWD/test_source/test.md' '$PWD/test_output/test.pdf' 'pdf'"
            The status should be success
            The file "test_output/test.pdf" should be exist

            unset -f pandoc
            rm -rf test_source test_output
        End

        It "returns failure for non-existent source file"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_convert_file '/nonexistent/file.md' '/tmp/output.pdf' 'pdf'"
            The status should be failure
            The stderr should include "ERROR"
        End
    End
End
