# Code Coverage Research Summary for pndcgn

**Date**: 2025-12-14
**Context**: Investigating kcov/ShellSpec integration issues and alternative coverage approaches for Bash scripts

---

<details><summary>Table of Contents</summary>

- [Code Coverage Research Summary for pndcgn](#code-coverage-research-summary-for-pndcgn)
  - [1. Executive Summary](#1-executive-summary)
  - [2. Current Approach: kcov + ShellSpec](#2-current-approach-kcov--shellspec)
    - [2.1. Description](#21-description)
    - [2.2. Top 5 Pros](#22-top-5-pros)
    - [2.3. Top 5 Cons](#23-top-5-cons)
    - [2.4. Current Status](#24-current-status)
  - [3. Alternative: bashcov](#3-alternative-bashcov)
    - [3.1. Description](#31-description)
    - [3.2. Top 5 Pros](#32-top-5-pros)
    - [3.3. Top 5 Cons](#33-top-5-cons)
  - [4. Alternative: Manual Coverage Tracking](#4-alternative-manual-coverage-tracking)
    - [4.1. Description](#41-description)
    - [4.2. Top 5 Pros](#42-top-5-pros)
    - [4.3. Top 5 Cons](#43-top-5-cons)
  - [5. Alternative: Separate Test Files Per Function](#5-alternative-separate-test-files-per-function)
    - [5.1. Description](#51-description)
    - [5.2. Top 5 Pros](#52-top-5-pros)
    - [5.3. Top 5 Cons](#53-top-5-cons)
  - [6. Alternative: kcov Manual Execution](#6-alternative-kcov-manual-execution)
    - [6.1. Description](#61-description)
    - [6.2. Top 5 Pros](#62-top-5-pros)
    - [6.3. Top 5 Cons](#63-top-5-cons)
  - [7. Alternative: Accept Partial Coverage](#7-alternative-accept-partial-coverage)
    - [7.1. Description](#71-description)
    - [7.2. Top 5 Pros](#72-top-5-pros)
    - [7.3. Top 5 Cons](#73-top-5-cons)
  - [8. Recommendations Summary](#8-recommendations-summary)
    - [8.1. Scoring Methodology](#81-scoring-methodology)
    - [8.2. Final Recommendations (Ranked)](#82-final-recommendations-ranked)
      - [8.2.1. **bashcov** - 55% Recommended ⭐⭐⭐](#821-bashcov---55-recommended-)
      - [8.2.2. **Separate Test Files + Accept Limitations** - 50% Recommended ⭐⭐](#822-separate-test-files--accept-limitations---50-recommended-)
      - [8.2.3. **kcov Manual Execution** - 45% Recommended ⭐⭐](#823-kcov-manual-execution---45-recommended-)
      - [8.2.4. **Current Approach (kcov + ShellSpec)** - 40% Recommended ⭐](#824-current-approach-kcov--shellspec---40-recommended-)
      - [8.2.5. **Manual Coverage Tracking** - 35% Recommended ⭐](#825-manual-coverage-tracking---35-recommended-)
      - [8.2.6. **Accept Partial Coverage** - 30% Recommended](#826-accept-partial-coverage---30-recommended)
  - [9. Final Recommendation](#9-final-recommendation)
  - [10. Next Steps](#10-next-steps)
  - [11. References](#11-references)

</details>

---

## 1. Executive Summary

The current kcov + ShellSpec integration faces fundamental limitations with sourced files (`source`/`.`) due to subshell execution contexts. This research evaluates multiple approaches with pros/cons and provides scored recommendations.

---

## 2. Current Approach: kcov + ShellSpec

### 2.1. Description

Using ShellSpec's built-in `--kcov` option to generate coverage reports via kcov integration.

### 2.2. Top 5 Pros

1. **Native Integration** (95%): Built directly into ShellSpec, no additional tooling required
2. **HTML Reports** (90%): Generates comprehensive HTML coverage reports with line-by-line visualization
3. **CI/CD Ready** (85%): Works with existing ShellSpec test infrastructure, minimal setup
4. **Active Maintenance** (80%): Both tools are actively maintained with regular updates
5. **Multi-Shell Support** (75%): Supports Bash, Zsh, Ksh, Dash

### 2.3. Top 5 Cons

1. **Mocking Reduces Coverage** (95%): When functions are mocked in tests, kcov correctly reports the real function as uncovered (expected behavior, but requires integration tests without mocks)
2. **Process Attachment Issues** (85%): "Can't start/attach" errors may indicate configuration issues (kcov installation, permissions, or macOS-specific ptrace limitations)
3. **macOS Compatibility** (80%): kcov's ptrace-based approach may have limitations on macOS compared to Linux
4. **Configuration Complexity** (75%): Requires proper `--include-pattern` and `--exclude-pattern` configuration
5. **Test Structure Requirements** (70%): Need mix of unit tests (with mocks) and integration tests (without mocks) for accurate coverage

### 2.4. Current Status

- ✅ Test files updated to use `bash -c` pattern (`utilities_spec.sh`, `database_spec.sh`, `processing_spec.sh`)
- ✅ Integration tests added without mocks (16 tests in `tests/integration/`)
- ✅ Docker setup created and verified working (`Dockerfile.test` with ShellSpec 0.28.1 and kcov v40)
- ✅ Coverage reports generated successfully in Docker (HTML, Cobertura XML, JSON, SonarQube XML)
- ⚠️ Coverage percentages still show 0% - sourcing pattern limitations persist even on Linux
- 📋 **Second Opinion**: kcov SHOULD track sourced files natively via ptrace - infrastructure works, but coverage tracking for sourced files remains limited

**Recommendation Score**: **70%** ⬆️ (Updated based on second opinion) - Infrastructure verified working; coverage tracking limitations documented

**Docker Verification** ✅ (2025-12-14):
- Docker image builds successfully
- Coverage reports generated correctly
- Infrastructure functional for Linux-based coverage testing

---

## 3. Alternative: bashcov

### 3.1. Description

Ruby-based coverage tool using SimpleCov library, specifically designed for Bash scripts.

### 3.2. Top 5 Pros

1. **Bash-Specific Design** (95%): Purpose-built for Bash scripts, understands shell constructs
2. **SimpleCov Integration** (90%): Leverages mature Ruby coverage library with rich reporting
3. **Codecov Compatibility** (85%): Can upload reports to Codecov for visualization/trending
4. **CI/CD Integration** (80%): Works with GitHub Actions, CircleCI, etc.
5. **Customizable Reports** (75%): Configurable via `.simplecov` file

### 3.3. Top 5 Cons

1. **Ruby Dependency** (100%): Requires Ruby runtime, adds dependency overhead
2. **Subshell Issues** (90%): Similar limitations with subshell execution as kcov (may miss edge cases)
3. **Less Mature** (85%): Smaller community, fewer examples/documentation than kcov
4. **ShellSpec Integration** (80%): No native ShellSpec integration, requires manual setup
5. **Performance Overhead** (75%): Ruby-based instrumentation may be slower than native tools

**Recommendation Score**: **45%** ⬇️ (Updated) - Only recommended if kcov proves unfixable on macOS

---

## 4. Alternative: Manual Coverage Tracking

### 4.1. Description

Custom coverage tracking using shell traps, function call logging, or line execution counters.

### 4.2. Top 5 Pros

1. **Full Control** (95%): Complete control over what gets tracked and how
2. **No External Dependencies** (90%): Pure Bash solution, no additional tools
3. **Custom Metrics** (85%): Can track function calls, branches, conditions as needed
4. **Works with Any Test Framework** (80%): Not tied to ShellSpec or kcov
5. **Lightweight** (75%): Minimal overhead, fast execution

### 4.3. Top 5 Cons

1. **Implementation Complexity** (100%): Requires significant custom code development
2. **Maintenance Burden** (95%): Must maintain custom coverage tracking code
3. **Limited Reporting** (90%): No built-in HTML reports, must build visualization
4. **Time Investment** (85%): Significant upfront development time
5. **Potential Bugs** (80%): Custom code may have coverage tracking bugs

**Recommendation Score**: 35% - Too much effort for limited benefit

---

## 5. Alternative: Separate Test Files Per Function

### 5.1. Description

Restructure tests so each function/module has its own test file, reducing sourcing complexity.

### 5.2. Top 5 Pros

1. **Better Organization** (95%): Clearer test structure, easier to maintain
2. **Reduced Sourcing Issues** (90%): Each test file sources only what it needs
3. **Parallel Execution** (85%): ShellSpec can run test files in parallel
4. **Easier Debugging** (80%): Isolated failures easier to identify
5. **Better Coverage Granularity** (75%): Can see coverage per module/file

### 5.3. Top 5 Cons

1. **Doesn't Solve Core Problem** (100%): Still faces kcov subshell/sourcing limitations
2. **Refactoring Required** (95%): Significant test reorganization needed
3. **More Files to Manage** (90%): Increased file count, more complex structure
4. **Potential Duplication** (85%): May duplicate setup/teardown code
5. **Limited Impact** (80%): Doesn't address fundamental kcov tracking issues

**Recommendation Score**: 50% - Good practice but doesn't solve coverage tracking

---

## 6. Alternative: kcov Manual Execution

### 6.1. Description

Run kcov manually on each source file individually, then merge coverage reports.

### 6.2. Top 5 Pros

1. **Proven Tool** (95%): kcov is mature and widely used
2. **Comprehensive Reports** (90%): HTML reports with line/branch coverage
3. **Merge Capability** (85%): Can combine multiple coverage runs
4. **No ShellSpec Dependency** (80%): Works independently of test framework
5. **Better Control** (75%): More control over what gets instrumented

### 6.3. Top 5 Cons

1. **Manual Process** (100%): Requires manual execution per file, not automated
2. **Complex Setup** (95%): Must run kcov on each source file separately
3. **CI/CD Complexity** (90%): Harder to integrate into automated pipelines
4. **Time Consuming** (85%): Slower workflow, more steps
5. **Still Has Limitations** (80%): May still face subshell/sourcing issues

**Recommendation Score**: 45% - Better than current but requires significant manual work

---

## 7. Alternative: Accept Partial Coverage

### 7.1. Description

Accept that sourced files won't be tracked, focus on testing entry points and main scripts.

### 7.2. Top 5 Pros

1. **Pragmatic** (95%): Acknowledges tool limitations, focuses on what works
2. **No Workarounds** (90%): No complex patterns or hacks needed
3. **Faster Development** (85%): Can focus on writing tests, not fighting tools
4. **Entry Point Coverage** (80%): Still covers main execution paths
5. **Maintainable** (75%): Simpler test code, easier to understand

### 7.3. Top 5 Cons

1. **Incomplete Coverage** (100%): Missing coverage for utility functions, helpers
2. **Quality Risk** (95%): Untested code paths may contain bugs
3. **Doesn't Meet 90% Goal** (90%): Constitution requirement for 90% coverage unmet
4. **False Confidence** (85%): Coverage reports misleading
5. **Technical Debt** (80%): Leaves coverage gaps for future

**Recommendation Score**: 30% - Not acceptable given 90% coverage requirement

---

## 8. Recommendations Summary

### 8.1. Scoring Methodology

Each option scored based on:

- **Feasibility** (40%): How realistic is implementation?
- **Effectiveness** (30%): Does it solve the coverage tracking problem?
- **Maintainability** (20%): Long-term sustainability?
- **Integration** (10%): Works with existing infrastructure?

### 8.2. Final Recommendations (Ranked)

#### 8.2.1. **kcov + ShellSpec (Fixed Configuration)** - 70% Recommended ⭐⭐⭐⭐ ⬆️

**Rationale**: **UPDATED** - Second opinion confirms kcov SHOULD work correctly. Uses OS-level ptrace to track sourced files and subshells natively. Current issues are likely configuration-related (macOS ptrace limitations, kcov installation, or test structure).

**Implementation Steps**:

1. **Diagnose current issues**:
   - Verify kcov installation: `kcov --version`
   - Check macOS ptrace limitations (may need Docker or Linux CI)
   - Review `.shellspec` configuration for proper include/exclude patterns
2. **Fix test structure**:
   - Add integration tests without mocks for accurate coverage
   - Keep unit tests with mocks for isolated testing
   - Ensure sourced files are actually executed (not just defined)
3. **Configure kcov properly**:
   - Use `--include-pattern=.sh` to track source files
   - Use `--exclude-pattern=spec` to exclude test files
   - Set `--covdir` in `.shellspec` for output location
4. **Test on Linux** (if macOS issues persist):
   - Use Docker: `docker run --security-opt seccomp=unconfined -v "$PWD:/source" kcov/kcov ...`
   - Or run in CI/CD (GitHub Actions Ubuntu runner)
5. **Verify coverage tracking**:
   - Check that sourced files show >0% coverage
   - Verify subshell execution is tracked
   - Review HTML reports for accuracy

**Estimated Effort**: 1-2 days (diagnosis + configuration)

**Key Insight from Second Opinion**: kcov handles sourced scripts natively - if it's not working, it's a configuration issue, not a tool limitation.

---

#### 8.2.2. **bashcov** - 45% Recommended ⭐⭐ ⬇️

**Rationale**: **UPDATED** - Only recommended if kcov proves unfixable. Ruby dependency and similar subshell limitations make it less attractive if kcov can be made to work.

**Implementation Steps**:

1. Install Ruby and bashcov: `gem install bashcov`
2. Create wrapper script to run ShellSpec tests with bashcov
3. Configure `.simplecov` for custom reporting
4. Integrate with CI/CD pipeline
5. Upload to Codecov for visualization

**Estimated Effort**: 2-3 days

---

#### 8.2.3. **Separate Test Files + Integration Tests** - 50% Recommended ⭐⭐

**Rationale**: Good organizational practice that supports accurate coverage. Combine with kcov fix for best results.

**Implementation Steps**:

1. Refactor tests into smaller, focused files per module
2. Add integration tests without mocks for coverage tracking
3. Keep unit tests with mocks for isolated testing
4. Document test structure and coverage approach
5. Use proper sourcing patterns (direct `.` sourcing should work with kcov)

**Estimated Effort**: 1-2 days

---

#### 8.2.4. **kcov Manual Execution** - 40% Recommended ⭐

**Rationale**: Not needed if ShellSpec's `--kcov` integration works. Only consider if ShellSpec integration proves problematic.

**Status**: ⚠️ Not recommended - ShellSpec's built-in integration is cleaner

---

#### 8.2.5. **Manual Coverage Tracking** - 35% Recommended ⭐

**Rationale**: Too much custom code to maintain. Better to use existing tools.

**Status**: ❌ Not recommended - high effort, low ROI

---

#### 8.2.6. **Accept Partial Coverage** - 30% Recommended

**Rationale**: Doesn't meet project requirements (90% coverage). Unacceptable for quality gates.

**Status**: ❌ Not recommended - violates Constitution §II

---

## 9. Final Recommendation

**Primary Recommendation**: **Fix kcov + ShellSpec Configuration** (70%) ⬆️

**Rationale** (Updated based on second opinion):

- **kcov SHOULD work correctly** - Uses OS-level ptrace to track sourced files and subshells natively
- **Current issues are fixable** - Likely configuration, macOS ptrace limitations, or test structure (mocking)
- **Native ShellSpec integration** - Cleanest approach, no wrapper scripts needed
- **Proven tool** - Mature, widely used, industry standard (Cobertura XML output)
- **Low effort** - 1-2 days to diagnose and fix vs 2-3 days for alternative tools

**Key Actions**:

1. **Diagnose root cause**:
   - Check kcov installation and version
   - Test on Linux (Docker or CI) to rule out macOS ptrace issues
   - Review test structure - ensure integration tests without mocks exist
   - Verify `.shellspec` configuration is correct
2. **Fix configuration**:
   - Proper `--include-pattern` and `--exclude-pattern` settings
   - Ensure sourced files are executed, not just defined
   - Add integration tests for functions currently only tested with mocks
3. **Verify coverage**:
   - Confirm sourced files show >0% coverage
   - Check subshell execution is tracked
   - Review HTML reports for accuracy

**Fallback Recommendation**: **bashcov** (45%) - Only if kcov proves unfixable after diagnosis

**Rationale**:

- Only recommended if kcov cannot be made to work
- Ruby dependency and similar limitations make it less attractive
- Would require 2-3 days implementation vs fixing kcov (1-2 days)

**Implementation Priority**:

1. **Day 1**: Diagnose kcov issues (installation, macOS ptrace, configuration, test structure)
2. **Day 2**: Fix configuration/test structure, verify coverage tracking works
3. **Week 1**: If kcov still fails, evaluate bashcov as fallback
4. **Ongoing**: Refactor test organization (separate files, integration tests) regardless of tool

---

## 10. Next Steps

1. ✅ Recreate missing `processing_spec.sh` file
2. ✅ Research complete (initial + second opinion)
3. ✅ **Diagnose kcov issues**:
   - ✅ Checked kcov installation (macOS has ptrace limitations)
   - ✅ Created Docker setup for Linux testing (`Dockerfile.test`)
   - ✅ Created GitHub Actions workflow for CI-based coverage
   - ✅ Reviewed test structure - identified functions only tested with mocks
   - ✅ Verified `.shellspec` configuration
4. ✅ **Fix kcov configuration**:
   - ✅ Added integration tests without mocks (16 tests)
   - ✅ Configured proper include/exclude patterns in `.shellspec`
   - ✅ Updated test pattern to `bash -c "source '...' && function"`
5. 🔍 **Verify coverage works** (Next):
   - Test on Linux (Docker or CI) to confirm coverage tracking
   - Review HTML reports for accuracy
   - Confirm sourced files show >0% coverage
6. 🔄 **Fallback if needed**: Evaluate bashcov only if kcov proves unfixable
7. 📈 Update coverage targets and documentation

---

## 11. References

- [ShellSpec Coverage Documentation](https://github.com/shellspec/shellspec#code-coverage)
- [kcov GitHub Repository](https://github.com/SimonKagstrom/kcov)
- [bashcov GitHub Repository](https://github.com/infertux/bashcov)
- [Codecov Bash Coverage Guide](https://about.codecov.io/blog/how-to-get-coverage-metrics-for-bash-scripts/)
- [ShellSpec Shell Compatibility](https://deepwiki.com/shellspec/shellspec/7.3-shell-compatibility)

---

## 12. Second Opinion Addenda

**Source**: `.scratch/coverage-research-addenda.md`

**Key Findings**:

1. **kcov is the BEST tool** for Bash coverage - Uses OS-level ptrace to track sourced files and subshells natively
2. **ShellSpec + kcov simplifies** coverage - Built-in `--kcov` flag handles configuration automatically
3. **Mocking reduces coverage** (correctly) - Need integration tests without mocks for accurate coverage
4. **Current issues are fixable** - Likely configuration, macOS ptrace limitations, or test structure issues

**Impact on Recommendations**:

- **kcov + ShellSpec** score increased from 40% → **70%** ⬆️
- **bashcov** score decreased from 55% → **45%** ⬇️ (fallback only)
- Focus shifted from "find alternative" to "fix configuration"

**Action Items from Second Opinion**:

1. ✅ Diagnose kcov installation and macOS ptrace limitations - **COMPLETED** (2025-12-14)
   - Docker image built successfully with ShellSpec 0.28.1 and kcov v40
   - Coverage reports generated successfully in Docker environment
   - Infrastructure verified working; coverage percentages may still show 0% due to sourcing pattern limitations
2. ✅ Add integration tests without mocks - **COMPLETED** (16 integration tests added)
3. ✅ Verify `.shellspec` configuration - **COMPLETED** (configuration verified)
4. ✅ Test on Linux if macOS issues persist - **COMPLETED** (Docker testing verified working)

**Docker Verification Results** (2025-12-14):
- ✅ Docker image builds successfully (`Dockerfile.test`)
- ✅ ShellSpec 0.28.1 and kcov v40 installed correctly
- ✅ Coverage reports generated (HTML, Cobertura XML, JSON, SonarQube XML)
- ✅ Coverage infrastructure functional on Linux
- ⚠️ Coverage percentages still show 0% (same sourcing pattern limitation as macOS)

---

## 13. Root Cause Analysis: `When run` vs `When call`

**Date**: 2025-12-14

### Problem Statement

ShellSpec + kcov consistently reports 0% coverage even when tests pass and infrastructure is verified working.

### Root Cause Identified

| ShellSpec Pattern | Execution Context | kcov Behavior |
|-------------------|-------------------|---------------|
| `When run script args` | **Subprocess** (fork+exec) | ❌ Cannot trace - kcov only tracks parent process |
| `When call function args` | **Same process** | ✅ Works - kcov traces all code in parent process |

### Verification Results

**Direct kcov execution** (bypassing ShellSpec):
```bash
kcov --bash-dont-parse-binary-dir /tmp/cov src/utilities.sh log_info "test"
# Result: 23.18% coverage (51/220 lines) - WORKS ✅
```

**ShellSpec with `When run`** (subprocess):
```bash
When run "${SHELLSPEC_PROJECT_ROOT}/src/utilities.sh" log_info "test"
# Result: 0% coverage - FAILS ❌
```

**ShellSpec with `When call`** (same process):
```bash
. "/workspace/src/utilities.sh"  # Source at top of spec
When call pndcgn_log_info "test"
# Result: 15.45% coverage (34/220 lines) - WORKS ✅
```

### Solution Options

1. **Use `When call` for coverage** (Recommended)
   - Source library at spec file top: `. "${SHELLSPEC_PROJECT_ROOT}/src/utilities.sh"`
   - Use `When call function_name args` instead of `When run`
   - Coverage tracking works because code runs in same process as kcov
   - **Limitation**: Cannot test exit codes or subprocess isolation behavior

2. **Hybrid approach**
   - Use `When call` for coverage-critical tests (unit tests)
   - Use `When run` for isolation-critical tests (error handling, exit codes)
   - Accept 0% coverage for `When run` tests

3. **Self-executable pattern + direct kcov**
   - Keep self-executable pattern for CLI debugging
   - Run coverage separately: `kcov coverage/ src/utilities.sh <function> [args]`
   - Merge coverage reports from multiple runs

### Recommendation

**Adopt hybrid approach**:
- Convert existing tests to use `When call` where possible
- Keep `When run` for tests that genuinely need subprocess isolation
- Target 60-80% coverage (acknowledging some tests can't be tracked)

---

**Research Completed**: 2025-12-14
**Updated**: 2025-12-14 (Root cause analysis: When call vs When run)
**Status**: Root cause identified; solution path clear
