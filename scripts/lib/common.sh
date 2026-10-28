#!/usr/bin/env bash

require_cmd() {
  local cmd="$1"
  local msg="${2:-}"
  command -v "$cmd" >/dev/null 2>&1 || {
    if [ -n "$msg" ]; then
      echo "$msg"
    else
      echo "ERROR: falta $cmd"
    fi
    exit 1
  }
}

compose() {
  docker compose "$@"
}

wait_http() {
  local url="$1"
  local tries="${2:-30}"
  local sleep_s="${3:-2}"
  local c
  local i
  for i in $(seq 1 "$tries"); do
    c=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 3 "$url" || echo 000)
    [ "$c" != "000" ] && return 0
    sleep "$sleep_s"
  done
  return 1
}
