#!/usr/bin/env shellspec
#
# pndcgn Prerequisites Validation Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for prerequisite validation functions
# Coverage: Uses 'When run' for tests requiring subprocess isolation (mock functions)
#           Coverage tracking is limited for these tests due to subprocess execution

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Note: Cannot use 'When call' here because we need subprocess isolation for mocking
# The mock functions (command) must be exported and run in a subprocess

Describe "Prerequisite Validation"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "prerequisite validation"
        # Note: These tests use 'When run' because they require mocking 'command'
        # which needs subprocess isolation. Coverage will show 0% for these paths.

        It "validates all prerequisites are available"
            command() {
                case "$1" in
                    -v)
                        case "$2" in
                            pandoc|sqlite3|curl)
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f command

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_check_prerequisites"
            The status should be success

            unset -f command
        End

        It "reports missing prerequisites"
            command() {
                case "$1" in
                    -v)
                        case "$2" in
                            pandoc)
                                return 1  # Missing
                                ;;
                            sqlite3|curl)
                                return 0
                                ;;
                        esac
                        ;;
                esac
            }
            export -f command

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_check_prerequisites"
            The status should be failure
            The stderr should include "pandoc"

            unset -f command
        End
    End
End
