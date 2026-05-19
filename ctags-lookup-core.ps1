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
    .PARAMETER Kind
        Filter by kind: c(lass), m(ethod), f(ield), p(roperty), i(nterface),
        n(amespace), e(numerator), g(enum), s(truct), E(vent), d(macro), t(typedef)
    .PARAMETER File
        Filter results to symbols in a specific file (substring match).
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TagsFile,
        [string]$Name,
        [string]$Prefix,
        [string]$Kind,
        [string]$File
    )

    if (-not (Test-Path $TagsFile)) {
        throw "Tags file not found: $TagsFile"
    }

    if (-not $Name -and -not $Prefix -and -not $Kind -and -not $File) {
        throw "Specify at least one of: -Name, -Prefix, -Kind, -File"
    }

    $kindMap = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $kindMap.Add("c", "class"); $kindMap.Add("m", "method"); $kindMap.Add("f", "field")
    $kindMap.Add("p", "property"); $kindMap.Add("i", "interface"); $kindMap.Add("n", "namespace")
    $kindMap.Add("e", "enumerator"); $kindMap.Add("g", "enum"); $kindMap.Add("s", "struct")
    $kindMap.Add("E", "event"); $kindMap.Add("d", "macro"); $kindMap.Add("t", "typedef")

    # Build rg pattern
    if ($Name) {
        $rgPattern = "^$([regex]::Escape($Name))`t"
    } elseif ($Prefix) {
        $rgPattern = "^$([regex]::Escape($Prefix))"
    } elseif ($Kind) {
        $rgPattern = "`t$([regex]::Escape($Kind))`t"
    } elseif ($File) {
        $rgPattern = [regex]::Escape($File)
    }

    # Run ripgrep
    $rawLines = & rg --no-filename --no-line-number -e $rgPattern $TagsFile 2>$null

    if (-not $rawLines) {
        return @()
    }

    # Parse matched lines
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($line in $rawLines) {
        if ($line.StartsWith("!_TAG")) { continue }

        $tabParts = $line.Split("`t")
        if ($tabParts.Count -lt 4) { continue }

        $tagName = $tabParts[0]
        $tagFile = $tabParts[1]
        $tagKind = $tabParts[3]

        # Post-filters for combined queries
        if ($Name -and $tagName -cne $Name) { continue }
        if ($Kind -and $tagKind -cne $Kind) { continue }
        if ($File -and $tagFile -notlike "*$File*") { continue }

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
