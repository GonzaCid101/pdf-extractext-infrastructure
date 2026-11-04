#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/../.."
source scripts/tests/lib.sh

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if ! docker compose --env-file .env.example config --format json > "$TMP/compose.json" 2>"$TMP/compose.err"; then
  fail "docker compose config con .env.example"
  sed 's/^/       /' "$TMP/compose.err"
  summary
  exit 1
fi
pass "docker compose config con .env.example"

python3 - "$TMP/compose.json" <<'PY'
import json
import sys

services = json.load(open(sys.argv[1]))["services"]
errors = []


def check(condition, message):
    print(("  PASS  " if condition else "  FAIL  ") + message)
    if not condition:
        errors.append(message)


def env_of(name):
    return services.get(name, {}).get("environment", {}) or {}


check("consul" in services, "servicio consul presente")
check("consul-seed" in services, "servicio consul-seed presente")
check(
    services.get("consul-seed", {}).get("restart") == "no",
    "consul-seed con restart no",
)
check(
    services.get("consul-seed", {}).get("depends_on", {}).get("consul", {}).get("condition")
    == "service_healthy",
    "consul-seed espera consul healthy",
)

for name in ("api", "extraction", "persistence"):
    env = env_of(name)
    check(env.get("CONSUL_HTTP_ADDR") == "consul:8500", f"{name}: CONSUL_HTTP_ADDR")
    check(bool(env.get("CONSUL_HTTP_TOKEN")), f"{name}: CONSUL_HTTP_TOKEN")
    check(str(env.get("CONSUL_ENABLED")) == "true", f"{name}: CONSUL_ENABLED=true")
    check(bool(env.get("SERVICE_NAME")), f"{name}: SERVICE_NAME")
    check(bool(env.get("SERVICE_PORT")), f"{name}: SERVICE_PORT")
    check(bool(env.get("SERVICE_HEALTH_PATH")), f"{name}: SERVICE_HEALTH_PATH")
    check(
        services[name].get("depends_on", {}).get("consul-seed", {}).get("condition")
        == "service_completed_successfully",
        f"{name}: depende de consul-seed completado",
    )

kv_keys = (
    "EXTRACTION_URL",
    "EXTRACTION_HOST",
    "PERSISTENCE_URL",
    "PERSISTENCE_HOST",
    "MAX_FILE_SIZE_MB",
    "MAX_UPLOAD_BYTES",
    "MAX_CONCURRENCY",
    "RETRY_AFTER_SECONDS",
    "MONGO_DATABASE_NAME",
    "MONGO_COLLECTION_NAME",
)
for name in ("api", "extraction", "persistence"):
    env = env_of(name)
    for key in kv_keys:
        check(key not in env, f"{name}: {key} no está en environment (vive en KV)")

check("MONGO_URI" in env_of("persistence"), "persistence: MONGO_URI por entorno")
check("WEB_CONCURRENCY" in env_of("extraction"), "extraction: WEB_CONCURRENCY por entorno")

for name in ("api", "extraction"):
    labels = services[name].get("labels", {}) or {}
    check(
        not any("traefik.http.routers" in key for key in labels),
        f"{name}: sin labels de router Traefik",
    )

check(
    services.get("api", {}).get("stop_grace_period") == "20s",
    "api: stop_grace_period 20s",
)
check(
    services.get("extraction", {}).get("stop_grace_period") == "35s",
    "extraction: stop_grace_period 35s",
)
check(
    services.get("persistence", {}).get("stop_grace_period") == "20s",
    "persistence: stop_grace_period 20s",
)

check(
    services.get("traefik", {}).get("depends_on", {}).get("consul", {}).get("condition")
    == "service_healthy",
    "traefik espera consul healthy",
)
check(
    bool(env_of("traefik").get("TRAEFIK_PROVIDERS_CONSULCATALOG_ENDPOINT_TOKEN")),
    "traefik: token de consulCatalog por entorno",
)

for name, service in services.items():
    for key, value in (service.get("environment", {}) or {}).items():
        check(
            "localhost" not in str(value),
            f"{name}: {key} sin localhost",
        )

sys.exit(1 if errors else 0)
PY

if [ $? -ne 0 ]; then
  fail "contrato de docker-compose.yml"
else
  pass "contrato de docker-compose.yml"
fi

summary
