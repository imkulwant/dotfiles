# Features — What you get

This file catalogs every tool, plugin, LSP, Brew formula, macOS default key, and launchd agent the dotfiles install. Each row shows the name, what it does, and where you configure it.

---

## Shell (zsh)

Homebrew zsh as login shell with history, completion, lazy toolchain management, and opt-in profiling.

| Name | What it is | Where to tweak |
|---|---|---|
| zsh | Login shell from Homebrew | `~/.zshrc` |
| Homebrew PATH | Shell paths for Homebrew binaries | `~/.zshrc` |
| HISTFILE | Shell history location | `~/.zshrc` — set to `~/.zsh_history` |
| HISTSIZE | Shell history size in memory | `~/.zshrc` — set to 50000 |
| compinit -C | Completion init with caching | `~/.zshrc` |
| zsh-autosuggestions | Inline suggestions from history | `~/.local/share/zsh-plugins/zsh-autosuggestions` |
| zsh-syntax-highlighting | Command syntax coloring | `~/.local/share/zsh-plugins/zsh-syntax-highlighting` |
| mise (lazy) | Runtime manager (Java, node, etc.) lazy-loaded | `.zshrc` sets `MISE_QUIET=1` and loads on first `command` |
| ZSH_PROFILE | Opt-in profiler (zprof) | `~/.zshrc` — set `ZSH_PROFILE=1 zsh` to profile |
| aliases | Shell command shortcuts | `~/.aliases.zsh` |

---

## Prompt

Fast, minimal prompt with git status and exit codes.

| Name | What it is | Where to tweak |
|---|---|---|
| starship | Cross-shell prompt replacing p10k | `~/.config/starship.toml` |

---

## History search

Fuzzy cross-session shell history with full-text search and database sync.

| Name | What it is | Where to tweak |
|---|---|---|
| atuin | Fuzzy history search (Ctrl-R) with SQLite backend | `~/.config/atuin/config.toml` |

---

## Multiplexer

Terminal multiplexer with vim-friendly keybindings and true color support.

| Name | What it is | Where to tweak |
|---|---|---|
| tmux | Session/window/pane manager with C-a prefix | `~/.config/tmux/tmux.conf` — true color, mouse, base-index 1, vim pane nav, vi copy mode |

---

## Editor

Neovim with LSP, treesitter, and harpoon2 for modal editing and quick file navigation.

| Name | What it is | Where to tweak |
|---|---|---|
| neovim | Modal text editor with LSP support | `~/.config/nvim/init.lua` |
| kickstart.nvim | Neovim starter config | `~/.config/nvim/` — vim.pack built-in, no plugin manager |
| nvim-pack-lock.json | Locked versions of Neovim plugins | `~/.config/nvim/nvim-pack-lock.json` |
| lua_ls | Lua language server | Installed via Mason inside Neovim |
| yamlls | YAML language server | Installed via Mason inside Neovim |
| bashls | Bash language server | Installed via Mason inside Neovim |
| jsonls | JSON language server | Installed via Mason inside Neovim |
| marksman | Markdown language server | Installed via Mason inside Neovim |
| pyright | Python language server | Installed via Mason inside Neovim |
| harpoon2 | Quick file navigation via marks | `~/.config/nvim/` — git branch harpoon2 |
| lazygit (nvim float) | Git UI in Neovim float | `~/.config/nvim/init.lua` — `<leader>gg` |
| Treesitter | Incremental parsing for syntax highlight and motions | Installed via `nvim-treesitter` plugins |

---

## Git

Version control with delta side-by-side diffs, SSH rewrite, and lazygit UI.

| Name | What it is | Where to tweak |
|---|---|---|
| git | Distributed version control | `~/.gitconfig` |
| git-delta | Side-by-side diff pager replacing less | `~/.gitconfig` — `[pager] diff = delta` |
| SSH URL rewrite | Automatic `https://` → `git@` for github.com | `~/.gitconfig` — `[url "git@github.com:"]` |
| zdiff3 | 3-way merge conflict marker style | `~/.gitconfig` — `[merge] conflictstyle = zdiff3` |
| rerere | Automatic reuse of resolved conflicts | `~/.gitconfig` — `[rerere] enabled = true` |
| pull.rebase | Rebase-based pulls by default | `~/.gitconfig` — `[pull] rebase = true` |
| push.autoSetupRemote | Auto-set upstream on push | `~/.gitconfig` — `[push] autoSetupRemote = true` |
| lazygit | Terminal Git UI with staging and commits | `~/.config/lazygit/config.yml` — delta pager integration |

---

## CLI tools

File listing, searching, fuzzing, and general-purpose command-line utilities.

