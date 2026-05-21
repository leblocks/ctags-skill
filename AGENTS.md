# ctags-lookup

Fast symbol lookup in Universal Ctags `tags` files using ripgrep + jq. Use when navigating large codebases, finding symbol definitions, or resolving symbol locations.

## Quick Start

Requires `rg` (ripgrep) and `jq` on PATH, plus a tags file generated with:
```
ctags -R --fields=+lKn --extras=+f -o tags .
```

## Commands

```bash
# Exact name lookup
./scripts/lookup.sh --name "SymbolName"

# Prefix search
./scripts/lookup.sh --prefix "Get"

# Specify tags file location
./scripts/lookup.sh --tags-file "/path/to/tags" --name "MyClass"
```

On Windows (CMD):
```cmd
scripts\lookup.cmd --name "SymbolName"
scripts\lookup.cmd --prefix "Get"
scripts\lookup.cmd --tags-file "C:\path\to\tags" --name "MyClass"
```

## Output

JSON array of objects with: `Name`, `Kind`, `File`, `Line`, `Scope`. Empty results return `[]`.

## Architecture

- `scripts/parse-ctags.jq` — jq filter that parses tab-delimited ctags output into JSON objects.
- `scripts/lookup.sh` — Bash entry point. Builds rg pattern, pipes to jq.
- `scripts/lookup.cmd` — Windows CMD entry point. Same interface.
