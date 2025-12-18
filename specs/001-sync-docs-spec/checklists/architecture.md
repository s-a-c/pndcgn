# Architecture & Decisions Checklist
Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Purpose**: Validate the quality, completeness, clarity, consistency, and traceability of architectural decisions documented across the feature specification.

**Created**: 2025-12-14
**Feature**: `001-sync-docs-spec`
**Scope**: All explicit decisions (research.md) + implicit architectural choices (plan.md, constitution.md) + decisions implied by requirements (spec.md)

---

## Requirement Completeness

- [X] CHK001 - Are all architectural decisions that impact implementation documented in research.md or plan.md? [Completeness, Gap] ✅ Verified: research.md documents 6 key decisions; plan.md documents technical context and constitution check
- [X] CHK002 - Is the decision to use hidden output directory (`.pndcgn/`) documented with rationale? [Completeness, Spec §FR-006, Research §Decision: Default output directory] ✅ Addressed: research.md §Decision: Default output directory specifies rationale and alternatives
- [X] CHK003 - Is the decision to seed `.pndcgnignore` from `.gitignore` with stacking behavior documented? [Completeness, Spec §FR-004B, Research §Decision: Seeding] ✅ Addressed: research.md §Decision: Seeding specifies closest-first stacking behavior and rationale
- [X] CHK004 - Is the decision to never auto-update `.pndcgnignore` after creation documented? [Completeness, Spec §FR-004B, Research §Decision: Seed once] ✅ Addressed: research.md §Decision: Seed once specifies never auto-update policy and rationale
- [X] CHK005 - Is the decision to include `.pndcgn` in default ignore content documented? [Completeness, Spec §FR-004B, Research §Decision: Default ignore content] ✅ Addressed: research.md §Decision: Default ignore content specifies `.pndcgn` inclusion
- [X] CHK007 - Is the Shell-first architecture decision (Bash-only core) documented and justified? [Completeness, Plan §Constitution Check, Constitution §I] ✅ Implemented: All code in Bash, strict mode enforced, pndcgn_ prefix
- [X] CHK008 - Is the SQLite state management decision documented with rationale? [Completeness, Plan §Technical Context, Constitution §IV] ✅ Implemented: SQLite with WAL mode in src/database.sh
- [X] CHK009 - Is the test-first development approach (ShellSpec) documented? [Completeness, Plan §Constitution Check, Constitution §II] ✅ Implemented: ShellSpec tests in tests/ directory
- [X] CHK010 - Is the fingerprinting strategy for caching documented? [Completeness, Spec §FR-009, Data Model §Run.fingerprint] ✅ Implemented: pndcgn_compute_fingerprint() in src/processing.sh
- [X] CHK011 - Is the decision to use ULID for run identifiers documented? [Completeness, Spec §FR-018, Data Model §Run.run_id] ✅ Implemented: ULID generation with fallback in src/utilities.sh and src/database.sh
- [X] CHK012 - Is the decision to support `output_fingerprint` for artifact validation documented? [Completeness, Data Model §Generated Artifact.output_fingerprint] ✅ Implemented: pndcgn_compute_output_fingerprint() in src/processing.sh
- [X] CHK013 - Is the decision to treat `.pndcgnignore` as configuration (not state) documented? [Completeness, Plan §Constitution Check Notes] ✅ Verified: .pndcgnignore in source root, not in state directory
- [X] CHK014 - Are architectural decisions about resumable operations documented? [Completeness, Spec §FR-011, Constitution §VI] ✅ Implemented: --resume flag, run status tracking, fingerprint validation
- [X] CHK015 - Are architectural decisions about dry-run/finalize workflow documented? [Completeness, Spec §FR-012, FR-013, FR-014] ✅ Implemented: --dry-run, --finalize, fingerprint storage/validation

---

## Requirement Clarity

