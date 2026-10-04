# Chezmoi dotfiles task runner.

# Bootstrap or re-apply the dotfiles (idempotent)
install:
    scripts/install.sh

# Uninstall the dotfiles (destructive). Pass flags, e.g. `just uninstall '--dry-run'`.
uninstall *args='':
    scripts/uninstall.sh {{args}}

# Upgrade package managers in a sensible order. Prints what runs.
upgrade-all:
    brew update && brew upgrade && brew cleanup
    mise upgrade
    chezmoi update

# Rotate atuin history DB snapshot (keeps 8 newest in ~/Library/Backups/atuin/).
backup-atuin:
    scripts/maintenance/atuin-backup.sh

# Composite: run upgrades, rotate atuin, then doctor.
maintain: upgrade-all backup-atuin
    just doctor

# Apply managed dotfiles to $HOME.
apply:
    chezmoi apply

# Verify managed files match chezmoi source (no-op if clean).
verify:
    chezmoi verify

# Pull latest changes from remote and apply.
update:
    chezmoi update

# Run doctor sanity checks. Pass phase letters to run a subset (e.g. `just doctor C D`).
doctor *phases='':
    scripts/doctor/run.sh {{phases}}

# Benchmark zsh startup time.
profile-shell:
    scripts/perf/shell-startup.sh
