BeforeAll {
    $Script:RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $Script:LookupScript = Join-Path $Script:RepoRoot "scripts\lookup.ps1"
    $Script:TestTagsFile = Join-Path $PSScriptRoot "tags"
    $Script:PowerShellExe = (Get-Command -Name "powershell.exe" -CommandType Application).Source
    $Script:CreatedFixtureRoots = New-Object 'System.Collections.Generic.List[string]'

    function Convert-LookupJsonToArray {
        param(
            [Parameter(Mandatory)]
            [string]$Json
        )

        if ([string]::IsNullOrWhiteSpace($Json) -or $Json -eq '[]') {
            return @()
        }

        $parsed = ConvertFrom-Json -InputObject $Json
        if ($null -eq $parsed) {
            return @()
        }

        return @($parsed)
    }

    function Invoke-LookupCli {
        param(
            [string]$Name,
            [string]$Prefix
        )

        $arguments = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $Script:LookupScript,
            '-TagsFile', $Script:TestTagsFile
        )

        if ($PSBoundParameters.ContainsKey('Name')) {
            $arguments += @('-Name', $Name)
        }

        if ($PSBoundParameters.ContainsKey('Prefix')) {
            $arguments += @('-Prefix', $Prefix)
        }

        $output = & $Script:PowerShellExe @arguments 2>&1
        $exitCode = $LASTEXITCODE
        $json = ($output | Out-String).Trim()

        [PSCustomObject]@{
            ExitCode = $exitCode
            Json     = $json
            Results  = if ($exitCode -eq 0) { Convert-LookupJsonToArray -Json $json } else { @() }
        }
    }
}

Describe 'ctags lookup agent evaluations' {
    Context 'Scenario: Agent needs to find a class definition' {
        It 'returns the ADAsyncWorkItem class with a resolvable source file path' {
            $lookup = Invoke-LookupCli -Name 'ADAsyncWorkItem'

            $lookup.ExitCode | Should -Be 0
            $classDefinition = $lookup.Results | Where-Object {
                $_.Name -eq 'ADAsyncWorkItem' -and $_.Kind -eq 'class'
            } | Select-Object -First 1

            $classDefinition | Should -Not -BeNullOrEmpty
            $classDefinition.Line | Should -Match '^\d+$'
            $classDefinition.Scope | Should -BeLike 'namespace:*'
        }
    }

    Context 'Scenario: Agent needs to discover API surface' {
        It 'returns a broad Get* surface with diverse kinds and scopes' {
            $lookup = Invoke-LookupCli -Prefix 'Get'

            $lookup.ExitCode | Should -Be 0
            $lookup.Results.Count | Should -BeGreaterThan 25
            $lookup.Results
                | ForEach-Object { $_.Name.StartsWith('Get') }
                | Where-Object { -not $_ }
                | Should -BeNullOrEmpty

            $kinds = @($lookup.Results | Select-Object -ExpandProperty Kind -Unique)
            $scopes = @(
                $lookup.Results |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_.Scope) } |
                    Select-Object -ExpandProperty Scope -Unique
            )

            $kinds | Should -Contain 'method'
            $kinds.Count | Should -BeGreaterThan 1
            $scopes.Count | Should -BeGreaterThan 10
            ($scopes | Where-Object { $_ -like 'class:*' }).Count | Should -BeGreaterThan 0
            ($scopes | Where-Object { $_ -like 'enum:*' }).Count | Should -BeGreaterThan 0
        }
    }

    Context 'Scenario: Agent needs to resolve ambiguity' {
        It 'returns all Dispose definitions across different scopes' {
            $lookup = Invoke-LookupCli -Name 'Dispose'

            $lookup.ExitCode | Should -Be 0
            $lookup.Results.Count | Should -BeGreaterThan 10
            ($lookup.Results | Select-Object -ExpandProperty Name -Unique) | Should -Be @('Dispose')

            $uniqueScopes = @(
                $lookup.Results |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_.Scope) } |
                    Select-Object -ExpandProperty Scope -Unique
            )
            $scopeKinds = @($uniqueScopes | ForEach-Object { ($_ -split ':', 2)[0] } | Select-Object -Unique)

            $uniqueScopes.Count | Should -BeGreaterThan 5
            $scopeKinds.Count | Should -BeGreaterThan 1
            $scopeKinds | Should -Contain 'class'
            $scopeKinds | Should -Contain 'struct'
        }
    }

    Context 'Scenario: Agent handles missing symbol gracefully' {
        It 'returns an empty JSON array for a missing symbol without failing' {
            $lookup = Invoke-LookupCli -Name 'ThisSymbolDoesNotExist12345'

            $lookup.ExitCode | Should -Be 0
            $lookup.Json | Should -Be '[]'
            $lookup.Results | Should -BeNullOrEmpty
        }
    }

    Context 'Scenario: End-to-end JSON output' {
        It 'emits valid parseable JSON from lookup.ps1 for agent consumption' {
            $lookup = Invoke-LookupCli -Name 'Dispose'

            $lookup.ExitCode | Should -Be 0
            $lookup.Json | Should -Match '^\[.*\]$'
            { ConvertFrom-Json -InputObject $lookup.Json | Out-Null } | Should -Not -Throw

            $firstResult = $lookup.Results | Select-Object -First 1
            $firstResult | Should -Not -BeNullOrEmpty
            $firstResult.PSObject.Properties.Name | Should -Contain 'Name'
            $firstResult.PSObject.Properties.Name | Should -Contain 'Kind'
            $firstResult.PSObject.Properties.Name | Should -Contain 'File'
            $firstResult.PSObject.Properties.Name | Should -Contain 'Line'
            $firstResult.PSObject.Properties.Name | Should -Contain 'Scope'
        }
    }
}
