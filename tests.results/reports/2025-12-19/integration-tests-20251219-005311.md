# Test Results Report: integration-tests

**Test File**: `tests/integration-tests.sh`
**Execution Time**: 2025-12-19 00:53:11
**Timestamp**: 20251219-005311

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Examples** | 26 |
| **Failures** | 9 |
| **Warnings** | 0 |
| **Success Rate** | 65.3% |

### Status
❌ **Some tests failed**

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
    [1m[31mcreates and initializes database (FAILED - 1)[0m
    [1m[31mcreates run with real database (FAILED - 2)[0m
    [1m[31mstores and retrieves fingerprint (FAILED - 3)[0m

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
    [1m[31mgenerates abbreviated prefixes for frontend/backend directories (FAILED - 4)[0m
    [1m[31muses prefixes in output filenames when multiple directories (FAILED - 5)[0m
    [1m[31mdoes not use prefix for single directory (backward compatibility) (FAILED - 6)[0m
  single run ID (T024)
    [1m[31mcreates single run ID for multiple source directories (FAILED - 7)[0m
  backward compatibility - single directory (T041)
    [1m[31mprocesses single directory without prefix (identical to pre-feature behavior) (FAILED - 8)[0m
  graceful degradation (FR-010)
    [1m[31mcontinues processing when one directory fails (FAILED - 9)[0m
  signal handling - graceful Ctrl+C (T067)
    [1m[32mhandles SIGINT gracefully with summary[0m
    [1m[32mexports PNDCGN_INTERRUPTED flag on SIGINT[0m

Examples:
[37m  1) Database Integration Tests (No Mocks) real database operations creates and initializes database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_init 2>/dev/null[0m

     1.1) [31mThe output should match pattern *pndcgn.db[0m

            [31mexpected "wal[0m
            [31m30000" to match pattern "*pndcgn.db"[0m

          [36m# tests/integration/database_integration_spec.sh:23[0m

     1.2) [31mThe status should be success[0m

            [31mexpected: success (zero)[0m
            [31m     got: failure (non-zero) [status: 1][0m

          [36m# tests/integration/database_integration_spec.sh:24[0m

[37m  2) Database Integration Tests (No Mocks) real database operations creates run with real database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_run_exists "$run_id" && echo "$run_id"[0m

     2.1) [31mThe output should not eq [0m

            [31mexpected: not equal ""[0m
            [31m     got: ""[0m

          [36m# tests/integration/database_integration_spec.sh:44[0m

     2.2) [31mThe status should be success[0m

            [31mexpected: success (zero)[0m
            [31m     got: failure (non-zero) [status: 1][0m

          [36m# tests/integration/database_integration_spec.sh:45[0m

     2.3) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m
            [33m/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh: line 169: [[: 0[0m
            [33m0: arithmetic syntax error in expression (error token is "0")[0m
            [33mParse error near line 2: no such column: source_dirs[0m
            [33mParse error near line 21: no such column: source_dirs[0m
            [33m  d, created_at, completed_at, status, source_root, source_dirs, target_root, ou[0m
            [33m                                      error here ---^[0m
            [33mERROR: Failed to extract source_root from source_dirs_json: /tmp/source[0m

          [36m# tests/integration/database_integration_spec.sh:35-49[0m

[37m  3) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && run_id=$(pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0') && pndcgn_db_store_fingerprint "$run_id" 'test-fingerprint-123' && pndcgn_db_get_fingerprint "$run_id"[0m

     3.1) [31mThe output should eq test-fingerprint-123[0m

            [31mexpected: "test-fingerprint-123"[0m
            [31m     got: ""[0m

          [36m# tests/integration/database_integration_spec.sh:60[0m

     3.2) [31mThe status should be success[0m

            [31mexpected: success (zero)[0m
            [31m     got: failure (non-zero) [status: 1][0m

          [36m# tests/integration/database_integration_spec.sh:61[0m

     3.3) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: WARN: Failed to load sqlite-ulid extension. Using Bash fallback.[0m
            [33m/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh: line 169: [[: 0[0m
            [33m0: arithmetic syntax error in expression (error token is "0")[0m
            [33mParse error near line 2: no such column: source_dirs[0m
            [33mParse error near line 21: no such column: source_dirs[0m
            [33m  d, created_at, completed_at, status, source_root, source_dirs, target_root, ou[0m
            [33m                                      error here ---^[0m
            [33mERROR: Failed to extract source_root from source_dirs_json: /tmp/source[0m

          [36m# tests/integration/database_integration_spec.sh:51-65[0m

[37m  4) Multi-Directory Integration abbreviated prefixes (T023) generates abbreviated prefixes for frontend/backend directories[0m
[1m[36m     When call pndcgn_compute_abbreviated_prefixes /var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/frontend /var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/backend[0m

     4.1) [31mThe output should include front[0m

            [31mexpected "f[0m
            [31mb" to include "front"[0m

          [36m# tests/integration/multi_dir_spec.sh:87[0m

     4.2) [31mThe output should include back[0m

            [31mexpected "f[0m
            [31mb" to include "back"[0m

          [36m# tests/integration/multi_dir_spec.sh:88[0m

[37m  5) Multi-Directory Integration abbreviated prefixes (T023) uses prefixes in output filenames when multiple directories[0m
[1m[36m     When call pndcgn_generate_prefixed_filename front file.md pdf[0m

     5.1) [31mThe output should eq front--file.pdf[0m

            [31mexpected: "front--file.pdf"[0m
            [31m     got: "front--file.md.pdf"[0m

          [36m# tests/integration/multi_dir_spec.sh:100[0m

     5.2) [31mWhen call pndcgn_generate_prefixed_filename back file.md pdf[0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/multi_dir_spec.sh:103[0m

     5.3) [31mThe output should eq back--file.pdf[0m

            [31mexpected: "back--file.pdf"[0m
            [31m     got: "front--file.md.pdf"[0m

          [36m# tests/integration/multi_dir_spec.sh:104[0m

[37m  6) Multi-Directory Integration abbreviated prefixes (T023) does not use prefix for single directory (backward compatibility)[0m
[1m[36m     When call pndcgn_generate_prefixed_filename  file.md pdf[0m

     6.1) [31mThe output should eq file.pdf[0m

            [31mexpected: "file.pdf"[0m
            [31m     got: "file.md.pdf"[0m

          [36m# tests/integration/multi_dir_spec.sh:112[0m

[37m  7) Multi-Directory Integration single run ID (T024) creates single run ID for multiple source directories[0m
[1m[36m     When call printf %s 01KCT1HGC62803758W72000000[0m

     7.1) [31mWhen call printf %s [
  "/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir1",
  "/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir2"
][0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/multi_dir_spec.sh:144[0m

     7.2) [31mThe output should include /var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir1[0m

            [31mexpected "01KCT1HGC62803758W72000000" to include "/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir1"[0m

          [36m# tests/integration/multi_dir_spec.sh:145[0m

     7.3) [31mThe output should include /var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir2[0m

            [31mexpected "01KCT1HGC62803758W72000000" to include "/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/dir2"[0m

          [36m# tests/integration/multi_dir_spec.sh:146[0m

[37m  8) Multi-Directory Integration backward compatibility - single directory (T041) processes single directory without prefix (identical to pre-feature behavior)[0m
[1m[36m     When call printf %s 01KCT1HGSF93EBPVPZ5C000000[0m

     8.1) [31mWhen call pndcgn_generate_prefixed_filename  file.md pdf[0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/multi_dir_spec.sh:178[0m

     8.2) [31mThe output should eq file.pdf[0m

            [31mexpected: "file.pdf"[0m
            [31m     got: "01KCT1HGSF93EBPVPZ5C000000"[0m

          [36m# tests/integration/multi_dir_spec.sh:179[0m

[37m  9) Multi-Directory Integration graceful degradation (FR-010) continues processing when one directory fails[0m
[1m[36m     When call printf %s /var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/valid_dir/file.md[0m

     9.1) [31mWhen call printf %s [0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/multi_dir_spec.sh:206[0m

     9.2) [31mThe output should eq [0m

            [31mexpected: ""[0m
            [31m     got: "/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.15MBVLuSqL/valid_dir/file.md"[0m

          [36m# tests/integration/multi_dir_spec.sh:207[0m

Finished in 4.87 seconds (user 1.44 seconds, sys 1.76 seconds)
[31m26 examples, 9 failures[0m


[1m[31mFailure examples / Errors: [0m(Listed here [4maffect[0m your suite's status)

[1m[31mshellspec tests/integration/database_integration_spec.sh:18[0m [36m# 1) Database Integration Tests (No Mocks) real database operations creates and initializes database FAILED[0m
[1m[31mshellspec tests/integration/database_integration_spec.sh:35[0m [36m# 2) Database Integration Tests (No Mocks) real database operations creates run with real database FAILED[0m
[1m[31mshellspec tests/integration/database_integration_spec.sh:51[0m [36m# 3) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:81[0m [36m# 4) Multi-Directory Integration abbreviated prefixes (T023) generates abbreviated prefixes for frontend/backend directories FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:94[0m [36m# 5) Multi-Directory Integration abbreviated prefixes (T023) uses prefixes in output filenames when multiple directories FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:108[0m [36m# 6) Multi-Directory Integration abbreviated prefixes (T023) does not use prefix for single directory (backward compatibility) FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:118[0m [36m# 7) Multi-Directory Integration single run ID (T024) creates single run ID for multiple source directories FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:153[0m [36m# 8) Multi-Directory Integration backward compatibility - single directory (T041) processes single directory without prefix (identical to pre-feature behavior) FAILED[0m
[1m[31mshellspec tests/integration/multi_dir_spec.sh:187[0m [36m# 9) Multi-Directory Integration graceful degradation (FR-010) continues processing when one directory fails FAILED[0m

```

</details>
