#!/usr/bin/env bash
# Uninstall the dotfiles managed by this chezmoi source.
# Safe by default: prompts, backs up to a tarball, requires explicit flags for
# brew removal and user-data purge.
set -euo pipefail

yes=0
dry_run=0
no_backup=0
purge_brew=0
purge_data=0

usage() {
  cat >&2 <<EOF
usage: $(basename "$0") [--yes] [--dry-run] [--no-backup] [--purge-brew] [--purge-data]

Flags:
  --yes          Skip the confirmation prompt.
  --dry-run      Print actions without executing them.
  --no-backup    Skip the pre-destruction tarball of managed files.
  --purge-brew   Also run brew bundle cleanup --force against this Brewfile.
  --purge-data   Also remove shell history / atuin DB / mise & nvim installs.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --yes) yes=1 ;;
  --dry-run) dry_run=1 ;;
  --no-backup) no_backup=1 ;;
  --purge-brew) purge_brew=1 ;;
  --purge-data) purge_data=1 ;;
  -h | --help) usage ;;
  *)
    echo "unknown flag: $1" >&2
    usage
    ;;
  esac
  shift
done

run() {
  if ((dry_run)); then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

step() {
  printf '>>> step %d of 10: %s\n' "$1" "$2"
}

if ((yes == 0)); then
  cat <<EOF
This will UNINSTALL the dotfiles managed by chezmoi:
  - Backup current managed files to ~/dotfiles-backup-<ts>.tar.gz (unless --no-backup).
  - Unload launchd agents.
  - Revert the macOS defaults listed in scripts/macos-defaults-keys.txt.
  - Reset login shell to /bin/zsh (if currently Homebrew zsh).
  - Remove managed files, chezmoi source + state.
EOF
  if ((purge_brew)); then
    echo "  - [--purge-brew] Remove formulae listed in Brewfile."
  fi
  if ((purge_data)); then
    echo "  - [--purge-data] Remove ~/.local/share/{atuin,mise,nvim,zsh-plugins} and shell history."
  fi
  read -r -p "Continue? [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || {
    echo "aborted."
    exit 0
  }
fi

# Step 1: Capture managed-file list and cache Brewfile
step 1 "capture managed-file list and cache Brewfile"
MANAGED_LIST=$(mktemp)
trap 'rm -f "$MANAGED_LIST"' EXIT
chezmoi managed >"$MANAGED_LIST" 2>/dev/null || true

BREWFILE_CACHE=$(mktemp)
if [[ -f "$HOME/.local/share/chezmoi/Brewfile" ]]; then
  cp "$HOME/.local/share/chezmoi/Brewfile" "$BREWFILE_CACHE"
fi

# Step 2: Backup managed files to tarball
step 2 "backup managed files to tarball"
backup_written=""
if ((no_backup)); then
  echo "  skipped (--no-backup)"
else
  backup="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  # Build an existing-files-only list (chezmoi managed may list files that
  # were removed manually; skip them so tar doesn't error).
  existing_backup_list=$(mktemp)
  trap 'rm -f "$MANAGED_LIST" "$existing_backup_list"' EXIT
  while IFS= read -r rel; do
    [[ -e "$HOME/$rel" ]] && printf '%s\n' "$rel" >>"$existing_backup_list"
  done <"$MANAGED_LIST"
  if [[ -s "$existing_backup_list" ]]; then
    run tar -czf "$backup" -C "$HOME" -T "$existing_backup_list"
    echo "  → $backup"
    backup_written="$backup"
  else
    echo "  no managed files found in HOME; nothing to back up"
  fi
fi

# Step 3: Unload and remove launchd agents
step 3 "unload and remove launchd agents"
for label in local.chezmoi-update local.weekly-maintenance com.kulsin.chezmoi-update; do
  run launchctl bootout "gui/$UID" "$label" 2>/dev/null || true
  run rm -f "$HOME/Library/LaunchAgents/$label.plist"
done

# Step 4: Revert macOS defaults listed in scripts/macos-defaults-keys.txt
step 4 "revert macOS defaults listed in scripts/macos-defaults-keys.txt"
keys_file="$HOME/.local/share/chezmoi/scripts/macos-defaults-keys.txt"
if [[ -f "$keys_file" ]]; then
  while read -r domain key _type _value; do
    [[ -z "$domain" || "$domain" =~ ^# ]] && continue
    run defaults delete "$domain" "$key" 2>/dev/null || true
  done <"$keys_file"
  run killall Dock 2>/dev/null || true
else
  echo "  keys file not found; skipping"
fi

# Step 5: Reset login shell to /bin/zsh (if currently Homebrew zsh)
step 5 "reset login shell to /bin/zsh (if currently Homebrew zsh)"
current_shell=$(dscl . -read "/Users/$(whoami)" UserShell 2>/dev/null | awk '{print $2}' || echo "")
if [[ "$current_shell" == /opt/homebrew/* || "$current_shell" == /usr/local/* ]]; then
  run chsh -s /bin/zsh
else
  echo "  current shell is $current_shell; no change"
fi

# Step 6: Remove managed files from HOME
step 6 "remove managed files from HOME"
while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  path="$HOME/$rel"
  [[ -e "$path" || -L "$path" ]] && run rm -f "$path"
done <"$MANAGED_LIST"

# Step 7: Remove chezmoi source and state directories
step 7 "remove chezmoi source and state directories"
run rm -rf "$HOME/.local/share/chezmoi" "$HOME/.config/chezmoi" "$HOME/.cache/chezmoi"

# Step 8: Optional brew bundle cleanup
step 8 "optional: brew bundle cleanup (--purge-brew)"
if ((purge_brew)); then
  if [[ -s "$BREWFILE_CACHE" ]]; then
    run brew bundle cleanup --force --file "$BREWFILE_CACHE"
  else
    echo "  no cached Brewfile; skipping"
  fi
else
  echo "  skipped (--purge-brew not set)"
fi

# Step 9: Optional user-data purge
step 9 "optional: purge user shell data (--purge-data)"
if ((purge_data)); then
  for d in \
    "$HOME/.local/share/atuin" \
    "$HOME/.local/share/mise" \
    "$HOME/.local/share/nvim" \
    "$HOME/.local/share/zsh-plugins" \
    "$HOME/Library/Backups/atuin"; do
    [[ -e "$d" ]] && run rm -rf "$d"
  done
  for f in \
    "$HOME/.zsh_history" \
    "$HOME/.zcompdump" \
    "$HOME"/.zcompdump-*; do
    [[ -e "$f" ]] && run rm -f "$f"
  done
else
  echo "  skipped (--purge-data not set)"
fi

# Step 10: Final banner
step 10 "done"
if ((dry_run)); then
  echo "✓ dry-run complete; nothing was changed."
else
  echo "✓ uninstall complete."
  if [[ -n "$backup_written" ]]; then
    echo "  Backup: $backup_written"
  fi
fi
echo "  chezmoi binary ($HOME/.local/bin/chezmoi) preserved."
echo "  Homebrew itself preserved."
