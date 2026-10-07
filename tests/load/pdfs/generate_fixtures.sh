#!/usr/bin/env bash
# generate_fixtures.sh — PDFs de prueba para las corridas de carga (Issue #4 / D11).
#
# Genera 4 PDFs mínimos y válidos (1, 3, 8 y 20 páginas) al vuelo, sin
# dependencias del host: se construyen objetos, offsets y tabla xref reales
# con printf/wc, de modo que cualquier parser (pypdf, pdfminer, poppler) los
# acepte. Son deterministas: regenerar produce bytes idénticos.
#
# Los PDFs son artefactos regenerables y NO se versionan (.gitignore);
# este script (o make load-k6 / load-vegeta) los crea si faltan.

set -euo pipefail
cd "$(dirname "$0")/../../.."  # raíz del repo

OUT_DIR="tests/load/pdfs"
mkdir -p "$OUT_DIR"

# make_pdf <salida> <paginas>: PDF de una sola fuente tipográfica, con texto
# distinto por página. Objeto 1: catálogo; 2: árbol de páginas; impares: páginas
# (3, 5, 7...); el siguiente: contenido de esa página; último: la fuente.
make_pdf() { # salida, paginas
  local out=$1 pages=$2 i id font_id xref stream
  local -a off=() kids=()
  for ((i = 1; i <= pages; i++)); do
    kids+=("$((2 * i + 1)) 0 R")
  done
  font_id=$((2 * pages + 3))
  : > "$out"
  printf '%%PDF-1.4\n' >> "$out"
  off[1]=$(( $(wc -c < "$out") ))
  printf '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n' >> "$out"
  off[2]=$(( $(wc -c < "$out") ))
  printf '2 0 obj\n<< /Type /Pages /Kids [%s] /Count %d >>\nendobj\n' "${kids[*]}" "$pages" >> "$out"
  for ((i = 1; i <= pages; i++)); do
    id=$((2 * i + 1))
    off[$id]=$(( $(wc -c < "$out") ))
    printf '%d 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 %d 0 R >> >> /Contents %d 0 R >>\nendobj\n' \
      "$id" "$font_id" "$((id + 1))" >> "$out"
    off[$((id + 1))]=$(( $(wc -c < "$out") ))
    stream="BT /F1 12 Tf 72 720 Td (pdf-extractext load fixture p${i}/${pages}) Tj ET"
    printf '%d 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n' \
      "$((id + 1))" "$((${#stream} + 1))" "$stream" >> "$out"
  done
  off[$font_id]=$(( $(wc -c < "$out") ))
  printf '%d 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n' "$font_id" >> "$out"
  xref=$(( $(wc -c < "$out") ))
  printf 'xref\n0 %d\n0000000000 65535 f \n' "$((font_id + 1))" >> "$out"
  for ((i = 1; i <= font_id; i++)); do
    printf '%010d 00000 n \n' "${off[$i]}" >> "$out"
  done
  printf 'trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' \
    "$((font_id + 1))" "$xref" >> "$out"
}

echo "== Generando fixtures de carga en $OUT_DIR/ =="
declare -A PAGES=( [fixture-1p.pdf]=1 [fixture-3p.pdf]=3 [fixture-8p.pdf]=8 [fixture-20p.pdf]=20 )
for name in "${!PAGES[@]}"; do
  make_pdf "$OUT_DIR/$name" "${PAGES[$name]}"
  printf '  %-18s %5s bytes  %2s páginas\n' "$name" "$(wc -c < "$OUT_DIR/$name")" "${PAGES[$name]}"
done

# Validación opcional: verifica estructura y cantidad de páginas si poppler
# está disponible; si no, la validez la garantiza la construcción (xref real).
if command -v pdfinfo >/dev/null 2>&1; then
  for name in "${!PAGES[@]}"; do
    got=$(pdfinfo "$OUT_DIR/$name" | awk '/^Pages:/{print $2}')
    want=${PAGES[$name]}
    [ "$got" = "$want" ] || { echo "ERROR: $name tiene $got páginas, esperaba $want" >&2; exit 1; }
  done
  echo "Fixtures validados con pdfinfo (estructura y páginas)."
fi
