[1 tool called]

### Recommended order of focus for `tests/pndcgn_spec.sh` contexts

**Tier 1 – Core CLI behavior (arg parsing + basic control flow)**

1. **`Context "when parsing arguments"`**
2. **`Context "error handling"`** (exit codes for runtime errors, invalid usage, help, stderr)
3. **`Context "--help output structure (T094a)"`**
4. **`Context "--version output (T094b)"`**

**Tier 2 – Happy-path runs with real DB + pandoc**

5. **`Context "when reporting progress"`** (Run ID + file counts)
6. **`Context "end-to-end generation workflow"`**
7. **`Context "dry-run functionality"`** (`--dry-run` happy path)
8. **`Context "--verbose mode (T094c)"`**
9. **`Context "final summary output (T094h)"`**

**Tier 3 – Finalize and fingerprint semantics (DB-heavy, some mocks kept)**

10. **`Context "finalize functionality"`**
11. **`Context "fingerprint validation"`**
12. **`Context "dry-run to finalize workflow"`**

**Tier 4 – Flags that affect workflow but are still “normal” success paths**

13. **`Context "when --reseed flag is provided"`**
14. **`Context "when --force flag is provided"`**

**Tier 5 – Simple error conditions around filesystem / options**

15. **`Context "when source directory is unreadable"`**
16. **`Context "when target directory is unwritable"`**
17. **`Context "when output type is unsupported"`**

**Tier 6 – fzf behaviors**

18. **`Context "when fzf is unavailable"`** (early T014b context)
19. **`Context "when fzf is unavailable"`** (T049i: silent fallback)

**Tier 7 – NFR / UX edge cases on “normal” runs**

20. **`Context "empty source directory warning (T096a)"`**
21. **`Context "source not-a-directory error (T096b)"`**
22. **`Context "source paths with spaces (T096c)"`**
23. **`Context "target directory creation (T096g)"`**
24. **`Context "output type case insensitivity (T096k)"`**
25. **`Context "error message format (T094i)"`**

**Tier 8 – DB/error-path specific behaviors (kept sqlite3 mocks)**

26. **`Context "non-interactive mode requiring --yes flag (T076c)"`**
27. **`Context "disk full error handling (T076m)"`**
28. **`Context "config change during dry-run/finalize detection (T076s)"`**
29. **`Context "cleanup active run error (T096q)"`**
30. **`Context "interrupted state communication (T094j)"`**

**Tier 9 – Signal handling / traps & ignore rules**

31. **`Context "SIGINT graceful shutdown (T076d)"`**
32. **`Context "SIGTERM graceful shutdown (T076o)"`**
33. **`Context "trap handler installation (T076p)"`**
34. **`Context "SIGHUP ignore (T096m)"`**
35. **`Context "malformed .pndcgnignore warning (T096p)"`**

If you’d like, I can start from Tier 1 and work downward, fixing contexts in that order.

---
