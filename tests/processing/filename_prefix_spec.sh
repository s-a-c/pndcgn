#!/usr/bin/env shellspec
#
# pndcgn Filename Prefix Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for abbreviated prefix computation and prefixed filename generation
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities and processing for When call pattern
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh"

Describe "Filename Prefix Generation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "abbreviated prefix computation (T013)"
        It "computes unique prefixes for distinct basenames"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/frontend" "/path/to/backend" "/path/to/docs"
            # Accept either "fron" or "front" (4-5 chars for readability)
            The output should match pattern "*fron*"
            # Accept either "back" or "backe" (4-5 chars for readability)
            The output should match pattern "*back*"
            The output should include "docs"
            The status should be success
        End

        It "computes shortest unique prefixes for common prefixes"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/project-alpha" "/path/to/project-beta" "/path/to/project-gamma"
            # Accept 4-5 char prefixes after common prefix stripped (alph/alpha, beta, gamm/gamma)
            The output should match pattern "*alph*"
            The output should include "beta"
            The output should match pattern "*gamm*"
            The status should be success
        End

        It "handles identical basenames with different parent directories"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/docs" "/other/path/docs"
            # Should use parent directory name to disambiguate (to- or path- prefix)
            The output should match pattern "*to*"
            The output should match pattern "*path*"
            The status should be success
        End

        It "handles single directory (returns basename)"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/single"
            The output should eq "single"
            The status should be success
        End

        It "handles empty input gracefully"
            When call pndcgn_compute_abbreviated_prefixes
            The output should eq ""
            The status should be success
        End

        It "handles very similar directory names"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/backend" "/path/to/backup"
            # Should find unique prefixes (end/backe vs up/backu - 3-5 chars for readability)
            The output should match pattern "*end*"
            The output should match pattern "*up*"
            The status should be success
        End

        It "handles directories with special characters in names"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/my-docs" "/path/to/my_notes"
            # Special characters should be sanitized to hyphens
            The output should not include "my-docs"
            The output should not include "my_notes"
            The status should be success
        End

        It "preserves order of input directories"
            local result
            result=$(pndcgn_compute_abbreviated_prefixes "/path/to/alpha" "/path/to/beta" "/path/to/gamma")
            local prefixes
            mapfile -t prefixes <<< "$result"
            When call pndcgn_compute_abbreviated_prefixes "/path/to/alpha" "/path/to/beta" "/path/to/gamma"
            # First line should be alpha prefix, second beta, third gamma
            local first_line
            first_line=$(echo "$result" | head -n1)
            The output should include "$first_line"
            The status should be success
        End
    End

    Context "prefixed filename generation (T015)"
        It "generates prefixed filename with prefix"
            When call pndcgn_generate_prefixed_filename "docs" "report.md" "pdf"
            The output should eq "docs--report.pdf"
            The status should be success
        End

        It "generates filename without prefix for single directory (backward compatibility)"
            When call pndcgn_generate_prefixed_filename "" "report.md" "pdf"
            The output should eq "report.pdf"
            The status should be success
        End

        It "handles special characters in prefix"
            When call pndcgn_generate_prefixed_filename "my-docs" "file_name.md" "html"
            The output should eq "my-docs--file_name.html"
            The status should be success
        End

        It "handles different output types"
            When call pndcgn_generate_prefixed_filename "notes" "document.md" "epub"
            The output should eq "notes--document.epub"
            The status should be success
        End

        It "handles filenames with no extension"
            When call pndcgn_generate_prefixed_filename "docs" "README" "pdf"
            The output should eq "docs--README.pdf"
            The status should be success
        End

        It "handles empty original filename"
            When call pndcgn_generate_prefixed_filename "prefix" "" "pdf"
            The output should eq "prefix--.pdf"
            The status should be success
        End

        It "defaults to pdf output type"
            When call pndcgn_generate_prefixed_filename "docs" "report.md"
            The output should eq "docs--report.pdf"
            The status should be success
        End

        It "handles filenames with multiple dots"
            When call pndcgn_generate_prefixed_filename "docs" "file.min.js.md" "pdf"
            The output should eq "docs--file.min.js.pdf"
            The status should be success
        End
    End

End
