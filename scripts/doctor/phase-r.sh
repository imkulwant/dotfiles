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
