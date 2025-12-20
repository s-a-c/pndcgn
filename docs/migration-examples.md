# Migration Examples

This document provides examples for migrating from default pndcgn behavior to custom configurations.

## Table of Contents

- [Basic Migration](#basic-migration)
- [Custom Include Patterns](#custom-include-patterns)
- [Multiple Output Types](#multiple-output-types)
- [Project-Specific Configuration](#project-specific-configuration)
- [Team Configuration](#team-configuration)

## Basic Migration

### Default Behavior

By default, pndcgn processes all text-based files in the source directory, excluding patterns from `.pndcgnignore` (seeded from `.gitignore`).

```bash
# Default: Process all text files, output PDFs
pndcgn docs/ output/
```

### Custom Include Patterns

To restrict processing to specific directories or file patterns, create a TOML configuration file.

**Example: Process only `docs/` and `guides/` directories**

Create `pndcgn.toml` in your project root:

```toml
[include]
patterns = [
    "docs/**",
    "guides/**"
]
```

**Example: Process only Markdown files in specific locations**

```toml
[include]
patterns = [
    "documentation/**/*.md",
    "manuals/**/*.markdown"
]
```

## Custom Include Patterns

### Pattern Syntax

pndcgn supports glob patterns with the following features:

- `*` - Matches any characters except `/`
- `**` - Matches any characters including `/` (recursive)
- `?` - Matches a single character
- `[abc]` - Matches any character in the set
- `{a,b,c}` - Brace expansion (matches any of the patterns)

### Example: Include Multiple File Types

```toml
[include]
patterns = [
    "docs/**/*.md",
    "docs/**/*.txt",
    "docs/**/*.rst"
]

[include.types]
extensions = ["md", "markdown", "txt", "rst"]
```

### Example: Exclude Specific Subdirectories

Use `.pndcgnignore` to exclude patterns:

```gitignore
# .pndcgnignore
drafts/
archive/
*.draft.md
```

## Multiple Output Types

### Generating Multiple Formats

To generate multiple output formats, run pndcgn multiple times with different `--type` options:

```bash
# Generate PDFs
pndcgn --type pdf docs/ output/pdf/

# Generate HTML
pndcgn --type html docs/ output/html/

# Generate EPUB
pndcgn --type epub docs/ output/epub/
```

### Automated Multi-Format Script

Create a script to generate all formats:

```bash
#!/bin/bash
# generate-all-formats.sh

SOURCE_DIR="${1:-docs}"
TARGET_DIR="${2:-output}"

for format in pdf html epub docx; do
    echo "Generating $format..."
    pndcgn --type "$format" "$SOURCE_DIR" "$TARGET_DIR/$format"
done
```

## Project-Specific Configuration

### Example: Documentation Project

For a project with documentation in multiple locations:

```toml
# pndcgn.toml
[include]
patterns = [
    "docs/user-guide/**",
    "docs/api-reference/**",
    "docs/tutorials/**"
]

[include.types]
extensions = ["md", "markdown"]
```

### Example: Technical Writing Project

For a technical writing project with structured content:

```toml
# pndcgn.toml
[include]
patterns = [
    "content/chapters/**",
    "content/appendix/**"
]

[include.types]
extensions = ["md"]
```

## Team Configuration

### Shared Team Configuration

Place a shared configuration in the XDG config directory:

**Location**: `~/.config/pndcgn/pndcgn.toml`

```toml
# Team-wide defaults
[include]
patterns = [
    "documentation/**",
    "guides/**"
]

[include.types]
extensions = ["md", "markdown", "txt"]
```

### Project Override

Project-specific configurations override team defaults:

**Location**: `project-root/pndcgn.toml`

```toml
# Project-specific overrides
[include]
patterns = [
    "docs/**"
]
```

## Migration Checklist

When migrating from defaults to custom configuration:

- [ ] Identify which files/directories should be processed
- [ ] Create `.pndcgnignore` if needed (auto-created from `.gitignore` on first run)
- [ ] Create `pndcgn.toml` with custom include patterns if needed
- [ ] Test with `--dry-run` to verify patterns match expected files
- [ ] Finalize the dry-run to generate outputs
- [ ] Verify outputs match expectations

## Common Migration Scenarios

### Scenario 1: Restrict to Single Directory

**Before**: Processing all files in project root
**After**: Process only `docs/` directory

```toml
[include]
patterns = ["docs/**"]
```

### Scenario 2: Include Multiple File Types

**Before**: Processing only Markdown files
**After**: Include Markdown, reStructuredText, and plain text

```toml
[include.types]
extensions = ["md", "markdown", "rst", "txt"]
```

### Scenario 3: Exclude Draft Content

**Before**: Processing all files including drafts
**After**: Exclude draft files and directories

Add to `.pndcgnignore`:
```gitignore
drafts/
*.draft.*
WIP/
```

## Troubleshooting

If migration doesn't work as expected:

1. **Verify pattern matching**: Use `--verbose` to see which files are discovered
2. **Check pattern syntax**: Ensure glob patterns are correct (use `**` for recursive)
3. **Validate TOML syntax**: Check for parse errors in configuration file
4. **Review ignore patterns**: `.pndcgnignore` patterns are evaluated after include patterns

See [Troubleshooting Guide](./troubleshooting.md) for more details.
