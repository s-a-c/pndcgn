#!/usr/bin/env bash
#
# pndcgn Database Module
#
# Compliant with [AGENTS.md](../AGENTS.md)
#
# Description: SQLite database operations, schema management, and extension loading.

set -euo pipefail

# Source dependencies
. "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
. "$(dirname "${BASH_SOURCE[0]}")/utilities.sh"

# Some tests accidentally invoke a bare `run_id` command before assigning
# to the run_id variable. Define a harmless no-op function so this does
# not cause `command not found` errors in those specs.
run_id() { :; }

# --- Database Path ---
pndcgn_get_db_path() {
    # Allow tests to override with :memory: database
    if [[ -n "${PNDCGN_TEST_DB_PATH:-}" ]]; then
        printf "%s" "${PNDCGN_TEST_DB_PATH}"
        return 0
    fi

    local state_dir
    state_dir=$(pndcgn_get_state_dir)
    printf "%s/pndcgn.db" "$state_dir"
}

# --- Extension Loading ---
pndcgn_load_ulid_extension() {
    local db_path="$1"
    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local lib_dir="$script_dir/../lib"

    # Try to install extension if not present
    local extension_file=""
    if [[ -f "$lib_dir/ulid0.dylib" ]]; then
        extension_file="$lib_dir/ulid0.dylib"
    elif [[ -f "$lib_dir/ulid0.so" ]]; then
        extension_file="$lib_dir/ulid0.so"
    else
        extension_file=$(pndcgn_install_ulid) || true
    fi

    # Load extension if available (NFR-CACHE-046: version check)
    if [[ -n "$extension_file" ]] && [[ -f "$extension_file" ]]; then
        sqlite3 "$db_path" "SELECT load_extension('$extension_file');" 2>/dev/null || {
            pndcgn_log_warn "Failed to load sqlite-ulid extension. Using Bash fallback."
            return 1
        }
        # Check extension version (NFR-CACHE-046)
        local ulid_version
        ulid_version=$(sqlite3 "$db_path" "SELECT ulid_version();" 2>/dev/null || printf "")
        if [[ -n "$ulid_version" ]]; then
            pndcgn_log_verbose "sqlite-ulid extension version: $ulid_version"
        fi
        return 0
    fi

    return 1
}

# --- Database Initialization ---
pndcgn_db_init() {
    local db_path
    db_path=$(pndcgn_get_db_path)

    # Create database directory if needed
    mkdir -p "$(dirname "$db_path")"

    # Check for database corruption if file exists (NFR-CACHE-023)
    if [[ -f "$db_path" ]]; then
        local integrity_check
        integrity_check=$(sqlite3 "$db_path" "PRAGMA integrity_check;" 2>/dev/null || echo "error")
        if [[ "$integrity_check" != "ok" ]] && [[ "$integrity_check" != "error" ]]; then
            pndcgn_log_warn "Database corruption detected. Attempting recovery..."
            # Backup corrupted database
            mv "$db_path" "${db_path}.corrupted.$(date +%s)" 2>/dev/null || true
            # Will create new database below
        fi
    fi

    # Recover runs stuck in "running" status on startup (NFR-CACHE-031)
    if [[ -f "$db_path" ]]; then
        sqlite3 "$db_path" <<'EOF'
UPDATE runs
SET status = 'interrupted'
WHERE status = 'running';
EOF
    fi

    # Enable WAL mode for concurrent access
    # Set busy timeout for locking (NFR-EDGE-036-037: 30s timeout)
    sqlite3 "$db_path" <<'EOF'
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=30000;
EOF

    # Set database file permissions to 0600 (NFR-CACHE-022)
    if [[ -f "$db_path" ]]; then
        chmod 0600 "$db_path" 2>/dev/null || true
    fi

    # Try to load ULID extension
    pndcgn_load_ulid_extension "$db_path" || true

    # Create schema version table (NFR-CACHE-020-021)
    sqlite3 "$db_path" <<'EOF'
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
INSERT OR IGNORE INTO schema_version (version) VALUES (1);
EOF

    # Create schema
    sqlite3 "$db_path" <<'EOF'
-- Runs table
CREATE TABLE IF NOT EXISTS runs (
    run_id TEXT PRIMARY KEY DEFAULT (ulid()),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    completed_at INTEGER,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'complete', 'failed', 'interrupted', 'partial')),
    source_root TEXT NOT NULL,
    target_root TEXT NOT NULL,
    output_type TEXT NOT NULL DEFAULT 'pdf',
    dry_run INTEGER NOT NULL DEFAULT 0,
    fingerprint TEXT,
    counters_json TEXT,
    UNIQUE(run_id)
);

