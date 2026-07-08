# dotfiles

Kul's personal macOS dotfiles, managed with [chezmoi](https://chezmoi.io).
This repo encodes a complete terminal environment — shell, editor, git, tmux,
language toolchains, and macOS system settings — as version-controlled source.

---

## Bootstrap

### Fresh Mac

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant
```

That single command:

1. Downloads and installs the `chezmoi` binary into `~/.local/bin`.
2. Clones this repo to `~/.local/share/chezmoi`.
3. Runs all `run_once_before_*` scripts (Homebrew, zsh, chezmoi itself).
4. Applies all managed files to `$HOME`.
5. Runs `run_onchange_*` scripts (Brewfile install, macOS defaults, launchd agent).

No `install.sh` is needed.
`chezmoi init --apply` is the only bootstrap entrypoint.

### Prerequisites

The bootstrap script handles everything, but a working internet connection
and Xcode Command Line Tools are required.
On a brand-new Mac, run `xcode-select --install` before bootstrapping.

---

## Day-to-day

```sh
just apply    # chezmoi apply — write source → home
just verify   # chezmoi verify — assert home matches source
just update   # chezmoi update — git pull + apply
just doctor   # run all phase checks (see Verification below)
```

Full chezmoi command reference: [`docs/chezmoi-cheatsheet.md`](docs/chezmoi-cheatsheet.md).

---

## Repository layout

```
~/.local/share/chezmoi/
├── .chezmoiexternal.toml        # pinned tarballs: OMZ, zsh plugins
├── .chezmoidata.yaml            # per-host template data (work boolean)
├── .chezmoiignore               # files chezmoi must not touch
├── .pre-commit-config.yaml      # shellcheck + shfmt + hygiene hooks
├── .github/workflows/ci.yml     # lint + validate on every push
├── justfile                     # apply / verify / update / doctor
├── Brewfile                     # all formulae, casks, fonts, VS Code extensions
│
├── .chezmoiscripts/             # scripts chezmoi runs automatically
│   ├── run_once_before_10_ensure_zsh.sh.tmpl
│   ├── run_once_before_20_install_homebrew.sh.tmpl
│   ├── run_once_before_70_install_chezmoi.sh.tmpl
│   ├── run_onchange_install-brewfile.sh.tmpl
│   ├── run_onchange_macos_defaults.sh.tmpl
│   └── run_onchange_load_chezmoi_launchd.sh.tmpl
│
├── dot_zshrc.tmpl               # zsh config (starship, atuin, mise, direnv, fzf, zoxide)
├── dot_aliases.zsh.tmpl         # shell aliases
├── dot_gitconfig.tmpl           # git: delta pager, SSH rewrite, rerere, zdiff3
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
├── dot_ssh/config               # SSH: keychain, github.com block
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

| Layer | Tool | Replaces |
|---|---|---|
| Dotfiles | chezmoi | bare git |
| Packages | Homebrew + Brewfile | ad-hoc installs |
| Shell prompt | Starship | Powerlevel10k |
| Shell history | Atuin | plain HISTFILE |
| Multiplexer | tmux | - |
| Editor | Neovim (kickstart.nvim) | - |
| Java | mise + Temurin 21 | jenv + Homebrew openjdk@21 |
| Python | uv | pyenv + pipx |
| Git pager | delta (side-by-side) | less |
| Git UI | lazygit | - |
| File listing | eza | ls |
| Cat | bat | cat |
| Fuzzy find | fzf + fd | find |
| Directory jump | zoxide | cd |
| Process monitor | btop | top |
| Task runner | just | make |
| Linter | shellcheck + shfmt | - |

Design rationale for each choice: [`docs/CHOICES.md`](docs/CHOICES.md).

---

## Scripts chezmoi runs

### `run_once_before_*` — run once on first apply

| Script | What it does |
|---|---|
| `10_ensure_zsh.sh` | Registers Homebrew zsh in `/etc/shells`, sets it as login shell |
| `20_install_homebrew.sh` | Installs Homebrew if missing |
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
work: false   # set to true on a work machine
```

Built-in variables also available in templates:

- `{{ .chezmoi.hostname }}` — e.g. `panzer.local`
- `{{ .chezmoi.os }}` — `darwin` on macOS
- `{{ .chezmoi.homeDir }}` — `$HOME`
- `{{ .chezmoi.username }}` — your Unix username

Example use in a template:

```
{{- if .work }}
# work-specific config
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
| H | Git + SSH | 21 |
| I | mise + uv | 21 |
| J | CI + hygiene | 23 |
| K | macOS defaults | 5 |
| L | Advanced | 5 |
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