| Name | What it is | Where to tweak |
|---|---|---|
| eza | ls replacement with git status and color icons | `~/.aliases.zsh` — aliased to `ls` |
| bat | cat replacement with syntax highlighting | `~/.aliases.zsh` — aliased to `cat` |
| ripgrep (rg) | Fast recursive grep with regex | Default settings work; can override in `.ripgreprc` |
| fd | Fast find replacement with simple syntax | Default settings work; can use flags for patterns |
| fzf | Fuzzy finder for command line and vim | `~/.zshrc` — Ctrl-T fuzzy file picker with fd/bat preview |
| zoxide | Smart directory jump based on frecency | `~/.zshrc` — faster alternative to `cd` via `z` alias |
| gh | GitHub CLI for issues, PRs, and releases | Use within shell or configure at `~/.config/gh/config.yml` |
| direnv | Environment-per-directory secrets and variables | `~/.envrc` in project roots; `~/.config/direnv/direnvrc` for shared lib |
| jq | JSON query and transform on command line | Standalone tool; pipe JSON to jq for filtering |
| yq | YAML query and transform on command line | Standalone tool; pipe YAML to yq for filtering |
| btop | System monitor with nice TUI | Standalone tool; shows CPU, memory, disk, processes |
| tldr | Simplified man pages | `tldr command` for common usage examples |
| dust | Disk usage helper (more intuitive than du) | `dust` to see which directories use the most space |
| just | Task runner replacing make | `justfile` — run recipes like `just apply`, `just doctor` |
| hyperfine | Benchmarking tool for shell performance | `scripts/perf/shell-startup.sh` uses it to measure zsh startup |
| tree-sitter-cli | Parser generator for grammars | Standalone; supports many languages via plugins |
| k9s | Kubernetes cluster manager TUI | Standalone; explore k8s resources interactively |
| maven | Build automation tool for Java | Installed via Homebrew; used by Java projects |

---

## Language toolchains

Java via mise, Python via uv and Homebrew python@3.13, with templates for new projects.

| Name | What it is | Where to tweak |
|---|---|---|
| mise | Polyglot runtime manager (Java, node, ruby, etc.) | `~/.config/mise/config.toml` — also lazy-loaded from `.zshrc` |
| Temurin 21 (Java) | OpenJDK 21 via mise | `~/.config/mise/config.toml` — installed to `~/.local/share/mise/installs/java/temurin-21` |
| uv | Fast Python package manager and project builder | `~/.local/share/chezmoi/templates/.envrc` — configure per-project |
| python@3.13 | System Python from Homebrew | Installed via Homebrew; available in PATH |
| templates/.mise.toml | Starter template for new projects | Copy to project root for mise config |
| templates/.envrc | Starter template for new projects | Copy to project root for direnv + uv |

---

## Package management

Homebrew with pinned dependencies and auto-install on source change.

| Name | What it is | Where to tweak |
|---|---|---|
| Homebrew | Package manager for macOS | `~/.local/share/chezmoi/Brewfile` — all formulae, casks, VS Code extensions |
| Brewfile | Declarative package list | `~/.local/share/chezmoi/Brewfile` |
| run_onchange_install-brewfile.sh | Auto-install on Brewfile change | Runs `brew bundle install` whenever Brewfile hash changes |

---

## macOS settings

System Dock configuration applied via defaults write and reverted on uninstall.

| Name | What it is | Where to tweak |
|---|---|---|
| autohide | Dock auto-hides when not in use | `defaults` key `com.apple.dock.autohide` = true |
| autohide-delay | Delay before Dock appears (seconds) | `defaults` key `com.apple.dock.autohide-delay` = 0 |
| autohide-time-modifier | Fade-in speed (seconds) | `defaults` key `com.apple.dock.autohide-time-modifier` = 0.5 |
| tilesize | Dock icon size in pixels | `defaults` key `com.apple.dock.tilesize` = 36 |
| show-recents | Show recent apps in Dock | `defaults` key `com.apple.dock.show-recents` = false |

---

## Automation

Scheduled updates, pre-commit hooks, GitHub Actions CI, and install/uninstall scripts.

| Name | What it is | Where to tweak |
|---|---|---|
| local.chezmoi-update (launchd) | Daily auto-update at 09:00 | `~/Library/LaunchAgents/local.chezmoi-update.plist` — loads via `.chezmoiscripts/run_onchange_load_chezmoi_launchd.sh.tmpl` |
| pre-commit | Framework for git hooks | `~/.pre-commit-config.yaml` — shellcheck, shfmt, trailing-whitespace, large-files, merge-conflict |
| shellcheck | Shell script linter | Runs via pre-commit; catches common bash/zsh mistakes |
| shfmt | Shell script formatter | Runs via pre-commit; enforces consistent style |
| GitHub Actions CI | Lint and validate on every push | `.github/workflows/ci.yml` — shellcheck + `just doctor C` |
| scripts/install.sh | Bootstrap or re-apply idempotently | Pre-flight checks (macOS version, Xcode CLT, network, disk), then chezmoi init/apply |
| scripts/uninstall.sh | Safe destructive uninstall | Flags: `--yes --dry-run --no-backup --purge-brew --purge-data` |
| just doctor | All-phases verification | Runs `scripts/doctor/run.sh` — 241 checks across phases A–R |

---

## VS Code

VS Code settings with Java language support and Python/Django extensions.

| Name | What it is | Where to tweak |
|---|---|---|
| VS Code | Microsoft code editor | `~/Library/Application Support/Code/User/settings.json.tmpl` |
| Java language support | Redhat Java extension + build/debug tools | Settings point `java.jdt.ls.java.home` to `{{ .chezmoi.homeDir }}/.local/share/mise/installs/java/temurin-21` |
| Python extensions | Django, Python, Pylance, debugpy, envs | Installed via Brewfile (VS Code extensions) |
| Java extensions | Java Pack, Maven, Gradle, test runner | Installed via Brewfile (VS Code extensions) |
| Other extensions | GitLens, SonarLint, Prettier, IntelliCode | Installed via Brewfile (VS Code extensions) |

---
