#!/usr/bin/env bash
#
# pndcgn Constants
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: Shared constants for the pndcgn tool.
# Sourced by both the main application and test suite to ensure
# a single source of truth for values like ANSI color codes.

set -euo pipefail

# --- NO_COLOR Support ---
# Disable colors if NO_COLOR environment variable is set (https://no-color.org/)
# Always re-check NO_COLOR on each source to allow dynamic changes
if [[ -n "${NO_COLOR:-}" ]]; then
    # Set all color codes to empty strings
    CSI=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BOLD=""
    DIM=""
    ITALIC=""
    UNDERLINE=""
    RESET=""
    B_RED=""
    B_GREEN=""
    B_YELLOW=""
    B_BLUE=""
    B_SUCCESS=""
    B_WARNING=""
    B_ERROR=""
else
    # --- ANSI Color Codes ---
    # CSI (Control Sequence Introducer) is the common prefix for ANSI escape sequences.
    CSI=$'\033['

    # --- SGR (Select Graphic Rendition) Parameters ---
    # Text Colors
    RED="${CSI}31m"
    GREEN="${CSI}32m"
    YELLOW="${CSI}33m"
    BLUE="${CSI}34m"
    MAGENTA="${CSI}35m"
    CYAN="${CSI}36m"

    # Text Styles
    BOLD="${CSI}1m"
    DIM="${CSI}2m"
    ITALIC="${CSI}3m"
    UNDERLINE="${CSI}4m"

    # Reset all text attributes to the terminal's default.
    RESET="${CSI}0m"

    # --- Combined Codes for Convenience ---
    # Colorblind-friendly: Use blue/yellow instead of red/green for critical distinctions
    # (NFR-CLI-019: Color choices SHOULD be colorblind-friendly)
    B_RED="${BOLD}${RED}"
    B_GREEN="${BOLD}${GREEN}"
    B_YELLOW="${BOLD}${YELLOW}"
    B_BLUE="${BOLD}${BLUE}"

    # Colorblind-friendly alternatives: Use blue for success, yellow for warnings
    # Red is still used for errors but combined with symbols/text for distinction
    B_SUCCESS="${BOLD}${BLUE}"  # Blue for success (instead of green)
    B_WARNING="${BOLD}${YELLOW}"  # Yellow for warnings (already good)
    B_ERROR="${BOLD}${RED}"  # Red for errors (with text labels for distinction)
fi

# --- Product Constants ---
# Use assignment with check to allow re-sourcing
if [[ -z "${PNDCGN_NAME:-}" ]]; then
    PNDCGN_NAME="pndcgn"
fi
if [[ -z "${PNDCGN_VERSION:-}" ]]; then
    PNDCGN_VERSION="0.1.0"
fi
if [[ -z "${PNDCGN_DEFAULT_OUTPUT_TYPE:-}" ]]; then
    PNDCGN_DEFAULT_OUTPUT_TYPE="pdf"
fi

# --- Exit Codes ---
if [[ -z "${PNDCGN_EXIT_SUCCESS:-}" ]]; then
    PNDCGN_EXIT_SUCCESS=0
fi
if [[ -z "${PNDCGN_EXIT_ERROR:-}" ]]; then
    PNDCGN_EXIT_ERROR=1
fi
if [[ -z "${PNDCGN_EXIT_USAGE:-}" ]]; then
    PNDCGN_EXIT_USAGE=2
fi
