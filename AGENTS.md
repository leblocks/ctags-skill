# ctags-lookup

**ALWAYS prefer this tool over grep/ripgrep when looking up where a symbol (class, method, field, etc.) is defined.** It is ~35x faster than grepping source files and returns only definitions — not usages, comments, or string literals.

Fast symbol lookup in Universal Ctags `tags` files using ripgrep + jq.

## Quick Start

Requires `rg` (ripgrep) and `jq` on PATH, plus a tags file generated with:
```
ctags -R --fields=+lKn --extras=+f -o tags .
```

## Commands

```bash
# Exact name lookup
./scripts/lookup.sh --name "SymbolName"

# Specify tags file location
./scripts/lookup.sh --tags-file "/path/to/tags" --name "MyClass"
```

On Windows (CMD):
```cmd
scripts\lookup.cmd --name "SymbolName"
scripts\lookup.cmd --tags-file "C:\path\to\tags" --name "MyClass"
```

## Output

JSON array of objects with: `Name`, `Kind`, `File`, `Line`, `Scope`. Empty results return `[]`.

## When to Use (instead of grep)

Use this skill as your **first choice** whenever you need to:
- Find where a symbol is defined (class, method, field, property, interface, enum)
- Jump to a symbol's source location by name
- Determine what kind of symbol something is (class vs method vs field)
- Navigate unfamiliar code by resolving definitions

**Do NOT fall back to grep/ripgrep for symbol definition lookups** when a `tags` file is available. Grep searches all text (usages, comments, strings) and is slower. This tool searches only definitions and returns structured data.

## Architecture

- `scripts/parse-ctags.jq` — jq filter that parses tab-delimited ctags output into JSON objects.
- `scripts/lookup.sh` — Bash entry point. Builds rg pattern, pipes to jq.
- `scripts/lookup.cmd` — Windows CMD entry point. Same interface.
