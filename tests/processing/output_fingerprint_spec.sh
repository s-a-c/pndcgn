#!/usr/bin/env shellspec
#
# pndcgn Output Fingerprint Computation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for output fingerprint computation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Output Fingerprint Computation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014m: Output fingerprint computation
    Context "output fingerprint computation"
        It "computes output fingerprint in correct format"
            mkdir -p test_output
            echo "content1" > test_output/file1.pdf
            echo "content2" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_output_fingerprint '$PWD/test_output'"
            The output should match pattern "*:*:*"  # Format: total_size:artifact_count:sha256
            The status should be success

            rm -rf test_output
        End

        It "returns failure for non-existent directory"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_output_fingerprint '/nonexistent/dir'"
            The status should be failure
        End

        It "includes all artifacts in fingerprint"
            mkdir -p test_output
            echo "content1" > test_output/file1.pdf
            echo "content2" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_output_fingerprint '$PWD/test_output'"
            # Fingerprint should contain artifact count
            The output should match pattern "*:2:*"

            rm -rf test_output
        End

        It "produces consistent fingerprints for same content"
            mkdir -p test_output1 test_output2
            echo "same content" > test_output1/file.pdf
            echo "same content" > test_output2/file.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && fp1=\$(pndcgn_compute_output_fingerprint '$PWD/test_output1') && fp2=\$(pndcgn_compute_output_fingerprint '$PWD/test_output2') && [ \"\$fp1\" = \"\$fp2\" ] && echo \"\$fp1\""
            The output should not eq ""

            rm -rf test_output1 test_output2
        End
    End
End
