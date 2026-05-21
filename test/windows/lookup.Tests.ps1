BeforeAll {
    $Script:RepoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $Script:LookupCmd = Join-Path $Script:RepoRoot "scripts\lookup.cmd"
    $Script:TagsFile = Join-Path $Script:RepoRoot "test\dotnet-reference-source-tags"

    function Invoke-Lookup {
        param(
            [string[]]$Arguments
        )

        $allArgs = @("/c", $Script:LookupCmd) + $Arguments
        $output = & cmd.exe @allArgs 2>&1
        $exitCode = $LASTEXITCODE
        $json = ($output | Out-String).Trim()

        $results = @()
        if ($exitCode -eq 0 -and $json -and $json -ne '[]') {
            $results = @(ConvertFrom-Json -InputObject $json)
        }

        [PSCustomObject]@{
            ExitCode = $exitCode
            Json     = $json
            Results  = $results
        }
    }
}

Describe "lookup.cmd" {

    Context "Input Validation" {

        It "Should fail when no arguments are provided" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile)
            $result.ExitCode | Should -Not -Be 0
        }

        It "Should fail when both --name and --prefix are provided" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Foo", "--prefix", "Bar")
            $result.ExitCode | Should -Not -Be 0
        }

        It "Should fail when tags file does not exist" {
            $result = Invoke-Lookup -Arguments @("--tags-file", "C:\nonexistent\tags", "--name", "Foo")
            $result.ExitCode | Should -Not -Be 0
        }
    }

    Context "Exact Name Search" {

        It "Should find symbols by exact name" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Dispose")
            $result.ExitCode | Should -Be 0
            $result.Results.Count | Should -BeGreaterThan 0
            $result.Results | ForEach-Object { $_.Name | Should -Be "Dispose" }
        }

        It "Should return empty JSON array for non-existent symbol" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "ThisSymbolDoesNotExist12345")
            $result.ExitCode | Should -Be 0
            $result.Json | Should -Be "[]"
        }

        It "Should be case-sensitive" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "dispose")
            $result.ExitCode | Should -Be 0
            $result.Json | Should -Be "[]"
        }

        It "Should return multiple results for overloaded names" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Dispose")
            $result.Results.Count | Should -BeGreaterThan 1
        }
    }

    Context "Prefix Search" {

        It "Should find symbols starting with prefix" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--prefix", "Dispose")
            $result.ExitCode | Should -Be 0
            $result.Results.Count | Should -BeGreaterThan 0
            $result.Results | ForEach-Object { $_.Name | Should -BeLike "Dispose*" }
        }

        It "Should find multiple symbols with common prefix" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--prefix", "ACCEPT_")
            $result.Results.Count | Should -BeGreaterThan 1
            $result.Results | ForEach-Object { $_.Name | Should -BeLike "ACCEPT_*" }
        }

        It "Should return empty for non-matching prefix" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--prefix", "ZZZNONEXISTENT")
            $result.ExitCode | Should -Be 0
            $result.Json | Should -Be "[]"
        }
    }

    Context "Output Structure" {

        It "Should output valid JSON" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Dispose")
            { ConvertFrom-Json -InputObject $result.Json | Out-Null } | Should -Not -Throw
            $result.Json.TrimStart() | Should -BeLike '`[*'
            $result.Json.TrimEnd() | Should -BeLike '*`]'
        }

        It "Should return objects with all expected properties" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Dispose")
            $first = $result.Results[0]
            $first.PSObject.Properties.Name | Should -Contain "Name"
            $first.PSObject.Properties.Name | Should -Contain "Kind"
            $first.PSObject.Properties.Name | Should -Contain "File"
            $first.PSObject.Properties.Name | Should -Contain "Line"
            $first.PSObject.Properties.Name | Should -Contain "Scope"
        }
    }

    Context "Kind Mapping" {

        It "Should map 'm' to 'method'" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "Dispose")
            ($result.Results | Where-Object { $_.Kind -eq "method" }).Count | Should -BeGreaterThan 0
        }

        It "Should map 'c' to 'class'" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "ADAsyncWorkItem")
            ($result.Results | Where-Object { $_.Kind -eq "class" }).Count | Should -BeGreaterThan 0
        }

        It "Should map 'f' to 'field'" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "ACCEPT_NETBINDCHANGE")
            $result.Results[0].Kind | Should -Be "field"
        }
    }

    Context "Line and Scope Parsing" {

        It "Should parse line numbers" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "ACCEPT_NETBINDCHANGE")
            $result.Results[0].Line | Should -Be "95"
        }

        It "Should parse class scope" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "ACCEPT_NETBINDCHANGE")
            $result.Results[0].Scope | Should -BeLike "class:*"
        }

        It "Should handle entries without scope" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--prefix", "LinqToSqlShared")
            $noScope = $result.Results | Where-Object { [string]::IsNullOrEmpty($_.Scope) }
            $noScope.Count | Should -BeGreaterThan 0
        }
    }

    Context "Metadata Lines" {

        It "Should not include ctags metadata in results" {
            $result = Invoke-Lookup -Arguments @("--tags-file", $Script:TagsFile, "--name", "!_TAG_FILE_FORMAT")
            $result.Results.Count | Should -Be 0
        }
    }
}
