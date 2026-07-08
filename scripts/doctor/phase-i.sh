#!/usr/bin/env bash
# Phase I — Language toolchains: mise + uv

phase_start "I" "mise + uv"

SOURCE="$(chezmoi source-path)"

# ── mise ──────────────────────────────────────────────────────────────────────
check "mise installed"
assert_cmd_ok "mise --version"

check "mise has global java temurin-21"
assert_cmd_out "mise ls java" "temurin-21"

check "mise-managed java on PATH (interactive shell)"
assert_cmd_out "zsh -i -c 'java -version 2>&1'" "21\."

check "mise-managed java binary path contains mise/installs"
assert_cmd_out "mise which java" "mise/installs/java"

# ── uv ───────────────────────────────────────────────────────────────────────
check "uv installed"
assert_cmd_ok "uv --version"

# ── Legacy tools removed ──────────────────────────────────────────────────────
_brew_formulae="$(brew list --formula 2>/dev/null)"

check "jenv no longer installed via brew"
if ! printf '%s\n' "$_brew_formulae" | grep -qx "jenv"; then pass; else fail "jenv still installed — run: brew uninstall jenv"; fi

check "pyenv no longer installed via brew"
if ! printf '%s\n' "$_brew_formulae" | grep -qx "pyenv"; then pass; else fail "pyenv still installed — run: brew uninstall pyenv"; fi

check "pipx no longer installed via brew"
if ! printf '%s\n' "$_brew_formulae" | grep -qx "pipx"; then pass; else fail "pipx still installed — run: brew uninstall pipx"; fi

check "openjdk@21 no longer installed via brew (mise manages Java)"
if ! printf '%s\n' "$_brew_formulae" | grep -qx "openjdk@21"; then pass; else fail "openjdk@21 still installed — run: brew uninstall openjdk@21"; fi

check "~/.jenv state directory removed"
assert_cmd_ok "[ ! -d \"$HOME/.jenv\" ]"

check "~/.pyenv state directory removed"
assert_cmd_ok "[ ! -d \"$HOME/.pyenv\" ]"

# ── Brewfile ──────────────────────────────────────────────────────────────────
check "Brewfile no longer declares jenv"
assert_no_grep '^brew "jenv"' "$SOURCE/Brewfile"

check "Brewfile no longer declares pyenv"
assert_no_grep '^brew "pyenv"' "$SOURCE/Brewfile"

check "Brewfile no longer declares pipx"
assert_no_grep '^brew "pipx"' "$SOURCE/Brewfile"

check "Brewfile no longer declares openjdk@21"
assert_no_grep '^brew "openjdk@21"' "$SOURCE/Brewfile"

# ── VS Code settings ──────────────────────────────────────────────────────────
_vscode_settings="$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json"

check "VS Code settings.json points Java runtime at mise/installs"
assert_grep 'mise/installs' "$_vscode_settings"

check "VS Code settings.json no longer references Homebrew openjdk@21 path"
assert_no_grep 'openjdk@21' "$_vscode_settings"

# ── Project templates ─────────────────────────────────────────────────────────
check "templates/.mise.toml exists in chezmoi source"
assert_file "$SOURCE/templates/.mise.toml"

check "templates/.envrc exists in chezmoi source"
assert_file "$SOURCE/templates/.envrc"

check ".chezmoiignore blocks templates/ from being applied to HOME"
assert_grep '^templates' "$SOURCE/.chezmoiignore"

check ".chezmoiignore blocks ~/.local/share/mise"
assert_grep '\.local/share/mise' "$SOURCE/.chezmoiignore"

phase_end
