# pdf-extractext-infrastructure

Bootstrap de infraestructura de **PDF Extractext** (migración de monolito a
microservicios).

## Qué demuestra

```
Traefik (:80→:443 TLS mkcert, dominio *.pdf-extractext.localhost)
        ▼  red `services`          :8090 entrypoint interno (no publicado)
   Extraction (:8001, /health) ◀── balanceo de réplicas vía Traefik
   Persistence (:8002, /health) ─┐
                                 ▼  red `data`
MongoDB  ◀─ solo Persistence; 27017 no publicado; volumen nombrado
```

Levanta **Traefik + Extraction + Persistence + MongoDB** sobre la arquitectura
acordada: `Traefik → API → {Extraction, Persistence} → MongoDB`.

El repo de API existe pero aún no se integra (le falta Dockerfile/health;
ver `docs/architecture-decisions.md` D15). Cuando esté listo, se agrega al
compose en la red `services` con router TLS propio.

## Requisitos

- Docker + Docker Compose v2, Make, Bash, curl, mkcert (si usás el binario
  suelto, ubicarlo en el PATH, p. ej. `~/.local/bin`)
- Repos de Extraction y Persistence clonados como hermanos (ver
  `docs/architecture-decisions.md`): `../pdf-extractext-extractor` y
  `../pdf-extractext-persistence`

## Quickstart

```bash
cp .env.example .env   # ajustá *_CONTEXT si tus rutas difieren
make certs             # genera el TLS local con mkcert (una vez por máquina)
make up                # valida los contextos de build y levanta todo
make smoke             # verifica los 12 checks
make down
make logs / make ps    # utilidades
```

Dashboard de Traefik: <https://traefik.pdf-extractext.localhost> (TLS local).

Si falta `.env` o algún contexto de build no existe, `make up` falla con un
mensaje que explica cómo resolverlo.

## Routing y dominios

| Dominio | Destino | Entrypoint |
| --- | --- | --- |
| `traefik.pdf-extractext.localhost` | dashboard Traefik | :443 (TLS) |
| `extraction.pdf-extractext.localhost` | réplicas de Extraction | interno :8090 (no publicado al host) |
| `pdf-extractext.localhost` | API Service (cuando se integre) | :443 (TLS) |

El redirect :80→:443 aplica solo al borde; el entrypoint interno no redirige
para que las llamadas servicio→servicio HTTP funcionen sin certificados.

## Comprobaciones de `make smoke`

1. Los 4 servicios quedan running tras `compose up --build`.
2. Traefik responde (dashboard con TLS local).
3. MongoDB pasa su healthcheck técnico de contenedor.
4. Extraction está running.
5. Extraction responde `GET /health` directo y vía Traefik interno (:8090).
6. Extraction **no** es alcanzable desde el host ni vía Traefik público.
7. Persistence responde `GET /health` desde la red interna.
8. Persistence **no** es alcanzable desde el host ni vía Traefik público.
9. MongoDB **no** es alcanzable desde el host ni desde la red de servicios.
10. Persistence garantizó el índice único `checksum_1` en Mongo (ownership).
11. `down && up` conserva los datos de Mongo. La prueba inserta y limpia un
    documento temporal directo en Mongo: es solo una prueba de infraestructura.
12. No hay `.env`, certs TLS ni datos runtime versionados.

## Registro de corridas

Las corridas de carga (k6/Vegeta, ver D11 del ADR) se registran en
`docs/test-runs/` con formato fijo ([TEMPLATE.md](docs/test-runs/TEMPLATE.md))
para que sean comparables entre sí.

`make record-run` extrae automáticamente del stack activo réplicas, tags de
imagen, límites CPU/mem y versiones de Traefik/Mongo; los parámetros y
resultados de la corrida se pasan como flags via `ARGS`:

```bash
make up
# ... correr k6 o vegeta contra el stack ...
make record-run ARGS="--tool k6 \
  --target http://traefik:8090 --desc 'Spike D11' \
  --load 'k6 spike 100 VUs' \
  --throughput 98.2 --success 99.7 --p50 42 --p90 120 --p95 210"
```

Genera `docs/test-runs/<fechaUTC>-<tool>.md` (p. ej.
`20261004T153012Z-k6.md`). Lo único que queda para completar a mano es la
sección Observaciones. Detalle de flags:
`./scripts/record-run.sh --help`.

## Reglas del bootstrap

- Solo Persistence accederá a MongoDB (aislamiento por redes).
- Datos de Mongo en volumen nombrado; jamás bind-mount versionado.
- `.env` y `traefik/certs/` (claves privadas) nunca versionados.
- Stack: Docker Compose v2, Traefik v3, Mongo `mongo:8`, Make, Bash, curl,
  mkcert. Sin observabilidad extra ni CI.
- Las decisiones arquitectónicas viven en
  [`docs/architecture-decisions.md`](docs/architecture-decisions.md).

## Healthchecks

El healthcheck de Mongo es **técnico** (el proceso responde a ping). Los
servicios aplicación usan imágenes distroless (sin shell/curl): healthcheck
in-container diferido hasta que expongan `/readyz` (decisión D8).
