# dotfiles

`chezmoi add $FILE`: Add a file from home to source directory (use --template for templates, --exact for non-dotfiles).

`chezmoi status`: Quick summary of pending changes.

`chezmoi diff`: Show differences between source and home (add -w for word-diff).

`chezmoi apply`: Update home from source (add -v verbose, -n dry-run).

`chezmoi re-add $FILE`: Re-add modified home files to source.​

`chezmoi init [--apply] $REPO`: Clone repo and optionally apply.

`chezmoi update`: Git pull + apply changes.

`chezmoi doctor`: Check for common issues.

`chezmoi verify`: Check if home matches source.

`chezmoi list [--managed | --unmanaged]`: List managed/unmanaged files.

`brew bundle install --file ~/Brewfile`

