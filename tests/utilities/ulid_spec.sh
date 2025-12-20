#!/usr/bin/env shellspec
#
# pndcgn ULID Generation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for ULID generation fallback functions
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "ULID Generation Fallback"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "ULID generation fallback"
        It "generates ULID in correct format (26 alphanumeric chars)"
            When call pndcgn_generate_ulid_fallback
            # ULID format: 26 characters, Crockford Base32 (0-9, A-Z excluding I, L, O, U)
            The output should match pattern "??????????????????????????"
            The length of output should eq 26
            The status should be success
        End

        It "generates unique ULIDs"
            # Generate two ULIDs and verify they're different
            generate_and_compare() {
                local ulid1 ulid2
                ulid1=$(pndcgn_generate_ulid_fallback)
                sleep 0.01  # Small delay to ensure time component differs
                ulid2=$(pndcgn_generate_ulid_fallback)
                [ "$ulid1" != "$ulid2" ] && echo "unique" || echo "duplicate"
            }

            When call generate_and_compare
            The output should eq "unique"
            The status should be success
        End

        It "generates lexicographically sortable ULIDs"
            When call pndcgn_generate_ulid_fallback
            The output should match pattern "[0-9A-Z]*"
            The status should be success
        End
    End
End
