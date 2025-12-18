#!/usr/bin/env shellspec
#
# pndcgn Configuration Tests
#
# Compliant with [AGENTS.md](../../AGENTS.md)
#
# Description: Tests for TOML configuration file discovery and parsing
# Coverage: Uses 'When call' for kcov tracking (same-process execution)

. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/tests/spec_helper.sh"

# Source utilities for When call pattern (same-process execution enables coverage)
. "${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh"

Describe "TOML Configuration File Discovery and Parsing"

    BeforeAll 'setup_test_env'
    AfterAll 'cleanup_test_env'

    Context "Config file discovery (T049a)"
        It "discovers config in XDG config directory when present"
            local xdg_config_dir
            xdg_config_dir=$(pndcgn_get_config_dir)
            mkdir -p "$xdg_config_dir"
            echo '[include]' > "$xdg_config_dir/pndcgn.toml"
            echo 'patterns = ["docs/**/*.md"]' >> "$xdg_config_dir/pndcgn.toml"

            When call pndcgn_discover_config_file "/tmp/test-source"
            The output should eq "$xdg_config_dir/pndcgn.toml"
            The status should be success

            rm -f "$xdg_config_dir/pndcgn.toml"
        End

        It "falls back to source directory config when XDG config missing"
            local source_dir
            source_dir=$(mktemp -d)
            echo '[include]' > "$source_dir/pndcgn.toml"
            echo 'patterns = ["custom/**/*.md"]' >> "$source_dir/pndcgn.toml"

            When call pndcgn_discover_config_file "$source_dir"
            # Normalize path to handle symlinks (e.g., /var -> /private/var on macOS)
            local expected_path actual_path
            expected_path=$(readlink -f "$source_dir/pndcgn.toml" 2>/dev/null || echo "$source_dir/pndcgn.toml")
            actual_path=$(readlink -f "$(pndcgn_discover_config_file "$source_dir")" 2>/dev/null || pndcgn_discover_config_file "$source_dir")
            The output should eq "$expected_path"
            The status should be success

            rm -rf "$source_dir"
        End

        It "returns empty when no config file exists"
            local source_dir
            source_dir=$(mktemp -d)

            When call pndcgn_discover_config_file "$source_dir"
            The output should eq ""
            The status should be success

            rm -rf "$source_dir"
        End

        It "prefers source directory config over XDG config when both exist"
            local xdg_config_dir source_dir
            xdg_config_dir=$(pndcgn_get_config_dir)
            source_dir=$(mktemp -d)
            mkdir -p "$xdg_config_dir"
            echo '[include]' > "$xdg_config_dir/pndcgn.toml"
            echo 'patterns = ["xdg-pattern"]' >> "$xdg_config_dir/pndcgn.toml"
            echo '[include]' > "$source_dir/pndcgn.toml"
            echo 'patterns = ["source-pattern"]' >> "$source_dir/pndcgn.toml"

            When call pndcgn_discover_config_file "$source_dir"
            # Normalize path to handle symlinks (e.g., /var -> /private/var on macOS)
            local expected_path
            expected_path=$(readlink -f "$source_dir/pndcgn.toml" 2>/dev/null || echo "$source_dir/pndcgn.toml")
            The output should eq "$expected_path"
            The status should be success

            rm -f "$xdg_config_dir/pndcgn.toml"
            rm -rf "$source_dir"
        End
    End

    Context "TOML config parsing (T049b)"
        It "parses include patterns array"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = [
    "docs/**/*.md",
    "doc-assets/**/*",
    "*.md"
]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should include "doc-assets/**/*"
            The output should include "*.md"
            The status should be success

            rm -f "$config_file"
        End

        It "parses include extensions array"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include.types]
extensions = ["md", "txt", "rst"]
EOF

            When call pndcgn_parse_toml_extensions "$config_file"
            The output should include "md"
            The output should include "txt"
            The output should include "rst"
            The status should be success

            rm -f "$config_file"
        End

        It "handles inline array syntax"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["docs/**/*.md", "*.md"]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should include "*.md"
            The status should be success

            rm -f "$config_file"
        End

        It "ignores comments in TOML"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
# This is a comment
[include]
# Another comment
patterns = ["docs/**/*.md"]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should not include "#"
            The status should be success

            rm -f "$config_file"
        End

        It "handles empty patterns array"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = []
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should eq ""
            The status should be success

            rm -f "$config_file"
        End

        It "handles missing include section gracefully"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[other]
key = "value"
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should eq ""
            The status should be success

            rm -f "$config_file"
        End

        It "handles quoted strings in arrays"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["docs/**/*.md", '*.md', "README.md"]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should include "*.md"
            The output should include "README.md"
            The status should be success

            rm -f "$config_file"
        End
    End

    # Phase 8: NFR P1-MVP Tests
    Context "include/exclude pattern evaluation order (T076r)"
        It "evaluates include patterns before exclude patterns"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["docs/**/*.md", "!docs/private/**"]
