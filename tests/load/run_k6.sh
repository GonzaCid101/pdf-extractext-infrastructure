#!/usr/bin/env bash
# run_k6.sh — spike k6 contra POST /extract.

set -euo pipefail
cd "$(dirname "$0")/../.."

command -v k6 >/dev/null 2>&1 || { echo "ERROR: falta k6"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: falta jq"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"

if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' primero." >&2
  exit 1
fi

SUMMARY="tests/load/.k6-summary.json"
rm -f "$SUMMARY"

k6 run --summary-export="$SUMMARY" ${K6_ARGS:-} tests/load/spike_tests.js || k6_rc=$?

stat_ms() {
  if [ -f "$SUMMARY" ]; then
    jq -r --arg k "$1" '.metrics.http_req_duration[$k] // 0' "$SUMMARY" | awk '{printf "%.1f", $1}'
  else
    echo 0
  fi
}
p50=$(stat_ms 'med')
p90=$(stat_ms 'p(90)')
p95=$(stat_ms 'p(95)')
if [ -f "$SUMMARY" ]; then
  throughput=$(jq -r '.metrics.http_reqs.rate // 0' "$SUMMARY" | awk '{printf "%.2f", $1}')
  success=$(jq -r '.metrics.extract_ok.value // 0' "$SUMMARY" | awk '{printf "%.1f", $1 * 100}')
else
  throughput=0 success=0
fi

rm -f "$SUMMARY"

echo
echo "== Corrida k6: ${throughput} req/s | éxito ${success}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms =="

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool k6 \
    --target "$TARGET_URL" \
    --load "spike k6: rampa 10s→100 VUs, 20s a 100 VUs, rampa 10s→0 (PDF oficial al azar por multipart)" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Spike contra POST /extract vía dominio público"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi

exit "${k6_rc:-0}"
