# pndcgn Overview

Compliant with [AGENTS.md](../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

## Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [pndcgn Overview](#pndcgn-overview)
  - [Table of Contents](#table-of-contents)
  - [1. Introduction](#1-introduction)
  - [2. Core Objective](#2-core-objective)
  - [3. System Features Overview](#3-system-features-overview)
    - [3.1. Intelligent Caching](#31-intelligent-caching)
    - [3.2. Parallel Processing](#32-parallel-processing)
    - [3.3. Dynamic Filter Chain](#33-dynamic-filter-chain)
    - [3.4. Dewey Decimal Naming](#34-dewey-decimal-naming)
    - [3.5. Interactive Source Selection (fzf)](#35-interactive-source-selection-fzf)
    - [3.6. Run Management](#36-run-management)
    - [3.7. Statistics and Reporting](#37-statistics-and-reporting)
  - [4. Design Philosophy](#4-design-philosophy)
    - [4.1. Speed Through Intelligence](#41-speed-through-intelligence)
    - [4.2. User Experience](#42-user-experience)
    - [4.3. Extensibility](#43-extensibility)
    - [4.4. Reliability](#44-reliability)
  - [5. Prerequisites Summary](#5-prerequisites-summary)
  - [6. Quick Start](#6-quick-start)
  - [7. Navigation](#7-navigation)

</details>

## 1. Introduction

**pndcgn** is an advanced documentation tool that transforms project source files into organized, hyperlinked documentation outputs (PDF, HTML, EPUB, and more). The system addresses the challenge of creating maintainable, navigable documentation from complex project structures by combining intelligent caching, parallel processing, and a sophisticated filter-based architecture.

**Primary Goal**: Automate the generation of comprehensive documentation outputs while maintaining speed, organization, and ease of navigation through intelligent design decisions.

**Target Users**: Development teams and technical writers who need to generate professional documentation from project source files with minimal manual intervention.

## 2. Core Objective

Create a shell script that traverses a project directory and generates a consolidated, hyperlinked, and logically sorted set of documentation outputs (default: PDF) stored in a deterministic run directory structure under the target directory (default: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`).

**Key Requirements**:

- Process markdown, code, and diagram files into professional documentation outputs
- Maintain fast execution through intelligent caching
- Provide clear progress feedback during generation
- Support resumption of interrupted operations
- Generate navigable output with hyperlinked table of contents
- Use consistent, logical naming for easy file location (Dewey Decimal-style prefixes)

## 3. System Features Overview

### 3.1. Intelligent Caching

The system uses a SQLite database (`${XDG_STATE_HOME:-${HOME}/.local/state}/pndcgn/cache.sqlite`) in Write-Ahead Logging (WAL) mode to provide intelligent caching capabilities:

**Core Capabilities**:

- **Hash-based change detection**: Only regenerate PDFs when source content changes
- **Dependency tracking**: Automatically regenerate PDFs when included files change
- **Resume-on-failure**: Continue from last successful point if interrupted
- **Analytics support**: Query cache for insights on document complexity and changes

**Performance Impact**: Reduces execution time from minutes to seconds on subsequent runs by avoiding redundant processing.

### 3.2. Parallel Processing

The system leverages multi-core processors to build multiple PDFs simultaneously:

**Benefits**:

- Dramatic reduction in initial build time
- Scales automatically with available CPU cores
- Each directory is processed as independent task
- WAL mode enables safe concurrent database access

**Use Case**: Particularly valuable for large projects with many directories requiring documentation.

### 3.3. Dynamic Filter Chain

The system automatically detects and uses available Pandoc filters for enhanced document processing:

**Supported Filters**:

- **Diagram rendering**: PlantUML, Mermaid, DBML
- **Cross-referencing**: Figure numbering (fignos), table numbering (tablenos), section numbering (secnos)
- **Content inclusion**: Include external files, advanced image handling (imagine)

**Advantage**: New filters can be added to the environment without modifying the script - they're automatically detected and used.

### 3.4. Dewey Decimal Naming

All generated outputs are stored within the run directory with hierarchical Dewey Decimal-style prefixes:

**Naming Algorithm**:

- Top-level directories: Base numbers (100, 200, 300)
- Sub-directories: Inherit parent prefix + unique sub-number (100.010, 100.020)
- Format: `[Prefix]-[Directory-Name].[ext]` (where extension matches output type)

**Example** (within `${TARGET_DIR}/.pndcgn/pdf-${RUN_ID}/`):

```log
100-laravel.pdf
100.010-tad.pdf
100.800-documentation-suite.pdf
200-AI-GUIDELINES.pdf
200.010-Documentation.pdf
```

**Benefits**: Logical sorting, easy file location, reflects project hierarchy within the run directory structure.

### 3.5. Interactive Source Selection (fzf)

The system optionally integrates with `fzf` (fuzzy finder) to provide an interactive folder selection interface:

**Core Capabilities**:
- **Optional integration**: If `fzf` is installed and available, and no source directory is specified, the tool offers an interactive folder selection interface
- **Directory-only display**: Only directories (folders) are shown in the selection interface, not individual files
- **Graceful fallback**: If `fzf` is not installed or unavailable, the tool silently falls back to using the current working directory as the default source
- **Non-blocking**: The integration is completely optional and does not affect normal operation if `fzf` is unavailable

**Use Case**: Particularly useful when working in large project directories where you want to quickly select a specific subdirectory without typing the full path.

### 3.6. Run Management

Each execution is tracked with a unique ULID (Universally Unique Lexicographically Sortable Identifier):

**Run Tracking**:

- ULID format for unique run identification (auto-generated by SQLite `ulid()` function from `sqlite-ulid` extension)
- Extension automatically downloaded and installed on first run
- Status tracking: in_progress, completed, aborted
- Checkpoint-based resumption support
- Clean specific runs or drop all outputs

**Commands**:

- `--resume <RUN_ID>`: Continue interrupted run
- `--finalize <RUN_ID>`: Finalize a previous dry-run (if inputs unchanged)
- `--dry-run`: Preview what would be generated without creating outputs
- `--reseed`: Explicitly re-seed `.pndcgnignore` from current ignore rules

### 3.7. Statistics and Reporting

Comprehensive statistics tracking for each run:

**Tracked Metrics**:

- Directories processed vs. skipped
- Files by type and extension
- Processing timings and duration
- Cache efficiency (hit/miss ratio)

**Output**: Rich `_index.md` within the run directory with:

- Mermaid visual mapping diagram of project structure
- Hyperlinked list of all generated outputs (sorted by Dewey Decimal prefix)
- Statistics report for the run

## 4. Design Philosophy

### 4.1. Speed Through Intelligence

Rather than raw processing power, the system achieves speed through intelligent decisions:

- Cache only what's needed, when it's needed
- Process only changed content
- Parallelize where safe and beneficial
- Use database for complex queries instead of file scanning

### 4.2. User Experience

Clear feedback and intuitive operation:

- **Progress indicators**: Animated spinners with percentage completion
- **Clear messaging**: ANSI-colored output for errors, success, warnings
- **Helpful output**: Generated index provides visual map and direct links
- **Safe operations**: Confirmation required for destructive commands

### 4.3. Extensibility

System grows without code changes:

- Filter ecosystem: Add new Pandoc filters without modifying script
- Directory structure: Handles any project organization
- File types: Processes markdown, code, diagrams automatically
- Future-proof: Design accommodates new requirements

### 4.4. Reliability

Built for real-world use:

- Prerequisite checks before execution
- Graceful handling of missing tools
- Resume capability for long-running operations
- Validation of generated output
- Comprehensive error reporting

## 5. Prerequisites Summary

**Core Requirements**:

- Pandoc (document conversion engine)
- LaTeX engine (TeX Live scheme-medium recommended)
- SQLite (caching database)
- PlantUML (diagram rendering)
- Mermaid CLI (diagram rendering)
- Python 3 with uv (for pip-based Pandoc filters)

**Testing**:

- shellspec (BDD/TDD framework for shell scripts)

**Platform Support**:

- IDX (Google): Managed via `dev.nix` configuration
- macOS: Homebrew installation
- Linux: APT/package manager installation

For detailed installation instructions, see [030-installation.md](030-installation.md).

## 6. Quick Start

**First Time Setup**:

1. Install prerequisites (see [030-installation.md](030-installation.md))
2. Run `pndcgn --help` to see available options
3. Execute `pndcgn` for first generation (defaults to current directory)
4. Review `${TARGET_DIR}/.pndcgn/pdf-${RUN_ID}/_index.md` for generated documentation

**Subsequent Runs**:

- `pndcgn` - Incremental update (uses cache)
- `pndcgn --force` - Force full regeneration
- `pndcgn --dry-run` - Preview what would be generated
- `pndcgn --finalize <RUN_ID>` - Finalize a previous dry-run

**Understanding Output**:

- Outputs are in `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/` with Dewey Decimal naming
- `_index.md` within the run directory provides visual map and hyperlinked navigation
- Progress indicators show real-time processing status

For comprehensive usage information, see [040-user-guide.md](040-user-guide.md).

## 7. Navigation

[← Index](000-index.md) | [↑ Top](#pndcgn-overview) | [Next: Requirements →](020-requirements.md)
