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
