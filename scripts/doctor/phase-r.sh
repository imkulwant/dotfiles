#!/usr/bin/env bash
# Phase R — Lifecycle (install + uninstall + features index)
phase_start "R" "Lifecycle"
SOURCE="$CHEZMOI_SOURCE"

check "scripts/macos-defaults-keys.txt exists"
assert_file "$SOURCE/scripts/macos-defaults-keys.txt"

check "macos_defaults script reads keys from file"
assert_grep 'macos-defaults-keys\.txt' "$SOURCE/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"

check "install.sh exists, executable, set -euo pipefail"
assert_file "$SOURCE/scripts/install.sh"
assert_perm "$SOURCE/scripts/install.sh" 755
assert_grep 'set -euo pipefail' "$SOURCE/scripts/install.sh"

check "justfile has install recipe"
assert_grep '^install:' "$SOURCE/justfile"

check "install.sh is idempotent on existing install (Review Focus #1)"
assert_grep 'if \[ -d.*\.local/share/chezmoi.*\]' "$SOURCE/scripts/install.sh"
assert_grep 'chezmoi apply' "$SOURCE/scripts/install.sh"

check "uninstall.sh exists, executable, set -euo pipefail"
assert_file "$SOURCE/scripts/uninstall.sh"
assert_perm "$SOURCE/scripts/uninstall.sh" 755
assert_grep 'set -euo pipefail' "$SOURCE/scripts/uninstall.sh"

check "justfile has uninstall recipe"
assert_grep '^uninstall ' "$SOURCE/justfile"

check "uninstall --dry-run prints all 10 step markers"
assert_cmd_out "$SOURCE/scripts/uninstall.sh --dry-run --yes" 'step 1 of 10'
assert_cmd_out "$SOURCE/scripts/uninstall.sh --dry-run --yes" 'step 10 of 10'

check "uninstall tolerates missing atuin DB under --purge-data (Review Focus #2)"
assert_cmd_ok "$SOURCE/scripts/uninstall.sh --dry-run --yes --purge-data"

check "docs/features.md exists"
assert_file "$SOURCE/docs/features.md"

check "features.md names every Brewfile formula"
_missing_formulae=()
while IFS= read -r line; do
  formula=$(printf '%s' "$line" | sed -E 's/^brew "([^"]+)".*/\1/')
  [[ -z "$formula" ]] && continue
  grep -qF "$formula" "$SOURCE/docs/features.md" || _missing_formulae+=("$formula")
done < <(grep '^brew "' "$SOURCE/Brewfile")
if [[ ${#_missing_formulae[@]} -eq 0 ]]; then pass; else fail "unlisted: ${_missing_formulae[*]}"; fi

check "features.md references every macos-defaults key"
_missing_keys=()
while read -r _domain key _type _value; do
  [[ -z "$_domain" || "$_domain" =~ ^# ]] && continue
  grep -qF "$key" "$SOURCE/docs/features.md" || _missing_keys+=("$_domain.$key")
done <"$SOURCE/scripts/macos-defaults-keys.txt"
if [[ ${#_missing_keys[@]} -eq 0 ]]; then pass; else fail "unlisted: ${_missing_keys[*]}"; fi
