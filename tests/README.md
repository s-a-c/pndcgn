# Test Suite for `pndcgn`

This directory contains the comprehensive test suite for the pndcgn documentation generation tool, built using the `shellspec` framework. The suite is designed to achieve 90% minimum code coverage (per Constitution §II).

## Test Files

- `pndcgn_spec.sh` - Main CLI entrypoint tests (argument parsing, fzf, progress, integration, error handling)
- `config_spec.sh` - Configuration management tests (.pndcgnignore discovery, .gitignore seeding)
- `processing_spec.sh` - Processing function tests (file discovery, fingerprinting, conversion, indexing)
- `database_spec.sh` - Database operation tests (run creation, cache lookup, ULID generation)
- `utilities_spec.sh` - Utility function tests (logging, paths, prerequisites, XDG support)
- `constants_spec.sh` - Constants validation tests

## Running Tests

To run the entire test suite, execute the following command from the project root:

```bash
shellspec
```

To run a specific test file:

```bash
# New modular structure (recommended)
shellspec tests/utilities/logging_spec.sh
shellspec tests/database/run_creation_spec.sh
shellspec tests/processing/file_discovery_spec.sh

# Legacy consolidated files (still supported)
shellspec tests/pndcgn_spec.sh
shellspec tests/config_spec.sh
shellspec tests/utilities_spec.sh
shellspec tests/database_spec.sh
shellspec tests/processing_spec.sh
```

To run all tests in a module:

```bash
shellspec tests/utilities/
shellspec tests/database/
shellspec tests/processing/
```

To run a specific test block by line number:

```bash
shellspec tests/pndcgn_spec.sh:25
```

## Coverage Reports

The test suite targets 90% minimum coverage. Coverage reports are generated using `kcov` via ShellSpec's `--kcov` flag.

### macOS Limitations

**Important**: kcov uses `ptrace` which has limitations on macOS. Coverage testing is **recommended on Linux** (Docker or CI).

### Local Testing (macOS)

```bash
# Attempt coverage (may fail on macOS due to ptrace limitations)
shellspec --kcov

# View HTML report (if generated)
open tests.results/coverage/index.html
```

### Linux Testing (Recommended)

**Option 1: Docker** ✅ **Verified Working**

```bash
# Build test image (includes ShellSpec 0.28.1 and kcov v40)
docker build -f Dockerfile.test -t pndcgn-test .

# Run tests with coverage
docker run --rm -v "$PWD:/workspace" -w /workspace pndcgn-test shellspec --kcov

# View coverage reports (generated in tests.results/coverage/)
open tests.results/coverage/index.html
```

**Status**: Docker-based coverage testing has been verified and works correctly. Coverage reports are generated successfully, though coverage percentages may still show 0% due to the `bash -c` sourcing pattern limitations (same as macOS).

**Option 2: GitHub Actions CI**

Coverage is automatically generated on push/PR via `.github/workflows/test-coverage.yml`. Coverage artifacts are uploaded and can be downloaded from the Actions tab.

### Coverage Reports Location

- **HTML Reports**: `tests.results/coverage/index.html`
- **Raw Data**: `tests.results/coverage/`
- **Test Reports**: `tests.results/reports/`

### Coverage Tracking Pattern

**Root Cause**: kcov traces the parent process only. ShellSpec's `When run` executes commands in a subprocess, which kcov cannot trace.

| ShellSpec Pattern | Execution | Coverage |
|-------------------|-----------|----------|
| `When call function` | Same process | ✅ **Works** |
| `When run script` | Subprocess | ❌ 0% |
| `When run bash -c "..."` | Subprocess | ❌ 0% |

**For coverage tracking, use `When call`:**

```bash
# At top of spec file - source the library
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

# ✅ Use When call - executes in same process, kcov tracks it
When call pndcgn_log_info "Test message"

# ❌ When run - executes in subprocess, kcov cannot trace
# When run "${SHELLSPEC_PROJECT_ROOT}/src/utilities.sh" log_info "Test message"
```

**When to use each pattern:**

| Use Case | Pattern | Coverage |
|----------|---------|----------|
| Unit tests (most functions) | `When call` | ✅ Tracked |
| Exit code testing | `When run` | ❌ Not tracked |
| Error handling (subprocess isolation) | `When run` | ❌ Not tracked |
| CLI argument parsing | `When run` | ❌ Not tracked |

