#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/../.."
source scripts/tests/lib.sh

assert_file docs/architecture-decisions.md
assert_file README.md
assert_file consul/README.md

assert_contains docs/architecture-decisions.md '### D8.' 'ADR D8 presente'
assert_contains docs/architecture-decisions.md 'consulCatalog' 'ADR menciona consulCatalog'
assert_contains docs/architecture-decisions.md 'Tags' 'ADR explica Tags'
assert_contains docs/architecture-decisions.md 'Meta' 'ADR explica Meta'

assert_contains README.md 'Consul' 'README menciona Consul'
assert_contains README.md 'consul-check' 'README documenta consul-check'
assert_contains README.md 'consul-kv-seed' 'README documenta el seed'
assert_contains consul/README.md 'X-Consul-Token' 'consul/README documenta el token'
assert_contains consul/README.md '/v1/agent/service/register' 'consul/README documenta el registro'
assert_contains consul/README.md '/v1/kv/' 'consul/README documenta KV'

assert_file scripts/consul-check.sh
assert_contains Makefile 'test-infra:' 'Makefile expone test-infra'
assert_contains Makefile 'consul-check:' 'Makefile expone consul-check'
assert_contains scripts/smoke.sh 'SMOKE_PHASE' 'smoke soporta fases'

summary
