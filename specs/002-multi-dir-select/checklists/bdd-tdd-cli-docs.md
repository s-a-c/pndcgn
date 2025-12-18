# BDD/TDD/CLI-UX/Documentation Checklist: Multi-Directory Selection

**Purpose**: Formal release gate validation of requirements quality for BDD, TDD, CLI user experience, and documentation aspects of the multi-directory selection feature.
**Created**: 2925-12-18
**Feature**: [spec.md](../spec.md)
**Depth**: Formal (Release/Milestone Gate)
**Audience**: Reviewer, QA, Release Manager

---

## BDD Scenario Completeness

- [ ] CHK001 - Are Given-When-Then scenarios defined for all four user stories? [Completeness, Spec §US1-4]
- [ ] CHK002 - Are alternate flow scenarios specified for each primary acceptance scenario? [Coverage, Gap]
- [ ] CHK003 - Are exception/error scenarios documented with Given-When-Then format for all edge cases? [Coverage, Spec §Edge Cases]
- [ ] CHK004 - Is the scenario for "user selects 0 directories (ESC/empty Enter)" explicitly defined with expected behavior? [Completeness, Spec §Edge Cases]
- [ ] CHK005 - Are recovery scenarios defined for interrupted multi-directory runs? [Coverage, Gap]
- [ ] CHK006 - Is the scenario for overlapping directories (subdirectory of another) complete with expected deduplication behavior? [Clarity, Spec §Edge Cases]
- [ ] CHK007 - Are scenarios for configuration edge cases (limit=0, limit=negative, limit>16) all specified? [Completeness, Spec §Edge Cases]
- [ ] CHK008 - Is the backward compatibility scenario (single-select without Tab) explicitly defined with "no prefix" assertion? [Completeness, Spec §US3]

## BDD Scenario Clarity

- [ ] CHK009 - Are all "Given" clauses specific about preconditions (config state, fzf availability, directory existence)? [Clarity, Spec §US1-4]
- [ ] CHK010 - Are all "Then" clauses measurable with specific observable outcomes? [Measurability, Spec §US1-4]
- [ ] CHK011 - Is "processed in sequence" quantified with expected ordering behavior? [Clarity, Spec §US1 Scenario 1]
- [ ] CHK012 - Is "single run ID" defined with expected format (ULID) in scenario assertions? [Clarity, Spec §US1 Scenario 3]
- [ ] CHK013 - Are "abbreviated unique prefixes" defined with algorithm reference in scenarios? [Clarity, Spec §US1 Scenario 4]
- [ ] CHK014 - Is "warning is shown" specified with exact warning message format? [Clarity, Spec §US2 Scenario 1]
- [ ] CHK015 - Is "error is displayed" specified with exact error message and exit code? [Clarity, Spec §US4 Scenario 2]

## TDD Test-First Enablement

- [ ] CHK016 - Are requirements written to enable failing tests before implementation? [TDD Compliance, Gap]
- [ ] CHK017 - Are function signatures specified with input/output types for test stub creation? [Completeness, Spec §Contracts/cli-interface.md]
- [ ] CHK018 - Are exit codes defined for all failure scenarios to enable assertion writing? [Completeness, Spec §Contracts/cli-interface.md §Exit Codes]
- [ ] CHK019 - Are the five new functions (`pndcgn_select_source_dirs`, `pndcgn_compute_abbreviated_prefixes`, etc.) specified with testable contracts? [Completeness, Spec §Contracts/cli-interface.md §Function Signatures]
- [ ] CHK020 - Is the JSON format for `source_dirs` column specified precisely enough for test data setup? [Clarity, Spec §data-model.md §Run]
- [ ] CHK021 - Are validation rules for `max_source_dirs` config specified with boundary values (0, 1, 16, 17)? [Completeness, Spec §data-model.md §Selection Limit Configuration]
- [ ] CHK022 - Is the prefix computation algorithm specified with enough detail to write unit tests? [Completeness, Spec §research.md §2]
- [ ] CHK023 - Are deduplication rules specified with expected input/output examples? [Clarity, Spec §data-model.md §Source Directory List]

## TDD Coverage Gaps

