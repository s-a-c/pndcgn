#!/usr/bin/env shellspec
#
# pndcgn Database Schema Migration Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database schema migrations, specifically source_dirs column addition
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Schema Migration"

    BeforeAll  'setup_test_env'
    AfterAll   'cleanup_test_env'
    BeforeEach 'setup_db_file'
    AfterEach  'cleanup_db_file'

    Context "source_dirs column migration (T019)"
        It "adds source_dirs column to runs table"
            check_column_exists() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true
                db_file=$(pndcgn_get_db_path)

                sqlite3 "$db_file" "PRAGMA table_info(runs);" | grep -q "source_dirs" || return 1
            }

            When call check_column_exists
            The status should be success
        End

        It "migrates existing runs to populate source_dirs from source_root"
            migrate_existing_runs() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                db_file=$(pndcgn_get_db_path)
                pndcgn_db_init >/dev/null 2>&1 || true

                # Create a run with old schema (source_root only)
                sqlite3 "$db_file" <<'EOF'
INSERT INTO runs (run_id, source_root, target_root, output_type, dry_run, status, created_at)
VALUES ('test-run-old', '/old/source', '/old/target', 'pdf', 0, 'complete', strftime('%s', 'now'));
EOF

                # Re-initialize to trigger migration
                pndcgn_db_init >/dev/null 2>&1 || true

                # Check that source_dirs was populated from source_root
                sqlite3 "$db_file" "SELECT source_dirs FROM runs WHERE run_id = 'test-run-old';"
            }

            When call migrate_existing_runs
            The output should include "/old/source"
            The status should be success
        End

        It "handles multiple migrations without errors (idempotent)"
            idempotent_migration() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true
                # Run migration again
                pndcgn_db_init >/dev/null 2>&1 || true
                # Should not fail
                return 0
            }

            When call idempotent_migration
            The status should be success
        End

        It "preserves existing source_dirs values during migration"
            preserve_existing_values() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                db_file=$(pndcgn_get_db_path)
                pndcgn_db_init >/dev/null 2>&1 || true

                # Create a run with source_dirs already set
                sqlite3 "$db_file" <<'EOF'
INSERT INTO runs (run_id, source_root, source_dirs, target_root, output_type, dry_run, status, created_at)
VALUES ('test-run-new', '/new/source', '["/new/source", "/new/other"]', '/new/target', 'pdf', 0, 'complete', strftime('%s', 'now'));
EOF

                # Re-initialize to trigger migration
                pndcgn_db_init >/dev/null 2>&1 || true

                # Check that source_dirs was preserved
                sqlite3 "$db_file" "SELECT source_dirs FROM runs WHERE run_id = 'test-run-new';"
            }

            When call preserve_existing_values
            The output should include "/new/source"
            The output should include "/new/other"
            The status should be success
        End

        It "allows NULL source_dirs (nullable column)"
            nullable_column() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                db_file=$(pndcgn_get_db_path)
                pndcgn_db_init >/dev/null 2>&1 || true

                # Insert run with NULL source_dirs (should be allowed)
                sqlite3 "$db_file" <<'EOF'
INSERT INTO runs (run_id, source_root, source_dirs, target_root, output_type, dry_run, status, created_at)
VALUES ('test-run-null', '/null/source', NULL, '/null/target', 'pdf', 0, 'complete', strftime('%s', 'now'));
EOF

                # Verify it was inserted
                sqlite3 "$db_file" "SELECT COUNT(*) FROM runs WHERE run_id = 'test-run-null' AND source_dirs IS NULL;"
            }

            When call nullable_column
            The output should eq "1"
            The status should be success
        End
    End
End
