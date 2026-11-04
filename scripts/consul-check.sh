#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "ERROR: falta .env — ejecutá: cp .env.example .env"; exit 1; }
set -a; . ./.env; set +a
: "${CONSUL_HTTP_TOKEN:?falta CONSUL_HTTP_TOKEN en .env}"

FAILURES=0
ok()   { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAILURES=$((FAILURES + 1)); }

consul_api() {
  docker compose exec -T consul wget -qO- \
    --header="X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    "http://127.0.0.1:8500$1" 2>/dev/null
}

leader=$(consul_api /v1/status/leader || true)
if [ -n "$leader" ] && [ "$leader" != '""' ]; then
  ok "Consul tiene leader ($leader)"
else
  fail "Consul sin leader"
fi

services=$(consul_api /v1/catalog/services || true)
if printf '%s' "$services" | grep -q '"consul"'; then
  ok "servicio consul en el catálogo"
else
  fail "servicio consul ausente del catálogo"
fi

for service in api extraction persistence; do
  if printf '%s' "$services" | grep -q "\"$service\""; then
    ok "servicio $service en el catálogo"
  else
    echo "PENDIENTE PASO 5: servicio $service no registrado todavía"
  fi
done

keys=$(consul_api '/v1/kv/pdf-extractext/config/?recurse' || true)
count=$(printf '%s' "$keys" | grep -o '"Key"' | wc -l | tr -d ' ')
if [ "$count" -ge 10 ]; then
  ok "KV con $count claves en pdf-extractext/config/"
else
  fail "KV incompleto: $count claves (esperaba >= 10)"
fi

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "CONSUL-CHECK FALLÓ — $FAILURES check(s) fallaron"
  exit 1
fi
echo "CONSUL-CHECK OK"
