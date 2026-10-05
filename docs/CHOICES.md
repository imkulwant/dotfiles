# Design choices

Key decisions made during the 2026 overhaul and the reasoning behind them.
Each entry answers: what was chosen, what was replaced, and why.

---

## Dotfiles manager: chezmoi

Kept from the original repo.
chezmoi covers templates, run-once scripts, externals (tarballs), encryption,
and cross-machine support — all in a single binary with no server-side component.
Alternatives (stow, yadm, bare-git) lack one or more of these properties.

---

## Package manager: Homebrew + single Brewfile

Kept from the original repo.
The entire tool stack — CLI tools, casks, fonts, VS Code extensions — lives in
one `Brewfile`.
`brew bundle check` detects drift; `brew bundle install` is idempotent.
`run_onchange_install-brewfile.sh.tmpl` uses a SHA hash of the Brewfile as a
trigger, so it re-runs only when the file changes.

---

## Shell prompt: Starship (replaced Powerlevel10k)

Powerlevel10k requires a custom font, a 400-line `.p10k.zsh` config, and an
async pre-execution hook that creates latency edge cases.
Starship is a single TOML file, works with any Nerd Font, and integrates
cleanly with mise and other tools via first-class modules.
The p10k config and install script were removed entirely in Phase E.

---

## Shell history: Atuin (replaced plain zsh history)

Atuin replaces `HISTFILE` with a local SQLite database that supports fuzzy
search, filtering by directory and exit code, and optional sync.
It is initialized after fzf in `.zshrc` to avoid Ctrl-R binding conflicts.
Sync is not enabled — history stays local.

---

## Java toolchain: mise + Temurin 21 (replaced jenv + Homebrew openjdk@21)

jenv is a shim manager that requires manual `jenv add` calls every time a JDK
is installed, and it does not install JDKs itself.
mise installs and activates `java@temurin-21` in one step, exports
`JAVA_HOME` automatically, and is the same tool already used for other
runtimes (Node, Python).
Three dead chezmoi scripts (install_jenv_plugins, add_java_to_jenv,
install_fzf) were deleted as a side effect of this migration.

---

## Python toolchain: uv (replaced pyenv + pipx)

pyenv adds startup overhead and requires `pyenv rehash` discipline.
pipx is a separate tool with its own venvs.
uv handles both: `uv python install` manages interpreters, `uv tool install`
manages CLI tools, and `uv run` executes scripts without explicit venv
activation.
Python is also available via Homebrew for system-level tools.

---

## Neovim config: kickstart.nvim via vim.pack (replaced lazy.nvim)

kickstart.nvim is a single-file config that uses Neovim 0.12's built-in
`vim.pack` instead of lazy.nvim.
This removes a runtime dependency (lazy.nvim itself) and avoids the
lazy-loading complexity that kickstart used to require.
LSPs are managed by Mason (lua_ls, yamlls, bashls, jsonls, marksman, pyright).
Java LSP (jdtls) is intentionally excluded — Java development happens in
IntelliJ.

---

## Git and SSH configs: unmanaged

`~/.gitconfig` and `~/.ssh/config` are not managed by chezmoi.
Identity, keys, hosts, and transport (SSH vs HTTPS) differ per machine,
especially on work laptops, and a managed copy overwrote local edits on every
daily `chezmoi update`.
Each machine keeps its own copies.
delta is still installed and used by lazygit; set `core.pager = delta` in a
machine's `~/.gitconfig` to use it for plain `git diff` too.

---

## tmux prefix: Ctrl-A (replaced Ctrl-B)

Ctrl-B conflicts with Vim's page-up motion.
Ctrl-A is the screen-era convention and keeps muscle memory consistent with
most terminal-multiplexer documentation.

---

## macOS defaults: Dock only

Finder, screenshots, keyboard, and trackpad settings were deliberately kept at
macOS defaults — those preferences are not strong enough to warrant encoding
them as managed state.
The Dock settings that are managed: autohide (0 delay), icon size 36px,
no recent apps.

---

## Per-host data: no setup prompts

Setup asks no questions; there is no `.chezmoi.toml.tmpl`.
A `work` flag and identity prompts existed earlier but nothing used them once
git and SSH configs became per-machine.
`.chezmoi.hostname` (built-in) handles machine-specific branching when needed.

---

## launchd auto-update: daily at 09:00

`com.kulsin.chezmoi-update` runs `chezmoi update --no-tty` daily.
Logs go to `~/Library/Logs/chezmoi-update.log`.
The plist is managed by chezmoi; `run_onchange_load_chezmoi_launchd.sh.tmpl`
re-bootstraps the agent whenever the plist changes.

---

## CI: GitHub Actions + pre-commit

Two jobs on every push:
- `lint`: shellcheck + shfmt on all doctor scripts.
- `validate`: `chezmoi execute-template`, `chezmoi apply --dry-run`,
  `just doctor C`, formula-drift-check.

pre-commit runs the same lint hooks locally before each commit.
`formula-drift-check.sh` asserts every `/opt/homebrew/opt/<formula>` reference
in source files is declared in the Brewfile.

---

## Secrets: none managed (1Password skipped)

1Password CLI integration was opted out of during Phase L.
Secrets are not stored in this repo.
If this changes, the approach would be `op read` calls in `.tmpl` files with
`chezmoi.useBuiltinAge = false`.
