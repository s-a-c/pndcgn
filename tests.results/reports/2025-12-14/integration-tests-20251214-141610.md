# Test Results Report: integration-tests

**Test File**: `tests/integration-tests.sh`
**Execution Time**: 2025-12-14 14:16:10
**Timestamp**: 20251214-141610

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Examples** | 15 |
| **Failures** | 5 |
| **Warnings** | 0 |
| **Success Rate** | 66.6% |

### Status
❌ **Some tests failed**

---

<details>
<summary><strong>Full Test Log</strong></summary>

```log
Running: /opt/homebrew/bin/bash [bash 5.3.9(1)-release]

Database Integration Tests (No Mocks)
  real database operations
    [1m[31mcreates and initializes database (FAILED - 1)[0m
    [1m[31mcreates run with real database (FAILED - 2)[0m
    [1m[31mstores and retrieves fingerprint (FAILED - 3)[0m

Processing Integration Tests (No Mocks)
  real file operations
    [1m[32mdiscovers files in real directory structure[0m
    [1m[32mcomputes real file fingerprints[0m
    [1m[32mcreates real output directories[0m
    [1m[32mgenerates real index files[0m
    [1m[32mcomputes real output fingerprints[0m
    [1m[32mcomputes real run fingerprints[0m

0
Utilities Integration Tests (No Mocks)
  real utility operations
    [1m[31mchecks real prerequisites (FAILED - 4)[0m
    [1m[32mresolves real paths[0m
    [1m[31mcreates real XDG directories (FAILED - 5)[0m
    [1m[32mgenerates real ULIDs[0m
    [1m[32mdiscovers real ignore files[0m
    [1m[33mseeds real ignore files (WARNED - 6)[0m

Examples:
[37m  1) Database Integration Tests (No Mocks) real database operations creates and initializes database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_init[0m

     1.1) [31mThe file test_state/pndcgn.db should be exist[0m

            [31mThe specified path does not exist[0m
            [31mpath: test_state/pndcgn.db[0m

          [36m# tests/integration/database_integration_spec.sh:24[0m

     1.2) [33mWARNING: There was output to stdout but not found expectation[0m

            [33mstdout: wal[0m
            [33m/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.FVmQQ6IPiQ/test_state/pndcgn/pndcgn.db[0m

          [36m# tests/integration/database_integration_spec.sh:18-28[0m

     1.3) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: [1m[33mWARN:[0m Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:18-28[0m

[37m  2) Database Integration Tests (No Mocks) real database operations creates run with real database[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_create_run '/tmp/source' '/tmp/target' 'pdf' '0'[0m

     2.1) [31mWhen run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_run_exists '01KCEKG4C5QGEC7W3BAF000000'[0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/database_integration_spec.sh:44[0m

     2.2) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: [1m[33mWARN:[0m Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:30-49[0m

     2.3) [31mUnexpected output to stderr occurred[0m

            [31m[1m[33mWARN:[0m Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:30-49[0m

[37m  3) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_store_fingerprint '01KCEKG4M2F4QM69ZQD6000000' 'test-fingerprint-123'[0m

     3.1) [31mWhen run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/database.sh' && pndcgn_db_get_fingerprint '01KCEKG4M2F4QM69ZQD6000000'[0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/database_integration_spec.sh:67[0m

     3.2) [31mThe output should eq test-fingerprint-123[0m

            [31mexpected: "test-fingerprint-123"[0m
            [31m     got: ""[0m

          [36m# tests/integration/database_integration_spec.sh:68[0m

     3.3) [31mUnexpected output to stderr occurred[0m

            [31m[1m[33mWARN:[0m Failed to load sqlite-ulid extension. Using Bash fallback.[0m

          [36m# tests/integration/database_integration_spec.sh:51-73[0m

[37m  4) Utilities Integration Tests (No Mocks) real utility operations checks real prerequisites[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && pndcgn_check_prerequisites[0m

     4.1) [31mThe stderr should satisfy expr shellspec_finished 1 = [0m

            [31mexpected "" satisfies "expr shellspec_finished 1 = "[0m

          [36m# tests/integration/utilities_integration_spec.sh:22[0m

[37m  5) Utilities Integration Tests (No Mocks) real utility operations creates real XDG directories[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && pndcgn_get_state_dir[0m

     5.1) [31mWhen run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && pndcgn_get_config_dir[0m

            [31mEvaluation has already been executed. Only one Evaluation allow per Example.[0m
            [31m(Use 'parameterized example' if you want a loop)[0m

          [36m# tests/integration/utilities_integration_spec.sh:50[0m

[37m  6) Utilities Integration Tests (No Mocks) real utility operations seeds real ignore files[0m
[1m[36m     When run bash -c source '/Users/s-a-c/nc/Projects/Git/pndcgn/src/utilities.sh' && pndcgn_seed_ignore_file '/var/folders/f0/2m6r6db57bxglzky2b_f49n00000gn/T/tmp.C9cE56kl7L/test_source'[0m

     6.1) [33mWARNING: There was output to stderr but not found expectation[0m

            [33mstderr: [1m[32mINFO:[0m Created .pndcgnignore with default patterns[0m

          [36m# tests/integration/utilities_integration_spec.sh:83-92[0m

Finished in 2.83 seconds (user 0.97 seconds, sys 0.99 seconds)
[31m15 examples, 5 failures, 1 warning, aborted by an unexpected error[0m


[1m[31mFailure examples / Errors: [0m(Listed here [4maffect[0m your suite's status)

[1m[31mshellspec tests/integration/database_integration_spec.sh:18[0m [36m# 1) Database Integration Tests (No Mocks) real database operations creates and initializes database FAILED[0m
[1m[31mshellspec tests/integration/database_integration_spec.sh:30[0m [36m# 2) Database Integration Tests (No Mocks) real database operations creates run with real database FAILED[0m
[1m[31mshellspec tests/integration/database_integration_spec.sh:51[0m [36m# 3) Database Integration Tests (No Mocks) real database operations stores and retrieves fingerprint FAILED[0m
[1m[31mshellspec tests/integration/utilities_integration_spec.sh:18[0m [36m# 4) Utilities Integration Tests (No Mocks) real utility operations checks real prerequisites FAILED[0m
[1m[31mshellspec tests/integration/utilities_integration_spec.sh:37[0m [36m# 5) Utilities Integration Tests (No Mocks) real utility operations creates real XDG directories FAILED[0m
[1m[33mshellspec tests/integration/utilities_integration_spec.sh:83[0m [36m# 6) Utilities Integration Tests (No Mocks) real utility operations seeds real ignore files WARNED[0m

[1;31mAborted with status code [executor: 0] [reporter: 1] [error handler: 0][m
[1;31mFatal error occurred, terminated with exit status 1.[m
```

</details>
