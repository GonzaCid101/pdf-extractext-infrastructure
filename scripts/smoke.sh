#!/usr/bin/env bash
set -euo pipefail
export COMPOSE_PROGRESS=plain
cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
source "$(dirname "$0")/lib/common.sh"

require_cmd jq "ERROR: falta jq — requerido para validar la respuesta de /extract"

COMPOSE="docker compose"
CURL_IMG="curlimages/curl:8.10.1"
NET_SERVICES="pdf-extractext_services"
FAILURES=0
SMOKE_PHASE="${SMOKE_PHASE:-full}"

ok()   { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAILURES=$((FAILURES + 1)); }

finish() {
  echo
  if [ "$FAILURES" = "0" ]; then
    echo "SMOKE OK — todos los checks pasaron"
    exit 0
  fi
  echo "SMOKE FALLÓ — $FAILURES check(s) fallaron"
  exit 1
}

ENV_REPLICAS="${EXTRACTION_REPLICAS:-}"
set -a
# shellcheck disable=SC1091
. ./.env
set +a
if [ -n "$ENV_REPLICAS" ]; then
  EXTRACTION_REPLICAS="$ENV_REPLICAS"
else
  EXTRACTION_REPLICAS="${EXTRACTION_REPLICAS:-1}"
fi
export EXTRACTION_REPLICAS

echo "== Smoke tests: bootstrap pdf-extractext =="

check_stack() {
  $COMPOSE up -d --build >/dev/null
  UP=$($COMPOSE ps --status running --format '{{.Service}}' | sort -u | tr '\n' ' ')
  if [ "$UP" = "api consul extraction mongodb persistence traefik " ]; then
    ok "1. los 6 servicios están running"
  else
    fail "1. servicios running inesperados: [$UP]"
  fi
}

mongo_cid() { $COMPOSE ps -q mongodb; }

wait_mongo_healthy() {
  local cid s
  for _ in $(seq 1 30); do
    cid=$(mongo_cid)
    s=$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo starting)
    [ "$s" = "healthy" ] && return 0
    sleep 2
  done
  return 1
}

wait_dashboard() {
  local c
  for _ in $(seq 1 30); do
    c=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
      -s -o /dev/null -w '%{http_code}' --max-time 3 \
      -H "Host: traefik.pdf-extractext.localhost" http://traefik:8090/api/overview || echo 000)
    [ "$c" = "200" ] && return 0
    sleep 2
  done
  return 1
}

check_network_isolation() {
  local c1 c2 status code replicas

  c1=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s -o /dev/null -w '%{http_code}' --max-time 5 \
    -H "Host: traefik.pdf-extractext.localhost" http://traefik:8090/api/overview || echo 000)
  c2=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://traefik.pdf-extractext.localhost/api/overview || echo 000)
  if [ "$c1" = "200" ] && [ "$c2" != "200" ]; then
    ok "2. dashboard accesible solo en red interna (interno: $c1, público: $c2)"
  else
    fail "2. dashboard (interno: $c1, público: $c2 — esperaba 200 y no-200)"
  fi

  status=$(docker inspect -f '{{.State.Health.Status}}' "$(mongo_cid)" 2>/dev/null || echo missing)
  if [ "$status" = "healthy" ]; then
    ok "3. MongoDB healthy"
  else
    fail "3. MongoDB health status: $status"
  fi

  replicas=$($COMPOSE ps -q extraction | wc -l)
  if [ "$replicas" -ge 1 ]; then
    ok "4. Extraction running ($replicas réplica/s)"
  else
    fail "4. Extraction sin réplicas running"
  fi

  c1=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s -o /dev/null -w '%{http_code}' --max-time 5 http://extraction:8001/health || echo 000)
  c2=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s -o /dev/null -w '%{http_code}' --max-time 5 \
    -H "Host: extraction.pdf-extractext.localhost" http://traefik:8090/health || echo 000)
  if [ "$c1" = "200" ] && [ "$c2" = "200" ]; then
    ok "5. Extraction /health 200 (directo y vía Traefik interno)"
  else
    fail "5. Extraction /health en red interna (directo: $c1, traefik interno: $c2)"
  fi

  c1=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8001/health || echo 000)
  c2=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:80/health || echo 000)
  if [ "$c1" != "200" ] && [ "$c2" != "200" ]; then
    ok "6. Extraction no es público (host: $c1, traefik:80: $c2)"
  else
    fail "6. Extraction expuesto indebidamente (host: $c1, traefik:80: $c2)"
  fi

  code=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s -o /dev/null -w '%{http_code}' --max-time 5 http://persistence:8002/health || echo 000)
  if [ "$code" = "200" ]; then
    ok "7. Persistence /health 200 en red interna"
  else
    fail "7. Persistence /health en red interna: HTTP $code"
  fi

  c1=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8002/health || echo 000)
  c2=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:80/documents || echo 000)
  if [ "$c1" != "200" ] && [ "$c2" != "200" ]; then
    ok "8. Persistence no es público (host: $c1, traefik:80: $c2)"
  else
    fail "8. Persistence expuesto indebidamente (host: $c1, traefik:80: $c2)"
  fi

  local c1m=0 c2m=0
  nc -z -w 2 localhost 27017 2>/dev/null && c1m=1
  docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s --max-time 3 -o /dev/null telnet://mongodb:27017 2>/dev/null && c2m=1
  if [ "$c1m" = "0" ] && [ "$c2m" = "0" ]; then
    ok "11. MongoDB aislado (host y red de servicios)"
  else
    fail "11. MongoDB alcanzable (host: $c1m, red servicios: $c2m)"
  fi

  local c1p=0 c2p=0
  nc -z -w 2 localhost 8090 2>/dev/null && c1p=1
  c2p=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8090/health 2>/dev/null || true)
  if [ "$c1p" = "0" ] && [ "${c2p:0:3}" != "200" ]; then
    ok "15. entrypoint interno :8090 cerrado al host"
  else
    fail "15. :8090 accesible desde el host (tcp: $c1p, http: $c2p)"
  fi
}

