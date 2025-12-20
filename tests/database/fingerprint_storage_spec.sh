#!/usr/bin/env shellspec
#
# pndcgn Database Fingerprint Storage Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database fingerprint storage functions

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Fingerprint Storage"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'
    BeforeEach 'setup_db_file'
    AfterEach 'cleanup_db_file'

    # T029c: Run fingerprint storage during dry-run
    Context "fingerprint storage"
        It "stores fingerprint for a run"
            store_fingerprint() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Create a run first
                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' 0)

                # Store fingerprint
                pndcgn_db_store_fingerprint "$run_id" 'test-fingerprint-123'

                # Verify it was stored
                db_file=$(pndcgn_get_db_path)
                sqlite3 "$db_file" "SELECT fingerprint FROM runs WHERE run_id = '$run_id';"
            }

            When call store_fingerprint
            The stdout should eq "test-fingerprint-123"
            The status should be success
        End

        It "retrieves stored fingerprint"
            retrieve_fingerprint() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Create a run and store fingerprint
                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' 0)
                pndcgn_db_store_fingerprint "$run_id" 'stored-fingerprint-abc'

                # Retrieve it
                pndcgn_db_get_fingerprint "$run_id"
            }

            When call retrieve_fingerprint
            The stdout should eq "stored-fingerprint-abc"
            The status should be success
        End

        It "returns failure when fingerprint not found"
            get_nonexistent_fingerprint() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Try to get fingerprint for non-existent run
                pndcgn_db_get_fingerprint 'nonexistent-run'
            }

            When call get_nonexistent_fingerprint
            The status should be failure
        End

        It "verifies run exists"
            verify_run_exists() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Create a run
                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' 0)

                # Verify it exists
                pndcgn_db_run_exists "$run_id"
            }

            When call verify_run_exists
            The status should be success
        End

        It "returns failure when run does not exist"
            verify_nonexistent_run() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                # Try to verify non-existent run
                pndcgn_db_run_exists 'nonexistent-run'
            }

            When call verify_nonexistent_run
            The status should be failure
        End
    End
End
