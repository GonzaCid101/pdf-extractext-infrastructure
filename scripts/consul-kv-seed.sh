#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "ERROR: falta .env — ejecutá: cp .env.example .env"; exit 1; }

docker compose run --rm consul-seed
