# dotfiles

Kul's personal macOS dotfiles, managed with [chezmoi](https://chezmoi.io).
This repo encodes a complete terminal environment — shell, editor, git, tmux,
language toolchains, and macOS system settings — as version-controlled source.

---

## Bootstrap

### Fresh Mac

```sh
curl -fsSL https://raw.githubusercontent.com/imkulwant/dotfiles/main/scripts/install.sh | bash
```

That single command:

1. Installs Homebrew if missing and puts it on PATH for the rest of the run.
2. Downloads and installs the `chezmoi` binary into `~/.local/bin`.
3. Clones this repo to `~/.local/share/chezmoi`.
4. Runs all `run_once_before_*` scripts in name order (Homebrew, zsh, chezmoi itself).
5. Applies all managed files to `$HOME`.
6. Runs `run_onchange_*` scripts (Brewfile install, macOS defaults, launchd agent).
7. Runs `just doctor` and reports failures without aborting.

The install script includes pre-flight checks (macOS version, Xcode CLT, network, disk space)
and is idempotent: running it again on an already-installed system applies any new changes.

---

## Day-to-day

```sh
just install       # bootstrap or re-apply (idempotent); runs pre-flight checks
just apply         # chezmoi apply — write source → home
just verify        # chezmoi verify — assert home matches source
just update        # chezmoi update — git pull + apply
just doctor        # run all phase checks (see Verification below)
just profile-shell # benchmark zsh startup time
ZSH_PROFILE=1 zsh  # print zsh profiling output (zprof)
```

Full chezmoi command reference: [`docs/chezmoi-cheatsheet.md`](docs/chezmoi-cheatsheet.md).

---

## Repository layout

```
~/.local/share/chezmoi/
├── .chezmoiexternal.toml        # pinned tarballs: OMZ, zsh plugins
├── .chezmoidata.yaml            # template data (shell budget, ask endpoint, automation flags)
├── .chezmoiignore               # files chezmoi must not touch
├── .pre-commit-config.yaml      # shellcheck + shfmt + hygiene hooks
├── .github/workflows/ci.yml     # lint + validate on every push
├── justfile                     # apply / verify / update / doctor
├── Brewfile                     # all formulae, casks, fonts, VS Code extensions
│
├── .chezmoiscripts/             # scripts chezmoi runs automatically
│   ├── run_once_before_20_install_homebrew.sh.tmpl
│   ├── run_once_before_30_ensure_zsh.sh.tmpl
│   ├── run_once_before_70_install_chezmoi.sh.tmpl
│   ├── run_onchange_install-brewfile.sh.tmpl
│   ├── run_onchange_macos_defaults.sh.tmpl
│   └── run_onchange_load_chezmoi_launchd.sh.tmpl
│
├── dot_zshrc.tmpl               # zsh config (starship, atuin, mise, direnv, fzf, zoxide)
├── dot_aliases.zsh.tmpl         # shell aliases
│
├── private_Library/
│   ├── Application Support/Code/User/settings.json   # VS Code settings
│   └── LaunchAgents/
│       └── com.kulsin.chezmoi-update.plist.tmpl      # daily auto-update agent
│
├── dot_config/
│   ├── nvim/                    # kickstart.nvim (vim.pack, Mason LSPs)
│   ├── tmux/tmux.conf           # C-a prefix, true color, vim pane nav
│   ├── starship.toml            # prompt config
│   ├── atuin/config.toml        # fuzzy history search
│   └── lazygit/config.yml       # delta pager integration
│
├── templates/                   # project starters (not applied to HOME)
│   ├── .mise.toml
│   └── .envrc
│
├── scripts/
│   └── doctor/                  # per-phase verification scripts
│       ├── run.sh
│       ├── lib.sh
│       ├── phase-c.sh … phase-n.sh
│       └── formula-drift-check.sh
│
└── docs/
    ├── CHOICES.md               # design decisions and rationale
    ├── chezmoi-cheatsheet.md    # full command reference
    └── history/
        ├── 2026-07-06-terminal-workflow-plan.md   # original overhaul plan
        └── 2026-07-06-swot.md                     # original SWOT analysis
```

