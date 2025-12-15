# Feature/Unit Test Plan

<details>
<summary>Table of Contents</summary>

- [1. Overview](#1-overview)
  - [1.1. Purpose](#11-purpose)
  - [1.2. Test Framework](#12-test-framework)
- [2. Constants Module Tests](#2-constants-module-tests)
- [3. Utilities Module Tests](#3-utilities-module-tests)
- [4. Database Module Tests](#4-database-module-tests)
- [5. Processing Module Tests](#5-processing-module-tests)
- [6. Main Controller Tests](#6-main-controller-tests)
- [7. Test Execution](#7-test-execution)
- [Navigation](#navigation)

</details>

---

**Compliant with**: AI-GUIDELINES.md v1.0

## 1. Overview

### 1.1. Purpose

This document defines unit and feature tests for individual modules. Tests follow BDD style using shellspec and target 50-70% code coverage (see Constitution §II for coverage tracking limitations).

### 1.2. Test Framework

**Tool**: shellspec

**Run tests**:
```bash
# All tests
shellspec

# Using test scripts (recommended)
./scripts/run-all-tests.sh
./scripts/run-unit-tests.sh
./scripts/run-integration-tests.sh

# Specific test file
./scripts/run-test.sh tests/utilities/logging_spec.sh

# With coverage
./scripts/run-coverage.sh all

# Local CI workflow
./scripts/local-ci.sh
```

**Test Structure** (as of 2025-12-14):
- **Modular Unit Tests**: `tests/utilities/`, `tests/database/`, `tests/processing/` (18 files)
- **Integration Tests**: `tests/integration/` (3 files, 16 tests without mocks)
- **Feature Tests**: `tests/pndcgn_spec.sh`, `tests/performance_spec.sh`, `tests/usability_spec.sh`
- **Legacy Files**: `tests/utilities_spec.sh`, `tests/database_spec.sh`, `tests/processing_spec.sh` (deprecated)

---

## 2. Constants Module Tests

**File**: `tests/constants_spec.sh`

**Tests**:
```bash
Describe 'Constants Module'
  It 'defines PNDCGN_RED'
    When call printf "%s" "$PNDCGN_RED"
    The output should start with "\\033["
  End

  It 'defines all required colors'
    The variable PNDCGN_GREEN should be defined
    The variable PNDCGN_YELLOW should be defined
    The variable PNDCGN_BLUE should be defined
    The variable PNDCGN_BOLD should be defined
    The variable PNDCGN_RESET should be defined
  End

  It 'respects NO_COLOR environment variable'
    NO_COLOR=1 source src/constants.sh
    The variable PNDCGN_RED should equal ""
  End
End
```

---

## 3. Utilities Module Tests

**File**: `specs/utilities_spec.sh`

**ULID Generation**:
```bash
Describe 'pndcgn_generate_ulid'
  It 'generates 26-character identifier'
    When call pndcgn_generate_ulid
    The length of output should equal 26
  End

  It 'generates unique IDs'
    id1=$(pndcgn_generate_ulid)
    id2=$(pndcgn_generate_ulid)
    The variable id1 should not equal "$id2"
  End
End
```

**Path Resolution**:
```bash
Describe 'pndcgn_resolve_path'
  It 'converts relative to absolute path'
    When call pndcgn_resolve_path "../docs"
    The output should start with "/"
  End

  It 'handles current directory'
    When call pndcgn_resolve_path "."
    The output should equal "$PWD"
  End
End
```

**Logging**:
```bash
Describe 'pndcgn_log_info'
  It 'outputs to stdout'
    When call pndcgn_log_info "Test message"
    The output should include "Test message"
  End
End

Describe 'pndcgn_log_error'
  It 'outputs to stderr'
    When call pndcgn_log_error "Error message"
    The error should include "Error message"
  End
End
```

---

## 4. Database Module Tests

**Files**: `tests/database/*.sh` (modular structure)

**Test Files**:
- `tests/database/run_creation_spec.sh` - Run creation with ULID generation
- `tests/database/cache_lookup_spec.sh` - Cache lookup functions
- `tests/database/fingerprint_storage_spec.sh` - Fingerprint storage and retrieval

**Legacy File**: `tests/database_spec.sh` (deprecated, use modular files above)

**Schema Creation**:
```bash
Describe 'pndcgn_db_init'
  It 'creates runs table'
    When call pndcgn_db_init
    The result of "table_exists runs" should be success
  End

  It 'creates generated_pdfs table'
    When call pndcgn_db_init
    The result of "table_exists generated_pdfs" should be success
  End

  It 'creates indexes'
    When call pndcgn_db_init
    The result of "index_exists idx_fingerprints" should be success
  End
End
```

**Run Management**:
```bash
Describe 'pndcgn_db_start_run'
  It 'inserts run record'
    run_id="TEST_RUN_ID"
    When call pndcgn_db_start_run "$run_id" "/src" "/out" "pdf" 0
    The status should be success
    The result of "run_exists $run_id" should be success
  End
End

Describe 'pndcgn_db_finish_run'
  It 'updates run status'
    When call pndcgn_db_finish_run "$run_id" "complete" 10 5 5 0
    The result of "get_run_status $run_id" should equal "complete"
  End
End
```

**Cache Operations**:
```bash
Describe 'pndcgn_db_store_file'
  It 'stores file metadata'
    When call pndcgn_db_store_file \
        "$run_id" "/src/f.md" "/out/f.pdf" "fp123" 100 1000
    The status should be success
  End
End

Describe 'pndcgn_db_get_fingerprint'
  It 'retrieves cached file'
    When call pndcgn_db_get_fingerprint "fp123" "pdf"
    The output should equal "/out/f.pdf"
  End

  It 'returns nothing for missing fingerprint'
    When call pndcgn_db_get_fingerprint "nonexistent" "pdf"
    The output should equal ""
  End
End
```

---

## 5. Processing Module Tests

**Files**: `tests/processing/*.sh` (modular structure)

**Test Files**:
- `tests/processing/file_discovery_spec.sh` - File discovery respecting .pndcgnignore
- `tests/processing/fingerprint_computation_spec.sh` - Input file fingerprint computation
- `tests/processing/pandoc_conversion_spec.sh` - Pandoc conversion functions
- `tests/processing/dewey_naming_spec.sh` - Dewey Decimal naming scheme
- `tests/processing/output_directory_spec.sh` - Output directory creation
- `tests/processing/index_generation_spec.sh` - Run index generation
- `tests/processing/output_fingerprint_spec.sh` - Output fingerprint computation
- `tests/processing/run_fingerprint_spec.sh` - Run fingerprint computation
- `tests/processing/fingerprint_validation_spec.sh` - Fingerprint validation

**Legacy File**: `tests/processing_spec.sh` (deprecated, use modular files above)

**File Discovery**:
```bash
Describe 'pndcgn_find_files'
  setup() {
    mkdir -p /tmp/test/sub
    touch /tmp/test/file1.md
    touch /tmp/test/sub/file2.md
  }

  It 'finds markdown files'
    When call pndcgn_find_files "/tmp/test"
    The lines of output should equal 2
  End

  cleanup() {
    rm -rf /tmp/test
  }
End
```

**Fingerprinting**:
```bash
Describe 'pndcgn_compute_fingerprint'
  It 'computes stable fingerprint'
    fp1=$(pndcgn_compute_fingerprint "/tmp/test.md")
    fp2=$(pndcgn_compute_fingerprint "/tmp/test.md")
    The variable fp1 should equal "$fp2"
  End

  It 'format includes size:mtime:hash'
    When call pndcgn_compute_fingerprint "/tmp/test.md"
    The output should match pattern "*:*:*"
  End
End
```

**File Conversion**:
```bash
Describe 'pndcgn_convert_file'
  It 'converts markdown to PDF'
    echo "# Test" > /tmp/test.md
    When call pndcgn_convert_file "/tmp/test.md" "/tmp/test.pdf" "pdf"
    The status should be success
    The path "/tmp/test.pdf" should be file
  End

  It 'handles pandoc errors'
    echo "{{invalid}}" > /tmp/invalid.md
    When call pndcgn_convert_file "/tmp/invalid.md" "/tmp/out.pdf" "pdf"
    The status should be failure
  End
End
```

---

## 6. Main Controller Tests

**File**: `tests/pndcgn_spec.sh` - Main CLI entrypoint tests

**Argument Parsing**:
```bash
Describe 'CLI argument parsing'
  It 'parses --help'
    When run bin/pdf-generator --help
    The output should include "Usage:"
    The status should be success
  End

  It 'parses --version'
    When run bin/pdf-generator --version
    The output should include "pndcgn"
  End

  It 'parses --verbose'
    When run bin/pdf-generator --verbose /tmp/test
    The variable pndcgn_verbose should equal "1"
  End
End
```

---

## 7. Test Execution

**Run all tests**:
```bash
# Using shellspec directly
shellspec

# Using test scripts (recommended)
./scripts/run-all-tests.sh
```

**Run specific suites**:
```bash
./scripts/run-unit-tests.sh          # Unit tests only
./scripts/run-feature-tests.sh       # Feature tests only
./scripts/run-integration-tests.sh   # Integration tests only
```

**Run individual test**:
```bash
./scripts/run-test.sh tests/utilities/logging_spec.sh
./scripts/run-test.sh tests/pndcgn_spec.sh 25  # Specific test block
```

**Run with coverage**:
```bash
# Using test scripts (recommended)
./scripts/run-coverage.sh all
./scripts/run-coverage.sh unit
./scripts/run-coverage.sh integration

# Direct shellspec (may fail on macOS due to ptrace limitations)
shellspec --kcov
```

**Local CI workflow**:
```bash
./scripts/local-ci.sh                 # Full CI workflow (lint + test + coverage)
./scripts/local-ci.sh --skip-coverage # Skip coverage (faster)
```

**Check coverage report**:
```bash
open tests.results/coverage/index.html
```

**Note**: Coverage works best on Linux. Use Docker (`Dockerfile.test`) or CI (`.github/workflows/test-coverage.yml`) for accurate results on macOS.

---

## Navigation

[← System Test Plan](100-system-test-plan.md) | [↑ Top](#featureunit-test-plan) | [README →](../README.md)
