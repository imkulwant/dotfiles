#!/usr/bin/env bash
# Phase L — Advanced (conditional)

phase_start "L" "Advanced (conditional)"

SOURCE="$CHEZMOI_SOURCE"

# ── launchd auto-update ───────────────────────────────────────────────────────
check "chezmoi-update plist managed by chezmoi"
assert_file "$SOURCE/private_Library/LaunchAgents/local.chezmoi-update.plist.tmpl"

check "chezmoi-update plist applied to LaunchAgents"
assert_file "$HOME/Library/LaunchAgents/local.chezmoi-update.plist"

check "chezmoi-update launchd agent loaded"
# Use non-quiet grep so launchctl can finish writing before grep closes stdin;
# `grep -q` exits on first match and gives launchctl SIGPIPE, which flips the
# pipeline exit under `set -o pipefail` (run.sh sets it) even though a match
# was found.
assert_cmd_ok "launchctl list | grep chezmoi-update >/dev/null"

phase_end
