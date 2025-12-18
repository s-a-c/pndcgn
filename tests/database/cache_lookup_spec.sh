#!/usr/bin/env shellspec
#
# pndcgn Database Cache Lookup Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database cache lookup functions
# Coverage: Uses real SQLite database for accurate testing and coverage tracking
#           Tests use actual database operations instead of mocking

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Cache Lookup"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014h: Cache lookup function
    Context "cache lookup"
        BeforeEach 'setup_db_file'
        AfterEach 'cleanup_db_file'

        It "finds cached artifact with matching fingerprint"
            cache_lookup_hit() {
                local work_dir
                work_dir=$(pwd)
                mkdir -p test_output
                cached_file="$work_dir/test_output/cached.pdf"
                # Create the cached file first
                echo "cached content" > "$cached_file"

                # Initialize database with schema in this process
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Insert test data: a complete run with a cached artifact
                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0')
                pndcgn_db_update_run_status "$run_id" 'complete'

                local db_file
                db_file=$(pndcgn_get_db_path)
                sqlite3 "$db_file" <<EOF
UPDATE runs SET status = 'complete' WHERE run_id = '$run_id';
INSERT INTO generated_artifacts (run_id, source_path, output_path, input_fingerprint, output_fingerprint, output_type)
VALUES ('$run_id', '/tmp/source/file.md', '$cached_file', 'fingerprint123', 'output-fp-123', 'pdf');
EOF

                pndcgn_db_check_cache '/tmp/source/file.md' 'fingerprint123' 'pdf'
            }

            When call cache_lookup_hit
            The stdout should match pattern "*/test_output/cached.pdf"
            The status should be success

            rm -rf test_output
        End

        It "returns failure when cache miss"
            cache_lookup_miss() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true
                pndcgn_db_check_cache '/tmp/source/file.md' 'new-fingerprint' 'pdf'
            }

            When call cache_lookup_miss
            The status should be failure
        End

        It "validates cached file exists"
            cache_lookup_missing_file() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                local db_file
                db_file=$(pndcgn_get_db_path)

                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0')
                sqlite3 "$db_file" <<EOF
UPDATE runs SET status = 'complete' WHERE run_id = '$run_id';
INSERT INTO generated_artifacts (run_id, source_path, output_path, input_fingerprint, output_fingerprint, output_type)
VALUES ('$run_id', '/tmp/source/file.md', '/nonexistent/file.pdf', 'fingerprint', 'output-fp', 'pdf');
EOF

                pndcgn_db_check_cache '/tmp/source/file.md' 'fingerprint' 'pdf'
            }

            When call cache_lookup_missing_file
            The status should be failure  # File doesn't exist
        End

        It "matches by output type"
            cache_lookup_by_type() {
                local work_dir
                work_dir=$(pwd)
                mkdir -p test_output
                cached_file="$work_dir/test_output/file.pdf"
                echo "content" > "$cached_file"

                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                local db_file
                db_file=$(pndcgn_get_db_path)

                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0')
                sqlite3 "$db_file" <<EOF
UPDATE runs SET status = 'complete' WHERE run_id = '$run_id';
INSERT INTO generated_artifacts (run_id, source_path, output_path, input_fingerprint, output_fingerprint, output_type)
VALUES ('$run_id', '/tmp/file.md', '$cached_file', 'fp123', 'output-fp', 'pdf');
EOF

                pndcgn_db_check_cache '/tmp/file.md' 'fp123' 'pdf'
            }

            When call cache_lookup_by_type
            The stdout should match pattern "*/test_output/file.pdf"
            The status should be success

            rm -rf test_output
        End
    End
End
