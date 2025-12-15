#!/usr/bin/env shellspec
#
# pndcgn Fingerprint Computation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for fingerprint computation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Fingerprint Computation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014f: Fingerprint computation (format validation)
    Context "fingerprint computation"
        It "computes fingerprint in correct format"
            mkdir -p test_source
            echo "test content" > test_source/test.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_fingerprint '$PWD/test_source/test.md'"
            The output should match pattern "*:*:*"  # Format: size:mtime:sha256
            The status should be success

            rm -rf test_source
        End

        It "returns failure for non-existent file"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_fingerprint '/nonexistent/file.md'"
            The status should be failure
        End

        It "produces consistent fingerprints for same file"
            mkdir -p test_source
            echo "test content" > test_source/test.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && fingerprint1=\$(pndcgn_compute_fingerprint '$PWD/test_source/test.md') && fingerprint2=\$(pndcgn_compute_fingerprint '$PWD/test_source/test.md') && [ \"\$fingerprint1\" = \"\$fingerprint2\" ] && echo \"\$fingerprint1\""
            The output should not eq ""
            The status should be success

            rm -rf test_source
        End
    End
End
