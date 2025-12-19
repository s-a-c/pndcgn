# Test Results Report: integration-tests

**Test File**: `tests/integration-tests.sh`
**Execution Time**: 2025-12-16 03:13:03
**Timestamp**: 20251216-031303

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Examples** | 17 |
| **Failures** | 2 |
| **Warnings** | 2 |
| **Success Rate** | 88.2% |

### Status
❌ **Some tests failed**

---

<details>
<summary><strong>Full Test Log</strong></summary>

```log
Running: /opt/homebrew/bin/bash [bash 5.3.9(1)-release]

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

Processing Integration Tests (No Mocks)
  real file operations
    [1m[31mdiscovers files in real directory structure (FAILED - 3)[0m
    [1m[32mcomputes real file fingerprints[0m
    [1m[32mcreates real output directories[0m
    [1m[32mgenerates real index files[0m
    [1m[32mcomputes real output fingerprints[0m
    [1m[31mcomputes real run fingerprints (FAILED - 4)[0m

Examples:
[37m  1) Database Integration Tests (No Mocks) real database operations creates run with real database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_run_exists "$run_id" && echo "$run_id"[0m

     1.1) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:35-49[0m

[37m  2) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_store_fingerprint "$run_id" 'test-fingerprint-123' && pndcgn_db_get_fingerprint "$run_id"[0m

     2.1) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:51-65[0m

[37m  3) Processing Integration Tests (No Mocks) real file operations discovers files in real directory structure[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/processing.sh' && pndcgn_discover_files '/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.u3kmEMTYqq/test_source'[0m

     3.1) [31mThe output should include doc1.md[0m

            [31mexpected "" to include "doc1.md"[0m

          [36m# tests/integration/processing_integration_spec.sh:26[0m

     3.2) [31mThe output should include subdir/doc2.md[0m

            [31mexpected "" to include "subdir/doc2.md"[0m

          [36m# tests/integration/processing_integration_spec.sh:27[0m

[37m  4) Processing Integration Tests (No Mocks) real file operations computes real run fingerprints[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/processing.sh' && pndcgn_compute_run_fingerprint '/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.u3kmEMTYqq/test_source' '/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.u3kmEMTYqq/test_source/.pndcgnignore' 'pdf' '/tmp/target'[0m

     4.1) [31mThe status should be success[0m

            [31mexpected: success (zero)[0m
            [31m     got: failure (non-zero) [status: 1][0m

          [36m# tests/integration/processing_integration_spec.sh:101[0m

     4.2) [31mExample aborted (exit status: 1)[0m

          [36m# tests/integration/processing_integration_spec.sh:93-110[0m

Finished in 1.99 seconds (user 0.73 seconds, sys 0.79 seconds)
[31m17 examples, 2 failures, 2 warnings[0m


[1m[31mFailure examples / Errors: [0m(Listed here [4maffect[0m your suite's status)

[1m[33mshellspec tests/integration/database_integration_spec.sh:35[0m [36m# 1) Database Integration Tests (No Mocks) real database operations creates run with real database WARNED[0m
[1m[33mshellspec tests/integration/database_integration_spec.sh:51[0m [36m# 2) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint WARNED[0m
[1m[31mshellspec tests/integration/processing_integration_spec.sh:18[0m [36m# 3) Processing Integration Tests (No Mocks) real file operations discovers files in real directory structure FAILED[0m
[1m[31mshellspec tests/integration/processing_integration_spec.sh:93[0m [36m# 4) Processing Integration Tests (No Mocks) real file operations computes real run fingerprints FAILED[0m

```

</details>
