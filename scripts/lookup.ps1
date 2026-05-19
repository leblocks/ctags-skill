<#
.SYNOPSIS
    Fast ctags symbol lookup using ripgrep.

.DESCRIPTION
    CLI wrapper around Invoke-CtagsLookup. Outputs JSON.

.EXAMPLE
    .\lookup.ps1 -Name "Dispose"
    .\lookup.ps1 -Prefix "Get"
#>

param(
    [string]$TagsFile,
    [string]$Name,
    [string]$Prefix,
    [string]$Pattern
)

. (Join-Path $PSScriptRoot "core.ps1")

if (-not $TagsFile) {
    $TagsFile = Join-Path $PSScriptRoot "tags"
}

try {
    $results = Invoke-CtagsLookup -TagsFile $TagsFile -Name $Name -Prefix $Prefix -Pattern $Pattern
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

if ($results.Count -eq 0) {
    Write-Host "[]"
} else {
    ConvertTo-Json -InputObject @($results) -Compress
}
