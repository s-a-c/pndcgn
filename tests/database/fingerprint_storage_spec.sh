#!/usr/bin/env shellspec
#
# pndcgn Database Fingerprint Storage Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database fingerprint storage functions
# Coverage: Uses 'When run' because tests require subprocess isolation for sqlite3 mocking
#           Coverage tracking is limited (0%) for these tests due to subprocess execution
#           See tests/README.md for coverage tracking patterns

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Fingerprint Storage"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T029c: Run fingerprint storage during dry-run
    Context "fingerprint storage"
        It "stores fingerprint for a run"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            local update_called=false
            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *UPDATE*fingerprint*)
                                [[ "$query" == *"test-fingerprint-123"* ]] && update_called=true
                                return 0
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_store_fingerprint 'test-run-id' 'test-fingerprint-123'"
            The status should be success

            unset -f sqlite3
            rm -rf test_state
        End

        It "retrieves stored fingerprint"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*fingerprint*)
                                echo "stored-fingerprint-abc"
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_get_fingerprint 'test-run-id'"
            The output should eq "stored-fingerprint-abc"
            The status should be success

            unset -f sqlite3
            rm -rf test_state
        End

        It "returns failure when fingerprint not found"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*fingerprint*)
                                return 1  # No result
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_get_fingerprint 'nonexistent-run'"
            The status should be failure

            unset -f sqlite3
            rm -rf test_state
        End

        It "verifies run exists"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*COUNT*)
                                echo "1"  # Run exists
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_run_exists 'test-run-id'"
            The status should be success

            unset -f sqlite3
            rm -rf test_state
        End

        It "returns failure when run does not exist"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*COUNT*)
                                echo "0"  # Run doesn't exist
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_run_exists 'nonexistent-run'"
            The status should be failure

            unset -f sqlite3
            rm -rf test_state
        End
    End
End
