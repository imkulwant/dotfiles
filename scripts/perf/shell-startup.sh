#!/usr/bin/env bash
# Benchmark zsh startup time and check against performance budget.

set -euo pipefail

budget_check="${1:---}"

if [[ "$budget_check" == "--budget-check" ]]; then
  # Run with JSON export, parse mean, compare to budget
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  hyperfine --warmup 3 --min-runs 10 --export-json "$tmpfile" -N 'zsh -c exit' >/dev/null 2>&1

  # Extract mean (in seconds) from JSON
  mean_seconds=$(yq eval '.results[0].mean' "$tmpfile")

  # Convert to milliseconds (integer)
  mean_ms=$(awk "BEGIN{printf \"%d\", $mean_seconds*1000}")

  # Read budget from .chezmoidata.yaml
  budget_ms=$(yq eval '.perf.shell_budget_ms' "$(chezmoi source-path)/.chezmoidata.yaml")

  # Check budget
  if ((mean_ms > budget_ms)); then
    echo "shell startup ${mean_ms}ms exceeded budget ${budget_ms}ms — try: ZSH_PROFILE=1 zsh"
    exit 1
  fi
  exit 0
else
  # No flag: run hyperfine and show output, always exit 0
  hyperfine --warmup 3 --min-runs 10 -N 'zsh -c exit' || true
  exit 0
fi
