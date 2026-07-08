#!/usr/bin/env bash
# Phase E — Shell layer

phase_start "E" "Shell layer"

SOURCE="$CHEZMOI_SOURCE"

# ── dot_zshrc.tmpl content checks ────────────────────────────────────────────
check "dot_zshrc.tmpl no longer sets Powerlevel10k theme"
assert_no_grep 'ZSH_THEME="powerlevel10k' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl no longer sources ~/.p10k.zsh"
assert_no_grep 'source ~/.p10k.zsh' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes starship"
assert_grep 'starship init zsh' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes zoxide"
assert_grep 'zoxide init zsh' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes mise"
assert_grep 'mise activate zsh' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes direnv"
assert_grep 'direnv hook zsh' "$SOURCE/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes atuin"
assert_grep 'atuin init zsh' "$SOURCE/dot_zshrc.tmpl"

check "fzf is sourced BEFORE atuin init (Ctrl-R conflict)"
awk '/fzf --zsh/{f=NR} /atuin init/{a=NR} END{exit !(f && a && f<a)}' \
  "$SOURCE/dot_zshrc.tmpl" && pass || fail "atuin init must come after fzf --zsh"

check "dot_zshrc.tmpl no longer runs jenv init"
assert_no_grep 'jenv init' "$SOURCE/dot_zshrc.tmpl"

check "EDITOR is nvim, not code"
assert_grep 'EDITOR="nvim"' "$SOURCE/dot_zshrc.tmpl"

# ── Config files ──────────────────────────────────────────────────────────────
check "starship.toml exists in chezmoi source"
assert_file "$SOURCE/dot_config/starship.toml"

check "atuin/config.toml exists in chezmoi source"
assert_file "$SOURCE/dot_config/atuin/config.toml"

check "atuin config sets fuzzy search"
assert_grep 'search_mode = "fuzzy"' "$SOURCE/dot_config/atuin/config.toml"

# ── Aliases ───────────────────────────────────────────────────────────────────
check "dot_aliases.zsh.tmpl has ls=eza alias"
assert_grep "alias ls='eza" "$SOURCE/dot_aliases.zsh.tmpl"

check "dot_aliases.zsh.tmpl has ll=eza alias"
assert_grep "alias ll='eza" "$SOURCE/dot_aliases.zsh.tmpl"

check "dot_aliases.zsh.tmpl has cat=bat alias"
assert_grep "alias cat='bat" "$SOURCE/dot_aliases.zsh.tmpl"

check "dot_aliases.zsh.tmpl has lg=lazygit alias"
assert_grep "alias lg='lazygit'" "$SOURCE/dot_aliases.zsh.tmpl"

# ── p10k fully removed ────────────────────────────────────────────────────────
check "dot_p10k.zsh.tmpl removed from chezmoi source"
assert_no_file "$SOURCE/dot_p10k.zsh.tmpl"

check "$HOME/.p10k.zsh not present in HOME (p10k fully retired)"
assert_no_file "$HOME/.p10k.zsh"

check "atuin has history (import zsh was run)"
assert_cmd_ok "[ -s \"$HOME/.local/share/atuin/history.db\" ]"

# ── Runtime verification ──────────────────────────────────────────────────────
check "Interactive zsh has starship prompt (STARSHIP_SHELL set)"
assert_cmd_ok "zsh -i -c 'test -n \"\$STARSHIP_SHELL\"'"

check "Interactive zsh has zoxide function 'z'"
assert_cmd_ok "zsh -i -c 'type z >/dev/null'"

check "Interactive zsh has v=nvim alias"
assert_cmd_out "zsh -i -c 'alias v'" "nvim"

check "Interactive zsh has ll=eza alias"
assert_cmd_out "zsh -i -c 'alias ll'" "eza"

check "Shell startup under 500ms"
_start=$(date +%s%N 2>/dev/null || echo 0)
zsh -i -c exit 2>/dev/null
_end=$(date +%s%N 2>/dev/null || echo 0)
_ms=$(((_end - _start) / 1000000))
[ "$_ms" -lt 500 ] && pass || fail "startup took ${_ms}ms (target: <500ms)"

phase_end
