# Test Results Report: integration-tests

**Test File**: `tests/integration-tests.sh`
**Execution Time**: 2025-12-19 01:39:34
**Timestamp**: 20251219-013934

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Examples** | 28 |
| **Failures** | 0 |
| **Warnings** | 2 |
| **Success Rate** | 100.0% |

### Status

⚠️  **All tests passed with warnings**

---

<details>
<summary><strong>Full Test Log</strong></summary>

```log
Running: /opt/homebrew/bin/bash [bash 5.3.9(1)-release]

Processing Integration Tests (No Mocks)
  real file operations
    [1m[32mdiscovers files in real directory structure[0m
    [1m[32mcomputes real file fingerprints[0m
    [1m[32mcreates real output directories[0m
    [1m[32mgenerates real index files[0m
    [1m[32mcomputes real output fingerprints[0m
    [1m[32mcomputes real run fingerprints[0m

Database Integration Tests (No Mocks)
  real database operations
    [1m[32mcreates and initializes database[0m
    [1m[33mcreates run with real database (WARNED - 1)[0m
    [1m[33mstores and retrieves fingerprint (WARNED - 2)[0m

Utilities Integration Tests (No Mocks)
  real utility operations
    [1m[32mchecks real prerequisites[0m
    [1m[32mresolves real paths[0m
    [1m[32mcreates real XDG state directory[0m
    [1m[32mcreates real XDG config directory[0m
    [1m[32mgenerates real ULIDs[0m
    [1m[32mgenerates unique ULIDs[0m
    [1m[32mdiscovers real ignore files[0m
    [1m[32mseeds real ignore files[0m

Multi-Directory Integration
  multi-directory processing (T022)
    [1m[32mprocesses files from multiple directories in single run[0m
  abbreviated prefixes (T023)
    [1m[32mgenerates abbreviated prefixes for frontend/backend directories[0m
    [1m[32muses prefixes in output filenames when multiple directories (front prefix)[0m
    [1m[32muses prefixes in output filenames when multiple directories (back prefix)[0m
    [1m[32mdoes not use prefix for single directory (backward compatibility)[0m
  single run ID (T024)
    [1m[32mcreates single run ID for multiple source directories[0m
  backward compatibility - single directory (T041)
    [1m[32mprocesses single directory without prefix (identical to pre-feature behavior)[0m
  graceful degradation (FR-010)
    [1m[32mcontinues processing when one directory fails[0m
  signal handling - graceful Ctrl+C (T067)
    [1m[32mhandles SIGINT gracefully with summary[0m
    [1m[32mexports PNDCGN_INTERRUPTED flag on SIGINT[0m
  performance validation (SC-004, T068)
    [1m[32mverifies N-directory run completes within N×single + 10% overhead[0m

Examples:
[37m  1) Database Integration Tests (No Mocks) real database operations creates run with real database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && source_dirs_json=$(pndcgn_array_to_json '/tmp/source') && run_id=$(pndcgn_db_create_run "$source_dirs_json" '/tmp/target' 'pdf' '0') && pndcgn_db_run_exists "$run_id" && echo "$run_id"[0m

     1.1) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:35-49[0m

[37m  2) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && source_dirs_json=$(pndcgn_array_to_json '/tmp/source') && run_id=$(pndcgn_db_create_run "$source_dirs_json" '/tmp/target' 'pdf' '0') && pndcgn_db_store_fingerprint "$run_id" 'test-fingerprint-123' && pndcgn_db_get_fingerprint "$run_id"[0m

     2.1) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:51-65[0m

Finished in 4.83 seconds (user 1.42 seconds, sys 1.66 seconds)
[33m28 examples, 0 failures, 2 warnings[0m


[1m[31mFailure examples / Errors: [0m(Listed here [4maffect[0m your suite's status)

[1m[33mshellspec tests/integration/database_integration_spec.sh:35[0m [36m# 1) Database Integration Tests (No Mocks) real database operations creates run with real database WARNED[0m
[1m[33mshellspec tests/integration/database_integration_spec.sh:51[0m [36m# 2) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint WARNED[0m

```

</details>
