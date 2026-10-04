#!/usr/bin/env bash
# Phase R — Lifecycle (install + uninstall + features index)
phase_start "R" "Lifecycle"
SOURCE="$CHEZMOI_SOURCE"

check "scripts/macos-defaults-keys.txt exists"
assert_file "$SOURCE/scripts/macos-defaults-keys.txt"

check "macos_defaults script reads keys from file"
assert_grep 'macos-defaults-keys\.txt' "$SOURCE/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"
