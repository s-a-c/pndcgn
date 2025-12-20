# Troubleshooting Guide

This guide helps resolve common issues when using pndcgn.

## Table of Contents

- [Common Issues](#common-issues)
- [Configuration Problems](#configuration-problems)
- [Performance Issues](#performance-issues)
- [Error Messages](#error-messages)
- [Getting Help](#getting-help)

## Common Issues

### Issue: "Source directory does not exist"

**Symptoms**: Error message: `Source directory does not exist: <path>`

**Solutions**:
1. Verify the path is correct (use absolute path if needed)
2. Check for typos in directory name
3. Ensure the directory exists before running pndcgn
4. Use `pwd` to verify your current directory

**Example**:
```bash
# Check if directory exists
ls -la docs/

# Use absolute path
pndcgn /full/path/to/docs/ /full/path/to/output/
```

### Issue: "Target directory is not writable"

**Symptoms**: Error message: `Target directory is not writable: <path>`

**Solutions**:
1. Check directory permissions: `ls -ld <target_dir>`
2. Ensure you have write permissions
3. Create the directory if it doesn't exist: `mkdir -p <target_dir>`
4. Check disk space: `df -h`

**Example**:
```bash
# Check permissions
ls -ld output/

# Fix permissions if needed
chmod u+w output/

# Create directory if missing
mkdir -p output/
```

### Issue: "Unsupported output type"

**Symptoms**: Error message: `Unsupported output type: <type>`

**Solutions**:
1. Verify the output type is supported by pandoc
2. Check pandoc version: `pandoc --version` (2.0+ recommended)
3. List supported formats: `pandoc --list-output-formats`
4. Use lowercase for output type: `--type pdf` not `--type PDF`

**Example**:
```bash
# Check pandoc version
pandoc --version

# List supported formats
pandoc --list-output-formats

# Use correct format name
pndcgn --type pdf docs/ output/
```

### Issue: "Missing required prerequisites"

**Symptoms**: Error message: `Missing required prerequisites: pandoc sqlite3 curl`

**Solutions**:
1. Install missing tools:
   - **macOS**: `brew install pandoc sqlite curl`
   - **Linux**: `apt-get install pandoc sqlite3 curl` (Debian/Ubuntu) or `yum install pandoc sqlite curl` (RHEL/CentOS)
2. Verify installation: `which pandoc sqlite3 curl`
3. Add to PATH if installed but not found

**Example**:
```bash
# macOS
brew install pandoc sqlite curl

# Linux (Debian/Ubuntu)
sudo apt-get install pandoc sqlite3 curl

# Verify
which pandoc sqlite3 curl
```

## Configuration Problems

### Issue: Files not being processed

**Symptoms**: Expected files are not included in processing

**Solutions**:
1. Check `.pndcgnignore` patterns (may be excluding files)
2. Verify TOML include patterns match your files
3. Use `--verbose` to see which files are discovered
4. Check file extensions match `[include.types]` configuration

**Example**:
```bash
# Run with verbose output
pndcgn --verbose docs/ output/

# Check ignore patterns
cat .pndcgnignore

# Check TOML config
cat pndcgn.toml
```

### Issue: TOML parse errors

**Symptoms**: Error message: `TOML parse error in <file>`

**Solutions**:
1. Validate TOML syntax (check for missing brackets, quotes)
2. Ensure arrays use proper syntax: `patterns = ["pattern1", "pattern2"]`
3. Check for special characters that need escaping
4. Verify file encoding (should be UTF-8)

**Example**:
```toml
# Correct syntax
[include]
patterns = [
    "docs/**",
    "guides/**"
]

# Incorrect syntax (missing brackets)
[include]
patterns = "docs/**"  # Wrong: should be array
```

### Issue: Pattern not matching files

**Symptoms**: Include patterns don't match expected files

**Solutions**:
1. Use `**` for recursive matching: `docs/**` not `docs/*`
2. Check pattern case sensitivity (patterns are case-sensitive)
3. Verify file paths relative to source directory
4. Test patterns with `--verbose` to see matches

**Example**:
```toml
# Recursive matching
patterns = ["docs/**"]  # Matches docs/ and all subdirectories

# Single level
patterns = ["docs/*"]  # Only matches files directly in docs/
```

## Performance Issues

### Issue: Slow processing

**Symptoms**: Processing takes a long time

**Solutions**:
1. Check cache efficiency (should be high after first run)
2. Use `--force` sparingly (bypasses cache)
3. Verify disk I/O performance
4. Check for large files that may slow processing

**Example**:
```bash
# Check cache efficiency (shown in summary)
pndcgn docs/ output/

# First run: 0% cache efficiency (expected)
# Subsequent runs: Should be >80% cache efficiency
```

### Issue: High memory usage

**Symptoms**: Process uses excessive memory

**Solutions**:
1. Process in smaller batches (split source directory)
2. Check for very large files (>100MB)
3. Verify SQLite database size (may need cleanup)
4. Use `--drop` to clear cache if database is corrupted

**Example**:
```bash
# Check database size
ls -lh ~/.local/state/pndcgn/pndcgn.db

# Clear cache if needed
pndcgn --drop --yes
```

## Error Messages

### "Fingerprint validation failed"

**Cause**: Source files or configuration changed between dry-run and finalize

**Solution**:
1. Review what changed (check git status if using version control)
2. Create a new dry-run if changes are intentional
3. Restore original files if changes were accidental

**Example**:
```bash
# Check what changed
git status

# Create new dry-run
pndcgn --dry-run docs/ output/
```

### "Run not found"

**Cause**: Run ID doesn't exist or database was cleared

**Solution**:
1. Verify run ID is correct (check previous output)
2. Check if database was cleared with `--drop`
3. Create a new run instead

**Example**:
```bash
# Verify run ID format (should be ULID)
echo "01ARZ3NDEKTSV4Y5QH6J7K8M9"

# Create new run if needed
pndcgn docs/ output/
```

### "Disk full"

**Cause**: Insufficient disk space for output files

**Solution**:
1. Free up disk space: `df -h`
2. Use a different target directory with more space
3. Clean up old run outputs: `pndcgn --clean <run_id>`

**Example**:
```bash
# Check disk space
df -h

# Clean old runs
pndcgn --clean 01ARZ3NDEKTSV4Y5QH6J7K8M9 --yes
```

## Getting Help

### Debug Information

Collect debug information before reporting issues:

```bash
# Version information
pndcgn --version

# System information
uname -a
pandoc --version
sqlite3 --version

# Run with verbose output
pndcgn --verbose docs/ output/ 2>&1 | tee debug.log
```

### Common Debug Steps

1. **Enable verbose mode**: `pndcgn --verbose`
2. **Check prerequisites**: Ensure all required tools are installed
3. **Verify configuration**: Check TOML syntax and patterns
4. **Test with dry-run**: Use `--dry-run` to preview without generating files
5. **Check logs**: Review error messages for specific guidance

### Reporting Issues

When reporting issues, include:

- pndcgn version: `pndcgn --version`
- Operating system: `uname -a`
- Pandoc version: `pandoc --version`
- Error messages (full output)
- Configuration files (`.pndcgnignore`, `pndcgn.toml`)
- Steps to reproduce

### Additional Resources

- **Man page**: `man pndcgn` (if installed)
- **Configuration guide**: See [TOML Config Defaults](./toml-config-defaults.md)
- **Migration examples**: See [Migration Examples](./migration-examples.md)
- **Project repository**: Check for known issues and updates
