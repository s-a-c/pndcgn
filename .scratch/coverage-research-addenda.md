# Coverage Research Addenda

---

<details><summary>Table of Contents</summary>

- [Coverage Research Addenda](#coverage-research-addenda)
  - [1. given a bash project, best test coverage tools](#1-given-a-bash-project-best-test-coverage-tools)
    - [1.1. The Best Tool: Kcov](#11-the-best-tool-kcov)
    - [1.2. Implementation Guide](#12-implementation-guide)
      - [1.2.1. A. Running Locally](#121-a-running-locally)
      - [1.2.2. B. GitHub Actions Integration (CI/CD)](#122-b-github-actions-integration-cicd)
    - [1.3. Handling Specific Edge Cases](#13-handling-specific-edge-cases)
      - [1.3.1. Sourced Scripts](#131-sourced-scripts)
      - [1.3.2. Subshells](#132-subshells)
    - [1.4. Alternative: Bashcov](#14-alternative-bashcov)
  - [2. how does using shellspec framework affect the use of kcov](#2-how-does-using-shellspec-framework-affect-the-use-of-kcov)
    - [2.1. The Command Changes](#21-the-command-changes)
    - [2.2. Configuration via `.shellspec`](#22-configuration-via-shellspec)
    - [2.3. Impact on Subshells and Mocks (Crucial)](#23-impact-on-subshells-and-mocks-crucial)
    - [2.4. Updated CI/CD Integration (GitHub Actions)](#24-updated-cicd-integration-github-actions)
    - [2.5. Summary of Differences](#25-summary-of-differences)

</details>

---

## 1. given a bash project, best test coverage tools

- ci/cd integration (github actions)
- tracking coverage even when `sourced` or in a subshell

For a Bash project requiring robust coverage tracking—especially for `sourced` scripts and subshells—**[kcov](https://github.com/SimonKagstrom/kcov)** is widely considered the best tool.

Unlike pure shell-based tracers (which often lose context in subshells) or language-specific wrappers (like Ruby's `bashcov`), `kcov` is a compiled binary that uses OS-level debugging features (like `ptrace` on Linux) to track execution. This makes it uniquely capable of following your code into subshells, pipes, and complex sourcing chains.

Here is the breakdown of the best tools and a complete CI/CD integration guide.

### 1.1. The Best Tool: Kcov

**Why it fits your needs:**
*   **Subshell Support:** Because it pauses and traces the process tree, it captures coverage even when your script spawns subshells `( ... )` or pipes `cmd | cmd`.
*   **Sourced Scripts:** It correctly maps coverage back to the original source files, even if they are sourced multiple times.
*   **Standard Formats:** It outputs **Cobertura XML**, which is the industry standard for CI visualizations (Codecov, Coveralls, Jenkins, etc.).

### 1.2. Implementation Guide

#### 1.2.1. A. Running Locally
Using the official Docker image is often cleaner than installing the C++ dependencies manually.

```bash
# Assuming your tests are in ./test and entry point is ./test/run_tests.sh
docker run --security-opt seccomp=unconfined \
  -v "$PWD:/source" \
  kcov/kcov \
  --include-pattern=.sh \
  --exclude-pattern=/test \
  /source/coverage \
  /source/test/run_tests.sh
```
*Note: `--security-opt seccomp=unconfined` is required for `ptrace` to work inside Docker.*

#### 1.2.2. B. GitHub Actions Integration (CI/CD)
Here is a complete `.github/workflows/test.yaml` that installs kcov, runs your tests, and posts a summary to the PR.

This setup uses **Codecov** for detailed reporting, or **Code Coverage Summary** for a simple comment on the PR without third-party accounts.

```yaml
name: Test & Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      #  Install kcov
      # We download a static binary or build it.
      # On Ubuntu, the apt version can be old, so we often use the snap or a managed step.
      # For simplicity in CI, using the apt version is often "good enough",
      # but manually installing the latest release is safer for newer bash features.
      - name: Install kcov
        run: |
          sudo apt-get update
          sudo apt-get install -y kcov

      # 2. Run Tests with Coverage
      # We tell kcov to output to ./coverage and run your test script
      - name: Run Tests
        run: |
          # --include-pattern ensures we only track your scripts, not system libs
          kcov --include-pattern=.sh --exclude-pattern=test ./coverage ./test/run_tests.sh

      # 3. OPTION A: Upload to Codecov (Recommended for detailed UI)
      # Requires setting up a repository on codecov.io
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/cobertura.xml
          fail_ci_if_error: true

      # 3. OPTION B: PR Comment (No 3rd party account needed)
      # Generates a simple markdown table in your PR
      - name: Code Coverage Summary
        uses: irongut/CodeCoverageSummary@v1.3.0
        with:
          filename: coverage/cobertura.xml
          badge: true
          fail_below_min: true
          format: markdown
          hide_branch_rate: false
          hide_complexity: true
          indicators: true
          output: both
          thresholds: '60 80'

      - name: Add Coverage PR Comment
        uses: marocchino/sticky-pull-request-comment@v2
        if: github.event_name == 'pull_request'
        with:
          recreate: true
          path: code-coverage-results.md
```

### 1.3. Handling Specific Edge Cases

#### 1.3.1. Sourced Scripts
Kcov handles this natively. If `main.sh` sources `utils.sh`, coverage will be generated for `utils.sh` automatically.
*   **Tip:** If you have a library file that is *only* sourced and never executed directly, ensure your test runner sources it or calls a function within it.

#### 1.3.2. Subshells
Kcov usually tracks subshells automatically. However, if you are doing very complex forking or using `sudo` inside scripts, you might lose the trace.
*   **Fix:** If you notice missing coverage in subshells, ensure you are **not** changing users (e.g., `su user -c ...`) inside the script without passing the specific kcov trace flags, though this is rare in standard CI environments.

### 1.4. Alternative: Bashcov
If you cannot use `kcov` (perhaps due to binary compilation issues), **Bashcov** is the runner-up.
*   **Pros:** Integrates natively with `SimpleCov` (Ruby).
*   **Cons:** Requires a Ruby environment; slower execution time; sometimes misses edge-case subshells compared to kcov's ptrace method.

To use Bashcov in CI:
```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.0'
- run: gem install bashcov
- run: bashcov ./test/run_tests.sh
```

## 2. how does using shellspec framework affect the use of kcov

Using ShellSpec actually **simplifies** the use of `kcov`.

Because ShellSpec is a sophisticated BDD framework that generates shell code dynamically, running `kcov` manually against the ShellSpec runner can be messy (you end up covering the testing framework rather than your code).

To solve this, ShellSpec has **native, built-in integration** for `kcov`. You generally do not invoke the `kcov` binary directly; you tell ShellSpec to "turn on coverage."

Here is how ShellSpec changes your workflow:

### 2.1. The Command Changes

Instead of the complex command required to run kcov manually:

```bash
# The "Hard" Manual Way
kcov --include-pattern=.sh --exclude-pattern=spec coverage/ ./my_test_runner.sh
```

You simply run ShellSpec with the flag:

```bash
# The ShellSpec Way
shellspec --kcov
```

ShellSpec detects the `kcov` binary in your path, configures the include/exclude patterns automatically (so you don't track the spec files themselves), and outputs the report to the standard `coverage/` directory.

### 2.2. Configuration via `.shellspec`

You can make coverage the default behavior or tweak settings in your project's `.shellspec` file (located at the root of your project).

```bash
# .shellspec
--kcov
--kcov-options "--include-pattern=.lib.sh"
```

This is significantly cleaner than maintaining long CLI strings in your CI YAML files.

### 2.3. Impact on Subshells and Mocks (Crucial)

This is where the behavior of the framework affects coverage results significantly:

* **Mocking Reduces Coverage (Correctly):**

    In ShellSpec, you often mock functions:

    ```bash
    It "calls the upload function"
      upload_data() { return 0; } # Mocking the real function
      When call process_data
      The status should be success
    End
    ```

    Because ShellSpec intercepts the call to `upload_data` and runs your mock instead, **kcov will report the real `upload_data` function as uncovered.** This is technically correct behavior (the real code didn't run), but it surprises many developers. To fix this, you must write integration tests that do *not* mock the internal functions.

* **Intercepting Subshells:**

    ShellSpec runs `Intercept` (mocks) by modifying the shell environment. Because `kcov` tracks the process at the OS level (`ptrace`), it sees through ShellSpec's "magic." This ensures that even if ShellSpec wraps your code in complex function structures to handle the "Expect/It" syntax, `kcov` still maps the execution back to your original source file lines accurately.

### 2.4. Updated CI/CD Integration (GitHub Actions)

Here is how the CI workflow looks when combining ShellSpec and Kcov. It is cleaner than the raw `kcov` example.

```yaml
name: ShellSpec Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      #  Install kcov (Required prerequisite)
      - name: Install kcov
        run: |
          sudo apt-get update
          sudo apt-get install -y kcov

      # 2. Install ShellSpec
      - name: Install ShellSpec
        run: curl -fsSL https://git.io/shellspec | sh -s -- -y

      # 3. Run ShellSpec with kcov enabled
      # We add the shellspec bin to path temporarily for this step
      - name: Run Tests with Coverage
        run: |
          $HOME/.local/bin/shellspec --kcov

      # 4. Upload results (Same as before)
      - name: Code Coverage Summary
        uses: irongut/CodeCoverageSummary@v1.3.0
        with:
          filename: coverage/cobertura.xml
          badge: true
          format: markdown
          output: both

      - name: Add Coverage PR Comment
        uses: marocchino/sticky-pull-request-comment@v2
        if: github.event_name == 'pull_request'
        with:
          recreate: true
          path: code-coverage-results.md
```

### 2.5. Summary of Differences

| Feature | Raw Kcov | ShellSpec + Kcov |
| :--- | :--- | :--- |
| **Invocation** | `kcov [flags] output/ ./script.sh` | `shellspec --kcov` |
| **Pattern Matching** | Manual `--include` / `--exclude` flags | Auto-configured (excludes spec files automatically) |
| **Mocking** | N/A (Manual mocking) | Mocks reduce coverage of real functions |
| **Setup** | High complexity | Low complexity |

**Recommendation:** If you are using ShellSpec, definitely use the built-in `--kcov` flag. Do not try to wrap the `shellspec` command in `kcov` manually, as it will produce messy reports covering the framework internals.
