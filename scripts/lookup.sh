#!/usr/bin/env bash
# ctags-lookup using rg + jq
# Usage:
#   ./lookup.sh --name "Dispose"
#   ./lookup.sh --name "Dispose" --tags-file /path/to/tags

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
TAGS_FILE=""
NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            NAME="$2"; shift 2 ;;
        --tags-file)
            TAGS_FILE="$2"; shift 2 ;;
        *)
            echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Default tags file: same directory as this script
if [[ -z "$TAGS_FILE" ]]; then
    TAGS_FILE="$SCRIPT_DIR/tags"
fi

# Validation
if [[ -z "$NAME" ]]; then
    echo "Error: --name is required" >&2
    exit 1
fi

if [[ ! -f "$TAGS_FILE" ]]; then
    echo "Error: tags file not found: $TAGS_FILE" >&2
    exit 1
fi

if ! command -v rg &>/dev/null; then
    echo "Error: ripgrep (rg) not found on PATH." >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq not found on PATH." >&2
    exit 1
fi

# Build rg pattern — escape regex metacharacters in the name
ESCAPED=$(printf '%s' "$NAME" | sed 's/[][\\.^$*+?{}()|]/\\&/g')
RG_PATTERN="^${ESCAPED}\t"

# Run rg and pipe to jq
# rg exits 1 on no matches — that's fine, we'll get empty input to jq which produces []
export CTAGS_EXACT_NAME="${NAME}"

# Temporarily disable pipefail: rg exit 1 (no matches) is expected and jq handles empty input
set +o pipefail
rg --no-filename --no-line-number -e "$RG_PATTERN" "$TAGS_FILE" 2>/dev/null \
    | jq -nMRf "$SCRIPT_DIR/parse-ctags.jq"
set -o pipefail
