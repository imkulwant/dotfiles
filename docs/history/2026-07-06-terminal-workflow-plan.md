# Unified Chezmoi Overhaul + Terminal-Native Workflow Plan

Date: 2026-07-07
Repo: `~/.local/share/chezmoi` (`imkulwant/dotfiles`)
Merges: [`SWOT.md`](SWOT.md) (bug/design audit, 2026-07-06) and the terminal-native workflow plan (originally at `/Users/kulsin/terminal-workflow/terminal-workflow-implementation-plan.md`).
Executing agent: Claude Code (Opus 4.7, max effort).

## 0. Guiding principles

1. **chezmoi is the single install/config source of truth.** `chezmoi init --apply git@github.com:imkulwant/dotfiles.git` is the sole bootstrap from a fresh Mac. `install.sh` is deleted. Every config, every Brew formula, every macOS default, every language toolchain flows through the chezmoi source dir. No orphan configs in `$HOME`, no dual install paths.
2. **Fix before add.** SWOT bugs 1-18 must be resolved before we layer on the terminal-native workflow, or a fresh install will fail today. Phase C does the fixes; Phases D+ add the new stack.
3. **Phase-by-phase, stop for user confirmation.** No runaway multi-phase work. Present findings/diffs after each phase.
4. **Commit incrementally.** One logical unit per commit. Conventional commits per global CLAUDE.md; no auto co-author.
5. **CI catches drift.** The bugs SWOT flagged (BrewFile casing, install.sh path, version drift between Brewfile and VS Code settings, silent partial installs) would all have been caught by minimal CI. Build that in Phase J.
6. **R4 from global CLAUDE.md — define success first.** Every phase writes its verification code (`scripts/doctor/phase-X.sh`) as part of the deliverable. `just doctor` runs those checks any time. "Looks right" is not a success criterion.

---

## Phase A — Audit (read-only, no changes)

Reconcile SWOT's assumptions against the current tree and running environment. Produce a short audit report, stop for confirmation.

Cover:
- **chezmoi state**: `chezmoi source-path`, `chezmoi managed`, `chezmoi status`, `chezmoi diff`. Any source-vs-`$HOME` drift.
- **SWOT bug status**: verify bugs 1-18 still reproduce today. (Verified as of 2026-07-07: BrewFile casing, install.sh path, duplicated OMZ installs, `.chezmoiignore` vs `.chezmoiexternal.toml` contradiction, `.chezmoidata.yaml` no-op, `master` branch, missing LICENSE, `chsh` uses system zsh, no `set -euo pipefail`, `openjdk@24` reference in VS Code, `pyenv`+`pipx`+`python@3.13` coexistence, `v=nvim` alias with no nvim installed.)
- **Installed tooling**: `brew list --formula`, `brew list --cask`, `brew bundle check --file "$(chezmoi source-path)/Brewfile"`. `nvim --version` if present (need >= 0.10). `tmux -V` if present. `git --version`.
- **Shell config**: which OMZ plugins are actually loaded, which aliases/functions live only in `~/.aliases.zsh`, what PATH manipulations, existing eval hooks.
- **Git config**: `~/.gitconfig` identity, aliases, pager. `~/.config/lazygit/config.yml`.
- **Existing nvim config**: does `~/.config/nvim` exist? If yes, inventory. Decide preserve/backup/replace with the user before Phase G.
- **JDK management**: how `JAVA_HOME` is set today, which JDKs are installed and where, whether `sdkman` or `mise` are already on PATH.
- **Python management**: `pyenv`, `pipx`, `uv` status. What global CLAUDE.md mandates vs what's installed.

**Doctor checks (`scripts/doctor/phase-a.sh`)** — mostly informational (audit is read-only). Assertions kept minimal:
- chezmoi is installed (`assert_cmd_ok "chezmoi --version"`)
- chezmoi source path resolves to `~/.local/share/chezmoi`
- Prints inventory (not assertions): brew formula count, cask count, current shell, current branch, `chezmoi status` output

**Deliverable:** audit report (markdown) covering current state, decision points needing user input, list of files that will change in Phase C. **Stop for confirmation.**

---

## Phase B — Doctor infrastructure (scaffolding for all subsequent verification)

Build the sanity-check system that every later phase writes checks into. Without this, "did Phase C actually land?" is a manual grep session every time.

### Files created (managed by chezmoi so they travel with the repo)

```
scripts/doctor/
├── lib.sh              # assertion helpers, colored output, pass/fail counter
├── run.sh              # orchestrator (runs one/many/all phase checks)
├── phase-a.sh          # written now (audit sanity — mostly informational)
├── phase-c.sh          # placeholder — filled in Phase C
├── phase-d.sh          # placeholder — filled in Phase D
├── ... (through phase-n.sh)
```

