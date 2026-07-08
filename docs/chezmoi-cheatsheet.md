# chezmoi cheatsheet

## Bootstrap

```sh
# Fresh Mac — installs chezmoi, clones this repo, applies everything
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant
```

## Daily workflow

```sh
# See what would change before applying
chezmoi diff

# Apply source → home
chezmoi apply

# Pull latest commits + apply
chezmoi update

# Show pending changes (short status)
chezmoi status

# Verify home matches source (exits 1 if drift)
chezmoi verify
```

## Managing files

```sh
# Track a new file (adds it to source dir)
chezmoi add ~/.config/foo/bar.toml

# Track as a template (allows {{ .chezmoi.hostname }} etc.)
chezmoi add --template ~/.config/foo/bar.toml

# Re-sync a file you edited in home back to source
chezmoi re-add ~/.config/foo/bar.toml

# Open a tracked file in your editor
chezmoi edit ~/.zshrc

# Edit, then immediately apply
chezmoi edit --apply ~/.zshrc
```

## Inspecting state

```sh
# List all managed files
chezmoi managed

# List unmanaged files in home
chezmoi unmanaged

# Show the source path for a target file
chezmoi source-path ~/.zshrc

# Show the target path for a source file
chezmoi target-path "$(chezmoi source-path)/dot_zshrc.tmpl"

# Render a template without applying
chezmoi execute-template < "$(chezmoi source-path)/dot_zshrc.tmpl"

# Print all template data available
chezmoi data
```

## Source directory

```sh
# Open source dir in $EDITOR
chezmoi cd

# Run a command inside source dir
chezmoi cd -- git log --oneline -10
```

## Troubleshooting

```sh
# chezmoi's own diagnostic check
chezmoi doctor

# Verbose apply (shows every file it touches)
chezmoi apply -v

# Dry-run apply (shows what would change, no writes)
chezmoi apply --dry-run

# Force re-run of a run_once script (reset its recorded hash)
chezmoi state delete-bucket --bucket=scriptState
```

## justfile shortcuts

```sh
just apply    # chezmoi apply
just verify   # chezmoi verify
just update   # chezmoi update
just doctor   # bash scripts/doctor/run.sh (all phases)
```
