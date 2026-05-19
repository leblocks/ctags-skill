<#
.SYNOPSIS
    Fast ctags symbol lookup using ripgrep.

.DESCRIPTION
    CLI wrapper around Invoke-CtagsLookup. Outputs JSON.

.EXAMPLE
    .\ctags-lookup.ps1 -Name "Dispose"
    .\ctags-lookup.ps1 -Prefix "Get" -Kind m
    .\ctags-lookup.ps1 -Kind c -File "mscorlib"
#>

param(
    [string]$TagsFile,
    [string]$Name,
    [string]$Prefix,
    [string]$Kind,
    [string]$File
)

. (Join-Path $PSScriptRoot "ctags-lookup-core.ps1")

if (-not $TagsFile) {
    $TagsFile = Join-Path $PSScriptRoot "tags"
}

try {
    $results = Invoke-CtagsLookup -TagsFile $TagsFile -Name $Name -Prefix $Prefix -Kind $Kind -File $File
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

if ($results.Count -eq 0) {
    Write-Host "[]"
} else {
    ConvertTo-Json -InputObject @($results) -Compress
}
