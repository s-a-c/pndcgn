# Implementation Plan: pndcgn Spec Consolidation

Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Branch**: `001-sync-docs-spec` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-sync-docs-spec/spec.md`

## Summary

Align implementation planning artifacts to the current consolidated spec for **pndcgn**, focusing on:

- Hidden run output directory default: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- `.pndcgnignore` lifecycle: discover at source root, seed-once from gitignore stacking (or built-in), never auto-update, explicit reseed action
- sqlite-ulid extension integration with Bash fallback for ULID generation
- Optional fzf integration for interactive source directory selection
- Output fingerprint format: `{total_size}:{artifact_count}:{sha256_of_all_content}`

See Phase 0 decisions in [research.md](./research.md).

## Technical Context

**Language/Version**: Bash (strict mode: `set -euo pipefail`)
**Primary Dependencies**: pandoc + sqlite3 + shellspec (test) + curl (for extension download)
**SQLite Extension**: sqlite-ulid v0.2.1 (auto-downloaded, Bash fallback if unavailable)
**Storage**: SQLite (persistent state/cache) with WAL mode
**Testing**: ShellSpec (BDD-style)
**Target Platform**: macOS + Linux (bash-based CLI)
**Project Type**: single CLI tool
**Performance Goals**: repeat run (no changes) ≥ 5× faster than first run (per spec SC-001)
**Constraints**: deterministic outputs; seed-once ignore; resumable runs; cache-first behavior; offline-capable (Bash ULID fallback)
**Scale/Scope**: source trees with many docs/assets; support incremental rebuilds

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Shell-first architecture: **PASS** (Bash-only core; namespacing required)
- Test-first development: **PASS** (ShellSpec; tests required before implementation)
- Documentation-driven design: **PASS** (spec and docs drive implementation)
- State via SQLite: **PASS** (persistent cache/state in SQLite with sqlite-ulid extension)
- Intelligent caching + resumable operations: **PASS** (required by spec and constitution)
- Unix philosophy: **PASS** (XDG-compliant paths, composable CLI, text in/out)

Notes:

- `.pndcgnignore` is treated as configuration (not state). Auto-creating it is an explicit, documented side effect.
- sqlite-ulid extension is optional; Bash fallback ensures offline operation capability.
- fzf integration is optional; tool functions without it.

## Project Structure

### Documentation (this feature)

```text
specs/001-sync-docs-spec/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── cli.md
│   └── pndcgnignore.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
bin/
└── pndcgn                     # primary entrypoint

src/
├── constants.sh                # ANSI codes, shared constants
├── database.sh                 # SQLite operations, extension loading
├── processing.sh               # Conversion logic, fingerprinting
└── utilities.sh                # Helper functions (ULID fallback, paths, logging)

lib/                            # Auto-created directory for sqlite-ulid extension
└── ulid0.so/.dylib            # Downloaded extension (platform-specific)

tests/
├── config_spec.sh
├── constants_spec.sh
├── database_spec.sh
├── processing_spec.sh
├── utilities_spec.sh
├── pndcgn_spec.sh              # Main controller tests
├── spec_helper.sh
└── README.md