---

## Tool stack

The complete, categorized inventory lives in [`docs/features.md`](docs/features.md) — a scannable reference of every tool, plugin, LSP, Brew formula, macOS default key, and launchd agent this repo installs, with per-row pointers to where each is configured.

Design rationale for each major choice: [`docs/CHOICES.md`](docs/CHOICES.md).

---

## Scripts chezmoi runs

### `run_once_before_*` — run once on first apply

| Script | What it does |
|---|---|
| `20_install_homebrew.sh` | Installs Homebrew if missing |
| `30_ensure_zsh.sh` | Registers Homebrew zsh in `/etc/shells`, sets it as login shell |
| `70_install_chezmoi.sh` | Ensures chezmoi binary is in place |

### `run_onchange_*` — re-run whenever their content changes

| Script | Trigger | What it does |
|---|---|---|
| `install-brewfile.sh` | SHA of `Brewfile` in comment | `brew bundle` |
| `macos_defaults.sh` | Script content | Dock autohide, size, no recents |
| `load_chezmoi_launchd.sh` | SHA of plist template | `launchctl bootstrap` the daily update agent |

---

## Templates and per-host data

`.chezmoidata.yaml` exposes custom variables to all `.tmpl` files:

```yaml
automation:
  weekly_maintenance: false   # set to true to load the weekly maintenance agent
```

Setup asks no questions; there is no `.chezmoi.toml.tmpl`.

Built-in variables also available in templates:

- `{{ .chezmoi.hostname }}` — e.g. `my-mac` (hostname up to the first dot)
- `{{ .chezmoi.os }}` — `darwin` on macOS
- `{{ .chezmoi.homeDir }}` — `$HOME`
- `{{ .chezmoi.username }}` — your Unix username

Example use in a template:

```
{{- if eq .chezmoi.hostname "my-mac" }}
# machine-specific config
{{- end }}
```

---

## Auto-update

A launchd agent (`com.kulsin.chezmoi-update`) runs `chezmoi update --no-tty`
daily at 09:00.
Logs: `~/Library/Logs/chezmoi-update.log`.

To check the agent status:

```sh
launchctl list | grep chezmoi-update
```

To trigger an immediate update:

```sh
chezmoi update
```

---

## Verification

Every phase of the overhaul has machine-readable doctor checks:

```sh
just doctor          # run all phases
just doctor C D E    # run specific phases
bash scripts/doctor/run.sh K L   # same, without just
```

Expected output: all checks green, zero failures.

### Phase summary

| Phase | Name | Checks |
|---|---|---|
| C | Critical fixes | 32 |
| D | Brewfile | 49 |
| E | Shell layer | 25 |
| F | tmux | 10 |
| G | Neovim | 21 |
| H | Git tooling | 6 |
| I | mise + uv | 21 |
| J | CI + hygiene | 23 |
| K | macOS defaults | 5 |
| L | Advanced | 3 |
| M | Documentation | 7 |
| N | Final verification | 4 |

---

## CI

GitHub Actions runs on every push:

- `lint`: shellcheck + shfmt on all `scripts/doctor/*.sh`.
- `validate`: `chezmoi execute-template`, `chezmoi apply --dry-run`,
  `just doctor C`, formula drift check.

`formula-drift-check.sh` asserts that every `/opt/homebrew/opt/<formula>`
reference in source files is declared in the Brewfile.
This catches tool retirements that leave dangling path references behind.

---

## Maintenance

### Adding a new Homebrew formula

1. Add the line to `Brewfile`.
2. Run `just apply` — the `run_onchange` script detects the SHA change and
   runs `brew bundle`.

### Adding a managed file

```sh
chezmoi add ~/.config/some/file
chezmoi re-add ~/.config/some/file   # if you edited it in HOME
```

### Changing a dotfile

```sh
chezmoi edit ~/.zshrc   # opens source file in $EDITOR
chezmoi apply           # writes rendered output to HOME
```

### Updating all tools

```sh
brew update && brew upgrade
mise upgrade
just update
```
