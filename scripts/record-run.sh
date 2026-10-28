#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
TEMPLATE="docs/test-runs/TEMPLATE.md"
OUT_DIR="docs/test-runs"

usage() {
	cat <<EOF
Uso: record-run.sh --tool <k6|vegeta> --target <url> --load <desc>
                    --throughput <req/s> --success <%> --p50 <ms> --p90 <ms> --p95 <ms>
                   [--desc <texto>] [--out-dir <dir>]
EOF
}

render_template() {
	local template_content="$1"
	shift
	local out="$template_content"
	local pair key val
	for pair in "$@"; do
		key="${pair%%=*}"
		val="${pair#*=}"
		out="${out//\{\{$key\}\}/$val}"
	done
	printf '%s\n' "$out"
}

TOOL= TARGET= LOAD= THROUGHPUT= SUCCESS= P50= P90= P95= DESC= OUT_DIR="$OUT_DIR"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--tool) TOOL="$2"; shift 2;;
		--target) TARGET="$2"; shift 2;;
		--load) LOAD="$2"; shift 2;;
		--throughput) THROUGHPUT="$2"; shift 2;;
		--success) SUCCESS="$2"; shift 2;;
		--p50) P50="$2"; shift 2;;
		--p90) P90="$2"; shift 2;;
		--p95) P95="$2"; shift 2;;
		--desc) DESC="$2"; shift 2;;
		--out-dir) OUT_DIR="$2"; shift 2;;
		-h|--help) usage; exit 0;;
		*) echo "ERROR: flag desconocido: $1"; usage >&2; exit 1;;
	esac
done

for var in TOOL TARGET LOAD THROUGHPUT SUCCESS P50 P90 P95; do
	if [[ -z "${!var}" ]]; then
		echo "ERROR: falta --${var,,} (requerido)" >&2; usage >&2; exit 1
	fi
done
case "$TOOL" in k6|vegeta) ;; *) echo "ERROR: --tool debe ser k6 o vegeta" >&2; exit 1;; esac
[[ -f "$TEMPLATE" ]] || { echo "ERROR: no existe $TEMPLATE" >&2; exit 1; }

COMPOSE="docker compose"

service_ids() { $COMPOSE ps -q --status running "$1" 2>/dev/null || true; }
first_id() { service_ids "$1" | head -1; }
replicas() { service_ids "$1" | grep -c . || true; }

image_of() {
	local id
	id="$(first_id "$1")"
	[[ -n "$id" ]] && docker inspect "$id" --format '{{.Config.Image}}' || echo "no running"
}

cpu_limit() {
	local id nano
	id="$(first_id "$1")"
	[[ -n "$id" ]] || { echo "—"; return; }
	nano="$(docker inspect "$id" --format '{{.HostConfig.NanoCpus}}')"
	[[ "$nano" == "0" || -z "$nano" ]] && echo "sin límite" || awk -v n="$nano" 'BEGIN{printf "%.2f", n/1e9}'
}

mem_limit() {
	local id mem
	id="$(first_id "$1")"
	[[ -n "$id" ]] || { echo "—"; return; }
	mem="$(docker inspect "$id" --format '{{.HostConfig.Memory}}')"
	if [[ "$mem" == "0" || -z "$mem" ]]; then
		echo "sin límite"
	elif (( mem % 1073741824 == 0 )); then
		echo "$(( mem / 1073741824 ))G"
	else
		echo "$(( mem / 1048576 ))M"
	fi
}

traefik_version() {
	local id v
	id="$(first_id traefik)"
	[[ -n "$id" ]] || { echo "—"; return; }
	v="$(docker exec "$id" traefik version 2>/dev/null | awk '/^Version/{print $2}')" || true
	if [[ -z "$v" ]]; then
		v="$(docker inspect "$(image_of traefik)" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || true)"
	fi
	echo "${v:-desconocida}"
}

mongo_version() {
	local id v
	id="$(first_id mongodb)"
	[[ -n "$id" ]] || { echo "—"; return; }
	v="$(docker exec "$id" mongod --version 2>/dev/null | awk '/^db version/{print $3; exit}' || true)"
	echo "${v:-desconocida}"
}

if [[ -z "$($COMPOSE ps -q 2>/dev/null)" ]]; then
	echo "ERROR: el stack no está levantado (docker compose ps vacío)." >&2
	echo "       Ejecutá 'make up' y corré la prueba de carga antes de registrarla." >&2
	exit 1
fi

for svc in extraction persistence traefik mongodb; do
	if [[ "$(replicas "$svc")" == "0" ]]; then
		echo "ADVERTENCIA: servicio '$svc' no está running; se registrará como tal." >&2
	fi
done

FECHA="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-${TOOL}"
OUT="$OUT_DIR/${RUN_ID}.md"

template_content="$(cat "$TEMPLATE")"
out="$(render_template "$template_content" \
	RUN_ID="$RUN_ID" \
	FECHA="$FECHA" \
	TOOL="$TOOL" \
	DESC="${DESC:-—}" \
	TARGET="$TARGET" \
	LOAD="$LOAD" \
	EXT_REPLICAS="$(replicas extraction)" \
	EXT_IMAGE="$(image_of extraction)" \
	EXT_CPU="$(cpu_limit extraction)" \
	EXT_MEM="$(mem_limit extraction)" \
	PER_REPLICAS="$(replicas persistence)" \
	PER_IMAGE="$(image_of persistence)" \
	PER_CPU="$(cpu_limit persistence)" \
	PER_MEM="$(mem_limit persistence)" \
	TRA_REPLICAS="$(replicas traefik)" \
	TRA_IMAGE="$(image_of traefik)" \
	TRA_CPU="$(cpu_limit traefik)" \
	TRA_MEM="$(mem_limit traefik)" \
	TRA_VERSION="$(traefik_version)" \
	MON_REPLICAS="$(replicas mongodb)" \
	MON_IMAGE="$(image_of mongodb)" \
	MON_CPU="$(cpu_limit mongodb)" \
	MON_MEM="$(mem_limit mongodb)" \
	MON_VERSION="$(mongo_version)" \
	THROUGHPUT="$THROUGHPUT" \
	SUCCESS="$SUCCESS" \
	P50="$P50" \
	P90="$P90" \
	P95="$P95")"

mkdir -p "$OUT_DIR"
printf '%s\n' "$out" > "$OUT"
echo "Registro generado: $OUT"
EOF
chmod +x /home/gonzalo/facu/desarrollo-software/pdf-extractext-microservicios/pdf-extractext-infrastructure/scripts/record-run.sh
bash -n /home/gonzalo/facu/desarrollo-software/pdf-extractext-microservicios/pdf-extractext-infrastructure/scripts/record-run.sh && echo "OK"
