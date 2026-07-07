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

# Sub-task 8 - every chezmoi script guarded by 'set -euo pipefail' (SWOT bug 10)
for f in "$(chezmoi source-path)/.chezmoiscripts"/*.sh.tmpl \
         "$(chezmoi source-path)"/run_onchange_*.sh.tmpl; do
  [ -f "$f" ] || continue
  check "$(basename "$f") has 'set -euo pipefail'"
  assert_grep '^set -euo pipefail' "$f"
done

# Sub-task 9 - dot_aliases.zsh.tmpl has no LLM citation markers (SWOT bug 11)
check "dot_aliases.zsh.tmpl has no '[N]' citation markers"
assert_no_grep '\[[0-9]+\]' "$(chezmoi source-path)/dot_aliases.zsh.tmpl"

# Sub-task 10 - .chezmoidata.yaml no-op removed (SWOT bug 12).
# Will be reintroduced in Phase L for per-host templating.
check ".chezmoidata.yaml no-op has been removed"
assert_no_file "$(chezmoi source-path)/.chezmoidata.yaml"

# Sub-task 11 - .DS_Store handling (SWOT threat 6)
check ".chezmoiignore blocks .DS_Store"
assert_grep '^\.DS_Store$' "$(chezmoi source-path)/.chezmoiignore"

check "no .DS_Store files remain in the chezmoi source tree"
assert_cmd_ok "[ -z \"\$(find \"\$(chezmoi source-path)\" -name .DS_Store)\" ]"

# Sub-task 12 - LICENSE present (SWOT gap 26). .chezmoiignore excludes from apply.
check "LICENSE exists at repo root"
assert_file "$(chezmoi source-path)/LICENSE"

check "LICENSE is MIT"
assert_grep 'MIT License' "$(chezmoi source-path)/LICENSE"

# Sub-task 3+5 - OMZ install-path consolidation (SWOT bugs 3, 4, 5, 6).
# Duplicated run_once scripts removed; externals become sole install path.
check "duplicated OMZ install script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_30_install_ohmyzsh.sh.tmpl"

check "duplicated Powerlevel10k install script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_40_install_powerlevel10k.sh.tmpl"

check "duplicated OMZ plugins install script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_ohmyzsh-plugins.sh.tmpl"

check ".chezmoiignore no longer blocks the whole .oh-my-zsh/custom subtree"
assert_no_grep '^\.oh-my-zsh/custom/\*$' "$(chezmoi source-path)/.chezmoiignore"

check ".chezmoiignore no longer blocks .oh-my-zsh/lib (needed for OMZ runtime)"
assert_no_grep '^\.oh-my-zsh/lib/\*$' "$(chezmoi source-path)/.chezmoiignore"

check ".chezmoiignore still blocks the OMZ runtime cache"
assert_grep '^\.oh-my-zsh/cache' "$(chezmoi source-path)/.chezmoiignore"

phase_end
