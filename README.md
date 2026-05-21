# ctags-skill

Fast symbol lookup for navigating large codebases using Universal Ctags `tags` files.
Powered by [ripgrep](https://github.com/BurntSushi/ripgrep) + [jq](https://jqlang.github.io/jq/) for speed. Outputs JSON.

## Prerequisites

- **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`) — required, used for fast file searching
- **[jq](https://jqlang.github.io/jq/)** — required, used for parsing and JSON output
- **[Universal Ctags](https://ctags.io/)** — needed to generate the `tags` file

## Setup

1. Generate a tags file:
   ```
   ctags -R --fields=+lKn --extras=+f -o tags .
   ```
2. Place the `tags` file in the project root (or specify path with `--tags-file`).

The `--fields=+lKn` flag is important — it includes line numbers and kind information that the skill parses into structured output. The `--extras=+f` flag adds file-level entries for better coverage.

## Usage

### Bash (`scripts/lookup.sh`)

```bash
# Exact symbol name
./scripts/lookup.sh --name "Dispose"

# Prefix search
./scripts/lookup.sh --prefix "Get"

# Custom tags file path
./scripts/lookup.sh --tags-file "/path/to/tags" --name "MyClass"
```

### Windows CMD (`scripts/lookup.cmd`)

```cmd
scripts\lookup.cmd --name "Dispose"
scripts\lookup.cmd --prefix "Get"
scripts\lookup.cmd --tags-file "C:\myproject\tags" --name "MyClass"
```

## Output Format

```json
[{"Name":"Dispose","Kind":"method","File":"src/MyClass.cs","Line":"42","Scope":"class:MyNamespace.MyClass"}]
```

Empty results return `[]`.

## Properties

| Property | Description                                |
|----------|--------------------------------------------|
| `Name`   | Symbol name                                |
| `Kind`   | Human-readable kind (class, method, etc.)  |
| `File`   | Source file path                           |
| `Line`   | Line number                                |
| `Scope`  | Containing scope (class/enum/namespace...) |

## Why Use This Over grep

When an agent needs to find where a symbol is defined, it typically greps across all source files. On a large codebase (.NET Reference Source, 83 MB tags file / 413K symbols), the difference is dramatic:

| Approach | Time | Results |
|----------|------|---------|
| **This skill** (tags lookup) | ~108ms | 1,176 structured definitions with file, line, kind, scope |
| **rg across source files** | ~6,000ms | 1,406 files containing the text (includes usages, comments, strings) |

The skill is **~60x faster** and returns only **definitions** — not usages, not comments, not string literals. Each result includes the exact file, line number, symbol kind, and containing scope, so the agent can jump directly to the right location without further searching.

For prefix queries (e.g., finding all `Get*` methods), the skill returns structured results for thousands of symbols in under 2 seconds — something that would require multiple grep passes and heuristic filtering otherwise.

## Test Fixture

The file `test/dotnet-reference-source-tags` is a ctags file generated from [microsoft/referencesource](https://github.com/microsoft/referencesource) — the .NET Framework reference source code. It provides a large, real-world fixture (~413K symbols) for testing and benchmarking.
