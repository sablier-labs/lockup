---
name: bash-script
version: "1.0.0"
description: >
  Write bash scripts for Sablier development workflows. Trigger phrases: "write bash script", "shell script", "automate
  workflow", "prepare artifacts", or when working in scripts/bash/ directories.
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Bash Script Skill

Rules and patterns for shell scripts. Find examples in the actual codebase.

## Bundled References

| Reference                   | Content                      | When to Read            |
| --------------------------- | ---------------------------- | ----------------------- |
| `references/ci-patterns.md` | CI templates, GitHub Actions | When writing CI scripts |

## Script Location

```
scripts/
└── bash/                    # All bash scripts
    ├── prepare-artifacts.sh # Release artifact preparation
    ├── ci-*.sh              # CI automation scripts
    └── dev-*.sh             # Development utilities
```

---

## Header Template

```bash
#!/usr/bin/env bash

# Strict mode
set -euo pipefail

# Script description
# Usage: ./script.sh [args]
```

---

## Strict Mode Flags

| Flag          | Effect                       |
| ------------- | ---------------------------- |
| `-e`          | Exit on error                |
| `-u`          | Error on undefined variables |
| `-o pipefail` | Fail pipe on first error     |

---

## Variable Rules

| Rule                     | Example                 |
| ------------------------ | ----------------------- |
| Quote all variables      | `"${var}"` not `$var`   |
| Use braces               | `${var}` not `$var`     |
| Default values           | `${var:-default}`       |
| Required variables       | `${var:?error message}` |
| Uppercase for env vars   | `FOUNDRY_PROFILE`       |
| Lowercase for local vars | `local file_path`       |

---

## Function Pattern

```bash
function_name() {
    local arg1="${1}"
    local arg2="${2:-default}"

    # Implementation
}
```

---

## Error Handling

| Pattern               | Usage                   |
| --------------------- | ----------------------- |
| `command \|\| exit 1` | Exit on command failure |
| `command \|\| true`   | Ignore failure          |
| `trap cleanup EXIT`   | Cleanup on exit         |
| `if ! command; then`  | Check command success   |

---

## Common Patterns

### Check Command Exists

```bash
command -v forge &>/dev/null || { echo "forge not found"; exit 1; }
```

### Loop Over Files

```bash
for file in "${dir}"/*.sol; do
    [[ -f "${file}" ]] || continue
    # Process file
done
```

### Read JSON

```bash
value=$(jq -r '.key' "${json_file}")
```

---

---

## Anti-Patterns

| Avoid               | Use Instead                  |
| ------------------- | ---------------------------- |
| `cd dir && command` | `command -C dir` or subshell |
| Unquoted `$var`     | `"${var}"`                   |
| `[ ]` for tests     | `[[ ]]` (safer)              |
| Parsing `ls` output | Globs or `find`              |
| `cat file \| grep`  | `grep pattern file`          |

---

## Shellcheck

Always run `shellcheck` on scripts before committing.

```bash
shellcheck scripts/bash/*.sh
```

---

## Example Invocations

Test this skill with these prompts:

1. **CI script**: "Write a CI script that runs tests for all packages and reports failures"
2. **Artifact prep**: "Create a script to prepare release artifacts with version tagging"
3. **Dev utility**: "Write a script that watches for .sol file changes and runs tests"
