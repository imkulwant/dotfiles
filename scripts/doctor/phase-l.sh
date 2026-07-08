#!/usr/bin/env bash
# Phase L — Advanced (conditional)

phase_start "L" "Advanced (conditional)"

SOURCE="$CHEZMOI_SOURCE"

# ── Per-host templating ───────────────────────────────────────────────────────
check ".chezmoidata.yaml defines host-scoped data"
assert_grep 'work' "$SOURCE/.chezmoidata.yaml"

check "chezmoi execute-template resolves .work variable"
assert_cmd_ok "chezmoi execute-template '{{ .work }}'"

# ── launchd auto-update ───────────────────────────────────────────────────────
check "chezmoi-update plist managed by chezmoi"
assert_file "$SOURCE/private_Library/LaunchAgents/com.kulsin.chezmoi-update.plist.tmpl"

check "chezmoi-update plist applied to LaunchAgents"
assert_file "$HOME/Library/LaunchAgents/com.kulsin.chezmoi-update.plist"

check "chezmoi-update launchd agent loaded"
assert_cmd_ok "launchctl list | grep -q chezmoi-update"

phase_end
