#!/usr/bin/env shellspec
#
# pndcgn Database Run Creation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database run creation functions
# Coverage: Uses 'When run' because tests require subprocess isolation for sqlite3 mocking
#           Coverage tracking is limited (0%) for these tests due to subprocess execution
#           See tests/README.md for coverage tracking patterns

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Run Creation"

    BeforeAll  'setup_test_env'
    AfterAll   'cleanup_test_env'
    BeforeEach 'setup_db_file'
    AfterEach  'cleanup_db_file'

    # T014g: Run creation and metadata
    Context "run creation"
        It "creates run and returns a non-empty ID (ULID or fallback)"
            create_run_with_id() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true
                pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0'
            }

            When call create_run_with_id
            The stdout should not eq ""
            The status should be success
        End

        It "uses Bash fallback when ULID extension unavailable"
            create_run_with_fallback_ulid() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                sqlite3() {
                    local db_file="${1:-}"
                    local query="${2:-}"
                    case "$db_file" in
                        *pndcgn.db)
                            case "$query" in
                                *CREATE*|*PRAGMA*)
                                    return 0
                                    ;;
                                *SELECT*ulid*)
                                    return 1  # Extension not available
                                    ;;
                                *INSERT*)
                                    echo "fallback-ulid"
                                    ;;
                                "")
                                    return 0
                                    ;;
                            esac
                            ;;
                    esac
                }
                export -f sqlite3

                pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0'
            }

            When call create_run_with_fallback_ulid
            The stdout should not eq ""
            The status should be success
        End

        It "stores run metadata correctly"
            store_run_metadata() {
                source "${PNDCGN_PROJECT_ROOT}/src/database.sh"
                pndcgn_db_init >/dev/null 2>&1 || true

                run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'html' '1')
                db_file=$(pndcgn_get_db_path)

                sqlite3 "$db_file" <<EOF
SELECT source_root || '|' || target_root || '|' || output_type || '|' || dry_run
FROM   runs
WHERE  run_id = '$run_id';
EOF
            }

            When call store_run_metadata
            The stdout should eq "/tmp/source|/tmp/target|html|1"
            The status should be success
        End
    End
End