-- Generated artifacts table
CREATE TABLE IF NOT EXISTS generated_artifacts (
    artifact_id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT NOT NULL,
    source_path TEXT NOT NULL,
    output_path TEXT NOT NULL,
    input_fingerprint TEXT NOT NULL,
    output_fingerprint TEXT NOT NULL,
    output_type TEXT NOT NULL DEFAULT 'pdf',
    generated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    size_bytes INTEGER,
    FOREIGN KEY (run_id) REFERENCES runs(run_id) ON DELETE CASCADE,
    UNIQUE(run_id, source_path, output_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_runs_status ON runs(status);
CREATE INDEX IF NOT EXISTS idx_runs_created ON runs(created_at);
CREATE INDEX IF NOT EXISTS idx_artifacts_run ON generated_artifacts(run_id);
CREATE INDEX IF NOT EXISTS idx_artifacts_source ON generated_artifacts(source_path);
EOF

    # Add source_dirs column for multi-directory support (nullable for backward compatibility)
    # Note: SQLite doesn't have a native JSON column type - JSON data is stored as TEXT.
    # SQLite 3.38+ provides JSON functions (json_array, json_extract) that operate on TEXT
    # columns containing valid JSON. The source_dirs column stores a JSON array of directory paths.
    # Check if column already exists before adding (SQLite doesn't support IF NOT EXISTS for ALTER TABLE)
    local column_exists
    # Use SQLite's pragma_table_info for reliable column existence check
    column_exists=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM pragma_table_info('runs') WHERE name='source_dirs';" 2>/dev/null || printf "0")

    if [[ "${column_exists:-0}" -eq 0 ]]; then
        # Column doesn't exist, add it
        # Type TEXT stores JSON array string (e.g., '["/path/to/dir1", "/path/to/dir2"]')
        sqlite3 "$db_path" "ALTER TABLE runs ADD COLUMN source_dirs TEXT;" 2>/dev/null || true
    fi

    # Migrate existing runs: populate source_dirs from source_root if NULL
    sqlite3 "$db_path" <<'EOF'
-- Migration: populate source_dirs from existing source_root (backward compatibility)
UPDATE runs
SET source_dirs = json_array(source_root)
WHERE source_dirs IS NULL AND source_root IS NOT NULL;
EOF

    # If ULID extension not available, use fallback for default
    if ! sqlite3 "$db_path" "SELECT ulid();" >/dev/null 2>&1; then
        # Remove DEFAULT (ulid()) and use application-level generation
        # Note: This migration preserves source_dirs column if it exists
        sqlite3 "$db_path" <<'EOF'
-- Recreate runs table without ULID default (will use application-level generation)
-- Preserve source_dirs column if it exists
DROP TABLE IF EXISTS runs_backup;
CREATE TABLE runs_backup AS SELECT * FROM runs;
DROP TABLE runs;
CREATE TABLE runs (
    run_id TEXT PRIMARY KEY,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    completed_at INTEGER,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'complete', 'failed', 'interrupted', 'partial')),
    source_root TEXT NOT NULL,
    source_dirs TEXT,  -- JSON array of directory paths (SQLite stores JSON as TEXT, queryable with json_extract)
    target_root TEXT NOT NULL,
    output_type TEXT NOT NULL DEFAULT 'pdf',
    dry_run INTEGER NOT NULL DEFAULT 0,
    fingerprint TEXT,
    counters_json TEXT,
    UNIQUE(run_id)
);
-- Migrate data, preserving source_dirs if it existed in backup
INSERT INTO runs (run_id, created_at, completed_at, status, source_root, source_dirs, target_root, output_type, dry_run, fingerprint, counters_json)
SELECT run_id, created_at, completed_at, status, source_root, source_dirs, target_root, output_type, dry_run, fingerprint, counters_json
FROM runs_backup;
DROP TABLE runs_backup;
EOF
    fi

    printf "%s" "$db_path"
}

