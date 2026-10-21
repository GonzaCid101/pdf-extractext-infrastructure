# pdf-extractext-infrastructure

Bootstrap de infraestructura de **PDF Extractext** (microservicios con Docker
Compose y Traefik).

```
Traefik (:80→:443 TLS mkcert)
    ▼ red `services`
API (:8000, HTTPS público)
  ├─ Persistence (:8002, /health)
  └─ Traefik :8090 (interno, no publicado)
       ▰ balanceo vía Traefik
    Extraction (:8001, /health)
                                      ▼ red `data`
MongoDB ◀─ solo Persistence; 27017 no publicado; volumen nombrado
```

La API es el único entrypoint público (`https://pdf-extractext.localhost`).
Consume Extraction vía Traefik :8090 y Persistence directo por la red
`services`.

## Requisitos

- Docker + Docker Compose v2, Make, Bash, curl, mkcert
- Para pruebas de carga: `jq`, `k6` y Vegeta
  (`go install github.com/tsenart/vegeta@latest`)
- `pdf-extractext.localhost` debe resolver en `127.0.0.1` (WSL/glibc que no
  resuelve `*.localhost` automáticamente):

  ```bash
  echo "127.0.0.1 pdf-extractext.localhost" | sudo tee -a /etc/hosts
  ```
- Repos hermanos clonados: `../pdf-extractext-api`,
  `../pdf-extractext-extractor`, `../pdf-extractext-persistence`

## Quickstart

```bash
cp .env.example .env        # ajustá *_CONTEXT si tus rutas difieren
make certs                  # TLS local con mkcert (una vez por máquina)
make up                     # valida contextos y levanta todo
make smoke                  # verifica los 15 checks
make down
make logs / make ps         # utilidades
```

Dashboard de Traefik: <https://traefik.pdf-extractext.localhost>

## Escalado de Extraction (1–5 réplicas)

```bash
EXTRACTION_REPLICAS=5 make up
docker compose ps extraction
```

Los límites `cpus: "1.0"` / `memory: 1G` aplican por réplica.

## Registro de corridas

`make record-run` extrae del stack activo réplicas, tags, límites y versiones,
y genera `docs/test-runs/<fechaUTC>-<tool>.md`:

```bash
make record-run ARGS="--tool k6 \
  --target https://pdf-extractext.localhost/extract \
  --load 'k6 spike 100 VUs' \
  --throughput 98.2 --success 99.7 --p50 42 --p90 120 --p95 210"
```

## Pruebas de carga (k6 y Vegeta)

Contra `https://pdf-extractext.localhost/extract` con el stack levantado:

```bash
make load-k6       # spike: 10s→100 VUs, 20s, 10s→0
make load-vegeta   # 50 req/s × 30s, timeout 30s
```

Ambas registran la corrida en `docs/test-runs/`.

- **k6** (`tests/load/spike_tests.js`): PDF oficial al azar por
  `multipart/form-data` (campo `file`). Éxito: HTTP 200 con
  `{content, page_count}`.
- **Vegeta** (`tests/load/vegeta/run_vegeta.sh`): pre-compila cuerpos
  multipart de los 4 PDFs oficiales y lanza un único ataque a 50 req/s.
- **PDFs oficiales** (`tests/load/pdfs/`): los 4 del profesor, versionados
  para que un clon limpio corra las pruebas sin pasos manuales. Corpus
  oficial único: 4 hashes únicos (`FIND-011` resuelto, 2026-10-21).
- **Registro de corridas** (`docs/test-runs/`): los `.md` que generan
  `run_k6.sh`/`run_vegeta.sh` son locales (`.gitignore`); solo `TEMPLATE.md`
  se versiona.
- **RECORD=0**: ensayo sin registrar (p. ej. contra `tests/load/mock_api.py`).
- **Overrides**: `TARGET_URL` (destino; por defecto el dominio público),
  `TARGET_VUS` (k6; por defecto 100), `RATE`/`DURATION`/`TIMEOUT` (Vegeta).

> **Nota (perfiles corregidos, 2026-10-21):** `spike_tests.js` ya ejecuta el
> spike de 100 VUs (`FIND-003`) y `run_vegeta.sh` ataca a 50 req/s
> (`FIND-007`), con targets en `-format=json` para Vegeta ≥ v12 (`FIND-048`) y
> resumen vía `handleSummary()` para k6 ≥ v2 (`FIND-049`). Correcciones
> **validadas contra un stub local**; la corrida real sobre el stack queda
> **pendiente de validación**.

## Reglas del bootstrap

- Solo Persistence accede a MongoDB (aislamiento por redes).
- Datos de Mongo en volumen nombrado; nunca bind-mount versionado.
- `.env` y `traefik/certs/` nunca versionados.
- Stack: Docker Compose v2, Traefik v3, Mongo `mongo:8`, Make, Bash, curl,
  mkcert. Sin observabilidad extra ni CI.

Decisiones de arquitectura: [`docs/architecture-decisions.md`](docs/architecture-decisions.md).
