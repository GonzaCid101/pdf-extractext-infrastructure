#!/usr/bin/env bash
# Helpers compartidos por los tests de contrato de infraestructura.

set -uo pipefail

PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  printf '  PASS  %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  FAIL  %s\n' "$1"
}

assert_file() {
  local file=$1
  [ -f "$file" ] && pass "existe $file" || fail "falta $file"
}

assert_contains() {
  local file=$1 needle=$2 label=$3
  grep -qF -- "$needle" "$file" && pass "$label" || fail "$label"
}

assert_not_contains() {
  local file=$1 needle=$2 label=$3
  grep -qF -- "$needle" "$file" && fail "$label" || pass "$label"
}

assert_eq() {
  local expected=$1 actual=$2 label=$3
  [ "$expected" = "$actual" ] && pass "$label" \
    || fail "$label (esperado: $expected, obtenido: $actual)"
}

summary() {
  echo "  -- $PASS PASS / $FAIL FAIL"
  [ "$FAIL" -eq 0 ]
}
