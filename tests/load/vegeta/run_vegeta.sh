#!/usr/bin/env bash
# run_vegeta.sh — ataque Vegeta 50 req/s × 30s contra POST /extract + registro
# automático (Issues #1/#4, ADR D11).
#
# Vegeta no arma multipart/form-data por sí solo: se pre-compilan los cuerpos
# binarios de las peticiones (framing MIME con boundary fija, cabeceras y
# bytes de cada PDF) para los 4 fixtures de tests/load/pdfs/, y un archivo
# targets que referencia cada cuerpo con @fichero. Vegeta rota los 4 targets
# uniformemente. El reporte de texto va a stdout; las métricas para el
# registro salen del reporte JSON (p50/p95) y de los resultados individuales
# (p90, nearest-rank; Vegeta no reporta p90 nativamente), en ns → ms.
#
# Perfil (D11): 50 req/s durante 30s, timeout 30s, -insecure (TLS mkcert).
#
# Env:
#   TARGET_URL  endpoint atacado (default: https://pdf-extractext.localhost/extract)
#   RECORD=0    ataca sin registrar la corrida (ensayo; p.ej. contra un mock)

set -euo pipefail
cd "$(dirname "$0")/../../.."

command -v vegeta >/dev/null 2>&1 \
  || { echo "ERROR: falta vegeta — instalalo con: go install github.com/tsenart/vegeta@latest"; exit 1; }
command -v jq >/dev/null 2>&1 \
  || { echo "ERROR: falta jq — requerido para extraer las métricas del reporte de Vegeta"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"
RATE="50/s"
DURATION="30s"
TIMEOUT="30s"
BOUNDARY="pdf-extractext-vegeta-boundary"

# Fixtures regenerables (deterministas): siempre presentes antes de atacar.
bash tests/load/pdfs/generate_fixtures.sh

# El registro extrae la config del stack activo: sin stack no hay corrida.
if [ "$RECORD" = "1" ] && [ -z "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "ERROR: el stack no está levantado — ejecutá 'make up' antes de la prueba de carga." >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- Pre-compilación de los cuerpos multipart (uno por fixture) ---
TARGETS="$WORK/targets.txt"
: > "$TARGETS"
for pdf in tests/load/pdfs/fixture-*.pdf; do
  name=$(basename "$pdf")
  body="$WORK/body-${name}"
  {
    printf -- '--%s\r\n' "$BOUNDARY"
    printf 'Content-Disposition: form-data; name="file"; filename="%s"\r\n' "$name"
    printf 'Content-Type: application/pdf\r\n\r\n'
    cat "$pdf"
    printf '\r\n--%s--\r\n' "$BOUNDARY"
  } > "$body"
  {
    printf 'POST %s\n' "$TARGET_URL"
    printf 'Content-Type: multipart/form-data; boundary=%s\n' "$BOUNDARY"
    printf '@%s\n\n' "$body"
  } >> "$TARGETS"
done

echo "== Vegeta: ${RATE} durante ${DURATION} (timeout ${TIMEOUT}) contra ${TARGET_URL} =="
vegeta attack -targets="$TARGETS" -rate="$RATE" -duration="$DURATION" -timeout="$TIMEOUT" \
  -insecure -output="$WORK/results.bin"

echo
echo "== Reporte del ataque =="
vegeta report --type=text "$WORK/results.bin"

vegeta report --type=json "$WORK/results.bin" > "$WORK/report.json"

# --- Métricas para el registro (unidades del TP: req/s, %, ms) ---
# throughputs: req/s efectivos; success: 0..1 -> %; latencias: ns -> ms.
p50=$(jq -r '.latencies["50th"]' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
p95=$(jq -r '.latencies["95th"]' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
# p90 no viene en el reporte: se calcula por nearest-rank sobre las latencias
# individuales (encode --to=json emite un JSON por resultado, latency en ns).
p90=$(vegeta encode --to=json "$WORK/results.bin" \
  | jq -s 'map(.latency) | sort | .[(length * 90 / 100 | ceil) - 1] // 0' \
  | awk '{printf "%.1f", $1 / 1e6}')
throughput=$(jq -r '.throughput' "$WORK/report.json" | awk '{printf "%.2f", $1}')
success=$(jq -r '.success' "$WORK/report.json" | awk '{printf "%.1f", $1 * 100}')

echo
echo "== Corrida vegeta: ${throughput} req/s | éxito ${success}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms =="

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool vegeta \
    --target "$TARGET_URL" \
    --load "vegeta ${RATE} × ${DURATION} (4 PDFs rotados por multipart, timeout ${TIMEOUT})" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Ataque sostenido D11 contra POST /extract vía dominio público (tests/load/vegeta/run_vegeta.sh)"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi
