# pndcgn Documentation Index

Compliant with [AGENTS.md](../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

## Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Quick Start](#2-quick-start)
- [3. Documentation Structure](#3-documentation-structure)
  - [3.1. Core Documentation](#31-core-documentation)
  - [3.2. Requirements and User Documentation](#32-requirements-and-user-documentation)
  - [3.3. Technical Documentation](#33-technical-documentation)
  - [3.4. Testing Documentation](#34-testing-documentation)
  - [3.5. Supporting Documentation](#35-supporting-documentation)
  - [3.6. Development History](#36-development-history)
- [4. For Specific Tasks](#4-for-specific-tasks)
- [5. Document Formatting Standards](#5-document-formatting-standards)
- [6. Testing Framework](#6-testing-framework)
- [7. Navigation](#7-navigation)

</details>

## 1. Introduction

This documentation set provides comprehensive guidance for the **pndcgn** tool, an advanced system for creating organized, hyperlinked documentation outputs (PDF, HTML, EPUB, and more) from project source files. The tool features intelligent caching, parallel processing, and a sophisticated filter-based architecture.

**Target Audience**: All documentation is written to be clear, actionable, and suitable for junior developers to understand and implement.

**Documentation Philosophy**: These documents capture the knowledge, decisions, and understanding achieved during the tool's development, preserving the technical rationale behind design choices.

## 2. Quick Start

**New to pndcgn?** Start here:

1. Read [010-overview.md](010-overview.md) for system overview and core objectives
2. Review [030-installation.md](030-installation.md) for setup instructions
3. Read [040-user-guide.md](040-user-guide.md) for usage and CLI options
4. Explore [050-architecture.md](050-architecture.md) to understand the system design

**Ready to Develop?**

1. Review [020-requirements.md](020-requirements.md) for BDD requirements
2. Read [110-implementation-plan.md](110-implementation-plan.md) for implementation guidance
3. Study [100-system-test-plan.md](100-system-test-plan.md) and [120-feature-unit-test-plan.md](120-feature-unit-test-plan.md) for testing approach

## 3. Documentation Structure

### 3.1. Core Documentation

- [000-index.md](000-index.md) - This document; central navigation hub

### 3.2. Requirements and User Documentation

- [010-overview.md](010-overview.md) - Project overview, core objectives, and feature summary
- [020-requirements.md](020-requirements.md) - BDD requirements as user stories with acceptance criteria
- [030-installation.md](030-installation.md) - Installation guide for IDX and manual setup
- [040-user-guide.md](040-user-guide.md) - Comprehensive user guide with CLI options and workflows

### 3.3. Technical Documentation

- [050-architecture.md](050-architecture.md) - System architecture, SQLite schema, and caching strategy
- [060-filters.md](060-filters.md) - Pandoc filter ecosystem and integration
- [070-dewey-decimal.md](070-dewey-decimal.md) - Dewey Decimal naming algorithm specification
- [080-statistics.md](080-statistics.md) - Statistics tracking and resumption system

### 3.4. Testing Documentation

- [100-system-test-plan.md](100-system-test-plan.md) - System tests mapped to requirements (shellspec)
- [110-implementation-plan.md](110-implementation-plan.md) - Implementation plan with requirements references
- [120-feature-unit-test-plan.md](120-feature-unit-test-plan.md) - Feature and unit tests for implementation (shellspec)
- `tests/README.md` - Test suite documentation and organization
- `scripts/README.md` - Test execution scripts library

### 3.5. Supporting Documentation

- [200-constants.md](200-constants.md) - ANSI color codes and constants specification

### 3.6. Development History

- [900-changelog.md](900-changelog.md) - Evolution history from initial concept to current design

## 4. For Specific Tasks

**Installation and Setup**:
- IDX platform setup → [030-installation.md](030-installation.md)
- Manual installation → [030-installation.md](030-installation.md)
- Prerequisites verification → [030-installation.md](030-installation.md)

**Using pndcgn**:
- First run → [040-user-guide.md](040-user-guide.md)
- CLI options → [040-user-guide.md](040-user-guide.md)
- Resuming interrupted runs → [040-user-guide.md](040-user-guide.md)
- Cleaning specific runs → [040-user-guide.md](040-user-guide.md)

**Understanding the System**:
- SQLite caching → [050-architecture.md](050-architecture.md)
- Filter chain → [060-filters.md](060-filters.md)
- PDF naming → [070-dewey-decimal.md](070-dewey-decimal.md)
- Statistics tracking → [080-statistics.md](080-statistics.md)

**Development and Testing**:
- Requirements → [020-requirements.md](020-requirements.md)
- Implementation tasks → [110-implementation-plan.md](110-implementation-plan.md)
- Writing tests → [100-system-test-plan.md](100-system-test-plan.md), [120-feature-unit-test-plan.md](120-feature-unit-test-plan.md)
- Running tests → `tests/README.md`, `scripts/README.md`
- Test scripts → `scripts/run-*.sh`, `scripts/local-ci.sh`
- ANSI constants → [200-constants.md](200-constants.md)

**Troubleshooting**:
- Common issues → [040-user-guide.md](040-user-guide.md)
- Design decisions → [900-changelog.md](900-changelog.md)

## 5. Document Formatting Standards

All documentation follows these standards from AGENTS.md:

- **Plain H1 headings**: No HTML anchors (e.g., `# Document Title`)
- **Numbered headings**: All headings below H1 are numbered (1, 1.1, 1.1.1)
- **Table of Contents**: Collapsible TOC in `<details>` tags after document title
- **Navigation footer**: Format: `[← Previous](path) | [↑ Top](#anchor) | [Next →](path)`
- **Code blocks**: All code blocks specify language (use `log` for plain text)
- **Links**: Standard markdown syntax `[text](url)`
- **Accessibility**: WCAG 2.1 AA compliance for color contrast and structure
- **File naming**: 3-digit prefixes in multiples of 10 (000, 010, 020, etc.)

## 6. Testing Framework

This project uses **shellspec** for BDD/TDD testing of shell scripts:

- shellspec is already configured in `.idx/dev.nix`
- Test files are located in `tests/` directory (modular structure as of 2025-12-14)
- System tests validate requirements → [100-system-test-plan.md](100-system-test-plan.md)
- Feature/unit tests validate implementation → [120-feature-unit-test-plan.md](120-feature-unit-test-plan.md)
- Integration tests (no mocks) → `tests/integration/` (16 tests)
- Test execution scripts → `scripts/` directory (comprehensive test runner library)
- Coverage tracking → kcov with Docker/CI support (macOS has ptrace limitations)
- `constants.sh` is shared between production code and tests → [200-constants.md](200-constants.md)

**Test Organization** (as of 2025-12-14):
- **Unit Tests**: `tests/utilities/`, `tests/database/`, `tests/processing/` (18 modular files)
- **Integration Tests**: `tests/integration/` (3 files, 16 tests without mocks)
- **Feature Tests**: `tests/pndcgn_spec.sh`, `tests/performance_spec.sh`, `tests/usability_spec.sh`
- **Scripts**: `scripts/run-*.sh` for test execution, `scripts/local-ci.sh` for CI workflow

## 7. Navigation

[↑ Top](#pndcgn-documentation-index) | [Next: Overview →](010-overview.md)
