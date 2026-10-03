# Dotfiles v2 — Perf safety net, portability, and automation

Date: 2026-10-03
Repo: `~/.local/share/chezmoi` (`imkulwant/dotfiles`)
Status: Draft, pending user approval → `writing-plans` handoff
Builds on: [`docs/history/2026-07-06-terminal-workflow-plan.md`](../history/2026-07-06-terminal-workflow-plan.md) (v1, phases A–N, completed 2026-07-08)

---

## 0. Context

Phases A–N of the v1 overhaul landed cleanly (`just doctor` ⇒ 227/227 across 14 phases). Since then four follow-up commits have patched the edges:

- `cf7602a perf(zshrc)` — dropped oh-my-zsh as a plugin manager and lazy-loaded mise. Measured steady-state `zsh -i -c exit` ≈ 90 ms (first invocation ≈ 260 ms).
- `f55ba1a fix(launchd)` — made failed bootstrap non-fatal on MDM-locked hosts.
- `7fdf67c fix(launchd)` — fall back to `user/<uid>` when `gui/<uid>` fails.
- `138fa63 feat(aliases)` — `python → python3` alias.

v2 is intentionally small. The surface area already does what it's supposed to; v2 hardens three remaining gaps and adds one new user-facing capability:

1. **Perf safety net** — prevent regressions in shell startup now that it is fast.
2. **Portability** — zero hardcoded `kulsin` in managed files so a fresh work-Mac bring-up under a different username is clean.
3. **Lifecycle** — a polished install wrapper, a safe uninstall, and a browsable "what you get" inventory.
4. **Automation & upkeep** — one-command maintenance; opt-in weekly background upkeep.

