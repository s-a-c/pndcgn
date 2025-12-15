# Test Scripts Library

**Compliant with [AGENTS.md](../AGENTS.md)**

This directory contains bash scripts for running individual tests, test suites, and local CI/CD workflows.

---

## Quick Reference

```bash
# Run individual test
./scripts/run-test.sh tests/utilities/logging_spec.sh

# Run test suites
./scripts/run-unit-tests.sh
./scripts/run-feature-tests.sh
./scripts/run-integration-tests.sh
./scripts/run-all-tests.sh

# Run with coverage
./scripts/run-coverage.sh all

# Run local CI/CD workflow
./scripts/local-ci.sh
```

---

## Scripts Overview

### Core Test Runners

#### `run-test.sh`
Run a single test file or specific test block.

**Usage:**
```bash
./scripts/run-test.sh <test-file> [line-number]
./scripts/run-test.sh tests/utilities/logging_spec.sh
./scripts/run-test.sh tests/pndcgn_spec.sh 25
./scripts/run-test.sh utilities/logging_spec.sh
```

**Examples:**
- Run entire test file: `./scripts/run-test.sh tests/utilities/logging_spec.sh`
- Run specific test block: `./scripts/run-test.sh tests/pndcgn_spec.sh 25`
- Relative path: `./scripts/run-test.sh utilities/logging_spec.sh`

---

#### `run-unit-tests.sh`
Run all unit tests (modular test files with mocks).

**Usage:**
```bash
./scripts/run-unit-tests.sh [--coverage]
```

**What it runs:**
- `tests/utilities/*.sh` - Utility function tests
- `tests/database/*.sh` - Database operation tests
- `tests/processing/*.sh` - Processing function tests
- `tests/constants_spec.sh` - Constants validation
- `tests/config_spec.sh` - Configuration management

**Options:**
- `--coverage` / `-c`: Run with kcov coverage

---

#### `run-feature-tests.sh`
Run feature/integration tests for CLI and end-to-end scenarios.

**Usage:**
```bash
./scripts/run-feature-tests.sh [--coverage]
```

**What it runs:**
- `tests/pndcgn_spec.sh` - Main CLI entrypoint tests
- `tests/performance_spec.sh` - Performance benchmarks
- `tests/usability_spec.sh` - Usability scenarios

**Options:**
- `--coverage` / `-c`: Run with kcov coverage

---

#### `run-integration-tests.sh`
Run integration tests without mocks (real implementations).

**Usage:**
```bash
./scripts/run-integration-tests.sh [--coverage]
```

**What it runs:**
- `tests/integration/*.sh` - Integration tests with real implementations

**Options:**
- `--coverage` / `-c`: Run with kcov coverage

**Note:** These tests use real implementations (no mocks) for accurate coverage tracking.

---

#### `run-all-tests.sh`
Run all test suites (unit, feature, integration).

**Usage:**
```bash
./scripts/run-all-tests.sh [--coverage] [--skip-integration]
```

**Options:**
- `--coverage` / `-c`: Run with kcov coverage
- `--skip-integration` / `-s`: Skip integration tests

**What it runs:**
1. Unit tests (`run-unit-tests.sh`)
2. Feature tests (`run-feature-tests.sh`)
3. Integration tests (`run-integration-tests.sh`) - unless skipped

---

### Coverage

#### `run-coverage.sh`
Run tests with kcov coverage reporting.

**Usage:**
```bash
./scripts/run-coverage.sh [suite]
```

**Suites:**
- `unit` - Unit tests only
- `feature` - Feature tests only
- `integration` - Integration tests only
- `all` - All test suites (default)

**Examples:**
```bash
./scripts/run-coverage.sh unit
./scripts/run-coverage.sh all
./scripts/run-coverage.sh  # defaults to 'all'
```

**Note:** Coverage works best on Linux. macOS has ptrace limitations. Use Docker or CI for accurate results.

---

### CI/CD

#### `local-ci.sh`
Run local CI/CD workflow (lint, test, coverage, reports).

**Usage:**
```bash
./scripts/local-ci.sh [--skip-lint] [--skip-coverage] [--clean]
```

