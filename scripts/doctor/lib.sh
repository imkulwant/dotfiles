#!/usr/bin/env bash
# Doctor library: pass/fail counter, assertion helpers, colored output.
# Sourced by scripts/doctor/run.sh and every scripts/doctor/phase-*.sh.
# Idempotent — sourcing twice is a no-op (preserves counters).

if [ -n "${DOCTOR_LIB_LOADED:-}" ]; then
  return 0
fi
DOCTOR_LIB_LOADED=1

# ---------- Colors (honor NO_COLOR + non-tty) ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_GREEN=$'\033[0;32m'
  C_RED=$'\033[0;31m'
  C_YELLOW=$'\033[0;33m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_GREEN='' C_RED='' C_YELLOW='' C_BOLD='' C_DIM='' C_RESET=''
fi

# ---------- Source path ----------
# Allow overriding the chezmoi source path via CHEZMOI_SOURCE. This lets doctor
# run against an arbitrary checkout (e.g. CI's $GITHUB_WORKSPACE) without
# requiring `chezmoi init`. Falls back to `chezmoi source-path` when unset.
CHEZMOI_SOURCE="${CHEZMOI_SOURCE:-$(chezmoi source-path)}"
export CHEZMOI_SOURCE

# ---------- Counters ----------
DOCTOR_PASSED=0
DOCTOR_FAILED=0
DOCTOR_FAILURES=()
DOCTOR_CURRENT_CHECK=""
DOCTOR_CURRENT_PHASE=""

phase_start() {
  DOCTOR_CURRENT_PHASE="$1"
  printf "\n%sPhase %s — %s%s\n" "$C_BOLD" "$1" "$2" "$C_RESET"
}

phase_end() {
  : # reserved for per-phase footers if needed later
}

check() {
  DOCTOR_CURRENT_CHECK="$1"
}

pass() {
  DOCTOR_PASSED=$((DOCTOR_PASSED + 1))
  printf "  %s✓%s %s\n" "$C_GREEN" "$C_RESET" "$DOCTOR_CURRENT_CHECK"
}

fail() {
  DOCTOR_FAILED=$((DOCTOR_FAILED + 1))
  local reason="${1:-}"
  DOCTOR_FAILURES+=("[Phase ${DOCTOR_CURRENT_PHASE}] ${DOCTOR_CURRENT_CHECK}${reason:+ — ${reason}}")
  printf "  %s✗%s %s\n" "$C_RED" "$C_RESET" "$DOCTOR_CURRENT_CHECK"
  if [ -n "$reason" ]; then
    printf "      %s→ %s%s\n" "$C_YELLOW" "$reason" "$C_RESET"
  fi
}

info() {
  printf "  %s%s%s\n" "$C_DIM" "$1" "$C_RESET"
}

# ---------- Assertions ----------
# Each assertion calls pass/fail internally. Caller must call `check "<name>"` first.

assert_file() {
  if [ -f "$1" ]; then pass; else fail "file not found: $1"; fi
}

assert_no_file() {
  if [ ! -f "$1" ]; then pass; else fail "file still present: $1"; fi
}

assert_dir() {
  if [ -d "$1" ]; then pass; else fail "directory not found: $1"; fi
}

assert_grep() {
  local pattern="$1" file="$2"
  if [ ! -f "$file" ]; then
    fail "file not found: $file"
    return
  fi
  if grep -qE -- "$pattern" "$file"; then pass; else fail "pattern not found: '$pattern' in $file"; fi
}

assert_no_grep() {
  local pattern="$1" file="$2"
  if [ ! -f "$file" ]; then
    fail "file not found: $file"
    return
  fi
  if ! grep -qE -- "$pattern" "$file"; then pass; else fail "pattern still present: '$pattern' in $file"; fi
}

assert_cmd_ok() {
  if eval "$1" >/dev/null 2>&1; then pass; else fail "command failed: $1"; fi
}

assert_cmd_out() {
  local cmd="$1" expected="$2" out
  if ! out=$(eval "$cmd" 2>&1); then
    fail "command failed: $cmd"
    return
  fi
  if printf '%s' "$out" | grep -qE -- "$expected"; then
    pass
  else
    local first
    first=$(printf '%s' "$out" | head -1)
    fail "output did not match '$expected' (first line: $first)"
  fi
}

assert_perm() {
  local path="$1" expected="$2" actual
  if [ ! -e "$path" ]; then
    fail "path not found: $path"
    return
  fi
  actual=$(stat -f %A "$path" 2>/dev/null || stat -c %a "$path" 2>/dev/null || echo "?")
  if [ "$actual" = "$expected" ]; then pass; else fail "$path perms are $actual, expected $expected"; fi
}

assert_brew_installed() {
  if brew list --formula 2>/dev/null | grep -qx "$1"; then pass; else fail "brew formula '$1' not installed"; fi
}

assert_brew_cask_installed() {
  if brew list --cask 2>/dev/null | grep -qx "$1"; then pass; else fail "brew cask '$1' not installed"; fi
}

# ---------- Summary ----------

summary() {
  local total=$((DOCTOR_PASSED + DOCTOR_FAILED))
  printf "\n%sSummary:%s %d passed, %d failed (%d total)\n" \
    "$C_BOLD" "$C_RESET" "$DOCTOR_PASSED" "$DOCTOR_FAILED" "$total"
  if [ "$DOCTOR_FAILED" -gt 0 ]; then
    printf "\n%sFailed checks:%s\n" "$C_RED" "$C_RESET"
    for f in "${DOCTOR_FAILURES[@]}"; do
      printf "  %s✗%s %s\n" "$C_RED" "$C_RESET" "$f"
    done
    return 1
  fi
  return 0
}
