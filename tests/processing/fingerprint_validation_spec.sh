#!/usr/bin/env shellspec
#
# pndcgn Fingerprint Validation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for fingerprint validation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Fingerprint Validation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T029e: Fingerprint validation function
    Context "fingerprint validation"
        It "validates matching fingerprints"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_validate_fingerprint 'abc123' 'abc123'"
            The status should be success
        End

        It "rejects mismatched fingerprints"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_validate_fingerprint 'abc123' 'xyz789'"
            The status should be failure
            The stderr should include "mismatch"
        End

        It "rejects empty stored fingerprint"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_validate_fingerprint 'abc123' ''"
            The status should be failure
            The stderr should include "No stored fingerprint"
        End

        It "provides actionable error messages"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_validate_fingerprint 'current-fp' 'stored-fp'"
            The stderr should include "source files or configuration have changed"
            The stderr should include "create a new run"
        End
    End
End
