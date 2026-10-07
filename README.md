# pdf-extractext-infrastructure

Bootstrap de infraestructura de **PDF Extractext** (migración de monolito a
microservicios).

## Qué demuestra

```
Traefik (:80→:443 TLS mkcert, dominio *.pdf-extractext.localhost)
        ▼  red `services`
   API (:8000, entrypoint público HTTPS)
        ├─ Persistence (:8002, /health) ─┐
        └─ Traefik :8090 (entrypoint interno, no publicado)
                 ▼  balanceo de réplicas vía Traefik
           Extraction (:8001, /health)
                                        ▼  red `data`
MongoDB  ◀─ solo Persistence; 27017 no publicado; volumen nombrado
```

Levanta **Traefik + API + Extraction + Persistence + MongoDB** sobre la
arquitectura acordada: `Traefik → API → {Extraction, Persistence} → MongoDB`.
La API es el único entrypoint público (`https://pdf-extractext.localhost`);
consume Extraction a través del entrypoint interno :8090 de Traefik (D3) y
Persistence directo por la red `services`.

## Requisitos

- Docker + Docker Compose v2, Make, Bash, curl, mkcert (si usás el binario
  suelto, ubicarlo en el PATH, p. ej. `~/.local/bin`)
- Para las pruebas de carga: `jq`, `k6` y Vegeta
  (`go install github.com/tsenart/vegeta@latest`)
- Repos de API, Extraction y Persistence clonados como hermanos (ver
  `docs/architecture-decisions.md`): `../pdf-extractext-api`,
  `../pdf-extractext-extractor` y `../pdf-extractext-persistence`

## Quickstart

```bash
cp .env.example .env   # ajustá *_CONTEXT si tus rutas difieren
make certs             # genera el TLS local con mkcert (una vez por máquina)
make up                # valida los contextos de build y levanta todo
make smoke             # verifica los 14 checks
make down
make logs / make ps    # utilidades
```

Dashboard de Traefik: <https://traefik.pdf-extractext.localhost> (TLS local).

Si falta `.env` o algún contexto de build no existe, `make up` falla con un
mensaje que explica cómo resolverlo.

## Routing y dominios

| Dominio | Destino | Entrypoint |
| --- | --- | --- |
| `pdf-extractext.localhost` | API Service | :443 (TLS) |
| `traefik.pdf-extractext.localhost` | dashboard Traefik | :443 (TLS) |
| `extraction.pdf-extractext.localhost` | réplicas de Extraction | interno :8090 (no publicado al host) |

El redirect :80→:443 aplica solo al borde; el entrypoint interno no redirige
para que las llamadas servicio→servicio HTTP funcionen sin certificados.

**Contrato de Extraction:** el servicio acepta **únicamente
`multipart/form-data`**; no acepta `application/octet-stream` ni binarios
crudos en el body. La API debe reenviar el archivo respetando ese formato.

## Comprobaciones de `make smoke`

1. Los 5 servicios quedan running tras `compose up --build`.
2. Traefik responde (dashboard con TLS local).
3. MongoDB pasa su healthcheck técnico de contenedor.
4. Extraction está running.
5. Extraction responde `GET /health` directo y vía Traefik interno (:8090).
6. Extraction **no** es alcanzable desde el host ni vía Traefik público.
7. Persistence responde `GET /health` desde la red interna.
8. Persistence **no** es alcanzable desde el host ni vía Traefik público.
9. Flujo feliz de `POST /extract` por el dominio público: un PDF mínimo
   generado al vuelo viaja por `multipart/form-data` (campo `file`) y la
   respuesta debe ser HTTP 200 con `content` y `page_count` (contrato del TP).
10. `POST /extract` sin el campo `file` (nombre incorrecto) se rechaza con
    HTTP 400.
11. MongoDB **no** es alcanzable desde el host ni desde la red de servicios.
12. Persistence garantizó el índice único `checksum_1` en Mongo (ownership).
13. `down && up` conserva los datos de Mongo. La prueba inserta y limpia un
    documento temporal directo en Mongo: es solo una prueba de infraestructura.
14. No hay `.env`, certs TLS ni datos runtime versionados.

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

## Pruebas de carga (k6 y Vegeta)

Corridas contra `https://pdf-extractext.localhost/extract` con el stack
levantado (`make up`). Ambas **registran la corrida automáticamente** en
`docs/test-runs/<fechaUTC>-<tool>.md` con la config real del stack (mismo
mecanismo de `record-run.sh`); queda completar las Observaciones a mano.

```bash
make load-k6       # spike k6: 10s→100 VUs, 20s sostenidos, 10s→0
make load-vegeta   # Vegeta: 50 req/s durante 30s (timeout 30s, -insecure)
```

- **k6** (`tests/load/k6-spike.js`): cada iteración elige al azar uno de los
  4 fixtures PDF y lo envía por `multipart/form-data` (campo `file`, TLS
  mkcert ignorado). El resumen mide p50, p90, p95 y error rate
  (`http_req_failed`); el spike busca la saturación (503 controlado, D10),
  no hay thresholds que aborten la corrida.
- **Vegeta** (`tests/load/vegeta/run_vegeta.sh`): Vegeta no arma multipart,
  así que el script pre-compila los cuerpos binarios (framing MIME + bytes
  de cada PDF) para los 4 fixtures y rota los targets; p90 se calcula sobre
  los resultados individuales (Vegeta solo reporta p50/p95/p99).
- **Fixtures** (`tests/load/pdfs/`): 4 PDFs válidos de 1, 3, 8 y 20 páginas,
  generados al vuelo por `generate_fixtures.sh` (deterministas; no se
  versionan, ambos targets los regeneran solos).
- **Ensayos sin stack** (opcional): `RECORD=0` corre el ataque sin registrarlo
  y `TARGET_URL` permite apuntar a otro endpoint, p. ej. el mock de verificación
  `tests/load/mock_api.py`:

```bash
python3 tests/load/mock_api.py &   # mock local que valida el multipart byte a byte
RECORD=0 TARGET_URL=http://127.0.0.1:8642/extract make load-k6
```

Los resultados de cada corrida (throughput, % éxito, p50/p90/p95) quedan en
la tabla del registro generado; el reporte completo de cada herramienta se
imprime por consola durante la corrida.

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
