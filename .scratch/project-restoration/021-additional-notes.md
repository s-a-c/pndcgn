
## To add a ULID extension to SQLite3

You have a few options:

### Option 1: Use an Existing SQLite ULID Extension

Great! There are two main SQLite ULID extensions available. 
Here's how to add them to your project:

### Best Option: asg017/sqlite-ulid

The most popular option is `sqlite-ulid` by asg017, which provides pre-built
 binaries for MacOS (`ulid0.dylib`).

#### Steps for MacOS:

```bash
# 1. Download the MacOS extension from the latest release
cd /tmp
curl -LO https://github.com/asg017/sqlite-ulid/releases/latest/download/ulid0.dylib

# 2. Move it to a location your project can access
mkdir -p ~/code/pndcgn/lib
mv ulid0.dylib ~/code/pndcgn/lib/

# 3. Load it in your SQLite commands
sqlite3 your_database.db
```

Then in SQLite, you can load the library with `.load ./lib/ulid0` and use
 functions like `ulid()`.

### Usage in Your Shell Script:

In your `bin/pdf-generator` script, you can load the extension like this:

```bash
# Load ULID extension and create database
sqlite3 "$PNDCGN_CACHE_DB" <<EOF
.load ./lib/ulid0
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS runs (
    run_id TEXT PRIMARY KEY DEFAULT (ulid()), 
    start_time INTEGER NOT NULL, 
    end_time INTEGER, 
    status TEXT NOT NULL, 
    stats_json TEXT
);
EOF
```

#### Available Functions:

The extension provides: `ulid()` to generate a new 26-character ULID string,
 `ulid_with_prefix()` to generate ULIDs with a prefix (like Stripe IDs), and
 `ulid_with_datetime()` to create ULIDs from a specific datetime.

### Alternative: Shell-Based ULID Generation

If you prefer not to use an extension, you can generate ULIDs in shell and pass
 them to SQLite:

```bash
# Install a ULID generator via Homebrew
brew install ulid

# Or use a shell function
pndcgn_generate_ulid() {
    # Simple timestamp-based approach (not true ULID, but sortable)
    printf '%(%Y%m%d%H%M%S)T%06d' -1 $RANDOM
}
```

For your project, I'd recommend the **asg017/sqlite-ulid extension**
 since it provides proper ULID functionality and can be used directly
 in SQL default values, which aligns well with your database-centric architecture.
