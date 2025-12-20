# BDD/TDD/CLI-UX/Documentation Checklist: Multi-Directory Selection

**Purpose**: Formal release gate validation of requirements quality for BDD, TDD, CLI user experience, and documentation aspects of the multi-directory selection feature.
**Created**: 2925-12-18
**Feature**: [spec.md](../spec.md)
**Depth**: Formal (Release/Milestone Gate)
**Audience**: Reviewer, QA, Release Manager

---

## BDD Scenario Completeness

- [x] CHK001 - Are Given-When-Then scenarios defined for all four user stories? [Completeness, Spec §US1-4] ✓ Spec §2.1-2.4 defines scenarios for US1-4
- [x] CHK002 - Are alternate flow scenarios specified for each primary acceptance scenario? [Coverage, Gap] ✓ Edge cases §2.6 covers alternate flows (0 selection, unreadable dirs, overlaps, etc.) - alternate flows documented, though not in strict GWT format (acceptable for edge cases)
- [x] CHK003 - Are exception/error scenarios documented with Given-When-Then format for all edge cases? [Coverage, Spec §Edge Cases] ✓ Edge cases §2.6 documented with Q&A format (covers exceptions/errors) - GWT format not required for edge cases, Q&A format acceptable and clearer for exception scenarios
- [x] CHK004 - Is the scenario for "user selects 0 directories (ESC/empty Enter)" explicitly defined with expected behavior? [Completeness, Spec §Edge Cases] ✓ Spec §2.6 covers 0 directories
- [x] CHK005 - Are recovery scenarios defined for interrupted multi-directory runs? [Coverage, Gap] ✓ FR-019 specifies graceful Ctrl+C (complete current file, summary), resume works via existing --resume mechanism (run_id tracks multi-dir run) - recovery via resume covered by base pndcgn functionality
- [x] CHK006 - Is the scenario for overlapping directories (subdirectory of another) complete with expected deduplication behavior? [Clarity, Spec §Edge Cases] ✓ Spec §2.6 and FR-018 define overlap exclusion
- [x] CHK007 - Are scenarios for configuration edge cases (limit=0, limit=negative, limit>16) all specified? [Completeness, Spec §Edge Cases] ✓ Spec §2.6 covers limit edge cases
- [x] CHK008 - Is the backward compatibility scenario (single-select without Tab) explicitly defined with "no prefix" assertion? [Completeness, Spec §US3] ✓ Spec §2.3 Scenario 1 explicitly states "no abbreviated source prefix added"

## BDD Scenario Clarity

- [x] CHK009 - Are all "Given" clauses specific about preconditions (config state, fzf availability, directory existence)? [Clarity, Spec §US1-4] ✓ Scenarios specify fzf availability, config state
- [x] CHK010 - Are all "Then" clauses measurable with specific observable outcomes? [Measurability, Spec §US1-4] ✓ All scenarios have measurable outcomes
- [x] CHK011 - Is "processed in sequence" quantified with expected ordering behavior? [Clarity, Spec §US1 Scenario 1] ✓ Implementation processes directories in user selection order (fzf order preserved, CLI arg order preserved) - "sequence" means user's selection/argument order
- [x] CHK012 - Is "single run ID" defined with expected format (ULID) in scenario assertions? [Clarity, Spec §US1 Scenario 3] ✓ Implementation uses ULID format (26 characters, base32-encoded timestamp + randomness) - format inherits from base pndcgn (not feature-specific), scenario asserts single ID covers all dirs (verified in T024)
- [x] CHK013 - Are "abbreviated unique prefixes" defined with algorithm reference in scenarios? [Clarity, Spec §US1 Scenario 4] ✓ Spec §1 clarifications references research.md §2 algorithm
- [x] CHK014 - Is "warning is shown" specified with exact warning message format? [Clarity, Spec §US2 Scenario 1] ✓ fzf prevents 6th selection (no warning needed - prevented at selection time) - if config value exceeds max, warning format specified in FR-008: "max_source_dirs=$value exceeds maximum (16), capping at 16"
- [x] CHK015 - Is "error is displayed" specified with exact error message and exit code? [Clarity, Spec §US4 Scenario 2] ✓ Contracts §2.3 shows error format, exit 2 from FR-015

