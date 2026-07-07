#!/usr/bin/env bash
# Phase A — Audit sanity. Mostly informational; assertions kept minimal since
# Phase A itself is read-only.

phase_start "A" "Audit sanity"

check "chezmoi is installed"
assert_cmd_ok "chezmoi --version"

check "chezmoi source-path resolves under \$HOME"
assert_cmd_out "chezmoi source-path" "^${HOME}/"

check "chezmoi source-path is a git repo"
assert_dir "$(chezmoi source-path)/.git"

check "chezmoi source-path has a git remote 'origin'"
assert_cmd_ok "git -C \"\$(chezmoi source-path)\" remote get-url origin"

# Informational (not asserted): print current branch, shell, brew count.
branch=$(git -C "$(chezmoi source-path)" branch --show-current 2>/dev/null || echo "?")
brew_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
info "branch=${branch}  shell=${SHELL##*/}  brew_formulae=${brew_count}  brew_casks=${cask_count}"

phase_end
