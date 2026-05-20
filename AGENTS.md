# ctags-lookup

Fast symbol lookup in Universal Ctags `tags` files using ripgrep. Use when navigating large codebases, finding symbol definitions, or resolving symbol locations.

## Quick Start

Requires `rg` (ripgrep) on PATH and a tags file generated with:
```
ctags -R --fields=+lKn --extras=+f -o tags .
```

## Commands

```powershell
# Exact name lookup
./scripts/lookup.ps1 -Name "SymbolName"

# Prefix search
./scripts/lookup.ps1 -Prefix "Get"

# Specify tags file location
./scripts/lookup.ps1 -TagsFile "/path/to/tags" -Name "MyClass"
```

## Output

JSON array of objects with: `Name`, `Kind`, `File`, `Line`, `Scope`. Empty results return `[]`.

## Architecture

- `scripts/core.ps1` — `Invoke-CtagsLookup` function. Streams parsed results to the pipeline.
- `scripts/lookup.ps1` — CLI entry point. Outputs JSON.

## Testing

```powershell
Invoke-Pester ./test/ctags-lookup.Tests.ps1
```