- [ ] CHK024 - Are test scenarios defined for the abbreviated prefix algorithm with identical basenames? [Coverage, Spec §data-model.md §Abbreviated Prefix]
- [ ] CHK025 - Are test scenarios defined for CLI argument parsing with mixed flags and positional args? [Coverage, Gap]
- [ ] CHK026 - Are test scenarios defined for fzf `--multi` limit enforcement behavior? [Coverage, Gap]
- [ ] CHK027 - Are test scenarios defined for SQLite JSON array storage and retrieval? [Coverage, Gap]
- [ ] CHK028 - Are test scenarios defined for the migration script (existing single-dir runs)? [Coverage, Spec §data-model.md §Migration]
- [ ] CHK029 - Are performance test criteria defined for linear scaling assertion (N× + 10% overhead)? [Coverage, Spec §Success Criteria SC-004]

## CLI-UX Argument Parsing

- [ ] CHK030 - Is the positional argument interpretation rule (last=target, rest=sources) unambiguously specified? [Clarity, Spec §Contracts/cli-interface.md]
- [ ] CHK031 - Are requirements for handling 0 positional arguments (fzf fallback) explicitly defined? [Completeness, Spec §Contracts/cli-interface.md]
- [ ] CHK032 - Are requirements for handling 1 positional argument (source only, target=cwd) defined? [Completeness, Gap]
- [ ] CHK033 - Is the interaction between `--type`/`--force` flags and positional args specified? [Clarity, Spec §Contracts/cli-interface.md §Usage Examples]
- [ ] CHK034 - Are requirements for handling paths with spaces or special characters defined? [Coverage, Gap]
- [ ] CHK035 - Is the behavior when source and target directories are the same specified? [Coverage, Gap]

## CLI-UX Error Messages

- [ ] CHK036 - Are error message formats specified for "too many directories" scenarios? [Clarity, Spec §Contracts/cli-interface.md §Edge Cases]
- [ ] CHK037 - Are warning message formats specified for duplicate directory removal? [Clarity, Spec §Contracts/cli-interface.md §Edge Cases]
- [ ] CHK038 - Are error message formats specified for unreadable directory scenarios? [Clarity, Spec §Edge Cases]
- [ ] CHK039 - Is the distinction between ERROR (exit 1) and USAGE (exit 2) messages clearly defined? [Consistency, Spec §Contracts/cli-interface.md §Exit Codes]
- [ ] CHK040 - Are warning message formats specified for config limit exceeding maximum (16)? [Clarity, Spec §FR-008]
- [ ] CHK041 - Are error messages actionable (telling user how to fix the issue)? [Clarity, Gap]

## CLI-UX Help & Documentation

- [ ] CHK042 - Is the `--help` output format specified with multi-directory examples? [Completeness, Gap]
- [ ] CHK043 - Are usage examples in help text specified for single vs multi-directory modes? [Completeness, Gap]
- [ ] CHK044 - Is the fzf header text ("Tab to select, max N") specified exactly? [Clarity, Spec §Contracts/cli-interface.md §fzf Multi-Select Behavior]
- [ ] CHK045 - Is the progress output format specified for multi-directory runs? [Clarity, Spec §Contracts/cli-interface.md §Standard Output]
- [ ] CHK046 - Is the completion summary format specified with per-directory breakdown? [Completeness, Gap]
- [ ] CHK047 - Are man page or README updates specified for the new multi-directory feature? [Coverage, Gap]

## CLI-UX Consistency

- [ ] CHK048 - Are multi-directory CLI patterns consistent with existing single-directory patterns? [Consistency, Spec §FR-006]
- [ ] CHK049 - Is the `--` separator convention documented if paths start with hyphens? [Coverage, Gap]
- [ ] CHK050 - Are the new function names consistent with existing `pndcgn_` namespace convention? [Consistency, Spec §plan.md §Constitution Check]
- [ ] CHK051 - Is the output filename format (`prefix--name.ext`) consistent across all documentation? [Consistency, Spec §data-model.md §Output Filename]

## Documentation Completeness

