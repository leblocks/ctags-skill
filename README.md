# ctags-skill

Fast symbol lookup for navigating large codebases using Universal Ctags `tags` files.
Powered by [ripgrep](https://github.com/BurntSushi/ripgrep) for speed. Outputs JSON.

## Prerequisites

- **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`) — required, used for fast file searching
- **[Universal Ctags](https://ctags.io/)** — needed to generate the `tags` file

## Setup

1. Generate a tags file:
   ```
   ctags -R --fields=+lKn --extras=+f -o tags .
   ```
2. Place the `tags` file in the project root (or specify path with `-TagsFile`).

## Usage

### CLI (`scripts/lookup.ps1`)

```powershell
# Exact symbol name
.\scripts\lookup.ps1 -Name "Dispose"

# Prefix search
.\scripts\lookup.ps1 -Prefix "Get"

# Custom tags file path
.\scripts\lookup.ps1 -TagsFile "C:\myproject\tags" -Name "MyClass"
```

### As a function (`scripts/core.ps1`)

```powershell
. .\scripts\core.ps1

$results = Invoke-CtagsLookup -TagsFile .\tags -Name "Dispose"
$results = Invoke-CtagsLookup -TagsFile .\tags -Prefix "Get"

# Filter results in PowerShell
$results | Where-Object { $_.Kind -eq "method" }
$results | Where-Object { $_.File -like "*mscorlib*" }
```

## Output Format

JSON array of objects:
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

## Kind Mapping

| Code | Output      |
|------|-------------|
| c    | class       |
| m    | method      |
| f    | field       |
| p    | property    |
| i    | interface   |
| n    | namespace   |
| e    | enumerator  |
| g    | enum        |
| s    | struct      |
| E    | event       |
| d    | macro       |
| t    | typedef     |

## Testing

```powershell
Invoke-Pester .\test\ctags-lookup.Tests.ps1
```