docs/
└── (project documentation)
```

**Structure Decision**: single CLI tool, shell-based modules under `src/`, executable entrypoint under `bin/`, ShellSpec tests under `tests/`, extension storage in `lib/` directory.

## Complexity Tracking

No constitution violations are required by this plan.

## Phased Delivery Schedule

Based on triage of 275 identified gaps (see spec.md NFR sections), delivery is organized into four phases:

### Phase Summary

| Phase | Priority | NFR Count | Focus | Target |
|-------|----------|-----------|-------|--------|
| **P1-MVP** | Critical | 32 | Core reliability, crash safety, data integrity | Required for release |
| **P2** | High | 86 | Common edge cases, error handling, UX | Release candidate |
| **P3** | Medium | 114 | Polish, edge cases, robustness | Post-release enhancement |
| **P4+** | Low | 43 | Nice-to-have, future enhancements | Future roadmap |

### Phase 1: MVP (Critical) - 32 NFRs

**Goal**: System is crash-safe, data-safe, and usable in CI/automation environments.

#### CLI (4 NFRs)
- NFR-CLI-013: Non-TTY stdout handling (disable interactive features)
- NFR-CLI-014: NO_COLOR environment variable support
- NFR-CLI-027: Non-interactive mode requires --yes for destructive ops
- NFR-CLI-048: SIGINT (Ctrl+C) graceful shutdown

#### Caching (12 NFRs)
- NFR-CACHE-001/002/003: Fingerprint edge cases (small files, empty files, mtime precision)
- NFR-CACHE-007/008: Deterministic fingerprint ordering
- NFR-CACHE-022/023: Database permissions and corruption recovery
- NFR-CACHE-029/030/031/032: Run state machine transitions

#### Edge Cases (12 NFRs)
- NFR-EDGE-018: Disk full handling
- NFR-EDGE-024: File changes during processing detection
- NFR-EDGE-041/042/043/045/046/047/048: Signal handling (SIGINT, SIGTERM, SIGKILL, trap handlers)
- NFR-EDGE-073/074: Resource exhaustion (memory, disk)

#### TOML Config (4 NFRs)
- NFR-TOML-006: Config in run fingerprint
- NFR-TOML-044/045: Include/exclude pattern evaluation order
- NFR-TOML-048/049: Config change detection during dry-run/resume

### Phase 2: High Priority - 86 NFRs

**Goal**: Robust error handling, clear UX, common edge cases covered.

#### CLI (16 NFRs)
- Help text structure, version display, verbose mode
- Run ID display format, timing/duration format
- Confirmation prompts, final summary output
- Error messages with actionable guidance

#### Caching (18 NFRs)
- File delete/rename/move handling
- Database schema versioning and migration
- Resume edge cases (completed/failed/dry-run)
- Dry-run expiration and multiple pending

#### Edge Cases (32 NFRs)
- Source/target directory edge cases
- Symlink handling (normal, broken, circular)
- Input file edge cases (empty, binary, permissions)
- Concurrent operations and resume edge cases
- External dependency failures

#### TOML Config (20 NFRs)
- Pattern syntax (wildcards, character classes)
- Extension syntax (case, compound)
- TOML parsing (multi-line, comments, duplicates)
- Error handling with line numbers

### Phase 3: Medium Priority - 114 NFRs

**Goal**: Polish, additional edge cases, improved robustness.

#### CLI (26 NFRs)
- Quiet mode, stdin/pipe input
- Terminal handling (TERM, wrapping)
- Progress indicators (spinner, file count, update frequency)
- Statistics formatting, column alignment
- fzf integration details

#### Caching (22 NFRs)
- Advanced fingerprint details (mtime timezone, delimiter)
- Output fingerprint edge cases
- Database transaction boundaries
- ULID details, cache metrics display
- Cleanup progress and interruption

#### Edge Cases (36 NFRs)
- Path edge cases (trailing slash, special chars)
- File edge cases (encoding, BOM, long names)
- Resource limits documentation
- Network mount, read-only filesystem

#### TOML Config (30 NFRs)
- Brace expansion, escape sequences
- Validation error formats
- Pattern precedence details
- Edge cases (large config, Unicode)
- Documentation (rationale, defaults)

### Phase 4+: Low Priority - 43 NFRs

**Goal**: Nice-to-have features, future enhancements.

- Man page documentation
- Accessibility (screen reader, colorblind)
- ETA display
- Cache warming/preloading
- Historical metrics
- Cleanup audit trail
- Migration/troubleshooting examples

## Implementation Notes

### P1-MVP Implementation Order

1. **Signal handling first**: Install trap handlers early in bin/pndcgn
2. **Database safety**: Implement corruption detection and recovery in src/database.sh
3. **Fingerprint determinism**: Ensure sorted ordering in src/processing.sh
4. **Non-interactive mode**: Check for TTY and NO_COLOR in src/utilities.sh
5. **Config fingerprinting**: Include TOML content in run fingerprint

### Technical Considerations

#### Signal Handling (NFR-EDGE-041-048)
```bash
# In bin/pndcgn
trap 'pndcgn_handle_interrupt' INT TERM
trap 'pndcgn_cleanup_on_exit' EXIT

pndcgn_handle_interrupt() {
    pndcgn_log_warn "Interrupted, saving checkpoint..."
    pndcgn_save_checkpoint
    pndcgn_mark_run_interrupted "$PNDCGN_RUN_ID"
    exit 130  # 128 + SIGINT(2)
}
```

#### Non-TTY Detection (NFR-CLI-013, NFR-CLI-027)
```bash
# In src/utilities.sh
pndcgn_is_interactive() {
    [[ -t 0 && -t 1 ]]  # stdin and stdout are TTYs
}

pndcgn_require_confirmation() {
    if ! pndcgn_is_interactive && [[ "${PNDCGN_YES:-}" != "1" ]]; then
        pndcgn_fail "Non-interactive mode requires --yes flag for destructive operations"
    fi
}
```

#### Database Corruption Recovery (NFR-CACHE-023)
```bash
# In src/database.sh
pndcgn_db_init() {
    if ! sqlite3 "$PNDCGN_DB" "PRAGMA integrity_check;" | grep -q "^ok$"; then
        local backup="${PNDCGN_DB}.corrupted.$(date +%s)"
        pndcgn_log_error "Database corrupted, backing up to: $backup"
        mv "$PNDCGN_DB" "$backup"
        pndcgn_db_create_fresh
    fi
}
```

#### Fingerprint Sorting (NFR-CACHE-007, NFR-CACHE-008)
```bash
# In src/processing.sh
pndcgn_compute_run_fingerprint() {
    local input_fingerprints
    input_fingerprints=$(
        find "$SOURCE_DIR" -type f -print0 | 
        sort -z |  # Sort by path for determinism
        while IFS= read -r -d '' file; do
            pndcgn_compute_fingerprint "$file"
        done
    )
    # Combine with config state
    echo "${input_fingerprints}|${PNDCGN_OUTPUT_TYPE}|${config_hash}" | sha256sum | cut -d' ' -f1
}
```

### Testing Strategy by Phase

| Phase | Test Focus | Coverage Target |
|-------|------------|-----------------|
| P1-MVP | Crash safety, signal handling, data integrity | 70% |
| P2 | Error messages, edge cases, UX flows | 60% |
| P3 | Polish, additional edge cases | 50% |
| P4+ | Documentation, examples | N/A |

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Signal handling complexity | Test with `kill -INT` and `kill -TERM` in CI |
| Database corruption | Use SQLite WAL mode, test with simulated corruption |
| Fingerprint non-determinism | Unit tests with fixed file sets, assert exact hashes |
| Non-TTY edge cases | CI runs are non-interactive by default |
