function Invoke-CtagsLookup {
    <#
    .SYNOPSIS
        Fast ctags symbol lookup using ripgrep.
    .DESCRIPTION
        Searches a ctags tags file using ripgrep for speed, returns parsed results as objects.
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

    if (-not (Test-Path $TagsFile)) {
        throw "Tags file not found: $TagsFile"
    }

    if (-not $Name -and -not $Prefix) {
        throw "Specify at least one of: -Name, -Prefix"
    }

    $kindMap = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $kindMap.Add("c", "class");
    $kindMap.Add("m", "method");
    $kindMap.Add("f", "field");
    $kindMap.Add("p", "property");
    $kindMap.Add("i", "interface");
    $kindMap.Add("n", "namespace");
    $kindMap.Add("e", "enumerator");
    $kindMap.Add("g", "enum");
    $kindMap.Add("s", "struct")
    $kindMap.Add("E", "event");
    $kindMap.Add("d", "macro");
    $kindMap.Add("t", "typedef")

    # Build rg pattern — symbol name is always ^<name>\t
    if ($Name) {
        $rgPattern = "^$([regex]::Escape($Name))`t"
    } elseif ($Prefix) {
        $rgPattern = "^$([regex]::Escape($Prefix))[^`t]*`t"
    }

    # Run ripgrep and parse results as they stream in
    $results = [System.Collections.Generic.List[object]]::new()

    & rg --no-filename --no-line-number -e $rgPattern $TagsFile 2>$null | ForEach-Object {
        if ($_.StartsWith("!_TAG")) { return }

        $tabParts = $_.Split("`t")
        if ($tabParts.Count -lt 4) { return }

        $tagName = $tabParts[0]
        $tagFile = $tabParts[1]
        $tagKind = $tabParts[3]

        # Post-filter for exact name match
        if ($Name -and $tagName -cne $Name) { return }

        $tagLine = ""
        $tagScope = ""
        for ($i = 4; $i -lt $tabParts.Count; $i++) {
            if ($tabParts[$i].StartsWith("line:")) { $tagLine = $tabParts[$i].Substring(5) }
            elseif ($tabParts[$i] -match "^(class|enum|interface|namespace|struct):") { $tagScope = $tabParts[$i] }
        }

        $results.Add([PSCustomObject]@{
            Name  = $tagName
            Kind  = if ($kindMap.ContainsKey($tagKind)) { $kindMap[$tagKind] } else { $tagKind }
            File  = $tagFile
            Line  = $tagLine
            Scope = $tagScope
        })
    }

    return ,$results.ToArray()
}
