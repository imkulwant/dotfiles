#!/usr/bin/env bash
# Phase P — Portability (multi-username / multi-host)

phase_start "P" "Portability (multi-username / multi-host)"

SOURCE="$CHEZMOI_SOURCE"

check "no .chezmoi.toml.tmpl (setup asks no questions)"
assert_no_file "$SOURCE/.chezmoi.toml.tmpl"

check ".chezmoidata.yaml has ask.endpoint"
assert_grep 'ask:' "$SOURCE/.chezmoidata.yaml"

check "VS Code settings.json is now a template"
assert_file "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json.tmpl"
assert_no_file "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json"

check "VS Code Java path uses chezmoi.homeDir"
assert_grep '\{\{ \.chezmoi\.homeDir \}\}/.local/share/mise/installs/java/temurin-21' \
  "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json.tmpl"

check "chezmoi-update plist renamed to local.chezmoi-update"
assert_file "$SOURCE/private_Library/LaunchAgents/local.chezmoi-update.plist.tmpl"
assert_no_file "$SOURCE/private_Library/LaunchAgents/com.kulsin.chezmoi-update.plist.tmpl"
assert_grep '<string>local.chezmoi-update</string>' \
  "$SOURCE/private_Library/LaunchAgents/local.chezmoi-update.plist.tmpl"
assert_grep 'lookPath "chezmoi"' \
  "$SOURCE/private_Library/LaunchAgents/local.chezmoi-update.plist.tmpl"

check "run_onchange_load_chezmoi_launchd bootouts legacy label"
assert_grep 'launchctl bootout.*com.kulsin.chezmoi-update' \
  "$SOURCE/.chezmoiscripts/run_onchange_load_chezmoi_launchd.sh.tmpl"
assert_grep 'local.chezmoi-update' \
  "$SOURCE/.chezmoiscripts/run_onchange_load_chezmoi_launchd.sh.tmpl"

check "ask() reads endpoint from chezmoi data"
assert_grep '\{\{ \.ask\.endpoint \}\}' "$SOURCE/dot_zshrc.tmpl"
assert_no_grep '192\.168\.0\.198' "$SOURCE/dot_zshrc.tmpl"

check "externals drop OMZ and p10k"
assert_no_grep '\.oh-my-zsh' "$SOURCE/.chezmoiexternal.toml"
assert_no_grep 'powerlevel10k' "$SOURCE/.chezmoiexternal.toml"

check "externals point zsh plugins to .local/share/zsh-plugins"
assert_grep '\.local/share/zsh-plugins/zsh-syntax-highlighting' "$SOURCE/.chezmoiexternal.toml"
assert_grep '\.local/share/zsh-plugins/zsh-autosuggestions' "$SOURCE/.chezmoiexternal.toml"

check "zshrc sources plugins from the new location"
assert_grep '\.local/share/zsh-plugins' "$SOURCE/dot_zshrc.tmpl"
assert_no_grep 'oh-my-zsh/custom/plugins' "$SOURCE/dot_zshrc.tmpl"

check ".chezmoiignore has no oh-my-zsh patterns"
assert_no_grep 'oh-my-zsh' "$SOURCE/.chezmoiignore"

check "no hardcoded personal identity outside docs/"
# Allowlist: docs/, .git/, phase-p.sh itself (needs to spell the patterns),
# lock files (*-lock.json may legitimately pin github username),
# .claude/ and .superpowers/ (user config and metadata, not managed).
if ! find "$SOURCE" -type f \
  -not -path "$SOURCE/docs/*" \
  -not -path "$SOURCE/.git/*" \
  -not -path "$SOURCE/.claude/*" \
  -not -path "$SOURCE/.superpowers/*" \
  -not -path "$SOURCE/scripts/doctor/phase-p.sh" \
  -not -name '*-lock.json' \
  -print0 |
  xargs -0 grep -lE '/Users/kulsin|kulsin@|singh\.kulwant@gmx' >/tmp/phase-p-hits 2>/dev/null; then
  : # grep -l exited 1 -> no files matched -> good
fi
if [ -s /tmp/phase-p-hits ]; then
  fail "hardcoded identity found: $(tr '\n' ' ' </tmp/phase-p-hits)"
else
  pass
fi
rm -f /tmp/phase-p-hits

check "grep guard allowlist does not false-positive on docs (Review Focus #5)"
# Sanity: a docs/ file is allowed to contain kulsin. Create a probe, run
# the SAME guard logic, confirm the probe does NOT trip the guard, delete it.
echo '/Users/kulsin probe' >"$SOURCE/docs/.phase-p-probe"
if ! find "$SOURCE" -type f \
  -not -path "$SOURCE/docs/*" \
  -not -path "$SOURCE/.git/*" \
  -not -path "$SOURCE/.claude/*" \
  -not -path "$SOURCE/.superpowers/*" \
  -not -path "$SOURCE/scripts/doctor/phase-p.sh" \
  -not -name '*-lock.json' \
  -print0 |
  xargs -0 grep -lE '/Users/kulsin' >/dev/null 2>&1; then
  pass # grep found no hits in non-docs tree -> allowlist is working
else
  fail "allowlist broken: docs probe triggered guard"
fi
rm -f "$SOURCE/docs/.phase-p-probe"
