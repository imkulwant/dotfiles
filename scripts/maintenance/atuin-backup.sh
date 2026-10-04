#!/usr/bin/env bash
# Rotate atuin history DB snapshots. Keeps the 8 newest in ~/Library/Backups/atuin/.
set -euo pipefail

SRC="$HOME/.local/share/atuin/history.db"
DST_DIR="$HOME/Library/Backups/atuin"

if [[ ! -f "$SRC" ]]; then
  echo "atuin DB not found at $SRC; nothing to back up."
  exit 0
fi

mkdir -p "$DST_DIR"
dst="$DST_DIR/history-$(date +%Y%m%d).db"
cp "$SRC" "$dst"
echo "backed up to $dst"

# Retention: keep 8 newest history-*.db
mapfile -t backups < <(find "$DST_DIR" -maxdepth 1 -name 'history-*.db' -print | sort -r)
if ((${#backups[@]} > 8)); then
  for old in "${backups[@]:8}"; do
    rm -f "$old"
    echo "pruned $old"
  done
fi
