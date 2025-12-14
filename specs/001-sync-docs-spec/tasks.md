# Tasks: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Input**: Design documents from `/specs/001-sync-docs-spec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are organized by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3])
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project directory structure per plan.md (bin/, src/, tests/, lib/)
- [ ] T002 [P] Create src/constants.sh with ANSI codes and shared constants
- [ ] T003 [P] Create tests/spec_helper.sh with ShellSpec test framework setup
- [ ] T004 [P] Create bin/pndcgn entrypoint script with basic structure and help command
- [ ] T005 [P] Configure ShellCheck linting rules and validation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Create src/utilities.sh module with helper functions (path resolution, logging)
- [ ] T007 [P] Implement pndcgn_install_ulid() function in src/utilities.sh for sqlite-ulid extension download
- [ ] T008 [P] Implement Bash-based ULID fallback function pndcgn_generate_ulid_fallback() in src/utilities.sh
- [ ] T009 Create src/database.sh module with SQLite initialization and extension loading
- [ ] T010 Implement database schema creation in src/database.sh (runs table with DEFAULT (ulid()), generated_artifacts table)
- [ ] T011 Implement WAL mode configuration and database connection management in src/database.sh
- [ ] T012 Implement prerequisite validation function pndcgn_check_prerequisites() in src/utilities.sh (pandoc, sqlite3, curl)
- [ ] T013 Create XDG-compliant state directory structure for database location

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Generate documentation outputs for a project (Priority: P1) 🎯 MVP

**Goal**: Core user value—turning a project's documentation sources into an organized output set

**Independent Test**: Run the tool against a small fixture project and confirm the expected output directory and index are produced

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T014a [P] [US1] Write ShellSpec test for argument parsing (SOURCE_DIR, TARGET_DIR, --type) in tests/pndcgn_spec.sh
- [ ] T014b [P] [US1] Write ShellSpec test for fzf integration fallback behavior in tests/pndcgn_spec.sh
- [ ] T014c [P] [US1] Write ShellSpec test for .pndcgnignore discovery and auto-creation in tests/config_spec.sh
- [ ] T014d [P] [US1] Write ShellSpec test for .gitignore stacking and seeding logic in tests/config_spec.sh
- [ ] T014e [P] [US1] Write ShellSpec test for file discovery respecting .pndcgnignore patterns in tests/processing_spec.sh
- [ ] T014f [P] [US1] Write ShellSpec test for fingerprint computation (format validation) in tests/processing_spec.sh
- [ ] T014g [P] [US1] Write ShellSpec test for run creation with ULID generation in tests/database_spec.sh
- [ ] T014h [P] [US1] Write ShellSpec test for cache lookup function in tests/database_spec.sh
- [ ] T014i [P] [US1] Write ShellSpec test for pandoc conversion function in tests/processing_spec.sh
- [ ] T014j [P] [US1] Write ShellSpec test for Dewey Decimal naming scheme in tests/processing_spec.sh
- [ ] T014k [P] [US1] Write ShellSpec test for run output directory creation in tests/processing_spec.sh
- [ ] T014l [P] [US1] Write ShellSpec test for run index generation (_index.md format) in tests/processing_spec.sh
- [ ] T014m [P] [US1] Write ShellSpec test for output_fingerprint computation (format: {total_size}:{artifact_count}:{sha256_of_all_content}) in tests/processing_spec.sh
- [ ] T014n [P] [US1] Write ShellSpec test for progress reporting format in tests/pndcgn_spec.sh
- [ ] T014o [US1] Write ShellSpec integration test for end-to-end generation workflow in tests/pndcgn_spec.sh
- [ ] T014p [US1] Write ShellSpec test for error handling (exit codes, stderr messages) in tests/pndcgn_spec.sh

### Implementation for User Story 1