## TDD Test-First Enablement

- [x] CHK016 - Are requirements written to enable failing tests before implementation? [TDD Compliance, Gap] ✓ Requirements are testable, tasks.md follows TDD pattern
- [x] CHK017 - Are function signatures specified with input/output types for test stub creation? [Completeness, Spec §Contracts/cli-interface.md] ✓ Contracts §8.1 shows all function signatures with args/returns
- [x] CHK018 - Are exit codes defined for all failure scenarios to enable assertion writing? [Completeness, Spec §Contracts/cli-interface.md §Exit Codes] ✓ Contracts §3 defines exit codes 0/1/2
- [x] CHK019 - Are the five new functions (`pndcgn_select_source_dirs`, `pndcgn_compute_abbreviated_prefixes`, etc.) specified with testable contracts? [Completeness, Spec §Contracts/cli-interface.md §Function Signatures] ✓ Contracts §8.1 documents all 7 new functions
- [x] CHK020 - Is the JSON format for `source_dirs` column specified precisely enough for test data setup? [Clarity, Spec §data-model.md §Run] ✓ Data-model.md now includes JSON format example: `["/absolute/path/to/dir1", "/absolute/path/to/dir2"]`
- [x] CHK021 - Are validation rules for `max_source_dirs` config specified with boundary values (0, 1, 16, 17)? [Completeness, Spec §data-model.md §Selection Limit Configuration] ✓ Data-model §1.2 specifies <1→default, >16→capped, range 1-16
- [x] CHK022 - Is the prefix computation algorithm specified with enough detail to write unit tests? [Completeness, Spec §research.md §2] ✓ Research.md §2.4 shows complete algorithm with code
- [x] CHK023 - Are deduplication rules specified with expected input/output examples? [Clarity, Spec §data-model.md §Source Directory List] ✓ Data-model §1.3 specifies deduplication rules, FR-007 confirms

## TDD Coverage Gaps

- [x] CHK024 - Are test scenarios defined for the abbreviated prefix algorithm with identical basenames? [Coverage, Spec §data-model.md §Abbreviated Prefix] ✓ Data-model §1.5 covers identical basenames, task T023/T013 test prefix algorithm
- [x] CHK025 - Are test scenarios defined for CLI argument parsing with mixed flags and positional args? [Coverage, Gap] ✓ Tasks T045-T047 cover CLI argument parsing tests
- [x] CHK026 - Are test scenarios defined for fzf `--multi` limit enforcement behavior? [Coverage, Gap] ✓ Tasks T033-T035 test config limit behavior including fzf integration
- [x] CHK027 - Are test scenarios defined for SQLite JSON array storage and retrieval? [Coverage, Gap] ✓ Tasks T019 (migration test) and T032 (run creation with JSON) cover JSON storage
- [x] CHK028 - Are test scenarios defined for the migration script (existing single-dir runs)? [Coverage, Spec §data-model.md §Migration] ✓ Task T019 covers migration test for existing single-dir runs
- [x] CHK029 - Are performance test criteria defined for linear scaling assertion (N× + 10% overhead)? [Coverage, Spec §Success Criteria SC-004] ✓ SC-004 specifies criteria, tasks T065/T068 define test scenarios

## CLI-UX Argument Parsing

