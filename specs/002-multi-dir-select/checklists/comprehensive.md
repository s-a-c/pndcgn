# Comprehensive Requirements Quality Checklist

**Purpose**: Rigorous validation of requirements quality across all dimensions for Multi-Directory Selection feature
**Created**: 2025-12-18
**Focus Areas**: Configuration, Edge Cases, CLI Contract, UX Flow
**Depth**: Rigorous (formal release gate)

---

## 1. Configuration Requirements Quality

### 1.1. TOML Configuration Completeness

- [ ] CHK001 - Is the exact TOML section name (`[source]`) explicitly specified? [Completeness, Spec §FR-005]
- [ ] CHK002 - Is the exact TOML key name (`max_source_dirs`) explicitly specified? [Completeness, Spec §FR-005]
- [ ] CHK003 - Are valid value types (integer) and ranges (1-16) documented for `max_source_dirs`? [Completeness, Gap]
- [ ] CHK004 - Is the default value (4) explicitly documented when config is missing? [Completeness, Spec §FR-003]
- [ ] CHK005 - Is the absolute maximum (16) documented as a hard cap? [Completeness, Spec §FR-004]
- [ ] CHK006 - Are requirements for config file location (pndcgn.toml path) specified? [Gap]
- [ ] CHK007 - Is config file discovery order (CWD, XDG_CONFIG_HOME, etc.) documented? [Gap]

### 1.2. Configuration Clarity

- [ ] CHK008 - Is the behavior when `max_source_dirs = 0` explicitly defined? [Clarity, Spec §2.6 Edge Cases]
- [ ] CHK009 - Is the behavior when `max_source_dirs` is negative explicitly defined? [Clarity, Spec §2.6 Edge Cases]
- [ ] CHK010 - Is the behavior when `max_source_dirs` is non-integer (e.g., "five") defined? [Gap]
- [ ] CHK011 - Is the behavior when `[source]` section is missing entirely defined? [Gap]
- [ ] CHK012 - Is the behavior when config file is malformed (syntax error) defined? [Gap]
- [ ] CHK013 - Is the warning message format for over-max config specified? [Clarity, Spec §FR-008]

### 1.3. Configuration Consistency

- [ ] CHK014 - Are configuration requirements consistent between spec.md and plan.md? [Consistency]
- [ ] CHK015 - Does the default limit (4) align with the "balance flexibility" assumption in §5? [Consistency, Spec §5]
- [ ] CHK016 - Is SC-002 ("config takes effect without restart") testable given current requirements? [Measurability, Spec §SC-002]

---

## 2. Edge Case Coverage

### 2.1. Zero/Empty Selection Edge Cases

- [ ] CHK017 - Is the behavior when 0 directories selected (ESC pressed) completely specified? [Coverage, Spec §2.6]
- [ ] CHK018 - Is the behavior when Enter pressed with nothing selected specified? [Coverage, Spec §2.6]
- [ ] CHK019 - Is the fallback to "current directory" unambiguous (CWD vs. launch dir)? [Clarity, Spec §2.6]
- [ ] CHK020 - Is the warning message content for zero-selection fallback specified? [Gap]

### 2.2. Directory Access Edge Cases

- [ ] CHK021 - Is "unreadable directory" defined (permission denied vs. not exists)? [Clarity, Spec §2.6]
- [ ] CHK022 - Is the behavior when ALL selected directories are unreadable specified? [Gap]
- [ ] CHK023 - Is the behavior when a directory becomes unreadable mid-processing specified? [Gap]
- [ ] CHK024 - Is the behavior when a directory is deleted during selection specified? [Gap]
- [ ] CHK025 - Is the behavior for symlinked directories specified? [Gap]
- [ ] CHK026 - Is the behavior for directories with special characters in names specified? [Assumption, Spec §5]

### 2.3. Overlap Detection Edge Cases

- [ ] CHK027 - Is "overlap" precisely defined (direct subdirectory vs. any descendant)? [Clarity, Spec §FR-018]
- [ ] CHK028 - Is the behavior when A is subdir of B AND B is subdir of C specified? [Coverage, Spec §2.6]
- [ ] CHK029 - Is the INFO message content for excluded subdirectory specified? [Gap]
- [ ] CHK030 - Is the behavior when overlap detection fails (permission issues) specified? [Gap]
- [ ] CHK031 - Is symlink-based overlap (symlink to parent) addressed? [Gap]

