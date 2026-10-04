#!/usr/bin/env bash
set -euo pipefail

# Polished install wrapper around chezmoi's one-liner bootstrap.
# Provides pre-flight checks and idempotent re-run semantics.

# 1. Platform check
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer targets macOS. Detected: $(uname -s)." >&2
  exit 1
fi

# Warn (don't fail) if macOS < 14 Sonoma
macos_major=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1 || echo 0)
if [[ "$macos_major" -lt 14 ]]; then
  echo "warning: macOS 14 (Sonoma) or newer recommended; found $(sw_vers -productVersion)." >&2
fi

# 2. Xcode CLT detection + auto-install + poll
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools missing. Triggering install..."
  xcode-select --install 2>/dev/null || true
  echo "Waiting for Xcode CLT to finish installing (max 20 min)..."
  elapsed=0
  while ! xcode-select -p >/dev/null 2>&1; do
    if ((elapsed >= 1200)); then
      echo "error: Xcode CLT did not install within 20 minutes." >&2
      exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    if ((elapsed % 60 == 0)); then
      printf '.'
    fi
  done
  echo
  echo "Xcode CLT installed."
fi

# 3. Network reachability
if ! curl -fsI https://get.chezmoi.io -o /dev/null; then
  echo "error: cannot reach https://get.chezmoi.io. Check network." >&2
  exit 1
fi

# 4. Disk space (≥ 2 GB free)
free_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
if ((free_kb < 2000000)); then
  echo "error: < 2 GB free in \$HOME. Available: ${free_kb} KB." >&2
  exit 1
fi

# 5. Idempotent branch: existing install → apply; fresh → bootstrap
if [ -d "$HOME/.local/share/chezmoi" ]; then
  echo "chezmoi source present at $HOME/.local/share/chezmoi. Running apply..."
  chezmoi apply
else
  echo "Bootstrapping chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply imkulwant
fi

# 6. Final verification
echo "Running doctor..."
if command -v just >/dev/null 2>&1; then
  just doctor || true
fi

echo
echo "✓ bootstrap complete. See docs/features.md for what was installed."