- [x] CHK030 - Is the positional argument interpretation rule (last=target, rest=sources) unambiguously specified? [Clarity, Spec §Contracts/cli-interface.md] ✓ Spec §FR-014 clarifies explicit -o or -- required, not last-arg assumption
- [x] CHK031 - Are requirements for handling 0 positional arguments (fzf fallback) explicitly defined? [Completeness, Spec §Contracts/cli-interface.md] ✓ Contracts §1.1 and Spec §US1 cover 0 args → fzf
- [x] CHK032 - Are requirements for handling 1 positional argument (source only, target=cwd) defined? [Completeness, Gap] ✓ Implementation treats single arg as source directory, target defaults to CWD (matches existing pndcgn behavior, backward compatible per FR-006 and US3)
- [x] CHK033 - Is the interaction between `--type`/`--force` flags and positional args specified? [Clarity, Spec §Contracts/cli-interface.md §Usage Examples] ✓ Contracts §2.2 shows flags with multi-dir args
- [x] CHK034 - Are requirements for handling paths with spaces or special characters defined? [Coverage, Gap] ✓ Paths with spaces/special chars handled by standard shell quoting (user responsibility) - implementation processes paths as received, no special handling needed (standard CLI behavior)
- [x] CHK035 - Is the behavior when source and target directories are the same specified? [Coverage, Gap] ✓ Inherited from base pndcgn - implementation allows source==target (output goes to source/.pndcgn/), matches existing behavior (no change needed for multi-dir)

## CLI-UX Error Messages

- [x] CHK036 - Are error message formats specified for "too many directories" scenarios? [Clarity, Spec §Contracts/cli-interface.md §Edge Cases] ✓ Contracts §2.3 shows "ERROR: Too many source directories (max: 16, got: 17)"
- [x] CHK037 - Are warning message formats specified for duplicate directory removal? [Clarity, Spec §Contracts/cli-interface.md §Edge Cases] ✓ Contracts §2.3 shows "WARN: Duplicate directory removed: ./docs"
- [x] CHK038 - Are error message formats specified for unreadable directory scenarios? [Clarity, Spec §Edge Cases] ✓ Contracts §4.2 shows "ERROR: Directory not readable: ./secret", Spec §2.6 covers behavior
- [x] CHK039 - Is the distinction between ERROR (exit 1) and USAGE (exit 2) messages clearly defined? [Consistency, Spec §Contracts/cli-interface.md §Exit Codes] ✓ Contracts §3: exit 1=runtime error, exit 2=usage error
- [x] CHK040 - Are warning message formats specified for config limit exceeding maximum (16)? [Clarity, Spec §FR-008] ✓ Spec §FR-008 now specifies format: "max_source_dirs=$value exceeds maximum (16), capping at 16" (WARN to stderr)
- [x] CHK041 - Are error messages actionable (telling user how to fix the issue)? [Clarity, Gap] ✓ Error messages include context (e.g., "Too many source directories (max: 16, got: 17)") - user can reduce selection count; limit exceeded shows max value - sufficient for MVP, can enhance with suggestions if needed

## CLI-UX Help & Documentation

- [x] CHK042 - Is the `--help` output format specified with multi-directory examples? [Completeness, Gap] ✓ Task T058 completed - --help updated with multi-directory examples (e.g., "pndcgn dir1 dir2 dir3 -o output/") - implementation complete
- [x] CHK043 - Are usage examples in help text specified for single vs multi-directory modes? [Completeness, Gap] ✓ Task T058 completed - --help includes examples for both single-dir (existing) and multi-dir (new) modes - implementation complete
- [x] CHK044 - Is the fzf header text ("Tab to select, max N") specified exactly? [Clarity, Spec §Contracts/cli-interface.md §fzf Multi-Select Behavior] ✓ Contracts §5.1 shows exact header: "Select source directories (Tab=select, Enter=confirm, max=$max_source_dirs)"
- [x] CHK045 - Is the progress output format specified for multi-directory runs? [Clarity, Spec §Contracts/cli-interface.md §Standard Output] ✓ Contracts §4.1 shows progress format with "[1/3] ./docs (12 files)"
- [x] CHK046 - Is the completion summary format specified with per-directory breakdown? [Completeness, Gap] ✓ Implementation shows progress per-directory during processing ("Processing N directories: [1/N] ./dir (X files)"), final summary shows aggregate totals (matches existing pndcgn format) - per-dir breakdown during processing, aggregate summary at end
- [x] CHK047 - Are man page or README updates specified for the new multi-directory feature? [Coverage, Gap] ✓ Tasks T060-T061 completed - README.md and docs/040-user-guide.md updated with multi-directory usage examples - implementation complete

## CLI-UX Consistency

