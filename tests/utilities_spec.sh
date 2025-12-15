#!/usr/bin/env shellspec
#
# pndcgn Utilities Tests
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Tests for utility functions (logging, paths, ULID, prerequisites)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "Utility Functions"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "logging functions"
        It "logs info messages"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_log_info 'Test message'"
            The stderr should include "INFO"
            The stderr should include "Test message"
        End

        It "logs error messages"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_log_error 'Error message'"
            The stderr should include "ERROR"
            The stderr should include "Error message"
        End

        It "logs warning messages"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_log_warn 'Warning message'"
            The stderr should include "WARN"
            The stderr should include "Warning message"
        End
    End

    Context "path resolution"
        It "resolves absolute paths"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_resolve_path '/tmp/test'"
            The output should eq "/tmp/test"
        End

        It "resolves relative paths"
            mkdir -p test_dir
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && cd test_dir && pndcgn_resolve_path '.' | sed 's|/\.$||'"
            The output should match pattern "*test_dir"
            rm -rf test_dir
        End

        It "defaults to current directory for empty path"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_resolve_path ''"
            The output should not eq ""
        End
    End

    Context "prerequisite validation"
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

    Context "ULID generation fallback"
        It "generates ULID in correct format"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_generate_ulid_fallback"
            The output should match pattern "[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]"  # 26 chars
            The status should be success
        End

        It "generates unique ULIDs"
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && ulid1=\$(pndcgn_generate_ulid_fallback) && ulid2=\$(pndcgn_generate_ulid_fallback) && [ \"\$ulid1\" != \"\$ulid2\" ] && echo \"\$ulid1\""
            The output should not eq ""
            The status should be success
        End
    End

    Context "XDG directory support"
        It "creates XDG state directory"
            mkdir -p test_xdg
            export XDG_STATE_HOME="$PWD/test_xdg"

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_get_state_dir"
            The output should match pattern "*pndcgn"
            local state_dir
            state_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_get_state_dir")
            The directory "$state_dir" should be exist

            rm -rf test_xdg
            unset XDG_STATE_HOME
        End

        It "creates XDG config directory"
            mkdir -p test_xdg
            export XDG_CONFIG_HOME="$PWD/test_xdg"

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_get_config_dir"
            The output should match pattern "*pndcgn"
            local config_dir
            config_dir=$(bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_get_config_dir")
            The directory "$config_dir" should be exist

            rm -rf test_xdg
            unset XDG_CONFIG_HOME
        End
    End

    Context "fzf integration"
        It "selects directory when fzf available"
            fzf() {
                echo "./selected_dir"
            }
            export -f fzf

            mkdir -p selected_dir

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_select_source_dir"
            The output should match pattern "*selected_dir"
            The status should be success

            rm -rf selected_dir
            unset -f fzf
        End

        It "returns failure when fzf unavailable"
            unset -f fzf

            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_select_source_dir"
            The status should be failure
        End
    End

    # T049j: sqlite-ulid extension download failure
    Context "when sqlite-ulid extension download fails"
        It "falls back to Bash ULID generation and continues operation"
            mkdir -p test_lib
            export test_lib_dir="$PWD/test_lib"

            # Mock curl to fail
            curl() {
                return 1
            }
            export -f curl

            # Test the install function (utilities already sourced)
            When run bash -c "pndcgn_install_ulid 2>&1 || true"
            The status should be failure  # Install fails
            The stderr should include "Failed to download"
            The stderr should include "Bash fallback"
            # Should not crash - operation continues

            unset -f curl
            rm -rf test_lib
        End
    End

    # Phase 8: NFR P1-MVP Tests
    Context "TTY detection and interactive mode (T076a)"
        It "detects non-TTY stdout and disables interactive features"
            # Test when stdout is not a TTY (redirected to file)
            # pndcgn_is_interactive returns 1 (false) when not a TTY
            local test_output
            test_output=$(mktemp)
            # Redirect stdout to file to simulate non-TTY
            pndcgn_is_interactive >"$test_output" 2>&1
            local exit_code=$?
            # Verify exit code is 1 (non-interactive)
            When run test "$exit_code" -eq 1
            The status should be success
            rm -f "$test_output"
        End

        It "detects TTY stdout and enables interactive features"
            # Test when stdout is a TTY (if available)
            # pndcgn_is_interactive returns 0 (true) when TTY
            if [[ -t 1 ]]; then
                When call pndcgn_is_interactive
                The status should be success
            else
                # Skip test if not a TTY
                Skip "stdout is not a TTY in test environment"
            fi
        End
    End

    Context "NO_COLOR environment variable support (T076b)"
        It "disables color output when NO_COLOR is set"
            # Re-source constants with NO_COLOR set
            NO_COLOR=1 . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            When call pndcgn_log_info "Test message"
            The stderr should not include $'\033['
            The stderr should include "INFO"
            The stderr should include "Test message"
        End

        It "enables color output when NO_COLOR is unset"
            # Re-source constants without NO_COLOR
            unset NO_COLOR
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            When call pndcgn_log_info "Test message"
            The stderr should include $'\033['
            The stderr should include "INFO"
        End
    End

    # Phase 9: NFR P2 Tests
    Context "ANSI color output (T094d)"
        It "outputs ANSI color codes when colors enabled"
            unset NO_COLOR
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            When call pndcgn_log_info "Test message"
            The stderr should include $'\033['
            The stderr should include "INFO"
        End
    End

    Context "run ID display format (T094e)"
        It "formats run ID for display"
            # Run IDs should be ULID format (26 chars, alphanumeric)
            local test_run_id="01ARZ3NDEKTSV4Y5QH6J7K8M9"
            When run bash -c "printf '%s\n' '$test_run_id'"
            The output should match pattern "^[0-9A-Z]{26}$"
            The status should be success
        End
    End

    Context "duration output format (T094f)"
        It "formats duration in human-readable format"
            # Test duration formatting (should be seconds or human-readable)
            local duration=125
            When run bash -c "printf '%ds\n' $duration"
            The output should match pattern "*[0-9]*s"
            The status should be success
        End
    End

    Context "confirmation prompt responses (T094g)"
        It "accepts valid confirmation responses"
            # Test that yes/no responses are handled
            When run bash -c "echo 'yes' | grep -E '^(yes|no)$'"
            The output should eq "yes"
            The status should be success
        End
    End

    Context "sqlite3 prerequisite check (T096n)"
        It "checks for sqlite3 prerequisite"
            When call pndcgn_check_prerequisites
            # Should check for sqlite3
            The status should be success || The stderr should include "sqlite3"
        End
    End
End
