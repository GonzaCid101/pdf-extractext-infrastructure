#!/usr/bin/env bash
# run_vegeta.sh — ataque Vegeta contra POST /extract con los 4 PDFs oficiales.
# Perfil D11: 50 req/s × 30s (1.500 reqs), timeout 30s, -insecure.
# Targets en formato JSON (body base64): Vegeta >= v12 ya no acepta el body embebido en formato HTTP.
#
# Env: TARGET_URL (default https://pdf-extractext.localhost/extract), RECORD=0 para ensayo sin registrar,
#      RATE/DURATION/TIMEOUT para override, KEEP_RESULTS=1 para conservar results.bin.

set -euo pipefail
cd "$(dirname "$0")/../../.."

# vegeta puede estar en PATH o en $HOME/go/bin (instalación con `go install`).
VEGETA="$(command -v vegeta 2>/dev/null || true)"
if [ -z "$VEGETA" ] && [ -x "$HOME/go/bin/vegeta" ]; then
  VEGETA="$HOME/go/bin/vegeta"
fi
[ -n "$VEGETA" ] || { echo "ERROR: falta vegeta (PATH o \$HOME/go/bin)"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: falta jq"; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo "ERROR: falta base64"; exit 1; }

RECORD="${RECORD:-1}"
TARGET_URL="${TARGET_URL:-https://pdf-extractext.localhost/extract}"
RATE="${RATE:-50/s}"
DURATION="${DURATION:-30s}"
TIMEOUT="${TIMEOUT:-30s}"
BOUNDARY="pdf-extractext-vegeta-boundary"
KEEP_RESULTS="${KEEP_RESULTS:-0}"

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

# Genera un target JSON por PDF (body multipart en base64), rotados por Vegeta en round-robin.
TARGETS="$WORK/targets.json"
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

  b64file="$body.b64"
  base64 -w0 "$body" > "$b64file"
  # jq lee el base64 desde archivo (-Rs) para evitar "argument list too long" con PDFs grandes.
  jq -cn --arg url "$TARGET_URL" --arg b "$BOUNDARY" \
    '{method:"POST", url:$url, header:{"Content-Type":["multipart/form-data; boundary=\($b)"]}, body:$body}' \
    --rawfile body "$b64file" \
    >> "$TARGETS"
done

echo "== Vegeta: ${RATE} durante ${DURATION} (timeout ${TIMEOUT}) contra ${TARGET_URL} =="
"$VEGETA" attack -format=json -targets="$TARGETS" -rate="$RATE" -duration="$DURATION" -timeout="$TIMEOUT" \
  -insecure -output="$WORK/results.bin"

echo
echo "== Reporte del ataque =="
"$VEGETA" report --type=text "$WORK/results.bin"
"$VEGETA" report --type=json "$WORK/results.bin" > "$WORK/report.json"

# --- Métricas globales (unidades del TP: req/s, %, ms) ---
if [ -f "$WORK/report.json" ] && [ -s "$WORK/report.json" ]; then
  p50=$(jq -r '.latencies["50th"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  p95=$(jq -r '.latencies["95th"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  p90=$(jq -r '.latencies["90th"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  pmax=$(jq -r '.latencies["max"] // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 / 1e6}')
  throughput=$(jq -r '.throughput // 0' "$WORK/report.json" | awk '{printf "%.2f", $1}')
  success=$(jq -r '.success // 0' "$WORK/report.json" | awk '{printf "%.1f", $1 * 100}')
  total=$(jq -r '.requests // 0' "$WORK/report.json")
else
  p50=0 p90=0 p95=0 pmax=0 throughput=0 success=0 total=0
fi

echo
echo "== Corrida vegeta: ${total} reqs | ${throughput} req/s | éxito ${success}% | p50 ${p50} ms | p90 ${p90} ms | p95 ${p95} ms | max ${pmax} ms =="

if [ "$KEEP_RESULTS" = "1" ]; then
  OUT="docs/test-runs/vegeta-$(date -u +%Y%m%dT%H%M%SZ)-results.bin"
  mkdir -p docs/test-runs
  cp "$WORK/results.bin" "$OUT"
  echo "(results.bin conservado en $OUT)"
fi

if [ "$RECORD" = "1" ]; then
  ./scripts/record-run.sh \
    --tool vegeta \
    --target "$TARGET_URL" \
    --load "vegeta ${RATE} × ${DURATION} (4 PDFs oficiales rotados por multipart, timeout ${TIMEOUT})" \
    --throughput "$throughput" \
    --success "$success" \
    --p50 "$p50" --p90 "$p90" --p95 "$p95" \
    --desc "Ataque sostenido contra POST /extract (${TARGET_URL})"
else
  echo "(RECORD=0: corrida de ensayo, NO registrada en docs/test-runs/)"
fi