### 2.4. Deduplication Edge Cases

- [ ] CHK032 - Is "duplicate" precisely defined (same path vs. same inode)? [Clarity, Spec §FR-007]
- [ ] CHK033 - Is the behavior for `./dir` vs. `dir` vs. `/abs/path/dir` specified? [Clarity, Spec §FR-007]
- [ ] CHK034 - Is the WARN message content for duplicate removal specified? [Gap]
- [ ] CHK035 - Is case sensitivity for path comparison specified (macOS HFS+ vs. Linux ext4)? [Gap]

### 2.5. Prefix Generation Edge Cases

- [ ] CHK036 - Is the behavior when all directories have identical basenames specified? [Coverage, Spec §2.6]
- [ ] CHK037 - Is the prefix separator (`--`) explicitly documented? [Completeness, Spec §3.2]
- [ ] CHK038 - Is the behavior when prefix + filename exceeds filesystem limits specified? [Gap]
- [ ] CHK039 - Is special character sanitization in prefixes defined? [Assumption, Spec §5]
- [ ] CHK040 - Is the behavior when sanitization creates duplicate prefixes specified? [Gap]

---

## 3. CLI Contract Quality

### 3.1. Argument Parsing Completeness

- [ ] CHK041 - Is the exact CLI syntax (`pndcgn dir1 dir2 ... target/`) documented? [Completeness, Spec §FR-014]
- [ ] CHK042 - Is "last argument is target" rule explicitly stated? [Completeness, Assumption §5]
- [ ] CHK043 - Is the minimum number of arguments (2: source + target) specified? [Gap]
- [ ] CHK044 - Is the behavior when only one argument provided specified? [Gap]
- [ ] CHK045 - Is the behavior when no arguments provided (fzf invocation) specified? [Completeness, Spec §US1]

### 3.2. CLI Error Handling

- [ ] CHK046 - Is the error message format for limit exceeded specified? [Clarity, Spec §FR-015]
- [ ] CHK047 - Is the exit code (2) for limit exceeded explicitly documented? [Completeness, Spec §FR-015]
- [ ] CHK048 - Is the behavior when source directory doesn't exist specified? [Gap]
- [ ] CHK049 - Is the behavior when target directory doesn't exist specified? [Gap]
- [ ] CHK050 - Is the behavior when target directory is not writable specified? [Gap]
- [ ] CHK051 - Is the behavior when source and target overlap (target is subdir of source) specified? [Gap]

### 3.3. CLI Consistency

- [ ] CHK052 - Are CLI multi-dir requirements consistent with fzf multi-select requirements? [Consistency]
- [ ] CHK053 - Do CLI prefix requirements match fzf prefix requirements (FR-011 vs US4 scenario 3)? [Consistency]
- [ ] CHK054 - Is exit code 2 consistent with constitution §VII Unix Philosophy? [Consistency, Constitution]

---

## 4. UX Flow Quality

### 4.1. fzf Interaction Completeness

- [ ] CHK055 - Is the fzf `--multi` flag behavior explicitly documented? [Completeness, Spec §FR-001]
- [ ] CHK056 - Is the Tab key for selection explicitly documented? [Completeness, Spec §US1]
- [ ] CHK057 - Is the fzf header/prompt format specified? [Clarity, Spec §FR-009]
- [ ] CHK058 - Is the dynamic count display format (e.g., "Selected: 2/4") specified? [Gap, Spec §FR-009]
- [ ] CHK059 - Is the fzf preview pane behavior specified? [Gap]
- [ ] CHK060 - Is the fzf keybinding customization addressed? [Gap]

### 4.2. Fallback UX Completeness

- [ ] CHK061 - Is the numbered list prompt format specified? [Completeness, Spec §2.5]
- [ ] CHK062 - Is the input format (comma-separated numbers) specified? [Completeness, Spec §2.5]
- [ ] CHK063 - Is the behavior for invalid input (e.g., "abc", "1,x,3") specified? [Gap]
- [ ] CHK064 - Is the behavior when user enters more numbers than limit specified? [Coverage, Spec §2.5]
- [ ] CHK065 - Is the INFO message for fallback activation specified? [Gap]
- [ ] CHK066 - Is the maximum number of directories shown in fallback list specified? [Gap]

