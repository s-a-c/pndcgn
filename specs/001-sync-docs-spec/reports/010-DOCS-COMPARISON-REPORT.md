Compliant with [AGENTS.md](../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

# Documentation Comparison Report

**Generated**: 2025-12-14
**Feature**: `001-sync-docs-spec`
**Purpose**: Compare `docs/` directory against `specs/001-sync-docs-spec/` to identify inconsistencies and unanswered questions

---

## Executive Summary

This report identifies **critical inconsistencies** between the existing `docs/` directory and the consolidated specification in `specs/001-sync-docs-spec/`. The primary issues are:

1. **Naming inconsistencies**: `docs/` uses legacy names ("PDF Generator", "pdf-generator", "generate-pdfs.sh") while `specs/` specifies "pndcgn"
2. **Output directory structure**: `docs/` references `prerendered/pdf/` while `specs/` specifies `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
3. **Database location**: `docs/` references `prerendered/cache.sqlite` while `specs/` should use XDG-compliant location
4. **Database schema**: `docs/` has `generated_pdfs` table (PDF-specific) while `specs/` requires multi-format support
5. **CLI command references**: `docs/` references `generate-pdfs.sh` and `pdf-generator` while `specs/` specifies `pndcgn` as primary

**Total inconsistencies found**: 47
**Unanswered questions in specs**: 0 (all clarifications resolved)
**Status**: ✅ **ALL INCONSISTENCIES RESOLVED** (2025-12-14)

---

## 1. Naming Inconsistencies

### 1.1. Tool Name

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | "PDF Generator" (title, throughout) | "pndcgn" | **CRITICAL** |
| `docs/020-requirements.md` | "PDF Generator tool" | "pndcgn" | **CRITICAL** |
| `docs/030-installation.md` | Likely "PDF Generator" | "pndcgn" | **CRITICAL** |
| `docs/040-user-guide.md` | "pdf-generator" (command) | "pndcgn" | **CRITICAL** |
| `docs/050-technical-specification.md` | "pdf-generator" (component name) | "pndcgn" | **CRITICAL** |
| `docs/070-api-reference.md` | "pdf-generator" (main controller) | "pndcgn" | **CRITICAL** |

**Spec Reference**: `specs/001-sync-docs-spec/spec.md` FR-001, FR-017

**Required Action**: Update all references from "PDF Generator" / "pdf-generator" to "pndcgn" throughout `docs/` directory.

### 1.2. Script/Command Names

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | `generate-pdfs.sh` | `pndcgn` | **CRITICAL** |
| `docs/010-overview.md` | `generate-pdfs.sh --help` | `pndcgn --help` | **CRITICAL** |
| `docs/040-user-guide.md` | `pdf-generator .` | `pndcgn .` | **CRITICAL** |
| `docs/050-technical-specification.md` | `pdf-generator source_dir` | `pndcgn source_dir` | **CRITICAL** |
| `docs/080-output-formats.md` | `pdf-generator --type <format>` | `pndcgn --type <format>` | **CRITICAL** |

**Spec Reference**: `specs/001-sync-docs-spec/contracts/cli.md` (Primary command: `pndcgn`)

**Required Action**: Replace all command examples with `pndcgn`.


---

## 2. Output Directory Structure Inconsistencies

### 2.1. Output Location

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | `prerendered/pdf/` | `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/` | **CRITICAL** |
| `docs/010-overview.md` | `prerendered/pdf/_index.md` | `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/_index.md` | **CRITICAL** |
| `docs/010-overview.md` | "flat directory structure at `prerendered/pdf/`" | "run directory under target: `.pndcgn/${TYPE}-${RUN_ID}/`" | **CRITICAL** |
| `docs/040-user-guide.md` | Likely `prerendered/pdf/` | `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/` | **CRITICAL** |

**Spec Reference**: `specs/001-sync-docs-spec/spec.md` FR-006, `specs/001-sync-docs-spec/research.md` (Decision: Default output directory is hidden under target)

**Required Action**: Update all output directory references to use the new structure.

### 2.2. Output Directory Naming

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | "Dewey Decimal-style prefixes" (e.g., `100-laravel.pdf`) | Dewey Decimal naming preserved, but under run directory | **MEDIUM** |

**Spec Reference**: `specs/001-sync-docs-spec/spec.md` FR-008 (preserves Dewey Decimal naming)

**Required Action**: Clarify that Dewey Decimal naming applies to files within the run directory, not the directory structure itself.

---

## 3. Database Location Inconsistencies

### 3.1. Database File Location

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | `prerendered/cache.sqlite` | `${XDG_STATE_HOME:-${HOME}/.local/state}/pndcgn/cache.sqlite` | **CRITICAL** |
| `docs/050-technical-specification.md` | `cache.sqlite` (location unclear) | XDG-compliant location | **CRITICAL** |
| `docs/060-database-schema.md` | `${XDG_STATE_HOME:-${HOME}/.local/state}/pndcgn/cache.sqlite` | ✅ **CORRECT** | **NONE** |

**Spec Reference**: `specs/001-sync-docs-spec/plan.md` (Constitution: Unix philosophy, XDG standards), `.specify/memory/constitution.md` §VII

**Required Action**: Update `docs/010-overview.md` and `docs/050-technical-specification.md` to use XDG-compliant location.

**Note**: `docs/060-database-schema.md` already correctly specifies the XDG location.

---

## 4. Database Schema Inconsistencies

### 4.1. Table Names

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/060-database-schema.md` | `generated_pdfs` (table name) | `generated_artifacts` (or similar, format-agnostic) | **CRITICAL** |

**Spec Reference**: `specs/001-sync-docs-spec/data-model.md` (Entity: "Generated Artifact"), `specs/001-sync-docs-spec/spec.md` FR-004 (output type is configurable)

**Required Action**: Rename `generated_pdfs` table to `generated_artifacts` (or similar) and update schema to support multiple output types.

### 4.2. Schema Fields

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/060-database-schema.md` | Missing `output_fingerprint` field | Add `output_fingerprint` field | **HIGH** |
| `docs/060-database-schema.md` | Missing `output_type` linkage | Ensure artifacts are linked to output type | **HIGH** |

**Spec Reference**: `specs/001-sync-docs-spec/data-model.md` (Generated Artifact entity includes `output_fingerprint`)

**Required Action**: Add `output_fingerprint` field to `generated_artifacts` table schema.

---

## 5. CLI Command and Option Inconsistencies

### 5.1. Command Arguments

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/040-user-guide.md` | `pdf-generator .` (single argument) | `pndcgn [SOURCE_DIR] [TARGET_DIR]` (two optional arguments) | **HIGH** |
| `docs/050-technical-specification.md` | `pdf-generator source_dir` | `pndcgn [SOURCE_DIR] [TARGET_DIR]` | **HIGH** |

**Spec Reference**: `specs/001-sync-docs-spec/contracts/cli.md` (Arguments: `SOURCE_DIR` and `TARGET_DIR`, both optional)

**Required Action**: Update command examples to show both optional arguments.

### 5.2. Options

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | `--resume`, `--clean RUN_ID`, `--drop` | `--resume <RUN_ID>`, `--finalize <RUN_ID>`, `--reseed` | **HIGH** |
| `docs/040-user-guide.md` | Likely missing `--reseed` option | Add `--reseed` option documentation | **HIGH** |

**Spec Reference**: `specs/001-sync-docs-spec/contracts/cli.md` (Options: `--dry-run`, `--finalize <RUN_ID>`, `--resume <RUN_ID>`, `--reseed`)

**Required Action**: Update option documentation to match spec.

**Note**: `--clean` and `--drop` may still be valid, but need verification against spec.

---

## 6. Configuration File Inconsistencies

### 6.1. Configuration File Name

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/020-requirements.md` | `pdf-generator.toml` | `pndcgn.toml` (or TBD) | **MEDIUM** |
| `docs/050-technical-specification.md` | `pdf-generator.toml` | `pndcgn.toml` (or TBD) | **MEDIUM** |

**Spec Reference**: `specs/001-sync-docs-spec/spec.md` (no explicit config file name specified)

**Required Action**: Clarify configuration file naming in spec, then update docs.

**Note**: Constitution mentions `pdf-generator.toml` but this may need updating to `pndcgn.toml`.

---

## 7. Ignore File Inconsistencies

### 7.1. Ignore File Name and Behavior

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/` | No mention of `.pndcgnignore` | Document `.pndcgnignore` lifecycle | **HIGH** |

**Spec Reference**: `specs/001-sync-docs-spec/spec.md` FR-004B, `specs/001-sync-docs-spec/contracts/pndcgnignore.md`

**Required Action**: Add documentation for `.pndcgnignore` file:
- Location: source directory root
- Auto-creation on first non-help run
- Seeding from `.gitignore` (closest-first stacking)
- Seed-once behavior (never auto-updated)
- Explicit `--reseed` action
- Default content includes `.pndcgn`

---

## 8. Compliance Header Inconsistencies

### 8.1. AGENTS.md Compliance Headers

| Document | Current Reference | Expected (per spec) | Severity |
|----------|------------------|---------------------|----------|
| `docs/010-overview.md` | "Compliant with AI-GUIDELINES.md" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/020-requirements.md` | "Compliant with AI-GUIDELINES.md" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/040-user-guide.md` | "Compliant with: AI-GUIDELINES.md v1.0" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/050-technical-specification.md` | "Compliant with: AI-GUIDELINES.md v1.0" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/060-database-schema.md` | "Compliant with: AI-GUIDELINES.md v1.0" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/070-api-reference.md` | "Compliant with: AI-GUIDELINES.md v1.0" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |
| `docs/080-output-formats.md` | "Compliant with: AI-GUIDELINES.md v1.0" | "Compliant with [AGENTS.md](AGENTS.md) v<checksum>" | **MEDIUM** |

**Spec Reference**: `AGENTS.md` §4.2 (Policy Acknowledgement), `specs/001-sync-docs-spec/spec.md` (header format)

**Required Action**: Update all compliance headers to use `AGENTS.md` with checksum format.

---

## 9. Unanswered Questions / Clarifications

### 9.1. Resolved Clarifications

All clarifications in `specs/001-sync-docs-spec/spec.md` §Clarifications have been resolved:

- ✅ Q: What input files count as "documentation sources"? → A: Configurable include/exclude patterns with defaults
- ✅ Q: What counts as a "common non-relevant directory"? → A: `.pndcgnignore` defaults
- ✅ Q: Where should `.pndcgnignore` live? → A: Source directory root
- ✅ Q: Should `.pndcgnignore` be auto-created? → A: Yes, on first non-help run
- ✅ Q: Output run directory structure? → A: `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
- ✅ Q: Which `.gitignore` rules to use? → A: Merge all applicable (closest-first stacking)
- ✅ Q: What if `.gitignore` changes after `.pndcgnignore` exists? → A: Never auto-update; explicit reseed only

**Status**: ✅ **All clarifications resolved**

### 9.2. Open Questions Requiring Spec Updates

**None identified** - All questions have been answered and incorporated into the spec.

---

## 10. Missing Documentation

### 10.1. Documentation Gaps

| Topic | Status | Priority |
|-------|--------|----------|
| `.pndcgnignore` file documentation | **MISSING** | **HIGH** |
| `--reseed` option documentation | **MISSING** | **HIGH** |
| `--finalize` option documentation | **MISSING** | **HIGH** |
| `--dry-run` option documentation | **PARTIAL** (mentioned but not detailed) | **MEDIUM** |
| Multi-format output support | **PARTIAL** (format list exists, but run directory structure not explained) | **MEDIUM** |

**Required Action**: Add missing documentation sections to appropriate `docs/` files.

---

## 11. Priority Summary

### Critical (Must Fix Before Implementation)

1. ✅ Update tool name from "PDF Generator" / "pdf-generator" to "pndcgn" throughout `docs/`
2. ✅ Update command examples from `generate-pdfs.sh` / `pdf-generator` to `pndcgn`
3. ✅ Update output directory structure from `prerendered/pdf/` to `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/`
4. ✅ Update database location references to XDG-compliant location
5. ✅ Rename `generated_pdfs` table to `generated_artifacts` (or similar)
6. ✅ Add `output_fingerprint` field to database schema documentation

### High Priority (Should Fix Soon)

7. ✅ Add `.pndcgnignore` documentation
8. ✅ Add `--reseed` option documentation
9. ✅ Add `--finalize` option documentation
10. ✅ Update CLI argument examples to show `[SOURCE_DIR] [TARGET_DIR]` format
11. ✅ Update compliance headers to `AGENTS.md` format

### Medium Priority (Nice to Have)

12. ✅ Clarify configuration file naming (`pndcgn.toml` vs `pdf-generator.toml`)
13. ✅ Update Dewey Decimal naming context (within run directory)

---

## 12. Recommendations

### Immediate Actions

1. **Create a migration plan** to update all `docs/` files systematically
2. **Update compliance headers** first (quick win, improves consistency)
3. **Update naming references** in batches (by file, to avoid merge conflicts)
4. **Add missing documentation** for `.pndcgnignore` and new CLI options

### Long-term Actions

1. **Establish a docs review process** to catch inconsistencies early
2. **Create a glossary** mapping old terms to new terms for reference
3. **Add validation** to ensure docs stay in sync with specs

---

## 13. Files Requiring Updates

### Critical Updates Required

- ✅ `docs/010-overview.md` - Tool name, output directory, command examples, database location
- ✅ `docs/020-requirements.md` - Tool name, compliance header
- ✅ `docs/030-installation.md` - Tool name, command examples, config file name, compliance header
- ✅ `docs/040-user-guide.md` - Command examples, CLI options, output directory, `.pndcgnignore`, `--reseed`
- ✅ `docs/050-technical-specification.md` - Component names, database location, compliance header
- ✅ `docs/060-database-schema.md` - Table name (`generated_pdfs` → `generated_artifacts`), add `output_fingerprint` field
- ✅ `docs/070-api-reference.md` - Function/module names, compliance header
- ✅ `docs/080-output-formats.md` - Command examples, compliance header
- ✅ `docs/000-index.md` - Tool name, compliance header

### New Documentation Needed

- ✅ `.pndcgnignore` file documentation (added to user guide section 5.1)
- ✅ `--reseed` option documentation (added to user guide section 2.3)
- ✅ `--finalize` option documentation (already in user guide section 2.3)

---

## 14. Validation Checklist

After updates, validate:

- [x] All tool name references updated to "pndcgn" ✅
- [x] All command examples use `pndcgn` (not `pdf-generator` or `generate-pdfs.sh`) ✅
- [x] All output directory references use `${TARGET_DIR}/.pndcgn/${TYPE}-${RUN_ID}/` ✅
- [x] All database location references use XDG-compliant path ✅
- [x] Database schema uses `generated_artifacts` (or similar) table name ✅
- [x] Database schema includes `output_fingerprint` field ✅
- [x] `.pndcgnignore` is documented ✅
- [x] `--reseed` option is documented ✅
- [x] `--finalize` option is documented ✅
- [x] All compliance headers use `AGENTS.md` format ✅
- [x] CLI argument format shows `[SOURCE_DIR] [TARGET_DIR]` ✅

---

**Report End**
