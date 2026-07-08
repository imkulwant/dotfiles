#!/usr/bin/env bash
# Phase K — macOS defaults

phase_start "K" "macOS defaults"

SOURCE="$(chezmoi source-path)"

check "run_onchange_macos_defaults script exists"
assert_file "$SOURCE/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"

check "macos_defaults script has set -euo pipefail"
assert_grep 'set -euo pipefail' "$SOURCE/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"

check "Dock autohide is on"
assert_cmd_out "defaults read com.apple.dock autohide" "1"

check "Dock icon size is 36"
assert_cmd_out "defaults read com.apple.dock tilesize" "36"

check "Dock show-recents is off"
assert_cmd_out "defaults read com.apple.dock show-recents" "0"

phase_end
