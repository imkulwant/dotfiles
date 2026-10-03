#!/usr/bin/env bash
# Benchmark zsh startup time and check against performance budget.

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
source_dir=$(cd "$script_dir/../.." && pwd)

case "${1:-}" in
--budget-check)
  # Run with JSON export, parse mean, compare to budget
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  hyperfine --warmup 3 --min-runs 10 --export-json "$tmpfile" --ignore-failure -N 'zsh -i -c exit' >/dev/null 2>&1

  # Extract mean (in seconds) from JSON
  mean_seconds=$(jq -r '.results[0].mean' "$tmpfile")

  # Convert to milliseconds (integer)
  mean_ms=$(awk "BEGIN{printf \"%d\", $mean_seconds*1000}")

  # Read budget from .chezmoidata.yaml
  budget_ms=$(yq eval '.perf.shell_budget_ms' "$source_dir/.chezmoidata.yaml")

  # Check budget
  if ((mean_ms > budget_ms)); then
    echo "shell startup ${mean_ms}ms exceeded budget ${budget_ms}ms — try: ZSH_PROFILE=1 zsh"
    exit 1
  fi
  exit 0
  ;;
"")
  # No flag: run hyperfine and show output, always exit 0
  hyperfine --warmup 3 --min-runs 10 --ignore-failure -N 'zsh -i -c exit' || true
  exit 0
  ;;
*)
  echo "usage: $(basename "$0") [--budget-check]" >&2
  exit 2
  ;;
esac
