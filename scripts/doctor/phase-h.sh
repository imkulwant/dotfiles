#!/usr/bin/env bash
# Phase H — Git tooling
# ~/.gitconfig and ~/.ssh/config are intentionally unmanaged (per-machine).

phase_start "H" "Git tooling"

SOURCE="$CHEZMOI_SOURCE"

# ── git + SSH configs stay unmanaged ─────────────────────────────────────────
check "chezmoi source does not manage ~/.gitconfig"
assert_no_file "$SOURCE/dot_gitconfig.tmpl"
assert_no_file "$SOURCE/dot_gitconfig"

check "chezmoi source does not manage ~/.ssh/config"
assert_no_file "$SOURCE/private_dot_ssh/private_config.tmpl"
assert_no_file "$SOURCE/private_dot_ssh/private_config"

check ".chezmoiignore guards SSH private keys"
assert_grep '\.ssh/id_\*' "$SOURCE/.chezmoiignore"

# ── lazygit ──────────────────────────────────────────────────────────────────
check "lazygit config.yml exists"
assert_file "$HOME/.config/lazygit/config.yml"

check "lazygit config uses delta pager"
assert_grep 'pager: delta' "$HOME/.config/lazygit/config.yml"

# ── gh CLI ───────────────────────────────────────────────────────────────────
check "gh CLI authenticated"
if assert_cmd_ok "gh auth status" 2>/dev/null; then
  : # pass already recorded
else
  fail "run: gh auth login --git-protocol ssh"
fi

phase_end
