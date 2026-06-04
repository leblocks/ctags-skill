# ctags-skill [![skills.sh](https://skills.sh/b/owner/repo)](https://skills.sh/leblocks/ctags-skill)

Fast symbol lookup for navigating large codebases using Universal Ctags `tags` files.
Powered by [ripgrep](https://github.com/BurntSushi/ripgrep) + [jq](https://jqlang.github.io/jq/) for speed. Outputs JSON.

## What Are Tags Files?

A `tags` file is a pre-built index of symbol definitions (classes, methods, fields, etc.) extracted from source code by [Universal Ctags](https://ctags.io/). Each line maps a symbol name to its source file, line number, kind, and scope — essentially a lookup table for "where is this thing defined?"

**Why use tags instead of grepping source directly?**

- **Speed** — searching a single index file is orders of magnitude faster than scanning thousands of source files
- **Precision** — tags contain only *definitions*, not usages, comments, or string literals
- **Structure** — each entry includes the symbol kind (class/method/field), line number, and containing scope, so you know exactly what you're looking at

Tags files are language-aware (C#, Java, Python, TypeScript, etc.) and can index entire monorepos in seconds. Once generated, they serve as a fast offline lookup for any tool that needs to resolve symbol locations.

## Prerequisites

- **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`) — required, used for fast file searching
- **[jq](https://jqlang.github.io/jq/)** — required, used for parsing and JSON output
- **[Universal Ctags](https://ctags.io/)** — needed to generate the `tags` file

## Installation

```bash
npx skills add leblocks/ctags-skill
```

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

# Custom tags file path
./scripts/lookup.sh --tags-file "/path/to/tags" --name "MyClass"
```

### Windows CMD (`scripts/lookup.cmd`)

```cmd
scripts\lookup.cmd --name "Dispose"
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

When an agent needs to find where a symbol is defined, it typically greps across all source files. On a large codebase ([microsoft/referencesource](https://github.com/microsoft/referencesource), 83 MB tags file / 413K symbols), the difference is dramatic:

### Exact name lookup: "Dispose"

| Approach | Time | Results |
|----------|------|---------|
| **ctags-lookup** (`rg` + `jq`) | ~233ms | 1,176 structured definitions with file, line, kind, scope |
| **rg across source files** | ~8,107ms | 1,448 files containing the text (includes usages, comments, strings) |

**~35x faster**, returning only definitions — not usages, not comments, not string literals.

Each result includes the exact file, line number, symbol kind, and containing scope, so the agent can jump directly to the right location without further searching.

## Test Fixture

The file `test/dotnet-reference-source-tags` is a ctags file generated from [microsoft/referencesource](https://github.com/microsoft/referencesource) — the .NET Framework reference source code. It provides a large, real-world fixture (~413K symbols) for testing and benchmarking.
