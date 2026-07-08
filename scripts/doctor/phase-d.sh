#!/usr/bin/env bash
# Phase D — Consolidated Brewfile

phase_start "D" "Brewfile"

SOURCE="$(chezmoi source-path)"

# ── Brewfile declarations ─────────────────────────────────────────────────────
for formula in neovim tmux ripgrep fd bat eza git-delta atuin starship mise gh jq yq direnv uv lazygit zoxide btop just fzf tldr dust; do
  check "Brewfile declares $formula"
  assert_grep "^brew \"$formula\"" "$SOURCE/Brewfile"
done

check "Brewfile declares font-meslo-lg-nerd-font"
assert_grep "font-meslo-lg-nerd-font" "$SOURCE/Brewfile"

# ── Runtime installs (cache brew list to avoid repeated slow calls) ───────────
_brew_formulae="$(brew list --formula 2>/dev/null)"
_brew_casks="$(brew list --cask 2>/dev/null)"

_check_formula() {
  local formula="$1"
  check "$formula installed"
  if printf '%s\n' "$_brew_formulae" | grep -qx "$formula"; then pass; else fail "brew formula '$formula' not installed"; fi
}

_check_cask() {
  local cask="$1"
  check "$cask installed"
  if printf '%s\n' "$_brew_casks" | grep -qx "$cask"; then pass; else fail "brew cask '$cask' not installed"; fi
}

for formula in neovim tmux ripgrep fd bat eza git-delta atuin starship mise gh jq yq direnv uv lazygit zoxide btop just fzf tldr dust; do
  _check_formula "$formula"
done

_check_cask "font-meslo-lg-nerd-font"

check "nvim >= 0.10"
assert_cmd_out "nvim --version" "NVIM v0\\.1"

check "brew bundle check clean (VS Code excluded — self-updates outside brew)"
assert_cmd_ok "HOMEBREW_BUNDLE_CASK_SKIP=visual-studio-code brew bundle check --file '$SOURCE/Brewfile'"

# ── run_onchange script ───────────────────────────────────────────────────────
check "run_onchange script contains SHA hash trigger"
assert_grep "sha256sum" "$SOURCE/run_onchange_install-brewfile.sh.tmpl"

phase_end
