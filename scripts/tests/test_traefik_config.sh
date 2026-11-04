#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/../.."
source scripts/tests/lib.sh

assert_contains traefik/traefik.yml 'consulCatalog:' 'provider consulCatalog presente'
assert_contains traefik/traefik.yml 'address: http://consul:8500' 'endpoint de Consul correcto'
assert_contains traefik/traefik.yml 'refreshInterval: 5s' 'refreshInterval de 5s'
assert_contains traefik/traefik.yml 'exposedByDefault: false' 'exposedByDefault false'

assert_contains docker-compose.yml 'TRAEFIK_PROVIDERS_CONSULCATALOG_ENDPOINT_TOKEN' 'token de Traefik por entorno'
assert_contains docker-compose.yml 'traefik.http.routers.consul.rule' 'UI de Consul por Docker labels'
assert_not_contains docker-compose.yml 'traefik.http.routers.api.rule' 'sin router api por Docker labels'
assert_not_contains docker-compose.yml 'traefik.http.routers.extraction.rule' 'sin router extraction por Docker labels'

assert_contains docs/architecture-decisions.md '### D8.' 'ADR D8 documentada'

summary