- [ ] CHK052 - Is the configuration option `max_source_dirs` documented with location (pndcgn.toml [source] section)? [Completeness, Spec §FR-005]
- [ ] CHK053 - Is the default value (4) and absolute maximum (16) documented in user-facing docs? [Completeness, Spec §FR-003, FR-004]
- [ ] CHK054 - Are all new functions documented with purpose, parameters, return values, and exit codes? [Completeness, Spec §Contracts/cli-interface.md §Function Signatures]
- [ ] CHK055 - Is the SQLite schema change documented for database administrators? [Completeness, Spec §data-model.md §Migration]
- [ ] CHK056 - Is the abbreviated prefix algorithm documented for users who need to understand filename patterns? [Completeness, Gap]
- [ ] CHK057 - Are assumptions documented (fzf version requirements, Tab key familiarity)? [Completeness, Spec §Assumptions]

## Documentation Clarity

- [ ] CHK058 - Is "multi-select" vs "multi-directory" terminology used consistently? [Clarity, Spec]
- [ ] CHK059 - Is the term "abbreviated prefix" defined clearly for non-technical users? [Clarity, Gap]
- [ ] CHK060 - Are examples provided for all edge cases (overlapping dirs, identical names, etc.)? [Clarity, Spec §data-model.md §Output Filename Examples]
- [ ] CHK061 - Is the distinction between fzf selection and CLI argument modes clearly explained? [Clarity, Gap]
- [ ] CHK062 - Is the backward compatibility guarantee clearly stated for existing users? [Clarity, Spec §US3]

## Documentation Coverage

- [ ] CHK063 - Are release notes requirements specified for this feature? [Coverage, Gap]
- [ ] CHK064 - Is a migration guide specified for users upgrading from single-directory mode? [Coverage, Gap]
- [ ] CHK065 - Are troubleshooting scenarios documented (fzf not found, config parse errors)? [Coverage, Gap]
- [ ] CHK066 - Is the feature documented in context of the overall pndcgn workflow? [Coverage, Gap]

## Non-Functional Requirements

- [ ] CHK067 - Is the performance target (N× + 10% overhead) specified with measurement methodology? [Measurability, Spec §SC-004]
- [ ] CHK068 - Are fzf version requirements specified (0.27+ for `--multi=N`)? [Completeness, Spec §research.md §1]
- [ ] CHK069 - Is SQLite version requirement specified (3.38+ for JSON functions)? [Completeness, Spec §research.md §3]
- [ ] CHK070 - Is the graceful degradation behavior specified when fzf is unavailable? [Completeness, Gap]
- [ ] CHK071 - Is the behavior on SIGINT/SIGTERM during multi-directory processing specified? [Completeness, Gap]

## Ambiguities & Conflicts

- [ ] CHK072 - Is "selection is prevented" in US2 Scenario 1 clarified (fzf behavior vs post-selection validation)? [Ambiguity, Spec §US2]
- [ ] CHK073 - Is the conflict between "falls back to current directory" (Edge Case) and "error if no source" resolved? [Conflict, Spec §Edge Cases vs §Contracts]
- [ ] CHK074 - Is the handling of symbolic links to directories specified? [Ambiguity, Gap]
- [ ] CHK075 - Is the handling of directories that become unreadable mid-processing specified? [Ambiguity, Gap]

## Dependencies & Assumptions

- [ ] CHK076 - Is the fzf dependency version constraint documented and validated? [Dependency, Spec §Assumptions]
- [ ] CHK077 - Is the assumption "users are familiar with fzf Tab key" validated or documented with help text? [Assumption, Spec §Assumptions]
- [ ] CHK078 - Is the assumption "default limit of 4 balances flexibility" validated with user research? [Assumption, Spec §Assumptions]
- [ ] CHK079 - Is the assumption "source directory names are filesystem-safe" handled with sanitization requirements? [Assumption, Spec §Assumptions]

---

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Link to relevant resources or documentation
- Items are numbered sequentially (CHK001-CHK079) for easy reference
- [Gap] indicates missing requirements that should be added to spec
- [Ambiguity] indicates unclear requirements needing clarification
- [Conflict] indicates contradictory requirements needing resolution
