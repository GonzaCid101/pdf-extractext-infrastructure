#!/bin/sh
set -eu

: "${CONSUL_HTTP_TOKEN:?falta CONSUL_HTTP_TOKEN}"

# El bind mount de /consul/config es :ro; el JSON con el token se renderiza en /tmp.
sed "s|__CONSUL_HTTP_TOKEN__|${CONSUL_HTTP_TOKEN}|g" \
  /consul/config/consul.json.tmpl > /tmp/consul.json

exec consul agent -config-file=/tmp/consul.json
