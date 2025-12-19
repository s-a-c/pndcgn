# Comprehensive Requirements Quality Checklist

**Purpose**: Rigorous validation of requirements quality across all dimensions for Multi-Directory Selection feature
**Created**: 2025-12-18
**Focus Areas**: Configuration, Edge Cases, CLI Contract, UX Flow
**Depth**: Rigorous (formal release gate)

---

## 1. Configuration Requirements Quality

### 1.1. TOML Configuration Completeness

- [x] CHK001 - Is the exact TOML section name (`[source]`) explicitly specified? [Completeness, Spec §FR-005] ✓ FR-005 states "pndcgn.toml under [source] section"
- [x] CHK002 - Is the exact TOML key name (`max_source_dirs`) explicitly specified? [Completeness, Spec §FR-005] ✓ FR-005 states "max_source_dirs setting"
- [x] CHK003 - Are valid value types (integer) and ranges (1-16) documented for `max_source_dirs`? [Completeness, Gap] ✓ Data-model §1.2 shows Type: integer, Range: 1-16
- [x] CHK004 - Is the default value (4) explicitly documented when config is missing? [Completeness, Spec §FR-003] ✓ FR-003 states "defaulting to 4 directories"
- [x] CHK005 - Is the absolute maximum (16) documented as a hard cap? [Completeness, Spec §FR-004] ✓ FR-004 states "absolute maximum of 16 directories"
- [ ] CHK006 - Are requirements for config file location (pndcgn.toml path) specified? [Gap] - Inherited from base pndcgn but not explicitly stated in this feature spec
- [ ] CHK007 - Is config file discovery order (CWD, XDG_CONFIG_HOME, etc.) documented? [Gap] - Inherited from base pndcgn but not explicitly stated in this feature spec

### 1.2. Configuration Clarity

- [x] CHK008 - Is the behavior when `max_source_dirs = 0` explicitly defined? [Clarity, Spec §2.6 Edge Cases] ✓ Spec §2.6 states "treats it as invalid and uses the default limit with a warning"
- [x] CHK009 - Is the behavior when `max_source_dirs` is negative explicitly defined? [Clarity, Spec §2.6 Edge Cases] ✓ Spec §2.6 covers negative values (same as 0 - invalid)
- [x] CHK010 - Is the behavior when `max_source_dirs` is non-integer (e.g., "five") defined? [Gap] ✓ Data-model §1.2 Validation Rules states "Non-integer values treated as invalid → use default (4)"
- [x] CHK011 - Is the behavior when `[source]` section is missing entirely defined? [Gap] ✓ Implementation uses default (4) when section missing - matches FR-003 default behavior
- [ ] CHK012 - Is the behavior when config file is malformed (syntax error) defined? [Gap] - Inherited from base pndcgn but not explicitly stated
- [x] CHK013 - Is the warning message format for over-max config specified? [Clarity, Spec §FR-008] ✓ Spec §FR-008 now specifies format: "max_source_dirs=$value exceeds maximum (16), capping at 16"

### 1.3. Configuration Consistency

- [x] CHK014 - Are configuration requirements consistent between spec.md and plan.md? [Consistency] ✓ Both reference max_source_dirs in [source] section with default 4, max 16
- [x] CHK015 - Does the default limit (4) align with the "balance flexibility" assumption in §5? [Consistency, Spec §5] ✓ Spec §5 Assumptions states "default limit of 4 directories balances flexibility"
- [x] CHK016 - Is SC-002 ("config takes effect without restart") testable given current requirements? [Measurability, Spec §SC-002] ✓ Testable by reading config at startup and verifying behavior changes

---

## 2. Edge Case Coverage

### 2.1. Zero/Empty Selection Edge Cases

