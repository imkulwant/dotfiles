#!/usr/bin/env bash
# Phase M — Documentation

phase_start "M" "Documentation"

SOURCE="$CHEZMOI_SOURCE"

check "README.md exists"
assert_file "$SOURCE/README.md"

check "README.md contains bootstrap one-liner"
assert_grep 'chezmoi init --apply' "$SOURCE/README.md"

check "README.md is non-trivial (>200 lines)"
assert_cmd_ok "[ \"$(wc -l <"$SOURCE/README.md")\" -gt 200 ]"

check "docs/CHOICES.md exists"
assert_file "$SOURCE/docs/CHOICES.md"

check "docs/chezmoi-cheatsheet.md exists"
assert_file "$SOURCE/docs/chezmoi-cheatsheet.md"

check "docs/history/ contains archived overhaul plan"
assert_file "$SOURCE/docs/history/2026-07-06-terminal-workflow-plan.md"

check "docs/history/ contains archived SWOT"
assert_file "$SOURCE/docs/history/2026-07-06-swot.md"

phase_end
