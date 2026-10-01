#!/usr/bin/env bash
# Smoke tests del bootstrap: servicios arriba, aislamiento por redes,
# persistencia del volumen e higiene del repo.
set -euo pipefail
export COMPOSE_PROGRESS=plain
cd "$(dirname "$0")/.."

COMPOSE="docker compose"
CURL_IMG="curlimages/curl:8.10.1"
NET_SERVICES="pdf-extractext_services"
FAILURES=0

ok()   { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAILURES=$((FAILURES + 1)); }

# Carga .env para el test de persistencia.
set -a; . ./.env; set +a

echo "== Smoke tests: bootstrap pdf-extractext =="

# 1) compose up termina con los 3 servicios arriba
$COMPOSE up -d --build >/dev/null
UP=$($COMPOSE ps --status running --format '{{.Service}}' | sort | tr '\n' ' ')
if [ "$UP" = "extraction mongodb traefik " ]; then
  ok "1. los 3 servicios están running"
else
  fail "1. servicios running inesperados: [$UP]"
fi

# Esperar readiness antes de verificar (ventana de arranque).
wait_url() { # url, intentos
  local url=$1 tries=${2:-30} c
  for _ in $(seq 1 "$tries"); do
    c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" || echo 000)
    [ "$c" != "000" ] && return 0; sleep 2
  done
  return 1
}
wait_mongo_healthy() {
  for _ in $(seq 1 30); do
    s=$(docker inspect -f '{{.State.Health.Status}}' pdf-extractext-mongodb-1 2>/dev/null || echo starting)
    [ "$s" = "healthy" ] && return 0; sleep 2
  done
  return 1
}
wait_url http://localhost:8080/api/overview || true
wait_mongo_healthy || true

# 2) Traefik responde (dashboard local PROVISIONAL)
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:8080/api/overview || echo 000)
[ "$code" = "200" ] && ok "2. Traefik responde (dashboard local)" \
                    || fail "2. Traefik no responde (HTTP $code)"

# 3) MongoDB pasa su healthcheck
status=$(docker inspect -f '{{.State.Health.Status}}' pdf-extractext-mongodb-1 2>/dev/null || echo missing)
[ "$status" = "healthy" ] && ok "3. MongoDB healthy" \
                          || fail "3. MongoDB health status: $status"

# 4) Extraction está up
$COMPOSE ps --status running --services | grep -qx extraction \
  && ok "4. Extraction running" || fail "4. Extraction no está running"

# 5) Extraction responde GET /health desde la red interna (contenedor efímero)
code=$(docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
  -s -o /dev/null -w '%{http_code}' --max-time 5 http://extraction:8001/health || echo 000)
[ "$code" = "200" ] && ok "5. Extraction /health 200 en red interna" \
                    || fail "5. Extraction /health en red interna: HTTP $code"

# 6) Extraction NO responde desde el host ni vía Traefik público (:80)
c1=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8001/health || echo 000)
c2=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:80/health || echo 000)
if [ "$c1" != "200" ] && [ "$c2" != "200" ]; then
  ok "6. Extraction no es público (host: $c1, traefik:80: $c2)"
else
  fail "6. Extraction expuesto indebidamente (host: $c1, traefik:80: $c2)"
fi

# 7) MongoDB NO es alcanzable desde el host ni desde la red de servicios
c1=0; nc -z -w 2 localhost 27017 2>/dev/null && c1=1
c2=0; docker run --rm --network "$NET_SERVICES" "$CURL_IMG" \
  -s --max-time 3 -o /dev/null telnet://mongodb:27017 2>/dev/null && c2=1
if [ "$c1" = "0" ] && [ "$c2" = "0" ]; then
  ok "7. MongoDB aislado (host y red de servicios)"
else
  fail "7. MongoDB alcanzable (host: $c1, red servicios: $c2)"
fi

# 8) down && up conserva los datos de Mongo (volumen nombrado).
#    Prueba de infraestructura: inserta/limpia un doc temporal directo en
#    Mongo porque Persistence aún no existe.
MARKER="smoke-$(date +%s)"
MONGO() { docker exec pdf-extractext-mongodb-1 mongosh --quiet \
  -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin "$@" ; }
MONGO smoke --eval "db.markers.insertOne({marker: '$MARKER'})" >/dev/null
$COMPOSE down >/dev/null
$COMPOSE up -d >/dev/null
for _ in $(seq 1 30); do # esperar a que Mongo vuelva a healthy
  s=$(docker inspect -f '{{.State.Health.Status}}' pdf-extractext-mongodb-1 2>/dev/null || echo starting)
  [ "$s" = "healthy" ] && break; sleep 2
done
found=$(MONGO smoke --eval "db.markers.countDocuments({marker: '$MARKER'})" | tail -n1)
MONGO smoke --eval "db.markers.deleteMany({})" >/dev/null
if [ "$found" = "1" ]; then
  ok "8. datos persistieron tras down/up (volumen nombrado)"
else
  fail "8. el documento de prueba no persistió (count=$found)"
fi

# 9) No hay .env ni datos runtime versionados
dirty=0
git ls-files --error-unmatch .env >/dev/null 2>&1 && { dirty=1; echo "     .env está versionado"; }
git ls-files | grep -Eq '(^|/)(mongodata|.*-data)/' && { dirty=1; echo "     hay datos runtime versionados"; }
[ "$dirty" = "0" ] && ok "9. cero secretos/datos versionados" \
                   || fail "9. hay secretos o datos runtime versionados"

echo
if [ "$FAILURES" = "0" ]; then
  echo "SMOKE OK — todos los checks pasaron"
else
  echo "SMOKE FALLÓ — $FAILURES check(s) fallaron"
  exit 1
fi