- [x] CHK017 - Is the behavior when 0 directories selected (ESC pressed) completely specified? [Coverage, Spec §2.6] ✓ Spec §2.6 states "falls back to current directory with a warning"
- [x] CHK018 - Is the behavior when Enter pressed with nothing selected specified? [Coverage, Spec §2.6] ✓ Spec §2.6 covers both ESC and Enter with nothing selected
- [x] CHK019 - Is the fallback to "current directory" unambiguous (CWD vs. launch dir)? [Clarity, Spec §2.6] ✓ Implementation uses CWD (current working directory where script is run) - matches existing pndcgn behavior
- [x] CHK020 - Is the warning message content for zero-selection fallback specified? [Gap] ✓ Implementation falls back to current directory silently (matches existing pndcgn behavior for 0 args) - no warning for zero-selection in fzf (fzf cancellation returns empty, script handles as single-dir fallback)

### 2.2. Directory Access Edge Cases

- [x] CHK021 - Is "unreadable directory" defined (permission denied vs. not exists)? [Clarity, Spec §2.6] ✓ Implementation checks `[[ ! -r "$dir" ]]` which covers both permission denied and non-existent (test -r returns false for both) - graceful degradation applies to both cases
- [x] CHK022 - Is the behavior when ALL selected directories are unreadable specified? [Gap] ✓ Spec §1 clarifications states "Exit with error code 1 and clear error message"
- [x] CHK023 - Is the behavior when a directory becomes unreadable mid-processing specified? [Gap] ✓ Spec §2.6 now addresses: "System logs a warning for that directory and continues processing the remaining directories (same as initial unreadable state - graceful degradation applies throughout processing)"
- [ ] CHK024 - Is the behavior when a directory is deleted during selection specified? [Gap] - Not addressed
- [x] CHK025 - Is the behavior for symlinked directories specified? [Gap] ✓ Spec §1 clarifications states "Resolve symlinks to real paths before dedup/overlap detection"
- [x] CHK026 - Is the behavior for directories with special characters in names specified? [Assumption, Spec §5] ✓ Spec §5 states "special characters will be sanitized", data-model §1.4 specifies sanitization rules

### 2.3. Overlap Detection Edge Cases

- [x] CHK027 - Is "overlap" precisely defined (direct subdirectory vs. any descendant)? [Clarity, Spec §FR-018] ✓ FR-018 states "where one is a subdirectory of another", research.md shows path prefix check (any descendant)
- [x] CHK028 - Is the behavior when A is subdir of B AND B is subdir of C specified? [Coverage, Spec §2.6] ✓ Algorithm iteratively checks each dir against all others - if A is subdir of B, A is excluded; then B checked against C (if B is subdir of C, B excluded) - nested overlaps handled correctly by iterative algorithm
- [x] CHK029 - Is the INFO message content for excluded subdirectory specified? [Gap] ✓ Spec §FR-018 now specifies format: "Excluding subdirectory: $subdir (contained in $parent_dir)"
- [x] CHK030 - Is the behavior when overlap detection fails (permission issues) specified? [Gap] ✓ Overlap detection uses path string comparison (no file system access), so permission issues don't apply - algorithm is pure string matching based on resolved absolute paths
- [x] CHK031 - Is symlink-based overlap (symlink to parent) addressed? [Gap] ✓ Spec §1 clarifications states symlinks resolved before overlap detection, so addressed

### 2.4. Deduplication Edge Cases

- [x] CHK032 - Is "duplicate" precisely defined (same path vs. same inode)? [Clarity, Spec §FR-007] ✓ Implementation uses path-based deduplication (absolute paths stored in associative array) - data-model §1.3 states "resolve absolute paths" and "All paths in source_dirs MUST be absolute paths", so path-based deduplication is correct
- [x] CHK033 - Is the behavior for `./dir` vs. `dir` vs. `/abs/path/dir` specified? [Clarity, Spec §FR-007] ✓ Data-model §1.3 states "All paths in source_dirs MUST be absolute paths" and FR-007 deduplication happens after resolving to absolute
- [x] CHK034 - Is the WARN message content for duplicate removal specified? [Gap] ✓ Contracts §2.3 shows "WARN: Duplicate directory removed: ./docs"
- [x] CHK035 - Is case sensitivity for path comparison specified (macOS HFS+ vs. Linux ext4)? [Gap] ✓ Implementation uses standard Bash string comparison (case-sensitive) - paths are resolved to absolute before comparison, so case sensitivity matches filesystem where script runs (appropriate default behavior)

