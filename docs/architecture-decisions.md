# Registro de decisiones de arquitectura (ADR) — Infrastructure

Fuente de verdad de las decisiones de infraestructura. Reemplaza al anterior
`docs/pending-decisions.md`. Cada decisión incluye contexto y alternativas
descartadas. Las decisiones marcadas como coordinación se implementan en los
repos de los servicios.

## Base del sistema (implementadas en este repo)

### D1. Traefik con TLS local (patrón del repo docente)
- **Decisión:** entrypoints `:80` (redirect → :443) y `:443`; certs generados
  con mkcert (`make certs`); dashboard detrás de `Host(traefik.pdf-extractext.localhost)`
  con TLS. Se elimina `api.insecure` y el puerto 8080.
- **Contexto:** se adopta el patrón del repo del docente, adaptado de dominio
  `universidad.localhost` → `pdf-extractext.localhost`.
- **Descartado:** HTTP plano dev-only (rompe paridad con el patrón pedido).

### D2. Dominio local `pdf-extractext.localhost`
- Los subdominios `*.localhost` resuelven a 127.0.0.1 sin tocar `/etc/hosts`.
- Certs mkcert cubren `pdf-extractext.localhost` y `*.pdf-extractext.localhost`.
- Las claves privadas **no se versionan**: cada dev genera las suyas con
  `make certs` (mkcert instala el CA local).

### D3. Routing interno: API → Extraction vía Traefik, entrypoint `internal` (`:8090`) sin redirect
- **Decisión:** el router de `extraction` vive en un entrypoint `internal`
  (`:8090`) **sin** redirect a HTTPS y **no publicado** al host; solo los
  routers públicos (API, cuando exista) redirigen :80 → :443.
- **Contexto:** desviación mínima del patrón docente — el repo docente no
  tiene servicios que se llamen entre sí; nosotros sí. Las llamadas internas
  HTTP+Host-header no deben recibir un 301.
- **Balanceo:** Traefik balancea entre réplicas de Extraction (labels docker
  + `deploy.replicas`). API consumirá `EXTRACTION_URL=http://traefik:8090` con
  `Host: extraction.pdf-extractext.localhost` (ver issues de coordinación).

### D4. Aislamiento por redes
- `services`: Traefik, API, Extraction, Persistence.
- `data`: MongoDB y Persistence (único servicio con acceso a la DB).
- 27017 no se publica al host; volúmenes nombrados; jamás bind-mounts de datos.

### D5. Versiones de imagen parametrizables
- `EXTRACTION_TAG` / `PERSISTENCE_TAG` en `.env`, default `dev`.
- Se elimina el tag hardcodeado `:bootstrap`.

### D6. Build desde repos hermanos (RESUELTA, antes pendiente #7)
- `EXTRACTION_CONTEXT` / `PERSISTENCE_CONTEXT` apuntan a los repos hermanos
  clonados. Forma definitiva para desarrollo local.

### D7. MongoDB `mongo:8` (RESUELTA, antes pendiente #6)
- `MONGO_IMAGE=mongo:8` es la versión definitiva.
- Coordinación: los tests de integración de Persistence deben alinearse
  (hoy fijados en `mongo:7.0`; comunicado al responsable).

### D8. Healthchecks
- `depends_on: service_healthy` solo donde existe healthcheck (Mongo).
- **Decisión:** Se implementan healthchecks in-container (CMD-SHELL con `curl -f http://localhost:<PUERTO>/readyz`) para `extraction` y `persistence`. El servicio `api` ahora depende de su `condition: service_healthy` para un arranque ordenado. Traefik, por defecto, excluye automáticamente del balanceo a las réplicas unhealthy.
- **Contexto:** Los microservicios ahora exponen `/readyz`. Para garantizar la orquestación de arranque y el balanceo correcto en Traefik, se habilitan estos healthchecks.

### D9. Límites de recursos
- Extraction: `cpus: '1.0'`, `memory: 1G` por réplica (exigencia del TP).
- Réplicas de Extraction parametrizables con `EXTRACTION_REPLICAS` (1–5,
  default 1); el balanceo lo resuelve Traefik vía provider docker (D3).
- Resto de servicios: sin límites en desarrollo local.

### D10. Saturación: 503 controlado (coordinación)
- Rechazo con 503 + `Retry-After` lo implementa Extraction (su issue).
- El TP admite 429, pero 429 es semántica de rate-limit por consumidor y no
  figura en el catálogo contractual. Infra no participa.

### D11. Herramienta de carga: k6 + Vegeta
- Decidido por el TP del equipo: k6 abierto ≥25 req/s, spike 100 VUs;
  Vegeta 50 req/s x 30s.
- Entorno de carga (fixtures, targets Make) se define en una issue aparte.

### D12. Sin CI por ahora
- `make smoke` corre solo local. CI se evalúa en issue aparte.

### D13. Sin herramientas adicionales
- Stack fijo: Docker Compose v2, Traefik v3, Mongo oficial, Make, Bash, curl.
- Si Bash/Make no alcanzan, se evalúa en una issue antes de agregar nada.

## Coordinación (se implementan en otros repos)

### D14. Contrato de Extraction: manda el TP del docente
- Entrada: **únicamente** multipart/form-data (decisión del equipo; se
  descarta binario directo / `application/octet-stream`).
- Salida 200: `{"content": "...", "page_count": N}`.
- API (Bruno) ya lo implementa; Extraction (Manu) ajusta sus issues #2 y #5.
- **Pregunta abierta del equipo:** quién calcula el SHA-256 que Persistence
  necesita para `POST /documents` (índice único `checksum_1`). Propuesta:
  Extraction lo sigue calculando (campo extra en la respuesta) o lo calcula
  API. A resolver en sync del equipo.

### D15. API Service en el compose (✅ RESUELTA)
- El servicio `api` se construye desde `API_CONTEXT` (repo hermano) con tag
  `API_TAG`; red `services` únicamente (sin acceso a `data`); expone `:8000`
  solo a la red interna (no publicado al host).
- Env inyectadas: `EXTRACTION_URL=http://traefik:8090` (entrypoint interno,
  ver D3), `PERSISTENCE_URL=http://persistence:8002`, `MAX_FILE_SIZE_MB=50`.
- Router público `Host(pdf-extractext.localhost)` en entrypoint `https` con
  TLS (mkcert). La redirección :80→:443 ya es global en la config estática,
  por lo que no se define un router HTTP redundante.
- **Restricción contractual:** Extraction acepta **solo** `multipart/form-data`
  (no `application/octet-stream` ni binario directo). La API reenvía el
  archivo en ese formato (ver D14).
