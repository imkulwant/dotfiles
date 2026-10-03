#!/usr/bin/env bash
# Phase O — Perf safety net

phase_start "O" "Perf safety net"

SOURCE="$CHEZMOI_SOURCE"

check "hyperfine installed"
assert_cmd_ok "command -v hyperfine"

check "scripts/perf/shell-startup.sh exists and executable"
assert_file "$SOURCE/scripts/perf/shell-startup.sh"
assert_perm "$SOURCE/scripts/perf/shell-startup.sh" 755

check "justfile has profile-shell recipe"
assert_grep '^profile-shell:' "$SOURCE/justfile"

check "dot_zshrc.tmpl has ZSH_PROFILE guard pair"
assert_grep 'ZSH_PROFILE.*zmodload zsh/zprof' "$SOURCE/dot_zshrc.tmpl"
assert_grep 'ZSH_PROFILE.*zprof' "$SOURCE/dot_zshrc.tmpl"

check ".chezmoidata.yaml has perf.shell_budget_ms"
assert_grep 'shell_budget_ms:' "$SOURCE/.chezmoidata.yaml"

check "zsh startup mean under budget"
assert_cmd_ok "$SOURCE/scripts/perf/shell-startup.sh --budget-check"