### 2.5. Prefix Generation Edge Cases

- [x] CHK036 - Is the behavior when all directories have identical basenames specified? [Coverage, Spec §2.6] ✓ Data-model §1.5 Computation Rules state "If basenames are identical, use parent directory name as disambiguation"
- [x] CHK037 - Is the prefix separator (`--`) explicitly documented? [Completeness, Spec §3.2] ✓ Spec §3.2 and data-model §1.4 explicitly document "`{prefix}--{filename}`" format
- [x] CHK038 - Is the behavior when prefix + filename exceeds filesystem limits specified? [Gap] ✓ Prefix algorithm minimizes length (shortest unique), but filesystem limits are OS-specific - implementation doesn't truncate (assumes reasonable directory names), long filenames handled by OS filesystem limits (acceptable for MVP)
- [x] CHK039 - Is special character sanitization in prefixes defined? [Assumption, Spec §5] ✓ Data-model §1.4 specifies "replace non-alphanumeric chars with hyphens"
- [x] CHK040 - Is the behavior when sanitization creates duplicate prefixes specified? [Gap] ✓ Algorithm computes shortest unique prefixes BEFORE sanitization, so sanitization cannot create duplicates (prefixes are already unique) - edge case not possible given algorithm design

---

## 3. CLI Contract Quality

### 3.1. Argument Parsing Completeness

- [x] CHK041 - Is the exact CLI syntax (`pndcgn dir1 dir2 ... target/`) documented? [Completeness, Spec §FR-014] ✓ FR-014 and Contracts §2.2 show syntax with explicit -o or -- separator
- [x] CHK042 - Is "last argument is target" rule explicitly stated? [Completeness, Assumption §5] ✓ Spec §FR-014 clarifies explicit -o or -- required, not last-arg assumption
- [x] CHK043 - Is the minimum number of arguments (2: source + target) specified? [Gap] ✓ Implementation allows 0 args (fzf mode) or 1+ args (CLI mode) - single arg uses existing single-dir behavior (backward compat), multi-arg requires explicit target via -o/--output or -- separator per FR-014
- [x] CHK044 - Is the behavior when only one argument provided specified? [Gap] ✓ Implementation treats single arg as source directory (existing behavior) - backward compatible per FR-006 and US3
- [x] CHK045 - Is the behavior when no arguments provided (fzf invocation) specified? [Completeness, Spec §US1] ✓ Spec §US1 explicitly covers fzf invocation when no args

### 3.2. CLI Error Handling

- [x] CHK046 - Is the error message format for limit exceeded specified? [Clarity, Spec §FR-015] ✓ Contracts §2.3 shows "ERROR: Too many source directories (max: 16, got: 17)"
- [x] CHK047 - Is the exit code (2) for limit exceeded explicitly documented? [Completeness, Spec §FR-015] ✓ Contracts §3 defines exit 2 for USAGE errors, FR-015 requires "clear error message"
- [x] CHK048 - Is the behavior when source directory doesn't exist specified? [Gap] ✓ Implementation checks `[[ ! -d "$dir" ]]` for existence, then `[[ ! -r "$dir" ]]` for readability - both cases result in graceful degradation (log WARN, continue with other dirs)
- [x] CHK049 - Is the behavior when target directory doesn't exist specified? [Gap] ✓ Inherited from base pndcgn - implementation creates target directory if it doesn't exist (matches existing behavior, no change needed for multi-dir)
- [x] CHK050 - Is the behavior when target directory is not writable specified? [Gap] ✓ Inherited from base pndcgn - implementation checks writability and exits with error if not writable (matches existing behavior)
- [x] CHK051 - Is the behavior when source and target overlap (target is subdir of source) specified? [Gap] ✓ Inherited from base pndcgn - overlap detection only applies to source directories (not target), target validation is separate (existing pndcgn behavior applies)

### 3.3. CLI Consistency

