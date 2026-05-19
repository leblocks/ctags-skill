# ctags-skill

Fast symbol lookup scripts for navigating large codebases using Universal Ctags `tags` files.
Outputs JSON for easy consumption by CLI tools and AI agents.

## Setup

1. Generate a tags file with [Universal Ctags](https://ctags.io/):
   ```
   ctags -R --fields=+lKn --extras=+f -o tags .
   ```
2. Place the `tags` file in this directory (or specify path with `-TagsFile`).

## Usage

```powershell
# Exact symbol name
.\ctags-lookup.ps1 -Name "AccessToken"

# Prefix search
.\ctags-lookup.ps1 -Prefix "Power" -Kind m

# Filter by file
.\ctags-lookup.ps1 -Kind c -File "Commands.Admin"

# Filter by scope (class/interface/enum)
.\ctags-lookup.ps1 -Name "Dispose" -Scope "PowerBIApiClient"

# Increase result limit
.\ctags-lookup.ps1 -Kind m -Limit 100
```

## Output Format

Results are returned as a JSON array:
```json
[
  {
    "Name": "AccessToken",
    "Kind": "p",
    "File": "src/Common/Common.Authentication/PowerBIAccessToken.cs",
    "Line": "13",
    "Scope": "class:Microsoft.PowerBI.Common.Authentication.PowerBIAccessToken"
  }
]
```

Empty results return `[]`.

## Kind Codes

| Code | Meaning     |
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

## Filter Options

| Option     | Description                              |
|------------|------------------------------------------|
| `-Name`    | Exact symbol name match                  |
| `-Prefix`  | Symbol name starts with...               |
| `-Kind`    | Filter by kind code (see table above)    |
| `-File`    | Substring match on file path             |
| `-Scope`   | Substring match on scope (class/enum...) |
