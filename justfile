# Chezmoi dotfiles task runner. Extended in Phase J.

# Run doctor sanity checks. Pass phase letters to run a subset (e.g. `just doctor C D`).
doctor *phases='':
    scripts/doctor/run.sh {{phases}}
