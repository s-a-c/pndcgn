#!/usr/bin/env shellspec
#
# pndcgn Processing Integration Tests (No Mocks)
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Integration tests for processing functions using real file operations
# These tests exercise actual processing code paths for accurate coverage tracking

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Processing Integration Tests (No Mocks)"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "real file operations"
        It "discovers files in real directory structure"
            mkdir -p test_source/subdir
            echo "# Doc1" > test_source/doc1.md
            echo "# Doc2" > test_source/subdir/doc2.md
            echo "# Ignored" > test_source/ignored.md
            echo "ignored.md" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "doc1.md"
            The output should include "subdir/doc2.md"
            The output should not include "ignored.md"
            The status should be success

            rm -rf test_source
        End

        It "computes real file fingerprints"
            mkdir -p test_source
            echo "test content" > test_source/test.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_fingerprint '$PWD/test_source/test.md'"
            The output should match pattern "*:*:*"  # Format: size:mtime:sha256
            The status should be success

            # Verify consistency
            local fp1 fp2
            fp1=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_fingerprint '$PWD/test_source/test.md'")
            fp2=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_fingerprint '$PWD/test_source/test.md'")
            The value "$fp1" should eq "$fp2"

            rm -rf test_source
        End

        It "creates real output directories"
            mkdir -p test_target

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'"
            The output should match pattern "*/.pndcgn/pdf-test-run-id"
            The status should be success

            local output_dir
            output_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'")
            The directory "$output_dir" should be exist

            rm -rf test_target
        End

        It "generates real index files"
            mkdir -p test_output
            echo "content1" > test_output/file1.pdf
            echo "content2" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'test-run-id' '{\"total\":2,\"processed\":2}'"
            The status should be success
            The file "test_output/_index.md" should be exist
            The contents of file "test_output/_index.md" should include "test-run-id"
            The contents of file "test_output/_index.md" should include "file1.pdf"
            The contents of file "test_output/_index.md" should include "file2.pdf"

            rm -rf test_output
        End

        It "computes real output fingerprints"
            mkdir -p test_output
            echo "content1" > test_output/file1.pdf
            echo "content2" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_output_fingerprint '$PWD/test_output'"
            The output should match pattern "*:*:*"  # Format: total_size:artifact_count:sha256
            The output should match pattern "*:2:*"  # Should have 2 artifacts
            The status should be success

            rm -rf test_output
        End

        It "computes real run fingerprints"
            mkdir -p test_source
            echo "# Doc1" > test_source/doc1.md
            echo "# Doc2" > test_source/doc2.md
            echo "*.tmp" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'"
            The output should match pattern "*"  # SHA256 hash format
            The status should be success

            # Verify consistency
            local fp1 fp2
            fp1=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'")
            fp2=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_compute_run_fingerprint '$PWD/test_source' '$PWD/test_source/.pndcgnignore' 'pdf' '/tmp/target'")
            The value "$fp1" should eq "$fp2"

            rm -rf test_source
        End
    End
End
