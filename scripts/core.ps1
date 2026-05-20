function Invoke-CtagsLookup {
    <#
    .SYNOPSIS
        Fast ctags symbol lookup using ripgrep.
    .DESCRIPTION
        Searches a ctags tags file using ripgrep for speed, emits parsed results as objects to the pipeline.
    .PARAMETER TagsFile
        Path to the tags file.
    .PARAMETER Name
        Symbol name to search for (exact match).
    .PARAMETER Prefix
        Search symbols starting with this prefix.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TagsFile,
        [string]$Name,
        [string]$Prefix
    )

    if ([string]::IsNullOrWhiteSpace($TagsFile)) {
        throw "Tags file path must not be empty."
    }

    if (-not (Test-Path -LiteralPath $TagsFile -PathType Leaf)) {
        throw "Tags file not found: $TagsFile"
    }

    if ($Name -and $Prefix) {
        throw "Specify either -Name or -Prefix, not both."
    }

    if (-not $Name -and -not $Prefix) {
        throw "Specify at least one of: -Name, -Prefix"
    }

    $ripgrepCommand = Get-Command -Name "rg" -CommandType Application -ErrorAction SilentlyContinue
    if (-not $ripgrepCommand) {
        throw "ripgrep executable 'rg' was not found on PATH. Install ripgrep and ensure 'rg' is available before running ctags lookup."
    }

    $minimumTagFieldCount = 4
    $tagNameIndex = 0
    $tagFileIndex = 1
    $tagKindIndex = 3
    $extensionFieldsStartIndex = 4
    $lineFieldPrefix = "line:"
    $tagFieldSeparator = "`t"
    $scopePattern = "^(class|enum|interface|namespace|struct):"

    $kindMap = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $kindMap.Add("c", "class")
    $kindMap.Add("m", "method")
    $kindMap.Add("f", "field")
    $kindMap.Add("p", "property")
    $kindMap.Add("i", "interface")
    $kindMap.Add("n", "namespace")
    $kindMap.Add("e", "enumerator")
    $kindMap.Add("g", "enum")
    $kindMap.Add("s", "struct")
    $kindMap.Add("E", "event")
    $kindMap.Add("d", "macro")
    $kindMap.Add("t", "typedef")

    # Build rg pattern — symbol name is always ^<name>\t
    if ($Name) {
        $rgPattern = "^$([regex]::Escape($Name))`t"
    } else {
        $rgPattern = "^$([regex]::Escape($Prefix))[^`t]*`t"
    }

    # ripgrep returns 1 when there are no matches, which is expected for empty results.
    & $ripgrepCommand.Source --no-filename --no-line-number -e $rgPattern $TagsFile 2>$null | ForEach-Object {
        if ($_.StartsWith("!_TAG")) { return }

        $tabParts = $_.Split($tagFieldSeparator)
        if ($tabParts.Count -lt $minimumTagFieldCount) { return }

        $tagName = $tabParts[$tagNameIndex]
        $tagFile = $tabParts[$tagFileIndex]
        $tagKind = $tabParts[$tagKindIndex]

        # Post-filter for exact name match
        if ($Name -and $tagName -cne $Name) { return }

        $tagLine = ""
        $tagScope = ""
        for ($i = $extensionFieldsStartIndex; $i -lt $tabParts.Count; $i++) {
            if ($tabParts[$i].StartsWith($lineFieldPrefix)) {
                $tagLine = $tabParts[$i].Substring($lineFieldPrefix.Length)
            } elseif ($tabParts[$i] -match $scopePattern) {
                $tagScope = $tabParts[$i]
            }
        }

        [PSCustomObject]@{
            Name  = $tagName
            Kind  = if ($kindMap.ContainsKey($tagKind)) { $kindMap[$tagKind] } else { $tagKind }
            File  = $tagFile
            Line  = $tagLine
            Scope = $tagScope
        }
    }

    if ($LASTEXITCODE -gt 1) {
        throw "ripgrep failed while reading tags file '$TagsFile' (exit code $LASTEXITCODE)."
    }
}
