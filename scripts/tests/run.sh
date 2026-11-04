#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

failed=0
for test in scripts/tests/test_*.sh; do
  echo "== $test"
  if ! bash "$test"; then
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "TEST-INFRA FALLÓ"
  exit 1
fi

echo "TEST-INFRA OK"
