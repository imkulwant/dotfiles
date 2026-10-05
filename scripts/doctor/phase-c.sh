#!/usr/bin/env bash
# Phase C - Critical fixes. Assertions grow commit-by-commit as each SWOT
# bug is closed. Every check here maps to one plan sub-task and one commit.

phase_start "C" "Critical fixes"

SOURCE="$CHEZMOI_SOURCE"

# Sub-task 1 - BrewFile casing (SWOT bug 1)
check "run_onchange script uses correct 'Brewfile' casing"
assert_grep '/Brewfile"' "$SOURCE/run_onchange_install-brewfile.sh.tmpl"

check "run_onchange script no longer references 'BrewFile' (wrong casing)"
assert_no_grep 'BrewFile' "$SOURCE/run_onchange_install-brewfile.sh.tmpl"

# Sub-task 2 - root-level install.sh stays removed. scripts/install.sh (Task 9,
# commit 79f01fa) is the new entry-point wrapper around chezmoi's bootstrap.
check "install.sh has been removed"
assert_no_file "$SOURCE/install.sh"

check "README documents the chezmoi bootstrap one-liner"
assert_grep 'chezmoi init --apply|chezmoi.io.*init --apply|get.chezmoi.io|install.sh' \
  "$SOURCE/README.md"

# Sub-task 4 - .chezmoiexternal.toml pinned to immutable refs (no master.tar.gz)
check ".chezmoiexternal.toml does not use unpinned 'master.tar.gz' URLs"
assert_no_grep 'archive/master\.tar\.gz' "$SOURCE/.chezmoiexternal.toml"

check ".chezmoiexternal.toml pins zsh-syntax-highlighting to a tag"
assert_grep 'zsh-syntax-highlighting/archive/[0-9]' \
  "$SOURCE/.chezmoiexternal.toml"

check ".chezmoiexternal.toml pins zsh-autosuggestions to a tag"
assert_grep 'zsh-autosuggestions/archive/v[0-9]' \
  "$SOURCE/.chezmoiexternal.toml"

# Sub-task 6 - VS Code settings.json version drift (SWOT bugs 7, 8)
VSCODE_SETTINGS="$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json.tmpl"

check "VS Code settings.json no longer references openjdk@24"
assert_no_grep 'openjdk@24' "$VSCODE_SETTINGS"

check "VS Code settings.json declares JavaSE-21 as default runtime"
assert_grep '"name": "JavaSE-21"' "$VSCODE_SETTINGS"

check "VS Code settings.json no longer references python3.12"
assert_no_grep '/python3\.12' "$VSCODE_SETTINGS"

check "VS Code settings.json references python3.13 (matches Brewfile)"
assert_grep '/python3\.13' "$VSCODE_SETTINGS"

# Sub-task 7 - chsh uses Homebrew zsh, not system /bin/zsh (SWOT bug 9)
ENSURE_ZSH="$SOURCE/.chezmoiscripts/run_once_before_30_ensure_zsh.sh.tmpl"

# chezmoi runs before-scripts in name order; anything calling brew must sort
# after the Homebrew installer or a fresh Mac aborts on "brew: not found".
check "before-scripts that call brew sort after install_homebrew"
_misordered=""
for f in "$SOURCE/.chezmoiscripts"/run_once_before_*.sh.tmpl; do
  _name=$(basename "$f")
  case "$_name" in *install_homebrew*) continue ;; esac
  if grep -qE '(^|[^/])brew (install|bundle)' "$f" &&
    [[ "$_name" < "run_once_before_20_install_homebrew.sh.tmpl" ]]; then
    _misordered="$_misordered $_name"
  fi
done
if [ -z "$_misordered" ]; then pass; else fail "runs before Homebrew:$_misordered"; fi

check "ensure_zsh script targets /opt/homebrew/bin/zsh"
assert_grep '/opt/homebrew/bin/zsh' "$ENSURE_ZSH"

check "ensure_zsh script no longer chsh's to bare /bin/zsh"
assert_no_grep 'chsh -s /bin/zsh' "$ENSURE_ZSH"

check "ensure_zsh script registers Homebrew zsh in /etc/shells"
assert_grep '/etc/shells' "$ENSURE_ZSH"

# Sub-task 8 - every chezmoi script guarded by 'set -euo pipefail' (SWOT bug 10)
for f in "$SOURCE/.chezmoiscripts"/*.sh.tmpl \
  "$SOURCE"/run_onchange_*.sh.tmpl; do
  [ -f "$f" ] || continue
  check "$(basename "$f") has 'set -euo pipefail'"
  assert_grep '^set -euo pipefail' "$f"
done

# Sub-task 9 - dot_aliases.zsh.tmpl has no LLM citation markers (SWOT bug 11)
check "dot_aliases.zsh.tmpl has no '[N]' citation markers"
assert_no_grep '\[[0-9]+\]' "$SOURCE/dot_aliases.zsh.tmpl"

# Sub-task 11 - .DS_Store handling (SWOT threat 6)
check ".chezmoiignore blocks .DS_Store"
assert_grep '^\.DS_Store$' "$SOURCE/.chezmoiignore"

check "no .DS_Store files remain in the chezmoi source tree"
assert_cmd_ok "[ -z \"\$(find \"$SOURCE\" -name .DS_Store)\" ]"

# Sub-task 12 - LICENSE present (SWOT gap 26). .chezmoiignore excludes from apply.
check "LICENSE exists at repo root"
assert_file "$SOURCE/LICENSE"

check "LICENSE is MIT"
assert_grep 'MIT License' "$SOURCE/LICENSE"

# Sub-task 3+5 - OMZ install-path consolidation (SWOT bugs 3, 4, 5, 6).
# Duplicated run_once scripts removed; externals become sole install path.
check "duplicated OMZ install script removed"
assert_no_file "$SOURCE/.chezmoiscripts/run_once_before_30_install_ohmyzsh.sh.tmpl"

check "duplicated Powerlevel10k install script removed"
assert_no_file "$SOURCE/.chezmoiscripts/run_once_before_40_install_powerlevel10k.sh.tmpl"

check "duplicated OMZ plugins install script removed"
assert_no_file "$SOURCE/.chezmoiscripts/run_once_before_ohmyzsh-plugins.sh.tmpl"

# Sub-task 13 - branch renamed master -> main (SWOT bug 18)
check "current branch is 'main'"
assert_cmd_out "git -C \"$SOURCE\" branch --show-current" "^main$"

phase_end