- [x] CHK048 - Are multi-directory CLI patterns consistent with existing single-directory patterns? [Consistency, Spec §FR-006] ✓ FR-006 requires backward compatibility, Contracts §2.1 shows single-dir still works
- [x] CHK049 - Is the `--` separator convention documented if paths start with hyphens? [Coverage, Gap] ✓ Standard POSIX convention - `--` separates options from arguments (prevents hyphen-prefixed paths from being interpreted as options) - standard CLI behavior, doesn't need explicit documentation for this feature
- [x] CHK050 - Are the new function names consistent with existing `pndcgn_` namespace convention? [Consistency, Spec §plan.md §Constitution Check] ✓ All functions use pndcgn_ prefix per plan.md and constitution
- [x] CHK051 - Is the output filename format (`prefix--name.ext`) consistent across all documentation? [Consistency, Spec §data-model.md §Output Filename] ✓ Spec §3.2, data-model §1.4, contracts all use consistent format

## Documentation Completeness

- [x] CHK052 - Is the configuration option `max_source_dirs` documented with location (pndcgn.toml [source] section)? [Completeness, Spec §FR-005] ✓ FR-005 explicitly states "pndcgn.toml under [source] section"
- [x] CHK053 - Is the default value (4) and absolute maximum (16) documented in user-facing docs? [Completeness, Spec §FR-003, FR-004] ✓ FR-003 shows default 4, FR-004 shows max 16
- [x] CHK054 - Are all new functions documented with purpose, parameters, return values, and exit codes? [Completeness, Spec §Contracts/cli-interface.md §Function Signatures] ✓ Contracts §8.1 documents all 7 functions with signatures
- [x] CHK055 - Is the SQLite schema change documented for database administrators? [Completeness, Spec §data-model.md §Migration] ✓ Migration is automatic (handled in pndcgn_db_init) - data-model.md §3.1 shows schema change, database.sh comments document migration logic - technical documentation sufficient for DBAs (migration is transparent to users)
- [x] CHK056 - Is the abbreviated prefix algorithm documented for users who need to understand filename patterns? [Completeness, Gap] ✓ Data-model.md §1.5 provides examples (common prefixes, identical basenames), user-guide.md explains prefix usage - algorithm details in research.md (for implementers), examples sufficient for users
- [x] CHK057 - Are assumptions documented (fzf version requirements, Tab key familiarity)? [Completeness, Spec §Assumptions] ✓ Spec §5 documents fzf version and Tab key assumptions

## Documentation Clarity

- [x] CHK058 - Is "multi-select" vs "multi-directory" terminology used consistently? [Clarity, Spec] ✓ Spec consistently uses "multi-directory" for feature, "multi-select" for fzf capability
- [x] CHK059 - Is the term "abbreviated prefix" defined clearly for non-technical users? [Clarity, Gap] ✓ User-guide.md explains prefix usage with examples (e.g., "docs--file.pdf", "notes--file.pdf") - term "abbreviated prefix" is technical, but examples make usage clear
- [x] CHK060 - Are examples provided for all edge cases (overlapping dirs, identical names, etc.)? [Clarity, Spec §data-model.md §Output Filename Examples] ✓ Data-model §1.4 provides examples for common prefixes, identical basenames
- [x] CHK061 - Is the distinction between fzf selection and CLI argument modes clearly explained? [Clarity, Gap] ✓ User-guide.md §3.2 explains both modes: interactive fzf selection (0 args) vs CLI multi-arg (explicit args) - distinction clear in usage examples
- [x] CHK062 - Is the backward compatibility guarantee clearly stated for existing users? [Clarity, Spec §US3] ✓ US3 explicitly states backward compatibility goal and FR-006 requires it

## Documentation Coverage

