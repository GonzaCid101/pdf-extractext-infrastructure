#!/usr/bin/env bash
# spike k6 contra POST /extract

set -euo pipefail
cd "$(dirname "$0")/../.."

source "$(dirname "$0")/lib/metrics.sh"

command -v k6 >/dev/null 2>&1 || { echo "ERROR: falta k6"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: falta jq"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"
TARGET_VUS="${TARGET_VUS:-100}"

BASE_URL="${BASE_URL:-${TARGET_URL%/extract}}"

if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' primero." >&2
  exit 1
fi

SUMMARY="tests/load/.k6-summary.json"
rm -f "$SUMMARY"

TARGET_VUS="$TARGET_VUS" BASE_URL="$BASE_URL" K6_SUMMARY_PATH="$SUMMARY" \
  k6 run ${K6_ARGS:-} tests/load/spike_tests.js || k6_rc=$?

# Extrae métricas vía helper puro
read -r throughput success p50 p90 p95 <<< "$(parse_k6_summary_json "$SUMMARY")"
if [ -f "$SUMMARY" ]; then
  failed=$(jq -r '.metrics.http_req_failed.values.rate // 0' "$SUMMARY" | awk '{printf "%.2f", $1 * 100}')
  total=$(jq -r '.metrics.http_reqs.values.count // 0' "$SUMMARY")
else
  failed=0 total=0
fi

rm -f "$SUMMARY"

echo
echo "== Corrida k6: ${total} reqs | ${throughput} req/s | éxito ${success}% | fallo ${failed}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms =="

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool k6 \
    --target "$TARGET_URL" \
    --load "spike k6: rampa 10s→${TARGET_VUS} VUs, 20s a ${TARGET_VUS} VUs, rampa 10s→0 (PDF oficial al azar)" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Spike contra POST /extract (${BASE_URL})"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi

exit "${k6_rc:-0}"