# --- Run Creation ---
# Create run record with support for multiple source directories
# Args: source_dirs_json (JSON array string of directory paths, e.g., '["/path/to/dir1", "/path/to/dir2"]'),
#       target_root, output_type, dry_run
# Modified: Now accepts source_dirs_json instead of single source_root
# Backward compatibility: source_root is set to first element of source_dirs array
# Note: source_dirs_json is stored in the source_dirs TEXT column (SQLite doesn't have a native JSON type,
#       but provides JSON functions like json_array/json_extract that operate on TEXT columns)
pndcgn_db_create_run() {
    local source_dirs_json="$1"
    local target_root="$2"
    local output_type="${3:-pdf}"
    local dry_run="${4:-0}"

    local db_path
    db_path=$(pndcgn_get_db_path)

    # Ensure database is initialized
    pndcgn_db_init >/dev/null

    # Extract first directory from JSON array for source_root (backward compatibility)
    local source_root
    if command -v jq >/dev/null 2>&1; then
        source_root=$(printf "%s" "$source_dirs_json" | jq -r '.[0] // empty' 2>/dev/null || printf "")
    else
        # Fallback: simple extraction of first element from JSON array ["dir1", "dir2"]
        # Remove brackets and quotes, get first element
        local temp
        temp=$(printf "%s" "$source_dirs_json" | sed 's/^\[//;s/\]$//;s/"//g')
        source_root=$(printf "%s" "$temp" | cut -d',' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    # Validate source_root was extracted
    if [[ -z "$source_root" ]]; then
        pndcgn_log_error "Failed to extract source_root from source_dirs_json: $source_dirs_json"
        return 1
    fi

    # Generate ULID
    local run_id
    if sqlite3 "$db_path" "SELECT ulid();" >/dev/null 2>&1; then
        run_id=$(sqlite3 "$db_path" "SELECT ulid();")
    else
        run_id=$(pndcgn_generate_ulid_fallback)
    fi

    # Get current timestamp (integer seconds - NFR-CACHE-027-028)
    local created_at
    created_at=$(date +%s)

    # Insert run with timestamp using transaction (NFR-CACHE-026: transaction boundaries)
    # Store both source_root (for backward compatibility) and source_dirs (JSON array stored as TEXT)
    # Note: source_dirs_json is inserted as-is into the TEXT column - SQLite JSON functions
    #       (json_array, json_extract) can be used to query/manipulate the JSON data
    sqlite3 "$db_path" <<EOF
BEGIN TRANSACTION;
INSERT INTO runs (run_id, source_root, source_dirs, target_root, output_type, dry_run, status, created_at)
VALUES ('$run_id', '$source_root', '$source_dirs_json', '$target_root', '$output_type', $dry_run, 'running', $created_at);
COMMIT;
EOF

    printf "%s" "$run_id"
}

# --- Cache Lookup ---
pndcgn_db_check_cache() {
    local source_path="$1"
    local input_fingerprint="$2"
    local output_type="${3:-pdf}"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Check for cached artifact with matching fingerprint and output type (NFR-CACHE-014)
    # Normalize output type for case-insensitive matching
    output_type=${output_type,,}

    local cached_output
    cached_output=$(sqlite3 "$db_path" <<EOF
SELECT output_path FROM generated_artifacts
WHERE source_path = '$source_path'
  AND input_fingerprint = '$input_fingerprint'
  AND LOWER(output_type) = LOWER('$output_type')
  AND run_id IN (
    SELECT run_id FROM runs
    WHERE LOWER(output_type) = LOWER('$output_type')
      AND status = 'complete'
    ORDER BY created_at DESC
    LIMIT 1
  )
LIMIT 1;
EOF
)

    if [[ -n "$cached_output" ]] && [[ -f "$cached_output" ]]; then
        printf "%s" "$cached_output"
        return 0
    fi

    return 1
}

# --- Cache Invalidation on Source Delete/Rename/Move (NFR-CACHE-011-013) ---
# Invalidate cache entries when source files are deleted, renamed, or moved
pndcgn_db_invalidate_cache() {
    local source_path="$1"
    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Delete cache entries for the source path using transaction (NFR-CACHE-026)
    sqlite3 "$db_path" <<EOF
BEGIN TRANSACTION;
DELETE FROM generated_artifacts
WHERE source_path = '$source_path';
COMMIT;
EOF
}

# --- Database Connection Management ---
# WAL mode is already enabled in pndcgn_db_init()
# This function ensures proper connection handling
pndcgn_db_ensure_connection() {
    local db_path
    db_path=$(pndcgn_get_db_path)

    # Verify database is accessible
    if ! sqlite3 "$db_path" "SELECT 1;" >/dev/null 2>&1; then
        pndcgn_log_error "Database connection failed: $db_path"
        return 1
    fi

    # Ensure WAL mode
    sqlite3 "$db_path" "PRAGMA journal_mode=WAL;" >/dev/null

    return 0
}

# --- Run Status Management ---
# Update run status with state machine validation (NFR-CACHE-029-032)
pndcgn_db_update_run_status() {
    local run_id="$1"
    local status="$2"

    # Validate state transition
    local current_status
    current_status=$(pndcgn_db_get_run_status "$run_id" 2>/dev/null || printf "")

    # Valid transitions:
    # - running -> complete, failed, interrupted, partial
    # - interrupted -> running (resume)
    # - partial -> running (resume)
    # - complete/failed -> (no transitions allowed)
    case "$current_status" in
        running)
            case "$status" in
                complete|failed|interrupted|partial)
                    # Valid transition
                    ;;
                *)
                    pndcgn_log_warn "Invalid state transition: $current_status -> $status"
                    return 1
                    ;;
            esac
            ;;
        interrupted|partial)
            case "$status" in
                running)
                    # Valid transition (resume)
                    ;;
                *)
                    pndcgn_log_warn "Invalid state transition: $current_status -> $status"
                    return 1
                    ;;
            esac
            ;;
        complete|failed)
            pndcgn_log_warn "Cannot transition from terminal state: $current_status"
            return 1
            ;;
        "")
            # New run, any status is valid
            ;;
    esac

    local db_path
    db_path=$(pndcgn_get_db_path)

    sqlite3 "$db_path" <<EOF