### `lib.sh` API (bash functions — no external deps beyond `chezmoi`, `git`, `brew`)

```bash
phase_start "C" "Critical fixes"   # section header
phase_end                          # section footer + running count

check "<human name of check>"      # start a check line
pass                               # mark passed (auto by asserts)
fail "reason"                      # mark failed (auto by asserts)

# Auto-assertions — call check first, then one of these:
assert_file <path>
assert_no_file <path>
assert_grep <pattern> <file>
assert_no_grep <pattern> <file>
assert_cmd_ok <cmd...>
assert_cmd_out <cmd...> <expected-substring>
assert_perm <path> <mode>              # e.g. 600 for SSH config
assert_brew_installed <formula>
assert_brew_cask_installed <cask>

summary                            # final totals + exit 0/1
```

Design constraints:
- Pure bash — runs on the Ubuntu CI container and macOS.
- No color when `NO_COLOR=1` or when stdout is not a TTY (CI-friendly).
- Every assertion is idempotent and side-effect-free.

### `run.sh` orchestrator

```bash
scripts/doctor/run.sh              # all phases in order (a c d e f g h i j k l m n)
scripts/doctor/run.sh C            # only Phase C
scripts/doctor/run.sh C D G        # subset
```

Sources `lib.sh`, sources each requested `phase-X.sh`, calls `summary` at end. Exit 0 iff all pass.

### `justfile` (created here, extended in Phase J)

```just
doctor *phases='':
    scripts/doctor/run.sh {{phases}}
```

### Doctor checks (`scripts/doctor/phase-a.sh` — written now)

