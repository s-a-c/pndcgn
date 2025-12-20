# TOML Configuration Default Patterns

**Compliant with [AGENTS.md](../AGENTS.md)**

## Default Include Patterns

When no `pndcgn.toml` configuration file is present, the following default include patterns are used:

- `docs/**/*` - All files in the `docs/` directory and subdirectories
- `doc-assets/**/*` - All files in the `doc-assets/` directory and subdirectories
- `**/*.md` - All Markdown files recursively
- `**/*.markdown` - All files with `.markdown` extension recursively
- `**/*.txt` - All text files recursively
- `**/*.rst` - All reStructuredText files recursively
- `**/*.org` - All Org-mode files recursively

## Rationale (NFR-TOML-060)

These defaults are designed to:

1. **Capture common documentation structures**: The `docs/` and `doc-assets/` patterns match typical project documentation organization where documentation sources are kept in dedicated directories.

2. **Include common text formats**: Patterns for `.md`, `.markdown`, `.txt`, `.rst`, and `.org` cover the most common documentation source formats that pandoc can process.

3. **Be permissive by default**: Using recursive patterns (`**/*`) ensures that documentation files are discovered regardless of directory depth, accommodating various project structures.

4. **Balance comprehensiveness with performance**: While these patterns may match many files, the `.pndcgnignore` file (seeded from `.gitignore`) provides exclusion filtering to skip build artifacts, dependencies, and other non-documentation files.

5. **Support incremental refinement**: Users can override defaults by creating a `pndcgn.toml` file with more specific patterns if the defaults are too broad for their use case.

## Default Extensions

When no `[include.types]` section is specified, the following extensions are considered valid input files:

- `md`, `markdown` - Markdown formats
- `txt` - Plain text
- `rst` - reStructuredText
- `org` - Org-mode
- `html`, `htm` - HTML files
- `tex` - LaTeX source

These extensions align with pandoc's supported input formats and common documentation source file types.

---

*This document explains the rationale for default patterns used when no TOML configuration is present.*
