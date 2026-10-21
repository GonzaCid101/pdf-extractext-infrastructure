#!/usr/bin/env bash
# run_k6.sh — spike k6 contra POST /extract.
# Perfil del TP: ramp 0→100 VUs (10s), 100 VUs (20s), →0 (10s). Parametrizable con TARGET_VUS.

set -euo pipefail
cd "$(dirname "$0")/../.."

command -v k6 >/dev/null 2>&1 || { echo "ERROR: falta k6"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: falta jq"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"
TARGET_VUS="${TARGET_VUS:-100}"

# spike_tests.js construye `${BASE_URL}/extract`; se deriva el origen de TARGET_URL
# para que TARGET_URL sea la única perilla de destino (p. ej. un stub local).
BASE_URL="${BASE_URL:-${TARGET_URL%/extract}}"

if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' primero." >&2
  exit 1
fi

SUMMARY="tests/load/.k6-summary.json"
rm -f "$SUMMARY"

TARGET_VUS="$TARGET_VUS" BASE_URL="$BASE_URL" K6_SUMMARY_PATH="$SUMMARY" \
  k6 run ${K6_ARGS:-} tests/load/spike_tests.js || k6_rc=$?

# handleSummary escribe el JSON en formato de k6 v2.x (data.metrics.*.values.*).
stat_ms() {
  if [ -f "$SUMMARY" ]; then
    jq -r --arg k "$1" '.metrics.http_req_duration.values[$k] // 0' "$SUMMARY" | awk '{printf "%.1f", $1}'
  else
    echo 0
  fi
}
p50=$(stat_ms 'med')
p90=$(stat_ms 'p(90)')
p95=$(stat_ms 'p(95)')
if [ -f "$SUMMARY" ]; then
  throughput=$(jq -r '.metrics.http_reqs.values.rate // 0' "$SUMMARY" | awk '{printf "%.2f", $1}')
  success=$(jq -r '.metrics.extract_ok.values.rate // 0' "$SUMMARY" | awk '{printf "%.1f", $1 * 100}')
  failed=$(jq -r '.metrics.http_req_failed.values.rate // 0' "$SUMMARY" | awk '{printf "%.2f", $1 * 100}')
  total=$(jq -r '.metrics.http_reqs.values.count // 0' "$SUMMARY")
else
  throughput=0 success=0 failed=0 total=0
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