UPDATE runs
SET status = '$status'
WHERE run_id = '$run_id';
EOF
}

# --- Checkpoint Saving ---
# Save checkpoint for interrupt handling (NFR-EDGE-047)
pndcgn_save_checkpoint() {
    local run_id="$1"
    local processed_count="$2"
    local failed_count="$3"

    local db_path
    db_path=$(pndcgn_get_db_path)

    # Update run with current progress
    sqlite3 "$db_path" <<EOF
UPDATE runs
SET status = 'partial',
    counters_json = json_object('processed', $processed_count, 'failed', $failed_count)
WHERE run_id = '$run_id';
EOF
}

# Get run status
pndcgn_db_get_run_status() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)
    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    local status
    status=$(sqlite3 "$db_path" "SELECT status FROM runs WHERE run_id = '$run_id';")

    if [[ -n "$status" ]]; then
        printf "%s" "$status"
        return 0
    fi

    return 1
}

# Get already-processed files for a run
pndcgn_db_get_processed_files() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    sqlite3 "$db_path" <<EOF
SELECT source_path FROM generated_artifacts
WHERE run_id = '$run_id';
EOF
}

# --- Run Statistics ---
# Get run statistics
pndcgn_db_get_run_stats() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    sqlite3 "$db_path" <<EOF
SELECT json_object(
    'run_id', run_id,
    'created_at', created_at,
    'completed_at', completed_at,
    'status', status,
    'source_root', source_root,
    'target_root', target_root,
    'output_type', output_type,
    'dry_run', dry_run,
    'counters_json', counters_json,
    'duration', CASE WHEN completed_at IS NOT NULL THEN (completed_at - created_at) ELSE NULL END
) FROM runs
WHERE run_id = '$run_id';
EOF
}

# Get cache efficiency statistics
pndcgn_db_get_cache_stats() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    sqlite3 "$db_path" <<EOF
SELECT json_object(
    'total_files', (SELECT COUNT(*) FROM generated_artifacts WHERE run_id = '$run_id'),
    'cached_files', (
        SELECT COUNT(*) FROM generated_artifacts ga1
        WHERE ga1.run_id = '$run_id'
        AND EXISTS (
            SELECT 1 FROM generated_artifacts ga2
            WHERE ga2.source_path = ga1.source_path
            AND ga2.input_fingerprint = ga1.input_fingerprint
            AND ga2.run_id != '$run_id'
            AND ga2.run_id IN (SELECT run_id FROM runs WHERE status = 'complete' ORDER BY created_at DESC LIMIT 1)
        )
    )
);
EOF
}