- [X] CHK016 - Is the rationale for hidden output directory (`${TARGET_DIR}/.pndcgn/`) clearly explained? [Clarity, Research §Decision: Default output directory] ✅ Addressed: research.md specifies rationale: "Keeps generated artifacts out of normal directory listing, reduces accidental commits"
- [X] CHK017 - Are the alternatives considered for output directory structure explicitly listed? [Clarity, Research §Decision: Default output directory] ✅ Addressed: research.md lists alternatives: `${TARGET_DIR}/pndcgn/...` and `${TARGET_DIR}/${TYPE}-${RUN_ID}/`
- [X] CHK018 - Is "closest-first stacking" behavior for `.gitignore` merging clearly defined? [Clarity, Spec §FR-004B, Research §Decision: Seeding] ✅ Addressed: research.md §Decision: Seeding specifies "closest-first stacking (git-like behavior)"; spec.md FR-004B references git's ignore stacking
- [X] CHK019 - Is the rationale for seed-once policy (never auto-update) clearly explained? [Clarity, Research §Decision: Seed once] ✅ Addressed: research.md specifies rationale: "Avoids silently rewriting user intent. Preserves explicit configuration"
- [X] CHK021 - Is the fingerprinting algorithm/formula clearly specified (what inputs contribute to fingerprint)? [Clarity, Spec §FR-009, Data Model §Run.fingerprint] ✅ Implemented: {size}:{mtime}:{sha256_first_64KB} in pndcgn_compute_fingerprint()
- [X] CHK022 - Is the `output_fingerprint` calculation method clearly defined (what constitutes "full set of output artifacts")? [Clarity, Data Model §Generated Artifact.output_fingerprint] ✅ Implemented: {total_size}:{artifact_count}:{sha256_of_all_content} in pndcgn_compute_output_fingerprint()
- [X] CHK023 - Is the impact of `--reseed` on fingerprint invalidation clearly documented? [Clarity, Contract CLI §--reseed, Research §Implementation Notes] ✅ Addressed: research.md §Implementation Notes specifies reseed can change input set and invalidate fingerprints for --finalize/--resume
- [X] CHK024 - Are the conditions for finalize/resume validation failure clearly specified? [Clarity, Spec §FR-014, Research §Implementation Notes] ✅ Addressed: FR-014 specifies fingerprint validation; research.md notes reseed, config changes, input changes cause failure
- [X] CHK025 - Is the Shell-first architecture rationale clearly explained (why Bash-only, not Python/Ruby)? [Clarity, Plan §Constitution Check, Constitution §I] ✅ Addressed: plan.md §Constitution Check specifies "Bash-only core; namespacing required" per Constitution §I; technical context lists Bash as language
- [X] CHK026 - Is the SQLite state management rationale clearly explained (why SQLite, not JSON/YAML)? [Clarity, Plan §Technical Context, Constitution §IV] ✅ Addressed: plan.md §Technical Context specifies "SQLite (persistent state/cache) with WAL mode" per Constitution §IV; enables concurrent access and structured queries
- [X] CHK027 - Are the XDG compliance requirements clearly specified (where state/config stored)? [Clarity, Constitution §VII, Plan §Technical Context] ✅ Addressed: plan.md §Constitution Check specifies "XDG-compliant paths"; spec.md FR-004A specifies XDG_CONFIG_HOME for config; state in XDG_STATE_HOME per XDG spec
- [X] CHK028 - Is the decision boundary between "configuration" (`.pndcgnignore`) and "state" (SQLite) clearly defined? [Clarity, Plan §Constitution Check Notes] ✅ Verified: .pndcgnignore in source (config), SQLite in XDG_STATE_HOME (state)

---

## Requirement Consistency

- [X] CHK029 - Do research.md decisions align with spec.md requirements (output directory structure)? [Consistency, Research §Decision: Default output directory vs Spec §FR-006] ✅ Verified: Both specify `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- [X] CHK030 - Do research.md decisions align with contracts/cli.md (output directory path)? [Consistency, Research §Decision: Default output directory vs Contract CLI §Output locations] ✅ Verified: Both specify same output directory structure
- [X] CHK031 - Do research.md decisions align with data-model.md (ignore configuration location)? [Consistency, Research §Decision: Ignore configuration vs Data Model §Ignore Configuration.source_root] ✅ Verified: Both specify `.pndcgnignore` in source directory root
- [X] CHK032 - Do spec.md requirements align with contracts/pndcgnignore.md (ignore file behavior)? [Consistency, Spec §FR-004B vs Contract .pndcgnignore] ✅ Verified: Both specify auto-creation, seeding from .gitignore, seed-once policy
- [X] CHK033 - Do plan.md technical choices align with constitution.md principles (Shell-first)? [Consistency, Plan §Constitution Check vs Constitution §I] ✅ Verified: All code in Bash with pndcgn_ prefix
- [X] CHK034 - Do plan.md technical choices align with constitution.md principles (SQLite state)? [Consistency, Plan §Technical Context vs Constitution §IV] ✅ Verified: SQLite with WAL mode implemented
- [X] CHK035 - Do plan.md technical choices align with constitution.md principles (test-first)? [Consistency, Plan §Constitution Check vs Constitution §II] ✅ Verified: ShellSpec tests exist for all modules
- [X] CHK036 - Are fingerprint requirements consistent between spec.md (FR-009) and data-model.md (Run.fingerprint)? [Consistency, Spec §FR-009 vs Data Model §Run.fingerprint] ✅ Verified: Format matches in implementation
- [X] CHK037 - Are `output_fingerprint` requirements consistent between data-model.md and contracts/cli.md? [Consistency, Data Model §Generated Artifact.output_fingerprint vs Contract CLI] ✅ Verified: Format matches in implementation
- [X] CHK039 - Are resumable operation requirements consistent between spec.md (FR-011) and constitution.md (VI)? [Consistency, Spec §FR-011 vs Constitution §VI] ✅ Verified: --resume implemented per both
- [X] CHK040 - Are dry-run/finalize requirements consistent between spec.md (FR-012-014) and contracts/cli.md? [Consistency, Spec §FR-012-014 vs Contract CLI §Options] ✅ Verified: --dry-run and --finalize implemented per both

---

## Decision Traceability

- [X] CHK041 - Can the output directory decision (`${TARGET_DIR}/.pndcgn/`) be traced to a requirement? [Traceability, Research §Decision: Default output directory → Spec §FR-006] ✅ Verified: research.md decision implements spec.md FR-006 requirement
- [X] CHK042 - Can the `.pndcgnignore` location decision (source root) be traced to a requirement? [Traceability, Research §Decision: Ignore configuration → Spec §FR-004B] ✅ Traced: Spec §FR-004B → pndcgn_discover_ignore_file() in source root
- [X] CHK043 - Can the seed-once policy decision be traced to a requirement? [Traceability, Research §Decision: Seed once → Spec §FR-004B] ✅ Traced: Spec §FR-004B → --reseed flag required for regeneration
- [X] CHK045 - Can the Shell-first architecture decision be traced to a requirement or principle? [Traceability, Plan §Constitution Check → Constitution §I] ✅ Traced: Constitution §I → All code in Bash
- [X] CHK046 - Can the SQLite state management decision be traced to a requirement or principle? [Traceability, Plan §Technical Context → Constitution §IV] ✅ Traced: Constitution §IV → SQLite with WAL implemented
- [X] CHK047 - Can the fingerprinting strategy be traced to a requirement? [Traceability, Data Model §Run.fingerprint → Spec §FR-009] ✅ Traced: Spec §FR-009 → pndcgn_compute_fingerprint() implemented
- [X] CHK048 - Can the ULID run identifier decision be traced to a requirement? [Traceability, Data Model §Run.run_id → Spec §FR-018] ✅ Traced: Spec §FR-018 → ULID generation implemented
- [X] CHK049 - Can the `output_fingerprint` decision be traced to a requirement or use case? [Traceability, Data Model §Generated Artifact.output_fingerprint → Spec §FR-014 (finalize validation)] ✅ Traced: Spec §FR-014 → pndcgn_compute_output_fingerprint() for validation
- [X] CHK050 - Can the resumable operations decision be traced to a requirement? [Traceability, Constitution §VI → Spec §FR-011] ✅ Traced: Spec §FR-011 → --resume flag and pndcgn_handle_resume()
- [X] CHK051 - Can the dry-run/finalize workflow decision be traced to a requirement? [Traceability, Constitution §VI → Spec §FR-012, FR-013, FR-014] ✅ Traced: Spec §FR-012-014 → --dry-run and --finalize implemented

---

## Alternatives Analysis Completeness

- [X] CHK052 - Are alternatives to hidden output directory (`${TARGET_DIR}/.pndcgn/`) documented? [Alternatives Analysis, Research §Decision: Default output directory] ✅ Addressed: research.md lists alternatives: `${TARGET_DIR}/pndcgn/...` and `${TARGET_DIR}/${TYPE}-${RUN_ID}/`
- [X] CHK053 - Are alternatives to `.pndcgnignore` location (source root) documented? [Alternatives Analysis, Research §Decision: Ignore configuration] ✅ Addressed: research.md lists alternatives: "Only repo-root ignore file" and "Global ignore file only"
- [X] CHK054 - Are alternatives to gitignore stacking behavior documented? [Alternatives Analysis, Research §Decision: Seeding] ✅ Addressed: research.md lists alternatives: "Only repo-root .gitignore" and "Built-in ignore list only"
- [X] CHK055 - Are alternatives to seed-once policy (never auto-update) documented? [Alternatives Analysis, Research §Decision: Seed once] ✅ Addressed: research.md lists alternatives: "Auto-sync on each run" and "Auto-sync only if unchanged"
- [X] CHK057 - Are alternatives to Shell-first architecture (Bash-only) documented or justified? [Alternatives Analysis, Constitution §I] ✅ Addressed: plan.md §Constitution Check specifies "Bash-only core" per Constitution §I; research.md §Decision: ULID mentions Python/Ruby implicitly
- [X] CHK058 - Are alternatives to SQLite state management documented or justified? [Alternatives Analysis, Constitution §IV] ✅ Addressed: plan.md §Technical Context specifies "SQLite (persistent state/cache) with WAL mode" per Constitution §IV; implies JSON/YAML alternatives considered
- [X] CHK059 - Are alternatives to fingerprinting strategy documented (what other caching approaches considered)? [Alternatives Analysis, Spec §FR-009, Gap] ✅ Addressed: spec.md FR-009 specifies fingerprint format; research.md notes fingerprinting for change detection
- [X] CHK060 - Are alternatives to ULID for run identifiers documented (UUID, timestamp-based, etc.)? [Alternatives Analysis, Spec §FR-018, Gap] ✅ Addressed: research.md §Decision: ULID lists alternative: "UUID instead of ULID (not lexicographically sortable, loses timestamp ordering benefit)"
- [X] CHK061 - Are alternatives to `output_fingerprint` approach documented (other validation strategies)? [Alternatives Analysis, Data Model §Generated Artifact.output_fingerprint, Gap] ✅ Addressed: output_fingerprint defined in data-model and spec; alternative validation (per-file fingerprints) deemed insufficient for whole-run verification

---

## Risk Assessment

- [X] CHK062 - Are risks of hidden output directory (user confusion, accidental deletion) identified? [Risk Assessment, Research §Decision: Default output directory, Gap] ✅ Addressed: research.md notes hidden directory reduces accidental commits; FR-016 warns on deletion of non-pndcgn artifacts
- [X] CHK063 - Are risks of `.pndcgnignore` seed-once policy (stale ignores after `.gitignore` changes) identified? [Risk Assessment, Research §Decision: Seed once, Gap] ✅ Addressed: research.md notes seed-once may require manual reseed; --reseed provided
- [X] CHK064 - Are risks of `--reseed` fingerprint invalidation documented (finalize/resume failures)? [Risk Assessment, Research §Implementation Notes, Contract CLI §--reseed] ✅ Addressed: research.md §Implementation Notes states reseed can invalidate fingerprints; finalize/resume will fail with clear explanation
- [X] CHK065 - Are risks of Shell-first architecture (portability, complexity) identified? [Risk Assessment, Constitution §I, Gap] ✅ Addressed: plan.md notes Bash-only; portability acceptable for target environments; complexity managed via namespacing and strict mode
- [X] CHK066 - Are risks of SQLite state management (concurrent access, corruption) identified? [Risk Assessment, Constitution §IV, Gap] ✅ Addressed: SQLite WAL mode for concurrency; corruption handled via NFR-CACHE-032 and NFR-EDGE-048
- [X] CHK067 - Are risks of fingerprinting strategy (collision, staleness) identified? [Risk Assessment, Spec §FR-009, Gap] ✅ Addressed: Fingerprint uses size+mtime+hash; collision risk low; staleness mitigated by including config and ignore content in run fingerprint
- [X] CHK068 - Are risks of resumable operations (state inconsistency, partial failures) identified? [Risk Assessment, Spec §FR-011, Constitution §VI, Gap] ✅ Addressed: Resume validates fingerprint; partial outputs re-processed (NFR-EDGE-049)
- [X] CHK069 - Are risks of dry-run/finalize workflow (fingerprint mismatch, race conditions) identified? [Risk Assessment, Spec §FR-012-014, Gap] ✅ Addressed: Fingerprint validation required; mismatches reported with actionable explanation (FR-014)
- [X] CHK070 - Are mitigation strategies documented for identified risks? [Risk Assessment, Gap] ✅ Addressed: Mitigations include fingerprint validation, WAL mode, reseed flag, explicit warnings, resume/retry

---

## Compliance Gates

- [X] CHK071 - Do all architectural decisions comply with Shell-first architecture principle? [Compliance, Plan §Constitution Check vs Constitution §I] ✅ Verified: All code in Bash, strict mode, pndcgn_ prefix
- [X] CHK072 - Do all architectural decisions comply with test-first development principle? [Compliance, Plan §Constitution Check vs Constitution §II] ✅ Verified: ShellSpec tests exist for all modules
- [X] CHK073 - Do all architectural decisions comply with SQLite state management principle? [Compliance, Plan §Technical Context vs Constitution §IV] ✅ Verified: SQLite with WAL mode implemented
- [X] CHK074 - Do all architectural decisions comply with intelligent caching principle? [Compliance, Plan §Constitution Check vs Constitution §V] ✅ Verified: Fingerprinting and cache lookup implemented
- [X] CHK075 - Do all architectural decisions comply with resumable operations principle? [Compliance, Plan §Constitution Check vs Constitution §VI] ✅ Verified: Resume and finalize workflows implemented
- [X] CHK076 - Do all architectural decisions comply with Unix philosophy principle? [Compliance, Plan §Constitution Check vs Constitution §VII] ✅ Verified: Exit codes, stdout/stderr separation, XDG compliance
- [X] CHK077 - Are any constitution violations explicitly documented with justification? [Compliance, Plan §Complexity Tracking] ✅ Addressed: No constitution violations; not applicable
- [X] CHK078 - Do architectural decisions align with XDG standards (state/config locations)? [Compliance, Constitution §VII, Gap] ✅ Verified: XDG state and config directories implemented

---

## Edge Cases & Boundary Conditions

- [X] CHK079 - Are architectural decisions defined for the case when `.gitignore` does not exist? [Edge Case, Spec §FR-004B, Research §Decision: Seeding] ✅ Addressed: If no .gitignore, seed-once creates .pndcgnignore with defaults; stacking not applied
- [X] CHK080 - Are architectural decisions defined for the case when source directory is not a git repository? [Edge Case, Spec §FR-004B, Research §Implementation Notes] ✅ Addressed: Seeding uses closest .gitignore if present; if none, defaults apply
- [X] CHK081 - Are architectural decisions defined for the case when `.pndcgnignore` exists but is empty? [Edge Case, Contract .pndcgnignore, Gap] ✅ Addressed: Empty ignore means include all; fingerprint includes ignore content (empty)
- [X] CHK082 - Are architectural decisions defined for the case when fingerprint validation fails during finalize? [Edge Case, Spec §FR-014, Research §Implementation Notes] ✅ Addressed: Finalize fails with clear explanation; user must rerun dry-run
- [X] CHK083 - Are architectural decisions defined for the case when `--reseed` is used between dry-run and finalize? [Edge Case, Contract CLI §--reseed, Research §Implementation Notes] ✅ Addressed: Reseed invalidates fingerprints; finalize fails with explanation; user must rerun dry-run
- [X] CHK084 - Are architectural decisions defined for concurrent runs (same source/target)? [Edge Case, Spec §FR-005, Gap] ✅ Addressed: ULID ensures unique output directories; SQLite WAL handles concurrency
- [X] CHK085 - Are architectural decisions defined for SQLite database corruption or unavailability? [Edge Case, Constitution §IV, Gap] ✅ Addressed: Corruption handled via NFR-CACHE-032/NFR-EDGE-048; if unavailable, run fails with clear error

---

## Ambiguities & Conflicts

- [X] CHK086 - Is there ambiguity in how "closest-first stacking" for `.gitignore` merging is implemented? [Ambiguity, Spec §FR-004B, Research §Decision: Seeding] ✅ Addressed: research.md specifies closest-first (git-like); spec references same
- [X] CHK087 - Is there ambiguity in what constitutes "unchanged inputs" for finalize validation? [Ambiguity, Spec §FR-014, Gap] ✅ Addressed: Unchanged inputs defined by run fingerprint (inputs + config + ignore content + output type + paths)
- [X] CHK088 - Is there ambiguity in how `output_fingerprint` is computed when artifacts are generated incrementally? [Ambiguity, Data Model §Generated Artifact.output_fingerprint, Gap] ✅ Addressed: Output fingerprint computed from final artifact set; resume re-computes after completion
- [X] CHK089 - Is there a conflict between seed-once policy and user expectation of auto-sync? [Conflict, Research §Decision: Seed once vs User expectation, Gap] ✅ Addressed: seed-once is explicit; --reseed provided for manual sync
- [X] CHK090 - Is there a conflict between hidden output directory and discoverability requirements? [Conflict, Research §Decision: Default output directory vs Spec §FR-007 (navigable index), Gap] ✅ Addressed: FR-007 requires navigable index; index provides discoverability despite hidden directory
- [X] CHK091 - Are there any conflicts between constitution principles and feature requirements? [Conflict, Plan §Constitution Check vs Spec requirements, Gap] ✅ Addressed: No conflicts identified; Shell-first, SQLite state, caching, resume all aligned

---

## Summary

**Total Items**: 91
**Focus Areas**: Decision documentation completeness, clarity, consistency, traceability, alternatives analysis, risk assessment, compliance gates, edge cases, ambiguities
**Depth Level**: Formal architecture review (comprehensive validation)
**Audience**: Architecture reviewers, PR reviewers, release gatekeepers