Everything else that came up during design — 1Password/age secrets, AI editor plugins, Intel Mac support, Linux parity, expanded macOS defaults, iTerm2 profile tracking — is captured in [§7 Future work](#7-future-work) and deliberately deferred.

---

## 1. Guiding principles (delta from v1)

v1's principles still apply. v2 adds two:

- **Nothing new regresses what's done.** Every phase lands with doctor coverage. Phase O is explicitly a regression guard.
- **Portability is enforced, not advised.** Grep guards in Phase P's doctor refuse `kulsin`, `/Users/kulsin`, or the personal email anywhere outside `docs/`. Policy that can be checked beats policy on a wiki.

Shared with v1: one logical commit per unit, conventional commits, no auto co-author, R4 (define success before implementation).

---

## 2. Scope summary

| Phase | Scope | Doctor checks | Weight |
|-------|-------|---------------|--------|
| O | Perf safety net | ~6 | Small |
| P | Portability (multi-username / multi-host) | ~10 | Medium |
| R | Lifecycle (install polish, uninstall, features index) | ~8 | Medium |
| Q | Automation & upkeep | ~8 | Medium |

Recommended landing order (see §6): **O → P → R → Q**. Phases are otherwise independent.

---

## 3. Phase O — Perf safety net

### 3.1 Goals

- Catch future shell-startup regressions early, locally.
- Make it trivial to profile when something *does* slow down.

### 3.2 Deliverables

1. **`scripts/perf/shell-startup.sh`** — benchmarks `zsh -i -c exit` with hyperfine:
   ```bash
   hyperfine --warmup 3 --min-runs 10 -N --export-json "$(mktemp)" 'zsh -i -c exit'
   ```
   Prints mean / median / stddev; always exits 0. Budget enforcement lives in doctor (which runs the same benchmark into its own tempfile and reads back `mean`).
2. **`justfile`** gains `profile-shell` recipe that invokes the script.
3. **`.chezmoidata.yaml`** gains:
   ```yaml
   perf:
     shell_budget_ms: 200
   ```
   Measured steady is 90 ms; 200 ms gives 2× headroom without being so loose it hides real regressions.
4. **`dot_zshrc.tmpl`** opt-in profiler. Top of file:
   ```zsh
   [[ -n "${ZSH_PROFILE:-}" ]] && zmodload zsh/zprof
   ```
   Bottom of file:
   ```zsh
   [[ -n "${ZSH_PROFILE:-}" ]] && zprof
   ```
   Zero cost when the env var is unset.
5. **`Brewfile`** gains `brew "hyperfine"` under the *CI & code quality* group.
6. **`README.md`** gets a one-block addition under *Day-to-day*: `just profile-shell` and `ZSH_PROFILE=1 zsh`.

### 3.3 Doctor checks (`scripts/doctor/phase-o.sh`)

~6 asserts:
- `hyperfine` present on `PATH`.
- `scripts/perf/shell-startup.sh` exists, executable, shellcheck-clean, has `set -euo pipefail`.
- `justfile` has a `profile-shell` recipe.
- `dot_zshrc.tmpl` contains both the `zmodload zsh/zprof` guard and the matching `zprof` call.
- `.chezmoidata.yaml` has `perf.shell_budget_ms` key, integer, `≤ 500`.
- **Budget assertion**: run the benchmark, parse `--export-json`, fail if mean > budget. Error output includes the hyperfine summary and a `ZSH_PROFILE=1 zsh` hint.

### 3.4 CI

Unchanged. CI doesn't have HOME applied, so the budget assertion is local-only. Lint job continues to shellcheck the new script.

### 3.5 Exit criteria

- `just doctor O` returns 0 on a fully-applied machine.
- `just profile-shell` works and reports a sensible number.
- Setting `ZSH_PROFILE=1 zsh` produces zprof output; unset: no output, no overhead.

### 3.6 Risks

- Hyperfine on a loaded machine (Spotlight indexing, Time Machine) can push the mean up. The `--warmup 3` + 10-run median mitigates this. If still flaky, raise the budget rather than disable the check.

---

## 4. Phase P — Portability (multi-username, multi-host)

### 4.1 Goals

Zero hardcoded `kulsin` in managed files. `chezmoi init --apply imkulwant` on a fresh work-Mac with a different Unix username finishes clean, with a different git identity, without edits to any committed file.

### 4.2 Current state — hardcoded references (from grep audit)

Seven real sites (confirmed 2026-10-03):

1. `private_Library/private_Application Support/private_Code/User/settings.json:76` — `/Users/kulsin/.local/share/mise/installs/java/temurin-21`.
2. `private_Library/LaunchAgents/com.kulsin.chezmoi-update.plist.tmpl:6` — `<string>com.kulsin.chezmoi-update</string>` (Label).
3. `private_Library/LaunchAgents/com.kulsin.chezmoi-update.plist.tmpl` — **filename** itself contains `kulsin`.
4. `.chezmoiscripts/run_onchange_load_chezmoi_launchd.sh.tmpl` — PLIST path, LABEL constant, and hash-include reference.
5. `scripts/doctor/phase-l.sh:17,20` — two asserts reference the hardcoded plist.
6. `private_dot_ssh/private_config.tmpl:19` — `User kulsin` on the `caduceus` LAN host. *This is a remote-machine username, not the local Mac username.*
7. `dot_gitconfig.tmpl:2-3` — `name = Kulwant Singh`, `email = singh.kulwant@gmx.com`.

Plus one hardcoded LAN IP: `dot_zshrc.tmpl` `ask()` function → `http://192.168.0.198:11434`.

### 4.3 Deliverables

#### A. Prompt-driven first-run config — `.chezmoi.toml.tmpl`

New top-level file (lives in source, templated, not applied to HOME):

```toml
{{- $name := promptStringOnce . "name" "Full name for git identity" "Kulwant Singh" -}}
{{- $email := promptStringOnce . "email" "Email for git identity" "singh.kulwant@gmx.com" -}}
{{- $github := promptStringOnce . "github_user" "GitHub username" "imkulwant" -}}
{{- $work := promptBoolOnce . "work" "Is this a work machine?" false -}}

[data]
name = {{ $name | quote }}
email = {{ $email | quote }}
github_user = {{ $github | quote }}
work = {{ $work }}
```

Rendered to `~/.config/chezmoi/chezmoi.toml` on first `chezmoi init`. Not tracked. Values accessible as `{{ .name }}`, `{{ .email }}`, `{{ .github_user }}`, `{{ .work }}`.

#### B. Template the seven sites

- **`dot_gitconfig.tmpl`**:
  ```
  [user]
      name = {{ .name }}
      email = {{ .email }}
  ```
- **VS Code `settings.json`** → add `.tmpl` suffix. Java path becomes `{{ .chezmoi.homeDir }}/.local/share/mise/installs/java/temurin-21`.
- **Rename plist**: `com.kulsin.chezmoi-update.plist.tmpl` → `local.chezmoi-update.plist.tmpl`. `<Label>` becomes `local.chezmoi-update`. Also template the binary path: `{{ lookPath "chezmoi" }}` instead of hardcoded `/opt/homebrew/bin/chezmoi` (future-proofs for Intel Macs — zero-cost on Apple Silicon).
- **`.chezmoiscripts/run_onchange_load_chezmoi_launchd.sh.tmpl`**:
  - Update `PLIST`, `LABEL`, and the `include "..."|sha256sum` include to the new filename.
  - **Prepend** a legacy-cleanup line (handles personal-Mac upgrade):
    ```bash
    launchctl bootout "gui/$UID" com.kulsin.chezmoi-update 2>/dev/null || true
    ```
- **`scripts/doctor/phase-l.sh`** — update the two asserts to the new plist name.
- **`dot_zshrc.tmpl`** `ask()` function reads endpoint from data:
  ```zsh
  ask() {
    local endpoint='{{ .ask.endpoint }}'
    [[ -z "$endpoint" ]] && { echo "ask: configure ask.endpoint in ~/.config/chezmoi/chezmoi.toml"; return 1; }
    curl -s "$endpoint/api/generate" -d "{\"model\":\"qwen3.5:0.8b\",\"prompt\":\"$1\",\"stream\":false}" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['response'])"
  }
  ```
- **`private_dot_ssh/private_config.tmpl`** — `caduceus` block templated from `.chezmoidata.yaml`:
  ```
  {{- range $alias, $cfg := .ssh.local_hosts }}
  Host {{ $alias }}
      HostName {{ $cfg.host }}
      User {{ $cfg.user }}
  {{ end }}
  ```

#### C. `.chezmoidata.yaml` additions

```yaml
# Existing:
work: false
# New:
ask:
  endpoint: ""              # personal Mac sets this in ~/.config/chezmoi/chezmoi.toml
ssh:
  local_hosts:
    caduceus:
      host: 192.168.0.100
      user: kulsin
```

The `caduceus.user` stays `kulsin` here because it's the username *on the remote machine*. If a work Mac wants different local-hosts, override `ssh.local_hosts` to `{}` or a different map via the local `~/.config/chezmoi/chezmoi.toml`.

#### D. Oh-my-zsh dead-code cleanup

Current state: `dot_zshrc.tmpl` sources plugins from `$HOME/.oh-my-zsh/custom/plugins/` but doesn't use the OMZ runtime (dropped in `cf7602a`). The `.chezmoiexternal.toml` still pulls the full OMZ tarball and the p10k theme — both unreachable code.

Changes:
- Remove `.oh-my-zsh` and `powerlevel10k` entries from `.chezmoiexternal.toml`.
- Repoint `zsh-syntax-highlighting` and `zsh-autosuggestions` externals to `.local/share/zsh-plugins/<name>/`.
- Update `dot_zshrc.tmpl` plugin source paths to `.local/share/zsh-plugins/`.
- Prune `.chezmoiignore` of all `.oh-my-zsh/*` patterns.

**Rollout order inside the implementation plan**: new externals + zshrc source-path change land in commit N; stale OMZ+p10k externals removed in commit N+1. Guarantees the shell is never without the two plugins.

### 4.4 Doctor checks (`scripts/doctor/phase-p.sh`)

~10 asserts:
- **Grep guard**: `rg -n -g '!docs/**' -g '!.git/**' -g '!scripts/doctor/phase-p.sh' '/Users/kulsin|kulsin@|singh\.kulwant@gmx'` returns zero hits.
- `.chezmoi.toml.tmpl` exists; declares `name`, `email`, `github_user`, `work` prompts.
- VS Code settings source has `.tmpl` suffix.
- Plist source filename is `local.chezmoi-update.plist.tmpl`.
- `dot_zshrc.tmpl` sources plugins from `.local/share/zsh-plugins/`, not `~/.oh-my-zsh/`.
- `.chezmoiexternal.toml` lacks `.oh-my-zsh` and `powerlevel10k` entries; has both plugins at the new path.
- `.chezmoiignore` lacks `.oh-my-zsh` patterns.
- `dot_gitconfig.tmpl` uses `{{ .name }}` and `{{ .email }}` (literal substring check).
- `.chezmoidata.yaml` has `ssh.local_hosts` and `ask.endpoint` keys.
- `run_onchange_load_chezmoi_launchd.sh.tmpl` contains the legacy `launchctl bootout` of `com.kulsin.chezmoi-update`.

### 4.5 Exit criteria

- `just doctor P` returns 0.
- `chezmoi init --apply imkulwant` on a VM with a different Unix username and corporate email finishes without errors and produces the right identity in `~/.gitconfig`.
- Personal Mac upgrade: previous `com.kulsin.chezmoi-update` agent is bootout'd; new `local.chezmoi-update` agent is loaded and runs.

### 4.6 Risks

- **Plist filename rename**: chezmoi will see the old plist as orphaned and the new as a create. The `run_onchange` script handles the launchd bootout; the old plist file at `~/Library/LaunchAgents/com.kulsin.chezmoi-update.plist` is removed in the same step.
- **VS Code settings rename to `.tmpl`**: `chezmoi apply` writes the rendered file at the same destination; no user-visible impact. If the user has edited the local settings file, `chezmoi diff` will show the Java path diff — that's the intended effect.
- **Intel Mac path** (`{{ lookPath "chezmoi" }}`): untested on Intel; defers to Future work for full Intel parity, but this single use site is low-risk because `lookPath` is a chezmoi built-in.
- **ask() demotion**: current users of the shell helper on the personal Mac must set `ask.endpoint` in `~/.config/chezmoi/chezmoi.toml` after Phase P lands. Documented in the migration note of the implementation plan.

---

## 5. Phase R — Lifecycle (install polish + clean uninstall + features index)

### 5.1 Goals

- A polished, idempotent install path with pre-flight checks.
- A safe, flagged uninstall that leaves the system in a predictable state.
- A browsable, drift-checked inventory of everything the dotfiles install.

### 5.2 Deliverables

#### A. `scripts/install.sh`

`set -euo pipefail`. Standalone (curl'd for fresh Macs) or via `just install`. Steps:

1. **Platform check** — macOS only; warn if `sw_vers -productVersion` < 14.
2. **Xcode CLT** — if `xcode-select -p` fails, run `xcode-select --install`, poll every 5s (cap 20 min) with progress markers.
3. **Network** — `curl -fsI https://get.chezmoi.io -o /dev/null`.
4. **Disk space** — `df -k "$HOME"` ≥ 2 GB free.
5. **Bootstrap or apply** — if `~/.local/share/chezmoi` is missing: `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant`. Else: `chezmoi apply`.
6. **Verify** — `just doctor` at the end.
7. **Final banner** — points at `docs/features.md`.

Fresh-Mac one-liner (also in README):
```sh
curl -fsSL https://raw.githubusercontent.com/imkulwant/dotfiles/main/scripts/install.sh | bash
```
(Chezmoi's own one-liner still works too; the wrapper only adds pre-flight.)

#### B. `scripts/uninstall.sh`

Flags: `--yes`, `--dry-run`, `--no-backup`, `--purge-brew`, `--purge-data`.

Interactive confirmation by default (skip with `--yes`); `--dry-run` prints every action without executing. Sequence (ordering is deliberate — capture steps must precede destructive steps):

1. **Capture state**:
   - `MANAGED=$(chezmoi managed)` into a variable.
   - `cp "$(chezmoi source-path)/Brewfile" /tmp/dotfiles-brewfile.$$`.
2. **Backup** — unless `--no-backup`: `tar -czf ~/dotfiles-backup-$(date +%Y%m%d-%H%M%S).tar.gz $MANAGED` (skipping paths that don't exist).
3. **Launchd** — `launchctl bootout "gui/$UID" local.chezmoi-update || true`; same for legacy `com.kulsin.chezmoi-update`; same for `local.weekly-maintenance` (added in Phase Q); then `rm` the plists.
4. **macOS defaults revert** — iterate `scripts/macos-defaults-keys.txt` (new shared file; see §5.2.D), issue `defaults delete <domain> <key>` for each, then `killall Dock`.
5. **Login shell** — if `basename "$SHELL"` is `zsh` and `$SHELL` starts with `/opt/homebrew` or `/usr/local`, `chsh -s /bin/zsh`.
6. **Remove managed files** — `rm` each path in `$MANAGED` (dirs that chezmoi created but that are now empty are removed last).
7. **Chezmoi state** — `rm -rf ~/.local/share/chezmoi ~/.config/chezmoi ~/.cache/chezmoi`.
8. **`--purge-brew`** — `brew bundle cleanup --force --file /tmp/dotfiles-brewfile.$$`.
9. **`--purge-data`** — `rm -rf ~/.local/share/{atuin,mise,nvim,zsh-plugins}`; `rm -f ~/.zsh_history ~/.zcompdump*`; `rm -rf ~/Library/Backups/atuin`.
10. **Final banner** — reports backup path (if any), what was skipped, residual state (chezmoi binary at `~/.local/bin/chezmoi` preserved; Homebrew itself preserved).

#### C. `justfile` additions

```make
# Fresh install (or re-run idempotently)
install:
    scripts/install.sh

# Uninstall. Pass flags: just uninstall '--dry-run' or '--yes --purge-brew'
uninstall *args='':
    scripts/uninstall.sh {{args}}
```

#### D. `scripts/macos-defaults-keys.txt`

New shared file listing every `(domain, key)` tuple written by `macos_defaults.sh.tmpl`. Format:
```
com.apple.dock autohide
com.apple.dock autohide-delay
com.apple.dock tilesize
com.apple.dock show-recents
```
Consumed by `macos_defaults.sh.tmpl` (replaces inline keys) and `uninstall.sh` (revert loop). Doctor enforces both.

#### E. `docs/features.md` — the "what you get" inventory

Twelve categorized sections. Each row: *name → what it is → where to tweak it*.

| Section | Content |
|---|---|
| **Shell (zsh)** | Homebrew zsh as login shell; `~/.zshrc` (Homebrew PATH, history, completion, lazy mise, aliases); `~/.aliases.zsh`; `ZSH_PROFILE=1 zsh` opt-in profiler |
| **Prompt** | starship → `~/.config/starship.toml` |
| **History search** | atuin → `~/.config/atuin/config.toml`; Ctrl-R takeover |
| **Multiplexer** | tmux → `~/.config/tmux/tmux.conf`; C-a prefix, true color, mouse, base-index 1, vim pane nav, vi copy mode |
| **Editor** | Neovim via kickstart.nvim (`vim.pack`); `~/.config/nvim/init.lua`; Mason LSPs (`lua_ls, yamlls, bashls, jsonls, marksman, pyright`); harpoon2; Treesitter; lazygit float on `<leader>gg` |
| **Git** | `~/.gitconfig` (delta pager, SSH URL rewrite, zdiff3, rerere); `~/.ssh/config` (github.com, local LAN); lazygit (`~/.config/lazygit/config.yml`) |
| **CLI tools** | eza, bat, rg, fd, fzf (+ fd/bat preview), zoxide, gh, direnv, jq, yq, btop, tldr, dust, just, hyperfine |
| **Language toolchains** | mise + Temurin 21 for Java; uv for Python project venvs; `python@3.13` from Homebrew for system Python |
| **Package management** | `~/.local/share/chezmoi/Brewfile`; `run_onchange_install-brewfile.sh` auto-installs on Brewfile change |
| **macOS settings** | Dock (autohide, autohide-delay 0, tilesize 36, show-recents false) |
| **Automation** | `local.chezmoi-update` launchd agent (daily 09:00); `local.weekly-maintenance` (opt-in, Phase Q); pre-commit (shellcheck, shfmt, hygiene); GitHub Actions (lint + validate) |
| **VS Code** | `~/Library/Application Support/Code/User/settings.json` (Java path templated to mise install) |

README's current *Tool stack* section shrinks to one sentence pointing at `docs/features.md`.

### 5.3 Doctor checks (`scripts/doctor/phase-r.sh`)

~8 asserts:
- `scripts/install.sh` exists, executable, shellcheck-clean, uses `set -euo pipefail`.
- `scripts/uninstall.sh` exists, executable, shellcheck-clean, uses `set -euo pipefail`.
- `justfile` has `install` and `uninstall` recipes.
- `scripts/uninstall.sh --dry-run` exits 0 and prints expected step markers (step 1 … step 10).
- `docs/features.md` exists.
- **Drift**: every `brew "..."` line in `Brewfile` is name-mentioned somewhere in `docs/features.md` (allowlist: Brewfile comments and heading lines).
- **Drift**: every key written in `macos_defaults.sh.tmpl` appears in `scripts/macos-defaults-keys.txt` *and* in `docs/features.md`.
- `scripts/macos-defaults-keys.txt` exists; `macos_defaults.sh.tmpl` reads from it (or the test accepts that both files reference the same keys).

### 5.4 CI

- `install.sh` and `uninstall.sh` added to the shellcheck lint job.
- `uninstall.sh --dry-run` added to the validate job (exercises the parser, catches syntax regressions; no system state touched).

### 5.5 Exit criteria

- `just doctor R` returns 0.
- `just install` is a no-op on an already-applied machine.
- `just uninstall --dry-run` prints a readable 10-step preview.
- On a dedicated VM: `scripts/install.sh` → full green doctor → `scripts/uninstall.sh --yes --purge-brew --purge-data` → system is back to stock (chezmoi binary and Homebrew preserved; backup tarball present).

### 5.6 Risks

- **Uninstall is destructive.** Safety nets stack: interactive prompt (default), backup-by-default, `--dry-run`.
- **CI can't exercise full uninstall** (no managed state). `--dry-run` plus shellcheck is the practical ceiling.
- **Backup can be large.** The tar may include node_modules, caches, etc. — mitigated because `chezmoi managed` only returns files under source control (not arbitrary HOME contents). Verified by inspection of the managed list before the plan is executed.
- **macOS defaults revert** is only as good as `macos-defaults-keys.txt`. The drift check keeps that file honest.

---

## 6. Phase Q — Automation & upkeep

### 6.1 Goals

- One-command maintenance so brew/mise/chezmoi stay fresh without ceremony.
- Rotating backup of the one piece of important shell state (atuin history).
- Opt-in weekly background upkeep.

### 6.2 Deliverables

#### A. `justfile` recipes

```make
# brew update + upgrade + cleanup, mise upgrade, chezmoi update
upgrade-all:
    brew update && brew upgrade && brew cleanup
    mise upgrade
    chezmoi update

# Rotate atuin history snapshot
backup-atuin:
    scripts/maintenance/atuin-backup.sh

# Composite: upgrade everything, rotate atuin, run doctor
maintain: upgrade-all backup-atuin
    just doctor
```

#### B. `scripts/maintenance/atuin-backup.sh`

`set -euo pipefail`. Copies `~/.local/share/atuin/history.db` to `~/Library/Backups/atuin/history-$(date +%Y%m%d).db`. Keeps the 8 newest; prunes older. Idempotent per day. No external deps beyond `cp` and `ls`.

#### C. Opt-in weekly launchd agent

New `private_Library/LaunchAgents/local.weekly-maintenance.plist.tmpl`, gated at the top:

```
{{ if .automation.weekly_maintenance -}}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.weekly-maintenance</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{ lookPath "just" }}</string>
        <string>--justfile</string>
        <string>{{ .chezmoi.homeDir }}/.local/share/chezmoi/justfile</string>
        <string>maintain</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>{{ .chezmoi.homeDir }}/Library/Logs/weekly-maintenance.log</string>
    <key>StandardErrorPath</key>
    <string>{{ .chezmoi.homeDir }}/Library/Logs/weekly-maintenance.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
{{- end }}
```

Empty render when `.automation.weekly_maintenance` is `false` → chezmoi skips the file. Default is `false` (opt-in).

New sibling script `.chezmoiscripts/run_onchange_load_weekly_maintenance_launchd.sh.tmpl` loads/unloads the agent based on the data flag. Kept separate from the daily-update loader so each agent has one owner.

`.chezmoidata.yaml` additions:
```yaml
automation:
  weekly_maintenance: false
```

### 6.3 Doctor checks (`scripts/doctor/phase-q.sh`)

~8 asserts:
- `justfile` has `upgrade-all`, `backup-atuin`, `maintain` recipes.
- `scripts/maintenance/atuin-backup.sh` exists, executable, shellcheck-clean, `set -euo pipefail`.
- `.chezmoidata.yaml` has `automation.weekly_maintenance` key (bool).
- Weekly plist template exists; `chezmoi execute-template` on it with `automation.weekly_maintenance=false` renders empty.
- `brew bundle check --no-upgrade --file Brewfile` passes.
- `find -L ~/.local/bin -maxdepth 1 -type l` returns zero dead symlinks (allowlist: `chezmoi`).
- Atuin DB exists and is `< 1 GB` (soft bound; warn above 500 MB, fail above 1 GB).
- `scripts/maintenance/` directory exists.

### 6.4 CI

Unchanged. All checks here depend on an applied machine.

### 6.5 Exit criteria

- `just doctor Q` returns 0.
- `just upgrade-all` runs the three steps and surfaces any failure.
- `just backup-atuin` creates a dated backup and prunes to 8.
- `just maintain` composes all three plus doctor and returns 0 on a healthy machine.
- Setting `automation.weekly_maintenance: true` in `~/.config/chezmoi/chezmoi.toml` and applying produces a loaded launchd agent; setting back to `false` and applying unloads it cleanly.

### 6.6 Risks

- **`brew upgrade` can introduce breaking versions**. Three safety nets: default-off, log at `~/Library/Logs/weekly-maintenance.log`, `just maintain` ends with `just doctor` so breakage is detected on next run.
- **Launchd backfill**: macOS replays missed `StartCalendarInterval` events after a sleep. Acceptable default; `FailIfMissed` opt-out captured in Future work.

---

## 7. Rollout order & dependencies

Phases are independent at the data level. Recommended landing order:

1. **O first** — the perf safety net is cheap and immediately prevents later phases from regressing shell startup silently.
2. **P second** — portability is the biggest refactor and establishes the data primitives (`name`, `email`, `work`, `ssh.local_hosts`, `ask.endpoint`) that P-aware templates in later phases can rely on.
3. **R third** — install.sh / uninstall.sh need Phase P's cleaner surface (`local.chezmoi-update`, templated settings.json) to not bake in `kulsin`-isms.
4. **Q last** — depends on R's `scripts/maintenance/` convention and on `local.*` naming.

Each phase ships in a tight sequence of commits with the doctor script added last (so partial phases don't poison `just doctor`). Memory `project-progress.md` is updated after each phase lands with the same table format v1 uses.

---

## 8. Future work

One-liners captured now so v2 doesn't lose them. **Not implementing in v2.**

### 8.1 Secrets & identity

- **1Password SSH agent + git signing** — replace `~/.ssh/id_ed25519` with a 1Password-held key; `gpg.format = ssh`, `user.signingkey`. Deferred because it needs the 1Password cask + account bootstrap.
- **`age`-encrypted secrets** — commit encrypted gitconfig include for API tokens, LLM endpoints, etc. Would let `ask.endpoint` live in-repo under encryption rather than per-machine chezmoi.toml.

### 8.2 Workflow polish

- **tmux plugin manager (tpm)** — enables tmux-resurrect, tmux-continuum, tmux-yank.
- **Expanded macOS defaults** — Finder (hidden files, path bar, status bar), screenshot location + format, trackpad speed, keyboard key-repeat.
- **iTerm2 profile tracked in chezmoi** — export the color/font profile JSON. Tradeoff: iTerm2 writes to its plist constantly, so repro-vs-dynamism tension.
- **Raycast settings sync** — if adopted as launcher.

### 8.3 AI / editor

- **nvim CodeCompanion or Copilot** — AI pair-programming. Needs an API-key path (argues for the secrets work first).
- **Real `ask()`** — proper backend contract (streaming, model selection, history), not the current curl-into-python stub.

### 8.4 Platform & toolchain

- **Intel Mac support** — template `brew --prefix` in plists and anywhere `/opt/homebrew` is hardcoded. Each site is one line; needs an Intel target to validate end-to-end.
- **Linux parity for the CLI subset** — split templates on `.chezmoi.os`; drop brew-cask, macOS defaults, launchd. Earns its weight only if a Linux dev box enters rotation.

### 8.5 Hygiene

- **Pre-commit `autoupdate`** — periodic hook-version bumps. Kept out of `just maintain` because it silently moves pinned versions.
- **Brewfile orphan detection** — flag formulae in Brewfile with no reference anywhere in source files or runtime hooks. One-off audit tool, not CI.
- **Launchd `FailIfMissed`** — opt into skip-backfill behavior for the weekly agent if a weekend of sleep should *not* produce a Monday-morning run.

---

## 9. Appendix — references

- v1 overhaul plan: [`docs/history/2026-07-06-terminal-workflow-plan.md`](../history/2026-07-06-terminal-workflow-plan.md)
- v1 SWOT audit: [`docs/history/2026-07-06-swot.md`](../history/2026-07-06-swot.md)
- Design choices: [`docs/CHOICES.md`](../CHOICES.md)
- chezmoi reference: [`docs/chezmoi-cheatsheet.md`](../chezmoi-cheatsheet.md)
- Chezmoi template functions: <https://chezmoi.io/reference/templates/functions/>
- hyperfine docs: <https://github.com/sharkdp/hyperfine>
