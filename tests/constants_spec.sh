#!/usr/bin/env shellspec

# Description: This test file serves as a "contract" to ensure that the
# shared constants are correctly defined and loaded into the test environment.

# Include the test helper, which sources the constants.
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

Describe "Shared Constants Contract (src/constants.sh)"

    Context "when the constants file is sourced"
        # Unset NO_COLOR to test actual constant values
        BeforeAll 'unset NO_COLOR'

        It "defines the B_RED constant correctly"
            # The value should be the combination of BOLD and RED.
            # We use `eq` for an exact string match.
            # Re-source constants without NO_COLOR
            unset NO_COLOR
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            The value "$B_RED" should eq "${BOLD}${RED}"
        End

        It "defines the RESET constant correctly"
            # Re-source constants without NO_COLOR
            unset NO_COLOR
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            The value "$RESET" should eq "${CSI}0m"
        End

        It "ensures constants are not empty"
            # Re-source constants without NO_COLOR
            unset NO_COLOR
            . "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/constants.sh"
            The value "$CSI" should not eq ""
            The value "$RED" should not eq ""
            The value "$BOLD" should not eq ""
            The value "$RESET" should not eq ""
            The value "$B_RED" should not eq ""
        End
    End
End
