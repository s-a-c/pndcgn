# Tasks: Multi-Directory Selection via fzf

**Input**: Design documents from `/specs/002-multi-dir-select/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-interface.md, quickstart.md

**Tests**: Included (TDD approach per constitution - Test-First Development is NON-NEGOTIABLE)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

---

<details><summary>Table of Contents</summary>

- [Tasks: Multi-Directory Selection via fzf](#tasks-multi-directory-selection-via-fzf)
  - [1. Format: `[ID] [P?] [Story] Description`](#1-format-id-p-story-description)
  - [2. Path Conventions](#2-path-conventions)
  - [3. Phase 0: Documentation (Constitution §III Compliance)](#3-phase-0-documentation-constitution-iii-compliance)
  - [4. Phase 1: Setup (Shared Infrastructure)](#4-phase-1-setup-shared-infrastructure)
  - [5. Phase 2: Foundational (Blocking Prerequisites)](#5-phase-2-foundational-blocking-prerequisites)
  - [6. Phase 3: User Story 1 - Select Multiple Source Directories (Priority: P1) 🎯 MVP](#6-phase-3-user-story-1---select-multiple-source-directories-priority-p1--mvp)
    - [6.1. Tests for User Story 1](#61-tests-for-user-story-1)
    - [6.2. Implementation for User Story 1](#62-implementation-for-user-story-1)
  - [7. Phase 4: User Story 2 - Configure Maximum Selection Limit (Priority: P2)](#7-phase-4-user-story-2---configure-maximum-selection-limit-priority-p2)
    - [7.1. Tests for User Story 2](#71-tests-for-user-story-2)
    - [7.2. Implementation for User Story 2](#72-implementation-for-user-story-2)
  - [8. Phase 5: User Story 3 - Backward Compatibility (Priority: P3)](#8-phase-5-user-story-3---backward-compatibility-priority-p3)
    - [8.1. Tests for User Story 3](#81-tests-for-user-story-3)
    - [8.2. Implementation for User Story 3](#82-implementation-for-user-story-3)
  - [9. Phase 6: User Story 4 - CLI Multi-Directory Support (Priority: P2)](#9-phase-6-user-story-4---cli-multi-directory-support-priority-p2)
    - [9.1. Tests for User Story 4](#91-tests-for-user-story-4)
    - [9.2. Implementation for User Story 4](#92-implementation-for-user-story-4)
  - [10. Phase 7: Derived Feature - fzf Fallback (FR-016)](#10-phase-7-derived-feature---fzf-fallback-fr-016)
    - [10.1. Tests for fzf Fallback](#101-tests-for-fzf-fallback)
    - [10.2. Implementation for fzf Fallback](#102-implementation-for-fzf-fallback)
  - [11. Phase 8: Polish \& Cross-Cutting Concerns](#11-phase-8-polish--cross-cutting-concerns)
  - [12. Dependencies \& Execution Order](#12-dependencies--execution-order)
    - [12.1. Phase Dependencies](#121-phase-dependencies)
    - [12.2. User Story Dependencies](#122-user-story-dependencies)
    - [12.3. Within Each User Story](#123-within-each-user-story)
    - [12.4. Parallel Opportunities](#124-parallel-opportunities)
  - [13. Parallel Example: Documentation Phase](#13-parallel-example-documentation-phase)
  - [14. Parallel Example: Foundational Phase](#14-parallel-example-foundational-phase)
  - [15. Parallel Example: User Story 1 Tests](#15-parallel-example-user-story-1-tests)
  - [16. Implementation Strategy](#16-implementation-strategy)
    - [16.1. MVP First (User Story 1 Only)](#161-mvp-first-user-story-1-only)
    - [16.2. Incremental Delivery](#162-incremental-delivery)
    - [16.3. Suggested MVP Scope](#163-suggested-mvp-scope)
  - [17. Notes](#17-notes)

</details>

---

## 1. Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## 2. Path Conventions

- **Single CLI project**: `src/`, `tests/`, `bin/` at repository root
- Per plan.md: Extend existing modules, no new directories needed

---

## 3. Phase 0: Documentation (Constitution §III Compliance)

**Purpose**: Update canonical documentation per Documentation-Driven Design principle (NON-NEGOTIABLE)

**⚠️ CRITICAL**: Constitution §III requires documentation updates BEFORE implementation

- [x] T001 [P] Update `docs/020-requirements.md` - add FR-001 to FR-018 in REQ-XXX format with traceability IDs
- [x] T002 [P] Update `docs/070-api-reference.md` - add function signatures for all new functions (pndcgn_select_source_dirs, pndcgn_compute_abbreviated_prefixes, pndcgn_generate_prefixed_filename, pndcgn_remove_overlapping_dirs, pndcgn_parse_toml_max_source_dirs, pndcgn_validate_source_count, pndcgn_select_source_dirs_fallback)
- [x] T003 [P] Update `docs/100-system-test-plan.md` - add TEST-XXX entries for all acceptance scenarios from spec.md User Stories 1-4
- [x] T004 Update `docs/020-requirements.md` traceability matrix - link REQ-XXX → TEST-XXX → Implementation

**Checkpoint**: Documentation complete - implementation can proceed per constitution ✅

**Status**: All Phase 0 tasks complete (T001-T004)
- ✅ Requirements added to docs/020-requirements.md (REQ-017 to REQ-035)
- ✅ Function signatures added to docs/070-api-reference.md
- ✅ System tests added to docs/100-system-test-plan.md (ST-017 to ST-035)
- ✅ Traceability matrix updated

---

## 4. Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add constants and shared infrastructure for multi-directory feature

- [x] T005 Add multi-directory constants to `src/constants.sh` (PNDCGN_DEFAULT_MAX_SOURCE_DIRS=4, PNDCGN_ABSOLUTE_MAX_SOURCE_DIRS=16)
- [x] T006 [P] Create test file structure for new tests in `tests/utilities/fallback_spec.sh`
- [x] T007 [P] Create test file structure for prefix tests in `tests/processing/filename_prefix_spec.sh`
- [x] T008 [P] Create test file structure for overlap tests in `tests/processing/overlap_detection_spec.sh`
- [x] T009 [P] Create test file structure for integration tests in `tests/integration/multi_dir_spec.sh`

---

## 5. Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T010 Implement `pndcgn_parse_toml_max_source_dirs()` in `src/utilities.sh` - parse max_source_dirs from [source] section
- [x] T011 [P] Write unit tests for `pndcgn_parse_toml_max_source_dirs()` in `tests/utilities/config_spec.sh` (default value, valid config, invalid config, over-max config)
- [x] T012 Implement `pndcgn_compute_abbreviated_prefixes()` in `src/utilities.sh` - shortest unique prefix algorithm
- [x] T013 [P] Write unit tests for `pndcgn_compute_abbreviated_prefixes()` in `tests/processing/filename_prefix_spec.sh` (unique basenames, common prefixes, identical basenames)
- [x] T014 Implement `pndcgn_generate_prefixed_filename()` in `src/processing.sh` - format output filenames with prefix
- [x] T015 [P] Write unit tests for `pndcgn_generate_prefixed_filename()` in `tests/processing/filename_prefix_spec.sh` (with prefix, without prefix, special chars)
- [x] T016 Implement `pndcgn_remove_overlapping_dirs()` in `src/utilities.sh` - detect and exclude subdirectories
- [x] T017 [P] Write unit tests for `pndcgn_remove_overlapping_dirs()` in `tests/processing/overlap_detection_spec.sh` (no overlap, one subdir, nested subdirs)
- [x] T018 Extend SQLite schema in `src/database.sh` - add `source_dirs` TEXT column to runs table
- [x] T019 [P] Write migration test in `tests/database/schema_migration_spec.sh` - verify column added, existing data migrated
- [x] T020 Modify `pndcgn_db_create_run()` in `src/database.sh` - accept source_dirs_json parameter, populate both columns

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## 6. Phase 3: User Story 1 - Select Multiple Source Directories (Priority: P1) 🎯 MVP

**Goal**: Allow users to select multiple directories using fzf multi-select (Tab key) and process all in a single run

**Independent Test**: Launch pndcgn without arguments, use Tab to select 2-3 directories in fzf, verify all are processed with abbreviated prefixes

### 6.1. Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T021 [P] [US1] Write BDD test for fzf multi-select in `tests/utilities/fzf_spec.sh` - Given fzf available, When Tab used, Then multiple dirs returned
- [x] T022 [P] [US1] Write BDD test for processing multiple dirs in `tests/integration/multi_dir_spec.sh` - Given 3 dirs selected, When processed, Then all files converted
- [x] T023 [P] [US1] Write BDD test for abbreviated prefixes in `tests/integration/multi_dir_spec.sh` - Given frontend/backend dirs, Then output uses front--/back-- prefixes
- [x] T024 [P] [US1] Write BDD test for single run ID in `tests/integration/multi_dir_spec.sh` - Given multi-dir run, Then single run_id covers all
- [x] T025 [P] [US1] Write BDD test for dynamic header count (FR-009) in `tests/utilities/fzf_spec.sh` - Given fzf launched, Then header shows "max=$max_dirs"

### 6.2. Implementation for User Story 1

- [x] T026 [US1] Implement `pndcgn_select_source_dirs()` in `src/utilities.sh` - fzf with --multi=$max_dirs flag AND dynamic header showing selection count (FR-009)
- [x] T027 [US1] Implement deduplication logic in `pndcgn_select_source_dirs()` - resolve absolute paths, remove duplicates with WARN
- [x] T028 [US1] Integrate overlap detection in `pndcgn_select_source_dirs()` - call `pndcgn_remove_overlapping_dirs()` after selection
- [x] T029 [US1] Update processing loop in `bin/pndcgn` - iterate source_dirs array, compute prefixes for multi-dir
- [x] T030 [US1] Implement graceful degradation (FR-010) in `bin/pndcgn` - continue processing if one directory fails, log WARN for failed dir
- [x] T031 [US1] Integrate prefix generation in `bin/pndcgn` - call `pndcgn_generate_prefixed_filename()` for output naming
- [x] T032 [US1] Update run creation in `bin/pndcgn` - pass source_dirs JSON to `pndcgn_db_create_run()`
- [x] T066 [US1] Implement SIGINT/SIGTERM trap handler in `bin/pndcgn` - complete current file conversion, log summary of completed work, exit cleanly (FR-019)
- [x] T067 [P] [US1] Write BDD test for Ctrl+C graceful handling in `tests/integration/multi_dir_spec.sh` - Given multi-dir run in progress, When SIGINT sent, Then current file completes, summary logged, exit 130

**Checkpoint**: User Story 1 complete - fzf multi-select works with abbreviated prefixes

---

## 7. Phase 4: User Story 2 - Configure Maximum Selection Limit (Priority: P2)

**Goal**: Allow power users to configure max directories via pndcgn.toml [source] section

**Independent Test**: Set `max_source_dirs = 5` in config, launch fzf, verify 6th selection prevented

### 7.1. Tests for User Story 2

- [x] T033 [P] [US2] Write BDD test for config limit in `tests/utilities/config_spec.sh` - Given max=5 configured, When fzf launched, Then --multi=5 used
- [x] T034 [P] [US2] Write BDD test for default limit in `tests/utilities/config_spec.sh` - Given no config, Then default 4 applies
- [x] T035 [P] [US2] Write BDD test for over-max warning in `tests/utilities/config_spec.sh` - Given max=20, Then capped at 16 with WARN

### 7.2. Implementation for User Story 2

- [x] T036 [US2] Read config in `bin/pndcgn` - call `pndcgn_parse_toml_max_source_dirs()` at startup
- [x] T037 [US2] Pass limit to fzf in `pndcgn_select_source_dirs()` - use $max_dirs from config
- [x] T038 [US2] Add warning logging in `pndcgn_parse_toml_max_source_dirs()` - WARN when value capped or invalid

**Checkpoint**: User Story 2 complete - configurable limits work

---

## 8. Phase 5: User Story 3 - Backward Compatibility (Priority: P3)

**Goal**: Ensure single-directory selection continues working exactly as before

**Independent Test**: Select one directory via fzf (Enter without Tab), verify no prefix added to filenames

### 8.1. Tests for User Story 3

- [x] T039 [P] [US3] Write BDD test for single-select behavior in `tests/utilities/fzf_spec.sh` - Given single dir selected, Then no prefix in output
- [x] T040 [P] [US3] Write BDD test for CLI single arg in `tests/pndcgn_spec.sh` - Given `pndcgn ./docs ./output`, Then fzf not invoked
- [x] T041 [P] [US3] Write regression test in `tests/integration/multi_dir_spec.sh` - Given single dir, Then identical to pre-feature behavior

### 8.2. Implementation for User Story 3

- [x] T042 [US3] Add single-dir check in `bin/pndcgn` - if source_dirs.length == 1, skip prefix computation
- [x] T043 [US3] Ensure empty prefix in `pndcgn_generate_prefixed_filename()` - when prefix empty, output original name only
- [x] T044 [US3] Verify FR-013 in `bin/pndcgn` - no source prefix when single directory processed

**Checkpoint**: User Story 3 complete - backward compatibility verified

---

## 9. Phase 6: User Story 4 - CLI Multi-Directory Support (Priority: P2)

**Goal**: Enable scripting/automation by accepting multiple source directories as positional CLI arguments

**Independent Test**: Run `pndcgn dir1 dir2 dir3 target/` and verify all three processed

### 9.1. Tests for User Story 4

- [x] T045 [P] [US4] Write BDD test for multi-arg CLI in `tests/pndcgn_spec.sh` - Given 3 source args, When run, Then all processed
- [x] T046 [P] [US4] Write BDD test for limit exceeded in `tests/pndcgn_spec.sh` - Given 5 args with max=4, Then exit 2 with error
- [x] T047 [P] [US4] Write BDD test for CLI prefix in `tests/pndcgn_spec.sh` - Given CLI multi-dir, Then abbreviated prefixes used

### 9.2. Implementation for User Story 4

- [x] T048 [US4] Refactor argument parsing in `bin/pndcgn` - collect positional args into array
- [x] T049 [US4] Implement explicit target directory parsing in `bin/pndcgn` - support `-o`/`--output` flag OR `--` separator to disambiguate target (per FR-014, spec.md L168)
- [x] T050 [US4] Add count validation in `bin/pndcgn` - call `pndcgn_validate_source_count()`, exit 2 if exceeded
- [x] T051 [US4] Implement `pndcgn_validate_source_count()` in `src/utilities.sh` - compare count vs limit, emit error

**Checkpoint**: User Story 4 complete - CLI automation works

---

## 10. Phase 7: Derived Feature - fzf Fallback (FR-016)

**Goal**: Provide numbered list prompt when fzf is unavailable

**Independent Test**: Unset fzf from PATH, run pndcgn, verify numbered list appears

**Note**: This is derived from FR-016, not a user story in spec.md. Implementing as a separate phase for clarity.

### 10.1. Tests for fzf Fallback

- [x] T052 [P] Write BDD test for fallback detection in `tests/utilities/fallback_spec.sh` - Given fzf unavailable, Then fallback invoked
- [x] T053 [P] Write BDD test for numbered list in `tests/utilities/fallback_spec.sh` - Given fallback, When "1,3" entered, Then dirs 1 and 3 selected
- [x] T054 [P] Write BDD test for fallback limit in `tests/utilities/fallback_spec.sh` - Given max=2, When "1,2,3" entered, Then first 2 used with WARN

### 10.2. Implementation for fzf Fallback

- [x] T055 Implement `pndcgn_select_source_dirs_fallback()` in `src/utilities.sh` - numbered list prompt
- [x] T056 Add fzf detection in `pndcgn_select_source_dirs()` - if ! command -v fzf, call fallback
- [x] T057 Add INFO log in `pndcgn_select_source_dirs()` - "fzf not available, using numbered list selection"

**Checkpoint**: fzf Fallback complete - graceful degradation works

---

## 11. Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T058 [P] Update `--help` output in `bin/pndcgn` - document multi-directory syntax
- [x] T059 [P] Add progress output in `bin/pndcgn` - "Processing N directories: [1/N] ./dir (X files)"
- [x] T060 [P] Update README.md with multi-directory usage examples
- [x] T061 [P] Update `docs/040-user-guide.md` with multi-directory usage per constitution §III
- [ ] T062 Run full test suite - verify all 50%+ coverage maintained
- [ ] T063 Run ShellCheck on all modified files - ensure no warnings
- [ ] T064 Verify quickstart.md scenarios work end-to-end
- [ ] T068 [P] Write BDD test for SC-004 performance in `tests/integration/multi_dir_spec.sh` - Given N=4 directories, When processed, Then completion time ≤N×single + 10% overhead
- [ ] T065 [P] Add performance validation for SC-004 - verify N-directory run (N=4) completes in ≤N×single + 10% overhead using `time` command

---

## 12. Dependencies & Execution Order

### 12.1. Phase Dependencies

- **Documentation (Phase 0)**: No dependencies - MUST complete first per constitution §III
- **Setup (Phase 1)**: Can start in parallel with Documentation (no blocking dependency)
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (P1): Core feature - MVP
  - US2 (P2): Configuration - enhances US1
  - US3 (P3): Backward compat - ensures no regression
  - US4 (P2): CLI automation - enables scripting
- **fzf Fallback (Phase 7)**: Depends on Foundational - derived from FR-016
- **Polish (Phase 8)**: Depends on all features being complete

### 12.2. User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational - Integrates with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational - Verifies backward compat
- **User Story 4 (P2)**: Can start after Foundational - CLI alternative to fzf
- **fzf Fallback (derived)**: Can start after Foundational - Fallback for fzf

### 12.3. Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Foundation functions before integration
- Core implementation before edge cases
- Story complete before moving to next priority

### 12.4. Parallel Opportunities

- All Documentation tasks T001-T003 can run in parallel
- All Setup tasks T006-T009 can run in parallel
- All Foundational tests (T011, T013, T015, T017, T019) can run in parallel
- Once Foundational completes, all user stories can start in parallel
- All tests within a story marked [P] can run in parallel
- Polish tasks T058-T061, T065 can run in parallel

---

## 13. Parallel Example: Documentation Phase

```bash
# Launch all documentation tasks together:
Task: "T001 Update docs/020-requirements.md"
Task: "T002 Update docs/070-api-reference.md"
Task: "T003 Update docs/100-system-test-plan.md"
```

---

## 14. Parallel Example: Foundational Phase

```bash
# Launch all foundation tests together:
Task: "T011 Write unit tests for pndcgn_parse_toml_max_source_dirs()"
Task: "T013 Write unit tests for pndcgn_compute_abbreviated_prefixes()"
Task: "T015 Write unit tests for pndcgn_generate_prefixed_filename()"
Task: "T017 Write unit tests for pndcgn_remove_overlapping_dirs()"
Task: "T019 Write migration test"
```

---

## 15. Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together:
Task: "T021 Write BDD test for fzf multi-select"
Task: "T022 Write BDD test for processing multiple dirs"
Task: "T023 Write BDD test for abbreviated prefixes"
Task: "T024 Write BDD test for single run ID"
Task: "T025 Write BDD test for dynamic header count (FR-009)"
```

