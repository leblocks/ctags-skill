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
    [string]$Prefix
)

$coreScriptPath = Join-Path $PSScriptRoot "core.ps1"
try {
    . $coreScriptPath
} catch {
    Write-Error "Failed to load core lookup script '$coreScriptPath': $($_.Exception.Message)"
    exit 1
}

if (-not $TagsFile) {
    $TagsFile = Join-Path $PSScriptRoot "tags"
}

try {
    $results = @(Invoke-CtagsLookup -TagsFile $TagsFile -Name $Name -Prefix $Prefix)
} catch {
    Write-Error "ctags lookup failed: $($_.Exception.Message)"
    exit 1
}

if ($results.Count -eq 0) {
    Write-Output "[]"
} else {
    ConvertTo-Json -InputObject @($results) -Compress
}
