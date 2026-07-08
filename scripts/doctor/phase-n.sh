#!/usr/bin/env bash
# Phase N — Final integration verification

phase_start "N" "Final verification"

SOURCE="$(chezmoi source-path)"

# ── Dotfile state ─────────────────────────────────────────────────────────────
# Scripts (run_once state tied to content hash) and externals (OMZ auto-updates)
# are intentionally excluded: their drift is structural, not a sign of breakage.
check "chezmoi diff is clean (dotfiles only, excluding scripts + externals)"
assert_cmd_ok "[ -z \"\$(chezmoi diff --exclude=scripts,externals 2>/dev/null)\" ]"

# ── Brewfile ──────────────────────────────────────────────────────────────────
check "brew bundle check clean"
assert_cmd_ok "brew bundle check --file \"$SOURCE/Brewfile\" --no-upgrade 2>/dev/null"

# ── Static analysis ───────────────────────────────────────────────────────────
check "shellcheck passes on all doctor scripts"
assert_cmd_ok "find \"$SOURCE/scripts/doctor\" -name '*.sh' -exec shellcheck --severity=warning {} +"

check "formula-drift-check passes"
assert_cmd_ok "\"$SOURCE/scripts/doctor/formula-drift-check.sh\""

# ── Manual checklist (printed, not asserted) ──────────────────────────────────
printf "\n  %sManual checks to eyeball:%s\n" "${C_BOLD:-}" "${C_RESET:-}"
printf "    - Fresh terminal renders Nerd Font glyphs in starship prompt\n"
printf "    - Ctrl-R opens atuin (not fzf, not zsh default)\n"
printf "    - Ctrl-T opens fzf file picker with bat preview\n"
printf "    - tmux + nvim inside it: true color, ESC latency imperceptible\n"
printf "    - VS Code opens a Java file with no 'interpreter not found' prompt\n"
printf "    - chezmoi-update launchd agent fires at 09:00 (check ~/Library/Logs/chezmoi-update.log)\n"

phase_end
