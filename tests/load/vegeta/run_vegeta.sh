#!/usr/bin/env bash
# run_vegeta.sh — ataque Vegeta 50 req/s × 30s contra POST /extract (4 PDF oficiales).
#
# Cada target lleva Content-Length para que Vegeta sepa cuántos bytes leer como
# cuerpo (evitando @archivo, que v12 rechaza con "bad target"). Un único ataque
# rota uniformemente entre los 4 targets a 50 req/s durante 30s (timeout 30s,
# -insecure). Perfil (D11): 50 req/s durante 30s, timeout 30s, -insecure (TLS mkcert).
#
# Env:
#   TARGET_URL  endpoint atacado (default: https://pdf-extractext.localhost/extract)
#   RECORD=0    ataca sin registrar la corrida (ensayo; p.ej. contra un mock)

set -euo pipefail
cd "$(dirname "$0")/../../.."

command -v vegeta >/dev/null 2>&1 || { echo "ERROR: falta vegeta"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: falta jq"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"
RATE="1/s"
DURATION="30s"
TIMEOUT="30s"
BOUNDARY="pdf-extractext-vegeta-boundary"

if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' primero." >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

PDFS=(
  "2020-Scrum-Guide-Spanish-Latin-South-American.pdf"
  "Essential-Kanban-Condensed-Spanish.pdf"
  "Filosofia Lean.pdf"
  "scrum_manager_historias_usuario.pdf"
)

for pdf in "${PDFS[@]}"; do
  [ -f "tests/load/pdfs/$pdf" ] || { echo "ERROR: falta tests/load/pdfs/$pdf" >&2; exit 1; }
done

# Generar los 4 cuerpos multipart (uno por PDF oficial) y un target por cada uno.
# Cada target incluye Content-Length para que Vegeta lea exactamente el cuerpo.
TARGETS="$WORK/targets.txt"
: > "$TARGETS"
for pdf in "${PDFS[@]}"; do
  body="$WORK/body-$(printf '%s' "$pdf" | tr '/' '_')"
  {
    printf -- '--%s\r\n' "$BOUNDARY"
    printf 'Content-Disposition: form-data; name="file"; filename="%s"\r\n' "$pdf"
    printf 'Content-Type: application/pdf\r\n\r\n'
    cat "tests/load/pdfs/$pdf"
    printf '\r\n--%s--\r\n' "$BOUNDARY"
  } > "$body"

  len=$(wc -c < "$body")
  {
    printf 'POST %s\n' "$TARGET_URL"
    printf 'Content-Type: multipart/form-data; boundary=%s\n' "$BOUNDARY"
    printf 'Content-Length: %s\n' "$len"
    printf '\n'
    cat "$body"
    printf '\n'
  } >> "$TARGETS"
done

echo "== Vegeta: ${RATE} durante ${DURATION} (timeout ${TIMEOUT}) contra ${TARGET_URL} =="
vegeta attack -targets="$TARGETS" -rate="$RATE" -duration="$DURATION" -timeout="$TIMEOUT" \
  -insecure -output="$WORK/results.bin"

echo
echo "== Reporte del ataque =="
vegeta report --type=text "$WORK/results.bin"
vegeta report --type=json "$WORK/results.bin" > "$WORK/report.json"

# --- Métricas globales (unidades del TP: req/s, %, ms) ---
if [ -f "$WORK/report.json" ] && [ -s "$WORK/report.json" ]; then
  p50=$(jq -r '.latencies["50th"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  p95=$(jq -r '.latencies["95th"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  p90=$(vegeta encode --to=json "$WORK/results.bin" \
    | jq -s 'map(.latency) | sort | .[(length * 90 / 100 | ceil) - 1] // 0' \
    | awk '{printf "%.1f", $1 / 1e6}')
  throughput=$(jq -r '.throughput // 0' "$WORK/report.json" | awk '{printf "%.2f", $1}')
  success=$(jq -r '.success // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 * 100}')
else
  p50=0 p90=0 p95=0 throughput=0 success=0
fi

echo
echo "== Corrida vegeta: ${throughput} req/s | éxito ${success}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms =="

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool vegeta \
    --target "$TARGET_URL" \
    --load "vegeta ${RATE} × ${DURATION} (4 PDFs oficiales rotados por multipart, timeout ${TIMEOUT})" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Ataque sostenido contra POST /extract vía dominio público"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi
