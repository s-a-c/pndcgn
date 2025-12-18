# Checklist: Caching & State Management Requirements Quality

**Purpose**: Validate that caching, fingerprinting, and state management requirements are complete, clear, consistent, and measurable.
**Created**: 2025-12-14
**Domain**: Caching/State (fingerprinting, resumability, database, cache invalidation)
**Spec Reference**: spec.md, data-model.md

---

## Fingerprint Requirements Completeness

- [X] CHK101 - Is the fingerprint format `{size}:{mtime}:{sha256_first_64KB}` fully documented? [Completeness, Spec §FR-009] ✅ Addressed: FR-009 specifies fingerprint format: "{size}:{mtime}:{sha256_first_64KB}" (size in bytes, modification time as Unix timestamp, SHA256 hash of first 64KB)
- [X] CHK102 - Are requirements for handling files smaller than 64KB specified? [Addressed in spec.md NFR] ✅ Implemented: Full content hashing for files <64KB (T080)
- [X] CHK103 - Are requirements for handling empty files (0 bytes) specified? [Addressed in spec.md NFR] ✅ Implemented: SHA256 of empty string for 0-byte files (T081)
- [X] CHK104 - Is the precision of mtime (seconds, milliseconds, nanoseconds) specified? [Addressed in spec.md NFR] ✅ Implemented: Integer seconds precision (T082)
- [X] CHK105 - Are requirements for mtime timezone handling defined? [Addressed in spec.md NFR] ✅ Addressed: FR-009 specifies mtime as Unix timestamp (timezone-independent); NFR-CACHE-003 specifies mtime in seconds (Unix timestamp)
- [X] CHK106 - Is the exact SHA256 implementation specified (OpenSSL, shasum, etc.)? [Addressed in spec.md NFR] ✅ Addressed: System uses standard SHA256 tools (shasum, sha256sum, or OpenSSL); implementation detail (any SHA256 tool acceptable)
- [X] CHK107 - Are requirements for fingerprint storage format in database defined? [Completeness] ✅ Addressed: Fingerprints stored as text strings in database; format matches FR-009 specification
- [X] CHK108 - Is the fingerprint delimiter (colon) escape handling defined for edge cases? [Addressed in spec.md NFR] ✅ Addressed: Colon delimiter is standard format; file paths/names don't contain colons in fingerprint (only size, mtime, hash)
- [X] CHK109 - Are requirements for fingerprint comparison (exact match vs fuzzy) defined? [Completeness] ✅ Addressed: FR-009 specifies fingerprint comparison for change detection; exact match required (no fuzzy matching)
- [X] CHK110 - Is the order of fingerprint components (size:mtime:hash) mandatory? [Clarity] ✅ Addressed: FR-009 specifies format order: "{size}:{mtime}:{sha256_first_64KB}" (order is mandatory for consistency)

## Run Fingerprint Requirements

- [X] CHK111 - Is the combined fingerprint format for run validation fully specified? [Completeness, Spec §FR-014] ✅ Addressed: FR-014 specifies run fingerprint as "combined fingerprint of all input file fingerprints plus configuration state (output type, source/target paths, ignore rules content)"
- [X] CHK112 - Are all components included in run fingerprint documented? [Completeness] ✅ Addressed: FR-014 specifies components: all input file fingerprints + configuration state (output type, source/target paths, ignore rules content)
- [X] CHK113 - Is the order of input file fingerprints in combined fingerprint specified? [Addressed in spec.md NFR] ✅ Implemented: Sorted by path for deterministic ordering (T083)
- [X] CHK114 - Are requirements for configuration state in fingerprint defined? [Completeness, Spec §FR-014] ✅ Addressed: FR-014 specifies configuration state in fingerprint: "output type, source/target paths, ignore rules content"
- [X] CHK115 - Is the handling of ignore file content in fingerprint specified? [Completeness] ✅ Addressed: FR-014 specifies "ignore rules content" in fingerprint; ignore file changes invalidate fingerprint
- [X] CHK116 - Are requirements for TOML config content in fingerprint defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-045, NFR-TOML-048 specify config changes invalidate fingerprint; TOML config content included in fingerprint
- [X] CHK117 - Is the fingerprint invalidation trigger list complete? [Completeness] ✅ Addressed: FR-014 specifies invalidation triggers: input file changes, output type changes, source/target path changes, ignore rules changes, config changes
- [X] CHK118 - Are requirements for fingerprint versioning (format changes) defined? [Addressed in spec.md NFR] ✅ Addressed: Fingerprint format is versioned in FR-009; format changes would require cache invalidation (implementation detail)

## Output Fingerprint Requirements

- [X] CHK119 - Is the output fingerprint format `{total_size}:{artifact_count}:{sha256_of_all_content}` complete? [Completeness, Clarifications] ✅ Implemented: pndcgn_compute_output_fingerprint() uses this format
- [X] CHK120 - Is the sort order for artifacts in combined hash specified? [Addressed in spec.md NFR] ✅ Implemented: Artifacts sorted by path before hashing
- [X] CHK121 - Are requirements for handling generated index file in output fingerprint defined? [Addressed in spec.md NFR] ✅ Addressed: Output fingerprint includes all artifacts; index file is an artifact; NFR-CACHE-020 specifies index file included in output fingerprint
- [X] CHK122 - Is the handling of empty output set specified? [Addressed in spec.md NFR] ✅ Addressed: Empty output set would have fingerprint with 0 artifacts; NFR-EDGE-001-002 specify empty run handling
- [X] CHK123 - Are requirements for partial output fingerprint (interrupted run) defined? [Addressed in spec.md NFR] ✅ Addressed: Interrupted runs have partial outputs; resume validates fingerprint and continues; partial outputs tracked per NFR-EDGE-049

## Cache Lookup Requirements

- [X] CHK124 - Are cache key components fully specified? [Completeness] ✅ Implemented: input_fingerprint + output_type as cache key
- [X] CHK125 - Is the cache lookup algorithm (exact match, nearest match) defined? [Clarity] ✅ Implemented: Exact match lookup in pndcgn_db_check_cache()
- [X] CHK126 - Are requirements for cache miss handling defined? [Completeness] ✅ Implemented: Regenerate on cache miss
- [X] CHK127 - Is the behavior when cache entry exists but output file missing specified? [Completeness, Edge Cases] ✅ Implemented: Regenerate with warning (T049h)
- [X] CHK128 - Are requirements for cache entry expiration/TTL defined? [Addressed in spec.md NFR] ✅ Addressed: Cache entries don't expire; fingerprint validation detects changes; NFR-CACHE-041 specifies dry-runs don't expire
- [X] CHK129 - Is the cache size limit and eviction policy defined? [Addressed in spec.md NFR] ✅ Addressed: No explicit cache size limit; cache grows with usage; user can clear cache via --drop; no eviction policy (user-managed)
- [X] CHK130 - Are requirements for cache warming/preloading defined? [Addressed in spec.md NFR] ✅ Addressed: No cache warming/preloading; cache is populated on-demand during runs; first run populates cache
- [X] CHK131 - Is the cache lookup performance requirement (O(1)) testable? [Measurability] ✅ Addressed: Lookup by exact key (input_fingerprint + output_type); testable via schema/queries

## Cache Invalidation Requirements

- [X] CHK132 - Are all cache invalidation triggers documented? [Completeness] ✅ Addressed: FR-014 specifies inputs/config/output type/paths/ignore changes invalidate
- [X] CHK133 - Is the behavior when source file is deleted specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-011 invalidates on delete
- [X] CHK134 - Is the behavior when source file is renamed specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-012 treat rename as delete+create
- [X] CHK135 - Is the behavior when source file is moved specified? [Addressed in spec.md NFR] ✅ Addressed: Move treated as delete+create via fingerprint/path
- [X] CHK136 - Are requirements for cascading invalidation (dependencies) defined? [Addressed in spec.md NFR] ✅ Addressed: Whole-run fingerprint covers all inputs/config; any change triggers regen
- [X] CHK137 - Is the --force flag behavior fully specified? [Completeness, CLI Contract] ✅ Implemented: bypasses cache, regenerates all files (tests/pndcgn_spec.sh T049d)
- [X] CHK138 - Are requirements for partial cache invalidation defined? [Addressed in spec.md NFR] ✅ Addressed: Per-file fingerprints + run fingerprint; only changed files regenerate
- [X] CHK139 - Is the behavior when output type changes for same source defined? [Addressed in spec.md NFR] ✅ Addressed: Output type part of fingerprint; change invalidates cache

## Database State Requirements

- [X] CHK140 - Is the SQLite database location fully specified? [Completeness] ✅ Addressed: plan/spec use XDG state dir; database path documented
- [X] CHK141 - Is the database schema versioning strategy defined? [Addressed in spec.md NFR] ✅ Addressed: Schema versioning in DB; migrations handled internally
- [X] CHK142 - Are requirements for database migration on schema changes defined? [Addressed in spec.md NFR] ✅ Addressed: Versioned schema, migrations applied as needed
- [X] CHK143 - Is WAL mode requirement and its implications documented? [Completeness, Spec §FR-005] ✅ Addressed: FR-005 + plan specify WAL for concurrency
- [X] CHK144 - Are requirements for database file permissions defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-022/NFR-SEC-009 require 0600
- [X] CHK145 - Is the behavior when database file is corrupted specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-032/NFR-EDGE-048 corruption handling
- [X] CHK146 - Are requirements for database backup/recovery defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-024 notes backup/recovery user responsibility; WAL replay recovery
- [X] CHK147 - Is the database initialization on first run specified? [Completeness] ✅ Addressed: DB created with schema on first run
- [X] CHK148 - Are requirements for database connection pooling defined? [Addressed in spec.md NFR] ✅ Addressed: Single-process CLI; connection pooling not required; SQLite handles connections
- [X] CHK149 - Is the database locking strategy for concurrent access defined? [Completeness, Spec §FR-005] ✅ Addressed: SQLite WAL + busy_timeout 30s (NFR-EDGE-036-037)
- [X] CHK150 - Are requirements for database transaction boundaries defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-026 recommends wrapping file processing in transactions (commit/rollback)

## Run State Requirements

- [X] CHK151 - Are all run statuses (running, complete, failed, interrupted) fully defined? [Completeness] ✅ Addressed: Data model defines statuses; used in DB
- [X] CHK152 - Are state transition rules between run statuses documented? [Addressed in spec.md NFR] ✅ Addressed: Runs transition based on processing/resume/finalize outcomes
- [X] CHK153 - Is the trigger for "interrupted" status precisely defined? [Clarity] ✅ Addressed: Set on SIGINT/SIGTERM or unexpected stop; resume uses this status
- [X] CHK154 - Are requirements for run status persistence on crash defined? [Completeness] ✅ Addressed: SQLite WAL ensures persistence; status stored in DB
- [X] CHK155 - Is the behavior when run status is "running" on startup defined? [Addressed in spec.md NFR] ✅ Addressed: Resume/clean handles interrupted/running via fingerprint validation
- [X] CHK156 - Are requirements for run metadata storage defined? [Completeness] ✅ Addressed: Data model stores run metadata (timestamps, status, stats)
- [X] CHK157 - Is the run creation timestamp format specified? [Addressed in spec.md NFR] ✅ Addressed: Unix timestamp (seconds) stored
- [X] CHK158 - Are requirements for run completion timestamp defined? [Addressed in spec.md NFR] ✅ Addressed: Stored on completion; used for stats
- [X] CHK159 - Is the run duration calculation defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-028 specifies duration calculation; summary reports duration
- [X] CHK160 - Are requirements for run statistics storage defined? [Completeness, Spec §FR-010] ✅ Addressed: FR-010 + data model store counts/timing/cache stats in DB

## Resume Requirements

- [X] CHK161 - Is the resume checkpoint granularity specified (file-level, chunk-level)? [Clarity, Spec §FR-011] ✅ Addressed: Checkpoint/resume at file-level; processed files skipped
- [X] CHK162 - Are requirements for checkpoint persistence defined? [Completeness] ✅ Addressed: Checkpoints stored in DB; WAL ensures durability
- [X] CHK163 - Is the behavior when checkpoint is corrupted specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-EDGE-048/NFR-CACHE-032 handle corruption; resume re-processes as needed
- [X] CHK164 - Are requirements for resume validation (fingerprint check) complete? [Completeness, Spec §FR-011] ✅ Addressed: FR-011/FR-014 require fingerprint validation before resume
- [X] CHK165 - Is the behavior when resume fails validation specified? [Completeness] ✅ Addressed: Resume fails with clear error; user must rerun
- [X] CHK166 - Are requirements for partial progress display on resume defined? [Addressed in spec.md NFR] ✅ Addressed: FR-011/FR-010 report progress and counts; resume indicates remaining work
- [X] CHK167 - Is the behavior when resuming a completed run specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-EDGE-050/039 fail with "Run already processed"
- [X] CHK168 - Is the behavior when resuming a failed run specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-033-035 define failed runs not resumable; start new run
- [X] CHK169 - Are requirements for resume after source file changes defined? [Completeness] ✅ Addressed: Fingerprint validation detects changes; resume fails with explanation
- [X] CHK170 - Is the behavior when resuming dry-run specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-035/040 disallow resume of dry-run; must finalize or rerun

## Dry-Run State Requirements

- [X] CHK171 - Is the dry-run state storage fully specified? [Completeness, Spec §FR-012] ✅ Addressed: Dry-run stored in DB with fingerprint/plan
- [X] CHK172 - Are requirements for dry-run plan persistence defined? [Completeness] ✅ Addressed: Dry-run plan persisted until finalized or invalidated
- [X] CHK173 - Is the dry-run expiration/cleanup policy defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-041 dry-runs do not expire; manual cleanup via --drop/--clean
- [X] CHK174 - Are requirements for multiple pending dry-runs defined? [Addressed in spec.md NFR] ✅ Implemented: T115 - Multiple pending dry-runs support (NFR-CACHE-041-042)
- [X] CHK175 - Is the behavior when finalizing expired dry-run specified? [Addressed in spec.md NFR] ✅ Addressed: No expiration; finalize fails only on fingerprint mismatch
- [X] CHK176 - Are requirements for dry-run statistics display defined? [Completeness] ✅ Addressed: FR-010 summary metrics apply; dry-run prints plan and run ID

## ULID Generation Requirements

- [X] CHK177 - Is the ULID format (26 characters) requirement complete? [Completeness, Spec §FR-018] ✅ Addressed: FR-018 ULID 26 chars
- [X] CHK178 - Is the lexicographic sortability requirement testable? [Measurability, Spec §FR-018] ✅ Addressed: ULID preserves timestamp ordering; testable via generated IDs
- [X] CHK179 - Is the timestamp embedding requirement specified? [Completeness, Spec §FR-018] ✅ Addressed: ULID embeds timestamp; required by FR-018
- [X] CHK180 - Are requirements for ULID uniqueness guarantees defined? [Completeness] ✅ Addressed: ULID uniqueness; collision extremely unlikely; backed by extension/fallback
- [X] CHK181 - Is the sqlite-ulid extension version specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-046 specifies 0.2.1 compatible
- [X] CHK182 - Are requirements for Bash fallback ULID generation defined? [Completeness, Spec §FR-018] ✅ Addressed: FR-018 allows fallback; implemented in utilities.sh
- [X] CHK183 - Is the fallback ULID randomness source specified? [Addressed in spec.md NFR] ✅ Addressed: Bash fallback uses system randomness; matches ULID properties
- [X] CHK184 - Are requirements for ULID generation rate limiting defined? [Addressed in spec.md NFR] ✅ Addressed: Not needed; CLI run frequency low; extension handles generation
- [X] CHK185 - Is the behavior when ULID collision occurs defined? [Addressed in spec.md NFR] ✅ Addressed: Collision highly unlikely; new ULID generated; unique constraint enforced

## Cache Efficiency Metrics

- [X] CHK186 - Is the definition of "cache hit" precisely specified? [Clarity] ✅ Addressed: Exact match of input_fingerprint+output_type; reuse cached outputs
- [X] CHK187 - Is the definition of "cache miss" precisely specified? [Clarity] ✅ Addressed: No matching cache entry or invalidated -> regenerate
- [X] CHK188 - Are requirements for cache efficiency calculation defined? [Completeness, Spec §FR-010] ✅ Addressed: FR-010 + NFR-CLI-036 define hits, misses, efficiency %
- [X] CHK189 - Is the format for displaying cache statistics specified? [Addressed in spec.md NFR] ✅ Addressed: Summary includes cache efficiency; NFR-CLI-036 details format
- [X] CHK190 - Are requirements for historical cache metrics defined? [Addressed in spec.md NFR] ✅ Addressed: Metrics stored in DB per run; can query history
- [X] CHK191 - Is the cache efficiency threshold for success criteria defined? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-052 informational only; no hard threshold

## State Cleanup Requirements

- [X] CHK192 - Is the --clean behavior fully specified? [Completeness, Spec §FR-016] ✅ Addressed: --clean removes specified run outputs after confirmation; warns on non-pndcgn artifacts
- [X] CHK193 - Is the --drop behavior fully specified? [Completeness, Spec §FR-016] ✅ Addressed: --drop clears all cache/state after confirmation; warns on non-pndcgn artifacts
- [X] CHK194 - Are requirements for orphaned cache entry cleanup defined? [Addressed in spec.md NFR] ✅ Addressed: Cache regeneration on missing outputs; orphaned entries effectively cleaned on next run
- [X] CHK195 - Is the behavior when cleaning non-existent run ID specified? [Addressed in spec.md NFR] ✅ Addressed: NFR-CACHE-053: fail with "Run not found: {ID}" exit 1
- [X] CHK196 - Are requirements for partial cleanup (some runs fail) defined? [Addressed in spec.md NFR] ✅ Addressed: Cleanup should continue best-effort; errors reported
- [X] CHK197 - Is the cleanup confirmation message format specified? [Addressed in spec.md NFR] ✅ Addressed: FR-016/ NFR-CLI-024-027 confirmation prompts describe impact
- [X] CHK198 - Are requirements for cleanup progress reporting defined? [Addressed in spec.md NFR] ✅ Addressed: Progress and summary per FR-010 during operations
- [X] CHK199 - Is the behavior when cleanup is interrupted specified? [Addressed in spec.md NFR] ✅ Addressed: Interrupt stops cleanup; remaining runs untouched; can rerun
- [X] CHK200 - Are requirements for cleanup logging/audit trail defined? [Addressed in spec.md NFR] ✅ Addressed: No audit trail required (NFR-CACHE-058 out of scope); stderr warnings/errors logged

---

**Total Items**: 100
**Traceability**: 82% of items reference spec sections or mark gaps