Written during this phase (Phase A's checks retroactively land here since we skipped writing them earlier):
- `chezmoi --version` succeeds
- `chezmoi source-path` returns `~/.local/share/chezmoi`
- (informational, not asserted) shell = zsh, brew count, current branch

### Verification

- `scripts/doctor/run.sh A` runs and passes.
- `scripts/doctor/run.sh` runs and passes (only Phase A has content; other phases are placeholders that print "not yet implemented" and pass — until Phase C+ fill them).

**Commit:** `feat(phaseB): doctor infrastructure - scripts/doctor + just doctor`

---

## Phase C — Critical fixes (was Phase B; SWOT Phase 0)

Address bugs that break a fresh install today. One commit per fix. **`phase-c.sh` doctor is written as fixes land** — each fix gets its assertion added the moment the fix commits.

1. **`BrewFile` -> `Brewfile` casing** in `run_onchange_install-brewfile.sh.tmpl:3`. (SWOT bug 1)
2. **Delete `install.sh`** entirely. `chezmoi init --apply` becomes the only bootstrap. Update README with the one-liner `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant`. (SWOT bugs 2, 3)
3. **Resolve duplicated OMZ/p10k installs.** Keep `.chezmoiexternal.toml` (declarative, pinned tarballs). Delete `.chezmoiscripts/run_once_before_30_install_ohmyzsh.sh.tmpl`, `run_once_before_40_install_powerlevel10k.sh.tmpl`, `run_once_before_ohmyzsh-plugins.sh.tmpl`. (SWOT bugs 4, 5)
4. **Pin `.chezmoiexternal.toml`** oh-my-zsh and plugin URLs to tags (not `master.tar.gz`) to remove unpinned-upstream risk. (SWOT threat #2)
5. **Reconcile `.chezmoiignore` vs `.chezmoiexternal.toml`.** Currently `.chezmoiignore` blocks `.oh-my-zsh/custom/*` but externals write into `.oh-my-zsh/custom/themes/powerlevel10k` and `.oh-my-zsh/custom/plugins/*`. Allow those specific paths. (SWOT bug 6)
6. **Fix VS Code `settings.json`** `openjdk@24` -> `openjdk@21`, `python@3.12` -> `python@3.13` (Phase I will move both to `mise` shim paths). (SWOT bugs 7, 8)
7. **Fix `chsh`** in `run_once_before_10_ensure_zsh.sh.tmpl` to use `/opt/homebrew/bin/zsh` (Homebrew zsh, not system 5.9). (SWOT bug 9)
8. **Add `set -euo pipefail`** to every `.chezmoiscripts/*.sh.tmpl` and any remaining `.sh.tmpl` at repo root. (SWOT bug 10, threat #1)
9. **Strip citation markers** `[1][2][3]` etc from `dot_aliases.zsh.tmpl`. (SWOT bug 11)
10. **`.chezmoidata.yaml`**: delete now (no-op); reintroduce in Phase L for per-host split. (SWOT bug 12)
11. **Add `.DS_Store` to `.chezmoiignore`.** Remove existing `.DS_Store` files from source tree. (SWOT threat #6)
12. **Add `LICENSE` (MIT).** `.chezmoiignore` already assumes one exists. (SWOT gap 26)
13. **Rename branch `master` -> `main`.** `git branch -m master main`; on GitHub, change default branch and update local upstream. (SWOT bug 18)

### Doctor checks (`scripts/doctor/phase-c.sh`)

```bash
phase_start "C" "Critical fixes"

check "run_onchange script references 'Brewfile' (correct casing)"
assert_grep '{{ .chezmoi.sourceDir }}/Brewfile' \
  "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

check "install.sh removed"
assert_no_file "$(chezmoi source-path)/install.sh"

check "Duplicated OMZ install script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_30_install_ohmyzsh.sh.tmpl"

check "Duplicated p10k install script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_40_install_powerlevel10k.sh.tmpl"

check "Duplicated OMZ plugins script removed"
assert_no_file "$(chezmoi source-path)/.chezmoiscripts/run_once_before_ohmyzsh-plugins.sh.tmpl"

check ".chezmoiexternal.toml pins oh-my-zsh to a tag (not master)"
assert_no_grep 'ohmyzsh/archive/master.tar.gz' \
  "$(chezmoi source-path)/.chezmoiexternal.toml"

check ".chezmoiignore does not block .oh-my-zsh/custom/themes and custom/plugins"
# Allow both to be either uncommented or specifically exempted
assert_no_grep '^\.oh-my-zsh/custom/\*$' "$(chezmoi source-path)/.chezmoiignore"

check "VS Code settings.json uses openjdk@21"
assert_no_grep 'openjdk@24' "$(chezmoi source-path)/private_Library/private_Application Support/Code/User/settings.json"

check "VS Code settings.json uses python@3.13"
assert_no_grep 'python@3.12' "$(chezmoi source-path)/private_Library/private_Application Support/Code/User/settings.json"

check "chsh uses Homebrew zsh"
assert_grep '/opt/homebrew/bin/zsh' \
  "$(chezmoi source-path)/.chezmoiscripts/run_once_before_10_ensure_zsh.sh.tmpl"

check "All .chezmoiscripts have set -euo pipefail"
for f in "$(chezmoi source-path)/.chezmoiscripts"/*.sh.tmpl; do
  assert_grep 'set -euo pipefail' "$f"
done

check "dot_aliases.zsh.tmpl has no citation markers"
assert_no_grep '\[[0-9]\+\]' "$(chezmoi source-path)/dot_aliases.zsh.tmpl"

check ".chezmoidata.yaml removed (no-op)"
assert_no_file "$(chezmoi source-path)/.chezmoidata.yaml"

check ".chezmoiignore blocks .DS_Store"
assert_grep 'DS_Store' "$(chezmoi source-path)/.chezmoiignore"

check "LICENSE exists"
assert_file "$(chezmoi source-path)/LICENSE"

check "Current branch is main"
assert_cmd_out "git -C $(chezmoi source-path) branch --show-current" "main"

phase_end
```

### Verification

- `just doctor C` returns 0
- `chezmoi apply --dry-run` succeeds; `chezmoi diff` clean after apply
- `brew bundle check` clean

---

## Phase D — Consolidated Brewfile (was Phase C)

Merge existing Brewfile with the terminal-workflow target list. Fix the `run_onchange_install-brewfile.sh.tmpl` (fixed in C) to include a SHA-based re-run trigger.

**Add formulae:** `neovim`, `tmux`, `ripgrep`, `fd`, `bat`, `eza`, `git-delta`, `atuin`, `starship`, `mise`, `gh`, `jq`, `yq`, `direnv`, `uv`, `lazygit`, `zoxide`, `btop`, `just` (task runner — powers `just doctor` from Phase B and CI in Phase J).

**Add casks:** `font-meslo-lg-nerd-font` (SWOT gap 23).

**Remove (deferred to Phase I completion):** `jenv`, `pyenv`, `pipx`.

**Keep for now:** `openjdk@21`, `maven` (mise takes over in Phase I, then `openjdk@21` gets removed).

**Ask user (optional):** `mas`, `tldr`, `dust`.

Update `run_onchange_install-brewfile.sh.tmpl`:
```bash
#!/bin/bash
set -euo pipefail
# Brewfile hash: {{ include "Brewfile" | sha256sum }}
brew bundle --file="{{ .chezmoi.sourceDir }}/Brewfile"
```

### Doctor checks (`scripts/doctor/phase-d.sh`)

```bash
phase_start "D" "Brewfile"

for formula in neovim tmux ripgrep fd bat eza git-delta atuin starship mise gh jq yq direnv uv lazygit zoxide btop just fzf; do
  check "Brewfile declares $formula"
  assert_grep "^brew \"$formula\"" "$(chezmoi source-path)/Brewfile"
done

check "Brewfile declares font-meslo-lg-nerd-font"
assert_grep 'font-meslo-lg-nerd-font' "$(chezmoi source-path)/Brewfile"

# Runtime checks
for formula in neovim tmux ripgrep fd bat eza git-delta atuin starship mise gh jq yq direnv uv lazygit zoxide btop just fzf; do
  check "$formula installed"
  assert_brew_installed "$formula"
done

check "nvim >= 0.10"
assert_cmd_out "nvim --version" "NVIM v0.1"      # matches v0.10, v0.11, ...

check "brew bundle check clean"
assert_cmd_ok "brew bundle check --file $(chezmoi source-path)/Brewfile"

check "run_onchange script contains SHA hash trigger"
assert_grep 'sha256sum' "$(chezmoi source-path)/run_onchange_install-brewfile.sh.tmpl"

phase_end
```

**Commit:** `feat(phaseD): consolidated Brewfile with modern CLI stack + nerd font`

---

## Phase E — Shell layer (was Phase D)

**Decision point (ask user):** keep OMZ as plugin-manager-only (theme off, starship takes prompt) or drop OMZ entirely. Recommended: keep OMZ, disable theme.

Rewrite `dot_zshrc.tmpl`:
- **Remove:** p10k instant prompt block, `ZSH_THEME`, `[[ -f ~/.p10k.zsh ]]`, `jenv init`, `EDITOR="code --wait"` → change to `nvim`.
- **Add hooks (order matters):**
  ```zsh
  eval "$(starship init zsh)"
  eval "$(zoxide init zsh)"
  eval "$(mise activate zsh)"
  eval "$(direnv hook zsh)"
  source <(fzf --zsh)               # fzf FIRST
  eval "$(atuin init zsh)"          # atuin LAST — claims Ctrl-R
  ```
- **Add env:**
  ```zsh
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
  export EDITOR="nvim"
  ```

Create `dot_config/starship.toml`: directory, git branch/status, java (mise-aware), cmd_duration. No modules that shell out per prompt.

Create `dot_config/atuin/config.toml`: `search_mode = "fuzzy"`, sync off. Run `atuin import zsh` once to seed.

Refresh `dot_aliases.zsh.tmpl` (citation markers already gone from C):
```zsh
alias ls='eza --icons --git'
alias ll='eza -la --icons --git'
alias cat='bat --paging=never'
alias lg='lazygit'
alias v='nvim'
```

### Doctor checks (`scripts/doctor/phase-e.sh`)

```bash
phase_start "E" "Shell layer"

check "dot_zshrc.tmpl no longer sets Powerlevel10k theme"
assert_no_grep 'ZSH_THEME="powerlevel10k' "$(chezmoi source-path)/dot_zshrc.tmpl"

check "dot_zshrc.tmpl no longer sources ~/.p10k.zsh"
assert_no_grep 'source ~/.p10k.zsh' "$(chezmoi source-path)/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes starship"
assert_grep 'starship init zsh' "$(chezmoi source-path)/dot_zshrc.tmpl"

check "dot_zshrc.tmpl initializes zoxide, mise, direnv, atuin"
for hook in 'zoxide init zsh' 'mise activate zsh' 'direnv hook zsh' 'atuin init zsh'; do
  assert_grep "$hook" "$(chezmoi source-path)/dot_zshrc.tmpl"
done

check "fzf is sourced BEFORE atuin init (Ctrl-R conflict)"
awk '/fzf --zsh/{f=NR} /atuin init/{a=NR} END{exit !(f && a && f<a)}' \
  "$(chezmoi source-path)/dot_zshrc.tmpl" && pass || fail "atuin init must come after fzf"

check "dot_zshrc.tmpl no longer runs jenv init"
assert_no_grep 'jenv init' "$(chezmoi source-path)/dot_zshrc.tmpl"

check "EDITOR is nvim, not code"
assert_grep 'EDITOR="nvim"' "$(chezmoi source-path)/dot_zshrc.tmpl"

check "starship.toml exists"
assert_file "$(chezmoi source-path)/dot_config/starship.toml"

check "atuin/config.toml exists"
assert_file "$(chezmoi source-path)/dot_config/atuin/config.toml"

# Runtime — shell must have applied
check "Interactive zsh has starship prompt (STARSHIP_SHELL set)"
assert_cmd_ok "zsh -i -c 'test -n \"\$STARSHIP_SHELL\"'"

check "Interactive zsh has zoxide function 'z'"
assert_cmd_ok "zsh -i -c 'type z >/dev/null'"

check "Interactive zsh has v=nvim alias"
assert_cmd_out "zsh -i -c 'alias v'" "nvim"

check "Shell startup under 500ms (SWOT target: 300ms)"
start=$(date +%s%N); zsh -i -c exit; end=$(date +%s%N)
duration_ms=$(( (end - start) / 1000000 ))
[ "$duration_ms" -lt 500 ] && pass || fail "startup took ${duration_ms}ms"

phase_end
```

Manual verification (can't script cleanly): press Ctrl-R and confirm atuin's UI opens; press Ctrl-T and confirm fzf's file picker with bat preview.

**Commit:** `feat(phaseE): shell layer — starship, atuin, fzf/fd/bat, zoxide, mise, direnv`

---

## Phase F — tmux (was Phase E)

Create `dot_config/tmux/tmux.conf` (see original plan for full content). Key items:
- `C-a` prefix, mouse on, base-index 1, `escape-time 0`, true color via `terminal-overrides`
- `|`/`-` splits with `-c "#{pane_current_path}"`, vim pane nav, reload binding

Document convention: one named session per project. Defer tpm/resurrect/sesh.

### Doctor checks (`scripts/doctor/phase-f.sh`)

```bash
phase_start "F" "tmux"

check "tmux.conf exists"
assert_file "$(chezmoi source-path)/dot_config/tmux/tmux.conf"

check "tmux.conf sets escape-time 0 (nvim ESC latency)"
assert_grep 'escape-time 0' "$(chezmoi source-path)/dot_config/tmux/tmux.conf"

check "tmux.conf enables true color via terminal-overrides"
assert_grep 'RGB' "$(chezmoi source-path)/dot_config/tmux/tmux.conf"

check "tmux.conf uses C-a prefix"
assert_grep 'set -g prefix C-a' "$(chezmoi source-path)/dot_config/tmux/tmux.conf"

check "tmux.conf enables mouse"
assert_grep 'set -g mouse on' "$(chezmoi source-path)/dot_config/tmux/tmux.conf"

check "tmux runtime advertises true color (Tc flag)"
# Only meaningful inside a tmux session; skip cleanly outside.
if [ -n "${TMUX:-}" ]; then
  assert_cmd_ok "tmux info | grep -q 'Tc: (flag) true'"
else
  echo "  (skipped — not inside a tmux session)"
fi

phase_end
```

**Commit:** `feat(phaseF): tmux config — vim-friendly, true color, per-project sessions`

---

## Phase G — Neovim (was Phase F)

Back up any pre-existing `~/.config/nvim` from Phase A. Bootstrap kickstart.nvim, strip `.git`, `chezmoi add -r ~/.config/nvim`. Track `lazy-lock.json`; never track `~/.local/share/nvim`.

Mason LSPs: `lua_ls`, `yamlls` (schema store), `bashls`, `jsonls`, `marksman`. **No `jdtls`.** Ask about `pyright`. Treesitter: `bash, yaml, json, lua, markdown, java, python, dockerfile`. Add `harpoon2` and `<leader>gg` → lazygit float.

### Doctor checks (`scripts/doctor/phase-g.sh`)

```bash
phase_start "G" "Neovim"

check "~/.config/nvim managed by chezmoi"
assert_cmd_out "chezmoi managed" ".config/nvim/init.lua"

check "lazy-lock.json tracked"
assert_file "$HOME/.config/nvim/lazy-lock.json"

check "nvim :checkhealth has no ERRORs"
assert_cmd_ok "nvim --headless '+checkhealth' +qa 2>&1 | grep -c ERROR | grep -qx 0"

for lsp in lua-language-server yaml-language-server bash-language-server marksman; do
  check "Mason installed $lsp"
  assert_file "$HOME/.local/share/nvim/mason/bin/$lsp"
done

check "jdtls NOT installed via Mason (Java stays in IntelliJ)"
assert_no_file "$HOME/.local/share/nvim/mason/bin/jdtls"

check "harpoon2 pinned in lazy-lock.json"
assert_grep 'harpoon' "$HOME/.config/nvim/lazy-lock.json"

for parser in bash yaml json lua markdown java python dockerfile; do
  check "Treesitter parser $parser installed"
  assert_file "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser/$parser.so"
done

check "chezmoi diff for nvim is clean"
assert_cmd_ok "chezmoi diff ~/.config/nvim | wc -l | grep -qx 0"

phase_end
```

**Commit sequence:** kickstart base → Mason LSPs → harpoon + lazygit binding (separate commits).

---

## Phase H — Git + SSH (was Phase G)

Create `dot_gitconfig.tmpl` (identity, `pull.rebase=true`, `init.defaultBranch=main`, delta, zdiff3). Create `private_dot_ssh/config.tmpl` (0600 perms, `UseKeychain`, `AddKeysToAgent`, `IdentitiesOnly`). Update `dot_config/lazygit/config.yml` for delta pager. Hand off `gh auth login` interactively.

### Doctor checks (`scripts/doctor/phase-h.sh`)

```bash
phase_start "H" "Git + SSH"

check "git user.email is set"
assert_cmd_ok "git config --get user.email"

check "git user.name is set"
assert_cmd_ok "git config --get user.name"

check "git init.defaultBranch is main"
assert_cmd_out "git config --get init.defaultBranch" "main"

check "git pull.rebase is true"
assert_cmd_out "git config --get pull.rebase" "true"

check "git push.autoSetupRemote is true"
assert_cmd_out "git config --get push.autoSetupRemote" "true"

check "git rerere.enabled is true"
assert_cmd_out "git config --get rerere.enabled" "true"

check "git core.pager is delta"
assert_cmd_out "git config --get core.pager" "delta"

check "git delta side-by-side enabled"
assert_cmd_out "git config --get delta.side-by-side" "true"

check "git merge.conflictstyle is zdiff3"
assert_cmd_out "git config --get merge.conflictstyle" "zdiff3"

check "~/.ssh/config exists"
assert_file "$HOME/.ssh/config"

check "~/.ssh/config has 0600 perms"
assert_perm "$HOME/.ssh/config" 600

check "~/.ssh/config enables UseKeychain"
assert_grep 'UseKeychain yes' "$HOME/.ssh/config"

check "~/.ssh/config enables IdentitiesOnly"
assert_grep 'IdentitiesOnly yes' "$HOME/.ssh/config"

check "lazygit config uses delta pager"
assert_grep 'pager: delta' "$HOME/.config/lazygit/config.yml"

check "gh CLI authenticated (interactive step complete)"
assert_cmd_ok "gh auth status"

phase_end
```

**Commit:** `feat(phaseH): managed gitconfig+sshconfig, delta pager, lazygit`

---

## Phase I — Language toolchains: mise + uv (was Phase H)

- `mise use -g java@temurin-21`
- Remove `jenv` state; `uv` replaces pyenv/pipx
- VS Code `settings.json` -> mise shim paths
- IntelliJ pointed at mise-managed JDKs (documented in `docs/CHOICES.md`)
- `templates/.mise.toml` and `templates/.envrc` in the repo (not applied to `$HOME`)
- Remove `openjdk@21`, `jenv`, `pyenv`, `pipx` from Brewfile

### Doctor checks (`scripts/doctor/phase-i.sh`)

```bash
phase_start "I" "mise + uv"

check "mise installed"
assert_cmd_ok "mise --version"

check "mise has global java 21"
assert_cmd_out "mise ls java" "temurin-21"

check "mise-managed java on PATH"
assert_cmd_out "mise which java" "mise/installs/java"

check "uv installed"
assert_cmd_ok "uv --version"

check "jenv no longer installed via brew"
assert_cmd_ok "! brew list --formula | grep -qx jenv"

check "pyenv no longer installed via brew"
assert_cmd_ok "! brew list --formula | grep -qx pyenv"

check "pipx no longer installed via brew"
assert_cmd_ok "! brew list --formula | grep -qx pipx"

check "Brewfile no longer declares jenv/pyenv/pipx/openjdk"
for tool in jenv pyenv pipx 'openjdk@21'; do
  assert_no_grep "^brew \"$tool\"" "$(chezmoi source-path)/Brewfile"
done

check "VS Code settings.json points at mise shim paths"
assert_grep 'mise/installs' \
  "$(chezmoi source-path)/private_Library/private_Application Support/Code/User/settings.json"

check "templates/.mise.toml exists"
assert_file "$(chezmoi source-path)/templates/.mise.toml"

check "templates/.envrc exists"
assert_file "$(chezmoi source-path)/templates/.envrc"

phase_end
```

**Commit sequence:** migrate to mise → migrate to uv → clean Brewfile → docs.

---

## Phase J — CI + hygiene (was Phase I)

- `.pre-commit-config.yaml`: shellcheck, shfmt, trailing-whitespace, end-of-file-fixer, check-added-large-files, check-merge-conflict
- `.github/workflows/ci.yml`: shellcheck + shfmt + `chezmoi execute-template` + `chezmoi apply --dry-run` + **`just doctor`** in Linux container + grep-formulae-vs-Brewfile check
- Extend `justfile` with `apply`, `verify`, `doctor` (already there), `update`

### Doctor checks (`scripts/doctor/phase-j.sh`)

```bash
phase_start "J" "CI + hygiene"

check ".pre-commit-config.yaml exists"
assert_file "$(chezmoi source-path)/.pre-commit-config.yaml"

check ".pre-commit config includes shellcheck"
assert_grep 'shellcheck' "$(chezmoi source-path)/.pre-commit-config.yaml"

check ".pre-commit config includes shfmt"
assert_grep 'shfmt' "$(chezmoi source-path)/.pre-commit-config.yaml"

check "GitHub Actions workflow exists"
assert_file "$(chezmoi source-path)/.github/workflows/ci.yml"

check "CI workflow runs just doctor"
assert_grep 'just doctor' "$(chezmoi source-path)/.github/workflows/ci.yml"

check "CI workflow runs shellcheck"
assert_grep 'shellcheck' "$(chezmoi source-path)/.github/workflows/ci.yml"

check "CI workflow runs chezmoi apply --dry-run"
assert_grep 'chezmoi apply --dry-run' "$(chezmoi source-path)/.github/workflows/ci.yml"

check "justfile exposes apply / verify / doctor / update"
for target in apply verify doctor update; do
  assert_grep "^${target}" "$(chezmoi source-path)/justfile"
done

check "pre-commit installed and hooks registered"
assert_cmd_ok "pre-commit --version"

check "No managed file references a formula missing from Brewfile"
# Grep every managed file for /opt/homebrew/opt/<formula> and check against Brewfile.
"$(chezmoi source-path)/scripts/doctor/formula-drift-check.sh" && pass || fail "found formula references not in Brewfile"

phase_end
```

**Commit:** `chore(phaseJ): pre-commit, GHA CI, justfile task runner + doctor in CI`

---

## Phase K — macOS defaults (was Phase J, optional but recommended)

`.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl` with an opinionated set (ask user for the list before writing).

### Doctor checks (`scripts/doctor/phase-k.sh`)

```bash
phase_start "K" "macOS defaults"

check "run_onchange_macos_defaults script exists"
assert_file "$(chezmoi source-path)/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"

check "script has set -euo pipefail"
assert_grep 'set -euo pipefail' "$(chezmoi source-path)/.chezmoiscripts/run_onchange_macos_defaults.sh.tmpl"

# Sample specific checks (depend on what user opts into):
check "Dock autohide is on"
assert_cmd_out "defaults read com.apple.dock autohide" "1"

check "Finder shows hidden files"
assert_cmd_out "defaults read com.apple.finder AppleShowAllFiles" "1"

check "Screenshots go to ~/Downloads/Screenshots"
assert_cmd_out "defaults read com.apple.screencapture location" "Downloads/Screenshots"

phase_end
```

**Commit:** `feat(phaseK): opinionated macOS defaults`

---

## Phase L — Advanced (was Phase K, opt-in; ask which)

Options:
- Secrets via 1Password CLI or `age`
- Per-host templating (`.chezmoi.hostname` + `data.work` boolean; reintroduce `.chezmoidata.yaml`)
- launchd auto-update

Each is an independent commit.

### Doctor checks (`scripts/doctor/phase-l.sh`)

Each check is conditional — only runs if the corresponding sub-feature was opted into.

```bash
phase_start "L" "Advanced (conditional)"

# Only if secrets enabled:
if grep -q 'onepasswordRead\|age' "$(chezmoi source-path)"/*.tmpl 2>/dev/null; then
  check "op CLI installed"
  assert_cmd_ok "op --version"

  check "chezmoi can read at least one templated secret"
  assert_cmd_ok "chezmoi execute-template '{{ onepasswordRead \"op://Personal/GitHub Token/token\" }}'"
fi

# Only if per-host templating enabled:
if [ -f "$(chezmoi source-path)/.chezmoidata.yaml" ]; then
  check ".chezmoidata.yaml defines host-scoped data"
  assert_grep 'work\|hostname' "$(chezmoi source-path)/.chezmoidata.yaml"
fi

# Only if launchd auto-update enabled:
if launchctl list 2>/dev/null | grep -q chezmoi-update; then
  check "chezmoi-update launchd agent loaded"
  assert_cmd_ok "launchctl list | grep -q chezmoi-update"
fi

phase_end
```

**Commit:** one per sub-feature.

---

## Phase M — Documentation (was Phase L)

- Rewrite `README.md` as a design doc (bootstrap one-liner, layout, choices)
- Move existing cheatsheet content to `docs/chezmoi-cheatsheet.md`
- Add `docs/CHOICES.md`
- Archive originals to `docs/history/` (from housekeeping section)

### Doctor checks (`scripts/doctor/phase-m.sh`)

```bash
phase_start "M" "Documentation"

check "README.md exists"
assert_file "$(chezmoi source-path)/README.md"

check "README.md contains bootstrap one-liner"
assert_grep 'chezmoi init --apply' "$(chezmoi source-path)/README.md"

check "docs/CHOICES.md exists"
assert_file "$(chezmoi source-path)/docs/CHOICES.md"

check "docs/chezmoi-cheatsheet.md exists"
assert_file "$(chezmoi source-path)/docs/chezmoi-cheatsheet.md"

check "docs/history/ archived originals"
assert_file "$(chezmoi source-path)/docs/history/2026-07-06-terminal-workflow-plan.md"
assert_file "$(chezmoi source-path)/docs/history/2026-07-06-swot.md"

check "README.md is non-trivial (>200 lines)"
assert_cmd_ok "[ \"\$(wc -l < $(chezmoi source-path)/README.md)\" -gt 200 ]"

phase_end
```

**Commit:** `docs(phaseM): design-doc README, choices doc, chezmoi cheatsheet`

---

## Phase N — Final verification (was Phase M)

The whole point of this phase is a single command:

```bash
$ just doctor
```

which runs every `scripts/doctor/phase-*.sh` in order and reports pass/fail. Exit 0 means the environment matches the plan.

### Doctor checks (`scripts/doctor/phase-n.sh`)

Cross-cutting integration checks that don't belong to any single earlier phase:

```bash
phase_start "N" "Integration"

check "chezmoi diff is empty"
assert_cmd_ok "[ -z \"\$(chezmoi diff)\" ]"

check "chezmoi status is clean"
assert_cmd_ok "[ -z \"\$(chezmoi status)\" ]"

check "chezmoi verify passes"
assert_cmd_ok "chezmoi verify"

check "brew bundle check clean"
assert_cmd_ok "brew bundle check --file $(chezmoi source-path)/Brewfile"

check "shellcheck clean on all .sh files in source dir"
assert_cmd_ok "find $(chezmoi source-path) -name '*.sh' -exec shellcheck {} +"

check "No managed file references a formula not in Brewfile"
assert_cmd_ok "$(chezmoi source-path)/scripts/doctor/formula-drift-check.sh"

# Manual checklist (not asserted — printed as reminders)
echo ""
echo "  Manual checks to eyeball:"
echo "    - Fresh terminal renders Nerd Font glyphs in starship"
echo "    - Ctrl-R opens atuin UI (not fzf, not zsh default)"
echo "    - Ctrl-T opens fzf file picker with bat preview"
echo "    - tmux + nvim inside it — true color; ESC latency imperceptible"
echo "    - VS Code opens a Java file with no 'interpreter not found' prompt"

phase_end
```

**Verification checklist (merged from both source plans):**
- `just doctor` returns 0 with all phases passing
- Fresh shell <300ms
- Nerd Font glyphs visible on first launch
- `chezmoi init --apply` in a scratch `$HOME` reproduces the environment (optional, Ubuntu container works for lint parts)

---

## Housekeeping (do alongside Phase A)

- Create `~/.local/share/chezmoi/docs/history/`
- Copy `/Users/kulsin/terminal-workflow/terminal-workflow-implementation-plan.md` -> `docs/history/2026-07-06-terminal-workflow-plan.md`
- Move `~/.local/share/chezmoi/SWOT.md` -> `docs/history/2026-07-06-swot.md`
- After user confirmation, `rm -rf /Users/kulsin/terminal-workflow/`
- This plan itself lives at `~/.local/share/chezmoi/OVERHAUL_PLAN.md`

---

## Deferred (do not implement now)

tmux plugin manager + resurrect/continuum + sesh; WezTerm/Ghostty/Kitty; nvim-jdtls; atuin sync; yazi; k9s companions; restic/backup; public dotfiles.

---

## Success criteria for the overhaul

1. Single command (`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant`) reproduces the whole environment on a fresh Mac.
2. Every SWOT bug 1-18 has a corresponding commit resolving it AND a doctor check preventing regression.
3. `just doctor` returns 0 on a healthy setup, and pinpoints exactly which phase's expectation broke on a regressed one.
4. CI (Phase J) runs `just doctor` on every push and fails the build on any regression.
5. No config file lives outside `~/.local/share/chezmoi` (except `~/.local/share/nvim` plugin state and `~/.local/share/mise/installs/`, both tool-managed).

---

## Notes on scope discipline

- **R1 (verify, don't guess):** Every phase starts with checking what's actually there. Phase A is the top-level version; each phase re-verifies in its doctor checks.
- **R2 (simplest working):** Doctor system is plain bash + colored output, no BATS or Python. `~/.p10k.zsh` stays as-is (regenerated by `p10k configure`) if we keep p10k as fallback; delete when starship is validated.
- **R3 (stay on task):** Bugs SWOT flagged but that aren't in a phase (e.g. VS Code Settings Sync conflict, SWOT gap 25) get noted in `docs/CHOICES.md` and not fixed here.
- **R4 (define success first):** Every phase's success = its doctor check passing. Doctor checks are written AS the phase lands, not after.