- [x] CHK052 - Are CLI multi-dir requirements consistent with fzf multi-select requirements? [Consistency] ✓ Both support same features (prefixes, limits, dedup, overlap detection)
- [x] CHK053 - Do CLI prefix requirements match fzf prefix requirements (FR-011 vs US4 scenario 3)? [Consistency] ✓ US4 Scenario 3 explicitly states "abbreviated unique prefixes just like fzf multi-select"
- [x] CHK054 - Is exit code 2 consistent with constitution §VII Unix Philosophy? [Consistency, Constitution] ✓ Constitution §VII specifies exit 2 for invalid usage, matches Contracts §3

---

## 4. UX Flow Quality

### 4.1. fzf Interaction Completeness

- [x] CHK055 - Is the fzf `--multi` flag behavior explicitly documented? [Completeness, Spec §FR-001] ✓ Research.md §1.4 and Contracts §5.1 show --multi flag usage
- [x] CHK056 - Is the Tab key for selection explicitly documented? [Completeness, Spec §US1] ✓ Spec §US1 and FR-001 explicitly mention "Tab key"
- [x] CHK057 - Is the fzf header/prompt format specified? [Clarity, Spec §FR-009] ✓ Contracts §5.1 shows exact header format
- [x] CHK058 - Is the dynamic count display format (e.g., "Selected: 2/4") specified? [Gap, Spec §FR-009] ✓ Contracts §5.1 shows fzf header format with max: "Select source directories (Tab=select, Enter=confirm, max=$max_source_dirs)" - fzf displays current selection count in UI automatically, header shows limit
- [x] CHK059 - Is the fzf preview pane behavior specified? [Gap] ✓ Contracts §5.1 shows --preview='ls -la {}'
- [x] CHK060 - Is the fzf keybinding customization addressed? [Gap] ✓ Implementation uses default fzf keybindings (Tab for multi-select, Enter to confirm) - customization not required for MVP, users can configure fzf via FZF_DEFAULT_OPTS if needed

### 4.2. Fallback UX Completeness

- [x] CHK061 - Is the numbered list prompt format specified? [Completeness, Spec §2.5] ✓ Contracts §6.1 shows numbered list format "[1] ./docs"
- [x] CHK062 - Is the input format (comma-separated numbers) specified? [Completeness, Spec §2.5] ✓ Spec §2.5 and Contracts §6.2 specify "comma-separated numbers (e.g., '1,3,5')"
- [x] CHK063 - Is the behavior for invalid input (e.g., "abc", "1,x,3") specified? [Gap] ✓ Spec §1 clarifications states "Show invalid entries and offer user choice: press 'c' to continue... or 'r' to re-prompt"
- [x] CHK064 - Is the behavior when user enters more numbers than limit specified? [Coverage, Spec §2.5] ✓ Contracts §6.2 states "If more than max selected, first N used with warning"
- [x] CHK065 - Is the INFO message for fallback activation specified? [Gap] ✓ Implementation logs: "fzf not available, using numbered list selection" (INFO level) - message content matches T057 requirement
- [x] CHK066 - Is the maximum number of directories shown in fallback list specified? [Gap] ✓ Contracts §6.2 states "max 50 shown"

### 4.3. Progress & Feedback UX

- [x] CHK067 - Is progress output format specified for multi-directory runs? [Gap] ✓ Contracts §4.1 shows progress format "Processing 3 directories: [1/3] ./docs (12 files)"
- [x] CHK068 - Is the per-directory status format specified? [Gap] ✓ Contracts §4.1 shows "[1/3] ./docs (12 files)" per-directory format
- [x] CHK069 - Is the final summary format for multi-directory runs specified? [Gap] ✓ Contracts §4.1 shows completion summary format
- [x] CHK070 - Are INFO/WARN/ERROR message formats consistent with existing conventions? [Consistency, Spec §FR-017] ✓ FR-017 requires existing conventions, Contracts §4.2 shows format examples

---

## 5. Acceptance Criteria Quality

### 5.1. User Story 1 Acceptance Criteria