### 4.3. Progress & Feedback UX

- [ ] CHK067 - Is progress output format specified for multi-directory runs? [Gap]
- [ ] CHK068 - Is the per-directory status format specified? [Gap]
- [ ] CHK069 - Is the final summary format for multi-directory runs specified? [Gap]
- [ ] CHK070 - Are INFO/WARN/ERROR message formats consistent with existing conventions? [Consistency, Spec §FR-017]

---

## 5. Acceptance Criteria Quality

### 5.1. User Story 1 Acceptance Criteria

- [ ] CHK071 - Can US1 Scenario 1 ("all selected directories processed in sequence") be objectively verified? [Measurability, Spec §US1]
- [ ] CHK072 - Can US1 Scenario 2 ("files from all 3 directories discovered and converted") be objectively verified? [Measurability, Spec §US1]
- [ ] CHK073 - Can US1 Scenario 3 ("single run ID covers all") be objectively verified? [Measurability, Spec §US1]
- [ ] CHK074 - Can US1 Scenario 4 ("abbreviated unique prefixes") be objectively verified? [Measurability, Spec §US1]

### 5.2. User Story 2 Acceptance Criteria

- [ ] CHK075 - Can US2 Scenario 1 ("6th selection prevented or warning shown") be objectively verified? [Measurability, Spec §US2]
- [ ] CHK076 - Is "prevented or warning shown" ambiguous (should it be one or the other)? [Ambiguity, Spec §US2]
- [ ] CHK077 - Can US2 Scenario 2 ("default limit of 4 applies") be objectively verified? [Measurability, Spec §US2]
- [ ] CHK078 - Can US2 Scenario 3 ("capped at 16 with warning") be objectively verified? [Measurability, Spec §US2]

### 5.3. User Story 3 Acceptance Criteria

- [ ] CHK079 - Can US3 Scenario 1 ("behavior identical to current single-select") be objectively verified? [Measurability, Spec §US3]
- [ ] CHK080 - Is "identical behavior" precisely defined (output format, timing, messages)? [Clarity, Spec §US3]
- [ ] CHK081 - Can US3 Scenario 2 ("fzf not invoked") be objectively verified? [Measurability, Spec §US3]

### 5.4. User Story 4 Acceptance Criteria

- [ ] CHK082 - Can US4 Scenario 1 ("files from all three source directories converted") be objectively verified? [Measurability, Spec §US4]
- [ ] CHK083 - Can US4 Scenario 2 ("error displayed and processing does not start") be objectively verified? [Measurability, Spec §US4]
- [ ] CHK084 - Can US4 Scenario 3 ("abbreviated unique prefixes just like fzf") be objectively verified? [Measurability, Spec §US4]

---

## 6. Success Criteria Quality

- [ ] CHK085 - Is SC-001 ("up to 16 directories") testable? [Measurability, Spec §SC-001]
- [ ] CHK086 - Is SC-002 ("without application restart") testable? [Measurability, Spec §SC-002]
- [ ] CHK087 - Is SC-003 ("no change in user experience or performance") measurable? [Ambiguity, Spec §SC-003]
- [ ] CHK088 - Is SC-004 ("N× single-directory time plus 10% overhead") measurable with specified method? [Measurability, Spec §SC-004]
- [ ] CHK089 - Is SC-005 ("identify which source directory") testable? [Measurability, Spec §SC-005]
- [ ] CHK090 - Is SC-006 ("no longer than necessary") objectively measurable? [Ambiguity, Spec §SC-006]

---

## 7. Non-Functional Requirements Coverage

### 7.1. Performance Requirements

- [ ] CHK091 - Is "linear scaling O(N)" precisely defined with measurement methodology? [Clarity, Plan §2]
- [ ] CHK092 - Is "<10% overhead" baseline defined (vs. N sequential runs)? [Clarity, Plan §2]
- [ ] CHK093 - Are memory requirements for N directories specified? [Gap]
- [ ] CHK094 - Are timeout/cancellation requirements for long-running multi-dir operations specified? [Gap]

### 7.2. Reliability Requirements

