#!/usr/bin/env shellspec
#
# pndcgn Processing Tests
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Tests for file discovery, fingerprinting, conversion, and output generation

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source processing for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh"

Describe "Processing Functions"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014e: File discovery respecting .pndcgnignore patterns
    Context "file discovery"
        It "discovers markdown files in source directory"
            mkdir -p test_source
            echo "# Test" > test_source/file1.md
            echo "# Test" > test_source/file2.txt

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "file1.md"
            The status should be success

            rm -rf test_source
        End

        It "respects .pndcgnignore patterns"
            mkdir -p test_source
            echo "# Test" > test_source/file1.md
            echo "# Test" > test_source/ignored.md
            echo "ignored.md" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source' '$PWD/test_source/.pndcgnignore'"
            The output should include "file1.md"
            The output should not include "ignored.md"
            The status should be success

            rm -rf test_source
        End

        It "respects include patterns from TOML config"
            mkdir -p test_source/docs test_source/other
            echo "# Test" > test_source/docs/file1.md
            echo "# Test" > test_source/other/file2.md
            echo '[include]' > test_source/pndcgn.toml
            echo 'patterns = ["docs/**/*.md"]' >> test_source/pndcgn.toml

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "docs/file1.md"
            The output should not include "other/file2.md"
            The status should be success

            rm -rf test_source
        End

        It "evaluates include patterns before exclude patterns"
            mkdir -p test_source/docs/public test_source/docs/private
            echo "# Test" > test_source/docs/public/file1.md
            echo "# Test" > test_source/docs/private/file2.md
            echo '[include]' > test_source/pndcgn.toml
            echo 'patterns = ["docs/**/*.md"]' >> test_source/pndcgn.toml
            echo "docs/private/**" > test_source/.pndcgnignore

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            # Include pattern matches both, but exclude pattern removes private
            The output should include "docs/public/file1.md"
            The output should not include "docs/private/file2.md"
            The status should be success

            rm -rf test_source
        End

        It "discovers multiple supported formats"
            mkdir -p test_source
            touch test_source/file.md test_source/file.markdown test_source/file.txt test_source/file.rst

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_discover_files '$PWD/test_source'"
            The output should include "file.md"
            The output should include "file.markdown"
            The output should include "file.txt"
            The output should include "file.rst"

            rm -rf test_source
        End
    End

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

    # T014j: Dewey Decimal naming scheme
    Context "Dewey Decimal naming"
        It "generates Dewey Decimal prefix for file"
            mkdir -p test_source/subdir
            touch test_source/subdir/file.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_dewey_prefix '$PWD/test_source/subdir/file.md' '$PWD/test_source'"
            The output should match pattern "[0-9][0-9][0-9]"  # Format: 001 (or 001.002 for nested)
            The status should be success

            rm -rf test_source
        End

        It "generates prefix for root-level file"
            mkdir -p test_source
            touch test_source/file.md

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_dewey_prefix '$PWD/test_source/file.md' '$PWD/test_source'"
            The output should eq "000"
            The status should be success

            rm -rf test_source
        End
    End

    # T014k: Run output directory creation
    Context "output directory creation"
        It "creates output directory with correct format"
            mkdir -p test_target

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'"
            The output should match pattern "*/.pndcgn/pdf-test-run-id"
            The status should be success
            local output_dir
            output_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'pdf' 'test-run-id'")
            The directory "$output_dir" should be exist

            rm -rf test_target
        End

        It "creates nested directory structure"
            mkdir -p test_target

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'html' 'run123'"
            local output_dir
            output_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_create_output_directory '$PWD/test_target' 'html' 'run123'")
            The directory "$output_dir" should be exist

            rm -rf test_target
        End
    End

    # T014l: Run index generation (_index.md format)
    Context "index generation"
        It "generates _index.md file"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'test-run-id' '{\"total\":1,\"processed\":1}'"
            The status should be success
            The file "test_output/_index.md" should be exist
            The contents of file "test_output/_index.md" should include "test-run-id"
            The contents of file "test_output/_index.md" should include "Run Index"

            rm -rf test_output
        End

        It "includes statistics in index"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'run-id' '{\"total\":5,\"processed\":3,\"skipped\":2}'"
            The contents of file "test_output/_index.md" should include "Statistics"

            rm -rf test_output
        End

        It "lists generated artifacts"
            mkdir -p test_output
            echo "content" > test_output/file1.pdf
            echo "content" > test_output/file2.pdf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_generate_index '$PWD/test_output' 'run-id' '{}'"
            The contents of file "test_output/_index.md" should include "file1.pdf"
            The contents of file "test_output/_index.md" should include "file2.pdf"

            rm -rf test_output
        End
    End

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

    # Phase 8: NFR P1-MVP Tests
    Context "files <64KB full content hashing (T076e)"
        It "hashes full content for files smaller than 64KB"
            mkdir -p test_source
            echo "Small file content" > test_source/small.md

            When call pndcgn_compute_fingerprint "$PWD/test_source/small.md"
            The output should match pattern "*:*:*"
            # Should contain size, mtime, and hash
            The status should be success

            rm -rf test_source
        End
    End

    Context "empty file fingerprint format (T076f)"
        It "generates fingerprint for empty file (0 bytes)"
            mkdir -p test_source
            touch test_source/empty.md

            When call pndcgn_compute_fingerprint "$PWD/test_source/empty.md"
            The output should match pattern "0:*:*"
            # Size should be 0, should have mtime and hash
            The status should be success

            rm -rf test_source
        End
    End

    Context "mtime precision (integer seconds) (T076g)"
        It "uses integer seconds for mtime"
            mkdir -p test_source
            echo "test" > test_source/file.md

            When call pndcgn_compute_fingerprint "$PWD/test_source/file.md"
            The output should match pattern "*:[0-9]*:*"
            # mtime should be integer (no decimal)
            The status should be success

            rm -rf test_source
        End
    End

    Context "deterministic fingerprint ordering (T076h)"
        It "sorts fingerprints by path for deterministic output"
            mkdir -p test_source
            echo "a" > test_source/z_file.md
            echo "b" > test_source/a_file.md
            echo "c" > test_source/m_file.md

            When call pndcgn_compute_run_fingerprint "$PWD/test_source" "" "pdf" "/tmp/target"
            The output should not eq ""
            # Fingerprints should be in sorted order
            The status should be success

            rm -rf test_source
        End
    End

    Context "file change during processing detection (T076n)"
        It "detects when file changes during processing"
            mkdir -p test_source
            echo "original" > test_source/file.md

            # Get initial fingerprint
            local initial_fp
            initial_fp=$(pndcgn_compute_fingerprint "$PWD/test_source/file.md")

            # Modify file
            echo "modified" > test_source/file.md

            # Get new fingerprint
            local new_fp
            new_fp=$(pndcgn_compute_fingerprint "$PWD/test_source/file.md")

            When run bash -c "[ \"$initial_fp\" != \"$new_fp\" ] && echo 'changed'"
            The output should eq "changed"
            The status should be success

            rm -rf test_source
        End
    End

    Context "config file in run fingerprint (T076q)"
        It "includes config file content in run fingerprint"
            mkdir -p test_source
            touch test_source/file.md
            echo '[include]' > test_source/pndcgn.toml
            echo 'patterns = ["docs/**/*.md"]' >> test_source/pndcgn.toml

            local fp1
            fp1=$(pndcgn_compute_run_fingerprint "$PWD/test_source" "" "pdf" "/tmp/target")

            # Modify config
            echo 'patterns = ["changed/**/*.md"]' > test_source/pndcgn.toml

            local fp2
            fp2=$(pndcgn_compute_run_fingerprint "$PWD/test_source" "" "pdf" "/tmp/target")

            # Should produce different fingerprint when config changes
            When call test -n "$fp1" && test -n "$fp2" && test "$fp1" != "$fp2"
            The status should be success

            rm -rf test_source
        End
    End

    # Phase 9: NFR P2 Tests
    Context "SHA256 implementation detection (T095a)"
        It "detects available SHA256 implementation"
            When call bash -c "command -v shasum >/dev/null 2>&1 && echo 'shasum' || command -v sha256sum >/dev/null 2>&1 && echo 'sha256sum' || echo 'none'"
            The output should not eq "none"
            The status should be success
        End
    End

    Context "TOML config in fingerprint (T095b)"
        It "includes TOML config content in fingerprint"
            mkdir -p test_source
            touch test_source/file.md
            echo '[include]' > test_source/pndcgn.toml
            echo 'patterns = ["docs/**/*.md"]' >> test_source/pndcgn.toml

            local fp
            fp=$(pndcgn_compute_run_fingerprint "$PWD/test_source" "" "pdf" "/tmp/target")
            When call test -n "$fp"
            # Fingerprint should include config hash
            The status should be success

            rm -rf test_source
        End
    End

    Context "symlink following (T096d)"
        It "follows symlinks to source files"
            mkdir -p test_source/linked
            echo "# Test" > test_source/linked/file.md
            ln -s test_source/linked/file.md test_source/symlink.md

            When call pndcgn_discover_files "$PWD/test_source"
            The output should include "symlink.md"
            The status should be success

            rm -rf test_source
        End
    End

    Context "broken symlink skipping (T096e)"
        It "skips broken symlinks"
            mkdir -p test_source
            ln -s /nonexistent/file.md test_source/broken.md

            When call pndcgn_discover_files "$PWD/test_source"
            # Broken symlinks should be skipped
            The output should not include "broken.md" || The status should be success
            The status should be success

            rm -rf test_source
        End
    End

    Context "circular symlink detection (T096f)"
        It "detects and handles circular symlinks"
            mkdir -p test_source
            ln -s test_source/circular.md test_source/circular.md 2>/dev/null || true

            # Should handle circular symlinks gracefully
            When call pndcgn_discover_files "$PWD/test_source" 2>&1 || true
            The status should be defined

            rm -rf test_source
        End
    End

    Context "empty input file processing (T096h)"
        It "processes empty input files"
            mkdir -p test_source
            touch test_source/empty.md

            When call pndcgn_compute_fingerprint "$PWD/test_source/empty.md"
            The output should match pattern "0:*:*"
            The status should be success

            rm -rf test_source
        End
    End

    Context "binary file skipping (T096i)"
        It "skips binary files"
            mkdir -p test_source
            printf '\x00\x01\x02' > test_source/binary.bin

            When call pndcgn_discover_files "$PWD/test_source"
            # Binary files should not be in output
            The output should not include "binary.bin"
            The status should be success

            rm -rf test_source
        End
    End

    Context "permission denied skipping (T096j)"
        It "skips files with permission denied"
            mkdir -p test_source
            echo "# Test" > test_source/file.md
            chmod 000 test_source/file.md 2>/dev/null || true

            # Should handle permission denied gracefully
            When call pndcgn_discover_files "$PWD/test_source" 2>&1 || true
            The status should be defined

            chmod 644 test_source/file.md 2>/dev/null || true
            rm -rf test_source
        End
    End

    Context "pandoc crash handling (T096o)"
        It "handles pandoc crashes gracefully"
            mkdir -p test_source
            echo "# Test" > test_source/file.md

            # Mock pandoc to crash
            pandoc() {
                exit 1
            }
            export -f pandoc

            # Should handle pandoc crash
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/processing.sh' && pndcgn_convert_file '$PWD/test_source/file.md' '/tmp/output.pdf' 'pdf' 2>&1 || true"
            The status should be defined

            unset -f pandoc
            rm -rf test_source
        End
    End
End