- [ ] T014 [US1] Implement argument parsing in bin/pndcgn (SOURCE_DIR, TARGET_DIR, --type)
- [ ] T015 [US1] Implement optional fzf integration for SOURCE_DIR selection in bin/pndcgn (if fzf available)
- [ ] T016 [US1] Implement .pndcgnignore discovery and auto-creation logic in src/utilities.sh
- [ ] T017 [US1] Implement .gitignore stacking and seeding logic for .pndcgnignore in src/utilities.sh
- [ ] T018 [US1] Implement file discovery function respecting .pndcgnignore patterns in src/processing.sh
- [ ] T019 [US1] Implement fingerprint computation function pndcgn_compute_fingerprint() in src/processing.sh (format: {size}:{mtime}:{sha256_first_64KB})
- [ ] T020 [US1] Implement run creation function pndcgn_db_create_run() in src/database.sh (with ULID generation)
- [ ] T021 [US1] Implement cache lookup function pndcgn_db_check_cache() in src/database.sh
- [ ] T022 [US1] Implement pandoc conversion function pndcgn_convert_file() in src/processing.sh
- [ ] T022a [US1] Implement output_fingerprint computation function pndcgn_compute_output_fingerprint() in src/processing.sh (format: {total_size}:{artifact_count}:{sha256_of_all_content}, sorted by artifact path)
- [ ] T023 [US1] Implement Dewey Decimal naming scheme for output files in src/processing.sh
- [ ] T024 [US1] Implement run output directory creation (${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/) in src/processing.sh
- [ ] T025 [US1] Implement run index generation (_index.md with navigation links and statistics) in src/processing.sh
- [ ] T026 [US1] Implement progress reporting to stdout (counts, timing, cache efficiency) in bin/pndcgn
- [ ] T027 [US1] Implement main processing loop in bin/pndcgn (discover files, check cache, convert, update database)
- [ ] T028 [US1] Implement error handling with explicit messages to stderr and appropriate exit codes in bin/pndcgn

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Preview a run and finalize safely (Priority: P2)

**Goal**: Dry-run/finalize reduces risk for large repos and supports cautious workflows

**Independent Test**: Perform a dry-run, record the run identifier, change nothing, then finalize and verify outputs are produced

### Tests for User Story 2 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T029a [P] [US2] Write ShellSpec test for --dry-run flag (no output artifacts, run ID printed) in tests/pndcgn_spec.sh
- [ ] T029b [P] [US2] Write ShellSpec test for run fingerprint computation (combined fingerprint format) in tests/processing_spec.sh
- [ ] T029c [P] [US2] Write ShellSpec test for run fingerprint storage during dry-run in tests/database_spec.sh
- [ ] T029d [P] [US2] Write ShellSpec test for --finalize <RUN_ID> flag handling in tests/pndcgn_spec.sh
- [ ] T029e [P] [US2] Write ShellSpec test for fingerprint validation function in tests/processing_spec.sh
- [ ] T029f [P] [US2] Write ShellSpec test for finalize validation logic (fingerprint mismatch detection) in tests/pndcgn_spec.sh
- [ ] T029g [P] [US2] Write ShellSpec test for error handling on fingerprint mismatch (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [ ] T029h [US2] Write ShellSpec integration test for dry-run → finalize workflow in tests/pndcgn_spec.sh

### Implementation for User Story 2

- [ ] T029 [US2] Implement --dry-run flag handling in bin/pndcgn (no output artifacts, print run ID)
- [ ] T030 [US2] Implement run fingerprint computation (combined fingerprint of all input files + config state) in src/processing.sh
- [ ] T031 [US2] Implement run fingerprint storage in database during dry-run in src/database.sh
- [ ] T032 [US2] Implement --finalize <RUN_ID> flag handling in bin/pndcgn
- [ ] T033 [US2] Implement fingerprint validation function pndcgn_validate_fingerprint() in src/processing.sh
- [ ] T034 [US2] Implement finalize validation logic (compare current fingerprint vs stored) in bin/pndcgn
- [ ] T035 [US2] Implement error handling for fingerprint mismatch during finalize (exit code 1, actionable explanation) in bin/pndcgn
- [ ] T036 [US2] Implement finalize execution (reuse dry-run plan, generate outputs) in bin/pndcgn

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Manage runs and understand results (Priority: P3)

**Goal**: Run management and reporting turn the tool from "one-off script" into something teams can trust and operate

**Independent Test**: Interrupt a run, resume it, and validate that already-generated outputs are not repeated

### Tests for User Story 3 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T037a [P] [US3] Write ShellSpec test for run status tracking (running, complete, failed, interrupted) in tests/database_spec.sh
- [ ] T037b [P] [US3] Write ShellSpec test for --resume <RUN_ID> flag handling in tests/pndcgn_spec.sh
- [ ] T037c [P] [US3] Write ShellSpec test for resume logic (skip already-processed files) in tests/pndcgn_spec.sh
- [ ] T037d [P] [US3] Write ShellSpec test for fingerprint validation before resume in tests/pndcgn_spec.sh
- [ ] T037e [P] [US3] Write ShellSpec test for --clean <RUN_ID> [RUN_ID...] flag with confirmation in tests/pndcgn_spec.sh
- [ ] T037f [P] [US3] Write ShellSpec test for cleanup validation (fingerprint check, non-pndcgn artifact warning) in tests/pndcgn_spec.sh
- [ ] T037g [P] [US3] Write ShellSpec test for run output directory deletion in tests/utilities_spec.sh
- [ ] T037h [P] [US3] Write ShellSpec test for --drop flag with confirmation in tests/pndcgn_spec.sh
- [ ] T037i [P] [US3] Write ShellSpec test for database cleanup and cache clearing in tests/database_spec.sh
- [ ] T037j [P] [US3] Write ShellSpec test for run statistics query functions in tests/database_spec.sh
- [ ] T037k [P] [US3] Write ShellSpec test for statistics display in run index (_index.md) in tests/processing_spec.sh
- [ ] T037l [US3] Write ShellSpec integration test for resume interrupted run workflow in tests/pndcgn_spec.sh

### Implementation for User Story 3

- [ ] T037 [US3] Implement run status tracking (running, complete, failed, interrupted) in src/database.sh
- [ ] T038 [US3] Implement --resume <RUN_ID> flag handling in bin/pndcgn
- [ ] T039 [US3] Implement resume logic (load run state, skip already-processed files) in bin/pndcgn
- [ ] T040 [US3] Implement fingerprint validation before resume in bin/pndcgn
- [ ] T041 [US3] Implement --clean <RUN_ID> [RUN_ID...] flag handling with confirmation in bin/pndcgn
- [ ] T042 [US3] Implement cleanup validation (fingerprint check, non-pndcgn artifact warning) in bin/pndcgn
- [ ] T043 [US3] Implement run output directory deletion in src/utilities.sh
- [ ] T044 [US3] Implement --drop flag handling with confirmation in bin/pndcgn
- [ ] T045 [US3] Implement database cleanup and cache clearing in src/database.sh
- [ ] T046 [US3] Implement run statistics query functions in src/database.sh (counts, timing, cache efficiency)
- [ ] T047 [US3] Implement statistics display in run index (_index.md) in src/processing.sh
- [ ] T048 [US3] Implement database query interface for programmatic statistics access in src/database.sh

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

### Tests for Polish Phase ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T049a [P] Write ShellSpec test for TOML config file discovery (XDG config hierarchy) in tests/config_spec.sh
- [ ] T049b [P] Write ShellSpec test for TOML config file parsing in tests/config_spec.sh
- [ ] T049c [P] Write ShellSpec test for --reseed flag handling (.pndcgnignore re-seeding) in tests/pndcgn_spec.sh
- [ ] T049d [P] Write ShellSpec test for --force flag handling (bypass cache) in tests/pndcgn_spec.sh
- [ ] T049e [P] Write ShellSpec test for edge case: source directory unreadable (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [ ] T049f [P] Write ShellSpec test for edge case: target directory unwritable (exit code 1, actionable message) in tests/pndcgn_spec.sh
- [ ] T049g [P] Write ShellSpec test for edge case: unsupported output type (exit code 2, list supported types) in tests/pndcgn_spec.sh
- [ ] T049h [P] Write ShellSpec test for edge case: cached outputs missing (regenerate, log warning) in tests/database_spec.sh
- [ ] T049i [P] Write ShellSpec test for edge case: fzf unavailable (silent fallback to CWD) in tests/pndcgn_spec.sh
- [ ] T049j [P] Write ShellSpec test for edge case: sqlite-ulid extension download failure (Bash fallback, continue operation) in tests/utilities_spec.sh

### Implementation for Polish Phase

- [ ] T049 [P] Implement comprehensive error handling for all edge cases (source unreadable, target unwritable, unsupported output type, cached outputs missing, fzf unavailable, extension download failure) in bin/pndcgn
- [ ] T050 [P] Implement concurrent run support validation (SQLite WAL mode, unique run IDs) in src/database.sh
- [ ] T051 [P] Implement TOML config file discovery and parsing (XDG config hierarchy) in src/utilities.sh
- [ ] T052 [P] Implement --reseed flag handling for .pndcgnignore re-seeding in bin/pndcgn
- [ ] T053 [P] Implement --force flag handling (bypass cache) in bin/pndcgn
- [ ] T054 [P] Implement output type validation against pandoc's supported formats in src/utilities.sh
- [ ] T055 [P] Update all user-facing text to consistently use "pndcgn" product name
- [ ] T056 [P] Implement trap handlers for cleanup on EXIT INT TERM signals in bin/pndcgn
- [ ] T057 [P] Add comprehensive logging with pndcgn_log_info() and pndcgn_log_error() functions in src/utilities.sh
- [ ] T058 [P] Validate quickstart.md acceptance checks
- [ ] T059 [P] Run ShellCheck validation and fix all warnings
- [ ] T060 [P] Update documentation (user guide, API reference) to reflect implementation
- [ ] T061 [P] Implement code coverage measurement and enforce 90% threshold (integrate ShellSpec coverage reporting, add CI gate)

---

## Phase 7: Success Criteria Validation

**Purpose**: Validate that the implementation meets all measurable success criteria from spec.md

### Success Criteria Validation Tasks

- [ ] T062 [P] Implement performance benchmark test for SC-001 (validate repeat run completes ≥5× faster than initial run, report skipped vs processed) in tests/performance_spec.sh
- [ ] T063 [P] Implement finalize success rate validation for SC-002 (validate 100% of dry-run finalizations with unchanged inputs succeed and produce matching outputs) in tests/pndcgn_spec.sh
- [ ] T064 [P] Implement finalize failure validation for SC-003 (validate 100% of dry-run finalizations with changed inputs fail safely with actionable explanation) in tests/pndcgn_spec.sh
- [ ] T065 [P] Implement usability test scenario for SC-004 (validate ≥90% of test users can locate and open specific document using run index in <60 seconds) in tests/usability_spec.sh

**Note**: SC-004 (usability testing) may require manual testing with real users or automated simulation. T065 provides the test framework; actual validation may need separate user testing session.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete
- **Success Criteria Validation (Phase 7)**: Depends on Polish phase completion - validates implementation meets spec requirements

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 run creation and fingerprinting
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Depends on US1 run management and US2 fingerprint validation

### Within Each User Story

- **Tests FIRST** (write failing tests before any implementation)
- Models/data structures before services
- Services before main controller logic
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002-T005)
- Foundational tasks T007-T008 can run in parallel (different functions)
- Foundational tasks T009-T013 can run in parallel (different modules)
- Once Foundational phase completes, US1 and US2 can start in parallel (US2 needs US1's fingerprinting)
- Polish phase test tasks (T049a-T049j) can all run in parallel
- Polish phase implementation tasks marked [P] can all run in parallel
- Success criteria validation tasks (T062-T065) can all run in parallel

---

## Parallel Example: User Story 1

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

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core generation)
   - Developer B: User Story 2 (dry-run/finalize) - can start after US1 fingerprinting
   - Developer C: User Story 3 (run management) - can start after US1 run creation
3. Stories complete and integrate independently

---

## Notes

- **Test-First Development**: All test tasks (T014a-T014p, T029a-T029h, T037a-T037l, T049a-T049j) MUST be written and FAIL before corresponding implementation tasks begin (Constitution §II)
- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- All functions must use pndcgn_ prefix for namespacing
- All variables must use pndcgn_ or PNDCGN_ prefix
- Strict mode: `set -euo pipefail` in all scripts
- Code coverage target: 90% minimum (enforced by T061)
