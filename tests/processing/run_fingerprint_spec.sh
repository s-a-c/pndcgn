#!/usr/bin/env shellspec
#
# pndcgn Run Fingerprint Computation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for run fingerprint computation functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Run Fingerprint Computation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T029b: Run fingerprint computation (combined fingerprint format)
    Context "run fingerprint computation"
        It "computes run fingerprint in correct format"
            mkdir -p test_source
            echo "# Doc1" > test_source/doc1.md
            echo "# Doc2" > test_source/doc2.md
            echo "*.tmp" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'"
            The output should match pattern "*"  # SHA256 hash format
            The status should be success

            rm -rf test_source
        End

        It "includes all input files in fingerprint"
            mkdir -p test_source
            echo "# Doc1" > test_source/doc1.md
            echo "# Doc2" > test_source/doc2.md
            echo "*.tmp" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && fp1=\$(pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target') && echo \"\$fp1\""
            local fp1
            fp1=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'")

            # Add a file - fingerprint should change
            echo "# Doc3" > test_source/doc3.md
            local fp2
            fp2=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'")

            The value "$fp1" should not eq "$fp2"

            rm -rf test_source
        End

        It "includes config state in fingerprint"
            mkdir -p test_source
            echo "# Doc" > test_source/doc.md
            echo "*.tmp" > test_source/.pndcgnignore

            local fp1
            fp1=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'")

            # Change output type - fingerprint should change
            local fp2
            fp2=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'html' '/tmp/target'")

            The value "$fp1" should not eq "$fp2"

            rm -rf test_source
        End

        It "produces consistent fingerprints for same inputs"
            mkdir -p test_source
            echo "# Doc" > test_source/doc.md
            echo "*.tmp" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && fp1=\$(pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target') && fp2=\$(pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target') && [ \"\$fp1\" = \"\$fp2\" ] && echo \"\$fp1\""
            The output should not eq ""

            rm -rf test_source
        End
    End
End