consul_api() {
  $COMPOSE exec -T consul wget -qO- \
    --header="X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    "http://127.0.0.1:8500$1" 2>/dev/null
}

check_infra_consul() {
  local status
  status=$(docker inspect -f '{{.State.Health.Status}}' "$($COMPOSE ps -q consul)" 2>/dev/null || echo missing)
  if [ "$status" = "healthy" ]; then
    ok "I1. Consul healthy"
  else
    fail "I1. Consul health status: $status"
  fi

  if SMOKE_PHASE="$SMOKE_PHASE" bash scripts/consul-check.sh >/dev/null; then
    ok "I2. Consul con leader y KV cargado"
  else
    fail "I2. consul-check falló (leader o KV incompletos)"
  fi
}

check_traefik_consulcatalog() {
  local overview
  overview=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
    -s --max-time 5 -H "Host: traefik.pdf-extractext.localhost" \
    http://traefik:8090/api/overview || true)
  if printf '%s' "$overview" | grep -qi 'consulcatalog'; then
    ok "I3. Traefik con provider consulCatalog"
  else
    fail "I3. Traefik sin provider consulCatalog"
  fi

  if $COMPOSE logs traefik 2>&1 | grep -Eiq 'consul.*(403|permission denied|acl not found)'; then
    fail "I4. Traefik con errores de ACL contra Consul"
  else
    ok "I4. Traefik sin errores de ACL contra Consul"
  fi
}

check_catalog_pending() {
  local services service
  services=$(consul_api /v1/catalog/services || true)
  for service in api extraction persistence; do
    if printf '%s' "$services" | grep -q "\"$service\""; then
      ok "I5. $service registrado en el catálogo"
    elif [ "$SMOKE_PHASE" = "infra" ]; then
      echo "SKIP  I5. $service (fase infra)"
    else
      fail "I5. $service no registrado en el catálogo"
    fi
  done
}

fixture_pdf() {
  local out=$1 i xref
  local stream='BT /F1 12 Tf 72 720 Td (pdf-extractext smoke test) Tj ET'
  local -a off=()
  : > "$out"
  printf '%%PDF-1.4\n' >> "$out"
  off[1]=$(( $(wc -c < "$out") ))
  printf '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n' >> "$out"
  off[2]=$(( $(wc -c < "$out") ))
  printf '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n' >> "$out"
  off[3]=$(( $(wc -c < "$out") ))
  printf '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>\nendobj\n' >> "$out"
  off[4]=$(( $(wc -c < "$out") ))
  printf '4 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n' "$((${#stream} + 1))" "$stream" >> "$out"
  off[5]=$(( $(wc -c < "$out") ))
  printf '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n' >> "$out"
  xref=$(( $(wc -c < "$out") ))
  printf 'xref\n0 6\n0000000000 65535 f \n' >> "$out"
  for i in 1 2 3 4 5; do
    printf '%010d 00000 n \n' "${off[$i]}" >> "$out"
  done
  printf 'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' "$xref" >> "$out"
}

wait_api_200() {
  local url="$1" c
  for _ in $(seq 1 30); do
    c=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 3 "$url" || echo 000)
    [ "$c" = "200" ] && return 0
    sleep 2
  done
  return 1
}

