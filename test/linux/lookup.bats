#!/usr/bin/env bats

LOOKUP="./scripts/lookup.sh"
TAGS="./test/dotnet-reference-source-tags"

# --- Input Validation ---

@test "fails when no arguments are provided" {
    run "$LOOKUP" --tags-file "$TAGS"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--name"* ]]
}

@test "fails when both --name and unknown arg are provided" {
    run "$LOOKUP" --tags-file "$TAGS" --prefix "Bar"
    [ "$status" -ne 0 ]
}

@test "fails when tags file does not exist" {
    run "$LOOKUP" --tags-file "/nonexistent/tags" --name "Foo"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "fails when rg is not on PATH" {
    # Provide bash but not rg/jq
    local tmpdir
    tmpdir=$(mktemp -d)
    ln -s /bin/bash "$tmpdir/bash"
    ln -s /usr/bin/env "$tmpdir/env"
    run env PATH="$tmpdir" "$LOOKUP" --tags-file "$TAGS" --name "Foo"
    rm -rf "$tmpdir"
    [ "$status" -ne 0 ]
    [[ "$output" == *"rg"* ]]
}

@test "fails when jq is not on PATH" {
    # Provide bash and rg but not jq
    local tmpdir
    tmpdir=$(mktemp -d)
    ln -s /bin/bash "$tmpdir/bash"
    ln -s /usr/bin/env "$tmpdir/env"
    ln -s /usr/bin/rg "$tmpdir/rg"
    run env PATH="$tmpdir" "$LOOKUP" --tags-file "$TAGS" --name "Foo"
    rm -rf "$tmpdir"
    [ "$status" -ne 0 ]
    [[ "$output" == *"jq"* ]]
}

# --- Exact Name Search ---

@test "finds symbols by exact name" {
    run "$LOOKUP" --tags-file "$TAGS" --name "Dispose"
    [ "$status" -eq 0 ]
    count=$(echo "$output" | jq 'length')
    [ "$count" -gt 0 ]
    # All results should have Name == "Dispose"
    mismatches=$(echo "$output" | jq '[.[] | select(.Name != "Dispose")] | length')
    [ "$mismatches" -eq 0 ]
}

@test "returns empty array for non-existent symbol" {
    run "$LOOKUP" --tags-file "$TAGS" --name "ThisSymbolDoesNotExist12345"
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "exact name search is case-sensitive" {
    run "$LOOKUP" --tags-file "$TAGS" --name "dispose"
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "returns multiple results for overloaded names" {
    run "$LOOKUP" --tags-file "$TAGS" --name "Dispose"
    [ "$status" -eq 0 ]
    count=$(echo "$output" | jq 'length')
    [ "$count" -gt 1 ]
}

# --- Prefix Search (removed) ---

@test "rejects --prefix as unknown argument" {
    run "$LOOKUP" --tags-file "$TAGS" --prefix "Dispose"
    [ "$status" -ne 0 ]
}

# --- Output Structure ---

@test "outputs valid JSON array" {
    run "$LOOKUP" --tags-file "$TAGS" --name "Dispose"
    [ "$status" -eq 0 ]
    echo "$output" | jq empty
    type=$(echo "$output" | jq 'type')
    [ "$type" = '"array"' ]
}

@test "returns objects with all expected properties" {
    run "$LOOKUP" --tags-file "$TAGS" --name "Dispose"
    [ "$status" -eq 0 ]
    first=$(echo "$output" | jq '.[0]')
    [ "$(echo "$first" | jq 'has("Name")')" = "true" ]
    [ "$(echo "$first" | jq 'has("Kind")')" = "true" ]
    [ "$(echo "$first" | jq 'has("File")')" = "true" ]
    [ "$(echo "$first" | jq 'has("Line")')" = "true" ]
    [ "$(echo "$first" | jq 'has("Scope")')" = "true" ]
}

# --- Kind Mapping ---

@test "maps 'm' to 'method'" {
    run "$LOOKUP" --tags-file "$TAGS" --name "Dispose"
    [ "$status" -eq 0 ]
    methods=$(echo "$output" | jq '[.[] | select(.Kind == "method")] | length')
    [ "$methods" -gt 0 ]
}

@test "maps 'c' to 'class'" {
    run "$LOOKUP" --tags-file "$TAGS" --name "ADAsyncWorkItem"
    [ "$status" -eq 0 ]
    classes=$(echo "$output" | jq '[.[] | select(.Kind == "class")] | length')
    [ "$classes" -gt 0 ]
}

@test "maps 'f' to 'field'" {
    run "$LOOKUP" --tags-file "$TAGS" --name "ACCEPT_NETBINDCHANGE"
    [ "$status" -eq 0 ]
    kind=$(echo "$output" | jq -r '.[0].Kind')
    [ "$kind" = "field" ]
}

# --- Line and Scope Parsing ---

@test "parses line numbers" {
    run "$LOOKUP" --tags-file "$TAGS" --name "ACCEPT_NETBINDCHANGE"
    [ "$status" -eq 0 ]
    line=$(echo "$output" | jq -r '.[0].Line')
    [ "$line" = "95" ]
}

@test "parses class scope" {
    run "$LOOKUP" --tags-file "$TAGS" --name "ACCEPT_NETBINDCHANGE"
    [ "$status" -eq 0 ]
    scope=$(echo "$output" | jq -r '.[0].Scope')
    [[ "$scope" == class:* ]]
}

@test "handles entries without scope" {
    run "$LOOKUP" --tags-file "$TAGS" --name "LinqToSqlShared.Mapping"
    [ "$status" -eq 0 ]
    empty_scopes=$(echo "$output" | jq '[.[] | select(.Scope == "")] | length')
    [ "$empty_scopes" -gt 0 ]
}

# --- Metadata Lines ---

@test "does not include ctags metadata in results" {
    run "$LOOKUP" --tags-file "$TAGS" --name "!_TAG_FILE_FORMAT"
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}
