# Contract: TOML Configuration File

Compliant with [AGENTS.md](../../../AGENTS.md) v8734620507988c6a9e6316900bfc9ff60394b1e358fadc2a6d223c5724583688

**Version**: 1.0
**Status**: Draft

## File Discovery

The system searches for `pndcgn.toml` in this order (first found wins):

1. `${XDG_CONFIG_HOME:-${HOME}/.config}/pndcgn/pndcgn.toml` (user config)
2. `${SOURCE_DIR}/pndcgn.toml` (project config)

If both exist, source directory (project) config takes precedence.

## Format

TOML v1.0.0 specification.

## Schema

```toml
# Include patterns for file discovery
[include]
patterns = [
    "docs/**/*.md",
    "doc-assets/**/*",
    "*.md"
]

# File type extensions to include (alternative to patterns)
[include.types]
extensions = ["md", "txt", "rst", "adoc"]
```

### Section: `[include]`

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `patterns` | Array of strings | No | Glob patterns for file inclusion |

### Section: `[include.types]`

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `extensions` | Array of strings | No | File extensions to include (without leading dot) |

## Parsing Rules

1. **Missing file**: Use defaults (docs/, doc-assets/, all .md files)
2. **Empty file**: Use defaults
3. **Malformed TOML**: Log warning to stderr, use defaults
4. **Missing sections**: Use defaults for missing sections only
5. **Empty arrays**: Treated as "include nothing" (explicit opt-out)

## Validation

- Patterns MUST be valid glob syntax (tested with `bash` glob expansion)
- Extensions MUST NOT include leading dot (e.g., `md` not `.md`)
- Unknown keys are ignored (forward compatibility)
- Invalid patterns logged to stderr with line context

## Default Values

When no config file exists:

```toml
[include]
patterns = ["docs/**/*", "doc-assets/**/*", "**/*.md"]

[include.types]
extensions = ["md", "txt", "rst", "adoc", "org"]
```

## Implementation Notes

### AWK-Based Parsing

Use simple AWK parsing (no external TOML library required):

```bash
# Extract [include] patterns array
pndcgn_parse_toml_patterns() {
    local config_file="$1"
    awk '
        /^\[include\]/ { in_include = 1; next }
        /^\[/ { in_include = 0 }
        in_include && /^patterns\s*=/ {
            gsub(/.*\[/, "")
            gsub(/\].*/, "")
            gsub(/[",]/, " ")
            print
        }
    ' "$config_file"
}
```

### Error Handling

- Report parsing errors to stderr with line numbers
- Continue with defaults on parse failure (graceful degradation)
- Log which config source was used (XDG vs project)

### Precedence

When both patterns and extensions are specified, patterns take precedence. Extensions are used as a simpler alternative when glob patterns are not needed.

## Examples

### Minimal Config (use extensions only)

```toml
[include.types]
extensions = ["md"]
```

### Custom Documentation Structure

```toml
[include]
patterns = [
    "documentation/**/*.md",
    "guides/**/*.md",
    "api-docs/**/*.rst"
]
```

### Exclude Everything Except Explicit Patterns

```toml
[include]
patterns = ["README.md", "CHANGELOG.md"]
```

## Related Contracts

- [cli.md](./cli.md) - CLI interface contract
- [pndcgnignore.md](./pndcgnignore.md) - Exclude patterns contract
