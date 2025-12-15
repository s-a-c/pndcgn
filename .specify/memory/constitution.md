# PNDCGN Constitution

## Core Principles

### I. Shell-First Architecture (NON-NEGOTIABLE)

**Bash as Foundation**: All core functionality MUST be implemented in Bash shell scripts.

- Pure Bash implementation required for main controller and all modules
- No Python, Ruby, or other language dependencies for core logic
- Strict mode MUST be enforced: `set -euo pipefail`
- Function namespacing REQUIRED: All functions use `pndcgn_` prefix
- Variable namespacing REQUIRED: All globals use `pndcgn_` or `PNDCGN_` prefix

**Rationale**: Ensures portability, minimal dependencies, and alignment with Unix philosophy of composable, single-purpose tools.

### II. Test-First Development (NON-NEGOTIABLE)

**BDD/TDD Mandatory**: Tests written → User approved → Tests fail → Then implement.

- Red-Green-Refactor cycle strictly enforced
- ShellSpec framework REQUIRED for all tests
- **Minimum 50% code coverage target** (realistic given kcov/ShellSpec limitations)
- Target 70% coverage for utility modules using `When call` pattern
- Tests MUST be executable with `bash` (not dependent on user's shell configuration)
- Every requirement in `docs/020-requirements.md` MUST have corresponding test in `docs/100-system-test-plan.md`
- Every function in `docs/070-api-reference.md` MUST have unit test in `docs/120-feature-unit-test-plan.md`

**Test Categories**:
- Unit tests: Test individual functions in isolation
- Integration tests: Test component interactions
- System tests: End-to-end BDD scenarios with Given-When-Then format

**Coverage Tracking Patterns** (kcov + ShellSpec):
- Use `When call function_name` for same-process execution (coverage tracked)
- Use `When run script` only when subprocess isolation required (mocking, exit codes)
- Tests using `When run` will show 0% coverage due to kcov subprocess limitation
- See `tests/README.md` for detailed coverage patterns

**Prohibition**: No implementation without corresponding failing test first.

### III. Documentation-Driven Design

**Living Documentation**: Documentation drives implementation, not vice versa.

- All features MUST be specified in `docs/020-requirements.md` as BDD user stories before implementation
- Technical specifications in `docs/050-technical-specification.md` MUST be updated before architectural changes
- API reference in `docs/070-api-reference.md` MUST define function signatures before implementation
- Test plans MUST be written before tests
- User guide MUST reflect actual behavior (update with implementation changes)

**Hierarchical Numbering**: All documentation MUST use sequential numbering (1, 1.1, 1.1.1) excluding main title.

**Traceability**: REQ-XXX → TEST-XXX → Implementation mapping MUST be maintained.

### IV. State Management via SQLite

**Database as Single Source of Truth**: All persistent state MUST be stored in SQLite.

- No flat file state tracking (JSON, YAML, text files)
- WAL (Write-Ahead Logging) mode REQUIRED for concurrent access
- ULID-based run identifiers for sortable, timestamp-embedded IDs
- Fingerprint-based caching using `{size}:{mtime}:{sha256_partial}` format
- All database operations via parameterized queries (`.param set`)

**Schema Stability**: Database schema changes MUST include migration strategy.

### V. Intelligent Caching

**Cache-First Philosophy**: Never reprocess unchanged content.

- Fingerprint computation MUST be O(1) - only first 64KB hashed
- Cache hit/miss ratio MUST be tracked and reported
- Dependency tracking MUST trigger cascading regeneration
- `--force` flag bypasses cache; `--clean` removes cache entries
- Stale cache detection via fingerprint validation

**Idempotency**: Running tool twice with unchanged inputs MUST produce identical output without reprocessing.

### VI. Resumable Operations

**Crash Resilience**: All long-running operations MUST be resumable.

- Incomplete runs MUST be detectable on next invocation
- `--resume` flag continues from last checkpoint
- Fingerprint validation ensures consistency before resumption
- Dry-run → finalize workflow via `--dry-run` then `--finalize RUN_ID`
- Database tracks run state: `running`, `complete`, `failed`, `interrupted`

### VII. Unix Philosophy

**Composable Tools**: Follow Unix principles religiously.

- Do one thing well: Convert markdown to formats via Pandoc
- Text in/out: Logs to stdout, errors to stderr
- Exit codes: 0 = success, 1 = error, 2 = invalid usage
- Work as part of pipelines: Accept paths as arguments
- Respect XDG standards: State in `$XDG_STATE_HOME/pndcgn/`
- Configuration in `pndcgn.toml` or `$XDG_CONFIG_HOME`

**No Surprises**: Minimize side effects, explicit over implicit.

## Technical Standards

### 1. Code Quality

**Linting**:
- ShellCheck MUST pass for all shell scripts
- No warnings or errors permitted
- Exceptions MUST be documented with inline comments

**Style Guide**:
- 4-space indentation (no tabs)
- Quote all variable expansions: `"${var}"`
- Use `[[ ]]` over `[ ]` for conditionals
- Lowercase with underscores for local variables: `source_dir`
- Uppercase for constants: `PNDCGN_DB`
- Function naming: verb-noun pattern (`pndcgn_compute_fingerprint`)

**Error Handling**:
- Fatal errors exit immediately with descriptive message
- Recoverable errors logged and processing continues
- Cleanup via trap handlers: `trap cleanup EXIT INT TERM`
- Custom error function: `pndcgn_fail()` for consistent formatting

### 2. Module Structure

**Organization**:
```
bin/pndcgn               # Main controller
src/constants.sh         # ANSI codes and shared constants
src/database.sh          # SQLite operations (not yet implemented)
src/processing.sh        # Conversion logic (not yet implemented)
src/utilities.sh         # Helper functions (not yet implemented)
tests/spec_helper.sh     # Test framework setup
tests/*.spec.sh          # ShellSpec test files
```

**Sourcing Order** (MUST be maintained):
1. `src/constants.sh` - First, no dependencies
2. `src/utilities.sh` - May use constants
3. `src/database.sh` - May use constants and utilities
4. `src/processing.sh` - May use all above

**Module Requirements**:
- Header comment block describing purpose
- Readonly variable declarations after configuration finalized
- No side effects on source (only define functions/constants)

### 3. External Dependencies

**Core Runtime** (REQUIRED):
- `bash` - Shell environment
- `pandoc` - PDF generation engine
- `sqlite3` - State management
- `uv` - Python package installer (for Pandoc filters)

**Pandoc Filters** (OPTIONAL but documented):
- `pandoc-plantuml-filter`, `mermaid-filter`, `pandoc-dbml-filter`
- `pandoc-fignos`, `pandoc-tablenos`, `pandoc-secnos`
- `pandoc-imagine`, `pandoc-include`

**Dependency Management**:
- Prerequisites verified before execution via `pndcgn_check_prerequisites()`
- Clear error messages identify missing dependencies
- Suggestion for installation method in error output

### 4. Configuration System

**Precedence** (highest to lowest):
1. Command-line arguments (`--type pdf`)
2. Environment variables (`PNDCGN_VERBOSE=1`)
3. TOML configuration (`pndcgn.toml`)
4. Built-in defaults (hardcoded)

**TOML Parsing**:
- Simple AWK-based parsing (no external TOML library)
- Empty values detected and reported as malformed
- Parameter expansion for defaults: `${VAR:-default}`

**Environment Variables**:
- `PNDCGN_CACHE_DIR` - Override cache location
- `PNDCGN_VERBOSE` - Enable verbose mode
- `PNDCGN_DRY_RUN` - Enable dry-run mode
- `XDG_STATE_HOME` - XDG base directory

## Development Workflow

### 1. Feature Development Process

**For New Features**:
1. Write user story in `docs/020-requirements.md` (REQ-XXX format)
2. Design technical approach in `docs/050-technical-specification.md`
3. Define function signatures in `docs/070-api-reference.md`
4. Write system test specification in `docs/100-system-test-plan.md` (TEST-XXX)
5. Write unit test specification in `docs/120-feature-unit-test-plan.md`
6. Implement failing ShellSpec tests
7. Implement feature to make tests pass
8. Update `docs/040-user-guide.md` with user-facing changes
9. Update traceability matrix in requirements doc

**For Bug Fixes**:
1. Write failing test that reproduces bug
2. Fix bug to make test pass
3. Update documentation if behavior changes

### 2. Quality Gates

**Before Commit**:
- All ShellSpec tests pass: `shellspec`
- ShellCheck passes with no warnings
- Manual smoke test with `--dry-run`
- Documentation updated for user-facing changes

**Before Merge**:
- All tests pass in CI environment
- Code coverage meets 50% threshold (70% target for utility modules)
- Technical documentation reviewed and approved
- No regression in existing functionality

### 3. Testing Standards

**Test Structure** (per AGENTS/Shell-CLI/020-zsh-testing-standards.md):
- Tests MUST be executable standalone: `bash tests/spec_name.spec.sh`
- No dependency on user's environment or shell configuration
- Use `setup_test_env()` and `cleanup_test_env()` from `spec_helper.sh`
- Mock external commands (pandoc, sqlite3) for unit tests
- Use temporary directories for test isolation

**Test Naming**:
```bash
Describe "Component name"
    Context "when condition"
        It "does something specific"
            # Test implementation
        End
    End
End
```

**Assertion Style**:
- Use ShellSpec's built-in assertions
- Provide descriptive failure messages
- Test both success and failure paths

### 4. Compliance Requirements

**AI Agent Compliance** (per AGENTS.md):
- All AI-authored artifacts MUST include acknowledgment header:
  `Compliant with AGENTS.md v<checksum>`
- Sensitive actions MUST cite exact rule with file and line reference
- Guidelines checksum MUST be current at time of authoring
- Policy validation via `php AGENTS/scripts/policy-check.php`

**Documentation Standards** (per AGENTS/Documentation/010-documentation-standards.md):
- Hierarchical numbering for all headings
- Code blocks with explicit language specification
- Markdown links using `[text](url)` format
- Validation for numbering, code blocks, and links

## Output Standards

### 1. User Interface

**Progress Indicators**:
- Animated spinner for long operations: `—`, `\`, `|`, `/`
- Overall progress with percentage: `[—] Overall Progress: 42/100 (42%)`
- Per-directory status during processing
- Color-coded messages (via `src/constants.sh`)

**Statistics Reporting**:
- Run duration tracked and reported
- Files processed by type
- Cache efficiency (hits/misses/ratio)
- Statistics persisted in database and displayed in `_index.md`

**Error Messages**:
- Clear, actionable error descriptions
- Suggest resolution when possible
- Include relevant context (file paths, run IDs)
- Use consistent formatting via `pndcgn_fail()`

### 2. Output Structure

**Directory Layout**:
```
${PNDCGN_OUTPUT_ROOT}/
├── pdf-{run_id}/           # Per-run output directories
│   ├── 100-section.pdf
│   ├── 100.010-subsection.pdf
│   └── _index.md           # Run report with hyperlinks
└── cache.sqlite            # State database
```

**Naming Convention**:
- Dewey Decimal system: `100-name.pdf`, `100.010-subname.pdf`
- No spaces in filenames
- Lowercase with hyphens for readability

**Index File**:
- Mermaid diagram showing document structure
- Hyperlinks to all generated PDFs
- Run statistics (duration, files processed, cache stats)
- Timestamp and run ID

## Governance

**Constitution Authority**: This constitution supersedes all other practices and conventions. When conflicts arise between this document and other guidelines, this document takes precedence.

**Amendment Process**:
1. Propose amendment with rationale
2. Document impact on existing code and tests
3. Require approval from project maintainer
4. Include migration plan for breaking changes
5. Update version and ratification date

**Enforcement**:
- Code reviews MUST verify compliance with constitution
- CI/CD pipeline MUST enforce quality gates
- Non-compliant code MUST NOT be merged
- Exceptions REQUIRE documented justification and time-bound remediation plan

**Prohibited Actions**:
- Implementing features without BDD user stories
- Merging code without corresponding tests
- Breaking existing tests to make new code work
- Bypassing ShellCheck without documented reason
- Committing secrets or credentials
- Overwriting user configuration without confirmation
- Silent failures (all errors must be reported)

**Complexity Justification**: Any deviation from simplicity MUST be justified with:
- Clear problem statement
- Explanation why simple approach insufficient
- Long-term maintenance considerations
- Documentation of added complexity

**Runtime Guidance**: For day-to-day development guidance, refer to:
- `WARP.md` - Warp AI agent development guidelines
- `AGENTS.md` - AI agent orchestration policy and development standards
- `AGENTS/Shell-CLI/` - Shell-specific implementation guides
- `docs/` - Detailed technical specifications and requirements

---

**Version**: 1.0.0
**Ratified**: 2025-12-14
**Last Amended**: 2025-12-14

**Compliance**: Compliant with AGENTS.md v1.0
