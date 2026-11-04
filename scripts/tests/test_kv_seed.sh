#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/../.."
source scripts/tests/lib.sh

assert_file consul/seed/keys.env
assert_file consul/seed/seed.sh
assert_file scripts/consul-kv-seed.sh

assert_contains consul/seed/keys.env 'pdf-extractext/config/api/MAX_FILE_SIZE_MB=16' 'KV: MAX_FILE_SIZE_MB'
assert_contains consul/seed/keys.env 'pdf-extractext/config/api/EXTRACTION_URL=http://traefik:8090' 'KV: EXTRACTION_URL'
assert_contains consul/seed/keys.env 'pdf-extractext/config/api/EXTRACTION_HOST=extraction.pdf-extractext.localhost' 'KV: EXTRACTION_HOST'
assert_contains consul/seed/keys.env 'pdf-extractext/config/api/PERSISTENCE_URL=http://traefik:8090' 'KV: PERSISTENCE_URL'
assert_contains consul/seed/keys.env 'pdf-extractext/config/api/PERSISTENCE_HOST=persistence.pdf-extractext.localhost' 'KV: PERSISTENCE_HOST'
assert_contains consul/seed/keys.env 'pdf-extractext/config/extraction/MAX_UPLOAD_BYTES=67108864' 'KV: MAX_UPLOAD_BYTES'
assert_contains consul/seed/keys.env 'pdf-extractext/config/extraction/MAX_CONCURRENCY=1' 'KV: MAX_CONCURRENCY'
assert_contains consul/seed/keys.env 'pdf-extractext/config/extraction/RETRY_AFTER_SECONDS=1' 'KV: RETRY_AFTER_SECONDS'
assert_contains consul/seed/keys.env 'pdf-extractext/config/persistence/MONGO_DATABASE_NAME=pdf_extractext' 'KV: MONGO_DATABASE_NAME'
assert_contains consul/seed/keys.env 'pdf-extractext/config/persistence/MONGO_COLLECTION_NAME=documents' 'KV: MONGO_COLLECTION_NAME'

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/consul" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
cmd=$1
shift
case "$cmd" in
  kv)
    sub=$1
    shift
    key=$1
    case "$sub" in
      get)
        [ -f "$FAKE_CONSUL_STORE/$key" ] || exit 1
        cat "$FAKE_CONSUL_STORE/$key"
        ;;
      put)
        value=$2
        mkdir -p "$FAKE_CONSUL_STORE/$(dirname "$key")"
        printf '%s' "$value" > "$FAKE_CONSUL_STORE/$key"
        ;;
    esac
    ;;
esac
FAKE
chmod +x "$TMP/consul"

export FAKE_CONSUL_STORE="$TMP/store"
export CONSUL_HTTP_ADDR=http://consul:8500
export CONSUL_HTTP_TOKEN=test-token
export KEYS_FILE="$PWD/consul/seed/keys.env"
mkdir -p "$FAKE_CONSUL_STORE"

PATH="$TMP:$PATH" sh consul/seed/seed.sh >/dev/null
assert_eq "16" "$(cat "$FAKE_CONSUL_STORE/pdf-extractext/config/api/MAX_FILE_SIZE_MB")" 'seed carga valores'

printf '%s' '99' > "$FAKE_CONSUL_STORE/pdf-extractext/config/api/MAX_FILE_SIZE_MB"
PATH="$TMP:$PATH" sh consul/seed/seed.sh >/dev/null
assert_eq "99" "$(cat "$FAKE_CONSUL_STORE/pdf-extractext/config/api/MAX_FILE_SIZE_MB")" 'seed no pisa valores existentes'

SEED_FORCE=true PATH="$TMP:$PATH" sh consul/seed/seed.sh >/dev/null
assert_eq "16" "$(cat "$FAKE_CONSUL_STORE/pdf-extractext/config/api/MAX_FILE_SIZE_MB")" 'SEED_FORCE pisa valores existentes'

printf '%s\n' 'pdf-extractext/config/api/EXTRA=a=b' > "$TMP/keys.env"
KEYS_FILE="$TMP/keys.env" SEED_FORCE=true PATH="$TMP:$PATH" sh consul/seed/seed.sh >/dev/null
assert_eq "a=b" "$(cat "$FAKE_CONSUL_STORE/pdf-extractext/config/api/EXTRA")" 'seed preserva = en el valor'

summary
