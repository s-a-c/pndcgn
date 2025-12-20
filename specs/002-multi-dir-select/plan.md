#  Implementation Plan: Multi-Directory Selection via fzf

**Branch**: `002-multi-dir-select` | **Date**: 2025-12-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-multi-dir-select/spec.md`

---

<details><summary>Table of Contents</summary>

- [Implementation Plan: Multi-Directory Selection via fzf](#implementation-plan-multi-directory-selection-via-fzf)
  - [1. Summary](#1-summary)
  - [2. Technical Context](#2-technical-context)
  - [3. Constitution Check](#3-constitution-check)
  - [4. Project Structure](#4-project-structure)
    - [4.1. Documentation (this feature)](#41-documentation-this-feature)
    - [4.2. Source Code (repository root)](#42-source-code-repository-root)
  - [5. Complexity Tracking](#5-complexity-tracking)
  - [6. Phase 0: Research](#6-phase-0-research)
    - [6.1. Research Tasks](#61-research-tasks)
    - [6.2. Findings](#62-findings)
  - [7. Phase 1: Design](#7-phase-1-design)
    - [7.1. Data Model](#71-data-model)
    - [7.2. Contracts](#72-contracts)
    - [7.3. Quickstart](#73-quickstart)
  - [8. Phase 2: Tasks](#8-phase-2-tasks)

</details>

---

## 1. Summary

Enable pndcgn to process multiple source directories in a single run via fzf multi-select or CLI positional arguments. Output files from multi-directory runs use abbreviated source prefixes to distinguish origin. Selection limit is configurable (default 4, max 16) via `pndcgn.toml`. When fzf is unavailable, falls back to numbered list prompt. Overlapping directories (subdirectories) are automatically excluded.

---

## 2. Technical Context

**Language/Version**: Bash 5.x (strict mode: `set -euo pipefail`)
**Primary Dependencies**: fzf (multi-select mode, optional), sqlite3, pandoc
**Storage**: SQLite (existing `cache.sqlite` - extend `runs` table for multi-source)
**Testing**: ShellSpec (BDD), kcov for coverage
**Target Platform**: macOS, Linux (POSIX-compliant shells)
**Project Type**: Single CLI tool
**Performance Goals**: Linear scaling O(N) for N directories, <10% overhead vs N sequential runs
**Constraints**: Backward compatible with single-directory workflows, no new dependencies
**Scale/Scope**: 1-16 directories per run, existing file processing limits apply

---

## 3. Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status | Notes |
|------|-------------|--------|-------|
| Shell-First | All core functionality in Bash | ✅ PASS | Feature extends existing Bash modules |
| Test-First | BDD tests before implementation | ✅ PASS | ShellSpec tests will be written first |
| Documentation-Driven | Spec before code | ✅ PASS | spec.md complete with clarifications |
| SQLite State | Persistent state in SQLite | ✅ PASS | Extend `runs` table for multi-source |
| Intelligent Caching | Cache-first, fingerprint-based | ✅ PASS | Per-directory fingerprints combined |
| Resumable Operations | Crash-resilient | ✅ PASS | Track per-directory progress in run |
| Unix Philosophy | Composable, text in/out | ✅ PASS | CLI args, exit codes preserved |
| Function Namespacing | `pndcgn_` prefix | ✅ PASS | New functions follow convention |
| No New Dependencies | Minimize external deps | ✅ PASS | fzf already optional, no new deps |

**Gate Result**: ✅ ALL PASS - Proceed to Phase 0

---

## 4. Project Structure

### 4.1. Documentation (this feature)

```text
specs/002-multi-dir-select/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (complete)
├── data-model.md        # Phase 1 output (complete)
├── quickstart.md        # Phase 1 output (complete)
├── contracts/           # Phase 1 output (complete)
│   └── cli-interface.md # CLI contract
├── checklists/          # Quality checklists
│   ├── requirements.md  # Requirements quality
│   └── bdd-tdd-cli-docs.md # BDD/TDD/CLI/Docs quality
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### 4.2. Source Code (repository root)

```text
bin/
└── pndcgn               # Main CLI - extend argument parsing for multi-source

src/
├── constants.sh         # Add PNDCGN_MAX_SOURCE_DIRS constant
├── utilities.sh         # Extend pndcgn_select_source_dirs() for multi-select
│                        # Add pndcgn_select_source_dirs_fallback()
│                        # Add pndcgn_compute_abbreviated_prefixes()
│                        # Add pndcgn_remove_overlapping_dirs()
│                        # Add pndcgn_parse_toml_max_source_dirs()
├── processing.sh        # Extend pndcgn_discover_files() for multi-source
│                        # Add pndcgn_generate_prefixed_filename()
└── database.sh          # Extend run schema for source_dirs JSON array

tests/
├── utilities/
│   ├── fzf_spec.sh      # Extend for multi-select tests
│   └── fallback_spec.sh # NEW: numbered list fallback tests
├── processing/
│   ├── file_discovery_spec.sh  # Multi-directory discovery tests
│   ├── filename_prefix_spec.sh # NEW: abbreviated prefix tests
│   └── overlap_detection_spec.sh # NEW: subdirectory exclusion tests
├── pndcgn_spec.sh       # CLI multi-directory argument tests
└── integration/
    └── multi_dir_spec.sh # NEW: end-to-end multi-directory tests
```

**Structure Decision**: Extend existing single-project structure. No new directories needed - feature integrates into existing modules.

---

## 5. Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

---

## 6. Phase 0: Research

### 6.1. Research Tasks

1. **fzf multi-select API**: Confirm `--multi` flag behavior and selection limit options ✅
2. **Shortest unique prefix algorithm**: Research efficient algorithm for computing minimal distinguishing prefixes ✅
3. **SQLite JSON storage**: Best practices for storing array of paths in SQLite column ✅
4. **CLI argument parsing**: Pattern for distinguishing multiple source dirs from target dir ✅
5. **fzf unavailability fallback**: Pattern for graceful degradation when fzf not installed ✅
6. **Overlapping directory detection**: Algorithm for detecting subdirectory relationships ✅

### 6.2. Findings

See [research.md](./research.md) for detailed findings.

---

## 7. Phase 1: Design

### 7.1. Data Model

See [data-model.md](./data-model.md) for entity definitions.

### 7.2. Contracts

See [contracts/](./contracts/) for CLI interface contract.

### 7.3. Quickstart

See [quickstart.md](./quickstart.md) for implementation guide.

---

## 8. Phase 2: Tasks

Run `/speckit.tasks` to generate implementation tasks from this plan.

---
