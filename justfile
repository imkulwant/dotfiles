# Chezmoi dotfiles task runner.

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
