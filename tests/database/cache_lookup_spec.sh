#!/usr/bin/env shellspec
#
# pndcgn Database Cache Lookup Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for database cache lookup functions
# Coverage: Uses 'When run' because tests require subprocess isolation for sqlite3 mocking
#           Coverage tracking is limited (0%) for these tests due to subprocess execution
#           See tests/README.md for coverage tracking patterns

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Database Cache Lookup"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    # T014h: Cache lookup function
    Context "cache lookup"
        It "finds cached artifact with matching fingerprint"
            mkdir -p test_state test_output
            local cached_file="$PWD/test_output/cached.pdf"
            # Create the cached file first
            echo "cached content" > "$cached_file"
            export XDG_STATE_HOME="$PWD/test_state"
            # Create dummy db file so existence check passes
            mkdir -p test_state
            touch test_state/pndcgn.db

            sqlite3() {
                local db_file="${1:-}"
                # Read query from stdin (heredoc)
                local query
                query=$(cat)
                case "$db_file" in
                    *pndcgn.db)
                        if [[ "$query" == *"SELECT output_path"* ]]; then
                            # Return the cached file path
                            echo "$cached_file"
                            return 0
                        fi
                        ;;
                esac
                return 1
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_check_cache '/tmp/source/file.md' 'fingerprint123' 'pdf'"
            The output should eq "$cached_file"
            The status should be success

            unset -f sqlite3
            rm -rf test_state test_output
        End

        It "returns failure when cache miss"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*output_path*)
                                return 1  # No match
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_check_cache '/tmp/source/file.md' 'new-fingerprint' 'pdf'"
            The status should be failure

            unset -f sqlite3
            rm -rf test_state
        End

        It "validates cached file exists"
            mkdir -p test_state
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*output_path*)
                                echo "/nonexistent/file.pdf"
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_check_cache '/tmp/source/file.md' 'fingerprint' 'pdf'"
            The status should be failure  # File doesn't exist

            unset -f sqlite3
            rm -rf test_state
        End

        It "matches by output type"
            mkdir -p test_state test_output
            echo "content" > test_output/file.pdf
            export XDG_STATE_HOME="$PWD/test_state"

            sqlite3() {
                local db_file="${1:-}"
                local query="${2:-}"
                case "$db_file" in
                    *pndcgn.db)
                        case "$query" in
                            *SELECT*output_path*)
                                # Should only match if output_type matches
                                [[ "$query" == *"output_type = 'pdf'"* ]] && echo "$PWD/test_output/file.pdf"
                                ;;
                            "")
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f sqlite3

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/database.sh' && pndcgn_db_check_cache '/tmp/file.md' 'fp123' 'pdf'"
            The status should be success

            unset -f sqlite3
            rm -rf test_state test_output
        End
    End
End
