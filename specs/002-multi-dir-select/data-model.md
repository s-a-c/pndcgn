# Data Model: Multi-Directory Selection

**Feature**: 002-multi-dir-select
**Date**: 2925-12-18

---

<details><summary>Table of Contents</summary>>

- [Data Model: Multi-Directory Selection](#data-model-multi-directory-selection)
  - [1. Entities](#1-entities)
    - [1.1. Run (Extended)](#11-run-extended)
    - [1.2. Selection Limit Configuration](#12-selection-limit-configuration)
    - [1.3. Source Directory List](#13-source-directory-list)
    - [1.4. Output Filename](#14-output-filename)
    - [1.5. Abbreviated Prefix](#15-abbreviated-prefix)
  - [2. Relationships](#2-relationships)
  - [3. Migration](#3-migration)
    - [3.1. Schema Migration (SQLite)](#31-schema-migration-sqlite)
    - [3.2. Backward Compatibility](#32-backward-compatibility)

</details>

---

## 1. Entities

### 1.1. Run (Extended)

The existing `runs` table is extended to support multiple source directories.

| Field | Type | Description | Change |
|-------|------|-------------|--------|
| `run_id` | TEXT PRIMARY KEY | ULID identifier | Unchanged |
| `source_path` | TEXT NOT NULL | First/primary source directory | Unchanged (backward compat) |
| `source_dirs` | TEXT | JSON array of all source directories | **NEW** |
| `target_path` | TEXT NOT NULL | Output directory | Unchanged |
| `output_type` | TEXT NOT NULL | pdf, html, epub | Unchanged |
| `is_dry_run` | INTEGER | 0 or 1 | Unchanged |
| `status` | TEXT | running, complete, failed, interrupted | Unchanged |
| `created_at` | TEXT | ISO 8601 timestamp | Unchanged |
| `completed_at` | TEXT | ISO 8601 timestamp | Unchanged |
| `fingerprint` | TEXT | Combined run fingerprint | Unchanged |
| `counters` | TEXT | JSON stats object | Unchanged |

**Validation Rules**:

- `source_dirs` MUST be valid JSON array when present
- `source_dirs` array length MUST be 1-16
- `source_path` MUST equal first element of `source_dirs` array
- All paths in `source_dirs` MUST be absolute paths
- All paths in `source_dirs` MUST be unique (no duplicates)

**JSON Format Example**:

```json
["/absolute/path/to/dir1", "/absolute/path/to/dir2", "/absolute/path/to/dir3"]
```

- Array of strings (directory paths)
- Paths are absolute, filesystem paths
- Strings are JSON-escaped if needed (backslashes, quotes, etc.)
- Empty array `[]` is invalid (minimum 1 directory required)

**State Transitions**:

```text
[created] → running → complete
                   → failed
                   → interrupted → running (resume)
```

### 1.2. Selection Limit Configuration

Configuration stored in `pndcgn.toml` under `[source]` section.

| Field | Type | Default | Range | Description |
|-------|------|---------|-------|-------------|
| `max_source_dirs` | integer | 4 | 1-16 | Maximum directories selectable |

**Validation Rules**:

- Values < 1 treated as invalid → use default (4)
- Values > 16 capped at 16 with warning
- Non-integer values treated as invalid → use default (4)

**TOML Example**:

```toml
[source]
max_source_dirs = 8
```

### 1.3. Source Directory List

Runtime entity representing selected directories for a run.

| Field | Type | Description |
|-------|------|-------------|
| `directories` | array[string] | Ordered list of absolute directory paths |
| `abbreviated_prefixes` | array[string] | Computed unique prefixes for each directory |
| `count` | integer | Number of directories (1-16) |

**Validation Rules**:

- All directories MUST exist and be readable
- Duplicate directories MUST be removed (deduplication)
- Order MUST be preserved (user selection order or CLI order)

### 1.4. Output Filename

Computed entity for multi-directory output files.

| Field | Type | Description |
|-------|------|-------------|
| `source_prefix` | string | Abbreviated directory prefix (empty for single-dir) |
| `original_name` | string | Original filename without extension |
| `extension` | string | Output type extension (pdf, html, epub) |
| `full_name` | string | `{prefix}--{name}.{ext}` or `{name}.{ext}` |

**Format Rules**:

- Single directory: `{original_name}.{ext}` (no prefix)
- Multiple directories: `{abbreviated_prefix}--{original_name}.{ext}`
- Prefix separator: `--` (double hyphen)
- Special characters in prefix sanitized to hyphens

**Examples**:

```text
# Single directory
readme.md → readme.pdf

# Multiple directories: projects/frontend, projects/backend
frontend/readme.md → front--readme.pdf
backend/readme.md  → back--readme.pdf

# Multiple directories: docs, notes
docs/guide.md  → docs--guide.pdf
notes/guide.md → notes--guide.pdf
```

### 1.5. Abbreviated Prefix

Computed entity for distinguishing source directories.

| Field | Type | Description |
|-------|------|-------------|
| `directory` | string | Full directory path |
| `basename` | string | Directory name (last path component) |
| `prefix` | string | Shortest unique prefix of basename |
| `length` | integer | Length of prefix |

**Computation Rules**:

1. Extract basename from each directory path
2. For each basename, find shortest prefix that is unique among all basenames
3. If basenames are identical, use parent directory name as disambiguation
4. Sanitize prefix: replace non-alphanumeric chars with hyphens

**Algorithm**:

```text
Input: ["/path/to/frontend", "/path/to/backend", "/other/frontend"]
Basenames: ["frontend", "backend", "frontend"]

Step 1: "frontend" vs "backend" - "f" vs "b" unique at length 1
Step 2: "frontend" vs "frontend" - identical, use parent: "to-front", "other-front"

Output: ["to-front", "back", "other-front"]
```

---

## 2. Relationships

```text
┌─────────────────┐
│      Run        │
├─────────────────┤
│ run_id (PK)     │
│ source_path     │──────┐
│ source_dirs[]   │──────┼──→ Source Directory List
│ target_path     │      │
│ ...             │      │
└─────────────────┘      │
                         │
┌─────────────────┐      │
│ Configuration   │      │
├─────────────────┤      │
│ max_source_dirs │──────┼──→ Validates count
└─────────────────┘      │
                         │
┌─────────────────┐      │
│ Output Filename │◄─────┘
├─────────────────┤
│ source_prefix   │◄───── Abbreviated Prefix
│ original_name   │
│ extension       │
└─────────────────┘
```

---

## 3. Migration

### 3.1. Schema Migration (SQLite)

```sql
-- Version: 002-multi-dir-select
-- Description: Add source_dirs column for multi-directory support

-- Step 1: Add new column
ALTER TABLE runs ADD COLUMN source_dirs TEXT;

-- Step 2: Migrate existing data
UPDATE runs
SET source_dirs = json_array(source_path)
WHERE source_dirs IS NULL;

-- Step 3: Create index for JSON queries (optional, for performance)
CREATE INDEX IF NOT EXISTS idx_runs_source_dirs ON runs(source_dirs);
```

### 3.2. Backward Compatibility

- Existing single-directory runs continue to work unchanged
- `source_path` column retained for backward compatibility
- Queries using `source_path` still return first/primary directory
- New code should prefer `source_dirs` for multi-directory awareness

---
