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
