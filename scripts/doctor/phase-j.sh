#!/usr/bin/env bash
# Phase J — CI + hygiene

phase_start "J" "CI + hygiene"

SOURCE="$CHEZMOI_SOURCE"

# ── pre-commit ────────────────────────────────────────────────────────────────
check ".pre-commit-config.yaml exists"
assert_file "$SOURCE/.pre-commit-config.yaml"

check ".pre-commit config includes shellcheck"
assert_grep 'shellcheck' "$SOURCE/.pre-commit-config.yaml"

check ".pre-commit config includes shfmt"
assert_grep 'shfmt' "$SOURCE/.pre-commit-config.yaml"

check ".pre-commit config includes trailing-whitespace"
assert_grep 'trailing-whitespace' "$SOURCE/.pre-commit-config.yaml"

check ".pre-commit config includes check-merge-conflict"
assert_grep 'check-merge-conflict' "$SOURCE/.pre-commit-config.yaml"

check "pre-commit installed"
assert_cmd_ok "pre-commit --version"

check "pre-commit hook registered in .git/hooks"
assert_file "$SOURCE/.git/hooks/pre-commit"

# ── GitHub Actions ────────────────────────────────────────────────────────────
check "GitHub Actions CI workflow exists"
assert_file "$SOURCE/.github/workflows/ci.yml"

check "CI workflow runs shellcheck"
assert_grep 'shellcheck' "$SOURCE/.github/workflows/ci.yml"

check "CI workflow runs shfmt"
assert_grep 'shfmt' "$SOURCE/.github/workflows/ci.yml"

check "CI workflow runs just doctor"
assert_grep 'just doctor' "$SOURCE/.github/workflows/ci.yml"

check "CI workflow runs chezmoi apply --dry-run"
assert_grep 'chezmoi apply --dry-run' "$SOURCE/.github/workflows/ci.yml"

check "CI workflow runs formula drift check"
assert_grep 'formula-drift-check' "$SOURCE/.github/workflows/ci.yml"

# ── justfile ──────────────────────────────────────────────────────────────────
for target in apply verify doctor update; do
  check "justfile exposes '$target' target"
  assert_grep "^${target}" "$SOURCE/justfile"
done

# ── Shell script quality ──────────────────────────────────────────────────────
check "shellcheck passes on all doctor scripts"
assert_cmd_ok "find '$SOURCE/scripts/doctor' -name '*.sh' | xargs shellcheck --severity=warning"

check "shfmt finds no formatting differences in doctor scripts"
assert_cmd_ok "find '$SOURCE/scripts/doctor' -name '*.sh' | xargs shfmt -d -i 2"

# ── Formula drift ─────────────────────────────────────────────────────────────
check "No managed file references a formula not in Brewfile"
assert_cmd_ok "'$SOURCE/scripts/doctor/formula-drift-check.sh'"

# ── CI tools installed ────────────────────────────────────────────────────────
check "shellcheck installed"
assert_cmd_ok "shellcheck --version"

check "shfmt installed"
assert_cmd_ok "shfmt --version"

check "pre-commit installed"
assert_cmd_ok "pre-commit --version"

phase_end
