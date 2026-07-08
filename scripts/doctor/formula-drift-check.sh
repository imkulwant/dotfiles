#!/usr/bin/env bash
# Check that every /opt/homebrew/opt/<formula> reference in tracked source files
# corresponds to a formula declared in the Brewfile.
# Exits 0 if clean, 1 if undeclared formula references are found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BREWFILE="$SOURCE_DIR/Brewfile"

if [ ! -f "$BREWFILE" ]; then
  echo "ERROR: Brewfile not found at $BREWFILE" >&2
  exit 1
fi

# Collect all /opt/homebrew/opt/<formula> references across source files.
# Exclude the Brewfile itself and binary/generated files.
refs=$(
  grep -r \
    --include="*.json" --include="*.yaml" --include="*.yml" \
    --include="*.toml" --include="*.tmpl" --include="*.zsh" \
    --include="*.conf" \
    --exclude-dir=scripts \
    --exclude="*.md" \
    -hE '/opt/homebrew/opt/[^/"[:space:]]+' "$SOURCE_DIR" 2>/dev/null |
    grep -oE '/opt/homebrew/opt/[^/"[:space:]]+' |
    sed 's|/opt/homebrew/opt/||' |
    sort -u || true
)

if [ -z "$refs" ]; then
  echo "No /opt/homebrew/opt/<formula> references found."
  exit 0
fi

drift=0
while IFS= read -r formula; do
  # Check if the formula is declared in the Brewfile (exact match on the name part)
  if ! grep -qE "^brew \"$formula\"" "$BREWFILE"; then
    echo "DRIFT: '$formula' referenced in source but not declared in Brewfile"
    drift=1
  fi
done <<<"$refs"

if [ "$drift" -eq 0 ]; then
  echo "OK: all formula references match Brewfile declarations"
fi

exit "$drift"