**Workflow Steps:**
1. **Linting**: ShellCheck on all scripts
2. **Unit Tests**: Run unit test suite
3. **Feature Tests**: Run feature test suite
4. **Integration Tests**: Run integration test suite
5. **Coverage**: Generate coverage reports (optional)

**Options:**
- `--skip-lint`: Skip ShellCheck linting
- `--skip-coverage`: Skip coverage generation
- `--clean`: Clean old results before running

**Examples:**
```bash
# Full CI workflow
./scripts/local-ci.sh

# Skip coverage (faster)
./scripts/local-ci.sh --skip-coverage

# Clean and run
./scripts/local-ci.sh --clean
```

---

## Common Functions Library

### `common.sh`
Shared functions and constants used by all scripts.

**Key Functions:**
- `print_info()`, `print_success()`, `print_warning()`, `print_error()` - Colored output
- `check_prerequisites()` - Verify shellspec is installed
- `ensure_results_dirs()` - Create results directories
- `run_shellspec()` - Run shellspec with common options
- `run_shellspec_with_coverage()` - Run shellspec with kcov
- `generate_report()` - Generate test reports
- `print_summary()` - Print test summary

**Constants:**
- `PROJECT_ROOT` - Project root directory
- `TESTS_DIR` - Tests directory (`tests/`)
- `RESULTS_DIR` - Results directory (`tests.results/`)
- `COVERAGE_DIR` - Coverage directory (`tests.results/coverage/`)
- `REPORTS_DIR` - Reports directory (`tests.results/reports/`)
- `LOGS_DIR` - Logs directory (`tests.results/logs/`)

---

## Test Organization

### Unit Tests (with mocks)
- `tests/utilities/*.sh` - Utility functions
- `tests/database/*.sh` - Database operations
- `tests/processing/*.sh` - Processing functions
- `tests/constants_spec.sh` - Constants
- `tests/config_spec.sh` - Configuration

### Feature Tests
- `tests/pndcgn_spec.sh` - CLI entrypoint
- `tests/performance_spec.sh` - Performance
- `tests/usability_spec.sh` - Usability

### Integration Tests (no mocks)
- `tests/integration/*.sh` - Real implementations

---

## Output Locations

All scripts write results to `tests.results/`:

- **Logs**: `tests.results/logs/{test-name}-{timestamp}.log`
- **Reports**: `tests.results/reports/{test-name}-{timestamp}.md`
- **Coverage**: `tests.results/coverage/index.html` (when using `--coverage`)

---

## Examples

### Development Workflow

```bash
# Quick test during development
./scripts/run-test.sh tests/utilities/logging_spec.sh

# Run all unit tests
./scripts/run-unit-tests.sh

# Run with coverage
./scripts/run-coverage.sh unit
```

### Pre-Commit

```bash
# Quick CI check
./scripts/local-ci.sh --skip-coverage

# Full check
./scripts/local-ci.sh
```

### CI/CD Simulation

```bash
# Simulate CI workflow
./scripts/local-ci.sh --clean
```

---

## Prerequisites

- **shellspec**: Test framework
  - Install: `brew install shellspec`
- **kcov**: Coverage tool (optional, for coverage)
  - Install: `brew install kcov`
  - Note: Works best on Linux (Docker or CI)
- **shellcheck**: Linting (optional, for CI)
  - Install: `brew install shellcheck`

---

## Troubleshooting

### kcov fails on macOS
**Issue**: "Can't start/attach" errors
**Solution**: Use Docker (`Dockerfile.test`) or CI (`.github/workflows/test-coverage.yml`)

### Test file not found
**Issue**: Script can't find test file
**Solution**: Use relative path from `tests/` directory or full path

### Permission denied
**Issue**: Script not executable
**Solution**: `chmod +x scripts/*.sh`

---

## See Also

- [Test Suite Documentation](../tests/README.md)
- [Coverage Research](../.scratch/coverage-research-summary.md)
- [Coverage Implementation Status](../.scratch/coverage-implementation-status.md)
- [Docker Testing](../Dockerfile.test)
- [CI Workflow](../.github/workflows/test-coverage.yml)

---

**Last Updated**: 2025-12-14