check_e2e_extract() {
  local FIXTURE code
  SMOKE_TMP=$(mktemp -d)
  trap 'rm -rf "$SMOKE_TMP"' EXIT
  FIXTURE="$SMOKE_TMP/fixture.pdf"
  fixture_pdf "$FIXTURE"
  wait_api_200 https://pdf-extractext.localhost/ || true

  code=$(curl -sk -o "$SMOKE_TMP/extract-ok.json" -w '%{http_code}' --max-time 30 \
    -F "file=@${FIXTURE}" https://pdf-extractext.localhost/extract || true)
  : "${code:=000}"
  if [ "$code" = "200" ] && jq -e 'has("content") and has("page_count")' "$SMOKE_TMP/extract-ok.json" >/dev/null 2>&1; then
    ok "9. POST /extract con PDF: 200 con content y page_count"
  else
    fail "9. POST /extract con PDF: HTTP $code (esperaba 200 con content y page_count), cuerpo: $(head -c 300 "$SMOKE_TMP/extract-ok.json" 2>/dev/null || echo '<vacío>')"
  fi

  code=$(curl -sk -o "$SMOKE_TMP/extract-err.json" -w '%{http_code}' --max-time 30 \
    -F "otro-campo=@${FIXTURE}" https://pdf-extractext.localhost/extract || true)
  : "${code:=000}"
  if [ "$code" = "400" ] && jq -e '.code == "INVALID_REQUEST" and .status == 400 and .type' "$SMOKE_TMP/extract-err.json" >/dev/null 2>&1; then
    ok "10. POST /extract sin campo file: HTTP 400 con problem+json RFC 9457"
  else
    fail "10. POST /extract sin campo file: HTTP $code (esperaba 400 problem+json), cuerpo: $(head -c 300 "$SMOKE_TMP/extract-err.json" 2>/dev/null || echo '<vacio>')"
  fi
}

check_persistence() {
  local collection indexes MARKER found
  # Lee la colección configurada en Consul KV (default: documents).
  collection=$(consul_api '/v1/kv/pdf-extractext/config/persistence/MONGO_COLLECTION_NAME?raw' || true)
  collection="${collection:-documents}"
  indexes=$(docker exec "$(mongo_cid)" mongosh --quiet \
    -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin pdf_extractext \
    --eval "db.getCollection('$collection').getIndexes().filter(i => i.name === 'checksum_1' && i.unique === true).length")
  if [ "$indexes" = "1" ]; then
    ok "12. índice único checksum_1 creado por Persistence (colección: $collection)"
  else
    fail "12. índice checksum_1 no encontrado o no único en $collection (match: $indexes)"
  fi

  MARKER="smoke-$(date +%s)"
  MONGO() { docker exec "$(mongo_cid)" mongosh --quiet \
    -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin "$@" ; }
  MONGO smoke --eval "db.markers.insertOne({marker: '$MARKER'})" >/dev/null
  $COMPOSE down >/dev/null
  $COMPOSE up -d >/dev/null
  for _ in $(seq 1 30); do
    local s
    s=$(docker inspect -f '{{.State.Health.Status}}' "$(mongo_cid)" 2>/dev/null || echo starting)
    [ "$s" = "healthy" ] && break
    sleep 2
  done
  found=$(MONGO smoke --eval "db.markers.countDocuments({marker: '$MARKER'})" | tail -n1)
  MONGO smoke --eval "db.markers.deleteMany({})" >/dev/null
  if [ "$found" = "1" ]; then
    ok "13. datos persistieron tras down/up (volumen nombrado)"
  else
    fail "13. el documento de prueba no persistió (count=$found)"
  fi
}

check_git_hygiene() {
  local dirty=0
  git ls-files --error-unmatch .env >/dev/null 2>&1 && { dirty=1; echo "     .env está versionado"; }
  git ls-files | grep -Eq '\.pem$' && { dirty=1; echo "     hay certificados/claves TLS versionados"; }
  git ls-files | grep -Eq '(^|/)(mongodata|.*-data)/' && { dirty=1; echo "     hay datos runtime versionados"; }
  if [ "$dirty" = "0" ]; then
    ok "14. cero secretos/datos versionados"
  else
    fail "14. hay secretos o datos runtime versionados"
  fi
}

wait_catalog_services() {
  local services
  for _ in $(seq 1 15); do
    services=$(consul_api /v1/catalog/services 2>/dev/null || true)
    if printf '%s' "$services" | grep -q '"api"' \
      && printf '%s' "$services" | grep -q '"extraction"' \
      && printf '%s' "$services" | grep -q '"persistence"'; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if [ "$SMOKE_PHASE" = "infra" ]; then
  check_infra_consul
  check_traefik_consulcatalog
  check_catalog_pending
  finish
fi

check_stack
wait_dashboard || true
wait_mongo_healthy || true
wait_catalog_services || true

check_infra_consul
check_traefik_consulcatalog
check_catalog_pending
check_network_isolation
check_e2e_extract
check_persistence
check_git_hygiene

finish