**Status**:
- ✅ Root cause identified: `When run` = subprocess = 0% coverage
- ✅ Solution verified: `When call` = same process = coverage works
- ✅ Docker setup created for Linux testing
- ✅ CI workflow configured for automated coverage
- ⏳ Tests to be migrated to `When call` pattern where applicable
- 📋 See `.scratch/coverage-research-summary.md` for detailed analysis

### Integration Tests for Coverage

Integration tests (in `tests/integration/`) use **real implementations without mocks** to ensure accurate coverage tracking. Unit tests use mocks for isolation, but integration tests exercise actual code paths.

## Test Organization

Tests are organized by functional area matching the source module structure. **As of 2025-12-14, tests have been reorganized into separate files per function group for better organization and coverage tracking.**

### New Structure (Recommended)

Tests are now organized in subdirectories by module:

- **`tests/utilities/`**: Utility function tests
  - `logging_spec.sh`: Logging functions (info, error, warn)
  - `path_resolution_spec.sh`: Path resolution functions
  - `prerequisites_spec.sh`: Prerequisite validation
  - `ulid_spec.sh`: ULID generation fallback
  - `xdg_spec.sh`: XDG directory support
  - `fzf_spec.sh`: fzf integration

- **`tests/database/`**: Database operation tests
  - `run_creation_spec.sh`: Run creation with ULID generation
  - `cache_lookup_spec.sh`: Cache lookup functions
  - `fingerprint_storage_spec.sh`: Fingerprint storage and retrieval

- **`tests/processing/`**: Processing function tests
  - `file_discovery_spec.sh`: File discovery respecting .pndcgnignore
  - `fingerprint_computation_spec.sh`: Input file fingerprint computation
  - `pandoc_conversion_spec.sh`: Pandoc conversion functions
  - `dewey_naming_spec.sh`: Dewey Decimal naming scheme
  - `output_directory_spec.sh`: Output directory creation
  - `index_generation_spec.sh`: Run index generation
  - `output_fingerprint_spec.sh`: Output fingerprint computation
  - `run_fingerprint_spec.sh`: Run fingerprint computation
  - `fingerprint_validation_spec.sh`: Fingerprint validation

### Legacy Structure (Deprecated)

The following files are maintained for backward compatibility but are being phased out:
- **`utilities_spec.sh`**: Consolidated utilities tests (use `tests/utilities/*` instead)
- **`database_spec.sh`**: Consolidated database tests (use `tests/database/*` instead)
- **`processing_spec.sh`**: Consolidated processing tests (use `tests/processing/*` instead)

### Integration Tests (No Mocks)

Integration tests exercise real implementations without mocks for accurate coverage tracking:

- **`tests/integration/`**: Integration tests without mocks
  - `database_integration_spec.sh`: Real SQLite database operations
  - `processing_integration_spec.sh`: Real file operations and processing
  - `utilities_integration_spec.sh`: Real utility functions without command mocking

**Purpose**: These tests ensure actual code paths are executed and tracked by coverage tools. Unit tests use mocks for isolation, but integration tests use real implementations.

### Other Test Files

- **`pndcgn_spec.sh`**: Tests for `bin/pndcgn` entrypoint (CLI integration)
- **`config_spec.sh`**: Tests for configuration management (legacy - may need reorganization)
- **`constants_spec.sh`**: Tests for constants validation (`src/constants.sh`)
- **`performance_spec.sh`**: Performance benchmark tests
- **`usability_spec.sh`**: Usability test scenarios

## Test Helper

The `spec_helper.sh` file provides:
- Test environment setup/cleanup
- Mock framework for external commands (pandoc, sqlite3, curl, fzf, git)
- Shared constants sourcing

## Test Results

Test execution results are captured and stored in `tests.results/` at the repository root. Each test run generates:
- Log files: `tests.results/logs/{test-name}-{YYYYMMDD-HHMMSS}.log` (raw ShellSpec output, automatically removed after processing)
- Markdown reports: `tests.results/reports/{test-name}-{YYYYMMDD-HHMMSS}.md` (formatted reports with summaries)
- Coverage reports: `tests.results/coverage/index.html` (when running with `--kcov`)

See `tests.results/README.md` for details on report format and generation.
