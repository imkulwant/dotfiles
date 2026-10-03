#!/usr/bin/env bash
# Phase P — Portability (multi-username / multi-host)

phase_start "P" "Portability (multi-username / multi-host)"

SOURCE="$CHEZMOI_SOURCE"

check ".chezmoi.toml.tmpl defines all four prompts"
assert_grep 'promptStringOnce .* "name"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptStringOnce .* "email"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptStringOnce .* "github_user"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptBoolOnce .* "work"' "$SOURCE/.chezmoi.toml.tmpl"

check "defaults declared for all four prompts (Review Focus #3)"
assert_grep 'promptStringOnce.*"name".*"Kulwant Singh"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptStringOnce.*"email".*"singh\.kulwant@gmx\.com"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptStringOnce.*"github_user".*"imkulwant"' "$SOURCE/.chezmoi.toml.tmpl"
assert_grep 'promptBoolOnce.*"work".*false' "$SOURCE/.chezmoi.toml.tmpl"

check ".chezmoidata.yaml has ask.endpoint and ssh.local_hosts"
assert_grep 'ask:' "$SOURCE/.chezmoidata.yaml"
assert_grep 'local_hosts:' "$SOURCE/.chezmoidata.yaml"

check "dot_gitconfig.tmpl uses templated identity"
assert_grep 'name = \{\{ \.name \}\}' "$SOURCE/dot_gitconfig.tmpl"
assert_grep 'email = \{\{ \.email \}\}' "$SOURCE/dot_gitconfig.tmpl"

check "VS Code settings.json is now a template"
assert_file "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json.tmpl"
assert_no_file "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json"

check "VS Code Java path uses chezmoi.homeDir"
assert_grep '\{\{ \.chezmoi\.homeDir \}\}/.local/share/mise/installs/java/temurin-21' \
  "$SOURCE/private_Library/private_Application Support/private_Code/User/settings.json.tmpl"
