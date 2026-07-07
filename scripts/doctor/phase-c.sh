#!/usr/bin/env bash
# Phase C - Critical fixes. Assertions grow commit-by-commit as each SWOT
# bug is closed. Every check here maps to one plan sub-task and one commit.

phase_start "C" "Critical fixes"

# Sub-task 1 - BrewFile casing (SWOT bug 1)
check "run_onchange script uses correct 'Brewfile' casing"
assert_grep '/Brewfile"' "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

check "run_onchange script no longer references 'BrewFile' (wrong casing)"
assert_no_grep 'BrewFile' "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

# Sub-task 2 - install.sh removed; chezmoi init --apply is the sole bootstrap
check "install.sh has been removed"
assert_no_file "$(chezmoi source-path)/install.sh"

check "README documents the chezmoi bootstrap one-liner"
assert_grep 'chezmoi init --apply|chezmoi.io.*init --apply|get.chezmoi.io' \
  "$(chezmoi source-path)/README.md"

# Sub-task 4 - .chezmoiexternal.toml pinned to immutable refs (no master.tar.gz)
check ".chezmoiexternal.toml does not use unpinned 'master.tar.gz' URLs"
assert_no_grep 'archive/master\.tar\.gz' "$(chezmoi source-path)/.chezmoiexternal.toml"

check ".chezmoiexternal.toml pins zsh-syntax-highlighting to a tag"
assert_grep 'zsh-syntax-highlighting/archive/[0-9]' \
  "$(chezmoi source-path)/.chezmoiexternal.toml"

check ".chezmoiexternal.toml pins zsh-autosuggestions to a tag"
assert_grep 'zsh-autosuggestions/archive/v[0-9]' \
  "$(chezmoi source-path)/.chezmoiexternal.toml"

# Sub-task 6 - VS Code settings.json version drift (SWOT bugs 7, 8)
VSCODE_SETTINGS="$(chezmoi source-path)/private_Library/private_Application Support/private_Code/User/settings.json"

check "VS Code settings.json no longer references openjdk@24"
assert_no_grep 'openjdk@24' "$VSCODE_SETTINGS"

check "VS Code settings.json declares JavaSE-21 as default runtime"
assert_grep '"name": "JavaSE-21"' "$VSCODE_SETTINGS"

check "VS Code settings.json no longer references python3.12"
assert_no_grep '/python3\.12' "$VSCODE_SETTINGS"

check "VS Code settings.json references python3.13 (matches Brewfile)"
assert_grep '/python3\.13' "$VSCODE_SETTINGS"

# Sub-task 7 - chsh uses Homebrew zsh, not system /bin/zsh (SWOT bug 9)
ENSURE_ZSH="$(chezmoi source-path)/.chezmoiscripts/run_once_before_10_ensure_zsh.sh.tmpl"

check "ensure_zsh script targets /opt/homebrew/bin/zsh"
assert_grep '/opt/homebrew/bin/zsh' "$ENSURE_ZSH"

check "ensure_zsh script no longer chsh's to bare /bin/zsh"
assert_no_grep 'chsh -s /bin/zsh' "$ENSURE_ZSH"

check "ensure_zsh script registers Homebrew zsh in /etc/shells"
assert_grep '/etc/shells' "$ENSURE_ZSH"

phase_end
