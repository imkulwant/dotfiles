#!/usr/bin/env bash
# Phase H — Git + SSH

phase_start "H" "Git + SSH"

SOURCE="$CHEZMOI_SOURCE"

# ── gitconfig ────────────────────────────────────────────────────────────────
check "git user.email is set"
assert_cmd_ok "git config --get user.email"

check "git user.name is set"
assert_cmd_ok "git config --get user.name"

check "git init.defaultBranch is main"
assert_cmd_out "git config --global --get init.defaultBranch" "main"

check "git pull.rebase is true"
assert_cmd_out "git config --global --get pull.rebase" "true"

check "git push.autoSetupRemote is true"
assert_cmd_out "git config --global --get push.autoSetupRemote" "true"

check "git rerere.enabled is true"
assert_cmd_out "git config --global --get rerere.enabled" "true"

check "git core.pager is delta"
assert_cmd_out "git config --global --get core.pager" "delta"

check "git delta side-by-side enabled"
assert_cmd_out "git config --global --get delta.side-by-side" "true"

check "git merge.conflictstyle is zdiff3"
assert_cmd_out "git config --global --get merge.conflictstyle" "zdiff3"

check "git url rewrite: https://github.com/ -> git@github.com: (SSH-only)"
assert_cmd_out "git config --global --get url.git@github.com:.insteadOf" "https://github.com/"

# ── gitconfig managed by chezmoi ─────────────────────────────────────────────
check "dot_gitconfig.tmpl exists in chezmoi source"
assert_file "$SOURCE/dot_gitconfig.tmpl"

# ── SSH config ───────────────────────────────────────────────────────────────
check "$HOME/.ssh/config exists"
assert_file "$HOME/.ssh/config"

check "$HOME/.ssh/config has 0600 perms"
assert_perm "$HOME/.ssh/config" 600

check "$HOME/.ssh/config has Host * with UseKeychain yes"
assert_grep 'UseKeychain yes' "$HOME/.ssh/config"

check "$HOME/.ssh/config has IdentitiesOnly yes"
assert_grep 'IdentitiesOnly yes' "$HOME/.ssh/config"

check "$HOME/.ssh/config has explicit Host github.com block"
assert_grep 'Host github.com' "$HOME/.ssh/config"

check "GitHub SSH authentication works"
assert_cmd_out "ssh -T git@github.com 2>&1 || true" "successfully authenticated"

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