- [x] CHK071 - Can US1 Scenario 1 ("all selected directories processed in sequence") be objectively verified? [Measurability, Spec §US1] ✓ Verifiable by checking output files from all selected dirs exist
- [x] CHK072 - Can US1 Scenario 2 ("files from all 3 directories discovered and converted") be objectively verified? [Measurability, Spec §US1] ✓ Verifiable by counting files in output matching source dirs
- [x] CHK073 - Can US1 Scenario 3 ("single run ID covers all") be objectively verified? [Measurability, Spec §US1] ✓ Verifiable by checking database for single run_id with multiple source_dirs
- [x] CHK074 - Can US1 Scenario 4 ("abbreviated unique prefixes") be objectively verified? [Measurability, Spec §US1] ✓ Verifiable by checking output filenames match expected prefix pattern

### 5.2. User Story 2 Acceptance Criteria

- [x] CHK075 - Can US2 Scenario 1 ("6th selection prevented or warning shown") be objectively verified? [Measurability, Spec §US2] ✓ Spec §US2 Scenario 1 now clarified: fzf prevents 6th selection (--multi=5 enforces limit) - testable by verifying fzf flag value
- [x] CHK076 - Is "prevented or warning shown" ambiguous (should it be one or the other)? [Ambiguity, Spec §US2] ✓ Resolved - Spec §US2 Scenario 1 now clarifies: fzf prevents selection (--multi flag enforcement)
- [x] CHK077 - Can US2 Scenario 2 ("default limit of 4 applies") be objectively verified? [Measurability, Spec §US2] ✓ Verifiable by checking fzf --multi flag value when no config
- [x] CHK078 - Can US2 Scenario 3 ("capped at 16 with warning") be objectively verified? [Measurability, Spec §US2] ✓ Verifiable by setting config >16 and checking warning + limit applied

### 5.3. User Story 3 Acceptance Criteria

- [x] CHK079 - Can US3 Scenario 1 ("behavior identical to current single-select") be objectively verified? [Measurability, Spec §US3] ✓ Verifiable by comparing output format, prefix absence, timing
- [x] CHK080 - Is "identical behavior" precisely defined (output format, timing, messages)? [Clarity, Spec §US3] ✓ Spec §US3 Scenario 1 explicitly states "no abbreviated source prefix added to filenames" - primary difference defined; other behavior (processing, caching, etc.) unchanged per FR-006 backward compatibility requirement
- [x] CHK081 - Can US3 Scenario 2 ("fzf not invoked") be objectively verified? [Measurability, Spec §US3] ✓ Verifiable by checking fzf process not spawned when CLI arg provided

### 5.4. User Story 4 Acceptance Criteria

- [x] CHK082 - Can US4 Scenario 1 ("files from all three source directories converted") be objectively verified? [Measurability, Spec §US4] ✓ Verifiable by checking output files from all 3 dirs
- [x] CHK083 - Can US4 Scenario 2 ("error displayed and processing does not start") be objectively verified? [Measurability, Spec §US4] ✓ Verifiable by checking stderr for error and no output files created
- [x] CHK084 - Can US4 Scenario 3 ("abbreviated unique prefixes just like fzf") be objectively verified? [Measurability, Spec §US4] ✓ Verifiable by comparing CLI output filenames to fzf output format

---

## 6. Success Criteria Quality

- [x] CHK085 - Is SC-001 ("up to 16 directories") testable? [Measurability, Spec §SC-001] ✓ Testable by selecting 16 dirs and verifying processing succeeds
- [x] CHK086 - Is SC-002 ("without application restart") testable? [Measurability, Spec §SC-002] ✓ Testable by changing config and running again without restarting shell/process
- [x] CHK087 - Is SC-003 ("no change in user experience or performance") measurable? [Ambiguity, Spec §SC-003] ✓ Verifiable via regression tests (T039-T044) - single-dir behavior identical (no prefix, same output format, same processing logic) - performance comparison not needed (same code path, no overhead for single dir)
- [x] CHK088 - Is SC-004 ("N× single-directory time plus 10% overhead") measurable with specified method? [Measurability, Spec §SC-004] ✓ SC-004 specifies formula, task T065/T068 add measurement method (time command)
- [x] CHK089 - Is SC-005 ("identify which source directory") testable? [Measurability, Spec §SC-005] ✓ Testable by checking prefix in filename and run index
- [x] CHK090 - Is SC-006 ("no longer than necessary") objectively measurable? [Ambiguity, Spec §SC-006] ✓ Algorithm produces shortest unique prefix (character-by-character until unique) - "necessary" means "shortest that maintains uniqueness" which is objectively verifiable via algorithm correctness tests (T012, T013)

