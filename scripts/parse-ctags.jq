# parse-ctags.jq
# Reads raw rg output (one ctags line per input line), produces a JSON array of symbol objects.
# Usage: rg ... | jq -nMRf parse-ctags.jq
#
# ctags format: {name}\t{file}\t{pattern};"\t{kind}\t{ext_fields...}
# The pattern field may contain tabs (from source code), so we find the `;"` terminator
# to locate the kind field reliably.

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

# Find the index of the field ending with ;" (end of pattern/address field)
def find_pattern_end:
  . as $fields |
  [range(2; $fields | length) | select($fields[.] | endswith(";\""))] |
  first // 2;

[ inputs
  | select(startswith("!_TAG") | not)
  | split("\t")
  | select(length >= 4)
  | . as $fields
  | find_pattern_end as $pat_end
  | {
      name: $fields[0],
      file: $fields[1],
      kind_raw: $fields[$pat_end + 1],
      ext: $fields[$pat_end + 2:]
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
