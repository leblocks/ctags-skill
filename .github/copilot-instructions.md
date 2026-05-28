# Copilot Instructions

## Project Overview

A tool for fast symbol lookup in Universal Ctags `tags` files, using ripgrep (`rg`) for speed and jq for parsing/JSON output. No PowerShell dependency.

## Architecture

- **`scripts/parse-ctags.jq`** — jq filter that parses tab-delimited ctags lines into JSON objects. Handles kind-code mapping, line number extraction, and scope parsing.
- **`scripts/lookup.sh`** — Bash CLI entry point. Validates prerequisites, builds the ripgrep regex pattern, and pipes `rg | jq`.
- **`scripts/lookup.cmd`** — Windows CMD entry point. Same interface and behavior as the bash version.
- **`test/dotnet-reference-source-tags`** — A real ctags file (generated from [microsoft/referencesource](https://github.com/microsoft/referencesource)) used as test fixture.

**Data flow:** `rg` filters the tags file by regex → stdout piped to `jq -nMRf parse-ctags.jq` → JSON array output. The `CTAGS_EXACT_NAME` env var is set by the shell scripts so jq can do post-filtering for exact matches.

Search mode: `--name` (exact, case-sensitive).

## Conventions

- Cross-platform: bash for Unix, CMD for Windows. Both must implement identical behavior and use the same jq filter.
- Kind codes are mapped to human-readable strings via a jq object literal in `parse-ctags.jq`; add new mappings there when supporting additional languages.
- 4 spaces indentation, UTF-8, LF line endings, max 120 chars per line.
- Output is always a JSON array (even for errors that produce no results: `[]`).

## Testing

```powershell
# Windows — full suite (Pester)
Invoke-Pester .\test\windows\lookup.Tests.ps1 -Output Detailed

# Windows — single test by name
Invoke-Pester .\test\windows\lookup.Tests.ps1 -Output Detailed -FullNameFilter "*Should find symbols by exact name*"
```

```bash
# Linux — full suite (bats-core via Docker)
docker build -t ctags-skill-test -f test/linux/Dockerfile .
docker run --rm ctags-skill-test

# Linux — single test by name (inside container or with bats installed)
bats --filter "finds symbols by exact name" test/linux/lookup.bats
```
