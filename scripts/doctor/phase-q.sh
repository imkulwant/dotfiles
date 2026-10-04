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
