#!/usr/bin/env bash
# run_k6.sh — spike k6 contra POST /extract + registro automático (Issues #1/#4).
#
# Ejecuta tests/load/k6-spike.js (rampa 10s→100 VUs, 20s sostenidos, 10s→0;
# PDF al azar por multipart) contra https://pdf-extractext.localhost/extract
# y registra la corrida en docs/test-runs/ vía scripts/record-run.sh,
# extrayendo req/s, % éxito y p50/p90/p95 del --summary-export de k6 (ms).
#
# Env:
#   TARGET_URL  endpoint atacado (default: https://pdf-extractext.localhost/extract)
#   RECORD=0    ataca sin registrar la corrida (ensayo; p.ej. contra un mock)

set -euo pipefail
cd "$(dirname "$0")/../.."

command -v k6 >/dev/null 2>&1 \
  || { echo "ERROR: falta k6 — https://grafana.com/docs/k6/latest/set-up/install/"; exit 1; }
command -v jq >/dev/null 2>&1 \
  || { echo "ERROR: falta jq — requerido para extraer las métricas del resumen k6"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"

# Fixtures regenerables (deterministas): siempre presentes antes de atacar.
bash tests/load/pdfs/generate_fixtures.sh

# El registro extrae la config del stack activo: sin stack no hay corrida.
if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' antes de la prueba de carga." >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

k6 run --summary-export="$WORK/summary.json" tests/load/k6-spike.js

# --- Métricas para el registro (unidades del TP: req/s, %, ms) ---
# k6 v2 exporta el trend plano con las claves de summaryTrendStats del script
# (p(50), p(90), p(95)) y el error rate en http_req_failed.value (0..1).
stat_ms() { # clave
  jq -r --arg k "$1" '.metrics.http_req_duration[$k]' "$WORK/summary.json" \
    | awk '{printf "%.1f", $1}'
}
p50=$(stat_ms 'p(50)')
p90=$(stat_ms 'p(90)')
p95=$(stat_ms 'p(95)')
throughput=$(jq -r '.metrics.http_reqs.rate' "$WORK/summary.json" | awk '{printf "%.2f", $1}')
success=$(jq -r '.metrics.http_req_failed.value' "$WORK/summary.json" | awk '{printf "%.1f", (1 - $1) * 100}')

echo
echo "== Corrida k6: ${throughput} req/s | éxito ${success}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms =="

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool k6 \
    --target "$TARGET_URL" \
    --load "spike k6: rampa 10s→100 VUs, 20s a 100 VUs, rampa 10s→0 (PDF al azar por multipart)" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Spike D11 contra POST /extract vía dominio público (tests/load/k6-spike.js)"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi
