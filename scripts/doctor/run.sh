#!/usr/bin/env bash
# Doctor orchestrator. Sources lib.sh, runs one or more phase-*.sh, prints summary.
# Usage:
#   scripts/doctor/run.sh            # all phases in order
#   scripts/doctor/run.sh C          # just Phase C
#   scripts/doctor/run.sh C D G      # subset
# Exit 0 iff all checks pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Ordered phase letters. Update when new phases are added.
ALL_PHASES=(a c d e f g h i j k l m n)

if [ "$#" -eq 0 ]; then
  PHASES=("${ALL_PHASES[@]}")
else
  PHASES=()
  for arg in "$@"; do
    PHASES+=("$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')")
  done
fi

for phase in "${PHASES[@]}"; do
  script="$SCRIPT_DIR/phase-${phase}.sh"
  if [ ! -f "$script" ]; then
    printf "%swarning:%s no doctor script for phase '%s' (%s)\n" \
      "$C_YELLOW" "$C_RESET" "$phase" "$script"
    continue
  fi
  # shellcheck disable=SC1090
  source "$script"
done

summary
