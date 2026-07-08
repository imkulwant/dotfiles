#!/usr/bin/env bash
# Phase F — tmux

phase_start "F" "tmux"

SOURCE="$(chezmoi source-path)"

check "tmux.conf exists in chezmoi source"
assert_file "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf sets escape-time 0 (nvim ESC latency)"
assert_grep 'escape-time 0' "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf enables true color via terminal-overrides"
assert_grep 'RGB|Tc' "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf uses C-a prefix"
assert_grep 'set -g prefix C-a' "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf enables mouse"
assert_grep 'set -g mouse on' "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf uses | and - for splits"
assert_grep "bind | split-window" "$SOURCE/dot_config/tmux/tmux.conf"
assert_grep "bind - split-window" "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf has vim pane navigation"
assert_grep 'bind h select-pane -L' "$SOURCE/dot_config/tmux/tmux.conf"

check "tmux.conf has reload binding"
assert_grep 'source-file' "$SOURCE/dot_config/tmux/tmux.conf"

check "~/.config/tmux/tmux.conf applied"
assert_file "$HOME/.config/tmux/tmux.conf"

# Runtime check only meaningful inside a tmux session
if [ -n "${TMUX:-}" ]; then
  check "tmux runtime advertises true color (Tc flag)"
  assert_cmd_ok "tmux info | grep -q 'Tc: (flag) true'"
else
  info "(true color runtime check skipped — not inside a tmux session)"
fi

phase_end
