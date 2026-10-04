#!/usr/bin/env bash
# record-run.sh — registra una corrida de carga (k6/Vegeta) extrayendo la
# configuración real del stack activo (Issue #1 / ADR D11).
#
# Los datos del entorno se extraen con docker compose ps / docker inspect.
# Los parámetros y resultados de la corrida se pasan como flags CLI.
#
# Uso: ver ./scripts/record-run.sh --help

set -euo pipefail

cd "$(dirname "$0")/.."
TEMPLATE="docs/test-runs/TEMPLATE.md"
OUT_DIR="docs/test-runs"

usage() {
	cat <<'EOF'
Uso: record-run.sh --tool <k6|vegeta> --target <url> --load <desc>
                   --throughput <req/s> --success <%> --p50 <ms> --p90 <ms> --p95 <ms>
                   [--desc <texto>] [--out-dir <dir>]

Extrae del stack activo (docker compose ps / inspect) réplicas, tags de
imagen, límites CPU/mem y versiones de Traefik/Mongo, y genera
docs/test-runs/<fechaUTC>-<tool>.md a partir del TEMPLATE.md.

  --tool        k6 o vegeta (requerido)
  --target      endpoint atacado (requerido)
  --load        patrón de carga, ej. "k6 abierto 25 req/s" (requerido)
  --throughput  req/s resultantes (requerido)
  --success     % éxito (requerido)
  --p50/--p90/--p95  latencias en ms (requeridos)
  --desc        descripción del escenario (opcional)
  --out-dir     directorio de salida (default: docs/test-runs)
EOF
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

# --- Extracción del entorno ---

# ids de contenedores activos de un servicio (rápido, por proyecto/label oneoff=false)
service_ids() { $COMPOSE ps -q --status running "$1" 2>/dev/null || true; }

# primer id del servicio; vacío si el servicio no está levantado
first_id() { service_ids "$1" | head -1; }

replicas() { service_ids "$1" | grep -c . || true; }

image_of() {
	local id
	id="$(first_id "$1")"
	[[ -n "$id" ]] && docker inspect "$id" --format '{{.Config.Image}}' || echo "no running"
}

# límites vigentes: NanoCpus (0 = sin límite) y Memory bytes (0 = sin límite)
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
	v="$(docker exec "$id" traefik version 2>/dev/null | awk '/^Version/{print $2}')" \
		|| true
	if [[ -z "$v" ]]; then
		v="$(docker inspect "$(image_of traefik)" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || true)"
	fi
	echo "${v:-desconocida}"
}

mongo_version() {
	local id
	id="$(first_id mongodb)"
	[[ -n "$id" ]] || { echo "—"; return; }
	docker exec "$id" mongod --version 2>/dev/null | awk '/^db version/{print $3; exit}' \
		|| echo "desconocida"
}

# --- Validación de stack ---

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

# --- Render del registro ---

FECHA="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-${TOOL}"
OUT="$OUT_DIR/${RUN_ID}.md"

out="$(cat "$TEMPLATE")"
render() { # render KEY value
	local key="$1" val="$2"
	out="${out//\{\{$key\}\}/$val}"
}

render RUN_ID "$RUN_ID"
render FECHA "$FECHA"
render TOOL "$TOOL"
render DESC "${DESC:-—}"
render TARGET "$TARGET"
render LOAD "$LOAD"

for svc in EXT:extraction PER:persistence TRA:traefik MON:mongodb; do
	key="${svc%%:*}"; name="${svc##*:}"
	render "${key}_REPLICAS" "$(replicas "$name")"
	render "${key}_IMAGE" "$(image_of "$name")"
	render "${key}_CPU" "$(cpu_limit "$name")"
	render "${key}_MEM" "$(mem_limit "$name")"
done

render TRA_VERSION "$(traefik_version)"
render MON_VERSION "$(mongo_version)"

render THROUGHPUT "$THROUGHPUT"
render SUCCESS "$SUCCESS"
render P50 "$P50"
render P90 "$P90"
render P95 "$P95"

mkdir -p "$OUT_DIR"
printf '%s\n' "$out" > "$OUT"
echo "Registro generado: $OUT"
