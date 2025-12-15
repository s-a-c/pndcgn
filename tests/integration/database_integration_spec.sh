#!/usr/bin/env shellspec
#
# pndcgn Database Integration Tests (No Mocks)
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Integration tests for database operations using real SQLite
# These tests exercise actual database code paths for accurate coverage tracking

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Integration Tests (No Mocks)"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "real database operations"
        It "creates and initializes database"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_init 2>/dev/null"
            The output should match pattern "*pndcgn.db"
            The status should be success

            # Verify database file exists
            local db_path
            db_path=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_get_db_path")
            The file "$db_path" should be exist

            rm -rf test_state
            unset XDG_STATE_HOME
        End

        It "creates run with real database"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            # Initialize database first (suppress ULID extension warning)
            bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_init" >/dev/null 2>&1 || true

            # Create run and verify in single test
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && run_id=\$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_run_exists \"\$run_id\" && echo \"\$run_id\""
            The output should not eq ""
            The status should be success

            rm -rf test_state
            unset XDG_STATE_HOME
        End

        It "stores and retrieves fingerprint"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            # Initialize database (suppress ULID extension warning)
            bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_init" >/dev/null 2>&1 || true

            # Create a run and store/retrieve fingerprint in single test
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && run_id=\$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_store_fingerprint \"\$run_id\" 'test-fingerprint-123' && pndcgn_db_get_fingerprint \"\$run_id\""
            The output should eq "test-fingerprint-123"
            The status should be success

            rm -rf test_state
            unset XDG_STATE_HOME
        End
    End
End
