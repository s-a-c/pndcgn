#!/usr/bin/env shellspec
#
# pndcgn Overlap Detection Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for overlapping directory detection and exclusion
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "Overlapping Directory Detection"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "overlap detection behavior (T017)"
        It "returns all directories when no overlap exists"
            When call pndcgn_remove_overlapping_dirs "/path/to/project1" "/other/path/project2" "/different/project3"
            The output should include "project1"
            The output should include "project2"
            The output should include "project3"
            The status should be success
        End

        It "excludes subdirectory when one directory contains another"
            When call pndcgn_remove_overlapping_dirs "/path/to/project" "/path/to/project/docs"
            The output should include "/path/to/project"
            The output should not include "/path/to/project/docs"
            The stderr should include "Excluding subdirectory"
            The status should be success
        End

        It "excludes nested subdirectories"
            When call pndcgn_remove_overlapping_dirs "/path/to/project" "/path/to/project/docs" "/path/to/project/docs/subdir"
            The output should include "/path/to/project"
            The output should not include "/path/to/project/docs"
            The output should not include "/path/to/project/docs/subdir"
            The status should be success
        End

        It "handles single directory input"
            When call pndcgn_remove_overlapping_dirs "/path/to/single"
            The output should eq "/path/to/single"
            The status should be success
        End

        It "handles empty input gracefully"
            When call pndcgn_remove_overlapping_dirs
            The output should eq ""
            The status should be success
        End

        It "preserves order of non-overlapping directories"
            local result
            result=$(pndcgn_remove_overlapping_dirs "/path/to/alpha" "/path/to/beta" "/path/to/gamma")
            When call pndcgn_remove_overlapping_dirs "/path/to/alpha" "/path/to/beta" "/path/to/gamma"
            The output should include "alpha"
            The output should include "beta"
            The output should include "gamma"
            The status should be success
        End

        It "handles directories with trailing slashes"
            When call pndcgn_remove_overlapping_dirs "/path/to/project/" "/path/to/project/docs/"
            The output should include "/path/to/project"
            The output should not include "/path/to/project/docs"
            The status should be success
        End

        It "handles multiple overlapping directories (keeps parent, excludes all children)"
            When call pndcgn_remove_overlapping_dirs "/path/to/project" "/path/to/project/src" "/path/to/project/docs" "/path/to/project/tests"
            The output should include "/path/to/project"
            The output should not include "/path/to/project/src"
            The output should not include "/path/to/project/docs"
            The output should not include "/path/to/project/tests"
            The status should be success
        End

        It "handles case where child directory comes before parent in input"
            When call pndcgn_remove_overlapping_dirs "/path/to/project/docs" "/path/to/project"
            The output should include "/path/to/project"
            The output should not include "/path/to/project/docs"
            The status should be success
        End
    End

End
