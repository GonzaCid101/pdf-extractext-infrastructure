#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/../.."
source scripts/tests/lib.sh

assert_file consul/config/consul.json.tmpl
assert_file consul/entrypoint.sh
assert_file consul/README.md

assert_contains consul/config/consul.json.tmpl '__CONSUL_HTTP_TOKEN__' 'plantilla con placeholder de token'
assert_contains consul/config/consul.json.tmpl '"enabled": true' 'ACL habilitada'
assert_contains consul/config/consul.json.tmpl '"default_policy": "allow"' 'default_policy allow'
assert_contains consul/config/consul.json.tmpl '"enable_token_persistence": true' 'persistencia de token'
assert_contains consul/config/consul.json.tmpl '"http": 8500' 'puerto HTTP 8500'
assert_not_contains consul/config/consul.json.tmpl 'ac80cdb0-2ca6-4182-ae14-15158c33c095' 'sin token del profesor'

assert_contains consul/entrypoint.sh '/tmp/consul.json' 'render en /tmp'
assert_contains consul/entrypoint.sh '-config-file=/tmp/consul.json' 'config-file apunta a /tmp'

assert_contains docker-compose.yml 'hashicorp/consul:2.0.4@sha256:' 'imagen de Consul pineada por digest'
assert_contains docker-compose.yml './consul/config:/consul/config:ro' 'bind mount de config en solo lectura'
assert_contains docker-compose.yml 'CONSUL_HTTP_TOKEN' 'token inyectado por entorno'
assert_not_contains docker-compose.yml '8500:8500' '8500 no publicado al host'
assert_contains docker-compose.yml 'traefik.http.routers.consul.entrypoints=internal' 'UI de Consul en entrypoint interno'

if grep -Eq '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
  consul/config/consul.json.tmpl consul/entrypoint.sh docker-compose.yml; then
  fail 'sin token hardcodeado en config/entrypoint/compose'
else
  pass 'sin token hardcodeado en config/entrypoint/compose'
fi

summary