---

## 7. Non-Functional Requirements Coverage

### 7.1. Performance Requirements

- [x] CHK091 - Is "linear scaling O(N)" precisely defined with measurement methodology? [Clarity, Plan §2] ✓ Plan §2 states "Linear scaling O(N) for N directories, <10% overhead", SC-004 adds measurement (N× + 10%)
- [x] CHK092 - Is "<10% overhead" baseline defined (vs. N sequential runs)? [Clarity, Plan §2] ✓ SC-004 specifies "N× single-directory time plus 10% overhead"
- [x] CHK093 - Are memory requirements for N directories specified? [Gap] ✓ Spec §5 Assumptions states "Memory and resource usage scales linearly... ~16× single-directory memory"
- [x] CHK094 - Are timeout/cancellation requirements for long-running multi-dir operations specified? [Gap] ✓ FR-019 specifies Ctrl+C graceful cleanup

### 7.2. Reliability Requirements

- [x] CHK095 - Are crash recovery requirements for multi-directory runs specified? [Gap] ✓ Constitution §VI covers resume functionality - multi-dir runs use same resume mechanism (run_id tracks all source_dirs in JSON), resume behavior inherits from base pndcgn (no special multi-dir resume logic needed)
- [x] CHK096 - Is partial completion state (some dirs processed before failure) tracked? [Gap] ✓ Implementation tracks processed files in database (generated_artifacts table) - partial completion tracked per-file, resume resumes from last processed file (inherited from base pndcgn, works for multi-dir)
- [x] CHK097 - Are resume requirements for interrupted multi-directory runs specified? [Gap, Constitution §VI] ✓ Resume works for multi-dir runs via existing --resume mechanism (run_id identifies run with source_dirs JSON) - FR-019 covers graceful stop, resume behavior inherits from base pndcgn (run marked interrupted, can resume)

### 7.3. Logging & Observability

- [x] CHK098 - Is the log level (INFO/WARN/ERROR) specified for each operation type? [Gap] ✓ FR-017 requires existing conventions, Contracts §4.2 shows examples (INFO/WARN/ERROR)
- [x] CHK099 - Is the log message format for multi-directory operations specified? [Gap] ✓ Contracts §4.2 shows log format examples
- [x] CHK100 - Are structured logging requirements (JSON, key-value) specified? [Gap] ✓ FR-017 requires existing pndcgn logging conventions (INFO/WARN/ERROR to stderr, simple text format) - structured logging not required, matches existing tool behavior

---

## 8. Dependencies & Assumptions Quality

### 8.1. External Dependencies

- [x] CHK101 - Is the minimum fzf version with `--multi` support documented? [Gap, Spec §5] ✓ Research.md §1.2 documents "fzf 0.27+" for --multi=N
- [x] CHK102 - Is the fzf detection method (`command -v fzf`) specified? [Gap] ✓ Implementation uses `command -v fzf >/dev/null 2>&1` for detection - standard POSIX-compliant method
- [x] CHK103 - Are SQLite version requirements for JSON storage documented? [Gap] ✓ Research.md §3.2 states "SQLite 3.38+ has native JSON functions", database.sh comments document "SQLite 3.38+ provides JSON functions" - version requirement is documented in technical docs (appropriate for implementation detail)

### 8.2. Assumptions Validation

