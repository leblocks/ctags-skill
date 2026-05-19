BeforeAll {
    . (Join-Path $PSScriptRoot ".." "ctags-lookup-core.ps1")
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
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose"
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object { $_.Name | Should -Be "Dispose" }
        }

        It "Should return empty for non-existent symbol" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ThisSymbolDoesNotExist12345"
            $results.Count | Should -Be 0
        }

        It "Should be case-sensitive for name matching" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "dispose"
            $results.Count | Should -Be 0
        }

        It "Should return multiple results for overloaded names" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose"
            $results.Count | Should -BeGreaterThan 1
        }
    }

    Context "Prefix Search" {

        It "Should find symbols starting with prefix" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "Dispose"
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object { $_.Name | Should -BeLike "Dispose*" }
        }

        It "Should find multiple symbols with common prefix" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "ACCEPT_"
            $results.Count | Should -BeGreaterThan 1
            $results | ForEach-Object { $_.Name | Should -BeLike "ACCEPT_*" }
        }

        It "Should return empty for non-matching prefix" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "ZZZNONEXISTENT"
            $results.Count | Should -Be 0
        }

        It "Should combine prefix with kind filter" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Prefix "Get" -Kind m
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object {
                $_.Name | Should -BeLike "Get*"
                $_.Kind | Should -Be "method"
            }
        }
    }

    Context "Kind Filter" {

        It "Should filter by class kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind c
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "class" }
        }

        It "Should filter by method kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind m
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "method" }
        }

        It "Should filter by field kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind f
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "field" }
        }

        It "Should filter by property kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind p
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "property" }
        }

        It "Should filter by interface kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind i
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "interface" }
        }

        It "Should filter by namespace kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind n
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "namespace" }
        }

        It "Should filter by enumerator kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind e
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "enumerator" }
        }

        It "Should filter by enum kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind g
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "enum" }
        }

        It "Should filter by struct kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind s
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "struct" }
        }

        It "Should filter by typedef kind" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind t
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.Kind | Should -Be "typedef" }
        }

        It "Should be case-sensitive for kind (e vs E)" {
            $resultsLower = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind e
            $resultsLower | Select-Object -First 5 | ForEach-Object { $_.Kind | Should -Be "enumerator" }
            $resultsUpper = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind E
            $resultsUpper | ForEach-Object { $_.Kind | Should -Be "event" }
        }
    }

    Context "File Filter" {

        It "Should filter results by file path substring" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -File "mscorlib"
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object { $_.File | Should -BeLike "*mscorlib*" }
        }

        It "Should combine file and kind filters" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind c -File "mscorlib"
            $results.Count | Should -BeGreaterThan 0
            $results | Select-Object -First 10 | ForEach-Object {
                $_.Kind | Should -Be "class"
                $_.File | Should -BeLike "*mscorlib*"
            }
        }

        It "Should return empty for non-matching file" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind c -File "NonExistentProject99999"
            $results.Count | Should -Be 0
        }
    }

    Context "Combined Filters" {

        It "Should combine Name and Kind filters" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose" -Kind m
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object {
                $_.Name | Should -Be "Dispose"
                $_.Kind | Should -Be "method"
            }
        }

        It "Should return empty when combined filters exclude everything" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose" -Kind c
            $results.Count | Should -Be 0
        }

        It "Should combine Name and File filters" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose" -File "mscorlib"
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object {
                $_.Name | Should -Be "Dispose"
                $_.File | Should -BeLike "*mscorlib*"
            }
        }
    }

    Context "Output Structure" {

        It "Should return objects with all expected properties" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose"
            $props = $results[0].PSObject.Properties.Name
            $props | Should -Contain "Name"
            $props | Should -Contain "Kind"
            $props | Should -Contain "File"
            $props | Should -Contain "Line"
            $props | Should -Contain "Scope"
        }

        It "Should return an array type" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "Dispose"
            $results | Should -BeOfType [PSCustomObject]
        }
    }

    Context "Kind Mapping" {

        It "Should map 'c' to 'class'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind c
            $results[0].Kind | Should -Be "class"
        }

        It "Should map 'm' to 'method'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind m
            $results[0].Kind | Should -Be "method"
        }

        It "Should map 'f' to 'field'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind f
            $results[0].Kind | Should -Be "field"
        }

        It "Should map 'p' to 'property'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind p
            $results[0].Kind | Should -Be "property"
        }

        It "Should map 'i' to 'interface'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind i
            $results[0].Kind | Should -Be "interface"
        }

        It "Should map 'n' to 'namespace'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind n
            $results[0].Kind | Should -Be "namespace"
        }

        It "Should map 'e' to 'enumerator'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind e
            $results[0].Kind | Should -Be "enumerator"
        }

        It "Should map 'g' to 'enum'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind g
            $results[0].Kind | Should -Be "enum"
        }

        It "Should map 's' to 'struct'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind s
            $results[0].Kind | Should -Be "struct"
        }

        It "Should map 't' to 'typedef'" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind t
            $results[0].Kind | Should -Be "typedef"
        }
    }

    Context "Line and Scope Parsing" {

        It "Should parse line numbers" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ACCEPT_NETBINDCHANGE"
            $results.Count | Should -BeGreaterThan 0
            $results[0].Line | Should -Be "95"
        }

        It "Should parse class scope" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ACCEPT_NETBINDCHANGE"
            $results[0].Scope | Should -BeLike "class:*"
        }

        It "Should parse namespace scope" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind g
            $withScope = $results | Where-Object { $_.Scope -like "*namespace:*" } | Select-Object -First 1
            $withScope | Should -Not -BeNullOrEmpty
        }

        It "Should handle entries without scope" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Kind n
            $noScope = $results | Where-Object { [string]::IsNullOrEmpty($_.Scope) } | Select-Object -First 1
            $noScope | Should -Not -BeNullOrEmpty
        }
    }

    Context "Metadata Lines" {

        It "Should not include metadata in results" {
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "!_TAG_FILE_FORMAT"
            $results.Count | Should -Be 0
        }
    }

    Context "Performance" {

        It "Should return results within 5 seconds" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-CtagsLookup -TagsFile $Script:TestTagsFile -Name "ToString"
            $stopwatch.Stop()
            $results.Count | Should -BeGreaterThan 0
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
        }
    }
}
