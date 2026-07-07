#!/usr/bin/env bash
# Phase C - Critical fixes. Assertions grow commit-by-commit as each SWOT
# bug is closed. Every check here maps to one plan sub-task and one commit.

phase_start "C" "Critical fixes"

# Sub-task 1 - BrewFile casing (SWOT bug 1)
check "run_onchange script uses correct 'Brewfile' casing"
assert_grep '/Brewfile"' "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

check "run_onchange script no longer references 'BrewFile' (wrong casing)"
assert_no_grep 'BrewFile' "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

phase_end
