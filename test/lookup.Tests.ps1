BeforeAll {
    . (Join-Path $PSScriptRoot ".." "scripts" "core.ps1")
    $Script:TestTagsFile = Join-Path $PSScriptRoot "tags"
}

Describe "Invoke-CtagsLookup" {

    Context "Input Validation" {

        It "Should throw when tags file does not exist" {
            { Invoke-CtagsLookup -TagsFile "C:\nonexistent\tags" -Name "Foo" } | Should -Throw "*Tags file not found*"
        }

        It "Should throw when no filter parameters are provided" {
            { Invoke-CtagsLookup -TagsFile $Script:TestTagsFile } | Should -Throw "*Specify at least one of*"
        }
    }

    Context "Exact Name Search" {

        It "Should find symbols by exact name" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose")
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object { $_.Name | Should -Be "Dispose" }
        }

        It "Should return empty for non-existent symbol" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ThisSymbolDoesNotExist12345")
            $results.Count | Should -Be 0
        }

        It "Should be case-sensitive for name matching" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "dispose")
            $results.Count | Should -Be 0
        }

        It "Should return multiple results for overloaded names" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose")
            $results.Count | Should -BeGreaterThan 1
        }
    }

    Context "Prefix Search" {

        It "Should find symbols starting with prefix" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "Dispose")
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object { $_.Name | Should -BeLike "Dispose*" }
        }

        It "Should find multiple symbols with common prefix" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "ACCEPT_")
            $results.Count | Should -BeGreaterThan 1
            $results | ForEach-Object { $_.Name | Should -BeLike "ACCEPT_*" }
        }

        It "Should return empty for non-matching prefix" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "ZZZNONEXISTENT")
            $results.Count | Should -Be 0
        }
    }

    Context "Output Structure" {

        It "Should return objects with all expected properties" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose")
            $props = $results[0].PSObject.Properties.Name
            $props | Should -Contain "Name"
            $props | Should -Contain "Kind"
            $props | Should -Contain "File"
            $props | Should -Contain "Line"
            $props | Should -Contain "Scope"
        }

        It "Should return an array type" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose")
            $results | Should -BeOfType [PSCustomObject]
        }
    }

    Context "Kind Mapping" {

        It "Should map kind codes to readable names" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose")
            $results[0].Kind | Should -Be "method"
        }

        It "Should map class kind" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ADAsyncWorkItem")
            ($results | Where-Object { $_.Kind -eq "class" }).Count | Should -BeGreaterThan 0
        }

        It "Should map field kind" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ACCEPT_NETBINDCHANGE")
            $results[0].Kind | Should -Be "field"
        }
    }

    Context "Line and Scope Parsing" {

        It "Should parse line numbers" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ACCEPT_NETBINDCHANGE")
            $results[0].Line | Should -Be "95"
        }

        It "Should parse class scope" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ACCEPT_NETBINDCHANGE")
            $results[0].Scope | Should -BeLike "class:*"
        }

        It "Should handle entries without scope" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "LinqToSqlShared")
            $noScope = $results | Where-Object { [string]::IsNullOrEmpty($_.Scope) }
            $noScope.Count | Should -BeGreaterThan 0
        }
    }

    Context "Metadata Lines" {

        It "Should not include metadata in results" {
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "!_TAG_FILE_FORMAT")
            $results.Count | Should -Be 0
        }
    }

    Context "Performance" {

        It "Should return results within 5 seconds" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $results = @(Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ToString")
            $stopwatch.Stop()
            $results.Count | Should -BeGreaterThan 0
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
        }
    }
}
