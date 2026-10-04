#!/usr/bin/env bash
# Phase Q — Automation & upkeep
phase_start "Q" "Automation & upkeep"
SOURCE="$CHEZMOI_SOURCE"

check "justfile has upgrade-all/backup-atuin/maintain"
assert_grep '^upgrade-all:' "$SOURCE/justfile"
assert_grep '^backup-atuin:' "$SOURCE/justfile"
assert_grep '^maintain:' "$SOURCE/justfile"

check "atuin-backup.sh exists, executable, set -euo pipefail"
assert_file "$SOURCE/scripts/maintenance/atuin-backup.sh"
assert_perm "$SOURCE/scripts/maintenance/atuin-backup.sh" 755
assert_grep 'set -euo pipefail' "$SOURCE/scripts/maintenance/atuin-backup.sh"

check "weekly-maintenance plist template exists"
assert_file "$SOURCE/private_Library/LaunchAgents/local.weekly-maintenance.plist.tmpl"

check "plist renders empty when weekly_maintenance is false"
_out=$(chezmoi execute-template <"$SOURCE/private_Library/LaunchAgents/local.weekly-maintenance.plist.tmpl" 2>/dev/null)
if [[ -z "$(printf '%s' "$_out" | tr -d '[:space:]')" ]]; then
  pass
else
  fail "non-empty render with flag=false"
fi

check "run_onchange_load_weekly_maintenance script exists"
assert_file "$SOURCE/.chezmoiscripts/run_onchange_load_weekly_maintenance_launchd.sh.tmpl"
assert_grep 'local\.weekly-maintenance' \
  "$SOURCE/.chezmoiscripts/run_onchange_load_weekly_maintenance_launchd.sh.tmpl"

check "toggle load/unload is clean (Review Focus #4)"
assert_grep 'launchctl bootstrap' "$SOURCE/.chezmoiscripts/run_onchange_load_weekly_maintenance_launchd.sh.tmpl"
assert_grep 'launchctl bootout' "$SOURCE/.chezmoiscripts/run_onchange_load_weekly_maintenance_launchd.sh.tmpl"

check "brew bundle check clean"
assert_cmd_ok "brew bundle check --no-upgrade --file $SOURCE/Brewfile"

check "no dead symlinks in ~/.local/bin"
set +e
_dead=$(find -L "$HOME/.local/bin" -maxdepth 1 -type l 2>/dev/null | grep -v '/chezmoi$' | wc -l | tr -d ' ')
set -e
if [[ "$_dead" -eq 0 ]]; then
  pass
else
  fail "$_dead dead symlink(s) in $HOME/.local/bin"
fi

check "atuin DB size sane (< 1 GB; warn >= 500 MB)"
_db="$HOME/.local/share/atuin/history.db"
if [[ ! -f "$_db" ]]; then
  info "atuin DB not yet created"
  pass
else
  _size=$(stat -f %z "$_db" 2>/dev/null || stat -c %s "$_db" 2>/dev/null || echo 0)
  if [[ "$_size" -ge 1073741824 ]]; then
    fail "atuin DB is ${_size} bytes (>= 1 GB)"
  elif [[ "$_size" -ge 524288000 ]]; then
    info "atuin DB is ${_size} bytes (>= 500 MB) — consider rotating"
    pass
  else
    pass
  fi
fi

check "scripts/maintenance/ dir exists"
assert_dir "$SOURCE/scripts/maintenance"