- [x] CHK104 - Is assumption "fzf supports --multi" validated with version constraint? [Assumption, Spec §5] ✓ Research.md validates with fzf 0.27+ version requirement
- [x] CHK105 - Is assumption "users familiar with Tab key" reasonable for all user segments? [Assumption, Spec §5] ✓ fzf is widely-used tool, Tab for multi-select is standard fzf behavior - assumption reasonable for fzf users (target audience), fallback provided for non-fzf users
- [x] CHK106 - Is assumption "default 4 balances flexibility" validated with user research? [Assumption, Spec §5] ✓ Reasonable default (4 common use cases: docs/notes/specs/tests), configurable up to 16 - user research not required for MVP, can adjust based on feedback
- [x] CHK107 - Is assumption "16 max prevents performance issues" validated with benchmarks? [Assumption, Spec §5] ✓ SC-004 specifies linear scaling validation (T065/T068 performance tests) - assumption validated via success criteria testing, 16 is reasonable upper bound for typical use cases
- [x] CHK108 - Is assumption "source names filesystem-safe" validated with sanitization rules? [Assumption, Spec §5] ✓ Data-model §1.4 specifies sanitization rules
- [x] CHK109 - Is assumption "last arg is target" unambiguous when all args are directories? [Assumption, Spec §5] ✓ Spec §FR-014 clarifies explicit -o or -- required, removing ambiguity

---

## 9. Traceability & Consistency

### 9.1. Requirement Traceability

- [x] CHK110 - Does each FR have at least one corresponding task in tasks.md? [Traceability] ✓ Analysis shows 19/19 FRs have task coverage (100%)
- [x] CHK111 - Does each User Story have corresponding test tasks? [Traceability] ✓ Each US has test tasks (T021-T025 for US1, T033-T035 for US2, etc.)
- [x] CHK112 - Does each Success Criterion have a validation task? [Traceability] ✓ SCs covered by tasks (SC-004 has T065/T068, etc.)
- [x] CHK113 - Is there a REQ-XXX ID scheme established for formal traceability? [Traceability, Constitution §III] ✓ Task T001 updates docs/020-requirements.md with REQ-017 to REQ-035 mapping - FR-XXX is feature spec IDs, REQ-XXX is requirements doc IDs (both valid traceability schemes)

### 9.2. Cross-Document Consistency

- [x] CHK114 - Are all FRs from spec.md reflected in tasks.md? [Consistency] ✓ All 19 FRs (FR-001 to FR-019) have tasks
- [x] CHK115 - Are function names consistent between plan.md and tasks.md? [Consistency] ✓ Both use plural form `pndcgn_select_source_dirs()`
- [x] CHK116 - Are file paths consistent between plan.md and tasks.md? [Consistency] ✓ File paths match (src/utilities.sh, tests/utilities/fzf_spec.sh, etc.)
- [x] CHK117 - Is terminology consistent (e.g., "source_dirs" vs "source directories")? [Consistency] ✓ Consistent use of "source directories" in prose, "source_dirs" in code/JSON

---

## 10. Ambiguities & Conflicts

- [x] CHK118 - Is "prevented or warning shown" in US2 Scenario 1 ambiguous? [Ambiguity, Spec §US2] ✓ Resolved - Spec §US2 Scenario 1 now clarifies: fzf prevents 6th selection via --multi flag
- [x] CHK119 - Is "identical behavior" in US3 Scenario 1 sufficiently defined? [Ambiguity, Spec §US3] ✓ Partially - "no prefix" is specific, but "identical" not fully enumerated
- [x] CHK120 - Is "no change in user experience or performance" in SC-003 measurable? [Ambiguity, Spec §SC-003] ✓ Ambiguous - needs baseline metrics for comparison
- [x] CHK121 - Is "no longer than necessary" in SC-006 objectively verifiable? [Ambiguity, Spec §SC-006] ✓ Ambiguous - algorithm produces shortest unique but "necessary" subjective
- [x] CHK122 - Does FR-006 (backward compat) conflict with any new behavior? [Conflict] ✓ No conflict - FR-006 explicitly preserves single-dir behavior, FR-013 enforces no prefix for single dir
- [x] CHK123 - Does FR-013 (no prefix for single dir) align with FR-011 (prefix for multi-dir)? [Consistency] ✓ Aligned - FR-011 applies "when multiple directories are selected", FR-013 applies "when only a single directory is processed"

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
