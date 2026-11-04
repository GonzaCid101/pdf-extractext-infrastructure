#!/bin/sh
set -eu

KEYS_FILE="${KEYS_FILE:-/consul/seed/keys.env}"

while IFS='=' read -r key value; do
  case "$key" in
    ''|\#*) continue ;;
  esac

  if [ "${SEED_FORCE:-false}" != "true" ] && consul kv get "$key" >/dev/null 2>&1; then
    continue
  fi

  echo "seed: $key"
  consul kv put "$key" "$value" >/dev/null
done < "$KEYS_FILE"
