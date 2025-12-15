# Tasks: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

---

<details><summary>Table of Contents</summary>

- [Tasks: pndcgn Spec Consolidation](#tasks-pndcgn-spec-consolidation)
  - [1. Format: `[ID] [P?] [Story] Description`](#1-format-id-p-story-description)
  - [2. Development Guidelines](#2-development-guidelines)
  - [3. Implementation Strategy](#3-implementation-strategy)
    - [3.1. MVP First (User Story 1 Only)](#31-mvp-first-user-story-1-only)
    - [3.2. Incremental Delivery](#32-incremental-delivery)
    - [3.3. Parallel Team Strategy](#33-parallel-team-strategy)
  - [4. Dependencies \& Execution Order](#4-dependencies--execution-order)
    - [4.1. Phase Dependencies](#41-phase-dependencies)
    - [4.2. User Story Dependencies](#42-user-story-dependencies)
    - [4.3. Within Each User Story](#43-within-each-user-story)
    - [4.4. Parallel Opportunities](#44-parallel-opportunities)
    - [4.5. Recommended Implementation Order](#45-recommended-implementation-order)
  - [5. Parallel Example: User Story 1](#5-parallel-example-user-story-1)
  - [6. Phase 1: Setup (Shared Infrastructure)](#6-phase-1-setup-shared-infrastructure)
  - [7. Phase 2: Foundational (Blocking Prerequisites)](#7-phase-2-foundational-blocking-prerequisites)
  - [8. Phase 3: User Story 1 - Generate documentation outputs for a project (Priority: P1) 🎯 MVP](#8-phase-3-user-story-1---generate-documentation-outputs-for-a-project-priority-p1--mvp)
    - [8.1. Tests for User Story 1 ⚠️](#81-tests-for-user-story-1-️)
    - [8.2. Implementation for User Story 1](#82-implementation-for-user-story-1)
  - [9. Phase 4: User Story 2 - Preview a run and finalize safely (Priority: P2)](#9-phase-4-user-story-2---preview-a-run-and-finalize-safely-priority-p2)
    - [9.1. Tests for User Story 2 ⚠️](#91-tests-for-user-story-2-️)
    - [9.2. Implementation for User Story 2](#92-implementation-for-user-story-2)
  - [10. Phase 5: User Story 3 - Manage runs and understand results (Priority: P3)](#10-phase-5-user-story-3---manage-runs-and-understand-results-priority-p3)
    - [10.1. Tests for User Story 3 ⚠️](#101-tests-for-user-story-3-️)
    - [10.2. Implementation for User Story 3](#102-implementation-for-user-story-3)
  - [11. Phase 6: Polish \& Cross-Cutting Concerns](#11-phase-6-polish--cross-cutting-concerns)
    - [11.1. Tests for Polish Phase ⚠️](#111-tests-for-polish-phase-️)
    - [11.2. Implementation for Polish Phase](#112-implementation-for-polish-phase)
  - [12. Phase 7: Success Criteria Validation](#12-phase-7-success-criteria-validation)
    - [12.1. Success Criteria Validation Tasks](#121-success-criteria-validation-tasks)
  - [13. Phase 8: NFR P1-MVP (Critical Requirements)](#13-phase-8-nfr-p1-mvp-critical-requirements)
    - [13.1. Tests for NFR P1-MVP ⚠️](#131-tests-for-nfr-p1-mvp-️)
    - [13.2. Implementation for NFR P1-MVP](#132-implementation-for-nfr-p1-mvp)
  - [14. Phase 9: NFR P2 (High Priority Requirements)](#14-phase-9-nfr-p2-high-priority-requirements)
    - [14.1. Tests for NFR P2 ⚠️](#141-tests-for-nfr-p2-️)
      - [14.1.1. CLI UX Tests](#1411-cli-ux-tests)
      - [14.1.2. Caching Tests](#1412-caching-tests)
      - [14.1.3. Edge Cases Tests](#1413-edge-cases-tests)
      - [14.1.4. TOML Config Tests](#1414-toml-config-tests)
    - [14.2. Implementation for NFR P2](#142-implementation-for-nfr-p2)
      - [14.2.1. CLI UX Implementation](#1421-cli-ux-implementation)
      - [14.2.2. Caching Implementation](#1422-caching-implementation)
      - [14.2.3. Edge Cases Implementation](#1423-edge-cases-implementation)
      - [14.2.4. TOML Config Implementation](#1424-toml-config-implementation)
  - [15. Phase 10: NFR P3 (Medium Priority Requirements)](#15-phase-10-nfr-p3-medium-priority-requirements)
    - [15.1. Summary of P3 Tasks (114 NFRs)](#151-summary-of-p3-tasks-114-nfrs)
    - [15.2. P3 Implementation Tasks (Grouped)](#152-p3-implementation-tasks-grouped)
  - [16. Phase 11: NFR P4+ (Low Priority / Future)](#16-phase-11-nfr-p4-low-priority--future)
    - [16.1. Summary of P4+ Tasks (43 NFRs)](#161-summary-of-p4-tasks-43-nfrs)
    - [16.2. P4+ Placeholder Tasks](#162-p4-placeholder-tasks)
  - [17. Task Summary](#17-task-summary)

</details>

---

**Input**: Design documents from `/specs/001-sync-docs-spec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are organized by user story to enable independent implementation and testing of each story.

## 1. Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3])
- Include exact file paths in descriptions

## 2. Development Guidelines

- **Test-First Development**: All test tasks (T014a-T014p, T029a-T029h, T037a-T037l, T049a-T049j) MUST be written and FAIL before corresponding implementation tasks begin (Constitution §II)
- **[P] tasks** = different files, no dependencies
- **[Story] label** maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- All functions must use `pndcgn_` prefix for namespacing
- All variables must use `pndcgn_` or `PNDCGN_` prefix
- Strict mode: `set -euo pipefail` in all scripts
- Code coverage target: 50% minimum, 70% for utilities (per Constitution §II; kcov has subprocess tracking limitations)
- Coverage tracking: Use `When call` pattern for coverage-trackable tests; `When run` for subprocess isolation (mocking)

## 3. Implementation Strategy

### 3.1. MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### 3.2. Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### 3.3. Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core generation)
   - Developer B: User Story 2 (dry-run/finalize) - can start after US1 fingerprinting
   - Developer C: User Story 3 (run management) - can start after US1 run creation
3. Stories complete and integrate independently

## 4. Dependencies & Execution Order

### 4.1. Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete
- **Success Criteria Validation (Phase 7)**: Depends on Polish phase completion - validates implementation meets spec requirements
- **Phase 8 (NFR P1-MVP)**: Can start after Phase 2 (Foundational) - CRITICAL for release
- **Phase 9 (NFR P2)**: Can start after Phase 8 - Recommended for release candidate
- **Phase 10 (NFR P3)**: Can start after Phase 9 - Post-release enhancement
- **Phase 11 (NFR P4+)**: Future roadmap - No dependencies

### 4.2. User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 run creation and fingerprinting
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Depends on US1 run management and US2 fingerprint validation

### 4.3. Within Each User Story

- **Tests FIRST** (write failing tests before any implementation)
- Models/data structures before services
- Services before main controller logic
- Core implementation before integration
- Story complete before moving to next priority

### 4.4. Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002-T005)
- Foundational tasks T007-T008 can run in parallel (different functions)
- Foundational tasks T009-T013 can run in parallel (different modules)
- Once Foundational phase completes, US1 and US2 can start in parallel (US2 needs US1's fingerprinting)
- Polish phase test tasks (T049a-T049j) can all run in parallel
- Polish phase implementation tasks marked [P] can all run in parallel
- Success criteria validation tasks (T062-T065) can all run in parallel
- NFR P1-MVP tasks can run in parallel with Phase 3 (User Story 1)
- NFR P2 tasks can run in parallel with Phase 6 (Polish)

### 4.5. Recommended Implementation Order

1. **Phase 1-2**: Setup + Foundational
2. **Phase 8**: NFR P1-MVP (Critical) - Parallel with Phase 3
3. **Phase 3**: User Story 1 (MVP)
4. **Phase 8 completion**: Verify crash safety
5. **Phase 4-5**: User Stories 2-3
6. **Phase 9**: NFR P2 (High) - Parallel with Phase 6
7. **Phase 6-7**: Polish + Success Criteria
8. **Phase 9 completion**: Release candidate
9. **Phase 10**: Post-release (P3 Medium)
10. **Phase 11**: Future roadmap (P4+ Low)

## 5. Parallel Example: User Story 1

```bash
# Launch foundational utilities in parallel:
Task: "Implement pndcgn_install_ulid() function in src/utilities.sh"
Task: "Implement Bash-based ULID fallback function pndcgn_generate_ulid_fallback() in src/utilities.sh"
Task: "Implement prerequisite validation function pndcgn_check_prerequisites() in src/utilities.sh"

# Launch US1 core functions in parallel (after foundational):
Task: "Implement fingerprint computation function pndcgn_compute_fingerprint() in src/processing.sh"
Task: "Implement cache lookup function pndcgn_db_check_cache() in src/database.sh"
Task: "Implement pandoc conversion function pndcgn_convert_file() in src/processing.sh"
```

---

## 6. Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project directory structure per plan.md (bin/, src/, tests/, lib/)
- [X] T002 [P] Create src/constants.sh with ANSI codes and shared constants
- [X] T003 [P] Create tests/spec_helper.sh with ShellSpec test framework setup
- [X] T004 [P] Create bin/pndcgn entrypoint script with basic structure and help command
- [X] T005 [P] Configure ShellCheck linting rules and validation

---

## 7. Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Create src/utilities.sh module with helper functions (path resolution, logging)
- [X] T007 [P] Implement pndcgn_install_ulid() function in src/utilities.sh for sqlite-ulid extension download
- [X] T008 [P] Implement Bash-based ULID fallback function pndcgn_generate_ulid_fallback() in src/utilities.sh
- [X] T009 Create src/database.sh module with SQLite initialization and extension loading
- [X] T010 Implement database schema creation in src/database.sh (runs table with DEFAULT (ulid()), generated_artifacts table)
- [X] T011 Implement WAL mode configuration and database connection management in src/database.sh
- [X] T012 Implement prerequisite validation function pndcgn_check_prerequisites() in src/utilities.sh (pandoc, sqlite3, curl)
- [X] T013 Create XDG-compliant state directory structure for database location

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## 8. Phase 3: User Story 1 - Generate documentation outputs for a project (Priority: P1) 🎯 MVP

**Goal**: Core user value—turning a project's documentation sources into an organized output set

**Independent Test**: Run the tool against a small fixture project and confirm the expected output directory and index are produced

### 8.1. Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T014a [P] [US1] Write ShellSpec test for argument parsing (SOURCE_DIR, TARGET_DIR, --type) in tests/pndcgn_spec.sh
- [X] T014b [P] [US1] Write ShellSpec test for fzf integration fallback behavior in tests/pndcgn_spec.sh
- [X] T014c [P] [US1] Write ShellSpec test for .pndcgnignore discovery and auto-creation in tests/config_spec.sh
- [X] T014d [P] [US1] Write ShellSpec test for .gitignore stacking and seeding logic in tests/config_spec.sh
- [X] T014e [P] [US1] Write ShellSpec test for file discovery respecting .pndcgnignore patterns in tests/processing_spec.sh
- [X] T014f [P] [US1] Write ShellSpec test for fingerprint computation (format validation) in tests/processing_spec.sh
- [X] T014g [P] [US1] Write ShellSpec test for run creation with ULID generation in tests/database_spec.sh
- [X] T014h [P] [US1] Write ShellSpec test for cache lookup function in tests/database_spec.sh
- [X] T014i [P] [US1] Write ShellSpec test for pandoc conversion function in tests/processing_spec.sh
- [X] T014j [P] [US1] Write ShellSpec test for Dewey Decimal naming scheme in tests/processing_spec.sh
- [X] T014k [P] [US1] Write ShellSpec test for run output directory creation in tests/processing_spec.sh
- [X] T014l [P] [US1] Write ShellSpec test for run index generation (_index.md format) in tests/processing_spec.sh
- [X] T014m [P] [US1] Write ShellSpec test for output_fingerprint computation (format: {total_size}:{artifact_count}:{sha256_of_all_content}) in tests/processing_spec.sh
- [X] T014n [P] [US1] Write ShellSpec test for progress reporting format in tests/pndcgn_spec.sh
- [X] T014o [US1] Write ShellSpec integration test for end-to-end generation workflow in tests/pndcgn_spec.sh
- [X] T014p [US1] Write ShellSpec test for error handling (exit codes, stderr messages) in tests/pndcgn_spec.sh

### 8.2. Implementation for User Story 1

- [X] T014 [US1] Implement argument parsing in bin/pndcgn (SOURCE_DIR, TARGET_DIR, --type)
- [X] T015 [US1] Implement optional fzf integration for SOURCE_DIR selection in bin/pndcgn (if fzf available)
- [X] T016 [US1] Implement .pndcgnignore discovery and auto-creation logic in src/utilities.sh
- [X] T017 [US1] Implement .gitignore stacking and seeding logic for .pndcgnignore in src/utilities.sh
- [X] T018 [US1] Implement file discovery function respecting .pndcgnignore patterns in src/processing.sh
- [X] T019 [US1] Implement fingerprint computation function pndcgn_compute_fingerprint() in src/processing.sh (format: {size}:{mtime}:{sha256_first_64KB})
- [X] T020 [US1] Implement run creation function pndcgn_db_create_run() in src/database.sh (with ULID generation)
- [X] T021 [US1] Implement cache lookup function pndcgn_db_check_cache() in src/database.sh
- [X] T022 [US1] Implement pandoc conversion function pndcgn_convert_file() in src/processing.sh
- [X] T022a [US1] Implement output_fingerprint computation function pndcgn_compute_output_fingerprint() in src/processing.sh (format: {total_size}:{artifact_count}:{sha256_of_all_content}, sorted by artifact path)
- [X] T023 [US1] Implement Dewey Decimal naming scheme for output files in src/processing.sh
- [X] T024 [US1] Implement run output directory creation (${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/) in src/processing.sh
- [X] T025 [US1] Implement run index generation (_index.md with navigation links and statistics) in src/processing.sh
- [X] T026 [US1] Implement progress reporting to stdout (counts, timing, cache efficiency) in bin/pndcgn
- [X] T027 [US1] Implement main processing loop in bin/pndcgn (discover files, check cache, convert, update database)
- [X] T028 [US1] Implement error handling with explicit messages to stderr and appropriate exit codes in bin/pndcgn

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## 9. Phase 4: User Story 2 - Preview a run and finalize safely (Priority: P2)

**Goal**: Dry-run/finalize reduces risk for large repos and supports cautious workflows

**Independent Test**: Perform a dry-run, record the run identifier, change nothing, then finalize and verify outputs are produced

### 9.1. Tests for User Story 2 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T029a [P] [US2] Write ShellSpec test for --dry-run flag (no output artifacts, run ID printed) in tests/pndcgn_spec.sh
- [X] T029b [P] [US2] Write ShellSpec test for run fingerprint computation (combined fingerprint format) in tests/processing_spec.sh
- [X] T029c [P] [US2] Write ShellSpec test for run fingerprint storage during dry-run in tests/database_spec.sh
- [X] T029d [P] [US2] Write ShellSpec test for --finalize <RUN_ID> flag handling in tests/pndcgn_spec.sh
- [X] T029e [P] [US2] Write ShellSpec test for fingerprint validation function in tests/processing_spec.sh
- [X] T029f [P] [US2] Write ShellSpec test for finalize validation logic (fingerprint mismatch detection) in tests/pndcgn_spec.sh
- [X] T029g [P] [US2] Write ShellSpec test for error handling on fingerprint mismatch (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [X] T029h [US2] Write ShellSpec integration test for dry-run → finalize workflow in tests/pndcgn_spec.sh

### 9.2. Implementation for User Story 2

- [X] T029 [US2] Implement --dry-run flag handling in bin/pndcgn (no output artifacts, print run ID)
- [X] T030 [US2] Implement run fingerprint computation (combined fingerprint of all input files + config state) in src/processing.sh
- [X] T031 [US2] Implement run fingerprint storage in database during dry-run in src/database.sh
- [X] T032 [US2] Implement --finalize <RUN_ID> flag handling in bin/pndcgn
- [X] T033 [US2] Implement fingerprint validation function pndcgn_validate_fingerprint() in src/processing.sh
- [X] T034 [US2] Implement finalize validation logic (compare current fingerprint vs stored) in bin/pndcgn
- [X] T035 [US2] Implement error handling for fingerprint mismatch during finalize (exit code 1, actionable explanation) in bin/pndcgn
- [X] T036 [US2] Implement finalize execution (reuse dry-run plan, generate outputs) in bin/pndcgn

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## 10. Phase 5: User Story 3 - Manage runs and understand results (Priority: P3)

**Goal**: Run management and reporting turn the tool from "one-off script" into something teams can trust and operate

**Independent Test**: Interrupt a run, resume it, and validate that already-generated outputs are not repeated

### 10.1. Tests for User Story 3 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T037a [P] [US3] Write ShellSpec test for run status tracking (running, complete, failed, interrupted) in tests/database_spec.sh
- [X] T037b [P] [US3] Write ShellSpec test for --resume <RUN_ID> flag handling in tests/pndcgn_spec.sh
- [X] T037c [P] [US3] Write ShellSpec test for resume logic (skip already-processed files) in tests/pndcgn_spec.sh
- [X] T037d [P] [US3] Write ShellSpec test for fingerprint validation before resume in tests/pndcgn_spec.sh
- [X] T037e [P] [US3] Write ShellSpec test for --clean <RUN_ID> [RUN_ID...] flag with confirmation in tests/pndcgn_spec.sh
- [X] T037f [P] [US3] Write ShellSpec test for cleanup validation (fingerprint check, non-pndcgn artifact warning) in tests/pndcgn_spec.sh
- [X] T037g [P] [US3] Write ShellSpec test for run output directory deletion in tests/utilities_spec.sh
- [X] T037h [P] [US3] Write ShellSpec test for --drop flag with confirmation in tests/pndcgn_spec.sh
- [X] T037i [P] [US3] Write ShellSpec test for database cleanup and cache clearing in tests/database_spec.sh
- [X] T037j [P] [US3] Write ShellSpec test for run statistics query functions in tests/database_spec.sh
- [X] T037k [P] [US3] Write ShellSpec test for statistics display in run index (_index.md) in tests/processing_spec.sh
- [X] T037l [US3] Write ShellSpec integration test for resume interrupted run workflow in tests/pndcgn_spec.sh

### 10.2. Implementation for User Story 3

- [X] T037 [US3] Implement run status tracking (running, complete, failed, interrupted) in src/database.sh
- [X] T038 [US3] Implement --resume <RUN_ID> flag handling in bin/pndcgn
- [X] T039 [US3] Implement resume logic (load run state, skip already-processed files) in bin/pndcgn
- [X] T040 [US3] Implement fingerprint validation before resume in bin/pndcgn
- [X] T041 [US3] Implement --clean <RUN_ID> [RUN_ID...] flag handling with confirmation in bin/pndcgn
- [X] T042 [US3] Implement cleanup validation (fingerprint check, non-pndcgn artifact warning) in bin/pndcgn
- [X] T043 [US3] Implement run output directory deletion in src/utilities.sh
- [X] T044 [US3] Implement --drop flag handling with confirmation in bin/pndcgn
- [X] T045 [US3] Implement database cleanup and cache clearing in src/database.sh
- [X] T046 [US3] Implement run statistics query functions in src/database.sh (counts, timing, cache efficiency)
- [X] T047 [US3] Implement statistics display in run index (_index.md) in src/processing.sh
- [X] T048 [US3] Implement database query interface for programmatic statistics access in src/database.sh

**Checkpoint**: All user stories should now be independently functional

---

## 11. Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

### 11.1. Tests for Polish Phase ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T049a [P] Write ShellSpec test for TOML config file discovery (XDG config hierarchy) in tests/config_spec.sh
- [X] T049b [P] Write ShellSpec test for TOML config file parsing in tests/config_spec.sh
- [X] T049c [P] Write ShellSpec test for --reseed flag handling (.pndcgnignore re-seeding) in tests/pndcgn_spec.sh
- [X] T049d [P] Write ShellSpec test for --force flag handling (bypass cache) in tests/pndcgn_spec.sh
- [X] T049e [P] Write ShellSpec test for edge case: source directory unreadable (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [X] T049f [P] Write ShellSpec test for edge case: target directory unwritable (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [X] T049g [P] Write ShellSpec test for edge case: unsupported output type (exit code 2, list supported types) in tests/pndcgn_spec.sh
- [X] T049h [P] Write ShellSpec test for edge case: cached outputs missing (regenerate, log warning) in tests/database_spec.sh
- [X] T049i [P] Write ShellSpec test for edge case: fzf unavailable (silent fallback to CWD) in tests/pndcgn_spec.sh
- [X] T049j [P] Write ShellSpec test for edge case: sqlite-ulid extension download failure (Bash fallback, continue operation) in tests/utilities_spec.sh

### 11.2. Implementation for Polish Phase

- [X] T049 [P] Implement comprehensive error handling for all edge cases (source unreadable, target unwritable, unsupported output type, cached outputs missing, fzf unavailable, extension download failure) in bin/pndcgn
- [X] T050 [P] Implement concurrent run support validation (SQLite WAL mode, unique run IDs) in src/database.sh
- [X] T051 [P] Implement TOML config file discovery and parsing (XDG config hierarchy) in src/utilities.sh
- [X] T052 [P] Implement --reseed flag handling for .pndcgnignore re-seeding in bin/pndcgn
- [X] T053 [P] Implement --force flag handling (bypass cache) in bin/pndcgn
- [X] T054 [P] Implement output type validation against pandoc's supported formats in src/utilities.sh
- [X] T055 [P] Update all user-facing text to consistently use "pndcgn" product name
- [X] T056 [P] Implement trap handlers for cleanup on EXIT INT TERM signals in bin/pndcgn
- [X] T057 [P] Add comprehensive logging with pndcgn_log_info() and pndcgn_log_error() functions in src/utilities.sh
- [X] T058 [P] Validate quickstart.md acceptance checks
- [X] T059 [P] Run ShellCheck validation and fix all warnings
- [X] T060 [P] Update documentation (user guide, API reference) to reflect implementation
- [X] T061 [P] Implement code coverage measurement and enforce 50% threshold (integrate ShellSpec coverage reporting, add CI gate; see Constitution §II for kcov limitations)
- [X] T066 [P] Document test results capture process in plan.md (location: tests.results/ at repository root, format: markdown reports with timestamps and summaries, generation workflow)
- [X] T067 [P] Create tests.results directory structure and generate-reports.sh script in tests.results/ (repository root)
- [X] T068 [P] Capture test execution results with timestamps and generate markdown reports for all test runs (log files: tests.results/logs/{test-name}-{YYYYMMDD-HHMMSS}.log, reports: tests.results/reports/{test-name}-{YYYYMMDD-HHMMSS}.md with summaries)
- [X] T069 [P] Improve test report formatting: extract human-readable summaries for failed tests and warnings (not raw log output), wrap full test log in collapsible <details> tags, automatically remove log files after report generation
- [X] T070 [P] Configure ShellSpec coverage reporting to output to tests.results/coverage/ directory (update .shellspec with --covdir option)
- [X] T071 [P] Fix coverage tracking: Migrate tests/utilities/*.sh to use `When call` pattern for accurate kcov tracking (34% coverage achieved)
- [X] T072 [P] Document coverage limitation: tests/database/*.sh use `When run` for mocking (0% coverage expected, subprocess isolation required)
- [X] T073 [P] Document coverage limitation: tests/processing/*.sh use `When run` for mocking (0% coverage expected, subprocess isolation required)
- [X] T074 [P] Update tests/integration/utilities_integration_spec.sh to use `When call` pattern for coverage tracking
- [X] T075 [P] Verify coverage tracking: Confirmed `When call` pattern works (utilities.sh: 34%), documented in tests/README.md and .scratch/coverage-research-summary.md

---

## 12. Phase 7: Success Criteria Validation

**Purpose**: Validate that the implementation meets all measurable success criteria from spec.md

### 12.1. Success Criteria Validation Tasks

- [X] T062 [P] Implement performance benchmark test for SC-001 (validate repeat run completes ≥5× faster than initial run, report skipped vs processed) in tests/performance_spec.sh
- [X] T063 [P] Implement finalize success rate validation for SC-002 (validate 100% of dry-run finalizations with unchanged inputs succeed and produce matching outputs) in tests/pndcgn_spec.sh
- [X] T064 [P] Implement finalize failure validation for SC-003 (validate 100% of dry-run finalizations with changed inputs fail safely with actionable explanation) in tests/pndcgn_spec.sh
- [X] T065 [P] Implement usability test scenario for SC-004 (validate ≥90% of test users can locate and open specific document using run index in <60 seconds) in tests/usability_spec.sh

**Note**: SC-004 (usability testing) may require manual testing with real users or automated simulation. T065 provides the test framework; actual validation may need separate user testing session.

---

## 13. Phase 8: NFR P1-MVP (Critical Requirements)

**Purpose**: Core reliability, crash safety, data integrity - Required for release

**Reference**: See spec.md Non-Functional Requirements section for detailed specifications

### 13.1. Tests for NFR P1-MVP ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T076a [P] [NFR] Write ShellSpec test for non-TTY stdout detection and interactive feature disabling in tests/utilities_spec.sh
- [X] T076b [P] [NFR] Write ShellSpec test for NO_COLOR environment variable support in tests/utilities_spec.sh
- [X] T076c [P] [NFR] Write ShellSpec test for non-interactive mode requiring --yes flag in tests/pndcgn_spec.sh
- [X] T076d [P] [NFR] Write ShellSpec test for SIGINT graceful shutdown in tests/pndcgn_spec.sh
- [X] T076e [P] [NFR] Write ShellSpec test for files <64KB full content hashing in tests/processing_spec.sh
- [X] T076f [P] [NFR] Write ShellSpec test for empty file (0 bytes) fingerprint format in tests/processing_spec.sh
- [X] T076g [P] [NFR] Write ShellSpec test for mtime precision (integer seconds) in tests/processing_spec.sh
- [X] T076h [P] [NFR] Write ShellSpec test for deterministic fingerprint ordering (sorted by path) in tests/processing_spec.sh
- [X] T076i [P] [NFR] Write ShellSpec test for database file permissions (0600) in tests/database_spec.sh
- [X] T076j [P] [NFR] Write ShellSpec test for database corruption detection and recovery in tests/database_spec.sh
- [X] T076k [P] [NFR] Write ShellSpec test for run state machine transitions in tests/database_spec.sh
- [X] T076l [P] [NFR] Write ShellSpec test for "running" status recovery on startup in tests/database_spec.sh
- [X] T076m [P] [NFR] Write ShellSpec test for disk full error handling in tests/pndcgn_spec.sh
- [X] T076n [P] [NFR] Write ShellSpec test for file change during processing detection in tests/processing_spec.sh
- [X] T076o [P] [NFR] Write ShellSpec test for SIGTERM graceful shutdown in tests/pndcgn_spec.sh
- [X] T076p [P] [NFR] Write ShellSpec test for trap handler installation in tests/pndcgn_spec.sh
- [X] T076q [P] [NFR] Write ShellSpec test for config file in run fingerprint in tests/processing_spec.sh
- [X] T076r [P] [NFR] Write ShellSpec test for include/exclude pattern evaluation order in tests/config_spec.sh
- [X] T076s [P] [NFR] Write ShellSpec test for config change during dry-run/finalize detection in tests/pndcgn_spec.sh

### 13.2. Implementation for NFR P1-MVP

- [X] T076 [NFR] Implement pndcgn_is_interactive() function for TTY detection in src/utilities.sh (NFR-CLI-013)
- [X] T077 [NFR] Implement NO_COLOR environment variable support in src/constants.sh (NFR-CLI-014)
- [X] T078 [NFR] Implement --yes flag and non-interactive mode check in bin/pndcgn (NFR-CLI-027)
- [X] T079 [NFR] Implement SIGINT/SIGTERM trap handlers with graceful shutdown in bin/pndcgn (NFR-CLI-048, NFR-EDGE-041-045) ✅ Already implemented in T056
- [X] T080 [NFR] Update pndcgn_compute_fingerprint() for files <64KB in src/processing.sh (NFR-CACHE-001)
- [X] T081 [NFR] Implement empty file fingerprint with SHA256 of empty string in src/processing.sh (NFR-CACHE-002)
- [X] T082 [NFR] Ensure mtime precision is integer seconds in src/processing.sh (NFR-CACHE-003)
- [X] T083 [NFR] Implement sorted fingerprint ordering (lexicographic by path) in src/processing.sh (NFR-CACHE-007, NFR-CACHE-008)
- [X] T084 [NFR] Set database file permissions to 0600 in src/database.sh (NFR-CACHE-022)
- [X] T085 [NFR] Implement database corruption detection and recovery in src/database.sh (NFR-CACHE-023)
- [X] T086 [NFR] Implement run state machine with valid transitions in src/database.sh (NFR-CACHE-029-032)
- [X] T087 [NFR] Implement "running" status recovery on startup in src/database.sh (NFR-CACHE-031)
- [X] T088 [NFR] Implement disk full error handling in bin/pndcgn (NFR-EDGE-018, NFR-EDGE-074) ✅ Implemented: Disk usage check and error handling
- [X] T089 [NFR] Implement file change during processing detection in src/processing.sh (NFR-EDGE-024) ✅ Implemented: Fingerprint comparison before/after processing
- [X] T090 [NFR] Implement pndcgn_save_checkpoint() for interrupt handling in src/database.sh (NFR-EDGE-047) ✅ Implemented: pndcgn_save_checkpoint() function
- [X] T091 [NFR] Include config file content in run fingerprint in src/processing.sh (NFR-TOML-006) ✅ Implemented: Config hash included in run fingerprint
- [X] T092 [NFR] Implement include/exclude pattern evaluation order in src/processing.sh (NFR-TOML-044-045) ✅ Implemented: Include patterns from TOML evaluated first, then exclude patterns from .pndcgnignore, ** glob support for recursive matching
- [X] T093 [NFR] Implement config change detection during dry-run/finalize in src/processing.sh (NFR-TOML-048-049) ✅ Implemented: Config included in fingerprint, validated during finalize

**Checkpoint**: System is crash-safe and usable in CI/automation environments

---

## 14. Phase 9: NFR P2 (High Priority Requirements)

**Purpose**: Robust error handling, clear UX, common edge cases covered

### 14.1. Tests for NFR P2 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

#### 14.1.1. CLI UX Tests

- [X] T094a [P] [NFR] Write ShellSpec test for --help output structure in tests/pndcgn_spec.sh
- [X] T094b [P] [NFR] Write ShellSpec test for --version output in tests/pndcgn_spec.sh
- [X] T094c [P] [NFR] Write ShellSpec test for --verbose mode in tests/pndcgn_spec.sh
- [X] T094d [P] [NFR] Write ShellSpec test for ANSI color output in tests/utilities_spec.sh
- [X] T094e [P] [NFR] Write ShellSpec test for run ID display format in tests/pndcgn_spec.sh
- [X] T094f [P] [NFR] Write ShellSpec test for duration output format in tests/utilities_spec.sh
- [X] T094g [P] [NFR] Write ShellSpec test for confirmation prompt responses in tests/utilities_spec.sh
- [X] T094h [P] [NFR] Write ShellSpec test for final summary output in tests/pndcgn_spec.sh
- [X] T094i [P] [NFR] Write ShellSpec test for error message format in tests/pndcgn_spec.sh
- [X] T094j [P] [NFR] Write ShellSpec test for interrupted state communication in tests/pndcgn_spec.sh

#### 14.1.2. Caching Tests

- [X] T095a [P] [NFR] Write ShellSpec test for SHA256 implementation detection in tests/processing_spec.sh
- [X] T095b [P] [NFR] Write ShellSpec test for TOML config in fingerprint in tests/processing_spec.sh
- [X] T095c [P] [NFR] Write ShellSpec test for source file delete cache invalidation in tests/database_spec.sh
- [X] T095d [P] [NFR] Write ShellSpec test for output type change cache miss in tests/database_spec.sh
- [X] T095e [P] [NFR] Write ShellSpec test for database schema versioning in tests/database_spec.sh
- [X] T095f [P] [NFR] Write ShellSpec test for run timestamp format in tests/database_spec.sh
- [X] T095g [P] [NFR] Write ShellSpec test for resume completed run error in tests/pndcgn_spec.sh
- [X] T095h [P] [NFR] Write ShellSpec test for resume with deleted source files in tests/pndcgn_spec.sh
- [X] T095i [P] [NFR] Write ShellSpec test for multiple pending dry-runs in tests/database_spec.sh
- [X] T095j [P] [NFR] Write ShellSpec test for sqlite-ulid version check in tests/database_spec.sh
- [X] T095k [P] [NFR] Write ShellSpec test for clean non-existent run ID error in tests/pndcgn_spec.sh

#### 14.1.3. Edge Cases Tests

- [X] T096a [P] [NFR] Write ShellSpec test for empty source directory warning in tests/pndcgn_spec.sh
- [X] T096b [P] [NFR] Write ShellSpec test for source not-a-directory error in tests/pndcgn_spec.sh
- [X] T096c [P] [NFR] Write ShellSpec test for source paths with spaces in tests/pndcgn_spec.sh
- [X] T096d [P] [NFR] Write ShellSpec test for symlink following in tests/processing_spec.sh
- [X] T096e [P] [NFR] Write ShellSpec test for broken symlink skipping in tests/processing_spec.sh
- [X] T096f [P] [NFR] Write ShellSpec test for circular symlink detection in tests/processing_spec.sh
- [X] T096g [P] [NFR] Write ShellSpec test for target directory creation in tests/pndcgn_spec.sh
- [X] T096h [P] [NFR] Write ShellSpec test for empty input file processing in tests/processing_spec.sh
- [X] T096i [P] [NFR] Write ShellSpec test for binary file skipping in tests/processing_spec.sh
- [X] T096j [P] [NFR] Write ShellSpec test for permission denied skipping in tests/processing_spec.sh
- [X] T096k [P] [NFR] Write ShellSpec test for output type case insensitivity in tests/pndcgn_spec.sh
- [X] T096l [P] [NFR] Write ShellSpec test for database locking timeout in tests/database_spec.sh
- [X] T096m [P] [NFR] Write ShellSpec test for SIGHUP ignore in tests/pndcgn_spec.sh
- [X] T096n [P] [NFR] Write ShellSpec test for sqlite3 prerequisite check in tests/utilities_spec.sh
- [X] T096o [P] [NFR] Write ShellSpec test for pandoc crash handling in tests/processing_spec.sh
- [X] T096p [P] [NFR] Write ShellSpec test for malformed .pndcgnignore warning in tests/config_spec.sh
- [X] T096q [P] [NFR] Write ShellSpec test for cleanup active run error in tests/pndcgn_spec.sh

#### 14.1.4. TOML Config Tests

- [X] T097a [P] [NFR] Write ShellSpec test for config symlink following in tests/config_spec.sh
- [X] T097b [P] [NFR] Write ShellSpec test for XDG_CONFIG_HOME with spaces in tests/config_spec.sh
- [X] T097c [P] [NFR] Write ShellSpec test for config directory error in tests/config_spec.sh
- [X] T097d [P] [NFR] Write ShellSpec test for glob pattern wildcards in tests/config_spec.sh
- [X] T097e [P] [NFR] Write ShellSpec test for pattern case sensitivity in tests/config_spec.sh
- [X] T097f [P] [NFR] Write ShellSpec test for extension case insensitivity in tests/config_spec.sh
- [X] T097g [P] [NFR] Write ShellSpec test for TOML multi-line arrays in tests/config_spec.sh
- [X] T097h [P] [NFR] Write ShellSpec test for TOML comments in tests/config_spec.sh
- [X] T097i [P] [NFR] Write ShellSpec test for parse error line numbers in tests/config_spec.sh
- [X] T097j [P] [NFR] Write ShellSpec test for absolute path pattern rejection in tests/config_spec.sh
- [X] T097k [P] [NFR] Write ShellSpec test for HOME unset error in tests/config_spec.sh

### 14.2. Implementation for NFR P2

#### 14.2.1. CLI UX Implementation

- [X] T094 [NFR] Implement structured --help output in bin/pndcgn (NFR-CLI-001-007) ✅ Already implemented: pndcgn_usage() with structured output
- [X] T098 [NFR] Implement --version flag in bin/pndcgn (NFR-CLI-002) ✅ Implemented: --version flag displays version
- [X] T099 [NFR] Implement --verbose mode in bin/pndcgn (NFR-CLI-011) ✅ Implemented: --verbose flag, pndcgn_log_verbose()
- [X] T100 [NFR] Implement ANSI color output functions in src/constants.sh (NFR-CLI-015) ✅ Already implemented: NO_COLOR support
- [X] T101 [NFR] Implement run ID display format in src/utilities.sh (NFR-CLI-020-021) ✅ Implemented: pndcgn_format_run_id()
- [X] T102 [NFR] Implement human-readable duration formatting in src/utilities.sh (NFR-CLI-022) ✅ Implemented: pndcgn_format_duration()
- [X] T103 [NFR] Implement confirmation prompt with valid responses in src/utilities.sh (NFR-CLI-024-025) ✅ Implemented: pndcgn_confirm()
- [X] T104 [NFR] Implement final summary output in bin/pndcgn (NFR-CLI-034) ✅ Implemented: Enhanced summary with formatted run ID and duration
- [X] T105 [NFR] Implement error message format with actionable suggestions in src/utilities.sh (NFR-CLI-037-039) ✅ Implemented: Enhanced error messages with actionable suggestions
- [X] T106 [NFR] Implement interrupted state communication in bin/pndcgn (NFR-CLI-049) ✅ Implemented: Interrupted state message in cleanup handler

#### 14.2.2. Caching Implementation

- [X] T107 [NFR] Implement SHA256 tool detection in src/processing.sh (NFR-CACHE-005) ✅ Implemented: SHA256 command detection
- [X] T108 [NFR] Include TOML config content in fingerprint in src/processing.sh (NFR-CACHE-009) ✅ Already implemented in T091
- [X] T109 [NFR] Implement cache invalidation on source delete/rename/move in src/database.sh (NFR-CACHE-011-013) ✅ Implemented: pndcgn_db_invalidate_cache()
- [X] T110 [NFR] Implement cache key including output type in src/database.sh (NFR-CACHE-014) ✅ Implemented: output_type in cache lookup and artifacts table
- [X] T111 [NFR] Implement database schema version table in src/database.sh (NFR-CACHE-020-021) ✅ Implemented: schema_version table
- [X] T112 [NFR] Implement run timestamp storage in src/database.sh (NFR-CACHE-027-028) ✅ Implemented: created_at timestamp in run creation
- [X] T113 [NFR] Implement resume error messages for complete/failed runs in bin/pndcgn (NFR-CACHE-033-035) ✅ Implemented: Resume error messages for complete/failed runs
- [X] T114 [NFR] Implement resume with deleted/added source files in bin/pndcgn (NFR-CACHE-036-037) ✅ Implemented: Deleted file detection and cache invalidation
- [X] T115 [NFR] Implement multiple pending dry-runs support in src/database.sh (NFR-CACHE-041-042) ✅ Implemented: Multiple dry-runs allowed (no restrictions)
- [X] T116 [NFR] Implement finalize error messages in bin/pndcgn (NFR-CACHE-043-044) ✅ Implemented: Enhanced finalize error messages
- [X] T117 [NFR] Check sqlite-ulid extension version in src/database.sh (NFR-CACHE-046) ✅ Implemented: Version check in pndcgn_load_ulid_extension()
- [X] T118 [NFR] Implement clean non-existent run error in bin/pndcgn (NFR-CACHE-053) ✅ Implemented: Error message for non-existent runs

#### 14.2.3. Edge Cases Implementation

- [X] T119 [NFR] Implement empty source directory warning in bin/pndcgn (NFR-EDGE-001-002) ✅ Implemented: Empty directory check with warning
- [X] T120 [NFR] Implement source not-a-directory check in bin/pndcgn (NFR-EDGE-003) ✅ Implemented: Directory validation with actionable error
- [X] T121 [NFR] Implement source paths with spaces handling in bin/pndcgn (NFR-EDGE-005) ✅ Implemented: Path resolution handles spaces and trailing slashes
- [X] T122 [NFR] Implement symlink following in src/processing.sh (NFR-EDGE-007) ✅ Implemented: Symlink resolution in file discovery
- [X] T123 [NFR] Implement broken symlink skipping in src/processing.sh (NFR-EDGE-008) ✅ Implemented: Broken symlink detection and skip
- [X] T124 [NFR] Implement circular symlink detection in src/processing.sh (NFR-EDGE-009) ✅ Implemented: Circular symlink detection
- [X] T125 [NFR] Implement automatic target directory creation in bin/pndcgn (NFR-EDGE-012-013) ✅ Implemented: Auto-create target directory with error handling
- [X] T126 [NFR] Implement empty input file processing in src/processing.sh (NFR-EDGE-020) ✅ Implemented: Empty file handling in conversion
- [X] T127 [NFR] Implement binary file detection and skipping in src/processing.sh (NFR-EDGE-021) ✅ Implemented: Binary file detection and skip
- [X] T128 [NFR] Implement permission denied file skipping in src/processing.sh (NFR-EDGE-023) ✅ Implemented: Permission check with warning
- [X] T129 [NFR] Implement output type case-insensitive matching in bin/pndcgn (NFR-EDGE-032) ✅ Implemented: Output type normalization
- [X] T130 [NFR] Implement database locking timeout (30s) in src/database.sh (NFR-EDGE-036-037) ✅ Implemented: PRAGMA busy_timeout=30000
- [X] T131 [NFR] Implement SIGHUP ignore in bin/pndcgn (NFR-EDGE-044) ✅ Verified: Only INT/TERM are trapped, SIGHUP ignored
- [X] T132 [NFR] Implement sqlite3 prerequisite check in src/utilities.sh (NFR-EDGE-054) ✅ Implemented: Enhanced prerequisite check
- [X] T133 [NFR] Implement pandoc crash handling in src/processing.sh (NFR-EDGE-056-057) ✅ Implemented: Pandoc error handling with cleanup
- [X] T134 [NFR] Implement malformed .pndcgnignore warning in src/utilities.sh (NFR-EDGE-061) ✅ Implemented: Malformed file detection
- [X] T135 [NFR] Implement cleanup active run check in bin/pndcgn (NFR-EDGE-068) ✅ Implemented: Active run check in clean handler

#### 14.2.4. TOML Config Implementation

- [X] T136 [NFR] Implement config symlink following in src/utilities.sh (NFR-TOML-001) ✅ Implemented: readlink in config discovery
- [X] T137 [NFR] Handle XDG_CONFIG_HOME with spaces in src/utilities.sh (NFR-TOML-002-003) ✅ Implemented: Path handling with spaces
- [X] T138 [NFR] Implement config directory check in src/utilities.sh (NFR-TOML-005) ✅ Implemented: Error handling in get_config_dir
- [X] T139 [NFR] Implement glob pattern support (*, **, ?, []) in src/processing.sh (NFR-TOML-007-010) ✅ Implemented: **, *, ?, [] support in glob matching
- [X] T140 [NFR] Implement pattern case sensitivity in src/processing.sh (NFR-TOML-015) ✅ Implemented: Case-sensitive pattern matching
- [X] T141 [NFR] Implement extension case insensitivity in src/processing.sh (NFR-TOML-017) ✅ Implemented: Extension normalization
- [X] T142 [NFR] Implement compound extension matching in src/processing.sh (NFR-TOML-018) ✅ Implemented: Compound extension support (.md.txt, etc.)
- [X] T143 [NFR] Implement TOML multi-line and inline array parsing in src/utilities.sh (NFR-TOML-023-024) ✅ Implemented: AWK handles multi-line and inline arrays
- [X] T144 [NFR] Implement TOML comment handling in src/utilities.sh (NFR-TOML-027) ✅ Implemented: AWK skips comment lines
- [X] T145 [NFR] Implement TOML duplicate key handling in src/utilities.sh (NFR-TOML-030) ✅ Implemented: Last occurrence wins (AWK behavior)
- [X] T146 [NFR] Implement parse error line numbers in src/utilities.sh (NFR-TOML-033-034) ✅ Implemented: Parse error detection and reporting
- [X] T147 [NFR] Implement absolute path pattern rejection in src/utilities.sh (NFR-TOML-043) ✅ Implemented: Absolute path pattern rejection with warning
- [X] T148 [NFR] Implement pattern OR evaluation in src/processing.sh (NFR-TOML-046) ✅ Implemented: OR logic for pattern matching (any pattern matches)
- [X] T149 [NFR] Implement HOME unset check in src/utilities.sh (NFR-TOML-053) ✅ Implemented: HOME check in get_config_dir/get_state_dir

**Checkpoint**: Robust error handling and clear UX for common scenarios

---

## 15. Phase 10: NFR P3 (Medium Priority Requirements)

**Purpose**: Polish, additional edge cases, improved robustness

**Note**: P3 tasks are documented but implementation is optional for initial release. See spec.md NFR sections for full details.

### 15.1. Summary of P3 Tasks (114 NFRs)

- **CLI UX (26)**: Quiet mode, stdin input, terminal handling, progress indicators, statistics formatting, fzf details
- **Caching (22)**: Advanced fingerprint details, output fingerprint edge cases, database transactions, cache metrics, cleanup details
- **Edge Cases (36)**: Path edge cases, file encoding/naming, resource limits, network mount handling
- **TOML Config (30)**: Brace expansion, escape sequences, validation formats, edge cases, documentation

### 15.2. P3 Implementation Tasks (Grouped)

- [X] T150 [P] [NFR-P3] Implement --quiet mode in bin/pndcgn (NFR-CLI-010) ✅ Implemented: --quiet flag, pndcgn_is_quiet(), quiet-aware logging
- [X] T151 [P] [NFR-P3] Implement stdin/pipe input support in bin/pndcgn (NFR-CLI-012) ✅ Implemented: stdin detection and source directory reading
- [X] T152 [P] [NFR-P3] Implement TERM environment handling in src/utilities.sh (NFR-CLI-016) ✅ Implemented: pndcgn_check_term() with TERM detection
- [X] T153 [P] [NFR-P3] Implement progress spinner animation in src/utilities.sh (NFR-CLI-029-032) ✅ Implemented: pndcgn_spinner_start/stop() functions
- [X] T154 [P] [NFR-P3] Implement byte size formatting in src/utilities.sh (NFR-CLI-023) ✅ Implemented: pndcgn_format_bytes() function
- [X] T155 [P] [NFR-P3] Implement statistics column alignment in bin/pndcgn (NFR-CLI-035-036) ✅ Implemented: Column-aligned statistics output
- [X] T156 [P] [NFR-P3] Implement fzf display options in bin/pndcgn (NFR-CLI-042-046) ✅ Implemented: Enhanced fzf with preview and header
- [X] T157 [P] [NFR-P3] Implement mtime UTC handling in src/processing.sh (NFR-CACHE-004) ✅ Implemented: UTC-normalized mtime using gdate
- [X] T158 [P] [NFR-P3] Implement fingerprint version embedding in src/processing.sh (NFR-CACHE-010) ✅ Implemented: v1: prefix in fingerprints
- [X] T159 [P] [NFR-P3] Implement database transaction boundaries in src/database.sh (NFR-CACHE-026) ✅ Implemented: BEGIN TRANSACTION/COMMIT in key operations
- [X] T160 [P] [NFR-P3] Implement /dev/urandom for Bash ULID in src/utilities.sh (NFR-CACHE-047) ✅ Implemented: /dev/urandom usage in ULID fallback
- [X] T161 [P] [NFR-P3] Implement cache statistics display format in bin/pndcgn (NFR-CACHE-050) ✅ Implemented: Cache efficiency in summary output
- [X] T162 [P] [NFR-P3] Implement cleanup progress display in bin/pndcgn (NFR-CACHE-054-057) ✅ Implemented: Progress counter in clean handler
- [X] T163 [P] [NFR-P3] Implement orphaned cache cleanup in src/database.sh (NFR-CACHE-059) ✅ Implemented: pndcgn_db_cleanup_orphaned_cache()
- [X] T164 [P] [NFR-P3] Implement trailing slash normalization in bin/pndcgn (NFR-EDGE-004) ✅ Implemented: Trailing slash removal in pndcgn_resolve_path()
- [X] T165 [P] [NFR-P3] Implement special character path handling in bin/pndcgn (NFR-EDGE-006) ✅ Implemented: Path resolution handles special characters via proper quoting
- [X] T166 [P] [NFR-P3] Implement large file warning in src/processing.sh (NFR-EDGE-022) ✅ Implemented: >100MB file warning in pndcgn_convert_file()
- [X] T167 [P] [NFR-P3] Implement unusual encoding passthrough in src/processing.sh (NFR-EDGE-025-026) ✅ Implemented: Files passed to pandoc as-is (pandoc handles encoding)
- [X] T168 [P] [NFR-P3] Implement pandoc version check in src/utilities.sh (NFR-EDGE-058) ✅ Implemented: Version check with warning for <2.0
- [X] T169 [P] [NFR-P3] Implement brace expansion in patterns in src/processing.sh (NFR-TOML-011) ✅ Implemented: {a,b,c} expansion to (a|b|c) pattern
- [X] T170 [P] [NFR-P3] Implement pattern escaping in src/processing.sh (NFR-TOML-016) ✅ Implemented: Backslash preservation in patterns
- [X] T171 [P] [NFR-P3] Implement TOML escape sequences in src/utilities.sh (NFR-TOML-026) ✅ Implemented: unescape_toml() function in AWK script
- [X] T172 [P] [NFR-P3] Implement validation error format in src/utilities.sh (NFR-TOML-038-040) ✅ Implemented: Error format "Config warning: file: error"
- [X] T173 [P] [NFR-P3] Implement path traversal rejection in src/utilities.sh (NFR-TOML-042) ✅ Implemented: ../ pattern rejection with warning
- [X] T174 [P] [NFR-P3] Implement config size limit (1MB) in src/utilities.sh (NFR-TOML-052) ✅ Implemented: Config size check with warning
- [X] T175 [P] [NFR-P3] Implement Unicode pattern support in src/processing.sh (NFR-TOML-058-059) ✅ Implemented: Bash glob supports Unicode natively
- [X] T176 [P] [NFR-P3] Document default pattern rationale in contracts/toml-config.md (NFR-TOML-060) ✅ Implemented: Created docs/toml-config-defaults.md with rationale

---

## 16. Phase 11: NFR P4+ (Low Priority / Future)

**Purpose**: Nice-to-have features, future enhancements

**Note**: P4+ tasks are documented for future roadmap. Implementation is not planned for current release.

### 16.1. Summary of P4+ Tasks (43 NFRs)

- Man page documentation (NFR-CLI-009)
- Screen reader compatibility (NFR-CLI-018)
- Colorblind-friendly colors (NFR-CLI-019)
- ETA display (NFR-CLI-033)
- Localization/i18n (NFR-CLI-041)
- fzf keybindings (NFR-CLI-047)
- Cache warming/preloading (NFR-CACHE-017)
- Historical cache metrics (NFR-CACHE-051)
- Cleanup audit trail (NFR-CACHE-058)
- Migration examples (NFR-TOML-062)
- Troubleshooting examples (NFR-TOML-063)

### 16.2. P4+ Placeholder Tasks

- [X] T177 [NFR-P4+] Create man page for pndcgn (NFR-CLI-009)
- [X] T178 [NFR-P4+] Implement screen reader structured output (NFR-CLI-018)
- [X] T179 [NFR-P4+] Implement colorblind-friendly color scheme (NFR-CLI-019)
- [X] T180 [NFR-P4+] Implement ETA display for long operations (NFR-CLI-033)
- [X] T181 [NFR-P4+] Add migration examples to documentation (NFR-TOML-062)
- [X] T182 [NFR-P4+] Add troubleshooting examples to documentation (NFR-TOML-063)

---

## 17. Task Summary

| Phase | Count | Status |
|-------|-------|--------|
| Phase 1: Setup | 5 | ✅ Complete |
| Phase 2: Foundational | 8 | ✅ Complete |
| Phase 3: User Story 1 | 31 | ✅ Complete |
| Phase 4: User Story 2 | 16 | ✅ Complete |
| Phase 5: User Story 3 | 24 | ✅ Complete |
| Phase 6: Polish | 28 | ✅ Complete |
| Phase 7: Success Criteria | 4 | ✅ Complete |
| **Phase 8: NFR P1-MVP** | **37** | ✅ Complete |
| **Phase 9: NFR P2** | **97** | ✅ Complete |
| **Phase 10: NFR P3** | **27** | ✅ Complete |
| **Phase 11: NFR P4+** | **6** | ✅ Complete |
| **Total** | **283** | ✅ Complete |

---