---

## 16. Implementation Strategy

### 16.1. MVP First (User Story 1 Only)

1. Complete Phase 0: Documentation (T001-T004) - CONSTITUTION REQUIRED
2. Complete Phase 1: Setup (T005-T009)
3. Complete Phase 2: Foundational (T010-T020) - CRITICAL
4. Complete Phase 3: User Story 1 (T021-T032)
5. **STOP and VALIDATE**: Test US1 independently with fzf
6. Deploy/demo if ready - core multi-select works!

### 16.2. Incremental Delivery

1. Documentation → Constitution compliance
2. Setup + Foundational → Foundation ready
3. Add User Story 1 → Test independently → **MVP Complete!**
4. Add User Story 2 → Test independently → Configurable limits
5. Add User Story 3 → Test independently → Backward compat verified
6. Add User Story 4 → Test independently → CLI automation ready
7. Add fzf Fallback → Test independently → Graceful degradation works
8. Polish → User guide, performance validation

### 16.3. Suggested MVP Scope

**Just User Story 1** - This delivers:
- fzf multi-select with Tab key
- Abbreviated unique prefixes
- Single run ID for all directories
- Deduplication and overlap detection
- Graceful degradation for directory failures (FR-010)
- Dynamic header count display (FR-009)

Users can immediately start using multi-directory selection. Configuration (US2), backward compat verification (US3), CLI automation (US4), and fzf fallback can follow incrementally.

---

## 17. Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD per constitution)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All functions use `pndcgn_` prefix per constitution

---