- [ ] CHK095 - Are crash recovery requirements for multi-directory runs specified? [Gap]
- [ ] CHK096 - Is partial completion state (some dirs processed before failure) tracked? [Gap]
- [ ] CHK097 - Are resume requirements for interrupted multi-directory runs specified? [Gap, Constitution §VI]

### 7.3. Logging & Observability

- [ ] CHK098 - Is the log level (INFO/WARN/ERROR) specified for each operation type? [Gap]
- [ ] CHK099 - Is the log message format for multi-directory operations specified? [Gap]
- [ ] CHK100 - Are structured logging requirements (JSON, key-value) specified? [Gap]

---

## 8. Dependencies & Assumptions Quality

### 8.1. External Dependencies

- [ ] CHK101 - Is the minimum fzf version with `--multi` support documented? [Gap, Spec §5]
- [ ] CHK102 - Is the fzf detection method (`command -v fzf`) specified? [Gap]
- [ ] CHK103 - Are SQLite version requirements for JSON storage documented? [Gap]

### 8.2. Assumptions Validation

- [ ] CHK104 - Is assumption "fzf supports --multi" validated with version constraint? [Assumption, Spec §5]
- [ ] CHK105 - Is assumption "users familiar with Tab key" reasonable for all user segments? [Assumption, Spec §5]
- [ ] CHK106 - Is assumption "default 4 balances flexibility" validated with user research? [Assumption, Spec §5]
- [ ] CHK107 - Is assumption "16 max prevents performance issues" validated with benchmarks? [Assumption, Spec §5]
- [ ] CHK108 - Is assumption "source names filesystem-safe" validated with sanitization rules? [Assumption, Spec §5]
- [ ] CHK109 - Is assumption "last arg is target" unambiguous when all args are directories? [Assumption, Spec §5]

---

## 9. Traceability & Consistency

### 9.1. Requirement Traceability

- [ ] CHK110 - Does each FR have at least one corresponding task in tasks.md? [Traceability]
- [ ] CHK111 - Does each User Story have corresponding test tasks? [Traceability]
- [ ] CHK112 - Does each Success Criterion have a validation task? [Traceability]
- [ ] CHK113 - Is there a REQ-XXX ID scheme established for formal traceability? [Traceability, Constitution §III]

### 9.2. Cross-Document Consistency

- [ ] CHK114 - Are all 18 FRs from spec.md reflected in tasks.md? [Consistency]
- [ ] CHK115 - Are function names consistent between plan.md and tasks.md? [Consistency]
- [ ] CHK116 - Are file paths consistent between plan.md and tasks.md? [Consistency]
- [ ] CHK117 - Is terminology consistent (e.g., "source_dirs" vs "source directories")? [Consistency]

---

## 10. Ambiguities & Conflicts

- [ ] CHK118 - Is "prevented or warning shown" in US2 Scenario 1 ambiguous? [Ambiguity, Spec §US2]
- [ ] CHK119 - Is "identical behavior" in US3 Scenario 1 sufficiently defined? [Ambiguity, Spec §US3]
- [ ] CHK120 - Is "no change in user experience or performance" in SC-003 measurable? [Ambiguity, Spec §SC-003]
- [ ] CHK121 - Is "no longer than necessary" in SC-006 objectively verifiable? [Ambiguity, Spec §SC-006]
- [ ] CHK122 - Does FR-006 (backward compat) conflict with any new behavior? [Conflict]
- [ ] CHK123 - Does FR-013 (no prefix for single dir) align with FR-011 (prefix for multi-dir)? [Consistency]

---

## Summary

| Category | Item Count | Coverage Focus |
|----------|------------|----------------|
| Configuration Quality | 16 | TOML config completeness, clarity, consistency |
| Edge Case Coverage | 24 | Zero selection, access, overlap, dedup, prefix |
| CLI Contract Quality | 14 | Argument parsing, error handling, consistency |
| UX Flow Quality | 16 | fzf interaction, fallback, progress |
| Acceptance Criteria | 14 | User story measurability |
| Success Criteria | 6 | Measurability validation |
| Non-Functional | 10 | Performance, reliability, logging |
| Dependencies | 9 | External deps, assumptions |
| Traceability | 8 | REQ→TEST→Impl mapping |
| Ambiguities | 6 | Conflict detection |

**Total Items**: 123

---