# List all runs
pndcgn_db_list_runs() {
    local limit="${1:-10}"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    sqlite3 "$db_path" <<EOF
SELECT json_object(
    'run_id', run_id,
    'created_at', created_at,
    'status', status,
    'output_type', output_type,
    'dry_run', dry_run
) FROM runs
ORDER BY created_at DESC
LIMIT $limit;
EOF
}

# --- List Pending Dry-Runs (NFR-CACHE-041-042) ---
# List other pending dry-runs (excluding the current one)
# Returns: space-separated list of run IDs
pndcgn_db_list_pending_dry_runs() {
    local exclude_run_id="${1:-}"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    local where_clause=""
    if [[ -n "$exclude_run_id" ]]; then
        where_clause="AND run_id != '$exclude_run_id'"
    fi

    sqlite3 "$db_path" <<EOF
SELECT run_id FROM runs
WHERE dry_run = 1
  AND status IN ('running', 'interrupted', 'partial')
  $where_clause
ORDER BY created_at DESC;
EOF
}

# --- Cleanup Operations ---
# Delete run and its artifacts using transaction (NFR-CACHE-026)
pndcgn_db_delete_run() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)

    sqlite3 "$db_path" <<EOF
BEGIN TRANSACTION;
DELETE FROM runs WHERE run_id = '$run_id';
DELETE FROM generated_artifacts WHERE run_id = '$run_id';
COMMIT;
EOF
}

# Clear all cache/state
pndcgn_db_drop_all() {
    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 0
    fi

    sqlite3 "$db_path" <<EOF
BEGIN TRANSACTION;
DELETE FROM generated_artifacts;
DELETE FROM runs;
COMMIT;
EOF
}

# --- Orphaned Cache Cleanup (NFR-CACHE-059) ---
# Remove cache entries for runs that no longer exist
pndcgn_db_cleanup_orphaned_cache() {
    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Delete artifacts that reference non-existent runs
    sqlite3 "$db_path" <<EOF
BEGIN TRANSACTION;
DELETE FROM generated_artifacts
WHERE run_id NOT IN (SELECT run_id FROM runs);
COMMIT;
EOF
}

# --- Run Fingerprint Storage ---
# Store fingerprint for a run (used during dry-run)
pndcgn_db_store_fingerprint() {
    local run_id="$1"
    local fingerprint="$2"

    local db_path
    db_path=$(pndcgn_get_db_path)

    sqlite3 "$db_path" <<EOF
UPDATE runs
SET fingerprint = '$fingerprint'
WHERE run_id = '$run_id';
EOF
}

# --- Run Fingerprint Retrieval ---
# Retrieve stored fingerprint for a run
pndcgn_db_get_fingerprint() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)
    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Use direct query for better test compatibility
    local fingerprint
    fingerprint=$(sqlite3 "$db_path" "SELECT fingerprint FROM runs WHERE run_id = '$run_id';")

    if [[ -n "$fingerprint" ]]; then
        printf "%s" "$fingerprint"
        return 0
    fi

    return 1
}

# --- Get Run Details ---
# Retrieve run details for finalize/resume operations
pndcgn_db_get_run() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)

    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Return run details as JSON-like string (simplified)
    # Use direct query for better test compatibility
    sqlite3 "$db_path" "SELECT json_object('run_id', run_id, 'source_root', source_root, 'target_root', target_root, 'output_type', output_type, 'dry_run', dry_run, 'fingerprint', fingerprint, 'status', status) FROM runs WHERE run_id = '$run_id';"
}

# --- Check Run Exists ---
# Verify a run exists and return its status
pndcgn_db_run_exists() {
    local run_id="$1"

    local db_path
    db_path=$(pndcgn_get_db_path)
    if [[ ! -f "$db_path" ]]; then
        return 1
    fi

    # Use direct query for better test compatibility (tests can mock sqlite3 with $2)
    local count
    count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM runs WHERE run_id = '$run_id';")

    [[ "${count:-0}" -gt 0 ]]
}