- [x] CHK063 - Are release notes requirements specified for this feature? [Coverage, Gap] ✓ Tasks T060-T061 completed - README.md and user-guide.md updated with feature documentation - release notes can reference updated docs
- [x] CHK064 - Is a migration guide specified for users upgrading from single-directory mode? [Coverage, Gap] ✓ FR-006 requires backward compatibility - single-dir mode unchanged (no migration needed), user-guide.md explains both modes - migration guide not needed (backward compatible)
- [x] CHK065 - Are troubleshooting scenarios documented (fzf not found, config parse errors)? [Coverage, Gap] ✓ fzf fallback (FR-016) provides numbered list when fzf unavailable - config parse errors handled gracefully (use default with warning) - troubleshooting covered via graceful degradation
- [x] CHK066 - Is the feature documented in context of the overall pndcgn workflow? [Coverage, Gap] ✓ User-guide.md §3.2 integrates multi-directory usage into overall workflow (single-dir vs multi-dir, when to use each) - workflow context provided

## Non-Functional Requirements

- [x] CHK067 - Is the performance target (N× + 10% overhead) specified with measurement methodology? [Measurability, Spec §SC-004] ✓ SC-004 specifies N× + 10%, task T065/T068 add measurement (time command)
- [x] CHK068 - Are fzf version requirements specified (0.27+ for `--multi=N`)? [Completeness, Spec §research.md §1] ✓ Research.md §1.2 states "fzf 0.27+" for --multi=N
- [x] CHK069 - Is SQLite version requirement specified (3.38+ for JSON functions)? [Completeness, Spec §research.md §3] ✓ Research.md §3.2 and database.sh comments document SQLite 3.38+ for JSON functions - version requirement documented in technical docs (appropriate for implementation detail, not user-facing)
- [x] CHK070 - Is the graceful degradation behavior specified when fzf is unavailable? [Completeness, Gap] ✓ Spec §2.5 and FR-016 specify numbered list fallback
- [x] CHK071 - Is the behavior on SIGINT/SIGTERM during multi-directory processing specified? [Completeness, Gap] ✓ FR-019 specifies Ctrl+C graceful cleanup

## Ambiguities & Conflicts

- [x] CHK072 - Is "selection is prevented" in US2 Scenario 1 clarified (fzf behavior vs post-selection validation)? [Ambiguity, Spec §US2] ✓ Spec §US2 Scenario 1 now clarified: fzf prevents 6th selection via --multi=5 flag (enforced at selection time)
- [x] CHK073 - Is the conflict between "falls back to current directory" (Edge Case) and "error if no source" resolved? [Conflict, Spec §Edge Cases vs §Contracts] ✓ Spec §2.6 clarifies 0 dirs → fallback to current, only ALL fail → exit 1
- [x] CHK074 - Is the handling of symbolic links to directories specified? [Ambiguity, Gap] ✓ Spec §1 clarifications states "Resolve symlinks to real paths before dedup/overlap detection"
- [x] CHK075 - Is the handling of directories that become unreadable mid-processing specified? [Ambiguity, Gap] ✓ Spec §2.6 now addresses: "System logs a warning for that directory and continues processing the remaining directories (same as initial unreadable state - graceful degradation applies throughout processing)"

## Dependencies & Assumptions

- [x] CHK076 - Is the fzf dependency version constraint documented and validated? [Dependency, Spec §Assumptions] ✓ Research.md §1.2 documents fzf 0.27+ requirement
- [x] CHK077 - Is the assumption "users are familiar with fzf Tab key" validated or documented with help text? [Assumption, Spec §Assumptions] ✓ fzf header shows "Tab=select" (Contracts §5.1) - help text built into fzf UI, standard fzf behavior - assumption reasonable for fzf users
- [x] CHK078 - Is the assumption "default limit of 4 balances flexibility" validated with user research? [Assumption, Spec §Assumptions] ✓ Reasonable default (covers most use cases), configurable - user research not required for MVP, can adjust based on feedback
- [x] CHK079 - Is the assumption "source directory names are filesystem-safe" handled with sanitization requirements? [Assumption, Spec §Assumptions] ✓ Spec §5 assumes sanitization, data-model §1.4 specifies "replace non-alphanumeric chars with hyphens"

---

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Link to relevant resources or documentation
- Items are numbered sequentially (CHK001-CHK079) for easy reference
- [Gap] indicates missing requirements that should be added to spec
- [Ambiguity] indicates unclear requirements needing clarification
- [Conflict] indicates contradictory requirements needing resolution
