# parse-ctags.jq
# Reads raw rg output (one ctags line per input line), produces a JSON array of symbol objects.
# Usage: rg ... | jq -nRf parse-ctags.jq
#   or with name filter: rg ... | jq -nR --arg exactName "Dispose" -f parse-ctags.jq

def kind_map:
  {
    "c": "class",
    "m": "method",
    "f": "field",
    "p": "property",
    "i": "interface",
    "n": "namespace",
    "e": "enumerator",
    "g": "enum",
    "s": "struct",
    "E": "event",
    "d": "macro",
    "t": "typedef"
  };

[ inputs
  | select(startswith("!_TAG") | not)
  | split("\t")
  | select(length >= 4)
  | {
      name: .[0],
      file: .[1],
      kind_raw: .[3],
      ext: .[4:]
    }
  | select(
      if ($ENV.CTAGS_EXACT_NAME // "") != "" then
        .name == $ENV.CTAGS_EXACT_NAME
      else
        true
      end
    )
  | .line = (
      .ext | map(select(startswith("line:"))) | first // "" | ltrimstr("line:")
    )
  | .scope = (
      .ext | map(select(test("^(class|enum|interface|namespace|struct):"))) | first // ""
    )
  | {
      Name: .name,
      Kind: (kind_map[.kind_raw] // .kind_raw),
      File: .file,
      Line: .line,
      Scope: .scope
    }
]