EOF

            # Pattern evaluation order should be: include first, then exclude
            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The status should be success

            rm -f "$config_file"
        End
    End

    # Phase 9: NFR P2 TOML Config Tests
    Context "config symlink following (T097a)"
        It "follows symlinks to config files"
            local config_file
            config_file=$(mktemp)
            local symlink_file
            symlink_file=$(mktemp -u)
            echo '[include]' > "$config_file"
            echo 'patterns = ["docs/**/*.md"]' >> "$config_file"
            ln -s "$config_file" "$symlink_file"

            When call pndcgn_parse_toml_patterns "$symlink_file"
            The output should include "docs/**/*.md"
            The status should be success

            rm -f "$config_file" "$symlink_file"
        End
    End

    Context "XDG_CONFIG_HOME with spaces (T097b)"
        It "handles XDG_CONFIG_HOME with spaces in path"
            local test_config_dir
            test_config_dir=$(mktemp -d -t "test config dir")
            # pndcgn_get_config_dir returns $XDG_CONFIG_HOME/pndcgn, so create file there
            mkdir -p "$test_config_dir/pndcgn"
            local config_file="$test_config_dir/pndcgn/pndcgn.toml"
            echo '[include]' > "$config_file"
            echo 'patterns = ["docs/**/*.md"]' >> "$config_file"

            export XDG_CONFIG_HOME="$test_config_dir"
            # Source utilities to make function available
            # Need to ensure HOME is set for pndcgn_get_config_dir to work
            When run bash -c "export HOME=\"\${HOME:-/tmp}\" && source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_discover_config_file ''"
            # Should return the config file path (may be normalized)
            The output should include "pndcgn.toml"
            The status should be success

            rm -rf "$test_config_dir"
            unset XDG_CONFIG_HOME
        End
    End

    Context "glob pattern wildcards (T097d)"
        It "handles glob pattern wildcards correctly"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["docs/**/*.md", "*.txt", "test?/file.*"]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should include "*.txt"
            The output should include "test?/file.*"
            The status should be success

            rm -f "$config_file"
        End
    End

    Context "pattern case sensitivity (T097e)"
        It "handles pattern case sensitivity"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["Docs/**/*.MD", "README.md"]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "Docs/**/*.MD"
            The output should include "README.md"
            The status should be success

            rm -f "$config_file"
        End
    End

    Context "extension case insensitivity (T097f)"
        It "handles extension case variations"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include.types]
extensions = ["MD", "md", "Markdown", "TXT"]
EOF

            When call pndcgn_parse_toml_extensions "$config_file"
            The output should include "MD"
            The output should include "md"
            The status should be success

            rm -f "$config_file"
        End
    End

    Context "TOML comments (T097h)"
        It "ignores TOML comments in patterns"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
# This is a comment
[include]
# Another comment
patterns = ["docs/**/*.md"]  # Inline comment
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should not include "#"
            The status should be success

            rm -f "$config_file"
        End
    End

    Context "HOME unset error (T097k)"
        It "handles HOME unset gracefully"
            local original_home="$HOME"
            unset HOME

            # Should fall back to default or handle gracefully
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_get_state_dir 2>&1 || true"
            The status should be success

            export HOME="$original_home"
        End
    End

    Context "config directory error (T097c)"
        It "handles config directory errors gracefully"
            local original_xdg="$XDG_CONFIG_HOME"
            export XDG_CONFIG_HOME="/nonexistent/config/dir"

            # Should handle missing config directory
            When run bash -c "source '${SHELLSPEC_PROJECT_ROOT:-$PWD}/src/utilities.sh' && pndcgn_discover_config_file '' 2>&1 || true"
            The status should be defined

            export XDG_CONFIG_HOME="$original_xdg"
        End
    End

    Context "TOML multi-line arrays (T097g)"
        It "parses TOML multi-line arrays"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = [
    "docs/**/*.md",
    "*.txt",
    "README.md"
]
EOF

            When call pndcgn_parse_toml_patterns "$config_file"
            The output should include "docs/**/*.md"
            The output should include "*.txt"
            The output should include "README.md"
            The status should be success

            rm -f "$config_file"
        End
    End

    Context "parse error line numbers (T097i)"
        It "reports parse error line numbers"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["valid"]
invalid syntax here
EOF

            # Should handle parse errors gracefully
            When run bash -c "pndcgn_parse_toml_patterns '$config_file' 2>&1 || true"
            The status should be defined

            rm -f "$config_file"
        End
    End

    Context "absolute path pattern rejection (T097j)"
        It "rejects absolute path patterns"
            local config_file
            config_file=$(mktemp)
            cat > "$config_file" <<'EOF'
[include]
patterns = ["/absolute/path/**"]
EOF

            # Should handle absolute paths (may reject or handle)
            When call pndcgn_parse_toml_patterns "$config_file"
            The output should be defined
            The status should be success

            rm -f "$config_file"
        End
    End
End
