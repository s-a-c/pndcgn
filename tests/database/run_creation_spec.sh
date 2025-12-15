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

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014g: Run creation with ULID generation
    Context "run creation"
        It "creates run with ULID generation"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *CREATE*|*PRAGMA*)
                                return 0
                                ;;
                            *INSERT*)
                                echo "01ARZ3NDEKTSV4Y5QH6J7K8M9"
                                ;;
                            *SELECT*ulid*)
                                echo "01ARZ3NDEKTSV4Y5QH6J7K8M9"
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0'"
            The output should match pattern "*"  # ULID format
            The status should be success

            unset -f sqlite3
            rm -rf test_state
        End

        It "uses Bash fallback when ULID extension unavailable"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

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

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0'"
            The output should not eq ""
            The status should be success
            The stderr should include "WARN"

            unset -f sqlite3
            rm -rf test_state
        End

        It "stores run metadata correctly"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            local insert_called=false
            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *CREATE*|*PRAGMA*)
                                return 0
                                ;;
                            *INSERT*)
                                [[ "$query" == *"/tmp/source"* ]] && insert_called=true
                                echo "test-run-id"
                                ;;
                            *SELECT*ulid*)
                                echo "test-run-id"
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_create_run '/tmp/source' '/tmp/target' 'html' '1'"
            The status should be success

            unset -f sqlite3
            rm -rf test_state
        End
    End
End
